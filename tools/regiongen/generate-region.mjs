#!/usr/bin/env node
/** GAME-21: call the real vendored Town Forge landscape generator. */
import {readFile, mkdir, writeFile, realpath} from "node:fs/promises";
import {createHash} from "node:crypto";
import {createRequire} from "node:module";
import {dirname, resolve} from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";
import {renderSvg} from "./preview-region.mjs";
import {sourceContext, geometryPoints} from "./source-context.mjs";
const here=dirname(fileURLToPath(import.meta.url));
const root=resolve(here,"../..");
const vendor=resolve(root,"vendor/town-forge");
const vendorAzgaar=resolve(root,"vendor/azgaar");
const buildRequire=createRequire(resolve(vendorAzgaar,"package.json"));
const ts=buildRequire("typescript");
const args=process.argv.slice(2);
const value=flag=>{const i=args.indexOf(flag);return i<0?undefined:args[i+1]};
const source=value("--world"), output=value("--output"),idText=value("--burg");
const xText=value("--x")??"0",yText=value("--y")??"0";
const regionKm=Number(value("--km")??30);
const isInt=s=>typeof s==="string"&&/^-?(0|[1-9]\d*)$/.test(s)&&Number.isSafeInteger(Number(s));
if(!source||!output||!isInt(idText)||!isInt(xText)||!isInt(yText)||!Number.isFinite(regionKm)||regionKm<10||regionKm>60){
 console.error("Usage: --world <Azgaar JSON fixture> --burg <existing numeric burg> --output <region.json> [--x 0] [--y 0] [--km 10..60]");
 process.exit(2);
}
// Reject aliases before any writes: output must never overwrite the world or JSON.
const svgOutput=value("--svg")??(/\.json$/i.test(output)?output.replace(/\.json$/i,".svg"):output+".svg");
const canonicalPath=async p=>realpath(resolve(p)).catch(()=>resolve(p));
const destinations=await Promise.all([source,output,svgOutput].map(canonicalPath));
if(new Set(destinations).size!==3)throw Error("World, JSON and SVG paths must be distinct");
const input=await readFile(resolve(source));
const world=JSON.parse(input.toString("utf8"));
const burgId=Number(idText),xTile=Number(xText),yTile=Number(yText);
const {burg,cell,terrain,waterSide,wetNeighborIds,forestMul}=sourceContext(world,burgId);
const seed="region:v2|"+world.seed+"|azgaar:"+world.generator.version+"|cell:"+burg.cell+"|tile:"+xTile+","+yTile;
const fixtureSHA=createHash("sha256").update(input).digest("hex");
const temp=resolve(root,"tools/regiongen/.tmp");
await mkdir(temp,{recursive:true});
// Upstream's 1.2.4 source is TypeScript reconstructed from the original
// Obsidian bundle. Transpile the *unmodified* pinned modules into isolated
// ignored ESM files with the already-pinned TypeScript compiler. No Obsidian
// runtime or speculative reimplementation of generateFull is required.
const dist=resolve(temp,"townforge-dist");
await mkdir(dist,{recursive:true});
await writeFile(resolve(dist,"package.json"),'{"type":"module"}\n');
for(const name of ["types","rng","geometry","roads","mountains","landscape","buildings","generate"]){
 const original=await readFile(resolve(vendor,"src",name+".ts"),"utf8");
 const imports=original.replace(/from ["'](\.\/[^"']+)["']/g,(_whole,relative)=>'from "'+relative+'.js"');
 const code=ts.transpileModule(imports,{compilerOptions:{
  module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022,
  moduleResolution:ts.ModuleResolutionKind.Node10
 }}).outputText;
 await writeFile(resolve(dist,name+".js"),code);
}
const {generateFull}=await import(pathToFileURL(resolve(dist,"generate.js")).href);
const scene=generateFull(terrain,seed,{mode:"landscape",roughness:0.46,octaves:5,
 seaSide:waterSide??undefined,overrides:{forestDensity:forestMul},showRoads:true,showForest:true});
const points=geometryPoints;
const polygons=(items,field)=>Array.isArray(items)?items.map(it=>points(field?it?.[field]:it)).filter(a=>a.length>=3):[];
const paths=(items,field)=>Array.isArray(items)?items.map(it=>points(field?it?.[field]:it)).filter(a=>a.length>=2):[];
const roads=(scene.roads||[]).map((r,i)=>({id:"road:"+i,role:r.role??"unknown",kind:r.class??"road",
 points:points(r.points)})).filter(r=>r.points.length>=2);
const region={
 schema_version:1,
 id:"region:v2:"+fixtureSHA+":cell:"+burg.cell+":tile:"+xTile+","+yTile+":km:"+regionKm,
 generation_version:2,
 provider:{name:"town-forge",version:"1.2.4",commit:"4b25a37c14c80970d2b66f0c587468c7493855d3",mode:"landscape"},
 source:{world_seed:world.seed,azgaar_version:world.generator.version,world_sha256:fixtureSHA,
  state_id:Number(cell.state),province_id:Number(cell.province),cell_id:Number(burg.cell),burg_id:burgId,
  cell_biome:Number(cell.biome),cell_height:Number(cell.height),cell_river:Number(cell.river),cell_coast:Number(cell.terrain)===1,
  shoreline_water_kind:cell.terrain===1?"unknown_lake_or_sea":"none",water_side:waterSide,wet_neighbor_ids:wetNeighborIds},
 region:{x:xTile,y:yTile,side_km:regionKm,grid_units:1000,scale_calibration:"provisional",terrain,forest_density_multiplier:forestMul},
 constraints:{road_edges:"provisional_town_forge",rivers:cell.river>0?(terrain==="river"?"azgaar_river_present_course_provisional":"source_river_not_rendered"):"none",
  coast:terrain==="coastal"?(waterSide?"neighbor_water_bearing_only_shape_provisional":"shoreline_orientation_unknown"):"none",
  elevation:cell.height>=68&&terrain!=="mountain"?"source_highland_not_rendered":"style_only",
  tile_geography:"parent_cell_style_only_not_spatially_sampled",seams:"not_yet_stitched"},
 geometry:{water:points(scene.water),river_centreline:points(scene.centreline),
 roads,forests:polygons(scene.forests,"polygon"),ridges:paths(scene.ridges),
 mountain_count:Array.isArray(scene.mountains)?scene.mountains.length:0}
};
await mkdir(dirname(resolve(output)),{recursive:true});
const bytes=JSON.stringify(region)+"\n";
await writeFile(resolve(output),bytes);
await mkdir(dirname(resolve(svgOutput)),{recursive:true});
await writeFile(resolve(svgOutput),renderSvg(region));
console.log(createHash("sha256").update(bytes).digest("hex")+"  "+output);
console.log("GAME-21 "+region.id+": terrain="+terrain+" roads="+roads.length+" forests="+region.geometry.forests.length+" side="+regionKm+"km (provisional scale)");
