#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {sampleInferredFineTerrain,buildInferredFineTerrain} from "../../tools/regiongen/inferred-fine-terrain.mjs";
import {renderInferredFineSvg} from "../../tools/regiongen/render-inferred-fine.mjs";
const sha=s=>createHash("sha256").update(s).digest("hex");
const dimensions=new Set(),landTotals=[],forestRanges=[],heightRanges=[];
for(const stem of ["game-11-determinism","atlas-showcase"]){
 const worldBytes=await readFile("tests/worldgen/fixtures/"+stem+".json");
 const world=JSON.parse(worldBytes),fingerprint=sha(worldBytes),contexts=[];
 for(const kind of ["shore","river","highland"]){
  const folder="tools/regiongen/.tmp/";
  const context=JSON.parse(await readFile(folder+"reference-"+stem+"-"+kind+".json"));
  const model=JSON.parse(await readFile(folder+"authority-"+stem+"-"+kind+".json"));
  const output=JSON.parse(await readFile(folder+"fine-"+stem+"-"+kind+".json"));
  const svg=await readFile(folder+"fine-"+stem+"-"+kind+".svg","utf8");
  contexts.push(context);
  assert.deepEqual(buildInferredFineTerrain(world,context,fingerprint),output,
    "Inference field must be reproducible and seeded from world, not UI state");
  assert(svg.startsWith("<svg")&&svg.includes('data-provenance="inferred-only"'));
  assert(svg.includes('mask="url(#exact-macro-land)"'),"Terrain was allowed into source water");
  assert(!svg.includes('bridge') || svg.includes("Unknown"),"Visual generated verified crossing");
  assert(svg.includes("not surveyed")&&svg.includes("not a canonical game distance"));
  assert.equal(svg,renderInferredFineSvg(model,output));
  assert.equal(output.reference_scale,"ASSUMED_NOT_CANON");
  assert.equal(output.truth,"INFERRED_VISUAL_FIELD_NOT_TRAVERSAL");
  assert.equal(output.claims.walkable,"UNKNOWN");
  assert.equal(output.claims.bridges,"UNKNOWN");
  assert.equal(output.claims.safe_routes,"UNKNOWN");
  assert.equal(output.claims.validated_cross_tile_traversal,false);
  assert.equal(output.claims.accurate_fine_shorelines,false);
  assert.equal(output.migration,"NOT_AUTOMATIC");
  assert.equal(output.source_context_id,context.id);
  assert.equal(output.source_world_sha256,fingerprint);
  assert.equal(output.vertices.length,(output.grid_steps+1)**2);
  assert(output.vertices.every(v=>Number.isFinite(v.h)&&Number.isFinite(v.f)&&
    v.h>=0&&v.h<=100&&v.f>=0&&v.f<=1&&typeof v.land==="boolean"));
  const land=output.vertices.filter(v=>v.land);
  assert(land.length>0,"Real source town unexpectedly has zero land samples");
  landTotals.push(land.length);
  const hr=Math.max(...land.map(v=>v.h))-Math.min(...land.map(v=>v.h));
  const fr=Math.max(...land.map(v=>v.f))-Math.min(...land.map(v=>v.f));
  heightRanges.push(hr);forestRanges.push(fr);
  const mid=output.vertices[Math.floor(output.vertices.length/2)];
  dimensions.add(context.space.original_map_units.width.toFixed(4)+"/"+context.space.original_map_units.height.toFixed(4));
  // Even a single-source-cell macro sample must remain insufficient to
  // certify fine pathfinding, coastal crossings or local water barriers.
  if(context.space.source_cell_centres_in_window<4){
   assert.equal(model.flags.sparse_source_samples,true);
   assert.equal(output.claims.validated_cross_tile_traversal,false);
  }
 }
 // Two different source-centred windows produce identical fine values at
 // the very same global coordinate, even where their local SVG pixels differ.
 const p=[world.settlements.find(b=>b?.i===contexts[0].source_home_burg_id).x,
          world.settlements.find(b=>b?.i===contexts[0].source_home_burg_id).y];
 const one=sampleInferredFineTerrain(world,contexts[0],fingerprint,p);
 const another=sampleInferredFineTerrain(world,contexts[1],fingerprint,p);
 assert.deepEqual(one,another,"Neighbourhood identity incorrectly reseeded the world's terrain");
 assert.throws(()=>sampleInferredFineTerrain(world,contexts[0],sha("not source"),p));
 const c0=structuredClone(contexts[0]);
 c0.source_features=[];c0.constraints.shorelines="UNAVAILABLE_NO_SIDECAR";
 assert.throws(()=>buildInferredFineTerrain(world,c0,fingerprint));
}
assert(heightRanges.some(x=>x>1),"Inferred relief has no local variation");
assert(forestRanges.some(x=>x>0.1),"Forest mass field has no spatial variety");
assert(dimensions.size>=2,"Varying local source reference zoom did not affect rendered cropping");
console.log("PASS: GAME-51 six real 30km-assumption visual terrain fields, shared global-coordinate determinism, masked dry-land, saved source/provenance unchanged; forest ranges "+forestRanges.map(x=>x.toFixed(3)).join(",")+" height ranges "+heightRanges.map(x=>x.toFixed(2)).join(","));
