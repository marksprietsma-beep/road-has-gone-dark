// A non-authoritative visual preview of source-backed Town Forge geometry.
// Gameplay and save logic must consume the JSON, not the SVG output.
const escape=t=>String(t).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;");
const poly=pts=>Array.isArray(pts)?pts.map(p=>p.join(",")).join(" "):"";
const line=(points,color,width,opacity=1)=>'<polyline points="'+poly(points)+'" fill="none" stroke="'+color+'" stroke-width="'+width+'" stroke-linecap="round" stroke-linejoin="round" opacity="'+opacity+'"/>';
export function renderSvg(region){
 const g=region.geometry||{},land=region.region||{},source=region.source||{};
 const lines=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">',
 '<title>GAME-21 Town Forge local region preview</title>',
 '<defs><clipPath id="bounds"><rect width="1000" height="1000"/></clipPath>',
 '<pattern id="forest-pines" width="53" height="57" patternUnits="userSpaceOnUse">',
 '<path d="M14 7 L8 19 L11 19 L5 30 L23 30 L17 19 L20 19 Z" fill="#354d39" opacity=".68"/>',
 '<path d="M38 23 L33 32 L35 32 L29 44 L48 44 L42 32 L44 32 Z" fill="#354d39" opacity=".54"/>',
 '<path d="M14 30 V34 M38 44 V48" stroke="#394b37" stroke-width="1.5"/></pattern>',
 '<pattern id="paper-ink" width="71" height="67" patternUnits="userSpaceOnUse">',
 '<path d="M5 8h1 M29 45h1 M58 27h1 M44 60h1" stroke="#706448" opacity=".15" stroke-width="1"/></pattern>',
 '<radialGradient id="age"><stop offset="0%" stop-color="#efe0b8" stop-opacity=".12"/><stop offset="100%" stop-color="#544731" stop-opacity=".12"/></radialGradient></defs>',
 '<rect width="1000" height="1000" fill="#c4b99b"/>',
 '<rect width="1000" height="1000" fill="url(#paper-ink)"/>',
 '<g clip-path="url(#bounds)">'];
 for(const p of g.forests||[]){
  lines.push('<polygon points="'+poly(p)+'" fill="#58694c" fill-opacity=".75" stroke="#4f5d44" stroke-width="1.1"/>');
  lines.push('<polygon points="'+poly(p)+'" fill="url(#forest-pines)" fill-opacity=".73"/>');
 }
 if((g.water||[]).length>2)lines.push('<polygon points="'+poly(g.water)+'" fill="#769297" stroke="#55777b" stroke-width="2.5"/>');
 for(const path of g.ridges||[])lines.push(line(path,"#7a6d59",3,0.58));
 for(const road of g.roads||[]){
  lines.push(line(road.points,"#625a47",road.role==="primary"?6:4));
  lines.push(line(road.points,"#d0be96",road.role==="primary"?3.5:2.4));
 }
 lines.push('</g>');
 lines.push('<rect width="1000" height="1000" fill="url(#age)" pointer-events="none"/>');
 lines.push('<g font-family="Georgia,serif">');
 lines.push('<rect x="12" y="12" width="395" height="91" rx="3" fill="#eee1c0" fill-opacity=".94" stroke="#6c604b"/>');
 lines.push('<text x="28" y="38" fill="#3b382c" font-size="21">THE ROAD HAS GONE DARK</text>');
 lines.push('<text x="28" y="62" fill="#554e3e" font-size="16">Town Forge • '+escape(land.terrain)+' region</text>');
 lines.push('<text x="28" y="84" fill="#554e3e" font-size="14">Azgaar cell '+escape(source.cell_id)+' • '+escape(land.side_km)+' km conceptual span</text>');
 lines.push('<rect x="17" y="962" width="260" height="25" rx="3" fill="#eee1c0" opacity=".94" stroke="#6c604b"/>');
 lines.push('<text x="28" y="980" fill="#4b4637" font-size="13">PREVIEW • roads/seams provisional</text>');
 if(region.constraints?.rivers==="source_river_not_rendered") {
  lines.push('<rect x="17" y="921" width="655" height="30" rx="3" fill="#eee1c0" opacity=".96" stroke="#6c604b"/>');
  lines.push('<text x="28" y="941" fill="#8e472e" font-size="15">SOURCE RIVER PRESENT — river mouth not rendered in shoreline preview</text>');
 }
 lines.push('</g></svg>');
 return lines.join("\n")+"\n";
}
