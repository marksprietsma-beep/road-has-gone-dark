#!/usr/bin/env node
import assert from "node:assert/strict";
import {sourceContext, geometryPoints} from "../../tools/regiongen/source-context.mjs";
import {readFile, writeFile, mkdir} from "node:fs/promises";
import {spawnSync} from "node:child_process";
import {createHash} from "node:crypto";
import {dirname, resolve} from "node:path";
import {fileURLToPath} from "node:url";
const root=resolve(dirname(fileURLToPath(import.meta.url)),"../..");
const source=resolve(root,"tests/worldgen/fixtures/game-11-determinism.json");
const show=resolve(root,"tests/worldgen/fixtures/atlas-showcase.json");
const tmp=resolve(root,"tools/regiongen/.tmp");
await mkdir(tmp,{recursive:true});
const raw=await readFile(source),world=JSON.parse(raw.toString("utf8"));
const before=createHash("sha256").update(raw).digest("hex");
const valid=b=>b&&b.i>0&&b.cell>=0&&b.capital!==1&&b.population>0&&b.population<=5
 &&world.cells.state[world.cells.ids.indexOf(b.cell)]>0;
const candidates=world.settlements.filter(valid);
assert(candidates.length>=2,"Need two source-backed small burgs in the existing fixture");
const a=candidates[0], b=candidates.find(t=>t.cell!==a.cell);
assert(b,"No distinct second origin");
const gen=(path,worldPath,id,x=0,y=0,extra=[])=>{
 const output=resolve(tmp,path+".json");
 const args=["tools/regiongen/generate-region.mjs","--world",worldPath,"--burg",String(id),"--x",String(x),"--y",String(y),"--output",output,...extra];
 const p=spawnSync(process.execPath,args,{cwd:root,encoding:"utf8",timeout:90000,maxBuffer:4*1024*1024});
 assert.equal(p.status,0,"Town Forge generator failed: "+p.stderr+"\n"+p.stdout);
 assert.match(p.stdout,/GAME-21/);
 return output;
};
const first=gen("first",source,a.i);
const repeated=gen("repeat",source,a.i);
const initial=await readFile(first,"utf8"),again=await readFile(repeated,"utf8");
assert.equal(initial,again,"Same pinned world/cell/tile failed bytewise determinism");
const data=JSON.parse(initial);
assert.equal(data.provider.name,"town-forge");
assert.equal(data.provider.commit,"4b25a37c14c80970d2b66f0c587468c7493855d3");
assert.equal(data.source.world_sha256,before);
assert.equal(data.source.burg_id,a.i);
assert.equal(data.source.cell_id,a.cell);
assert.equal(data.region.side_km,30);
assert.equal(data.constraints.seams,"not_yet_stitched");
assert.equal(data.constraints.road_edges,"provisional_town_forge");
assert(data.geometry.roads.length>0,"Town Forge did not emit any provisional roads");
assert(data.geometry.forests.length>0||data.geometry.water.length>2||data.geometry.ridges.length>0,"Town Forge preview has no landscape features");
assert(!("houses" in data.geometry),"Local region must not include generated town buildings");
const svg=await readFile(first.replace(/\.json$/,".svg"),"utf8");
assert(svg.startsWith("<svg"),"SVG preview missing");
assert(svg.includes("Town Forge")&&svg.includes("PREVIEW"),"Preview must identify provider/provisional status");

const otherBurg=JSON.parse(await readFile(gen("second-burg",source,b.i),"utf8"));
assert.notEqual(otherBurg.id,data.id,"Different source cell gives same region identity");
assert.notDeepEqual(otherBurg.geometry,data.geometry,"Different source cell produced identical geometry");
const otherTile=JSON.parse(await readFile(gen("other-tile",source,a.i,1,0),"utf8"));
assert.notEqual(otherTile.id,data.id);
assert.notDeepEqual(otherTile.geometry,data.geometry,"Adjacent tile did not use independent seed");

const renamed=JSON.parse(raw.toString("utf8"));
renamed.settlements.find(z=>z&&z.i===a.i).name="Renamed in source for independent identity test";
const changed=resolve(tmp,"renamed-world.json");
await writeFile(changed,JSON.stringify(renamed));
const sameName=JSON.parse(await readFile(gen("renamed",changed,a.i),"utf8"));
assert.deepEqual(sameName.geometry,data.geometry,"A town name changed actual region geometry");
assert.notEqual(sameName.source.world_sha256,data.source.world_sha256,
 "Modifying full world source should change the immutable world fingerprint");
