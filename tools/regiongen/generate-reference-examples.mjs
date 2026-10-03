#!/usr/bin/env node
import {readFile} from "node:fs/promises";
import {spawnSync} from "node:child_process";
import {resolve} from "node:path";
// A 6371.0088 km hypothetical radius is an EXPLICIT Earth-equivalent
// visual *reference*, not a fact about The Road Has Gone Dark's world.
const tmp=resolve("tools/regiongen/.tmp"),assumedRadius="6371.0088";
for(const stem of ["game-11-determinism","atlas-showcase"]){
 for(const kind of ["shore","river","highland"]){
  const classic=JSON.parse(await readFile(resolve(tmp,"local-"+stem+"-"+kind+".json"),"utf8"));
  const args=["tools/regiongen/preview-local-context.mjs",
   "--world",resolve("tests/worldgen/fixtures/"+stem+".json"),
   "--geography",resolve(tmp,"geography-"+stem+".json"),
   "--burg",String(classic.source_home_burg_id),
   "--reference-radius-km",assumedRadius,"--reference-km","30",
   "--output",resolve(tmp,"reference-"+stem+"-"+kind+".json")];
  const result=spawnSync(process.execPath,args,{encoding:"utf8",timeout:90000});
  if(result.status!==0)throw Error("GAME-48 reference failed "+stem+"/"+kind+": "+result.stderr);
  const reference=JSON.parse(await readFile(resolve(tmp,"reference-"+stem+"-"+kind+".json"),"utf8"));
  if(reference.space.physical_km!=="ASSUMED_NOT_CANON"||
     reference.source_home_burg_id!==classic.source_home_burg_id)
    throw Error("Unlabelled physical assumption or shifted reference hometown");
  console.log(stem+"/"+kind+": original 16 source units vs hypothetical 30 km = "+
   JSON.stringify(reference.space.original_map_units)+
   ", original source cells "+reference.space.source_cell_centres_in_window);
 }
}
console.log("PASS: GAME-48 six strictly hypothetical physical references, no v1 context replacement");
