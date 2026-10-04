/**
 * GAME-44, independent v2 local-site placement: source geography is binding.
 *
 * GAME-40 v1 IDs remain unchanged on their own PR and in older playthroughs.
 * This module defines a NEW namespace, never silently migrating v1 saves.
 */
import {createHash} from "node:crypto";
import {isOwnedDryLand} from "./cell-region.mjs";
import {sourceDryLand} from "./compose-local-region.mjs";
import {auditSourceRoutes} from "./route-consistency.mjs";

export const CONTEXT_SITE_GENERATION_VERSION=2;
const hash=t=>createHash("sha256").update(t).digest("hex");
const fractional=(key)=>parseInt(hash(key).slice(0,8),16)/4294967296;
const round=n=>Math.round(n*100)/100;
const dst=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
const point=p=>Array.isArray(p)&&p.length===2&&p.every(Number.isFinite);
const CATALOGUE=[
 ["farmstead",["Lowfield Holding","Ashfield Croft","Miller's Acre"]],
 ["roadside_inn",["The Last Lantern","Old Toll House","The Grey Mare"]],
 ["watchtower",["Ashen Watch","Broken Beacon","Eastward Lookout"]],
 ["shrine",["Wayfarer's Shrine","The Weeping Saint","Old Stone Chapel"]],
 ["ruins",["Fallen Priory","The Black Abbey","Shattered Hall"]],
 ["cave",["Wolf's Maw","Coldstone Hollow","The Deep Cleft"]],
 ["abandoned_camp",["The Silent Encampment","Burnt Wagons","Hunter's Last Rest"]],
 ["ancient_stones",["The Nine Stones","Crow's Circle","The Ashen Cairn"]],
 ["dangerous_woods",["The Bleak Thicket","Widow's Copse","The Hollow Woods"]],
 ["old_mine",["Old Silver Mine","Drowned Shaft","Blackrock Mine"]]
];
const CATALOGUE_NAMES=new Map(CATALOGUE);
const CIVIL=new Set(["farmstead","roadside_inn","watchtower","shrine"]);
const ROUTE_REQUIRED=new Set(["farmstead","roadside_inn","watchtower","shrine"]);
const HIGH_RELATED=new Set(["cave","old_mine"]);
const WILD=new Set(["ruins","cave","abandoned_camp","ancient_stones","dangerous_woods","old_mine"]);
const pick=(a,key)=>a[Math.floor(fractional(key)*a.length)];
const clamp=(n,a,b)=>Math.max(a,Math.min(b,n));
function routeDistance(p,segments){
 let result=Infinity;
 for(const [a,b] of segments){
  const dx=b[0]-a[0],dy=b[1]-a[1];
  const t=clamp(((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy||1),0,1);
  result=Math.min(result,dst(p,[a[0]+dx*t,a[1]+dy*t]));
 }
 return result;
}
function routes(audit){
 return audit.trustedApproaches.map(seg=>seg.local_points);
}
function nearOriginalHeight(world,context,p) {
 const bounds=context.space.source_bounds;
 const real=[bounds.left+p[0]*(bounds.right-bounds.left)/1000,
   bounds.top+p[1]*(bounds.bottom-bounds.top)/1000];
 let best=Infinity,index=-1;
 for(let i=0;i<world.cells?.points?.length;i++){
  const q=world.cells.points[i];if(!point(q))continue;
  const dist=(real[0]-q[0])**2+(real[1]-q[1])**2;
  if(dist<best){best=dist;index=i;}
 }
 return index<0?null:world.cells.heights?.[index];
}
function clearDryLand(context,p) {
 if(p[0]<38||p[0]>962||p[1]<115||p[1]>915)return false;
 return sourceDryLand(context,p) &&
  [[-12,0],[12,0],[0,-12],[0,12]].every(([x,y])=>sourceDryLand(context,[p[0]+x,p[1]+y]));
}
function nearestDecoration(p,decorations){
 let nearest=Infinity;
 for(const t of decorations)nearest=Math.min(nearest,dst(p,[t.x,t.y]));
 return nearest;
}
function proposal(kind,seed,attempt,context,realRoads) {
 // A real route segment provides the only permitted infrastructure anchor.
 // When absent, do NOT conjure an inn/farm/shrine to imply a safe network.
 if(ROUTE_REQUIRED.has(kind)){
  if(!realRoads.length)return null;
  const line=pick(realRoads,seed+":"+kind+":route:"+attempt);
  const t=0.05+fractional(seed+":"+kind+":t:"+attempt)*0.9;
  const offset=kind==="roadside_inn"?16:kind==="farmstead"?44:kind==="watchtower"?55:31;
  const a=line[0],b=line[1],dx=b[0]-a[0],dy=b[1]-a[1];
  const mag=Math.hypot(dx,dy);
  if(mag<2)return null;
  const side=fractional(seed+":"+kind+":side:"+attempt)>0.5?1:-1;
  const d=offset*(0.78+fractional(seed+":"+kind+":dist:"+attempt)*0.45);
  return [round(a[0]+t*dx-side*dy/mag*d),round(a[1]+t*dy+side*dx/mag*d)];
 }
 return [
  round(55+fractional(seed+":"+kind+":x:"+attempt)*890),
  round(125+fractional(seed+":"+kind+":y:"+attempt)*780)
 ];
}
function suitable(kind,p,world,context,composite,used,realRoads){
 if(!clearDryLand(context,p)|| (context.parent_cell && !isOwnedDryLand(context,p)))return false;
 if((context.source_landmarks||[]).some(m=>dst(p,m.position)<58))return false;
 // Keep original burgs *exactly* where Azgaar says they are.
 if(context.source_burgs.some(b=>dst(p,b.local_position)<58))return false;
 if(used.some(q=>dst(p,q)<82))return false;
 const home=(context.source_burgs.find(b=>b.source_id===context.source_home_burg_id)?.local_position??context.space.home_local);
 const homeDist=dst(home,p),roadDist=routeDistance(p,realRoads);
 if(kind==="farmstead" && (homeDist>275||roadDist>85||nearOriginalHeight(world,context,p)>65))return false;
 if(kind==="roadside_inn" && (homeDist>350||roadDist>52))return false;
 if(kind==="watchtower" && (homeDist>460||roadDist>95))return false;
 if(kind==="shrine" && (homeDist>390||roadDist>75))return false;
 if(WILD.has(kind)&&homeDist<135)return false;
 if(HIGH_RELATED.has(kind) && !(nearOriginalHeight(world,context,p)>=60))return false;
 if(kind==="dangerous_woods" && nearestDecoration(p,composite.landscape?.trees||[])>85)return false;
 if(["ruins","ancient_stones","abandoned_camp"].includes(kind) && roadDist<35)return false;
 // A deserted camp or ruin may lie near an old wilderness trail, but is not
 // proof of patrolled or protected access.
 return true;
}
function validate(world,composite) {
 const context=composite?.source_context;
 if(world?.schemaVersion!==1||world.generator?.provider!=="azgaar"||
  composite?.provider?.mode!=="DECORATIONS_ONLY"||
  composite?.constraints?.source_water_mask!=="AZGAAR_LAND_MINUS_LAKES"||
  context?.schema_version!==1||context?.constraints?.shorelines!=="original_source_features"||
  !Array.isArray(context.source_burgs)||!Array.isArray(context.source_features))
  throw Error("Expected authoritative Azgaar local constrained composite");
 const burg=world.settlements.find(b=>b?.i===context.source_home_burg_id);
 if(context.source_home_burg_id!==null&&(!burg||burg.removed||burg.hidden||!Number.isFinite(burg.x)||!Number.isFinite(burg.y)))
  throw Error("Missing authoritative burg");
 if(context.parent_source_world_sha256.length!==64)throw Error("Missing immutable world ID");
 const original=context.source_burgs.find(b=>b.source_id===burg?.i);
 if(burg&&(!original||original.name!==burg.name || dst(original.world_position,[burg.x,burg.y])>0.001))
  throw Error("Hometown source coordinate or label mismatch");
 return {context,burg};
}
/** Entire output is a DEBUG/GENERATION LAYER. Never save it to an older v1
 * playthrough; opt-in migration from GAME-40 v1 is a separate future task. */
export function generateContextualSites(world,composite) {
 const {context,burg}=validate(world,composite);
 const seed="contextual-sites:v2|"+context.id;
 const routeAudit=auditSourceRoutes(context);
 const knownRoads=routes(routeAudit);
 const home=burg?{id:"burg:"+burg.i,kind:"hometown",
  label:String(burg.name||"Unnamed Burg"),position:[...context.space.home_local],
  provenance:"azgaar_burg",source_id:burg.i,knowledge:"discovered",
  description:"An original Azgaar settlement. Its detailed town layout is not yet generated.",
  detail_hook:{provider:"settlemaker",burg_id:burg.i},patrol_protection:"unverified"}:null;
 const result=home?[home]:[],used=home?[home.position]:[],taken=new Set(home?[home.label.toLowerCase()]:[]);
 const weighted=CATALOGUE.filter(([kind])=>{
  // Source conditions control *eligibility*, while deterministic seed
  // controls density. No fixed identical checklist in each biome.
  if(ROUTE_REQUIRED.has(kind)&&!knownRoads.length)return false;
  if(kind==="dangerous_woods" && !(composite.landscape?.trees?.length>0))return false;
  if(fractional(seed+":eligible:"+kind)<(kind==="farmstead"?0.10:kind==="ruins"?0.15:0.28))return false;
  return true;
 });
 for(const [kind,names] of weighted){
  if(result.length>=9)break;
  let candidate=null;
  for(let attempt=0;attempt<520;attempt++){
   const p=proposal(kind,seed,attempt,context,knownRoads);
   if(p&&suitable(kind,p,world,context,composite,used,knownRoads)) {candidate=p;break;}
  }
  if(!candidate)continue;
  used.push(candidate);
  // At most one location of each kind is generated in this model. Its ID
  // must not change when another kind is excluded for terrain or density.
  let label=pick(names,seed+":"+kind+":name");
  if(taken.has(label.toLowerCase()))label+=" "+kind;
  taken.add(label.toLowerCase());
  // Knowledge varies by place type and immutable context, not by list index.
  // Civilian infrastructure is more often known; remote ruins, caves and
  // dangers are usually rumours or hidden until actual exploration.
  const knowledgeRoll=fractional(seed+":knowledge:"+kind);
  const [knownThreshold,rumourThreshold]=({
   farmstead:[0.84,0.95],roadside_inn:[0.80,0.96],
   watchtower:[0.55,0.88],shrine:[0.48,0.87],
   ruins:[0.24,0.70],cave:[0.10,0.61],
   abandoned_camp:[0.16,0.64],ancient_stones:[0.20,0.73],
   dangerous_woods:[0.11,0.75],old_mine:[0.20,0.72]
  })[kind];
  const knowledge=knowledgeRoll<knownThreshold?"discovered":
   knowledgeRoll<rumourThreshold?"rumoured":"hidden";
  const id=context.id+":site:v2:"+kind;
  const isDungeon=["cave","old_mine","ruins"].includes(kind);
  result.push({id,kind,label,position:candidate,
   provenance:"game_generated_local_site",source_id:null,knowledge,
   description:({
    farmstead:"An inferred smallholding near a real route; not an Azgaar settlement.",
    roadside_inn:"An inferred roadside stop; road safety remains unknown.",
    watchtower:"A speculative watchpoint along a source road, not proof of patrols.",
    shrine:"A minor roadside shrine, generated for local exploration.",
    ruins:"Unmapped ruins, away from known settlements.",
    cave:"An inferred highland cave site; interior remains ungenerated.",
    old_mine:"Disused workings in source highland terrain.",
    dangerous_woods:"A suspicious woodland tract inferred from decorative forest.",
    ancient_stones:"Unexplained stones beyond the nearest settled area.",
    abandoned_camp:"Abandoned traces away from settled roads."
   })[kind],
   detail_hook:{provider:isDungeon?"dungeongen":"local_event",site_id:id},
   patrol_protection:"unverified"});
 }
 return {schema_version:2,site_generation_version:2,
  region_id:composite.id,source_context_id:context.id,
  source_world_sha256:context.parent_source_world_sha256,
  source_burg_id:burg?.i??null,
  placement:"SOURCE_CONSTRAINED_DERIVED_NOT_ORIGINAL_POI",
  source_routes:"actual_Azgaar_overland_route_segments",
  source_water:"original_Azgaar_land_and_lakes",
  route_consistency:{method:routeAudit.method,status:routeAudit.status,
   conflicts:routeAudit.conflicts,eligible_approach_segments:knownRoads.length},
  source_km:"UNCALIBRATED",
  migration:{from_site_generation_v1:"NOT_AUTOMATIC",existing_v1_states:"UNCHANGED",new_namespace:"site:v2"},
  sites:result};
}
/** Exact security semantics from GAME-40: names/IDs/positions of unknown
 * places never reach ordinary player-facing views, including SVG. */
export function contextualPlayerSiteView(layer,overrides={},debugReveal=false){
 const allowed=new Set(["hidden","rumoured","discovered","visited"]);
 const visible=[],rumours=[];
 for(const site of layer.sites||[]){
  const state=overrides[site.id]??site.knowledge;
  if(!allowed.has(state))throw Error("Invalid site knowledge override");
  if(debugReveal){visible.push({...site,knowledge:state,debug_only:state==="hidden"});continue;}
  if(state==="discovered"||state==="visited")visible.push({...site,knowledge:state});
  else if(state==="rumoured")rumours.push({knowledge:"rumoured",
   hint:"A "+site.kind.replaceAll("_"," ")+" is rumoured in the region."});
 }
 return {visible,rumours};
}
