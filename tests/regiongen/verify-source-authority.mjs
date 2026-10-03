#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {buildLocalContext,buildReferenceLocalContext} from "../../tools/regiongen/local-source-context.mjs";
import {buildSourceAuthority} from "../../tools/regiongen/source-authority.mjs";
const sha=b=>createHash("sha256").update(b).digest("hex");
const layers=new Set();
let checked=0,referenceSparse=0;
for(const stem of ["game-11-determinism","atlas-showcase"]){
 const bytes=await readFile("tests/worldgen/fixtures/"+stem+".json");
 const world=JSON.parse(bytes),hash=sha(bytes);
 const sidecar=JSON.parse(await readFile("tools/regiongen/.tmp/geography-"+stem+".json","utf8"));
 const homes=world.settlements.filter(b=>b?.i>0&&!b.removed&&!b.hidden&&Number.isFinite(b.x)&&Number.isFinite(b.y)&&
  Math.abs(world.map.bounds.latN-b.y*world.map.bounds.latT/world.map.height)<70);
 assert(homes.length>3,stem+" lacks non-polar original towns");
 for(const home of homes.slice(0,3)){
  const legacy=buildLocalContext(world,home.i,hash,sidecar);
  const reference=buildReferenceLocalContext(world,home.i,hash,sidecar,30,6371.0088);
  assert.notEqual(legacy.id,reference.id);
  for(const ctx of [legacy,reference]){
   const result=buildSourceAuthority(world,ctx,hash);
   assert.deepEqual(result,buildSourceAuthority(world,ctx,hash),"Non-deterministic spatial authority contract");
   assert(result.id.startsWith("source-authority:v1:"));
   assert.equal(result.identity.origin_source_burg_id,home.i);
   assert.equal(result.source_macro.scale,"ORIGINAL_AZGAAR_CANVAS_NOT_MICRO_EXACT");
   assert(result.source_macro.towns.some(b=>b.source_burg_id===home.i&&
     b.source_position[0]===home.x&&b.source_position[1]===home.y));
   assert(result.source_macro.routes.every(r=>r.truth==="EXACT_ORIGINAL_MACRO_POLYLINE_NOT_FINE_ROAD"));
   assert(result.source_macro.feature_polygons.every(f=>f.truth==="EXACT_ORIGINAL_MACRO_VERTEX_POLYGON_NOT_FINE_SHORELINE"));
   assert(result.derived_approximate.rivers.every(r=>r.truth==="APPROXIMATE_CELL_CENTRE_CHAIN_NOT_CHANNEL"));
   assert.equal(result.flags.reliable_fine_road_geometry,false);
   assert.equal(result.flags.travel_safety_known,false);
   assert.equal(result.inferred_fine_detail.trust,"NOT_GENERATED");
   assert.equal(result.unknown.bridges_fords_and_road_barriers,"NOT_VERIFIED");
   assert.equal(result.unknown.v1_game40_save_conversion,"NOT_AUTOMATIC");
   assert(!JSON.stringify(result).includes('"safe_route":true'));
   const fail=structuredClone(ctx);fail.source_burgs[0].name+=" (fabricated)";
   assert.throws(()=>buildSourceAuthority(world,fail,hash));
   assert.throws(()=>buildSourceAuthority(world,ctx,sha("wrong world")));
   const fake={provider:{mode:"DECORATIONS_ONLY"},source_context:ctx,landscape:{
    procedural_roads_used:false,procedural_water_used:false,
    trees:[{x:210,y:320,type:"forest"}],ridges:[{x:300,y:300,type:"illustration"}]}};
   const withArt=buildSourceAuthority(world,ctx,hash,fake);
   assert.equal(withArt.inferred_fine_detail.trees[0].source_authority,false);
   assert.equal(withArt.inferred_fine_detail.ridge_marks[0].source_authority,false);
   const forbidden=structuredClone(fake);forbidden.landscape.procedural_roads_used=true;
   assert.throws(()=>buildSourceAuthority(world,ctx,hash,forbidden));
   layers.add(result.identity.source_space_kind);
   if(result.flags.sparse_source_samples)referenceSparse++;
   checked++;
  }
 }
}
assert.deepEqual([...layers].sort(),["hypothetical_globe_reference_window","source_neighbourhood_window"]);
assert(referenceSparse>=2,"Small reference views were not recognised as macro-sparse");
console.log("PASS: GAME-49 exact macro facts, approximate/inferred/unknown boundaries, 12 real source contexts, "+referenceSparse+" sparse hypothetical micro views; no invented protected roads");
