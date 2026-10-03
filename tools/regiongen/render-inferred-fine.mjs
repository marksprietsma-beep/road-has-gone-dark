/**
 * GAME-51: visualisation of non-authoritative fine details.
 * Source land masks always take priority over inferred scalar fields.
 */
const pts=xs=>xs.map(p=>p.map(n=>Number(n.toFixed(3))).join(",")).join(" ");
const escape=s=>String(s).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;");
const lerp=(a,b,t)=>[a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t];
function thresholdTri(v,cut){
 const poly=[];
 for(let i=0;i<3;i++){
  const a=v[i],b=v[(i+1)%3],ai=a.z>=cut,bi=b.z>=cut;
  if(ai)poly.push(a.p);
  if(ai!==bi){
   const t=(cut-a.z)/(b.z-a.z);
   poly.push(lerp(a.p,b.p,t));
  }
 }
 return poly.length>=3?poly:[];
}
export function renderInferredFineSvg(authority,fine){
 if(authority?.id===undefined||fine?.schema_version!==1||
   fine.source_context_id!==authority.identity?.source_context_id ||
   fine.source_world_sha256!==authority.identity?.source_world_sha256)
  throw Error("Fine map cannot be rendered over unrelated source authority");
 const source=authority.source_macro,G=fine.grid_steps,values=fine.vertices;
 if(values.length!==(G+1)**2)throw Error("Missing complete illustrative scalar grid");
 const home=source.towns.find(x=>x.source_burg_id===authority.identity.origin_source_burg_id);
 const features=source.feature_polygons;
 const lines=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">',
  '<title>Inferred landscape illustration — not traversable source terrain</title>',
  '<defs><mask id="exact-macro-land"><rect width="1000" height="1000" fill="black"/>'];
 for(const f of features.filter(f=>f.classification==="land_boundary"))
  lines.push('<polygon points="'+pts(f.source_polygon)+'" fill="white"/>');
 for(const f of features.filter(f=>f.classification==="freshwater_lake"))
  lines.push('<polygon points="'+pts(f.source_polygon)+'" fill="black"/>');
 lines.push('</mask></defs><rect width="1000" height="1000" fill="#81a9b4"/>');
 // Source sea lanes under the actual source mask. Never show a shipping
 // route as an invented overland path through coastlines.
 for(const r of source.routes.filter(r=>r.classification==="sea_lane"))
  for(const segment of r.segments)lines.push('<polyline points="'+pts(segment.local_points)+'" stroke="#376977" stroke-width="3" stroke-dasharray="8 7" fill="none"/>');
 for(const f of features.filter(f=>f.classification==="land_boundary"))
  lines.push('<polygon points="'+pts(f.source_polygon)+'" fill="#d8c7a1"/>');
 // Inferred relief/canopy is *visually* clipped to original macro land,
 // never interpreted as an actual shoreline or gameplay collision field.
 lines.push('<g mask="url(#exact-macro-land)" data-provenance="inferred-only">');
 const idx=(i,j)=>j*(G+1)+i;
 const bands=[
  ["h",48,"#c9b58c"],["h",58,"#b5a17e"],["h",69,"#a08e75"],["h",78,"#89816c"],
  ["f",0.49,"#7f946c"],["f",0.57,"#5e7655"],["f",0.65,"#455c49"]];
 for(const [key,cut,shade] of bands){
  const paths=[];
  for(let j=0;j<G;j++)for(let i=0;i<G;i++){
   const x=1000*i/G,y=1000*j/G,delta=1000/G;
   const corners=[
    {p:[x,y],z:values[idx(i,j)][key]},
    {p:[x+delta,y],z:values[idx(i+1,j)][key]},
    {p:[x+delta,y+delta],z:values[idx(i+1,j+1)][key]},
    {p:[x,y+delta],z:values[idx(i,j+1)][key]}
   ];
   for(const triplet of [[0,1,2],[0,2,3]]){
    const tri=thresholdTri(triplet.map(k=>corners[k]),cut);
    if(tri.length)paths.push("M"+tri.map(p=>p.map(v=>+v.toFixed(2)).join(",")).join(" L")+"Z");
   }
  }
  lines.push('<path class="inferred-'+(key==="h"?"relief":"forest")+'" d="'+paths.join(" ")+'" fill="'+shade+'" opacity="'+(key==="h"?.66:.88)+'"/>');
 }
 lines.push('</g>');
 // Retain canonical freshwater lakes on top.
 for(const f of features.filter(f=>f.classification==="freshwater_lake"))
  lines.push('<polygon points="'+pts(f.source_polygon)+'" fill="#81a9b4" stroke="#487785" stroke-width="1.5"/>');
 for(const r of source.routes.filter(r=>r.classification!=="sea_lane"))
  for(const s of r.segments)
   lines.push('<polyline points="'+pts(s.local_points)+'" stroke="#63543d" stroke-width="'+(r.classification==="trail"?2:3.5)+'" fill="none"/>');
 for(const river of authority.derived_approximate.rivers)
  for(const s of river.segments)
   lines.push('<polyline points="'+pts(s.local_points)+'" stroke="#427d98" stroke-width="2.5" stroke-dasharray="4 5" fill="none"/>');
 for(const t of source.towns){
  lines.push('<circle cx="'+t.local_position[0]+'" cy="'+t.local_position[1]+'" r="'+(t.source_burg_id===home?.source_burg_id?9:5)+'" fill="#9a5141" stroke="#f2e5bd" stroke-width="2"/>');
 }
 const homeName=escape(home?.name||"Unknown");
 const scaleText=fine.reference_scale==="UNCALIBRATED"?
  "Scale: original Azgaar source units; no kilometre calibration":
  "30 km is an ASSUMED Earth-radius reference, not a canonical game distance";
 lines.push('<rect x="8" y="8" width="690" height="91" fill="#efe2c6" fill-opacity=".95" stroke="#74694e"/>',
  '<text x="22" y="35" font-family="Georgia,serif" font-size="21" fill="#292921">'+homeName+' — inferred local relief</text>',
  '<text x="22" y="58" font-family="Georgia,serif" font-size="13" fill="#4f4a3b">Azgaar macro towns/coasts/routes; forests and hills are inferred, not surveyed</text>',
  '<text x="22" y="78" font-family="Georgia,serif" font-size="12" fill="#83573c">'+scaleText+'</text>',
  '<rect x="8" y="935" width="984" height="56" fill="#efe2c6" fill-opacity=".95" stroke="#74694e"/>',
  '<text x="19" y="958" font-family="Georgia,serif" font-size="14" fill="#473b2c">Source = coast/settlement/route | Approximate = river | Inferred = relief/woods</text>',
  '<text x="19" y="979" font-family="Georgia,serif" font-size="13" fill="#834734">Unknown: crossings, safe roads, walking barriers, precise coast and real mountain passes</text>',
  '</svg>');
 return lines.join("\n")+"\n";
}
