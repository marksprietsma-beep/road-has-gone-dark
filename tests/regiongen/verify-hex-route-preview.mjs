import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {buildHexRoutePreview,findHexRoute,approximateRiverCrossings} from '../../tools/regiongen/hex-route-preview.mjs';
import {hexDistance} from '../../tools/regiongen/hex-overlay.mjs';
import {hexSourceDry} from '../../tools/regiongen/shared-map-icons.mjs';
const key=p=>p.join(',');
const nodes=[];
for(let q=-3;q<=3;q++)for(let r=-3;r<=3;r++)if(hexDistance([0,0],[q,r])<=3)nodes.push({axial:[q,r],cost_ticks:4});
assert.equal(findHexRoute(nodes,[-2,0],[2,0]).steps,4);
assert.equal(findHexRoute(nodes,[-2,0],[-2,0]).cost_ticks,0);
const lake=nodes.filter(c=>key(c.axial)!=='0,0');
const detour=findHexRoute(lake,[-2,0],[2,0]);assert.equal(detour.steps,5);assert.ok(!detour.path.some(p=>key(p)==='0,0'));
assert.equal(findHexRoute(nodes.filter(c=>c.axial[0]!==0),[-2,0],[2,0]),null);
assert.equal(findHexRoute(nodes,[99,99],[2,0]),null,'Blocked endpoint was silently snapped');
const rough=nodes.map(c=>({...c,cost_ticks:key(c.axial)==='0,0'?9:4}));
assert.equal(findHexRoute(rough,[-2,0],[2,0],false).steps,4);
const cheaper=findHexRoute(rough,[-2,0],[2,0]);assert.equal(cheaper.steps,5);assert.equal(cheaper.cost_ticks/8,5);
assert.equal(findHexRoute(rough,[2,0],[-2,0]).cost_ticks,cheaper.cost_ticks,'Effort must be symmetric');
assert.throws(()=>findHexRoute([{axial:[0,0],cost_ticks:0}],[0,0],[0,0]));
const river={source_rivers:[{source_id:1,segments:[{local_points:[[5,-10],[5,10]]}]}]};
assert.equal(approximateRiverCrossings(river,[[0,0],[10,0]]).length,1);
assert.equal(approximateRiverCrossings(river,[[0,20],[10,20]]).length,0);
assert.equal(approximateRiverCrossings(river,[[5,-5],[5,5]]).length,1,'Route along a river must flag uncertainty');
let connected=0,longer=0,crossings=0;
for(const stem of ['game-11-determinism','atlas-showcase'])for(const kind of ['shore','river','highland']){
 const name=`tools/regiongen/.tmp/contextual-${stem}-${kind}`,r=JSON.parse(await readFile(name+'.json','utf8'));
 const layer=r.hex_route_preview_v1,ctx=r.source_context,terrain=r.landscape_presentation_v1.terrain;
 assert.deepEqual(buildHexRoutePreview(ctx,r.hex_overlay_v1,terrain,r.local_sites_v2.sites),layer);
 assert.equal(layer.hours,'UNCALIBRATED');assert.equal(layer.physical_km,'UNCALIBRATED');
 const changed=structuredClone(r.local_sites_v2.sites);
 for(const s of changed)if(['hidden','rumoured'].includes(s.knowledge)){s.position=[0,0];s.id='PRIVATE';s.label='PRIVATE';}
 assert.deepEqual(buildHexRoutePreview(ctx,r.hex_overlay_v1,terrain,changed),layer);
 assert.throws(()=>buildHexRoutePreview(ctx,{...r.hex_overlay_v1,source_context_id:'other'},terrain,changed));
 if(layer.routes.length){
  for(const which of ['home','target']){
   const centre=which==='home'?ctx.space.home_local:r.local_sites_v2.sites.find(s=>s.id===layer.routes[0].site_id).position;
   const blocked=structuredClone(ctx),[x,y]=centre;
   blocked.source_features.push({classification:'freshwater_lake',local_polygon:[[x-20,y-20],[x+20,y-20],[x+20,y+20],[x-20,y+20]]});
   const proof=buildHexRoutePreview(blocked,r.hex_overlay_v1,terrain,r.local_sites_v2.sites);
   const result=proof.routes.find(r=>r.site_id===layer.routes[0].site_id);
   assert.equal(result.status,which==='home'?'HOME_HEX_BLOCKED':'TARGET_HEX_BLOCKED');
   assert.deepEqual(result.path,[],'Water-blocked endpoint was snapped or given a route');
  }
 }
 const byKey=new Map(layer.cells.map(c=>[key(c.axial),c]));
 for(const route of layer.routes){
  assert.ok(r.local_sites_v2.sites.some(s=>s.id===route.site_id&&['discovered','visited'].includes(s.knowledge)));
  if(route.status!=='PREVIEW_ROUTE'){assert.deepEqual(route.path,[]);continue;}
  connected++;if(route.route_steps>route.shortest_steps){longer++;assert.ok(route.effort<route.shortest_effort);}crossings+=route.river_crossings.length;
  assert.equal(route.route_steps,route.path.length-1);assert.ok(route.shortest_steps>=route.geometric_steps);
  assert.ok(route.effort<=route.shortest_effort+1e-8);
  let effort=0;
  for(let i=0;i<route.path.length;i++){
   const p=route.path[i];assert.ok(byKey.has(key(p)));
   assert.ok(hexSourceDry(ctx,r.hex_overlay_v1.cells.find(c=>key(c.axial)===key(p))));
   if(i){assert.equal(hexDistance(route.path[i-1],p),1);effort+=(byKey.get(key(p)).cost_ticks+byKey.get(key(route.path[i-1])).cost_ticks)/8;}
  }
  assert.equal(effort,route.effort);
 }
 const svg=await readFile(name+'.route.svg','utf8');assert.ok(svg.includes('hex-route-preview'));assert.ok(svg.includes('walkability unknown'));
 for(const site of r.local_sites_v2.sites)if(['hidden','rumoured'].includes(site.knowledge))assert.ok(!svg.includes(site.label));
 assert.ok(!(await readFile(name+'.svg','utf8')).includes('hex-route-preview'));
}
assert.ok(connected>=10&&longer>=1&&crossings>=1);
console.log(`PASS: ${connected} known-site routes, ${longer} lower-effort detours, ${crossings} unverified river crossing; obstacles, disconnection, symmetric effort, privacy and source identity`);
