const esc = value => String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll('"', "&quot;");
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
