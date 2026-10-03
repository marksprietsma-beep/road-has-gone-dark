#!/usr/bin/env node
/** GAME-21: call the real vendored Town Forge landscape generator. */
import {readFile, mkdir, writeFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {createRequire} from "node:module";
import {dirname, resolve} from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";
import {renderSvg} from "./preview-region.mjs";
const here=dirname(fileURLToPath(import.meta.url));
const root=resolve(here,"../..");
const vendor=resolve(root,"vendor/town-forge");
const vendorAzgaar=resolve(root,"vendor/azgaar");
const buildRequire=createRequire(resolve(vendorAzgaar,"package.json"));
const {build}=await import(pathToFileURL(buildRequire.resolve("esbuild")).href);
const args=process.argv.slice(2);
const value=flag=>{const i=args.indexOf(flag);return i<0?undefined:args[i+1]};
const source=value("--world"), output=value("--output"),idText=value("--burg");
const xText=value("--x")??"0",yText=value("--y")??"0";
const regionKm=Number(value("--km")??30);
const isInt=s=>typeof s==="string"&&/^(0|[1-9]\d*)$/.test(s);
if(!source||!output||!isInt(idText)||!isInt(xText)||!isInt(yText)||!Number.isFinite(regionKm)||regionKm<10||regionKm>60){
 console.error("Usage: --world <Azgaar JSON fixture> --burg <existing numeric burg> --output <region.json> [--x 0] [--y 0] [--km 10..60]");
 process.exit(2);
}
const input=await readFile(resolve(source));
const world=JSON.parse(input.toString("utf8"));
if(world.schemaVersion!==1||world.generator?.provider!=="azgaar"||world.generator.version!=="1.153.1")throw Error("Unsupported Azgaar fixture/generator");
const burgId=Number(idText),xTile=Number(xText),yTile=Number(yText);
const burg=(world.settlements||[]).find(b=>b&&b.i===burgId);
if(!burg||burg.cell===undefined)throw Error("Burg ID missing from canonical world");
const cellIndex=(world.cells?.ids||[]).indexOf(burg.cell);
if(cellIndex<0)throw Error("Burg source cell not in canonical map");
if(burg.hidden)throw Error("Starting burg is source-hidden");
const cell={i:burg.cell,biome:world.cells.biome[cellIndex],height:world.cells.heights[cellIndex],state:world.cells.state[cellIndex],
 province:world.cells.province[cellIndex],river:world.cells.river[cellIndex],terrain:world.cells.terrain[cellIndex]};
const terrain=Number(cell.terrain)===1?"coastal":Number(cell.river)>0?"river":Number(cell.height)>=68?"mountain":"inland";
const forestBiomes=new Set([5,6,7,8,9]);
const dryBiomes=new Set([1,2,10,11]);
const forestMul=forestBiomes.has(Number(cell.biome))?1.8:dryBiomes.has(Number(cell.biome))?0.25:1;
const seed="region:v1|"+world.seed+"|azgaar:"+world.generator.version+"|cell:"+burg.cell+"|tile:"+xTile+","+yTile;
const fixtureSHA=createHash("sha256").update(input).digest("hex");
const temp=resolve(root,"tools/regiongen/.tmp");
await mkdir(temp,{recursive:true});
const bundle=resolve(temp,"townforge-provider-"+process.pid+".mjs");
await build({entryPoints:[resolve(vendor,"src/generate.ts")],bundle:true,platform:"node",format:"esm",outfile:bundle,logLevel:"error"});
const {generateFull}=await import(pathToFileURL(bundle).href);
const scene=generateFull(terrain,seed,{mode:"landscape",roughness:0.46,octaves:5,
 overrides:{forestDensity:forestMul},showRoads:true,showForest:true});
const round=n=>{if(!Number.isFinite(n))throw Error("Town Forge returned nonfinite geometry");return Math.round(n*1000)/1000};
const points=pts=>(Array.isArray(pts)?pts:[]).filter(p=>p&&Number.isFinite(p.x)&&Number.isFinite(p.y)).map(p=>[round(p.x),round(p.y)]);
const polygons=(items,field)=>Array.isArray(items)?items.map(it=>points(field?it?.[field]:it)).filter(a=>a.length>=3):[];
const paths=(items,field)=>Array.isArray(items)?items.map(it=>points(field?it?.[field]:it)).filter(a=>a.length>=2):[];
const roads=(scene.roads||[]).map((r,i)=>({id:"road:"+i,role:r.role??"unknown",kind:r.class??"road",
 points:points(r.points)})).filter(r=>r.points.length>=2);
const region={
 schema_version:1,
 id:"region:v1:"+fixtureSHA.slice(0,16)+":cell:"+burg.cell+":tile:"+xTile+","+yTile,
 provider:{name:"town-forge",version:"1.2.4",commit:"4b25a37c14c80970d2b66f0c587468c7493855d3",mode:"landscape"},
 source:{world_seed:world.seed,azgaar_version:world.generator.version,world_sha256:fixtureSHA,
  state_id:Number(cell.state),province_id:Number(cell.province),cell_id:Number(burg.cell),burg_id:burgId,
  cell_biome:Number(cell.biome),cell_height:Number(cell.height),cell_river:Number(cell.river),cell_coast:Number(cell.terrain)===1},
 region:{x:xTile,y:yTile,side_km:regionKm,grid_units:1000,scale_calibration:"provisional",terrain,forest_density_multiplier:forestMul},
 constraints:{road_edges:"provisional_town_forge",rivers:terrain==="river"?"azgaar_river_present_course_provisional":"none",
  coast:terrain==="coastal"?"azgaar_coastal_cell_orientation_provisional":"none",seams:"not_yet_stitched"},
 geometry:{water:points(scene.water),river_centreline:points(scene.centreline),
 roads,forests:polygons(scene.forests,"polygon"),ridges:paths(scene.ridges),
 mountain_count:Array.isArray(scene.mountains)?scene.mountains.length:0}
};
await mkdir(dirname(resolve(output)),{recursive:true});
const bytes=JSON.stringify(region)+"\n";
await writeFile(resolve(output),bytes);
const svgOutput=value("--svg")??String(output).replace(/\.json$/i,".svg");
await mkdir(dirname(resolve(svgOutput)),{recursive:true});
await writeFile(resolve(svgOutput),renderSvg(region));
console.log(createHash("sha256").update(bytes).digest("hex")+"  "+output);
console.log("GAME-21 "+region.id+": terrain="+terrain+" roads="+roads.length+" forests="+region.geometry.forests.length+" side="+regionKm+"km (provisional scale)");
