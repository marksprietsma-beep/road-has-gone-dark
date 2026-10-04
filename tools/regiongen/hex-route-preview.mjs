/** GAME-60: conservative source-water filter + provisional illustrative effort.
 * Not gameplay pathfinding, safe-road certification, kilometres or hours. */
import {hexAt,hexDistance} from './hex-overlay.mjs';
import {hexSourceDry,encounterTerrainAt} from './shared-map-icons.mjs';
const neighbours=[[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]];
const key=p=>p.join(',');
const tie=(a,b)=>a[0]-b[0]||a[1]-b[1];
const round=n=>Math.round(n*1e5)/1e5;
export function findHexRoute(cells,start,target,weighted=true){
 if(cells.some(c=>!Number.isFinite(c.cost_ticks)||c.cost_ticks<=0))throw Error('Hex effort costs must be positive');
 const byKey=new Map(cells.map(c=>[key(c.axial),c])),origin=key(start),goal=key(target);
 if(!byKey.has(origin)||!byKey.has(goal))return null;
 const distance=new Map([[origin,0]]),parent=new Map(),open=new Set([origin]),done=new Set();
 while(open.size){
  const current=[...open].sort((a,b)=>distance.get(a)-distance.get(b)||tie(byKey.get(a).axial,byKey.get(b).axial))[0];
  open.delete(current);done.add(current);
  if(current===goal){
   const path=[];for(let at=goal;at!==undefined;at=parent.get(at))path.unshift(byKey.get(at).axial);
   return {path,steps:path.length-1,cost_ticks:distance.get(goal)};
  }
  const a=byKey.get(current);
  for(const [dq,dr] of neighbours){
   const next=key([a.axial[0]+dq,a.axial[1]+dr]),b=byKey.get(next);
   if(!b||done.has(next))continue;
   // Symmetric integer eighth-units: average terrain costs of both cells.
   const cost=weighted?a.cost_ticks+b.cost_ticks:8;
   const candidate=distance.get(current)+cost;
   if(candidate<(distance.get(next)??Infinity)){
    distance.set(next,candidate);parent.set(next,current);open.add(next);
   }
  }
 }
 return null;
}
function intersection(a,b,c,d){
 const dx=b[0]-a[0],dy=b[1]-a[1],ex=d[0]-c[0],ey=d[1]-c[1],cross=dx*ey-dy*ex;
 if(Math.abs(cross)<1e-9){
  const length=dx*dx+dy*dy;
  if(length<1e-9||Math.abs((c[0]-a[0])*dy-(c[1]-a[1])*dx)>1e-7)return null;
  const t=((c[0]-a[0])*dx+(c[1]-a[1])*dy)/length,u=((d[0]-a[0])*dx+(d[1]-a[1])*dy)/length;
  const lo=Math.max(0,Math.min(t,u)),hi=Math.min(1,Math.max(t,u));
  return lo<=hi?[round(a[0]+(lo+hi)/2*dx),round(a[1]+(lo+hi)/2*dy)]:null;
 }
 const t=((c[0]-a[0])*ey-(c[1]-a[1])*ex)/cross,u=((c[0]-a[0])*dy-(c[1]-a[1])*dx)/cross;
 return t>=-1e-7&&t<=1+1e-7&&u>=-1e-7&&u<=1+1e-7?[round(a[0]+t*dx),round(a[1]+t*dy)]:null;
}
export function approximateRiverCrossings(context,points){
 const hits=new Map();
 for(const river of context.source_rivers)for(const segment of river.segments)
  for(let j=1;j<segment.local_points.length;j++)for(let i=1;i<points.length;i++){
   const p=intersection(points[i-1],points[i],segment.local_points[j-1],segment.local_points[j]);
   if(p)hits.set(`${river.source_id}:${p.map(n=>Math.round(n*100)).join(',')}`,{source_river_id:river.source_id,position:p,meaning:'APPROXIMATE_RIVER_CROSSING_UNVERIFIED'});
  }
 return [...hits.values()];
}
export function buildHexRoutePreview(context,hexes,terrain,visible){
 for(const layer of [hexes,terrain])if(layer?.source_context_id!==context.id||layer?.source_world_sha256!==context.parent_source_world_sha256)throw Error('Route inputs belong to a different source context');
 if(terrain.truth!=='INFERRED_VISUAL_FIELD_NOT_TRAVERSAL')throw Error('Route costs must remain explicitly inferred');
 const cells=hexes.cells.filter(c=>hexSourceDry(context,c)).map(c=>{
  const v=encounterTerrainAt(terrain,c.centre),woodland=v.f>=.57,rough=v.h>=69;
  return {axial:c.axial,centre:c.centre,cost_ticks:4+(woodland?2:0)+(rough?3:0),woodland,rough};
 });
 const byKey=new Map(cells.map(c=>[key(c.axial),c])),b=context.space.source_bounds;
 const localHex=p=>hexAt([b.left+p[0]*(b.right-b.left)/1000,b.top+p[1]*(b.bottom-b.top)/1000]);
 const home=context.space.home_local,start=localHex(home),routes=[];
 // Public knowledge only, even if callers accidentally pass the complete site layer.
 for(const site of visible.filter(s=>s.kind!=='hometown'&&['discovered','visited'].includes(s.knowledge))){
  const target=localHex(site.position),base={site_id:site.id,target_axial:target,geometric_steps:hexDistance(start,target)};
  const shortest=findHexRoute(cells,start,target,false),weighted=findHexRoute(cells,start,target,true);
  if(!weighted){
   routes.push({...base,status:!byKey.has(key(start))?'HOME_HEX_BLOCKED':!byKey.has(key(target))?'TARGET_HEX_BLOCKED':'DISCONNECTED_IN_WINDOW',path:[],points:[],river_crossings:[]});continue;
  }
  const points=[home,...weighted.path.map(p=>byKey.get(key(p)).centre),site.position].filter((p,i,a)=>i===0||key(p)!==key(a[i-1]));
  const shortestEffort=shortest.path.slice(1).reduce((total,p,i)=>total+byKey.get(key(p)).cost_ticks+byKey.get(key(shortest.path[i])).cost_ticks,0)/8;
  routes.push({...base,status:'PREVIEW_ROUTE',path:weighted.path,points,route_steps:weighted.steps,shortest_steps:shortest.steps,shortest_path:shortest.path,shortest_effort:shortestEffort,effort:weighted.cost_ticks/8,river_crossings:approximateRiverCrossings(context,points)});
 }
 const score=r=>r.status==='PREVIEW_ROUTE'?(r.route_steps-r.shortest_steps)*100+r.river_crossings.length*20+(r.route_steps>r.shortest_steps?-r.geometric_steps:r.geometric_steps):-1;
 const preferred=routes.reduce((a,r)=>!a||score(r)>score(a)?r:a,null);
 return {schema_version:1,source_context_id:context.id,source_world_sha256:context.parent_source_world_sha256,
  meaning:'SOURCE_WATER_FILTERED_NOT_VERIFIED_TRAVERSABLE',physical_km:'UNCALIBRATED',hours:'UNCALIBRATED',
  cost_model:{meaning:'PROVISIONAL_INFERRED_TERRAIN_EFFORT',open:1,woodland_addition:.5,rough_addition:.75,road_discount:0,encounter_cost:0},
  home_axial:start,default_site_id:preferred?.site_id||'',cells,routes};
}
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
export function renderHexRoutePreview(layer,hexes,route,site){
 const lines=['<g id="hex-route-preview" clip-path="url(#world)">'];
 if(route?.status==='PREVIEW_ROUTE'){
  for(const axial of route.path){const c=hexes.cells.find(c=>key(c.axial)===key(axial));lines.push(`<polygon points="${c.points.map(p=>p.join(',')).join(' ')}" fill="#d8a749" fill-opacity=".3" stroke="#a47b2d" stroke-width="1.5"/>`);}
  lines.push(`<polyline points="${route.points.map(p=>p.join(',')).join(' ')}" fill="none" stroke="#6f4c16" stroke-width="3" stroke-dasharray="7 4"/>`);
  for(const crossing of route.river_crossings)lines.push(`<circle cx="${crossing.position[0]}" cy="${crossing.position[1]}" r="6" fill="#efe1bd" stroke="#9d4735" stroke-width="2"/>`);
 }
 lines.push('</g><rect x="520" y="20" width="460" height="110" fill="#efe1bd" fill-opacity=".97" stroke="#a47b2d"/>',
  `<text x="535" y="45" font-size="18" font-family="Georgia" fill="#59451e">ROUTE PREVIEW · ${esc(site?.label||'No known destination')}</text>`);
 if(route?.status==='PREVIEW_ROUTE')lines.push(`<text x="535" y="68" font-size="15" fill="#59451e">${route.geometric_steps} straight · ${route.route_steps} routed steps · ${route.effort} effort</text>`,
  `<text x="535" y="91" font-size="13" fill="#843e30">${route.river_crossings.length} approximate river crossings · unverified</text>`);
 else lines.push(`<text x="535" y="68" font-size="14" fill="#843e30">${!route?'No known destination yet':route.status==='HOME_HEX_BLOCKED'?'Coastal home hex needs finer geometry':route.status==='TARGET_HEX_BLOCKED'?'Destination hex overlaps source water':'No connected dry-hex route in this window'}</text>`);
 lines.push('<text x="535" y="114" font-size="12" fill="#74674d">Provisional terrain costs · hours undecided · walkability unknown</text>');
 return lines.join('\n');
}
