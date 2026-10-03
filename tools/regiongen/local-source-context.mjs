/**
 * GAME-46: versioned, source-authored neighbourhood context.
 *
 * A local view is a window within Azgaar's actual canvas, not the 64-unit
 * global audit tile or a 30 km Town Forge tile. Its width is intentionally
 * labelled in SOURCE MAP UNITS, not calibrated kilometres.
 * No Town Forge, save ID, provider seed, or hidden knowledge is changed.
 */
import {createHash} from "node:crypto";
import {checkGeographySidecar} from "../worldgen/geography-sidecar.mjs";
import {clipSegment,clipPolygon} from "./source-projection.mjs";
import {referenceNeighbourhoodBounds,REFERENCE_VERSION} from "./reference-scale.mjs";
export const LOCAL_CONTEXT_VERSION=1;
export const LOCAL_SPAN_SOURCE_UNITS=16;
export const LOCAL_DISPLAY_UNITS=1000;
const EPS=1e-8;
const fixed=x=>Math.round(x*1e6)/1e6;
const finite=x=>Number.isFinite(x);
const point=p=>Array.isArray(p)&&p.length>=2&&finite(p[0])&&finite(p[1]);
const inRect=(p,r)=>p[0]>=r.left-EPS&&p[0]<=r.right+EPS&&p[1]>=r.top-EPS&&p[1]<=r.bottom+EPS;
const distanceSquared=(a,b)=>(a[0]-b[0])**2+(a[1]-b[1])**2;
function sourceRect(world,center,span) {
 if(!finite(span)||span<=0||span>Math.min(world.map.width,world.map.height))
  throw Error("Invalid local source span");
 const x=Math.max(0,Math.min(world.map.width-span,center[0]-span/2));
 const y=Math.max(0,Math.min(world.map.height-span,center[1]-span/2));
 return {left:fixed(x),top:fixed(y),right:fixed(x+span),bottom:fixed(y+span)};
}
function linePieces(points,bounds) {
 const parts=[];
 for(let i=0;i<points.length-1;i++){
  const clipped=clipSegment(points[i],points[i+1],bounds);
  if(!clipped)continue;
  if(distanceSquared(clipped[0],clipped[1])<=EPS)continue;
  parts.push({source_segment:i,points:clipped});
 }
 return parts;
}
export function toLocalPoint(p,bounds){
 return [fixed((p[0]-bounds.left)*LOCAL_DISPLAY_UNITS/(bounds.right-bounds.left)),
         fixed((p[1]-bounds.top)*LOCAL_DISPLAY_UNITS/(bounds.bottom-bounds.top))];
}
export function fromLocalPoint(p,bounds) {
 return [fixed(bounds.left+p[0]*(bounds.right-bounds.left)/LOCAL_DISPLAY_UNITS),
         fixed(bounds.top+p[1]*(bounds.bottom-bounds.top)/LOCAL_DISPLAY_UNITS)];
}
function classifySourceLine(route){
 if(route.group==="searoutes")return "sea_lane";
 if(route.group==="trails")return "trail";
 if(route.group==="roads")return "land_road";
 return "source_route_unknown_type";
}
export function buildLocalContext(world,homeId,fingerprint,sidecar,span=LOCAL_SPAN_SOURCE_UNITS){
 if(world?.schemaVersion!==1 ||world.generator?.provider!=="azgaar"||
   !Array.isArray(world.settlements)||!Array.isArray(world.routes)||
   !Array.isArray(world.rivers)||!Array.isArray(world.map?.geography))
  throw Error("Invalid canonical Azgaar source");
 if(typeof fingerprint!=="string"||!/^[a-f0-9]{64}$/.test(fingerprint))
  throw Error("Invalid immutable world fingerprint");
 if(!Number.isSafeInteger(homeId)||homeId<=0)throw Error("Invalid home burg ID");
 const matches=world.settlements.filter(b=>b?.i===homeId);
 if(matches.length!==1 ||matches[0].hidden||matches[0].removed ||
    !finite(matches[0].x)||!finite(matches[0].y))throw Error("Missing/hidden source home burg");
 const home=matches[0];
 const reference=typeof span==="object"&&span!==null?span:null;
 if(reference && (reference.schema_version!==REFERENCE_VERSION||
    reference.certainty!=="ASSUMED_WORLD_RADIUS_NOT_GAME_CANON"||
    !reference.bounds))throw Error("Unverified physical projection reference");
 const bounds=reference?reference.bounds:sourceRect(world,[home.x,home.y],span);
 const validBurg=b=>b&&Number.isSafeInteger(b.i)&&b.i>0&&
    !b.hidden&&!b.removed&&finite(b.x)&&finite(b.y);
 const originalBurgs=world.settlements.filter(validBurg)
  .filter(b=>inRect([b.x,b.y],bounds))
  .sort((a,b)=>a.i-b.i)
  .map(b=>({source_id:b.i,source_cell_id:b.cell,name:b.name,
    world_position:[fixed(b.x),fixed(b.y)],local_position:toLocalPoint([b.x,b.y],bounds),
    provenance:"azgaar_burg"}));
 if(!originalBurgs.some(b=>b.source_id===homeId))throw Error("Home not inside its local view");
 const originalRoutes=[];
 for(const route of world.routes) {
  if(!Number.isSafeInteger(route?.i)||!Array.isArray(route.points))continue;
  if(route.points.some(p=>!point(p)))throw Error("Malformed canonical route");
  const pieces=linePieces(route.points,bounds);
  if(!pieces.length)continue;
  originalRoutes.push({source_id:route.i,classification:classifySourceLine(route),
    source_group:route.group||"unknown",provenance:"original_azgaar_route_points",
    segments:pieces.map(s=>({...s,local_points:s.points.map(p=>toLocalPoint(p,bounds))}))});
 }
 originalRoutes.sort((a,b)=>a.source_id-b.source_id);
 const rivers=[],cellMap=new Map();
 world.cells?.ids?.forEach((id,i)=>cellMap.set(id,i));
 for(const river of world.rivers) {
  if(!Number.isSafeInteger(river?.i)||!Array.isArray(river.cells))continue;
  const points=[];
  for(const id of river.cells){
   if(!cellMap.has(id))throw Error("Unknown canonical river cell "+id);
   const p=world.cells?.points?.[cellMap.get(id)];
   if(!point(p))throw Error("Malformed river cell coordinate");
   points.push([p[0],p[1]]);
  }
  const pieces=linePieces(points,bounds);
  if(pieces.length)rivers.push({source_id:river.i,
   geometry:"APPROXIMATE_CELL_CHAIN_NOT_ACTUAL_MEANDER",segments:pieces.map(s=>({...s,
    local_points:s.points.map(p=>toLocalPoint(p,bounds))}))});
 }
 rivers.sort((a,b)=>a.source_id-b.source_id);
 const features=[];
 if(sidecar){
  const vertices=checkGeographySidecar(world,sidecar,fingerprint);
  for(const f of world.map.geography){
   if(!f?.vertices?.length)continue;
   const original=f.vertices.map(i=>vertices[i]);
   const clipped=clipPolygon(original,bounds);
   if(clipped.length)features.push({source_id:f.i,
     classification:f.type==="lake"?"freshwater_lake":f.type==="island"?"land_boundary":"unclassified_source_feature",
     source_type:f.type,source_subtype:f.subtype??null,
     provenance:"original_azgaar_pack_vertices",
     local_polygon:clipped.map(p=>toLocalPoint(p,bounds))});
  }
 }
 features.sort((a,b)=>a.source_id-b.source_id);
 const version=reference?REFERENCE_VERSION:LOCAL_CONTEXT_VERSION;
 const sourceHash=createHash("sha256").update(JSON.stringify([fingerprint,homeId,bounds,version,
     ...(reference?[reference.hypothetical_square_km,reference.reference_radius_km]:[])])).digest("hex");
 return {
  schema_version:1,
  id:"local-source:v"+version+":"+sourceHash,
  parent_source_world_sha256:fingerprint,
  source_home_burg_id:homeId,
  space:reference?{
    kind:"hypothetical_globe_reference_window",version:REFERENCE_VERSION,
    original_map_units:reference.source_window_units,
    display_units:LOCAL_DISPLAY_UNITS,physical_km:"ASSUMED_NOT_CANON",
    angular_reference:reference,
    global_tile_compatibility:"distinct_from_64_unit_macro_source_tiles",
    source_bounds:bounds,home_local:toLocalPoint([home.x,home.y],bounds)
   }:{
    kind:"source_neighbourhood_window",version:LOCAL_CONTEXT_VERSION,
    original_map_units:span,display_units:LOCAL_DISPLAY_UNITS,
    physical_km:"UNCALIBRATED",global_tile_compatibility:"distinct_from_64_unit_macro_source_tiles",
    source_bounds:bounds,home_local:toLocalPoint([home.x,home.y],bounds)},
  constraints:{route_protection:"unverified",
    shorelines:sidecar?"original_source_features":"UNAVAILABLE_NO_SIDECAR",
    rivers:"APPROXIMATE_SOURCE_CELL_CHAIN",provider_interior:"NOT_CONSTRAINED",
    river_mouths:"NOT_RECONSTRUCTED",bridges:"NOT_VERIFIED"},
  source_burgs:originalBurgs,source_routes:originalRoutes,source_rivers:rivers,
  source_features:features,
  generated_sites:[] // GAME-40 site migration is explicitly out of scope
 };
}

