#!/usr/bin/env node
/** Existing GAME-49 canonical authority examples remain unchanged.
 * Optional GAME-51 output is strictly an inferred illustration pair. */
import {readFile,mkdir,writeFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {resolve,dirname} from "node:path";
import {buildInferredFineTerrain} from "./inferred-fine-terrain.mjs";
import {renderInferredFineSvg} from "./render-inferred-fine.mjs";
const root=resolve("tools/regiongen/.tmp");
for(const stem of ["game-11-determinism","atlas-showcase"])
 for(const kind of ["shore","river","highland"]){
  const raw=await readFile(resolve("tests/worldgen/fixtures/"+stem+".json"));
  const world=JSON.parse(raw),hash=createHash("sha256").update(raw).digest("hex");
  const context=JSON.parse(await readFile(resolve(root,"reference-"+stem+"-"+kind+".json"),"utf8"));
  const authority=JSON.parse(await readFile(resolve(root,"authority-"+stem+"-"+kind+".json"),"utf8"));
  const field=buildInferredFineTerrain(world,context,hash);
  const file=resolve(root,"fine-"+stem+"-"+kind+".json");
  const svg=renderInferredFineSvg(authority,field);
  await mkdir(dirname(file),{recursive:true});
  await writeFile(file,JSON.stringify(field)+"\n");
  await writeFile(file.replace(/\.json$/i,".svg"),svg);
  const land=field.vertices.filter(v=>v.land).length;
  console.log(stem+"/"+kind+": inferred grid vertices "+field.vertices.length+
   ", source-land vertices "+land+", unique source cells in reference "+
   context.space.source_cell_centres_in_window);
 }
console.log("PASS: GAME-51 six original-world non-authoritative inferred relief/forest maps");
