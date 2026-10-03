/**
 * GAME-42. SVG counterpart to the Godot renderer's shared decorative glyph
 * registry. This module is deliberately independent of generated site data.
 */
import {readFileSync} from "node:fs";
const source = new URL("../../assets/map/region-site-icons.json", import.meta.url);
export const registry = JSON.parse(readFileSync(source, "utf8"));
if (registry.schema_version !== 1) throw Error("Unsupported regional icon registry");
const esc = value => String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll('"', "&quot;");
const pts = vertices => vertices.map(([x,y]) => x+","+y).join(" ");
export function renderSiteSymbol(site, selected=false) {
 const [x,y] = site.position;
 const spec = registry.symbols[site.kind] || registry.symbols.ancient_stones;
 const scale = spec.scale || 1;
 const lines = [];
 const accent = site.provenance === "azgaar_burg" ? "#b78943" : "#6f6c50";
 lines.push('<g class="region-site" transform="translate('+x+' '+y+')" stroke-linejoin="round" stroke-linecap="round">');
 lines.push('<circle cy="2" r="'+(selected?24:21)+'" fill="#252b25" opacity=".18"/>');
 lines.push('<circle r="'+(selected?23:20)+'" fill="#e6d9b7" stroke="'+accent+'" stroke-width="'+(selected?3:2)+'"/>');
 lines.push('<g transform="scale('+scale+')" stroke="'+registry.palette.ink+'" stroke-width="1.35">');
 for (const shape of spec.polygons) lines.push('<polygon points="'+pts(shape.points)+'" fill="'+(registry.palette[shape.role]||registry.palette.stone)+'"/>');
 for (const line of spec.lines||[]) lines.push('<polyline points="'+pts(line.points)+'" fill="none" stroke="'+(registry.palette[line.role]||registry.palette.ink)+'" stroke-width="'+line.width+'"/>');
 lines.push('</g></g>');
 return lines.join("");
}
/** Only label the home and a few landmarks. No full invisible-site positions. */
export function renderReadableLabels(sites) {
 const order={hometown:0,ruins:1,roadside_inn:2,watchtower:3,shrine:4};
 const preferred=sites.filter(s=>s.kind in order).sort((a,b)=>order[a.kind]-order[b.kind]).slice(0,4);
 const occupied=[];
 const labels=[];
 for(const site of preferred) {
  const [x,y]=site.position;
  const title=String(site.label);
  const width=Math.max(87,Math.min(220,title.length*7.3+18));
  const candidates=[
   {x:x+25,y:y-16},
   {x:x-width-25,y:y-16},
   {x:x-width/2,y:y+27},
   {x:x-width/2,y:y-47}
  ];
  let place;
  for(const c of candidates) {
   const r={x:c.x,y:c.y,w:width,h:25};
   if(r.x<18||r.x+r.w>981||r.y<116||r.y+r.h>928)continue;
   if(occupied.some(b=>!(r.x+r.w+6<b.x||b.x+b.w+6<r.x||r.y+r.h+5<b.y||b.y+b.h+5<r.y)))continue;
   place=r; break;
  }
  if(!place)continue;
  occupied.push(place);
  const home=site.kind==="hometown";
  labels.push('<g class="site-label"><rect x="'+place.x+'" y="'+place.y+'" width="'+width+'" height="25" rx="3" fill="'+(home?"#f1dfae":"#e5d8b8")+'" fill-opacity=".94" stroke="#4c4736" stroke-width="'+(home?1.8:0.8)+'"/><text x="'+(place.x+9)+'" y="'+(place.y+17)+'" fill="#292b22" font-family="Georgia,serif" font-size="'+(home?15:13)+'" font-weight="'+(home?"bold":"normal")+'">'+esc(title)+'</text></g>');
 }
 return labels.join("\n");
}
