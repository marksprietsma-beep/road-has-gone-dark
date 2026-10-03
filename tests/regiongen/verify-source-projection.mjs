#!/usr/bin/env node
/** GAME-39 independent data-contract tests, no generated fixture changes. */
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {resolve} from "node:path";
import {buildTileConstraints,sideCrossings,tileForPosition,tileForBurg,fromLocal,toLocal,
 clipSegment,canonicalBoundary,WORLD_UNITS_PER_TILE} from "../../tools/regiongen/source-projection.mjs";
const hash=x=>createHash("sha256").update(x).digest("hex");
const b={left:0,right:64,top:0,bottom:64};
assert.deepEqual(clipSegment([-10,20],[100,20],b),[[0,20],[64,20]]);
assert.equal(clipSegment([-20,-20],[-1,-2],b),null);
assert.deepEqual(clipSegment([-10,0],[0,0],b),[[0,0],[0,0]]);
assert.deepEqual(clipSegment([-10,10],[10,-10],b),[[0,0],[0,0]],"Corner tangency clipping");
assert.equal(canonicalBoundary(0,0,"E"),canonicalBoundary(1,0,"W"));
assert.equal(canonicalBoundary(0,0,"S"),canonicalBoundary(0,1,"N"));
assert.throws(()=>canonicalBoundary(0,0,"Q"));
function mock(){
 const cellPoints=[[10,16],[20,16],[75,16],[10,75],[80,80]];
 return {schemaVersion:1,generator:{provider:"azgaar"},seed:"synthetic",
  map:{width:128,height:128},cells:{ids:[0,1,2,3,4],points:cellPoints},
  settlements:[
   {i:1,name:"First",cell:0,x:10,y:16},
   {i:2,name:"Same tile",cell:1,x:20,y:16},
   {i:3,name:"Other tile",cell:2,x:75,y:16}],
  routes:[
   {i:1,group:"roads",points:[[0,16],[64,16],[125,16]]},
   {i:2,group:"trails",points:[[12,45],[90,45],[10,45],[100,45]]},
   {i:3,group:"roads",points:[[10,10],[64,64],[120,120]]},
   {i:4,group:"roads",points:[[2,30],[64,31],[2,32]]},
   {i:5,group:"roads",points:[[30,64],[40,64]]}
  ],rivers:[{i:1,cells:[0,1,2]}]};
}
const m=mock(),c=(x,y)=>buildTileConstraints(m,x,y,"test-fixture");
assert.deepEqual(tileForBurg(m,1),tileForBurg(m,2),"Same region chosen through two burgs");
assert.deepEqual(tileForBurg(m,3),[1,0]);
assert.deepEqual(tileForPosition(64,18,m),[1,0]);
const original=c(0,0),right=c(1,0),bottom=c(0,1),diagonal=c(1,1);
assert.deepEqual(original.burgs.map(q=>q.source_id),[1,2]);
assert.deepEqual(right.burgs.map(q=>q.source_id),[3]);
assert.deepEqual(sideCrossings(original,"E"),sideCrossings(right,"W"),"E/W must share canonical source crossing events");
assert.deepEqual(sideCrossings(original,"S"),sideCrossings(bottom,"N"),"N/S must share canonical source crossing events");
assert(sideCrossings(original,"E").some(x=>x.source==="route:1"));
assert(sideCrossings(original,"E").some(x=>x.source==="river:1"));
assert(sideCrossings(original,"E").filter(x=>x.source==="route:2").length>=2,"Multiple route crossings are lost");
assert(!original.crossings.some(x=>x.source==="route:4"&&x.boundary==="V:64:0"),
 "A border tangent must not become a travel connector");
assert(!original.crossings.some(x=>x.source==="route:5"&&x.boundary==="H:0:64"),
 "A coincident edge must not become a random crossing");
assert(original.crossings.some(x=>x.source==="route:3"&&x.world_position.join(",")==="64,64"),
 "Corner crossing missing");
assert.deepEqual(c(0,0),original,"Constraint generation must be order independent");
assert.deepEqual(c(1,1),diagonal);
assert.deepEqual(fromLocal(toLocal([21.42,30.85],0,0),0,0),[21.42,30.85]);
assert(original.segments.every(s=>s.kind==="azgaar_route"||s.kind==="azgaar_river"));
assert(original.crossings.every(x=>x.protected_status==="unverified"));
assert(original.segments.filter(s=>s.kind==="azgaar_river").every(s=>s.geometry.includes("approximation")));
for(const mutate of [
 w=>w.cells.ids[1]=0,
 w=>w.routes[0].points[1]=[NaN,10],
 w=>w.rivers[0].cells=[0,123456],
 w=>w.map.width=0
]){let w=structuredClone(m);mutate(w);assert.throws(()=>buildTileConstraints(w,0,0,"test-fixture"))}
let checked=0;
for(const filename of ["game-11-determinism","atlas-showcase"]){
 const bytes=await readFile(resolve("tests/worldgen/fixtures/"+filename+".json"));
 const w=JSON.parse(bytes.toString("utf8")),fingerprint=hash(bytes);
 const homes=w.settlements.filter(b=>b?.i>0&&!b.hidden&&!b.removed&&Number.isFinite(b.x)&&Number.isFinite(b.y));
 assert(homes.length>10,"Need real towns in "+filename);
 const home=homes.find(b=>{
  const t=tileForBurg(w,b.i);
  return (t[0]+1)*WORLD_UNITS_PER_TILE<w.map.width &&
         (t[1]+1)*WORLD_UNITS_PER_TILE<w.map.height;
 });
 assert(home,filename+" requires an interior origin");
 const tile=tileForBurg(w,home.i),a=buildTileConstraints(w,...tile,fingerprint);
 assert(a.burgs.some(b=>b.source_id===home.i),filename+" hometown missing from selected tile");
 assert.deepEqual(a.tile.bounds,{
  left:tile[0]*WORLD_UNITS_PER_TILE,right:(tile[0]+1)*WORLD_UNITS_PER_TILE,
  top:tile[1]*WORLD_UNITS_PER_TILE,bottom:(tile[1]+1)*WORLD_UNITS_PER_TILE});
 assert.equal(a.scale.km_mapping.startsWith("NOT_CALIBRATED"),true);
 for(const [step,one,two,oneSide,twoSide] of [
  ["EW",buildTileConstraints(w,tile[0],tile[1],fingerprint),
        buildTileConstraints(w,tile[0]+1,tile[1],fingerprint),"E","W"],
  ["NS",buildTileConstraints(w,tile[0],tile[1],fingerprint),
        buildTileConstraints(w,tile[0],tile[1]+1,fingerprint),"S","N"]
 ]) assert.deepEqual(sideCrossings(one,oneSide),sideCrossings(two,twoSide),filename+" "+step+" mismatched");
 checked++;
}
console.log("PASS: GAME-39 shared source projection, clipping, multiple crossings, corners, tangencies, 2 real Azgaar worlds ("+checked+"), protected-road caution, stable source IDs");
