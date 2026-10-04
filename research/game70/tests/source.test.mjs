import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {generateCellRegion,publicRegion} from '../../../tools/regiongen/generator-v1.mjs';
import {hash,sourceCellPolygon} from '../../../tools/regiongen/cell-region.mjs';
import {validateModel,pointInPolygon} from '../../game67/model.mjs';
const read=async p=>JSON.parse(await readFile(p));
const manifest=await read('research/game70/journeys.json'),art=await read('research/game70/art/manifest.json');
for(const c of manifest.cases){
 test(`${c.slug}: canonical identity, original public model and source-owned exact cell`,async()=>{
  const bytes=await readFile(`tests/worldgen/fixtures/${c.world}.json`),world=JSON.parse(bytes),fp=hash(bytes),burg=world.settlements.find(b=>b?.i===c.burgId);
  assert(burg&&!burg.hidden&&!burg.removed);assert.equal(burg.name,c.name);assert.equal(burg.cell,c.cellId);assert.deepEqual([burg.x,burg.y],c.worldPosition);assert.equal(fp,c.fixtureSha256);
  const model=validateModel(await read(`research/game67/samples/${c.slug}.public.json`));assert.equal(model.settlement.worldIdentity,fp);assert.equal(model.settlement.burgId,burg.i);assert.equal(model.settlement.worldSeed,world.seed);assert(model.establishments.every(e=>e.knowledge!=='unknown'));
  const region=await read(`research/game70/regions/${c.regionFile}`),ctx=region.source_context;assert.equal(region.export_scope,'PUBLIC_KNOWN_ONLY');assert.equal(region.id,c.regionId);assert.equal(ctx.parent_source_world_sha256,fp);assert.equal(ctx.parent_cell.source_id,burg.cell);assert(ctx.parent_cell.burg_ids.includes(burg.i));
  const selected=ctx.source_burgs.find(b=>b.source_id===burg.i);assert.deepEqual(selected.local_position,c.localPosition);assert.deepEqual(selected.world_position,c.worldPosition);assert.equal(selected.source_cell_id,c.cellId);
  const sidecar=await read(`tools/regiongen/.tmp/geography-${c.world==='atlas-showcase'?'atlas':'game-11'}.json`);assert.deepEqual(ctx.parent_cell.world_polygon,sourceCellPolygon(world,sidecar,c.cellId));
  assert(region.local_sites_v2.sites.every(s=>s.kind==='hometown'||['discovered','visited'].includes(s.knowledge)));assert(region.local_sites_v2.rumours.every(r=>!('position'in r)&&!('id'in r)));
 });
 test(`${c.slug}: generation replays committed bytes without stock-region substitution`,async()=>{
  const bytes=await readFile(`tests/worldgen/fixtures/${c.world}.json`),world=JSON.parse(bytes),sidecar=await read(`tools/regiongen/.tmp/geography-${c.world==='atlas-showcase'?'atlas':'game-11'}.json`);
  const a=publicRegion(await generateCellRegion(world,c.cellId,hash(bytes),sidecar)),b=publicRegion(await generateCellRegion(world,c.cellId,hash(bytes),sidecar));assert.deepEqual(a,b);assert.equal(JSON.stringify(a)+'\n',await readFile(`research/game70/regions/${c.regionFile}`,'utf8'));
  const other=await read(`tests/worldgen/fixtures/${c.world==='atlas-showcase'?'game-11-determinism':'atlas-showcase'}.json`);await assert.rejects(()=>generateCellRegion(other,c.cellId,hash(bytes),sidecar));
 });
 test(`${c.slug}: exact public SVG provenance and original facility building preserved`,async()=>{
  const record=art.find(r=>r.slug===c.slug);assert.equal(hash(await readFile(record.source)),record.sourceSha256);assert.equal(hash(await readFile(`research/game70/art/${c.slug}.png`)),record.outputSha256);assert(Math.max(...record.pixels)===4096);
  const model=await read(`research/game67/samples/${c.slug}.public.json`),type={batan:'inn',albanes:'guildhall',thilranlena:'warehouse'}[c.slug],e=model.establishments.find(e=>e.type===type),b=model.buildings.find(b=>b.id===e.buildingId);assert(pointInPolygon(e.position,b.polygon));if(c.slug==='albanes')assert.equal(e.provenance.providerBuildingId,'b93');if(c.slug==='thilranlena')assert.equal(e.provenance.providerBuildingId,'b223');
  const dev=await read(`research/game67/samples/${c.slug}.developer.json`);for(const secret of dev.establishments.filter(e=>e.knowledge==='unknown'))assert(!JSON.stringify(model).includes(secret.id));
 });
}
test('Scope preserves GAME-62/67/69, canonical fixtures, saves and main scene',()=>{
 const changed=execFileSync('git',['diff','--name-only','c90a96be9c1a6546f147e4853d5bdc183a8b24c9'],{encoding:'utf8'}).trim().split('\n').filter(Boolean);
 assert(changed.every(p=>p.startsWith('research/game70/')||p.startsWith('scripts/debug/game70/')||p==='scripts/debug/world_region_town_flow.gd'||p==='scenes/debug/world_region_town_flow.tscn'));
 assert.equal(execFileSync('git',['diff','c90a96be9c1a6546f147e4853d5bdc183a8b24c9','--','project.godot','tests/worldgen/fixtures','scripts/debug/local_region_v1.gd','tools/regiongen','research/game67','research/game69'],{encoding:'utf8'}),'');
});
