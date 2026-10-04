import {readFileSync} from 'node:fs';
import {sourceDryLand,insidePolygon} from './compose-local-region.mjs';
export const SITE_ROLES={farmstead:'hamlet',roadside_inn:'inns',watchtower:'fort',shrine:'monastery',ruins:'ruins',cave:'cave',old_mine:'mine',abandoned_camp:'encounters',ancient_stones:'statues',dangerous_woods:'sacred-forests'};
const roles=new Set(['capital','city','town','village','hamlet','fort','monastery','trading','ruins','cave','lighthouse','mine']);
export function settlementRole(s){
 if(['caravanserai','trading_post'].includes(s.group))return 'trading';
 return roles.has(s.group)?s.group:s.capital===1?'capital':'town';
}
export function buildSharedIcons(world,context){
 const burg_roles={};
 for(const b of context.source_burgs){
  const s=world.settlements.find(s=>s.i===b.source_id);
  if(!s)throw Error('Missing source settlement');
  burg_roles[b.source_id]=settlementRole(s);
 }
 const home=context.source_burgs.find(b=>b.source_id===context.source_home_burg_id);
 const area=world.cells.area[home.source_cell_id],bounds=context.space.source_bounds;
 const windowArea=(bounds.right-bounds.left)*(bounds.bottom-bounds.top);
 return {schema_version:1,family:'Game-icons',marker_diameter:32,icon_diameter:26,burg_roles,site_roles:SITE_ROLES,
  scale:{source_cell_id:home.source_cell_id,source_cell_area:area,local_window_area:windowArea,window_to_home_cell_area:windowArea/area,hex_area:Math.sqrt(3)/2,home_cell_to_hex_area:area/(Math.sqrt(3)/2),physical_units:'UNCALIBRATED',world_cells:'IRREGULAR_VORONOI_NOT_LOCAL_HEXES'}};
}
const cache=new Map();
export function renderSharedIcon(role,position,{danger=false}={}){
 if(!cache.has(role)){
  const svg=readFileSync(new URL('../../assets/map_icons/trials/game-icons/'+role+'.svg',import.meta.url),'utf8');
  cache.set(role,svg.slice(svg.indexOf('>')+1,svg.lastIndexOf('</svg>')));
 }
 const [x,y]=position;
 return `<g class="shared-game-icon" data-role="${role}"><circle cx="${x}" cy="${y}" r="16" fill="#efe1bd" stroke="${danger?'#9d4735':'#66583e'}" stroke-width="2"/><svg x="${x-13}" y="${y-13}" width="26" height="26" viewBox="0 0 512 512">${cache.get(role)}</svg></g>`;
}
const distance=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
function segmentsTouch(a,b,c,d){
 const eps=1e-7,cross=(a,b,c)=>(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);
 if(Math.max(a[0],b[0])+eps<Math.min(c[0],d[0])||Math.max(c[0],d[0])+eps<Math.min(a[0],b[0])||Math.max(a[1],b[1])+eps<Math.min(c[1],d[1])||Math.max(c[1],d[1])+eps<Math.min(a[1],b[1]))return false;
 return cross(a,b,c)*cross(a,b,d)<=eps&&cross(c,d,a)*cross(c,d,b)<=eps;
}
export function hexSourceDry(context,cell){
 const points=cell.points;
 if(points?.length!==6||!sourceDryLand(context,cell.centre)||!points.every(p=>sourceDryLand(context,p)))return false;
 // Exact boundary intersections catch narrow channels missed by vertex tests.
 for(const f of context.source_features){
  if(!['land_boundary','freshwater_lake'].includes(f.classification))continue;
  const poly=f.local_polygon;
  if(poly.some(p=>insidePolygon(p,points)))return false; // Includes an enclosed tiny lake.
  for(let i=0;i<poly.length;i++)for(let j=0;j<6;j++)
   if(segmentsTouch(poly[i],poly[(i+1)%poly.length],points[j],points[(j+1)%6]))return false;
 }
 return true;
}
export function sourceRoadDistance(context,p){
 let best=Infinity;
 for(const route of context.source_routes.filter(r=>['land_road','trail'].includes(r.classification)))
  for(const segment of route.segments)for(let i=1;i<segment.local_points.length;i++){
   const a=segment.local_points[i-1],b=segment.local_points[i],dx=b[0]-a[0],dy=b[1]-a[1];
   const t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy||1)));
   const nearest=[a[0]+t*dx,a[1]+t*dy];
   if(sourceDryLand(context,nearest))best=Math.min(best,distance(p,nearest));
  }
 return best;
}
export function encounterTerrainAt(terrain,p){
 const n=terrain.grid_steps,i=Math.max(0,Math.min(n,Math.round(p[0]*n/1000))),j=Math.max(0,Math.min(n,Math.round(p[1]*n/1000)));
 return terrain.vertices[j*(n+1)+i];
}
export function buildEncounterDemo(context,hexes,visible,terrain){
 // A presentation proof, deliberately separate from gameplay and hidden POIs.
 if(terrain?.source_context_id!==context.id||terrain?.source_world_sha256!==context.parent_source_world_sha256||terrain?.truth!=='INFERRED_VISUAL_FIELD_NOT_TRAVERSAL')throw Error('Encounter proof needs matching illustrative terrain');
 const known=[...context.source_burgs.map(b=>b.local_position),...visible.map(s=>s.position)];
 const candidates=hexes.cells.filter(c=>c.centre[0]>120&&c.centre[0]<760&&c.centre[1]>200&&c.centre[1]<860&&hexSourceDry(context,c)&&known.every(p=>distance(p,c.centre)>100))
  .map(c=>({...c,road_distance:sourceRoadDistance(context,c.centre),terrain:encounterTerrainAt(terrain,c.centre)}));
 const tie=(a,b)=>a.axial[1]-b.axial[1]||a.axial[0]-b.axial[0];
 const selected=[];
 for(const role of ['brigands','hill-monsters']){
  const eligible=candidates.filter(c=>selected.every(s=>distance(s.position,c.centre)>180)&&
   (role==='brigands'?c.road_distance<=65:c.terrain.f>=.57||c.terrain.h>=69));
  eligible.sort(role==='brigands'?(a,b)=>a.road_distance-b.road_distance||tie(a,b):(a,b)=>b.terrain.f-a.terrain.f||b.terrain.h-a.terrain.h||tie(a,b));
  const c=eligible[0];
  if(c)selected.push({id:`mock:${role}:${c.axial.join(':')}`,role,axial:c.axial,position:c.centre,label:role==='brigands'?'Bandits':'Monster',
   placement:role==='brigands'?'NEAR_SOURCE_ROAD_NOT_VERIFIED_SAFE':c.terrain.f>=.57?'INFERRED_WOODLAND':'INFERRED_ROUGH_GROUND',
   evidence:{road_distance:Number.isFinite(c.road_distance)?+c.road_distance.toFixed(3):null,canopy:+c.terrain.f.toFixed(4),height:+c.terrain.h.toFixed(4)}});
 }
 return {schema_version:1,source_context_id:context.id,source_world_sha256:context.parent_source_world_sha256,meaning:'MOCKUP_NOT_SIMULATION',occupants:selected,omitted_roles:['brigands','hill-monsters'].filter(role=>!selected.some(o=>o.role===role))};
}
