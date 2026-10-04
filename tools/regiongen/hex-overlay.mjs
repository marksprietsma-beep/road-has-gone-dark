/** World-anchored pointy hex distance ruler, independent of terrain/saves.
 * One centre-to-centre spacing = one original source unit, NOT one km/hour. */
export const HEX_SPACING=1;
const SIZE=HEX_SPACING/Math.sqrt(3);
const round=n=>Math.round(n*1e5)/1e5;
export function hexAt([x,y]){
 const q=(Math.sqrt(3)/3*x-y/3)/SIZE,r=2*y/3/SIZE,s=-q-r;
 let a=Math.round(q),b=Math.round(r),c=Math.round(s);
 const da=Math.abs(a-q),db=Math.abs(b-r),dc=Math.abs(c-s);
 if(da>db&&da>dc)a=-b-c;else if(db>dc)b=-a-c;else c=-a-b;
 return [a||0,b||0];
}
export const hexCentre=([q,r])=>[SIZE*Math.sqrt(3)*(q+r/2),SIZE*1.5*r];
export const hexDistance=(a,b)=>Math.max(Math.abs(a[0]-b[0]),Math.abs(a[1]-b[1]),Math.abs(a[0]+a[1]-b[0]-b[1]));
export function buildHexOverlay(context){
 const b=context.space.source_bounds;
 const sx=1000/(b.right-b.left),sy=1000/(b.bottom-b.top);
 if(Math.abs(sx-sy)>.001)throw Error("Hex overlay needs square source bounds");
 const local=p=>[(p[0]-b.left)*sx,(p[1]-b.top)*sy].map(round);
 const cornerHexes=[[b.left-1,b.top-1],[b.right+1,b.top-1],[b.left-1,b.bottom+1],[b.right+1,b.bottom+1]].map(hexAt);
 const cells=[];
 for(let r=Math.min(...cornerHexes.map(p=>p[1]));r<=Math.max(...cornerHexes.map(p=>p[1]));r++)
  for(let q=Math.min(...cornerHexes.map(p=>p[0]));q<=Math.max(...cornerHexes.map(p=>p[0]));q++){
   const p=hexCentre([q,r]),c=local(p);
   if(c[0]<-sx||c[0]>1000+sx||c[1]<-sx||c[1]>1000+sx)continue;
   const points=Array.from({length:6},(_,i)=>{
    const a=(i*60-30)*Math.PI/180;return local([p[0]+SIZE*Math.cos(a),p[1]+SIZE*Math.sin(a)]);
   });
   cells.push({axial:[q,r],centre:c,points});
  }
 const home=context.source_burgs.find(t=>t.source_id===context.source_home_burg_id);
 return {schema_version:1,source_context_id:context.id,source_world_sha256:context.parent_source_world_sha256,
  source_spacing:HEX_SPACING,physical_km:"UNCALIBRATED",meaning:"GEOMETRIC_DISTANCE_NOT_TRAVEL_ROUTE",
  home_axial:hexAt(home.world_position),cells};
}
export function measureHexDistance(context,position){
 const b=context.space.source_bounds;
 const home=context.source_burgs.find(t=>t.source_id===context.source_home_burg_id);
 const world=[b.left+position[0]*(b.right-b.left)/1000,b.top+position[1]*(b.bottom-b.top)/1000];
 return hexDistance(hexAt(home.world_position),hexAt(world));
}
export function renderHexOverlay(overlay){
 return '<defs><mask id="hex-label-clearance"><rect width="1000" height="1000" fill="white"/><rect x="18" y="18" width="330" height="70" fill="black"/><rect x="18" y="950" width="700" height="32" fill="black"/></mask></defs><g id="hex-distance-grid" mask="url(#hex-label-clearance)" clip-path="url(#world)" fill="none" stroke="#584b32" stroke-width=".85" opacity=".28">'+
  overlay.cells.map(c=>'<polygon points="'+c.points.map(p=>p.join(',')).join(' ')+'"/>').join('\n')+'</g>';
}
export function renderHexRuler(context,overlay,site){
 const b=context.space.source_bounds,home=overlay.home_axial;
 const target=hexAt([b.left+site.position[0]*(b.right-b.left)/1000,b.top+site.position[1]*(b.bottom-b.top)/1000]);
 const n=hexDistance(home,target),selected=[];
 for(let i=0;i<=n;i++){
  const a=hexCentre(home),z=hexCentre(target),t=n?i/n:0;
  selected.push(hexAt([a[0]+(z[0]-a[0])*t+1e-7,a[1]+(z[1]-a[1])*t+1e-7]));
 }
 const cells=selected.map(p=>overlay.cells.find(c=>c.axial[0]===p[0]&&c.axial[1]===p[1])).filter(Boolean);
 const polygons=cells.map((c,i)=>'<polygon points="'+c.points.map(p=>p.join(',')).join(' ')+'" fill="#d8a749" fill-opacity=".25" stroke="#a47b2d" stroke-width="2"/><text x="'+c.centre[0]+'" y="'+(c.centre[1]+4)+'" text-anchor="middle" fill="#6f4c16" font-family="Georgia,serif" font-size="14">'+i+'</text>');
 return '<g clip-path="url(#world)">'+polygons.join('\n')+'</g><rect x="605" y="22" width="375" height="57" rx="3" fill="#efe2c2" stroke="#a47b2d"/><text x="620" y="46" font-family="Georgia,serif" font-size="17" fill="#59451e">DISTANCE RULER · '+n+' hex steps</text><text x="620" y="66" font-family="Georgia,serif" font-size="12" fill="#74674d">Geometric distance; terrain routing and hours pending</text>';
}
