/**
 * GAME-39: optional world-geography coordinate sidecar.
 * Azgaar's canonical map.geography already retains source vertex IDs,
 * but excludes pack.vertices.p; export just that missing, source-owned table.
 * No invented coastlines, lake/ocean guesses or world fixture edits.
 */
import {createHash} from "node:crypto";

export const GEOGRAPHY_SIDECAR_VERSION = 1;
const point=p=>Array.isArray(p)&&p.length===2&&p.every(Number.isFinite);
const sha256=bytes=>createHash("sha256").update(bytes).digest("hex");
// The table is the ORIGINAL Voronoi graph, not a rectangle-clipped drawing.
// Boundary pseudo-points can produce finite circumcentres outside the canvas.
// Clipping belongs to source-projection / local-source-context, never this table.
function validateGeometry(world,positions,cellVertices=null) {
 if(world?.schemaVersion!==1||world.generator?.provider!=="azgaar"||
    !Array.isArray(world.map?.geography)||!Number.isFinite(world.map.width)||world.map.width<=0||
    !Number.isFinite(world.map.height)||world.map.height<=0)throw Error("Invalid Azgaar geometry source");
 if(!Array.isArray(positions)||!positions.length)throw Error("Missing Azgaar vertex coordinates");
 positions.forEach((p,i)=>{if(!point(p))throw Error(`Malformed Azgaar vertex ${i}: expected two finite coordinates`)});
 const polygon=(ids,label,centre=null)=>{
  if(!Array.isArray(ids)||ids.length<3||new Set(ids).size!==ids.length)throw Error("Malformed "+label+" polygon");
  const points=ids.map(id=>{
   if(!Number.isSafeInteger(id)||id<0||id>=positions.length)throw Error(label+" references missing vertex "+id);
   return positions[id];
  });
  // Translate before summation to avoid cancellation in tiny far-origin cells.
  const origin=points[0];let area=0,orientation=0;
  for(let i=0;i<points.length;i++){
   const a=points[i],b=points[(i+1)%points.length];
   area+=(a[0]-origin[0])*(b[1]-origin[1])-(b[0]-origin[0])*(a[1]-origin[1]);
   if(centre){
    const cross=(b[0]-a[0])*(centre[1]-a[1])-(b[1]-a[1])*(centre[0]-a[0]);
    if(!Number.isFinite(cross))throw Error("Invalid "+label+" polygon arithmetic");
    if(Math.abs(cross)>1e-8){const sign=Math.sign(cross);if(orientation&&orientation!==sign)throw Error("Invalid "+label+" polygon around source centre");orientation=sign;}
   }
  }
  if(!Number.isFinite(area)||Math.abs(area)<1e-8)throw Error("Degenerate "+label+" polygon");
  // Reject proper self-intersections without treating legitimate collinear
  // shoreline detail as corrupt. Broad-phase x/y intervals keep long coasts cheap.
  const edges=points.map((a,i)=>{const b=points[(i+1)%points.length];return {a,b,i,left:Math.min(a[0],b[0]),right:Math.max(a[0],b[0]),top:Math.min(a[1],b[1]),bottom:Math.max(a[1],b[1])}}).sort((a,b)=>a.left-b.left);
  let active=[];
  const cross=(a,b,c)=>(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);
  for(const edge of edges){
   active=active.filter(other=>other.right>=edge.left);
   for(const other of active){
    if(Math.abs(edge.i-other.i)===1||Math.abs(edge.i-other.i)===points.length-1||other.bottom<edge.top||edge.bottom<other.top)continue;
    if(cross(edge.a,edge.b,other.a)*cross(edge.a,edge.b,other.b)<-1e-16&&
       cross(other.a,other.b,edge.a)*cross(other.a,other.b,edge.b)<-1e-16)throw Error("Self-intersecting "+label+" polygon");
   }
   active.push(edge);
  }
 };
 let features=0;
 for(const f of world.map.geography){
  if(f?.vertices!==undefined&&!Array.isArray(f.vertices))throw Error("Malformed source feature vertices: "+f.i);
  if(!f||!Array.isArray(f.vertices)||!f.vertices.length)continue;
  polygon(f.vertices,"feature "+f.i);features++;
 }
 if(!features)throw Error("No source coast/lake feature polygons exported");
 // Feature-only v1 sidecars remain supported. When supplied, every real cell
 // must retain a valid ring enclosing its source point, including edge cells.
 if(cellVertices!==null){
  if(!Array.isArray(cellVertices)||cellVertices.length!==world.cells?.ids?.length||
     world.cells.points?.length!==cellVertices.length)throw Error("Missing original Azgaar cell geometry");
  cellVertices.forEach((ids,i)=>{
   if(!point(world.cells.points[i]))throw Error("Malformed source cell centre "+i);
   polygon(ids,"cell "+world.cells.ids[i],world.cells.points[i]);
  });
 }
}
export function buildGeographySidecar(world,vertices,canonicalBytes,cellVertices=null) {
 if(world?.schemaVersion!==1 || world.generator?.provider!=="azgaar") throw Error("Expected Azgaar canonical world");
 if(!Array.isArray(world.map?.geography)||!Number.isFinite(world.map?.width)||!Number.isFinite(world.map?.height))
  throw Error("Missing source feature geography");
 if(!Array.isArray(vertices)||!vertices.length)throw Error("Missing Azgaar pack.vertices.p");
 if(typeof canonicalBytes!=="string"||!canonicalBytes.length)throw Error("Missing canonical world bytes");
 validateGeometry(world,vertices,cellVertices);
 const positions=vertices.map(p=>[p[0],p[1]]);
 return {schema_version:GEOGRAPHY_SIDECAR_VERSION,
  source_world_sha256:sha256(canonicalBytes),
  provider:{name:"azgaar",version:world.generator.version,upstream_commit:world.generator.upstreamCommit},
  source_seed:world.seed,
  map:{width:world.map.width,height:world.map.height},
  vertex_coordinates:"original_pack.vertices.p",
  feature_vertex_ids:"canonical_world.map.geography[*].vertices",
  vertices:positions,
  ...(cellVertices?{cell_vertex_ids:cellVertices,cell_geometry:"original_pack.cells.v"}:{})};
}

export function checkGeographySidecar(world,sidecar,fingerprint) {
 if(sidecar?.schema_version!==GEOGRAPHY_SIDECAR_VERSION||
    sidecar.vertex_coordinates!=="original_pack.vertices.p"||
    sidecar.feature_vertex_ids!=="canonical_world.map.geography[*].vertices"||
    sidecar.source_world_sha256!==fingerprint||
    sidecar.provider?.name!=="azgaar"||
    sidecar.provider.version!==world.generator.version||
    sidecar.provider.upstream_commit!==world.generator.upstreamCommit||
    sidecar.source_seed!==world.seed||
    sidecar.map?.width!==world.map.width||sidecar.map?.height!==world.map.height)
  throw Error("Geography sidecar does not match immutable canonical world");
 const positions=sidecar.vertices;
 if(sidecar.cell_vertex_ids!==undefined&&sidecar.cell_geometry!=="original_pack.cells.v")throw Error("Unsupported source cell geometry");
 validateGeometry(world,positions,sidecar.cell_vertex_ids??null);
 return positions;
}
