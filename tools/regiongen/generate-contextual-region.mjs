#!/usr/bin/env node
/** GAME-44: separate opt-in v2 local sites, never overwrites GAME-40 v1. */
import {readFile,mkdir,writeFile,realpath} from "node:fs/promises";
import {dirname,resolve} from "node:path";
import {createHash} from "node:crypto";
import {generateContextualSites,contextualPlayerSiteView} from "./contextual-sites-v2.mjs";
import {renderConstrainedRegion} from "./render-constrained-region.mjs";
import {buildInferredFineTerrain} from "./inferred-fine-terrain.mjs";
import {buildLandscapePresentation} from "./landscape-presentation.mjs";
import {buildHexOverlay,renderHexOverlay,renderHexRuler,measureHexDistance} from "./hex-overlay.mjs";
import {renderReadableLabels} from "./site-icons.mjs";
import {buildSharedIcons,renderSharedIcon,buildEncounterDemo,SITE_ROLES} from './shared-map-icons.mjs';
import {buildHexRoutePreview,renderHexRoutePreview} from './hex-route-preview.mjs';
import {estimateRouteTime} from './route-time-scenario.mjs';
const args=process.argv.slice(2);
const get=k=>{const i=args.indexOf(k);return i<0?undefined:args[i+1]};
const source=get("--world"),input=get("--constrained"),output=get("--output");
if(!source||!input||!output)throw Error("Usage: --world <canonical.json> --constrained <GAME-47.json> --output <GAME-44.json>");
const svg=get("--svg") || output.replace(/\.json$/i,".svg");
const auditSvg=get("--audit-svg");
const names=await Promise.all([source,input,output,svg,...(auditSvg?[auditSvg]:[])].map(x=>realpath(resolve(x)).catch(()=>resolve(x))));
if(new Set(names).size!==names.length)throw Error("Source, constrained, JSON and SVG must differ");
const bytes=await readFile(resolve(source)),world=JSON.parse(bytes);
const composite=JSON.parse(await readFile(resolve(input),"utf8"));
if(createHash("sha256").update(bytes).digest("hex")!==composite.source_context?.parent_source_world_sha256)
 throw Error("Canonical source world fingerprint does not match");
const layer=generateContextualSites(world,composite);
const preview=contextualPlayerSiteView(layer);
const inferred=buildInferredFineTerrain(world,composite.source_context,
 composite.source_context.parent_source_world_sha256);
// Debug generation artefact only; never a save schema migration.
const art=buildLandscapePresentation(world,composite);
const hexes=buildHexOverlay(composite.source_context);
const icons=buildSharedIcons(world,composite.source_context);
const combined={...composite,local_sites_v2:layer,inferred_fine_v1:inferred,landscape_presentation_v1:art,hex_overlay_v1:hexes,world_icon_roles_v1:icons};
// This SVG is a filtered *player-facing* POI overlay on a source-visual
// diagnostic; complete debug JSON (including hidden POIs) is NOT player UI.
const visible=preview.visible.filter(site=>site.kind!=="hometown");
const fragments=['<g id="known-game-owned-pois">'];
for(const site of visible)fragments.push(renderSharedIcon(SITE_ROLES[site.kind],site.position));
combined.encounter_demo_v1=buildEncounterDemo(composite.source_context,hexes,visible,art.terrain);
combined.hex_route_preview_v1=buildHexRoutePreview(composite.source_context,hexes,art.terrain,preview.visible);
fragments.push(renderReadableLabels(visible),'</g>');
const text='<text x="668" y="111" fill="#333127" font-family="Georgia,serif" font-size="12">Known nearby sites: '+
 preview.visible.length+' · Rumours: '+preview.rumours.length+'</text>';
const warnings=[];
for(const issue of layer.route_consistency.conflicts){
 const route=composite.source_context.source_routes.find(r=>r.source_id===issue.source_route_id);
 const segment=route?.segments.find(z=>z.source_segment===issue.source_segment);
 if(!segment)throw Error("Source route consistency references missing segment");
 warnings.push('<polyline class="source-geometry-conflict" points="'+
  segment.local_points.map(([x,y])=>x+","+y).join(" ") +
  '" fill="none" stroke="#9d4735" stroke-width="3.5" stroke-dasharray="7 5" opacity=".85"/>');
}
const conflictText='<text x="668" y="129" fill="#8b4333" font-family="Georgia,serif" font-size="12">Route/coast conflicts: '+
 layer.route_consistency.conflicts.length+' · red dashed = uncertain</text>';
