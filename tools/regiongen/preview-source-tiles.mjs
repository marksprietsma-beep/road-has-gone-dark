#!/usr/bin/env node
/** GAME-39 diagnostic: no modification to Town Forge or source worlds. */
import {readFile,mkdir,writeFile} from "node:fs/promises";
import {resolve,dirname} from "node:path";
import {createHash} from "node:crypto";
import {buildTileConstraints,tileForBurg,sideCrossings,sideShorelineCrossings,WORLD_UNITS_PER_TILE} from "./source-projection.mjs";
const args=process.argv.slice(2);
const get=k=>{const i=args.indexOf(k);return i<0?undefined:args[i+1]};
const input=get("--world"),output=get("--output"),rawId=get("--burg");
if(!input||!output||rawId===undefined||!/^[1-9]\d*$/.test(rawId))throw Error("Usage: --world <existing fixture> --burg <source ID> --output <json> [--svg <svg>] [--tile-x <n> --tile-y <n>]");
const raw=await readFile(resolve(input)),world=JSON.parse(raw.toString("utf8"));
const hash=createHash("sha256").update(raw).digest("hex");
const geometryPath=get("--geography");
const geographySidecar=geometryPath?JSON.parse(await readFile(resolve(geometryPath),"utf8")):null;
const xy=tileForBurg(world,Number(rawId));
const tx=get("--tile-x")!==undefined?Number(get("--tile-x")):xy[0],ty=get("--tile-y")!==undefined?Number(get("--tile-y")):xy[1];
const first=buildTileConstraints(world,tx,ty,hash,geographySidecar);
const second=buildTileConstraints(world,tx+1,ty,hash,geographySidecar);
const constraints={schema_version:1,diagnostic:true,
  description:"Two adjacent real Azgaar source tiles, not rendered Town Forge interiors",
  first,second,shared_boundary_key:"V:"+((tx+1)*WORLD_UNITS_PER_TILE)+":"+ty,
  east_crossings:sideCrossings(first,"E"),west_crossings:sideCrossings(second,"W"),
  shoreline_east:sideShorelineCrossings(first,"E"),shoreline_west:sideShorelineCrossings(second,"W")};
const xml=t=>String(t).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;");
const pts=points=>points.map(p=>p.join(",")).join(" ");
function renderOne(tile,offset) {
 const output=['<g transform="translate('+offset+' 65)"><rect x="0" y="0" width="500" height="500" fill="'+(geographySidecar?"#88acb6":"#d7ccb0")+'" stroke="#675840" stroke-width="2"/>'];
 const scale=0.5;
 if(tile.source_shoreline){
  const polygons=tile.source_shoreline.polygons||[];
  for(const feature of polygons.filter(p=>p.kind==="source_land_boundary"))output.push(
   '<polygon points="'+pts(feature.local_points.map(p=>p.map(v=>+(v*scale).toFixed(3))))+'" fill="#d7ccb0" stroke="none"/>');
  for(const feature of polygons.filter(p=>p.kind==="source_lake"))output.push(
   '<polygon points="'+pts(feature.local_points.map(p=>p.map(v=>+(v*scale).toFixed(3))))+'" fill="#88acb6" stroke="none"/>');
  for(const seg of tile.source_shoreline.segments)output.push(
   '<polyline points="'+pts(seg.local_points.map(p=>p.map(v=>+(v*scale).toFixed(3))))+'" stroke="#365c60" stroke-width="1.3" fill="none"/>');
 }
 for(const seg of tile.segments){
  const color=seg.kind==="azgaar_river"?"#5c8ca0":"#715943",width=seg.kind==="azgaar_river"?2:3;
  output.push('<polyline points="'+pts(seg.local_points.map(p=>p.map(v=>+(v*scale).toFixed(3))))+'" fill="none" stroke="'+color+'" stroke-width="'+width+'" opacity=".85"/>');
 }
 for(const burg of tile.burgs){
  const [x,y]=burg.local_position.map(v=>v*scale);
  output.push('<circle cx="'+x+'" cy="'+y+'" r="6" fill="#6b3128" stroke="#f7ebcb" stroke-width="2"/>');
  output.push('<text x="'+(x+9)+'" y="'+(y-8)+'" font-size="12" font-family="Georgia" fill="#28221a">'+xml(burg.label)+'</text>');
 }
 for(const x of tile.crossings){
  const [px,py]=x.local_position.map(v=>v*scale);
  output.push('<circle cx="'+px+'" cy="'+py+'" r="3" fill="'+(x.kind==="azgaar_route"?"#9b6d28":"#306d8b")+'"/>');
 }
 output.push('<text x="13" y="28" font-family="Georgia" font-size="18" fill="#302a20">Source tile '+tile.tile.x+','+tile.tile.y+'</text></g>');
 return output.join("\n");
}
const svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="650" viewBox="0 0 1080 650">',
 '<rect width="1080" height="650" fill="#f0e5c8"/>',
 '<text x="40" y="39" font-size="22" font-family="Georgia">Azgaar shared geometry — GAME-39</text>',
 renderOne(first,40),renderOne(second,540),
 '<text x="40" y="592" font-family="Georgia" font-size="14" fill="#463b2c">Brown: original roads | Blue: approximate rivers | Dark cyan: source shorelines | Red: actual burgs</text>',
 '<text x="40" y="619" font-family="Georgia" font-size="13" fill="#744c34">NOT calibrated to km. Azgaar shorelines '+(geographySidecar?"exact from vertex sidecar":"not supplied")+'; Town Forge terrain is unaligned.</text>',
 '</svg>'].join("\n");
const dest=resolve(output),visual=resolve(get("--svg")||output.replace(/\.json$/i,".svg"));
if(dest===visual||dest===resolve(input)||visual===resolve(input)|| (geometryPath&&[dest,visual].includes(resolve(geometryPath))))throw Error("Output aliases immutable source");
await mkdir(dirname(dest),{recursive:true});await mkdir(dirname(visual),{recursive:true});
await writeFile(dest,JSON.stringify(constraints,null,2)+"\n");
await writeFile(visual,svg+"\n");
console.log("GAME-39 shared border "+constraints.shared_boundary_key+" crossings E "+constraints.east_crossings.length+", W "+constraints.west_crossings.length);
