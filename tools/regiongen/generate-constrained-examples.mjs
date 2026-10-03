#!/usr/bin/env node
/** GAME-47: use the same authentic six hometown cases as GAME-46's source view. */
import {readFile} from "node:fs/promises";
import {spawnSync} from "node:child_process";
import {resolve} from "node:path";
const tmp=resolve("tools/regiongen/.tmp");
let total=0;
for(const stem of ["game-11-determinism","atlas-showcase"])for(const kind of ["shore","river","highland"]){
 const context=JSON.parse(await readFile(resolve(tmp,"local-"+stem+"-"+kind+".json"),"utf8"));
 const args=["tools/regiongen/generate-constrained-region.mjs",
 "--world",resolve("tests/worldgen/fixtures/"+stem+".json"),
 "--geography",resolve(tmp,"geography-"+stem+".json"),
 "--burg",String(context.source_home_burg_id),
 "--output",resolve(tmp,"constrained-"+stem+"-"+kind+".json")];
 const run=spawnSync(process.execPath,args,{encoding:"utf8",timeout:120000,maxBuffer:4*1024*1024});
 if(run.status!==0)throw Error("Source constrained provider failed for "+stem+"/"+kind+": "+run.stderr+"\n"+run.stdout);
 console.log(stem+" "+kind+": "+run.stdout.trim());
 total++;
}
if(total!==6)throw Error("Six real environments are mandatory");
console.log("PASS: six generated source-grounded Town Forge decoration diagnostics");
