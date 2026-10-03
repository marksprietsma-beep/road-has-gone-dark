#!/usr/bin/env node
/** GAME-54: v1 source-window integration proof, NOT gameplay or save migration.
 * The GAME-44 sites and GAME-51 field MUST use the exact same context.
 */
import {readFile,writeFile,mkdir,realpath} from "node:fs/promises";
import {createHash} from "node:crypto";
import {dirname,resolve} from "node:path";
import {buildSourceAuthority} from "./source-authority.mjs";
import {buildInferredFineTerrain} from "./inferred-fine-terrain.mjs";
import {generateContextualSites,contextualPlayerSiteView} from "./contextual-sites-v2.mjs";
import {renderInferredFineSvg} from "./render-inferred-fine.mjs";
import {renderSiteSymbol,renderReadableLabels} from "./site-icons.mjs";
const args=process.argv.slice(2);
const get=k=>{const i=args.indexOf(k);return i<0?undefined:args[i+1]};
const worldArg=get("--world"),regionArg=get("--constrained"),output=get("--output");
if(!worldArg||!regionArg||!output)throw Error("Expected --world source.json --constrained GAME47.json --output player.json [--audit-output debug.json]");
const paths=[worldArg,regionArg,output,output.replace(/\.json$/i,".svg"),...(get("--audit-output")?[get("--audit-output")]:[])];
const absolute=await Promise.all(paths.map(p=>realpath(resolve(p)).catch(()=>resolve(p))));
if(new Set(absolute).size!==absolute.length)throw Error("Outputs must not overwrite source or each other");
const original=await readFile(resolve(worldArg)),world=JSON.parse(original);
const hash=createHash("sha256").update(original).digest("hex");
const composite=JSON.parse(await readFile(resolve(regionArg),"utf8"));
const context=composite.source_context;
if(context?.space?.kind!=="source_neighbourhood_window" ||
  context?.space?.physical_km!=="UNCALIBRATED" ||
  context.parent_source_world_sha256!==hash)
 throw Error("GAME-54 must use matching 16-source-unit context, NOT the hypothetical 30km reference");
const authority=buildSourceAuthority(world,context,hash);
const fine=buildInferredFineTerrain(world,context,hash);
const sites=generateContextualSites(world,composite);
if(authority.identity.source_context_id!==fine.source_context_id ||
   sites.source_context_id!==fine.source_context_id ||
   sites.source_burg_id!==authority.identity.origin_source_burg_id)
 throw Error("Conflicting sites, source geography or inference viewport");
const player=contextualPlayerSiteView(sites);
const visible=player.visible.filter(p=>p.kind!=="hometown");
const symbols=visible.map(p=>renderSiteSymbol(p)).join("\n");
const labels=renderReadableLabels(visible);
const annotation='<g id="known-contextual-sites" data-source-window="shared-v1">'+symbols+
 "\n"+labels+"</g>";
const svg=renderInferredFineSvg(authority,fine).replace("</svg>",annotation+"</svg>");
const playerJSON={
 schema_version:1,role:"PLAYER_PREVIEW_NOT_GAME_SAVE",
 source_region:composite.id,source_context:context.id,
 original_world_sha256:hash,inferred_field_id:fine.id,
 km_scale:"UNCALIBRATED_SOURCE_UNITS",
 route_safety:"UNKNOWN",fine_walkable:"UNKNOWN",
 migration:"NOT_AUTOMATIC",
 known_sites:player.visible,rumours:player.rumours
};
const file=resolve(output),svgPath=resolve(output.replace(/\.json$/i,".svg"));
await mkdir(dirname(file),{recursive:true});
await writeFile(file,JSON.stringify(playerJSON,null,2)+"\n");
await writeFile(svgPath,svg+"\n");
if(get("--audit-output")){
 const audit=resolve(get("--audit-output"));
 await mkdir(dirname(audit),{recursive:true});
 await writeFile(audit,JSON.stringify({
  schema_version:1,role:"DEVELOPER_ONLY_UNFILTERED_NEVER_PLAYER_SAVE",
  original:authority,inference:fine,sites
 },null,2)+"\n");
}
console.log("GAME-54 source-v1 unified "+context.source_home_burg_id+
 " original burgs="+context.source_burgs.length+" known sites="+player.visible.length+
 " rumours="+player.rumours.length+" (developer-only hidden data separated)");
