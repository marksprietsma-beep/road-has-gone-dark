/** GAME-47 QA view: actual source-world places/routes/water are top-level.
 * Town Forge supplies ONLY clipped ink/vegetation/ridge decoration.
 */
const escape=s=>String(s).replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;");
const pts=poly=>poly.map(p=>p.map(n=>+n.toFixed(2)).join(",")).join(" ");
const bounded=n=>Math.max(0,Math.min(1000,n));
export function renderConstrainedRegion(region){
 const context=region.source_context,landscape=region.landscape;
 if(!context?.source_features || !landscape || region.provider?.mode!=="DECORATIONS_ONLY")
  throw Error("Expected source-authored decorative composite");
 const lines=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">',
 '<title>Source-correct local landscape — decorative Town Forge vegetation</title>',
 '<defs><clipPath id="world"><rect width="1000" height="1000"/></clipPath>',
 '<pattern id="paper" width="48" height="54" patternUnits="userSpaceOnUse"><path d="M4 10l3 1 M28 48l4 -1 M41 27l2 2" stroke="#776748" stroke-width="0.7" opacity=".2"/></pattern>',
 '</defs><rect width="1000" height="1000" fill="#8babb2"/>',
 '<g clip-path="url(#world)">'];
 // Renderer-only visibility mask for source overland routes. Azgaar may
 // report an original road over source sea/lake polygons; masking these wet
 // stretches avoids depicting an unverified bridge or traversable land road.
 // Preserve every original route point in context.source_routes for auditing.
 lines.push('<defs><mask id="azgaar-source-dry-road-mask" maskUnits="userSpaceOnUse" x="0" y="0" width="1000" height="1000">');
 lines.push('<rect width="1000" height="1000" fill="black"/>');
 for(const f of context.source_features.filter(f=>f.classification==="land_boundary"))
  lines.push('<polygon points="'+pts(f.local_polygon)+'" fill="white"/>');
 for(const f of context.source_features.filter(f=>f.classification==="freshwater_lake"))
  lines.push('<polygon points="'+pts(f.local_polygon)+'" fill="black"/>');
 lines.push('</mask></defs>');
 // Original Azgaar searoutes sometimes cross source land at its coarse
 // resolution. Display them UNDER authentic land/lake polygons so the
 // inland portion is masked, without mutating their original source points
 // or fabricating harbours, ground access or safe routes.
 for(const route of context.source_routes.filter(r=>r.classification==="sea_lane"))
  for(const seg of route.segments)
   lines.push('<polyline class="azgaar-sea_lane" points="'+pts(seg.local_points)+
     '" stroke="#4b8392" stroke-width="3" stroke-dasharray="8 8" fill="none"/>');
 // Do not draw Town Forge coastlines or waters. Source land and lake feature
 // boundaries are actual Azgaar indexed-vertex geometry.
 for(const f of context.source_features.filter(f=>f.classification==="land_boundary"))
  lines.push('<polygon class="azgaar-land" points="'+pts(f.local_polygon)+'" fill="#d1c19c"/>');
 for(const f of context.source_features.filter(f=>f.classification==="freshwater_lake"))
  lines.push('<polygon class="azgaar-lake" points="'+pts(f.local_polygon)+'" fill="#87b0b9" stroke="#4b7778" stroke-width="1"/>');
 lines.push('<rect width="1000" height="1000" fill="url(#paper)" opacity=".62" pointer-events="none"/>');
 for(const ridge of landscape.ridges){
  const x=ridge.x,y=ridge.y;
  lines.push('<path d="M'+(x-15)+' '+(y+7)+' L'+x+' '+(y-11)+' L'+(x+15)+' '+(y+7)+
   ' M'+(x-9)+' '+(y+4)+' L'+(x-2)+' '+(y-3)+'" fill="none" stroke="#857556" stroke-width="1.6" opacity=".57"/>');
 }
 for(const tree of landscape.trees){
  const x=tree.x,y=tree.y,s=tree.size;
  lines.push('<path d="M'+x+' '+(y+s*.45)+' L'+x+' '+(y+s*1.15)+
   ' M'+(x-s*.65)+' '+(y+s*.5)+' L'+x+' '+(y-s*.9)+' L'+(x+s*.65)+' '+(y+s*.5)+' Z" fill="#4a6550" stroke="#2c4337" stroke-width="1"/>');
  lines.push('<path d="M'+(x-s*.45)+' '+(y-s*.1)+' L'+x+' '+(y-s*.9)+' L'+(x+s*.45)+' '+(y-s*.1)+
   '" fill="none" stroke="#819a70" stroke-width="1" opacity=".67"/>');
 }
 // River-cell-derived geometry is **approximate**. Dashing explicitly
 // prevents implying a definitive, traversable water channel.
 for(const river of context.source_rivers)
  for(const s of river.segments)
   lines.push('<polyline class="approximate-river" points="'+pts(s.local_points)+'" stroke="#4e8498" stroke-width="3" stroke-dasharray="6 4" opacity=".9" fill="none"/>');
 // Route classes from Azgaar are preserved: sea lanes are NOT safe land roads.
 lines.push('<g id="source-ground-route-presentation" mask="url(#azgaar-source-dry-road-mask)">');
 for(const route of context.source_routes)for(const s of route.segments){
  // Sea routes were drawn *behind* source land, and cannot turn into
  // a visual overland route by crossing inconsistent source coast geometry.
  if(route.classification==="sea_lane")continue;
  const trail=route.classification==="trail";
  lines.push('<polyline class="azgaar-'+escape(route.classification)+'" points="'+pts(s.local_points)+
    '" fill="none" stroke="#5c503a" stroke-width="'+(trail?3:5)+
    '" stroke-linejoin="round" stroke-linecap="round"/>');
  if(!trail)lines.push('<polyline points="'+pts(s.local_points)+
    '" stroke="#cbb98b" stroke-width="2" fill="none" opacity=".9"/>');
 }
 lines.push('</g>');
 // Source towns are never moved to meet Town Forge's arbitrary paths.
 for(const burg of context.source_burgs){
  const [x,y]=burg.local_position,home=burg.source_id===context.source_home_burg_id;
  const size=home?12:7;
  lines.push('<circle class="source-burg" cx="'+x+'" cy="'+y+'" r="'+size+'" fill="#efe1bd" stroke="#382e25" stroke-width="2"/>');
  lines.push('<path d="M'+(x-size*.6)+' '+(y+size*.5)+' L'+(x-size*.6)+' '+(y-size*.35)+
     ' L'+x+' '+(y-size)+' L'+(x+size*.6)+' '+(y-size*.35)+' L'+(x+size*.6)+' '+(y+size*.5)+
     ' Z" fill="'+(home?"#9b5644":"#806953")+'" stroke="#4b382d" stroke-width="1"/>');
 }
 // Sparse labels with edge clamping, no debug boxes over all sites.
 const home=context.source_burgs.find(b=>b.source_id===context.source_home_burg_id);
 const label=(b,major)=>{
  const [x,y]=b.local_position;
  const w=Math.min(230,Math.max(70,b.name.length*(major?12:8)));
  const left=bounded(x+17+w>996?x-w-25:x+17);
  const top=Math.max(113,Math.min(930,y-12));
  lines.push('<rect x="'+(left-5)+'" y="'+(top-(major?20:14))+'" width="'+(w+12)+
    '" height="'+(major?26:20)+'" rx="2" fill="#efe1be" fill-opacity=".91" stroke="#b7a57f" stroke-width=".7"/>');
  lines.push('<text x="'+left+'" y="'+top+'" font-family="Georgia,serif" font-size="'+(major?19:13)+'" fill="#292d25" font-weight="'+(major?"bold":"normal")+'">'+escape(b.name)+'</text>');
 };
 if(home)label(home,true);
 for(const b of context.source_burgs.filter(b=>b.source_id!==context.source_home_burg_id).slice(0,3))label(b,false);
 lines.push('</g>',
 '<rect x="10" y="10" width="635" height="85" rx="3" fill="#ede1c1" fill-opacity=".95" stroke="#5b513e"/>',
 '<text x="23" y="34" font-size="21" font-family="Georgia,serif" fill="#2b2c24">THE ROAD HAS GONE DARK</text>',
 '<text x="23" y="57" font-size="15" font-family="Georgia,serif" fill="#4e493c">Source geography · '+escape(home?.name||"Unknown")+' neighbourhood</text>',
 '<text x="23" y="77" font-size="13" font-family="Georgia,serif" fill="#655845">Town Forge vegetation only — roads and coastlines are Azgaar original</text>',
 '<rect x="9" y="939" width="981" height="51" rx="3" fill="#eee1c3" fill-opacity=".94" stroke="#70624b"/>',
 '<text x="20" y="958" font-family="Georgia,serif" font-size="14" fill="#443b2b">Brown: source roads  •  Dashed teal: sea lanes  •  Dashed blue: approximate river  •  Trees: inferred</text>',
 '<text x="20" y="978" font-family="Georgia,serif" font-size="13" fill="#785438">PREVIEW ONLY · distances uncalibrated; safe roads, bridges, river mouths &amp; generated sites unverified</text>',
 '</svg>');
 return lines.join("\n")+"\n";
}
