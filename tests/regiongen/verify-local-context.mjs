#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile,access} from "node:fs/promises";
import {createHash} from "node:crypto";
import {buildLocalContext,toLocalPoint,fromLocalPoint} from "../../tools/regiongen/local-source-context.mjs";
const sha=s=>createHash("sha256").update(s).digest("hex");
const mock={schemaVersion:1,seed:"synthetic",
 generator:{provider:"azgaar",version:"1.153.1",upstreamCommit:"fixture"},
 map:{width:128,height:128,geography:[{i:1,type:"island",vertices:[0,1,2,3]}]},
 cells:{ids:[0,1,2],points:[[50,25],[55,25],[75,25]]},
 settlements:[{i:1,x:53,y:25,cell:0,name:"Origin"},{i:2,x:55,y:26,cell:1,name:"Neighbour"},
  {i:3,x:75,y:25,cell:2,name:"Outside"},{i:4,x:54,y:24,cell:1,name:"Hidden",hidden:true}],
 routes:[{i:1,group:"roads",points:[[43,25],[57,25]]},
  {i:2,group:"searoutes",points:[[53,14],[53,36]]},
  {i:3,group:"trails",points:[[45,22],[59,22]]}],
 rivers:[{i:1,cells:[0,1,2]}]};
const fingerprint=sha("world-fixture");
const sidecar={schema_version:1,source_world_sha256:fingerprint,source_seed:"synthetic",
 provider:{name:"azgaar",version:"1.153.1",upstream_commit:"fixture"},
 map:{width:128,height:128},
 vertex_coordinates:"original_pack.vertices.p",
 feature_vertex_ids:"canonical_world.map.geography[*].vertices",
 vertices:[[48,19],[62,19],[62,31],[48,31]]};
const context=buildLocalContext(mock,1,fingerprint,sidecar);
assert.equal(context.space.original_map_units,16);
assert.equal(context.space.physical_km,"UNCALIBRATED");
assert.equal(context.space.global_tile_compatibility,"distinct_from_64_unit_macro_source_tiles");
assert.equal(context.constraints.route_protection,"unverified");
assert.equal(context.constraints.bridges,"NOT_VERIFIED");
assert.equal(context.constraints.river_mouths,"NOT_RECONSTRUCTED");
assert.deepEqual(context.source_burgs.map(x=>x.source_id),[1,2]);
assert(context.source_features.some(x=>x.classification==="land_boundary"));
assert(context.source_routes.some(x=>x.classification==="land_road"));
assert(context.source_routes.some(x=>x.classification==="sea_lane"));
assert(context.source_routes.some(x=>x.classification==="trail"));
assert(context.source_rivers.every(x=>x.geometry.includes("APPROXIMATE")));
assert.deepEqual(context.generated_sites,[]);
assert.deepEqual(context.space.home_local,
 context.source_burgs.find(x=>x.source_id===1).local_position);
assert.deepEqual(fromLocalPoint(toLocalPoint([53,25],context.space.source_bounds),context.space.source_bounds),[53,25]);
assert.deepEqual(context,buildLocalContext(mock,1,fingerprint,sidecar));
assert.notEqual(context.id,buildLocalContext(mock,2,fingerprint,sidecar).id);
assert.throws(()=>buildLocalContext(mock,4,fingerprint,sidecar));
assert.throws(()=>buildLocalContext(mock,1,sha("different"),sidecar));
assert.equal(buildLocalContext(mock,1,fingerprint,null).constraints.shorelines,"UNAVAILABLE_NO_SIDECAR");
assert.equal(buildLocalContext(mock,1,fingerprint,null).source_features.length,0);
let examples=0;
for(const [stem,geometryFile] of [
 ["game-11-determinism","geography-game-11-determinism.json"],
 ["atlas-showcase","geography-atlas-showcase.json"]
]){
 const bytes=await readFile("tests/worldgen/fixtures/"+stem+".json");
 const world=JSON.parse(bytes),hash=sha(bytes);
 const geometry=JSON.parse(await readFile("tools/regiongen/.tmp/"+geometryFile,"utf8"));
 const eligible=world.settlements.filter(b=>b?.i>0&&!b.removed&&!b.hidden&&Number.isFinite(b.x)&&Number.isFinite(b.y));
 assert(eligible.length>=3,"Not enough real source homes");
 const categories=new Set(),ids=new Set();
 for(const b of eligible.slice(0,40)){
  const local=buildLocalContext(world,b.i,hash,geometry);
  assert(local.source_burgs.some(x=>x.source_id===b.i&&x.world_position[0]===b.x&&x.world_position[1]===b.y),
   "Hometown moved or lost: "+b.i);
  assert(!local.source_burgs.some(x=>world.settlements.find(b=>b?.i===x.source_id)?.hidden));
  assert(local.source_routes.every(r=>r.provenance==="original_azgaar_route_points"&&
    ["sea_lane","land_road","trail","source_route_unknown_type"].includes(r.classification)));
  assert(local.source_features.every(f=>f.provenance==="original_azgaar_pack_vertices"));
  assert(local.generated_sites.length===0,"Unexpected fabricated local POIs");
  assert(local.space.physical_km==="UNCALIBRATED");
  assert.deepEqual(local,buildLocalContext(world,b.i,hash,geometry),"Non-deterministic context "+b.i);
  ids.add(local.id);
  categories.add(local.source_features.map(f=>f.classification).sort().join(","));
  examples++;
 }
 assert(ids.size>=3,stem+" source towns did not produce unique contexts");
}
console.log("PASS: GAME-46 source-grounded local neighbourhoods, source types, identity, precision and sidecar validation; "+examples+" actual burg cases in two immutable worlds");