assert.equal(createHash("sha256").update(await readFile(source)).digest("hex"),before,"Canonical fixture mutated");
// Malformed input must fail explicitly rather than become plausible-looking terrain.
for (const change of [w=>delete w.cells.river, w=>w.cells.heights.pop(),
 w=>w.cells.ids[1]=w.cells.ids[0], w=>w.seed="",
 w=>w.settlements.find(z=>z&&z.i===a.i).removed=true,
 w=>w.cells.heights[w.cells.ids.indexOf(a.cell)]=null]) {
 const bad=structuredClone(world); change(bad);
 assert.throws(()=>sourceContext(bad,a.i));
}
assert.throws(()=>sourceContext(world,0));
assert.throws(()=>sourceContext(world,Number.MAX_SAFE_INTEGER));
assert.throws(()=>geometryPoints([{x:NaN,y:1}]));
assert.throws(()=>geometryPoints([{x:1,y:Infinity}]));
assert.deepEqual(geometryPoints(null),[]);
// Array offsets must never be confused with source numeric IDs.
const reordered=structuredClone(world);
for(const [key,items] of Object.entries(reordered.cells)) if(Array.isArray(items)) reordered.cells[key]=items.slice().reverse();
assert.deepEqual(sourceContext(reordered,a.i),sourceContext(world,a.i));
const west=JSON.parse(await readFile(gen("west-tile",source,a.i,-1,0),"utf8"));
assert.equal(west.region.x,-1);
const scaled=JSON.parse(await readFile(gen("scale-check",source,a.i,0,0,["--km","40"]),"utf8"));
assert.notEqual(scaled.id,data.id,"Different physical interpretations must not collide in cache");
assert.deepEqual(scaled.geometry,data.geometry,"Conceptual scale should not reroll geometry");
// Each case is an actual existing burg in an unchanged real fixture.
const cases={coast:c=>c.terrain===1&&c.river===0,river:c=>c.terrain!==1&&c.river>0,
 mountain:c=>c.terrain!==1&&c.river===0&&c.height>=68,estuary:c=>c.terrain===1&&c.river>0};
for(const [label,predicate] of Object.entries(cases)) {
 const origin=world.settlements.find(b=>b&&b.i>0&&!b.hidden&&!b.removed&&predicate(sourceContext(world,b.i).cell));
 assert(origin,"Missing real geography case: "+label);
 const output=JSON.parse(await readFile(gen(label,source,origin.i),"utf8"));
 const context=sourceContext(world,origin.i);
 assert.equal(output.source.cell_id,origin.cell);
 assert.equal(output.source.cell_river,context.cell.river);
 assert.equal(output.region.terrain,context.terrain);
 if(label==="coast"||label==="estuary") {
  assert(context.waterSide,"Coast needs a source-backed water bearing");
  assert.equal(output.source.water_side,context.waterSide);
  assert(output.geometry.water.length>2);
  assert.equal(output.source.shoreline_water_kind,"unknown_lake_or_sea");
 }
 if(label==="river") assert(output.geometry.river_centreline.length>2);
 if(label==="mountain") assert(output.geometry.ridges.length>0);
 if(label==="estuary") assert.equal(output.constraints.rivers,"source_river_not_rendered");
}
const secondWorld=JSON.parse(await readFile(show));
assert(secondWorld.seed!==world.seed,"Test worlds unexpectedly share seed");
const secondHome=secondWorld.settlements.find(b=>b&&b.i>0&&!b.hidden&&!b.removed);
const second=JSON.parse(await readFile(gen("second-world",show,secondHome.i),"utf8"));
assert.equal(second.source.world_seed,secondWorld.seed);
assert.notDeepEqual(second.geometry,data.geometry);
const secondAgain=JSON.parse(await readFile(gen("second-world-repeat",show,secondHome.i),"utf8"));
assert.deepEqual(secondAgain,second);
// The CLI must reject output paths that alias its immutable input or each other.
for(const [output,extra] of [[source,[]],[resolve(tmp,"collision.json"),["--svg",source]],
 [resolve(tmp,"collision.json"),["--svg",resolve(tmp,"collision.json")]]]) {
 const p=spawnSync(process.execPath,["tools/regiongen/generate-region.mjs","--world",source,"--burg",String(a.i),"--output",output,...extra],{cwd:root,encoding:"utf8"});
 assert.notEqual(p.status,0,"Aliased output was accepted");
 assert.match(p.stderr,/paths must be distinct/);
}
assert.equal(createHash("sha256").update(await readFile(source)).digest("hex"),before);
console.log("PASS: GAME-21 Town Forge provider, same-source deterministic geometry, distinct origins/tiles, name independence, source validation, coast/river/mountain/estuary, two generated worlds, output safety and SVG preview");
