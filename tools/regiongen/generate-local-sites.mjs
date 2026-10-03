#!/usr/bin/env node
/** Deterministic GAME-40 local site layer + visual proof. No fixture writes. */
import {readFile,writeFile,mkdir} from "node:fs/promises";
import {createHash} from "node:crypto";
import {dirname,resolve} from "node:path";
import {populateRegion,playerSiteView} from "./local-sites.mjs";
import {renderSvg} from "./preview-region.mjs";
import {renderSiteSymbol,renderReadableLabels} from "./site-icons.mjs";

const args=process.argv.slice(2);
const arg=name=>{let i=args.indexOf(name);return i===-1?null:args[i+1]};
const file=arg("--world"),area=arg("--region"),out=arg("--output");
if(!file||!area||!out)throw Error("Usage: --world <canonical Azgaar JSON> --region <Town Forge region JSON> --output <populated region JSON>");
const worldBytes=await readFile(resolve(file));
const world=JSON.parse(worldBytes.toString("utf8"));
const region=JSON.parse(await readFile(resolve(area),"utf8"));
const actualSHA=createHash("sha256").update(worldBytes).digest("hex");
if(region.source?.world_sha256!==actualSHA)throw Error("Immutable world fingerprint does not match region origin");
const layer=populateRegion(world,region);
const combined={...region,local_sites:layer};
const jsonOutput=resolve(out),svgOutput=resolve(arg("--svg")||out.replace(/\.json$/i,".svg"));
if(jsonOutput===svgOutput||jsonOutput===resolve(file)||jsonOutput===resolve(area)||svgOutput===resolve(file)||svgOutput===resolve(area))
 throw Error("Output paths may not alias immutable source files");
await mkdir(dirname(jsonOutput),{recursive:true});
await mkdir(dirname(svgOutput),{recursive:true});
await writeFile(jsonOutput,JSON.stringify(combined)+"\n");
const shown=playerSiteView(layer);
// Player-facing SVG deliberately contains no hidden site identifiers/positions.
const unique=shown.visible;
const overlays=['<g aria-label="Discovered frontier sites">'];
for(const site of unique) overlays.push(renderSiteSymbol(site));
overlays.push(renderReadableLabels(unique));
overlays.push('</g>');
// Keep technical information outside the navigable map field.
overlays.push('<g font-family="Georgia,serif"><rect x="685" y="14" width="298" height="77" rx="3" fill="#ebe0c4" fill-opacity=".94" stroke="#554e39"/>');
overlays.push('<text x="700" y="39" fill="#342f24" font-size="19" font-weight="bold">FRONTIER REGION</text>');
overlays.push('<text x="700" y="60" fill="#484433" font-size="13">'+unique.length+' known sites · '+shown.rumours.length+' rumours</text>');
overlays.push('<text x="700" y="78" fill="#484433" font-size="12">Symbols: illustrated exploration sites</text></g>');
overlays.push('<g font-family="Georgia,serif"><rect x="600" y="940" width="386" height="44" rx="3" fill="#e6dcc1" fill-opacity=".95" stroke="#514c3c"/>');
overlays.push('<text x="610" y="956" fill="#4d493b" font-size="12">CONCEPT PREVIEW · placements and routes provisional</text>');
overlays.push('<text x="610" y="972" fill="#4d493b" font-size="12">Protection unverified · inspect in Godot (F6)</text></g>');
const svg=renderSvg(region).replace("</svg>",overlays.join("\n")+"\n</svg>");
await writeFile(svgOutput,svg);
console.log("PASS: GAME-40 "+layer.sites.length+" source/game sites; "+unique.length+" visible, "+shown.rumours.length+" rumours; no hidden-site leaks");
