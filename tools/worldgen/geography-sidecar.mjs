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
export function buildGeographySidecar(world,vertices,canonicalBytes) {
 if(world?.schemaVersion!==1 || world.generator?.provider!=="azgaar") throw Error("Expected Azgaar canonical world");
 if(!Array.isArray(world.map?.geography)||!Number.isFinite(world.map?.width)||!Number.isFinite(world.map?.height))
  throw Error("Missing source feature geography");
 if(!Array.isArray(vertices)||!vertices.length)throw Error("Missing Azgaar pack.vertices.p");
 if(typeof canonicalBytes!=="string"||!canonicalBytes.length)throw Error("Missing canonical world bytes");
 const positions=vertices.map((p,i)=>{
  if(!point(p)||p[0]<0||p[1]<0||p[0]>world.map.width||p[1]>world.map.height)
   throw Error("Bad Azgaar packed vertex position "+i);
  return [p[0],p[1]];
 });
 let polygons=0;
 for(const f of world.map.geography){
  if(!f||!Array.isArray(f.vertices)||!f.vertices.length)continue;
  if(f.vertices.length<3)throw Error("Malformed source feature vertices: "+f.i);
  polygons++;
  for(const id of f.vertices)
   if(!Number.isSafeInteger(id)||id<0||id>=positions.length)throw Error("Feature references missing vertex "+id);
 }
 if(!polygons)throw Error("No source coast/lake feature polygons exported");
 return {schema_version:GEOGRAPHY_SIDECAR_VERSION,
  source_world_sha256:sha256(canonicalBytes),
  provider:{name:"azgaar",version:world.generator.version,upstream_commit:world.generator.upstreamCommit},
  source_seed:world.seed,
  map:{width:world.map.width,height:world.map.height},
  vertex_coordinates:"original_pack.vertices.p",
  feature_vertex_ids:"canonical_world.map.geography[*].vertices",
  vertices:positions};
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
 if(!Array.isArray(positions)||!positions.length)throw Error("Sidecar missing vertex coordinates");
 for(let i=0;i<positions.length;i++)if(!point(positions[i])||
    positions[i][0]<0||positions[i][0]>world.map.width||
    positions[i][1]<0||positions[i][1]>world.map.height)throw Error("Malformed sidecar vertex "+i);
 for(const f of world.map.geography) {
  if(!f?.vertices?.length)continue;
  for(const id of f.vertices)
   if(!Number.isSafeInteger(id)||id<0||id>=positions.length)throw Error("Unresolved source shoreline vertex");
 }
 return positions;
}