// Normal exploration preview has *no* red diagnostic conflict strokes.
 // Keep conflicts as original source-backed JSON evidence. Only an explicitly
 // separate developer SVG displays them, never a default player-facing view.
const base=renderConstrainedRegion(combined,inferred);
const image=base.replace(/<\/svg>\s*$/,fragments.join("\n")+
 '<desc>Known nearby sites: '+preview.visible.length+'; Rumours: '+preview.rumours.length+
 '; scenery is inferred illustration; distances uncalibrated; river geometry approximate; crossings and safe roads unknown.</desc>\n</svg>');
const auditImage=auditSvg?base.replace(/<\/svg>\s*$/,
 warnings.join("\n")+"\n"+fragments.join("\n")+"\n"+text+"\n"+conflictText+"\n</svg>"):null;
await mkdir(dirname(resolve(output)),{recursive:true});
await mkdir(dirname(resolve(svg)),{recursive:true});
if(auditSvg)await mkdir(dirname(resolve(auditSvg)),{recursive:true});
await writeFile(resolve(output),JSON.stringify(combined,null,2)+"\n");
await writeFile(resolve(svg),image);
const measured=visible.slice().sort((a,b)=>measureHexDistance(composite.source_context,b.position)-measureHexDistance(composite.source_context,a.position))[0];
const hexImage=base.replace(/<\/svg>\s*$/,renderHexOverlay(hexes)+(measured?renderHexRuler(composite.source_context,hexes,measured):'')+fragments.join('\n')+'</svg>');
await writeFile(resolve(svg.replace(/\.svg$/i,'.hex.svg')),hexImage);
const routes=combined.hex_route_preview_v1.routes;
const route=routes.find(r=>r.site_id===combined.hex_route_preview_v1.default_site_id);
const routeSite=visible.find(s=>s.id===route?.site_id);
await writeFile(resolve(svg.replace(/\.svg$/i,'.route.svg')),base.replace(/<\/svg>\s*$/,renderHexOverlay(hexes)+renderHexRoutePreview(combined.hex_route_preview_v1,hexes,route,routeSite)+fragments.join('\n')+'</svg>'));
await writeFile(resolve(svg.replace(/\.svg$/i,'.timing.svg')),base.replace(/<\/svg>\s*$/,renderHexOverlay(hexes)+renderHexRoutePreview(combined.hex_route_preview_v1,hexes,route,routeSite,estimateRouteTime(route,30))+fragments.join('\n')+'</svg>'));
const demo=combined.encounter_demo_v1.occupants.map(o=>{
 const cell=hexes.cells.find(c=>c.axial.join(',')===o.axial.join(',')),label=o.label+' · mock-up';
 return `<polygon points="${cell.points.map(p=>p.join(',')).join(' ')}" fill="#9d4735" fill-opacity=".08"/>`+
  renderSharedIcon(o.role,o.position,{danger:true})+`<rect x="${o.position[0]+21}" y="${o.position[1]-15}" width="${label.length*8.5+12}" height="24" fill="#efe1bd" fill-opacity=".94"/><text x="${o.position[0]+25}" y="${o.position[1]+3}" font-family="Georgia,serif" font-size="15" fill="#843e30">${label}</text>`;
}).join('\n');
const omitted=combined.encounter_demo_v1.omitted_roles.length?'<text x="604" y="84" font-size="13" font-family="Georgia,serif" fill="#843e30">Some mock-ups omitted: no suitable dry cell</text>':'';
await writeFile(resolve(svg.replace(/\.svg$/i,'.encounter.svg')),base.replace(/<\/svg>\s*$/,renderHexOverlay(hexes)+fragments.join('\n')+demo+'<rect x="590" y="20" width="390" height="45" fill="#efe1bd"/><text x="604" y="48" font-size="18" fill="#843e30">HEX OCCUPANTS · MOCK-UP, NOT LIVE</text>'+omitted+'</svg>'));
if(auditSvg)await writeFile(resolve(auditSvg),auditImage);
console.log("PASS: GAME-44 v2 sites "+layer.sites.length+
 " generated/context source, "+preview.visible.length+" known, "+
 preview.rumours.length+" non-positional rumours; prior v1 site records untouched");
