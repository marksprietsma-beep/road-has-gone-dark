#!/usr/bin/env node
/** Deterministic GAME-40 local site layer + visual proof. No fixture writes. */
import {readFile,writeFile,mkdir} from "node:fs/promises";
import {createHash} from "node:crypto";
import {dirname,resolve} from "node:path";
import {populateRegion,playerSiteView} from "./local-sites.mjs";
import {renderSvg} from "./preview-region.mjs";

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
const xml=t=>String(t).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;");
const color={hometown:"#e8c873",farmstead:"#d6b26e",roadside_inn:"#f6d48f",watchtower:"#b5cbd1",shrine:"#d3c4ed",ruins:"#e4a19c",cave:"#b1adc9",abandoned_camp:"#ddd0b5",ancient_stones:"#ddd0b5",dangerous_woods:"#baae7a",old_mine:"#beb5b7"};
const unique=shown.visible;
const overlays=['<g font-family="Arial, sans-serif" stroke-linejoin="round">'];
for(const site of unique){
 const [x,y]=site.position,c=color[site.kind]||"#e9d9bb";
 overlays.push('<circle cx="'+x+'" cy="'+y+'" r="13" fill="#242820" stroke="'+c+'" stroke-width="3"/>');
 overlays.push('<circle cx="'+x+'" cy="'+y+'" r="4.5" fill="'+c+'"/>');
 let label=xml(site.label);
 const width=Math.min(220,Math.max(75,label.length*8+13));
 let lx=x+18;if(lx+width>985)lx=x-width-16;
 overlays.push('<rect x="'+lx+'" y="'+(y-12)+'" width="'+width+'" height="24" rx="4" fill="#1e2221" fill-opacity="0.9" stroke="'+c+'" stroke-width="1"/>');
 overlays.push('<text x="'+(lx+7)+'" y="'+(y+5)+'" fill="#fff1db" font-size="14">'+label+'</text>');
}
overlays.push('</g>');
overlays.push('<g font-family="Arial, sans-serif"><rect x="655" y="16" width="330" height="91" rx="5" fill="#1c2220" opacity=".94"/>');
overlays.push('<text x="670" y="39" fill="#f1dba5" font-size="19">FRONTIER REGION</text>');
overlays.push('<text x="670" y="61" fill="#e4dac6" font-size="13">Sources: Azgaar hometown + local sites</text>');
overlays.push('<text x="670" y="83" fill="#cbd2c6" font-size="13">'+unique.length+' visible • '+shown.rumours.length+' rumours • hidden sites omitted</text>');
overlays.push('<rect x="652" y="935" width="336" height="43" rx="4" fill="#1c2220" opacity=".94"/>');
overlays.push('<text x="666" y="954" fill="#e4d9c5" font-size="13">Concept map: local site positions provisional</text>');
overlays.push('<text x="666" y="971" fill="#e4d9c5" font-size="13">Illustrative trails, protection unverified</text></g>');
const svg=renderSvg(region).replace("</svg>",overlays.join("\n")+"\n</svg>");
await writeFile(svgOutput,svg);
console.log("PASS: GAME-40 "+layer.sites.length+" source/game sites; "+unique.length+" visible, "+shown.rumours.length+" rumours; no hidden-site leaks");
