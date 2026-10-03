#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {insidePolygon,sourceDryLand,composeLocalRegion} from "../../tools/regiongen/compose-local-region.mjs";
import {renderConstrainedRegion} from "../../tools/regiongen/render-constrained-region.mjs";
const fingerprint=createHash("sha256").update("synthetic-fixture").digest("hex");
const bounds=[[0,0],[1000,0],[1000,1000],[0,1000]];
const island=[[100,100],[920,100],[920,920],[100,920]];
const lake=[[400,400],[600,400],[600,600],[400,600]];
const c={
 schema_version:1,
 id:"local-source:v1:synthetic",
 parent_source_world_sha256:fingerprint,
 source_home_burg_id:3,
 space:{kind:"source_neighbourhood_window",source_bounds:{left:0,top:0,right:16,bottom:16}},
 constraints:{shorelines:"original_source_features",route_protection:"unverified"},
 source_features:[{classification:"land_boundary",local_polygon:island},{classification:"freshwater_lake",local_polygon:lake}],
 source_burgs:[{source_id:3,name:"Testburg",local_position:[200,200]}],
 source_routes:[{classification:"land_road",source_id:1,segments:[{local_points:[[150,200],[850,200]]}]},
 {classification:"sea_lane",source_id:2,segments:[{local_points:[[30,80],[700,80]]}]}],
 source_rivers:[{source_id:1,segments:[{local_points:[[700,350],[700,800]]}]}]
};
const fixture={cells:{points:[[5,5],[12,12]],heights:[80,12],biome:[5,1]}};
const provider={schema_version:1,provider:{name:"town-forge",version:"1.2.4"},
 source:{world_sha256:fingerprint,burg_id:3},id:"legacy:test",
 geometry:{forests:[bounds],ridges:[[[160,160],[180,180],[210,210],[250,230]],[[700,700],[750,750]]],
 roads:[{points:[[0,0],[1000,1000]],id:"FAKE_ROAD"}],
 water:[[50,50],[900,50],[900,600]],river_centreline:[[0,300],[1000,300]]}};
assert.equal(insidePolygon([200,200],island),true);
assert.equal(insidePolygon([50,50],island),false);
assert.equal(insidePolygon([100,200],island),true);
assert.equal(insidePolygon([450,450],lake),true);
assert(sourceDryLand(c,[200,200]));
assert(!sourceDryLand(c,[500,500]));
assert(!sourceDryLand(c,[80,200]));
assert(!sourceDryLand(c,[-1,100]));
let noSidecar=structuredClone(c);noSidecar.constraints.shorelines="UNAVAILABLE_NO_SIDECAR";
assert(!sourceDryLand(noSidecar,[200,200]));
assert.throws(()=>composeLocalRegion(fixture,noSidecar,provider));
let wrong=structuredClone(provider);wrong.source.burg_id=4;
assert.throws(()=>composeLocalRegion(fixture,c,wrong));
wrong=structuredClone(provider);wrong.source.world_sha256="wrong";
assert.throws(()=>composeLocalRegion(fixture,c,wrong));
let out=composeLocalRegion(fixture,c,provider);
assert(out.id.startsWith("constrained-decorative:v1:"));
assert(out.landscape.trees.length>0);
assert(out.landscape.trees.every(t=>sourceDryLand(c,[t.x,t.y])));
assert(out.landscape.trees.every(t=>Math.hypot(t.x-200,t.y-200)>=36));
assert(out.landscape.trees.every(t=>Math.abs(t.y-200)>=13||t.x<150||t.x>850));
assert(out.landscape.trees.every(t=>Math.abs(t.x-700)>=13||t.y<350||t.y>800));
assert(out.landscape.trees.every(t=>!insidePolygon([t.x,t.y],lake)));
assert(!JSON.stringify(out.landscape).includes("FAKE_ROAD"));
assert(out.landscape.source_routes_authoritative);
assert.equal(out.landscape.procedural_roads_used,false);
assert.equal(out.landscape.procedural_water_used,false);
assert.equal(out.constraints.safe_roads,"UNVERIFIED");
assert.equal(out.constraints.local_sites,"NOT_MIGRATED");
assert.equal(out.source_context.source_home_burg_id,3);
assert.deepEqual(out,composeLocalRegion(fixture,c,provider));
const svg=renderConstrainedRegion(out);
assert(svg.includes('class="azgaar-land"'));
assert(svg.includes('class="azgaar-lake"'));
assert(svg.includes('class="azgaar-land_road"'));
assert(svg.includes('class="azgaar-sea_lane"'));
assert(svg.includes('class="approximate-river"'));
assert(!svg.includes("FAKE_ROAD"));
assert(svg.includes("Town Forge vegetation only"));
assert(!svg.includes("30 km"));
let examples=0,treeCount=0;
for(const [stem,kinds] of [["game-11-determinism",["shore","river","highland"]],
 ["atlas-showcase",["shore","river","highland"]]]){
 const bytes=await readFile("tests/worldgen/fixtures/"+stem+".json");
 const actual=JSON.parse(bytes);
 for(const kind of kinds){
  const region=JSON.parse(await readFile("tools/regiongen/.tmp/constrained-"+stem+"-"+kind+".json","utf8"));
  const ctx=region.source_context;
  const burg=actual.settlements.find(b=>b?.i===ctx.source_home_burg_id);
  assert(burg,"Missing real Azgaar source burg");
  assert.equal(ctx.parent_source_world_sha256,createHash("sha256").update(bytes).digest("hex"));
  assert.deepEqual(ctx.source_burgs.find(b=>b.source_id===burg.i)?.world_position,[burg.x,burg.y]);
  assert(ctx.source_routes.every(x=>x.provenance==="original_azgaar_route_points"));
  assert(region.landscape.trees.every(t=>sourceDryLand(ctx,[t.x,t.y])));
  assert(region.landscape.ridges.every(t=>sourceDryLand(ctx,[t.x,t.y])));
  assert.equal(region.landscape.procedural_water_used,false);
  assert.equal(region.landscape.procedural_roads_used,false);
  const words=await readFile("tools/regiongen/.tmp/constrained-"+stem+"-"+kind+".svg","utf8");
  assert(words.startsWith("<svg")&&words.includes("source-burg"),"Rendered scene missing source burg "+kind);
  treeCount+=region.landscape.trees.length;
  examples++;
 }
}
assert.equal(examples,6);
assert(treeCount>0,"No Town Forge vegetation survived source land constraints");
console.log("PASS: GAME-47 dry land, lake/water exclusion, source routes and burgs, filtering and determinism, "+examples+" real constrained maps, "+treeCount+" decorative trees");
