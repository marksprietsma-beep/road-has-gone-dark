// A non-authoritative visual preview of source-backed Town Forge geometry.
// Gameplay and save logic must consume the JSON, not the SVG output.
const escape=t=>String(t).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;");
const poly=pts=>Array.isArray(pts)?pts.map(p=>p.join(",")).join(" "):"";
const line=(points,color,width,opacity=1)=>'<polyline points="'+poly(points)+'" fill="none" stroke="'+color+'" stroke-width="'+width+'" stroke-linecap="round" stroke-linejoin="round" opacity="'+opacity+'"/>';
export function renderSvg(region){
 const g=region.geometry||{},land=region.region||{},source=region.source||{};
 const lines=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">',
 '<title>GAME-21 Town Forge local region preview</title>',
 '<defs><clipPath id="bounds"><rect width="1000" height="1000"/></clipPath></defs>',
 '<rect width="1000" height="1000" fill="#b5af93"/>',
 '<g clip-path="url(#bounds)">'];
 for(const p of g.forests||[])lines.push('<polygon points="'+poly(p)+'" fill="#536b48" fill-opacity="0.69" stroke="#485c44" stroke-width="1"/>');
 if((g.water||[]).length>2)lines.push('<polygon points="'+poly(g.water)+'" fill="#71989e" stroke="#4f747a" stroke-width="3"/>');
 for(const path of g.ridges||[])lines.push(line(path,"#7b6853",4,0.7));
 for(const road of g.roads||[]){
  lines.push(line(road.points,"#554b3c",road.role==="primary"?7:5));
  lines.push(line(road.points,"#c9b889",road.role==="primary"?4:2.8));
 }
 lines.push('</g>');
 lines.push('<g font-family="Arial, sans-serif">');
 lines.push('<rect x="12" y="12" width="395" height="99" rx="5" fill="#191b19" opacity="0.82"/>');
 lines.push('<text x="28" y="38" fill="#e9dfc6" font-size="21">THE ROAD HAS GONE DARK</text>');
 lines.push('<text x="28" y="62" fill="#cfc8b7" font-size="16">Town Forge • '+escape(land.terrain)+' region</text>');
 lines.push('<text x="28" y="84" fill="#cfc8b7" font-size="14">Azgaar cell '+escape(source.cell_id)+' • '+escape(land.side_km)+' km conceptual span</text>');
 lines.push('<rect x="17" y="962" width="240" height="25" rx="4" fill="#191b19" opacity="0.8"/>');
 lines.push('<text x="28" y="980" fill="#e7debf" font-size="13">PREVIEW • roads/seams provisional</text>');
 lines.push('</g></svg>');
 return lines.join("\n")+"\n";
}
