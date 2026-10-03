/**
 * GAME-49: explicit source-vs-inference contract. No coordinates are invented
 * or promoted to "source exact" by small-scale SVG projection.
 */
import {createHash} from "node:crypto";
export const SOURCE_AUTHORITY_VERSION=1;
const finite=x=>Number.isFinite(x);
const coord=p=>Array.isArray(p)&&p.length===2&&p.every(finite);
const SHA=/^[0-9a-f]{64}$/;
const seal=v=>createHash("sha256").update(JSON.stringify(v)).digest("hex");
function assertContext(world,ctx,fingerprint){
 if(world?.schemaVersion!==1||world.generator?.provider!=="azgaar"||
  !SHA.test(fingerprint)||ctx?.schema_version!==1||
  ctx.parent_source_world_sha256!==fingerprint||
  !["source_neighbourhood_window","hypothetical_globe_reference_window"].includes(ctx.space?.kind)||
  !Array.isArray(ctx.source_burgs)||!Array.isArray(ctx.source_routes)||
  !Array.isArray(ctx.source_rivers)||!Array.isArray(ctx.source_features))throw Error("Invalid Azgaar source constraint provenance");
 const home=world.settlements?.filter(s=>s?.i===ctx.source_home_burg_id);
 if(home?.length!==1||home[0].removed||home[0].hidden||
  !coord([home[0].x,home[0].y]))throw Error("Missing original source burg");
 const original=ctx.source_burgs.find(s=>s.source_id===home[0].i);
 if(!original||original.name!==home[0].name||
  !coord(original.world_position) ||
  Math.hypot(original.world_position[0]-home[0].x,
   original.world_position[1]-home[0].y)>1e-5)
  throw Error("Original burg anchor was moved or renamed");
 const ref=ctx.space.angular_reference;
 if(ctx.space.kind==="hypothetical_globe_reference_window" &&
  (!ref||!finite(ref.reference_radius_km)||!finite(ref.hypothetical_square_km)||
   ctx.space.physical_km!=="ASSUMED_NOT_CANON"))throw Error("Unlabelled radius assumption");
 if(ctx.space.kind==="source_neighbourhood_window"&&ctx.space.physical_km!=="UNCALIBRATED")
  throw Error("Legacy source coordinates cannot be treated as physical km");
}
function projections(ctx){
 // Coarse source original geometry remains coarse regardless of the number
 // of SVG/map coordinates used to display it.
 const towns=ctx.source_burgs.map(b=>({
  id:"burg:"+b.source_id,source_burg_id:b.source_id,
  name:b.name,local_position:b.local_position,
  source_position:b.world_position,truth:"EXACT_ORIGINAL_MACRO_ANCHOR"}));
 const routes=ctx.source_routes.map(r=>({
  id:"source-route:"+r.source_id,group:r.source_group,
  classification:r.classification,
  original_line_source:"original_azgaar_route_points",
  truth:"EXACT_ORIGINAL_MACRO_POLYLINE_NOT_FINE_ROAD",
  segments:r.segments.map(s=>({source_segment:s.source_segment,
   local_points:s.local_points,source_world_points:s.points}))}));
 const water=ctx.source_features.map(f=>({
  id:"feature:"+f.source_id,classification:f.classification,
  source_polygon:f.local_polygon,
  truth:"EXACT_ORIGINAL_MACRO_VERTEX_POLYGON_NOT_FINE_SHORELINE"}));
 const rivers=ctx.source_rivers.map(r=>({
  id:"river:"+r.source_id,source_id:r.source_id,
  truth:"APPROXIMATE_CELL_CENTRE_CHAIN_NOT_CHANNEL",
  segments:r.segments.map(s=>({source_segment:s.source_segment,
   local_points:s.local_points}))}));
 return {towns,routes,water,rivers};
}
export function buildSourceAuthority(world,ctx,fingerprint,decorated=null){
 assertContext(world,ctx,fingerprint);
 if(decorated!==null &&
   (decorated?.source_context?.id!==ctx.id||
    decorated?.provider?.mode!=="DECORATIONS_ONLY"||
    decorated?.source_context?.parent_source_world_sha256!==fingerprint))
  throw Error("Refusing decorative output from a different source window");
 const original=projections(ctx);
 const cellSamples=ctx.space.source_cell_centres_in_window??null;
 const sparse=ctx.space.kind==="hypothetical_globe_reference_window" && (cellSamples===null||cellSamples<4);
 const inferred=decorated?{
  from:"town-forge",trust:"INFERRED_DECORATION_ONLY",
  trees:(decorated.landscape?.trees||[]).map(t=>({
   x:t.x,y:t.y,visual_type:t.type,source_authority:false})),
  ridge_marks:(decorated.landscape?.ridges||[]).map(r=>({
   x:r.x,y:r.y,visual_type:r.type,source_authority:false}))
 }:{from:"none",trust:"NOT_GENERATED",trees:[],ridge_marks:[]};
 const unknown={
  source_radius_km:ctx.space.physical_km==="UNCALIBRATED"?
   "NOT_ESTABLISHED": "HYPOTHETICAL_REFERENCE_RADIUS_NOT_CANON",
  walkable_local_paths:"UNKNOWN_UNTIL_FINE_PROVIDER_INTEGRATION",
  safe_or_patrolled_routes:"NOT_VERIFIED",
  exact_river_meanders:"NOT_EXPORTED",
  bridges_fords_and_road_barriers:"NOT_VERIFIED",
  coastal_ramps_and_actual_ports:"NOT_VERIFIED",
  local_footstep_water_mask:sparse?"UNRESOLVED_AT_MACRO_SAMPLE_DENSITY":
   "MACRO_FEATURE_ONLY_NOT_WALKABLE",
  fine_scale_cross_tile_seams:"NOT_ESTABLISHED",
  v1_game40_save_conversion:"NOT_AUTOMATIC",
  provenance:"unknown_is_not_safe"
 };
 const identity={schema_version:SOURCE_AUTHORITY_VERSION,
  source_world_sha256:fingerprint,
  origin_source_burg_id:ctx.source_home_burg_id,
  source_context_id:ctx.id,source_space_kind:ctx.space.kind};
 const assumption=ctx.space.angular_reference?{
  status:"HYPOTHETICAL_NOT_CANON",
  reference_radius_km:ctx.space.angular_reference.reference_radius_km,
  requested_square_km:ctx.space.angular_reference.hypothetical_square_km,
  source_cell_samples:cellSamples}:{
  status:"UNCALIBRATED_SOURCE_UNITS",
  source_window_units:ctx.space.original_map_units};
 return {schema_version:SOURCE_AUTHORITY_VERSION,
  id:"source-authority:v1:"+seal(identity),
  identity,assumption,
  source_macro:{
   scale:"ORIGINAL_AZGAAR_CANVAS_NOT_MICRO_EXACT",
   towns:original.towns,routes:original.routes,
   feature_polygons:original.water
  },
  derived_approximate:{rivers:original.rivers,
   elevations:"SOURCE_CELL_HEIGHTS_COARSE",
   biomes:"SOURCE_CELL_BIOMES_COARSE"},
  inferred_fine_detail:inferred,
  unknown,
  flags:{sparse_source_samples:sparse,
   reliable_fine_road_geometry:false,
   reliable_micro_shoreline:false,
   travel_safety_known:false}};
}