/** Opt-in hypothesis ONLY: requires the caller to choose an assumed globe
 * radius in kilometres. Does not replace the existing v1 region or saves. */
export function buildReferenceLocalContext(world,homeId,fingerprint,sidecar,spanKm,assumedRadiusKm){
 const matches=world?.settlements?.filter(b=>b?.i===homeId)||[];
 if(matches.length!==1 ||matches[0]?.hidden||matches[0]?.removed ||
    !finite(matches[0]?.x)||!finite(matches[0]?.y))
  throw Error("Invalid source home for reference neighbourhood");
 const reference=referenceNeighbourhoodBounds(world,[matches[0].x,matches[0].y],
    spanKm,assumedRadiusKm);
 const result=buildLocalContext(world,homeId,fingerprint,sidecar,reference);
 // This is a crop from a *macro* polygon/route dataset. At 30 hypothetical
 // kilometres a window often covers fewer than four Azgaar cell centres:
 // never misrepresent it as detailed, walkable or high-resolution geography.
 const bounds=reference.bounds;
 const cellsInWindow=(world.cells?.points||[]).filter(p=>validPointForWindow(p,bounds)).length;
 result.space.source_cell_centres_in_window=cellsInWindow;
 result.constraints.local_resolution=cellsInWindow<4?
    "COARSE_MACRO_GEOGRAPHY_NO_WALKABLE_MICRO_DETAIL":"SOURCE_CELL_SAMPLES_ONLY";
 return result;
}
function validPointForWindow(p,b){
 return Array.isArray(p)&&p.length>=2&&finite(p[0])&&finite(p[1])&&
    p[0]>=b.left&&p[0]<=b.right&&p[1]>=b.top&&p[1]<=b.bottom;
}
