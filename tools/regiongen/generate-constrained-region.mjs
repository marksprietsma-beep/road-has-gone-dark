#!/usr/bin/env node
/** GAME-47: compose source-bound local preview + actual pinned Town Forge
 * decoration while preventing Town Forge roads or water replacing Azgaar. */
import {readFile,mkdir,writeFile,realpath} from "node:fs/promises";
import {spawnSync} from "node:child_process";
import {createHash} from "node:crypto";
import {dirname,resolve} from "node:path";
import {buildLocalContext} from "./local-source-context.mjs";
import {composeLocalRegion} from "./compose-local-region.mjs";
import {renderConstrainedRegion} from "./render-constrained-region.mjs";
const argv=process.argv.slice(2);
const get=flag=>{const i=argv.indexOf(flag);return i>=0?argv[i+1]:undefined};
const source=get("--world"),geo=get("--geography"),output=get("--output"),burgArg=get("--burg");
if(!source||!geo||!output||!/^[1-9]\d*$/.test(burgArg||"")) {
 console.error("Usage: --world <canonical.json> --geography <matching vertex sidecar> --burg <source ID> --output <composite.json>");
 process.exit(2);
}
const svgOutput=get("--svg")||(/\.json$/i.test(output)?output.replace(/\.json$/i,".svg"):output+".svg");
const sourcePath=resolve(source),geographyPath=resolve(geo),jsonPath=resolve(output),svgPath=resolve(svgOutput);
const originalPaths=await Promise.all([sourcePath,geographyPath,jsonPath,svgPath].map(p=>realpath(p).catch(()=>p)));
if(new Set(originalPaths).size!==4)throw Error("World, sidecar, JSON and SVG must have distinct paths");
const worldBytes=await readFile(sourcePath),fingerprint=createHash("sha256").update(worldBytes).digest("hex");
const world=JSON.parse(worldBytes.toString("utf8"));
const sidecar=JSON.parse(await readFile(geographyPath,"utf8"));
const burg=Number(burgArg);
const context=buildLocalContext(world,burg,fingerprint,sidecar);
// Provider output is always isolated under ignored .tmp, never overwrites
// the accepted GAME-21 geometry or live game region/cache records.
const internal=resolve("tools/regiongen/.tmp/game47-provider-"+fingerprint.slice(0,12)+"-"+burg+".json");
await mkdir(dirname(internal),{recursive:true});
const run=spawnSync(process.execPath,["tools/regiongen/generate-region.mjs",
 "--world",sourcePath,"--burg",String(burg),"--output",internal],
 {encoding:"utf8",timeout:120000,maxBuffer:8*1024*1024});
if(run.status!==0)throw Error("Pinned Town Forge adapter failed: "+run.stderr+"\n"+run.stdout);
const native=JSON.parse(await readFile(internal,"utf8"));
const region=composeLocalRegion(world,context,native);
await mkdir(dirname(jsonPath),{recursive:true});
await mkdir(dirname(svgPath),{recursive:true});
await writeFile(jsonPath,JSON.stringify(region,null,2)+"\n");
await writeFile(svgPath,renderConstrainedRegion(region));
console.log("GAME-47 source-constrained decor: "+burg+" trees="+region.landscape.trees.length+
 " ridge marks="+region.landscape.ridges.length+
 " real roads="+context.source_routes.length+
 " original features="+context.source_features.length+"; physical km UNCALIBRATED");
