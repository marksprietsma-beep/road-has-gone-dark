#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {buildGeographySidecar,checkGeographySidecar} from "../../tools/worldgen/geography-sidecar.mjs";
import {clipPolygon,buildTileConstraints,sideShorelineCrossings,tileForPosition,WORLD_UNITS_PER_TILE} from "../../tools/regiongen/source-projection.mjs";
const digest=x=>createHash("sha256").update(x).digest("hex");
const sample={schemaVersion:1,seed:"synthetic",generator:{provider:"azgaar",version:"1.153.1",upstreamCommit:"example"},
 map:{width:128,height:128,geography:[
  {i:1,type:"island",subtype:"continent",vertices:[0,1,2,3]},
  {i:2,type:"lake",subtype:"freshwater",vertices:[4,5,6,7]}]},
 cells:{ids:[0,1],points:[[50,20],[75,20]]},
 routes:[],rivers:[],settlements:[]};
const points=[[52,12],[76,12],[76,38],[52,38],[58,18],[70,18],[70,27],[58,27]];
const bytes=JSON.stringify(sample)+"\n",hash=digest(bytes);
const sidecar=buildGeographySidecar(sample,points,bytes);
assert.equal(sidecar.source_world_sha256,hash);
assert.deepEqual(checkGeographySidecar(sample,sidecar,hash),points);
const left=buildTileConstraints(sample,0,0,hash,sidecar);
const right=buildTileConstraints(sample,1,0,hash,sidecar);
assert.equal(left.constraints.shoreline,"exact_source_feature_vertices");
assert.equal(left.source_shoreline.polygons.length,2);
assert.equal(right.source_shoreline.polygons.length,2);
assert.deepEqual(sideShorelineCrossings(left,"E"),sideShorelineCrossings(right,"W"));
assert.equal(sideShorelineCrossings(left,"E").length,4,"One land and one lake ring should each have two shared crossings");
assert(left.source_shoreline.segments.every(x=>x.geometry==="original_pack_feature_vertex_points"));
assert(left.source_shoreline.polygons.some(x=>x.kind==="source_lake"));
assert(right.source_shoreline.polygons.some(x=>x.kind==="source_land_boundary"));
assert.deepEqual(clipPolygon([[72,72],[85,72],[85,85],[72,85]],{left:0,right:64,top:0,bottom:64}),[]);
assert.throws(()=>buildTileConstraints(sample,0,0,"wrong sha",sidecar));
assert.throws(()=>buildGeographySidecar(sample,points.slice(0,3),bytes));
let modified=structuredClone(sidecar); modified.vertices[0]=[Infinity,2];
assert.throws(()=>checkGeographySidecar(sample,modified,hash));
modified=structuredClone(sidecar);modified.source_seed="other";
assert.throws(()=>checkGeographySidecar(sample,modified,hash));

// Generated from exactly the same upstream seed as each immutable world fixture.
let cases=0;
for(const stem of ["game-11-determinism","atlas-showcase"]){
 const fixture=await readFile("tests/worldgen/fixtures/"+stem+".json");
 const replay=await readFile("tools/regiongen/.tmp/geography-"+stem+".world.json");
 assert.equal(digest(fixture),digest(replay),"Source re-generation mutated world: "+stem);
 const world=JSON.parse(fixture.toString("utf8"));
 const geometry=JSON.parse(await readFile("tools/regiongen/.tmp/geography-"+stem+".json","utf8"));
 checkGeographySidecar(world,geometry,digest(fixture));
 const features=world.map.geography.filter(f=>f?.vertices?.length>=3);
 assert(features.length>=3,stem+": missing island/lake outlines");
 assert(features.some(f=>f.type==="island"),stem+": no original island polygon");
 assert(features.some(f=>f.type==="lake"),stem+": no original lake polygon");
 assert(geometry.vertices.length>Math.max(...features.flatMap(f=>f.vertices)),stem+": invalid vertex index coverage");
 // Find a genuine original polygon that crosses a globally shared tile edge,
 // not a manufactured match between independently generated fragments.
 let found=false;
 for(const feature of features){
  const p=feature.vertices.map(i=>geometry.vertices[i]);
  for(let i=0;i<p.length;i++){
   const a=p[i],b=p[(i+1)%p.length];
   const middle=[(a[0]+b[0])/2,(a[1]+b[1])/2];
   const tx=Math.floor(middle[0]/WORLD_UNITS_PER_TILE);
   const ty=Math.floor(middle[1]/WORLD_UNITS_PER_TILE);
   if(tx+1>=Math.ceil(world.map.width/WORLD_UNITS_PER_TILE))continue;
   if(ty+1>=Math.ceil(world.map.height/WORLD_UNITS_PER_TILE))continue;
   const A=buildTileConstraints(world,tx,ty,digest(fixture),geometry);
   const E=buildTileConstraints(world,tx+1,ty,digest(fixture),geometry);
   assert.deepEqual(sideShorelineCrossings(A,"E"),sideShorelineCrossings(E,"W"),stem+" E/W feature boundary mismatch");
   const S=buildTileConstraints(world,tx,ty+1,digest(fixture),geometry);
   assert.deepEqual(sideShorelineCrossings(A,"S"),sideShorelineCrossings(S,"N"),stem+" N/S feature boundary mismatch");
   if(A.source_shoreline.segments.length || E.source_shoreline.segments.length){
    found=true;break;
   }
  }
  if(found)break;
 }
 assert(found,stem+": no actual coast/lake segments rendered");
 cases++;
}
console.log("PASS: GAME-39 original coastline/lake feature vertices, shared E/W and N/S, immutable replay fingerprints, two seeded worlds ("+cases+")");
