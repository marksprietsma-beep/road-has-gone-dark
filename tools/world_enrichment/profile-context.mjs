// Source-derived evidence only. No demographic census, resource invention or marker prose.
import {context} from './context.mjs';
const caches=new WeakMap();
export function profileIndex(world){
 if(caches.has(world))return caches.get(world);
 const s=world.source,c=s.cells,land=i=>c.heights[i]>=20;
 const features=new Map((s.map.geography??[]).map(f=>[f.i,f]));
 const water=i=>{const types=(c.neighbors[i]??[]).filter(n=>!land(n)).map(n=>features.get(c.features[n])?.type);return types.includes('ocean')?'coast':types.includes('lake')?'lake':null;};
 const routeCells=new Map();
 for(const r of s.routes.filter(r=>r&&!r.hidden&&!r.removed&&['roads','trails'].includes(r.group)))for(const p of r.points??[])if(Number.isInteger(p[2])){const tags=routeCells.get(p[2])??new Set();tags.add(r.group==='roads'?'road':'trail');routeCells.set(p[2],tags);}
 const mines=new Set(s.markers.filter(m=>m&&!m.hidden&&!m.removed&&m.type==='mines'&&!/undiscovered|iframe/i.test(m.note??'')).map(m=>m.cell));
 const cells=c.ids.filter(land), towns=s.settlements.filter(b=>b&&b.i>0&&!b.hidden&&!b.removed&&b.population>0&&land(b.cell));
 const out={features,water,routeCells,mines,cells,towns};caches.set(world,out);return out;
}
export function areaContext(world,stateId,provinceId=null,burg=null){
 const idx=profileIndex(world),s=world.source,c=s.cells;
 const ids=burg?[burg.cell]:idx.cells.filter(i=>c.state[i]===stateId&&(provinceId===null||c.province[i]===provinceId));
 const set=new Set(ids),towns=burg?[burg]:idx.towns.filter(b=>set.has(b.cell));
 const tags=new Set(),hist=field=>{const counts=new Map();for(const i of ids){const id=c[field]?.[i];if(id>0)counts.set(id,(counts.get(id)??0)+1);}return [...counts].sort((a,b)=>b[1]-a[1]||a[0]-b[0]).map(([id,count])=>({id,mapped_cells:count,name:world.record(field==='culture'?'cultures':'religions',id)?.name??null})).filter(x=>x.name!==null);};
 const biomeCounts=new Map();
 for(const i of ids){const name=world.record('biomes',c.biome[i])?.name??'Unknown';biomeCounts.set(name,(biomeCounts.get(name)??0)+1);const w=idx.water(i);if(w)tags.add(w);if(c.river[i]>0)tags.add('river');if(c.heights[i]>=50)tags.add('upland');if(idx.mines.has(i))tags.add('mine');for(const t of idx.routeCells.get(i)??[])tags.add(t);if(c.neighbors[i].some(n=>c.heights[n]>=20&&c.state[n]!==stateId))tags.add('border');}
 const biomes=[...biomeCounts].sort((a,b)=>b[1]-a[1]||a[0].localeCompare(b[0]));
 // Regional resources must be a meaningful share, not one decorative forest cell.
 const share=re=>biomes.filter(([n])=>re.test(n)).reduce((sum,[,n])=>sum+n,0)/Math.max(ids.length,1);
 if(share(/forest|woodland|taiga/i)>=.2)tags.add('forest');
 if(share(/grassland|savanna|tundra/i)>=.2)tags.add('pasture');
 if(share(/grassland|savanna|seasonal forest|deciduous/i)>=.2)tags.add('farmland');
 if(share(/wetland/i)>=.2)tags.add('wetland');
 if(towns.some(b=>b.port>0))tags.add('port');
 // Aggregation must not combine a lake port with an unrelated ocean coast.
 if(towns.some(b=>b.port>0&&idx.water(b.cell)==='coast'))tags.add('coastal-port');
 if(towns.some(b=>b.walls))tags.add('walls');if(towns.some(b=>b.capital))tags.add('capital');
 const cultures=hist('culture'),religions=hist('religion');if(cultures.length>1)tags.add('mixed-cultures');
 return {world_id:world.base.id,state_id:stateId,province_id:provinceId,burg_id:burg?.i??null,cell_id:burg?.cell??null,
  tags:[...tags].sort(),cultures,religions,dominant_biome:biomes[0]?.[0]??'Unknown',land_cells:ids.length,settlement_ids:towns.map(b=>b.i).sort((a,b)=>a-b),
  provenance:{cultures:'positive, existing cells.culture IDs; counts of mapped land cells, not population shares or language',religions:'positive existing cells.religion IDs; no religious character inferred from names',geography:'source map.geography types + cells.heights/neighbors/river/biome; coastal-port requires one actual port burg adjoining ocean water',routes:'public source route point cell membership, not proof of a direct settlement entrance',mining:'public explicit mines markers; no ore type or hidden note text',biome:'20% compatible mapped-cell share; suitability supports generated livelihood, not source-exact industry',economy:'TRHGD generated background constrained by evidence; no simulated trade'},
 };
}
// Stable IDs and parent records are available to every existing downstream domain.
export function withProfiles(world,burgId,profiles){
 const ctx=context(world,'settlements',burgId),home=profiles.hometowns[String(burgId)];
 if(!home||home.source.world_id!==world.base.id)throw Error('Profile context belongs to a different hometown/world');
 const region=profiles.regions[home.parents.region],state=profiles.states[String(ctx.state_id)];
 const scoped=[['state',state],['region',region],['hometown',home]].flatMap(([scope,r])=>r.tags.filter(t=>!r.source_context.tags.includes(t)).map(t=>scope+':'+t));
 return {...ctx,profile_context:{schema_version:2,state:state.public,region:region.public,hometown:home.public,provenance:'immutable profiles-v2; generated background, not canonical Azgaar economy'},profile_tags:[...new Set(scoped)].sort()};
}
