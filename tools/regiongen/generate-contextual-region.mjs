#!/usr/bin/env node
/** GAME-44: separate opt-in v2 local sites, never overwrites GAME-40 v1. */
import {readFile,mkdir,writeFile,realpath} from "node:fs/promises";
import {dirname,resolve} from "node:path";
import {createHash} from "node:crypto";
import {generateContextualSites,contextualPlayerSiteView} from "./contextual-sites-v2.mjs";
import {renderConstrainedRegion} from "./render-constrained-region.mjs";
import {renderSiteSymbol,renderReadableLabels} from "./site-icons.mjs";
const args=process.argv.slice(2);
const get=k=>{const i=args.indexOf(k);return i<0?undefined:args[i+1]};
const source=get("--world"),input=get("--constrained"),output=get("--output");
if(!source||!input||!output)throw Error("Usage: --world <canonical.json> --constrained <GAME-47.json> --output <GAME-44.json>");
const svg=get("--svg") || output.replace(/\.json$/i,".svg");
const names=await Promise.all([source,input,output,svg].map(x=>realpath(resolve(x)).catch(()=>resolve(x))));
if(new Set(names).size!==names.length)throw Error("Source, constrained, JSON and SVG must differ");
const bytes=await readFile(resolve(source)),world=JSON.parse(bytes);
const composite=JSON.parse(await readFile(resolve(input),"utf8"));
if(createHash("sha256").update(bytes).digest("hex")!==composite.source_context?.parent_source_world_sha256)
 throw Error("Canonical source world fingerprint does not match");
const layer=generateContextualSites(world,composite);
const preview=contextualPlayerSiteView(layer);
const combined={...composite,local_sites_v2:layer};
// This SVG is a filtered *player-facing* POI overlay on a source-visual
// diagnostic; complete debug JSON (including hidden POIs) is NOT player UI.
const visible=preview.visible.filter(site=>site.kind!=="hometown");
const fragments=['<g id="known-game-owned-pois">'];
for(const site of visible)fragments.push(renderSiteSymbol(site));
fragments.push(renderReadableLabels(visible),'</g>');
const text='<text x="668" y="111" fill="#333127" font-family="Georgia,serif" font-size="12">Known nearby sites: '+
 preview.visible.length+' · Rumours: '+preview.rumours.length+'</text>';
const image=renderConstrainedRegion(composite).replace("</svg>",fragments.join("\n")+"\n"+text+"\n</svg>");
await mkdir(dirname(resolve(output)),{recursive:true});
await mkdir(dirname(resolve(svg)),{recursive:true});
await writeFile(resolve(output),JSON.stringify(combined,null,2)+"\n");
await writeFile(resolve(svg),image);
console.log("PASS: GAME-44 v2 sites "+layer.sites.length+
 " generated/context source, "+preview.visible.length+" known, "+
 preview.rumours.length+" non-positional rumours; prior v1 site records untouched");
