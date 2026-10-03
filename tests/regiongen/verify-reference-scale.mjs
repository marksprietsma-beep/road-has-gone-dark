#!/usr/bin/env node
/** Explicit hypothetical radius test; never computes canonical travel distance. */
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {sourceGeographicReference,referenceNeighbourhoodBounds} from "../../tools/regiongen/reference-scale.mjs";
import {buildLocalContext,buildReferenceLocalContext} from "../../tools/regiongen/local-source-context.mjs";
const digest=x=>createHash("sha256").update(x).digest("hex");
const radius=6371.0088;
const mock={
 schemaVersion:1,seed:"synthetic",
 generator:{provider:"azgaar",version:"1.153.1",upstreamCommit:"test"},
 map:{width:360,height:240,bounds:{latN:60,latS:-60,latT:120,lonW:-90,lonE:90,lonT:180},geography:[]},
 cells:{ids:[0,1],points:[[180,120],[180.7,120.1]]},
 settlements:[{i:1,x:180,y:120,cell:0,name:"Origin"},{i:2,x:180.7,y:120.1,cell:1,name:"Neighbour"}],
 routes:[{i:1,group:"roads",points:[[179,120],[182,120]]}],rivers:[]};
const base=sourceGeographicReference(mock,[180,120],radius);
assert.equal(base.angular_position.lat,0);
assert.equal(base.angular_position.lon,0);
assert.equal(base.reference_radius_km,radius);
assert.equal(base.certainty,"ASSUMED_WORLD_RADIUS_NOT_GAME_CANON");
assert(Math.abs(base.hypothetical_km_per_source_unit.east_west-
 base.hypothetical_km_per_source_unit.north_south)<0.0001);
const crop=referenceNeighbourhoodBounds(mock,[180,120],30,radius);
assert.equal(crop.hypothetical_square_km,30);
assert(crop.source_window_units.width<1);
assert(crop.source_window_units.height<1);
assert(Math.abs(crop.source_window_units.width-crop.source_window_units.height)<.0001);
assert.equal(crop.endpoint_shifted_for_world_edge,false);
const highLat=sourceGeographicReference(mock,[180,0],radius);
assert(highLat.hypothetical_km_per_source_unit.east_west <
 base.hypothetical_km_per_source_unit.east_west*.6);
const polar=structuredClone(mock);polar.map.bounds={latN:90,latS:-90,latT:180,lonW:-90,lonE:90,lonT:180};
assert.throws(()=>sourceGeographicReference(polar,[180,1],radius),/pole/);
assert.throws(()=>sourceGeographicReference(mock,[180,120],0));
assert.throws(()=>referenceNeighbourhoodBounds(mock,[180,120],0,radius));
assert.throws(()=>referenceNeighbourhoodBounds(mock,[180,120],30,NaN));
assert.throws(()=>sourceGeographicReference(mock,[361,120],radius));
const fp=digest("synthetic-fixture");
const v1=buildLocalContext(mock,1,fp,null),v2=buildReferenceLocalContext(mock,1,fp,null,30,radius);
assert.equal(v1.space.physical_km,"UNCALIBRATED");
assert.equal(v1.space.original_map_units,16);
assert(v1.id.startsWith("local-source:v1:"));
assert(v2.id.startsWith("local-source:v2:"));
assert.notEqual(v1.id,v2.id);
assert.equal(v2.space.physical_km,"ASSUMED_NOT_CANON");
assert.equal(v2.space.original_map_units.width,crop.source_window_units.width);
assert.equal(v2.space.angular_reference.reference_radius_km,radius);
assert.equal(v2.space.source_cell_centres_in_window,1);
assert.equal(v2.constraints.local_resolution,"COARSE_MACRO_GEOGRAPHY_NO_WALKABLE_MICRO_DETAIL");
assert.deepEqual(v2,buildReferenceLocalContext(mock,1,fp,null,30,radius));
assert.notEqual(v2.id,buildReferenceLocalContext(mock,1,fp,null,50,radius).id);
assert.notEqual(v2.id,buildReferenceLocalContext(mock,1,fp,null,30,5000).id);
let checked=0;
for(const stem of ["game-11-determinism","atlas-showcase"]) {
 const raw=await readFile("tests/worldgen/fixtures/"+stem+".json");
 const w=JSON.parse(raw),sha=digest(raw);
 const sidecar=JSON.parse(await readFile("tools/regiongen/.tmp/geography-"+stem+".json","utf8"));
 const candidates=w.settlements.filter(b=>b?.i>0&&!b.hidden&&!b.removed&&Number.isFinite(b.x)&&Number.isFinite(b.y));
 for(const burg of candidates.slice(0,100)) {
  const lat=w.map.bounds.latN-burg.y/w.map.height*w.map.bounds.latT;
  if(Math.abs(lat)>=80)continue;
  const original=buildLocalContext(w,burg.i,sha,sidecar);
  const reference=buildReferenceLocalContext(w,burg.i,sha,sidecar,30,radius);
  assert(original.id.startsWith("local-source:v1:"));
  assert.equal(original.space.original_map_units,16);
  assert.equal(reference.space.physical_km,"ASSUMED_NOT_CANON");
  assert(reference.space.source_cell_centres_in_window>=0);
  assert(reference.space.original_map_units.width<original.space.original_map_units*3,
    "Reference window unexpectedly enormous near non-polar town");
  assert(reference.source_burgs.some(b=>b.source_id===burg.i));
  assert(!reference.source_burgs.some(b=>w.settlements.find(z=>z?.i===b.source_id)?.hidden));
  assert(reference.source_routes.every(s=>s.provenance==="original_azgaar_route_points"));
  assert(reference.source_features.every(s=>s.provenance==="original_azgaar_pack_vertices"));
  assert.deepEqual(reference,buildReferenceLocalContext(w,burg.i,sha,sidecar,30,radius));
  assert.deepEqual(original,buildLocalContext(w,burg.i,sha,sidecar),"v1 mutated by v2 addition");
  checked++;
 }
}
assert(checked>=100);
console.log("PASS: GAME-48 explicit assumed-radius source windows, unchanged v1 identities, no invented km, polar guards and "+checked+" real origin contexts");
