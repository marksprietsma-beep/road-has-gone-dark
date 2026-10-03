#!/usr/bin/env node
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import {spawnSync} from "node:child_process";
const tmp=resolve("tools/regiongen/.tmp");
let done=0;
for(const stem of ["game-11-determinism","atlas-showcase"])
 for(const kind of ["shore","river","highland"]){
  const input=resolve(tmp,"constrained-"+stem+"-"+kind+".json");
  const world=resolve("tests/worldgen/fixtures/"+stem+".json");
  const output=resolve(tmp,"contextual-"+stem+"-"+kind+".json");
  const args=["tools/regiongen/generate-contextual-region.mjs",
   "--world",world,"--constrained",input,"--output",output,
   "--audit-svg",output.replace(/\.json$/i,".audit.svg")];
  const run=spawnSync(process.execPath,args,{encoding:"utf8",timeout:120000,maxBuffer:3*1024*1024});
  if(run.status!==0)throw Error("Failed genuine source v2 sites "+stem+"/"+kind+": "+run.stderr+"\n"+run.stdout);
  console.log(stem+"/"+kind+" "+run.stdout.trim());
  done++;
 }
if(done!==6)throw Error("Exactly six real source contexts required");
console.log("PASS: six source-grounded GAME-44 local site examples");
