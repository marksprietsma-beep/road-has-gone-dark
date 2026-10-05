import {readFileSync} from 'node:fs';
import {sha} from './core.mjs';
export function loadWorld(path) {
  const bytes = readFileSync(path), source = JSON.parse(bytes);
  if (source.schemaVersion !== 1 || source.generator?.provider !== 'azgaar' || source.generator.version !== '1.153.1' || !source.seed || !Array.isArray(source.cells?.ids)) throw Error('Unsupported base world');
  const digest = sha(bytes);
  const base = {id: `azgaar:1.153.1:${source.seed}:${digest}`, seed: source.seed, sha256: digest, generator: source.generator};
  const cellIndices = new Map(source.cells.ids.map((id, i) => [id, i]));
  if (cellIndices.size !== source.cells.ids.length) throw Error('Duplicate source cell');
  const record = (group, id) => source[group].find(x => x && typeof x === 'object' && x.i === id) ?? null;
  const cell = id => {
    const i = cellIndices.get(id); if (i === undefined) throw Error('Missing source cell');
    return Object.fromEntries(Object.entries(source.cells).filter(([, v]) => Array.isArray(v)).map(([k, v]) => [k, v[i]]));
  };
  return {source, base, record, cell};
}
export const eligible = b => b && !b.hidden && !b.removed && !b.capital && b.population > 0 && b.population <= 5;
export function context(world, kind, id) {
  if (!['settlements', 'markers'].includes(kind)) throw Error('Unsupported context kind');
  const entity = world.record(kind, id);
  if (!entity || entity.removed || entity.hidden) throw Error('Unavailable source entity');
  const c = world.cell(entity.cell);
  const fact = (value, path, status = 'source-exact') => ({value: value ?? null, status: value == null ? 'unknown' : status, provenance: path});
  const lookup = (group, n) => n > 0 ? world.record(group, n)?.name ?? null : null;
  const routes = world.source.routes.filter(r => r && !r.hidden && !r.removed && Array.isArray(r.points) && r.points.some(p => p[2] === entity.cell && Math.hypot(p[0] - c.points[0], p[1] - c.points[1]) < 0.02)).map(r => r.i).sort((a,b) => a-b);
  return {
    world: world.base, source_kind: kind, source_id: id, cell_id: entity.cell,
    state_id: c.state, province_id: c.province,
    display_name: entity.name ?? null,
    marker_type: kind === 'markers' ? entity.type ?? null : null,
    culture: fact(lookup('cultures', c.culture), `cells.culture[${entity.cell}] -> cultures:${c.culture}`),
    religion: fact(lookup('religions', c.religion), `cells.religion[${entity.cell}] -> religions:${c.religion}`),
    biome: fact(world.record('biomes', c.biome)?.name ?? null, `cells.biome[${entity.cell}] -> biomes:${c.biome}`),
    culture_id: c.culture, religion_id: c.religion,
    river_id: fact(c.river > 0 ? c.river : null, `cells.river[${entity.cell}]`),
    road_ids: fact(routes.filter(id => world.record('routes', id).group === 'roads'), `routes.group=roads; points match cell:${entity.cell} and canonical coordinates`, 'source-derived'),
    trail_ids: fact(routes.filter(id => world.record('routes', id).group === 'trails'), `routes.group=trails; points match cell:${entity.cell} and canonical coordinates`, 'source-derived'),
    sea_route_ids: fact(routes.filter(id => world.record('routes', id).group === 'searoutes'), `routes.group=searoutes; points match cell:${entity.cell} and canonical coordinates`, 'source-derived'),
    // A port flag is not sufficient evidence of ocean coast. Never call it coastal.
    port: fact(kind === 'settlements' && Object.hasOwn(entity, 'port') ? entity.port : null, `${kind}:${id}.port`),
    walls: fact(kind === 'settlements' && Object.hasOwn(entity, 'walls') ? Boolean(entity.walls) : null, `${kind}:${id}.walls`),
    coast: fact(null, 'Water-body classification not implemented in this research adapter'),
    source_flavour: kind === 'markers' ? {dungeon_seed: (entity.note ?? '').match(/one-page-dungeon\/\?seed=([^"&<>\s]+)/)?.[1] ?? null, name: entity.name ?? '', note: entity.note ?? '', visibility: 'developer-only', authoritative_history: false} : null,
    source_visibility: /undiscovered|<iframe|one-page-dungeon/i.test(entity.note ?? '') ? 'hidden' : 'public'
  };
}
