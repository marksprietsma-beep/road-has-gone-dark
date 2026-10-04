import {readFileSync} from 'node:fs';
import {sourceDryLand} from './compose-local-region.mjs';
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
export function buildEncounterDemo(context,hexes,visible){
 // A presentation proof, deliberately separate from gameplay and hidden POIs.
 const known=[...context.source_burgs.map(b=>b.local_position),...visible.map(s=>s.position)];
 const candidates=hexes.cells.filter(c=>c.points.every(p=>p.every(n=>n>110&&n<900)&&sourceDryLand(context,p))&&sourceDryLand(context,c.centre)&&known.every(p=>Math.hypot(p[0]-c.centre[0],p[1]-c.centre[1])>100));
 const selected=[];
 for(const role of ['brigands','hill-monsters']){
  const c=candidates.find(c=>selected.every(s=>Math.hypot(s.position[0]-c.centre[0],s.position[1]-c.centre[1])>180));
  if(c)selected.push({role,axial:c.axial,position:c.centre,label:role==='brigands'?'Bandits':'Monster'});
 }
 return {meaning:'MOCKUP_NOT_SIMULATION',occupants:selected};
}
