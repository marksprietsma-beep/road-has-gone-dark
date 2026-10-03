#!/usr/bin/env node
/** QA-only neighbourhood map of genuine Azgaar source geography, NOT Town Forge art. */
import {readFile,writeFile,mkdir} from "node:fs/promises";
import {createHash} from "node:crypto";
import {resolve,dirname} from "node:path";
import {buildLocalContext,buildReferenceLocalContext} from "./local-source-context.mjs";
const args=process.argv.slice(2);
const get=k=>{const i=args.indexOf(k);return i<0?undefined:args[i+1]};
const source=get("--world"),output=get("--output"),home=get("--burg"),geo=get("--geography");
if(!source||!output||!/^[1-9]\d*$/.test(home||""))throw Error("Usage: --world <canonical.json> --burg <id> --output <preview.json> [--geography <sidecar.json>]");
const data=await readFile(resolve(source)),world=JSON.parse(data.toString("utf8"));
const sha=createHash("sha256").update(data).digest("hex");
const sidecar=geo?JSON.parse(await readFile(resolve(geo),"utf8")):null;
const referenceRadius=get("--reference-radius-km"), referenceSpan=get("--reference-km");
if((referenceRadius===undefined)!==(referenceSpan===undefined))
 throw Error("--reference-radius-km and --reference-km must be supplied together");
const result=referenceRadius===undefined?
 buildLocalContext(world,Number(home),sha,sidecar):
 buildReferenceLocalContext(world,Number(home),sha,sidecar,Number(referenceSpan),Number(referenceRadius));
const reference=result.space.angular_reference;
const scaleCaption=reference?
 "HYPOTHETICAL "+reference.hypothetical_square_km+" km reference; assumed globe radius "+reference.reference_radius_km+" km.":
 "16 Azgaar map units. NOT 30 km. Town Forge interior not aligned.";
const esc=t=>String(t).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;");
const coords=ps=>ps.map(p=>p.join(",")).join(" ");
const lines=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">',
 '<rect width="1000" height="1000" fill="'+(sidecar?"#8fb7c0":"#d8c9a5")+'"/>'];
const all=result.source_features;
for(const p of all.filter(p=>p.classification==="land_boundary"))
 lines.push('<polygon points="'+coords(p.local_polygon)+'" fill="#d8c9a5"/>');
for(const p of all.filter(p=>p.classification==="freshwater_lake"))
 lines.push('<polygon points="'+coords(p.local_polygon)+'" fill="#8fb7c0"/>');
for(const route of result.source_routes)for(const seg of route.segments){
 const cls=route.classification;
 const color=cls==="sea_lane"?"#3b727d":"#765942";
 const dash=cls==="sea_lane"?' stroke-dasharray="9,7"':'';
 lines.push('<polyline points="'+coords(seg.local_points)+'" stroke="'+color+'" stroke-width="'+(cls==="trail"?2.5:4)+'"'+dash+' fill="none" stroke-linecap="round"/>');
}
for(const r of result.source_rivers)for(const seg of r.segments)
 lines.push('<polyline points="'+coords(seg.local_points)+'" stroke="#5c91a4" stroke-width="2.5" fill="none" stroke-dasharray="3 4"/>');
for(const b of result.source_burgs){
 const home=b.source_id===result.source_home_burg_id;
 lines.push('<circle cx="'+b.local_position[0]+'" cy="'+b.local_position[1]+'" r="'+(home?10:5)+'" fill="'+(home?"#9b392d":"#594137")+'" stroke="#f4e7c8" stroke-width="2"/>');
 if(home)lines.push('<text x="'+(b.local_position[0]+15)+'" y="'+(b.local_position[1]-10)+'" font-size="22" font-family="Georgia" fill="#242320">'+esc(b.name)+'</text>');
}
lines.push('<rect x="10" y="10" width="740" height="91" rx="4" fill="#f0e1bd" fill-opacity=".94" stroke="#5b513c"/>',
 '<text x="25" y="40" font-family="Georgia" font-size="22" fill="#2a2820">SOURCE NEIGHBOURHOOD — '+esc(result.source_burgs.find(b=>b.source_id===result.source_home_burg_id).name)+'</text>',
 '<text x="25" y="65" font-family="Georgia" font-size="15" fill="#504839">'+esc(scaleCaption)+'</text>',
 '<text x="25" y="84" font-family="Georgia" font-size="13" fill="#504839">'+(geo?"Source coastline/lakes exact":"Source coastline missing — no sidecar")+' · Rivers approximate · Road safety unknown</text>',
 '</svg>');
const dest=resolve(output),svg=dest.replace(/\.json$/i,".svg");
if(dest===resolve(source)||dest===resolve(geo||"~")||svg===resolve(source)||svg===dest)throw Error("Refusing aliasing output");
await mkdir(dirname(dest),{recursive:true});
await writeFile(dest,JSON.stringify(result,null,2)+"\n");
await writeFile(svg,lines.join("\n")+"\n");
console.log("GAME-46 source local map: "+result.source_burgs.length+" burg(s), "+result.source_routes.length+" source routes, "+result.source_features.length+" coastline/lake shapes");
