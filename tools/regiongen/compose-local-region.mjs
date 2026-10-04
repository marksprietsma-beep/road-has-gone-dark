/**
 * GAME-47 — Town Forge is a *decorator*, never a replacement world generator.
 * True Burgs, land/lake polygons and route positions always come from Azgaar.
 * No source world facts, playthrough data or legacy region/site IDs are mutated.
 */
import {createHash} from "node:crypto";

const rounded=n=>Math.round(n*1000)/1000;
const close=(a,b,r)=>Math.hypot(a[0]-b[0],a[1]-b[1])<r;
export function insidePolygon([x,y],poly) {
 if(!Array.isArray(poly)||poly.length<3)return false;
 // Boundary points are included so coast settlements are not discarded.
 let inside=false;
 for(let i=0,j=poly.length-1;i<poly.length;j=i++){
  const a=poly[j],b=poly[i];
  const dx=b[0]-a[0],dy=b[1]-a[1];
  const cross=(x-a[0])*dy-(y-a[1])*dx;
  if(Math.abs(cross)<0.001 && x>=Math.min(a[0],b[0])-0.001 &&
      x<=Math.max(a[0],b[0])+0.001 && y>=Math.min(a[1],b[1])-0.001 &&
      y<=Math.max(a[1],b[1])+0.001)return true;
  if((a[1]>y)!==(b[1]>y) && x<(dx*(y-a[1])/(dy||1e-15)+a[0]))inside=!inside;
 }
 return inside;
}
export function sourceDryLand(context,p) {
 if(!Array.isArray(p)||p.length!==2||p.some(n=>!Number.isFinite(n)))return false;
 if(p[0]<0||p[1]<0||p[0]>1000||p[1]>1000)return false;
 if(context.constraints?.shorelines!=="original_source_features")return false;
 const features=context.source_features||[];
 const land=features.some(f=>f.classification==="land_boundary"&&insidePolygon(p,f.local_polygon));
 const lake=features.some(f=>f.classification==="freshwater_lake"&&insidePolygon(p,f.local_polygon));
 return land&&!lake;
}
function dryWithClearance(context,p,margin) {
 if(!sourceDryLand(context,p))return false;
 for(const [dx,dy] of [[margin,0],[-margin,0],[0,margin],[0,-margin]])
  if(!sourceDryLand(context,[p[0]+dx,p[1]+dy]))return false;
 return true;
}
function nearRoute(context,p,radius) {
 const limit=radius*radius;
 for(const route of context.source_routes||[]){
  if(route.classification==="sea_lane")continue;
  for(const segment of route.segments||[]){
   const [a,b]=segment.local_points;
   const dx=b[0]-a[0],dy=b[1]-a[1];
   const k=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy||1)));
   if((p[0]-(a[0]+k*dx))**2+(p[1]-(a[1]+k*dy))**2<limit)return true;
  }
 }
 return false;
}
function stylisticLandmarkAllowed(context,p){
 if(!dryWithClearance(context,p,10))return false;
 if(context.source_burgs.some(b=>close(b.local_position,p,36)))return false;
 if(nearRoute(context,p,13))return false;
 // The river centreline is only a source-cell approximation; avoid drawing
 // tree symbols over its indicated corridor, but never claim a true bank.
 for(const river of context.source_rivers||[])for(const seg of river.segments||[]){
  const [a,b]=seg.local_points;
  const dx=b[0]-a[0],dy=b[1]-a[1];
  const t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy||1)));
  if(Math.hypot(p[0]-(a[0]+dx*t),p[1]-(a[1]+dy*t))<13)return false;
 }
 return true;
}
function finitePoly(points) {
 return Array.isArray(points)&&points.length>=3&&points.every(p=>
  Array.isArray(p)&&p.length===2&&p.every(Number.isFinite));
}
function getTerrainClass(world,context,p) {
 const bounds=context.space.source_bounds;
 const actual=[bounds.left+p[0]*(bounds.right-bounds.left)/1000,
               bounds.top+p[1]*(bounds.bottom-bounds.top)/1000];
 let min=Infinity,near=-1;
 for(let i=0;i<(world.cells?.points?.length||0);i++){
  const point=world.cells.points[i];
  if(!Array.isArray(point)||point.length!==2)continue;
  const d=(point[0]-actual[0])**2+(point[1]-actual[1])**2;
  if(d<min){min=d;near=i;}
 }
 const height=world.cells?.heights?.[near],biome=world.cells?.biome?.[near];
 return {height:typeof height==="number"?height:null,biome:typeof biome==="number"?biome:null};
}
function seedFraction(seed,ix,iy,variant=0) {
 // Stable, non-cryptographic grid jitter; independent of provider RNG state.
 let n=2166136261;
 for(const ch of seed+":"+ix+":"+iy+":"+variant){n^=ch.charCodeAt(0);n=Math.imul(n,16777619);}
 return ((n>>>0)%100000)/100000;
}
export function composeLocalRegion(world,context,townForge) {
 if(context?.schema_version!==1||context.space?.kind!=="source_neighbourhood_window"||
   context.constraints?.shorelines!=="original_source_features")
  throw Error("Source geometry sidecar is mandatory; cannot infer valid dry land");
 if(townForge?.provider?.name!=="town-forge"||townForge.source?.world_sha256!==context.parent_source_world_sha256||
    townForge.source?.burg_id!==context.source_home_burg_id||townForge.schema_version!==1)
  throw Error("Town Forge preview is from the wrong immutable world or home");
 if(context.source_home_burg_id!==null&&!context.source_burgs.some(b=>b.source_id===context.source_home_burg_id))
  throw Error("Missing original Azgaar hometown");
 // The original provider-generated roads/water are deliberately excluded.
 const treeCandidates=[],hills=[],forestPolys=townForge.geometry?.forests||[];
 const seed=context.id;
 for(let i=0;i<forestPolys.length;i++){
  const poly=forestPolys[i];if(!finitePoly(poly))throw Error("Town Forge forest polygon invalid");
  const xs=poly.map(p=>p[0]),ys=poly.map(p=>p[1]);
  const left=Math.max(16,Math.min(...xs)),right=Math.min(984,Math.max(...xs));
  const top=Math.max(16,Math.min(...ys)),bottom=Math.min(984,Math.max(...ys));
  for(let x=Math.ceil(left/26)*26;x<right;x+=26)for(let y=Math.ceil(top/26)*26;y<bottom;y+=26){
   const p=[rounded(x+(seedFraction(seed,x,y,1)-.5)*10),
            rounded(y+(seedFraction(seed,x,y,2)-.5)*10)];
   if(!insidePolygon(p,poly)||!stylisticLandmarkAllowed(context,p))continue;
   const terrain=getTerrainClass(world,context,p);
   // Non-forest biome codes must not turn into dense forest merely because
   // Town Forge put a blob there. Unsupported biomes stay sparse.
   const woodland=[5,6,7,8,9].includes(terrain.biome);
   const chance=woodland?0.84:([1,2,10,11].includes(terrain.biome)?0.12:0.44);
   if(seedFraction(seed,x,y,3)>chance)continue;
   treeCandidates.push({x:p[0],y:p[1],
    size:rounded(7+seedFraction(seed,x,y,4)*4),
    type:woodland?"forest":"scattered_trees",
    provenance:"town_forge_decoration_filtered_by_azgaar_land_and_biome"});
  }
 }
 for(const line of townForge.geometry?.ridges||[]) {
  if(!Array.isArray(line)||line.length<2)continue;
  for(let i=0;i<line.length;i+=Math.max(1,Math.floor(line.length/14))){
   const p=line[i],terrain=getTerrainClass(world,context,p);
   if(!(terrain.height>=68)||!stylisticLandmarkAllowed(context,p))continue;
   hills.push({x:rounded(p[0]),y:rounded(p[1]),
    type:"highland_illustration",provenance:"town_forge_shape_nearest_azgaar_cell_height"});
  }
 }
 // Use deterministic *spatial thinning*, not the first N scanned points:
 // a hard cap unfairly filled the top-left first and made every world 220 trees.
 const trees=treeCandidates.filter(t=>seedFraction(seed,t.x,t.y,7)<0.25)
   .sort((a,b)=>a.y-b.y||a.x-b.x).slice(0,140);
 const ridges=hills.slice(0,55);
 // We never expose "townForge.geometry.roads"/water: this is not a road network.
 const digest=createHash("sha256").update(context.id+"|"+townForge.id+"|v1").digest("hex");
 return {schema_version:1,id:"constrained-decorative:v1:"+digest,
  source_context:context,
  provider:{name:"town-forge",version:townForge.provider.version,
    mode:"DECORATIONS_ONLY",legacy_provider_region_id:townForge.id},
  landscape:{trees,ridges,
    counts:{tree_candidates:treeCandidates.length,tree_displayed:trees.length,
     ridge_displayed:ridges.length},
    source_routes_authoritative:true,
    procedural_roads_used:false,procedural_water_used:false},
  constraints:{physical_km:"UNCALIBRATED",safe_roads:"UNVERIFIED",
    river_mouths:"NOT_RECONSTRUCTED",
    local_sites:"NOT_MIGRATED",
    source_water_mask:"AZGAAR_LAND_MINUS_LAKES",
    decoration_authority:"NONE",
    terrain_reconstruction:"ILLUSTRATIVE_NOT_FULLY_CONSTRAINED"}};
}
