#!/usr/bin/env node
/** GAME-49 proof, not walkable geography. Exactly source vs approximation vs
 * unsupported inferred/unknown truth is shown. */
import {readFile,writeFile,mkdir} from "node:fs/promises";
import {resolve,dirname} from "node:path";
import {createHash} from "node:crypto";
import {buildSourceAuthority} from "./source-authority.mjs";
const xml=v=>String(v).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;");
const points=v=>v.map(p=>p.map(n=>Math.round(n*100)/100).join(",")).join(" ");
for(const stem of ["game-11-determinism","atlas-showcase"])for(const kind of ["shore","river","highland"]){
 const tmp=resolve("tools/regiongen/.tmp");
 const worldFile=resolve("tests/worldgen/fixtures/"+stem+".json");
 const raw=await readFile(worldFile),world=JSON.parse(raw);
 const ref=JSON.parse(await readFile(resolve(tmp,"reference-"+stem+"-"+kind+".json"),"utf8"));
 const model=buildSourceAuthority(world,ref,createHash("sha256").update(raw).digest("hex"));
 const home=model.source_macro.towns.find(b=>b.source_burg_id===model.identity.origin_source_burg_id);
 const s=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">',
  '<rect width="1000" height="1000" fill="#8eabb8"/>'];
 for(const f of model.source_macro.feature_polygons.filter(f=>f.classification==="land_boundary"))
  s.push('<polygon points="'+points(f.source_polygon)+'" fill="#d9c9a2"/>');
 for(const f of model.source_macro.feature_polygons.filter(f=>f.classification==="freshwater_lake"))
  s.push('<polygon points="'+points(f.source_polygon)+'" fill="#8eabb8" stroke="#386e80" stroke-width="2"/>');
 for(const route of model.source_macro.routes)for(const seg of route.segments)
  s.push('<polyline points="'+points(seg.local_points)+'" fill="none" stroke="'+(route.classification==="sea_lane"?"#44818d":"#806448")+
  '" stroke-width="4"'+(route.classification==="sea_lane"?' stroke-dasharray="9 7"':'')+'/>');
 for(const river of model.derived_approximate.rivers)for(const seg of river.segments)
  s.push('<polyline points="'+points(seg.local_points)+'" stroke="#3e879f" stroke-width="3" stroke-dasharray="4 8" fill="none"/>');
 for(const t of model.source_macro.towns){
  s.push('<circle cx="'+t.local_position[0]+'" cy="'+t.local_position[1]+'" r="'+(t.source_burg_id===home?.source_burg_id?12:7)+'" fill="#8b3227" stroke="#fcf2d4" stroke-width="2"/>');
 }
 const name=xml(home?.name||"Unknown");
 s.push('<rect x="9" y="9" width="970" height="133" fill="#efe0be" fill-opacity=".95" stroke="#5f5742"/>',
 '<text x="22" y="37" font-family="Georgia" font-size="23" fill="#272b26">MACRO SOURCE EVIDENCE — '+name+'</text>',
 '<text x="22" y="62" font-family="Georgia" font-size="14" fill="#554b39">Brown lines and burgs: original Azgaar source at coarse resolution (NOT a pathfinding map)</text>',
 '<text x="22" y="82" font-family="Georgia" font-size="14" fill="#554b39">Dotted blue: approximate river cells | Town Forge fine detail: NOT GENERATED</text>',
 '<text x="22" y="104" font-family="Georgia" font-size="14" fill="#8a4330">30 km at HYPOTHETICAL Earth-radius reference; source cells in crop: '+
  model.assumption.source_cell_samples+'</text>',
 '<text x="22" y="126" font-family="Georgia" font-size="14" fill="#8a4330">Fine bridges, ports, safe roads and actual walking surface: UNKNOWN / UNVERIFIED</text>',
 '<rect x="10" y="959" width="980" height="29" fill="#efe0be" stroke="#5f5742"/>',
 '<text x="20" y="979" font-family="Georgia" font-size="14">GAME-49  Source != approximate != inferred != unknown  ·  Context '+xml(stem+" / "+kind)+'</text>',
 '</svg>');
 const target=resolve(tmp,"authority-"+stem+"-"+kind+".json");
 await mkdir(dirname(target),{recursive:true});
 await writeFile(target,JSON.stringify(model,null,2)+"\n");
 await writeFile(target.replace(".json",".svg"),s.join("\n")+"\n");
 console.log(stem+"/"+kind+": original towns "+model.source_macro.towns.length+
  ", routes "+model.source_macro.routes.length+", source cells "+model.assumption.source_cell_samples+
  ", coarse = "+model.flags.sparse_source_samples);
}
console.log("PASS: GAME-49 six actual original-vs-assumed reference source authority diagnostic maps");
