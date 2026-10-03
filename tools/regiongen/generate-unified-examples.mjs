#!/usr/bin/env node
/** Required before use: replay actual world fixtures and generate six GAME-47
 * source-constrained composites. Never interpolate from unrelated 30km crops. */
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import {spawnSync} from "node:child_process";
const tmp=resolve("tools/regiongen/.tmp");
let total=0;
for(const stem of ["game-11-determinism","atlas-showcase"])
 for(const kind of ["shore","river","highland"]){
  const region=resolve(tmp,"constrained-"+stem+"-"+kind+".json");
  const data=JSON.parse(await readFile(region));
  if(data?.source_context?.space?.kind!=="source_neighbourhood_window")
   throw Error("Refusing hypothetical scale or wrong source data");
  const out=resolve(tmp,"unified-"+stem+"-"+kind+".json");
  const run=spawnSync(process.execPath,["tools/regiongen/generate-unified-preview.mjs",
   "--world",resolve("tests/worldgen/fixtures/"+stem+".json"),
   "--constrained",region,"--output",out,
   "--audit-output",resolve(tmp,"developer","unified-"+stem+"-"+kind+".json")],
   {encoding:"utf8",timeout:90000,maxBuffer:4*1024*1024});
  if(run.status!==0)throw Error("GAME-54 failed "+stem+"/"+kind+": "+run.stderr+"\n"+run.stdout);
  console.log(stem+"/"+kind+": "+run.stdout.trim());
  total++;
 }
if(total!==6)throw Error("Missing required six real examples");
console.log("PASS: GAME-54 six source-v1 regions with one shared coordinate system for terrain and sites");
