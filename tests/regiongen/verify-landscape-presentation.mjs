#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {buildLandscapePresentation} from "../../tools/regiongen/landscape-presentation.mjs";
import {sampleLandscapeArt} from "../../tools/regiongen/inferred-fine-terrain.mjs";
import {sourceDryLand} from "../../tools/regiongen/compose-local-region.mjs";
const total={canopy:0,pine:0,field:0,building:0};
for(const stem of ["game-11-determinism","atlas-showcase"]){
 const world=JSON.parse(await readFile(`tests/worldgen/fixtures/${stem}.json`));
 const cases=[];
 for(const kind of ["shore","river","highland"]){
  const region=JSON.parse(await readFile(`tools/regiongen/.tmp/contextual-${stem}-${kind}.json`));
  const art=region.landscape_presentation_v1,context=region.source_context;
  cases.push(context);
  assert.equal(art.truth,"ILLUSTRATION_ONLY");
  assert.equal(art.source_context_id,context.id);
  assert.equal(art.source_world_sha256,context.parent_source_world_sha256);
  assert.equal(art.claims.walkable,"UNKNOWN");
  assert.equal(art.terrain.vertices.length,65**2);
  // Art must be reproducible and independent of hidden locations, labels or
  // changing playthrough knowledge. No game-site layer is an input.
  const revised=structuredClone(region);revised.local_sites_v2={sites:[{position:[20,30],label:"SECRET",knowledge:"visited"}]};
  assert.deepEqual(buildLandscapePresentation(world,revised),art);
  for(const primitive of [...art.ground,...art.objects]){
   assert(primitive.points.every(p=>p.length===2&&p.every(Number.isFinite)&&sourceDryLand(context,p)),"Art escaped original source dry land");
   const centre=primitive.points.reduce((p,q)=>[p[0]+q[0]/primitive.points.length,p[1]+q[1]/primitive.points.length],[0,0]);
   assert(sourceDryLand(context,centre),"Art interior covers original source water");
   assert(!/road|bridge|river|site|pass|harbour/.test(primitive.kind),"Scenery created travel/source facts");
   if(primitive.kind in total)total[primitive.kind]++;
  }
  for(const ripple of art.water)assert(ripple.points.every(p=>!sourceDryLand(context,p)));
  // Detect the original visual aliasing: the art's neighbouring canopy
  // samples should be appreciably calmer than the legacy fine:v1 grid.
  const roughness=terrain=>{
   const n=terrain.grid_steps,a=terrain.vertices,steps=[];
   for(let y=0;y<n;y++)for(let x=0;x<n;x++){
    const k=y*(n+1)+x;steps.push(Math.abs(a[k].f-a[k+1].f),Math.abs(a[k].f-a[k+n+1].f));
   }
   return steps.reduce((a,b)=>a+b,0)/steps.length;
  };
  assert(roughness(art.terrain)<roughness(region.inferred_fine_v1)*.6,"Art sampler still aliases at local-map zoom");
 }
 const p=world.cells.points[100];
 assert.deepEqual(sampleLandscapeArt(world,cases[0],cases[0].parent_source_world_sha256,p),
  sampleLandscapeArt(world,cases[1],cases[1].parent_source_world_sha256,p),"Art was reseeded by region identity");
}
assert(total.canopy>200&&total.pine>100&&total.field>15&&total.building>25);
console.log("PASS: GAME-57 six deterministic shared landscape scenes, calmer world-coordinate sampling, source-water exclusion, hidden-site independence; "+JSON.stringify(total));
