#!/usr/bin/env node
import {readFile} from "node:fs/promises";
import {spawnSync} from "node:child_process";
import {resolve} from "node:path";
const tmp=resolve("tools/regiongen/.tmp");
let generated=0;
for(const [stem,sidecar] of [
 ["game-11-determinism","geography-game-11-determinism.json"],
 ["atlas-showcase","geography-atlas-showcase.json"]
]){
 const source=resolve("tests/worldgen/fixtures/"+stem+".json"),world=JSON.parse(await readFile(source));
 const byId=new Map(world.cells.ids.map((id,i)=>[id,i]));
 const candidates=world.settlements.filter(b=>b?.i>0&&!b.hidden&&!b.removed&&
    Number.isFinite(b.x)&&Number.isFinite(b.y)&&byId.has(b.cell));
 const used=new Set();
 const checks=[
  ["shore",b=>world.cells.terrain[byId.get(b.cell)]===1],
  ["river",b=>world.cells.river[byId.get(b.cell)]>0&&world.cells.terrain[byId.get(b.cell)]!==1],
  ["highland",b=>world.cells.heights[byId.get(b.cell)]>=68&&world.cells.terrain[byId.get(b.cell)]!==1]
 ];
 for(const [kind,test] of checks){
  const home=candidates.find(b=>!used.has(b.i)&&test(b));
  if(!home)throw Error("No authentic "+kind+" origin in "+stem);
  used.add(home.i);
  const output=resolve(tmp,"local-"+stem+"-"+kind+".json");
  const run=spawnSync(process.execPath,[
   "tools/regiongen/preview-local-context.mjs",
   "--world",source,"--burg",String(home.i),
   "--geography",resolve(tmp,sidecar),"--output",output],{encoding:"utf8",timeout:90000});
  if(run.status!==0)throw Error("Local preview generation failed "+kind+": "+run.stderr);
  console.log(stem+" "+kind+" burg "+home.i+": "+run.stdout.trim());
  generated++;
 }
}
if(generated!==6)throw Error("Expected six authentic local contexts");
console.log("PASS: six source-backed GAME-46 local neighbourhood previews");
