/**
 * GAME-44 source data QA: original roads and source water polygons sometimes
 * disagree near coasts/lakes. Preserve Azgaar geometry/IDs, surface conflicts
 * and refuse to anchor *new game-owned sites* to inconsistent route segments.
 */
import {sourceDryLand} from "./compose-local-region.mjs";
const point=p=>Array.isArray(p)&&p.length===2&&p.every(Number.isFinite);
const steps=[0.06,0.18,0.32,0.5,0.68,0.82,0.94];
const samples=([a,b])=>steps.map(t=>[a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t]);
function entry(id,group,index,geometry) {
 return {source_route_id:id,source_route_class:group,
  source_segment:index,problem:geometry,
  significance:"SOURCE_GEOMETRY_CLASSIFICATION_INCONSISTENT_NOT_A_BRIDGE_OR_SAFE_ROUTE"};
}
export function auditSourceRoutes(context) {
 if(context?.constraints?.shorelines!=="original_source_features")
  throw Error("Source coastline sidecar required to audit route consistency");
 const conflicts=[],trustedApproaches=[];
 for(const route of context.source_routes||[]) {
  for(const segment of route.segments||[]) {
   const line=segment.local_points;
   if(!Array.isArray(line)||line.length!==2||!line.every(point))
    throw Error("Malformed source route segment");
   const observations=samples(line).map(p=>sourceDryLand(context,p));
   const land=observations.filter(Boolean).length;
   const sea=observations.length-land;
   const classification=route.classification;
   if(classification==="sea_lane"){
    if(land>0)conflicts.push(entry(route.source_id,classification,segment.source_segment,
      "SEA_ROUTE_INTERSECTS_SOURCE_LAND"));
   } else if(classification==="land_road"||classification==="trail"){
    if(sea>0)conflicts.push(entry(route.source_id,classification,segment.source_segment,
      "OVERLAND_ROUTE_INTERSECTS_SOURCE_WATER"));
    // Short and coarse shoreline segments are never promoted to verified
    // access just because their endpoint happens to touch dry land.
    if(sea===0)trustedApproaches.push({
     source_route_id:route.source_id,source_segment:segment.source_segment,
     classification,local_points:line
    });
   }
 }
 }
 return {schema_version:1,method:"7_intermediate_source_landmask_samples",
  status:"DIAGNOSTIC_ONLY_NOT_PHYSICAL_ACCESS_PROOF",conflicts,trustedApproaches};
}
