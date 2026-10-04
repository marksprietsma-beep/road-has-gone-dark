/** GAME-57: disposable illustration geometry shared by SVG and Godot.
 * Never consumes game POIs: hidden/rumoured sites cannot affect scenery.
 * No roads, rivers, coastlines, movement, saves or source IDs are generated. */
import {createHash} from "node:crypto";
import {sourceDryLand,insidePolygon} from "./compose-local-region.mjs";
import {sampleLandscapeArt} from "./inferred-fine-terrain.mjs";
const round=n=>Math.round(n*1000)/1000;
const hash=s=>createHash("sha256").update(s).digest("hex");
function random(seed,x,y,k=0){
 let h=2166136261;for(const c of `${seed.slice(0,16)}:${x}:${y}:${k}`){h^=c.charCodeAt(0);h=Math.imul(h,16777619);}return (h>>>0)/4294967295;
}
const ring=(x,y,r,n=8,aspect=1)=>Array.from({length:n},(_,i)=>[x+Math.cos(i*Math.PI*2/n)*r,y+Math.sin(i*Math.PI*2/n)*r*aspect]);
const distance=(p,q)=>Math.hypot(p[0]-q[0],p[1]-q[1]);
function nearRoad(context,p){
 let best=Infinity;
 for(const route of context.source_routes.filter(r=>["land_road","trail"].includes(r.classification)))
  for(const segment of route.segments)for(let i=1;i<segment.local_points.length;i++){
   const a=segment.local_points[i-1],b=segment.local_points[i],dx=b[0]-a[0],dy=b[1]-a[1];
   const t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(dx*dx+dy*dy||1)));
   best=Math.min(best,distance(p,[a[0]+dx*t,a[1]+dy*t]));
  }
 return best;
}
export function buildLandscapePresentation(world,region){
 const context=region.source_context,seed=context.parent_source_world_sha256,b=context.space.source_bounds;
 if(context.constraints?.shorelines!=="original_source_features")throw Error("Original water mask required for art");
 const N=64,vertices=[];
 for(let j=0;j<=N;j++)for(let i=0;i<=N;i++){
  const x=i*1000/N,y=j*1000/N;
  vertices.push({...sampleLandscapeArt(world,context,seed,[b.left+(b.right-b.left)*i/N,b.top+(b.bottom-b.top)*j/N]),land:sourceDryLand(context,[x,y])});
 }
 const terrain={schema_version:1,source_context_id:context.id,source_world_sha256:seed,
  truth:"INFERRED_VISUAL_FIELD_NOT_TRAVERSAL",grid_steps:N,vertices};
 const ground=[],objects=[],water=[];
 const safe=points=>!context.source_features.filter(f=>f.classification==="freshwater_lake").some(f=>f.local_polygon.some(p=>insidePolygon(p,points)))&&points.every(p=>sourceDryLand(context,p))&&points.every((p,i)=>{
  const q=points[(i+1)%points.length],steps=Math.max(1,Math.ceil(distance(p,q)/3));
  return Array.from({length:steps},(_,j)=>[p[0]+(q[0]-p[0])*j/steps,p[1]+(q[1]-p[1])*j/steps]).every(z=>sourceDryLand(context,z));
 });
 const add=(list,points,fill,stroke=null,width=1,alpha=1,kind="scenery")=>{
  if(!safe(points))return false;list.push({kind,points:points.map(p=>p.map(round)),fill,stroke,width,alpha});return true;
 };
 const line=(list,points,stroke,width=1,alpha=1,kind="scenery")=>add(list,points,null,stroke,width,alpha,kind);
 // Subtle directional relief and elevation contours are illustration only.
 // The same primitive list is consumed by the in-engine and SVG renderers.
 const step=1000/N;
 for(let j=1;j<N-1;j++)for(let i=1;i<N-1;i++){
  const idx=j*(N+1)+i,v=vertices[idx];
  if(!v.land||v.h<48)continue;
  const dx=(vertices[idx+1].h-vertices[idx-1].h)/2,dy=(vertices[idx+N+1].h-vertices[idx-N-1].h)/2;
  const shade=Math.max(-1,Math.min(1,(dx+dy)/3));
  const x=i*step,y=j*step;
  add(ground,[[x,y],[x+step,y],[x+step,y+step],[x,y+step]],shade>0?"#514e3e":"#f8e7c3",null,1,Math.abs(shade)*.08,"hillshade");
  if(v.h>64 && (i+j)%3===0 && Math.hypot(dx,dy)>.25){
   const length=5+Math.min(13,Math.hypot(dx,dy)*7),norm=Math.hypot(dx,dy);
   line(ground,[[x+3,y+3],[x+3+dx/norm*length,y+3+dy/norm*length]],"#80765b",.75,.24,"slope-hatch");
  }
  const corners=[{p:[x,y],h:v.h},{p:[x+step,y],h:vertices[idx+1].h},
   {p:[x+step,y+step],h:vertices[idx+N+2].h},{p:[x,y+step],h:vertices[idx+N+1].h}];
  for(const cut of [60,65,70,75,80,85])for(const ids of [[0,1,2],[0,2,3]]){
   const cross=[];
   for(let k=0;k<3;k++){
    const a=corners[ids[k]],c=corners[ids[(k+1)%3]];
    if((a.h>=cut)===(c.h>=cut))continue;
    const t=(cut-a.h)/(c.h-a.h);cross.push([a.p[0]+(c.p[0]-a.p[0])*t,a.p[1]+(c.p[1]-a.p[1])*t]);
   }
   if(cross.length===2)line(ground,cross,"#82795e",.9,.3,"elevation-contour");
  }
 }
 // Settlement hinterland is schematic and based on original burgs only.
 // Clearing and building radii describe artwork, never the real town size.
 const towns=context.source_burgs;
 for(const town of towns){
  const [x,y]=town.local_position;
  const clearing=ring(x,y,83,20,.82).map((p,i)=>{
   const s=.85+random(seed,town.source_id,i,30)*.22;return [x+(p[0]-x)*s,y+(p[1]-y)*s];
  });
  add(ground,clearing,"#cbbb8e",null,1,1,"town-clearing");
  for(let k=0;k<16;k++){
   const angle=random(seed,town.source_id,k,1)*Math.PI*2;
   const radius=82+random(seed,town.source_id,k,2)*72;
   const cx=x+Math.cos(angle)*radius,cy=y+Math.sin(angle)*radius;
   const a=24+random(seed,town.source_id,k,3)*15,d=12+random(seed,town.source_id,k,4)*10;
   if(nearRoad(context,[cx,cy])<10||distance([cx,cy],[x,y])<68)continue;
   const p=[[cx-a,cy-d],[cx+a,cy-d-3],[cx+a-4,cy+d],[cx-a-2,cy+d+2]];
   if(ground.some(g=>g.kind==="field"&&g.points.some(q=>insidePolygon(q,p)||p.some(z=>insidePolygon(z,g.points)))))continue;
   if(!add(ground,p,["#b0ad72","#b9a96b","#c6b77c","#a9a17b"][k%4],"#8d885d",.8,1,"field"))continue;
   for(let z=-a+6;z<a-4;z+=7)line(ground,[[cx+z,cy-d+3],[cx+z-3,cy+d-3]],"#8d885d",.7,.55,"furrow");
  }
  for(let k=0;k<22;k++){
   const angle=random(seed,town.source_id,k,8)*Math.PI*2,r=17+random(seed,town.source_id,k,9)*43;
   const px=x+Math.cos(angle)*r,py=y+Math.sin(angle)*r*.7;
   if(nearRoad(context,[px,py])<9)continue;
   const w=4+random(seed,town.source_id,k,10)*3,h=5+random(seed,town.source_id,k,11)*4;
   add(objects,[[px-w,py],[px+w,py],[px+w,py+h],[px-w,py+h]],"#e1ccaa","#69583e",.7,1,"building");
   add(objects,[[px-w-1,py],[px,py-h*.6],[px+w+1,py],[px+w,py+3],[px-w,py+3]],k%3?"#8a6249":"#78684d","#554935",.7,1,"roof");
  }
 }
 // World-anchored object lattice. Adjacent crops sample the same tree centres.
 const spacing=.32,scale=1000/(b.right-b.left);
 for(let wy=Math.floor(b.top/spacing);wy<=Math.ceil(b.bottom/spacing);wy++)
  for(let wx=Math.floor(b.left/spacing);wx<=Math.ceil(b.right/spacing);wx++){
   const rx=random(seed,wx,wy,20),ry=random(seed,wx,wy,21);
   const x=((wx+.2+rx*.6)*spacing-b.left)*scale,y=((wy+.2+ry*.6)*spacing-b.top)*scale;
   if(x<12||x>988||y<12||y>988||!sourceDryLand(context,[x,y]))continue;
   if(towns.some(t=>distance(t.local_position,[x,y])<90)||nearRoad(context,[x,y])<10)continue;
   if(ground.some(g=>g.kind==="field"&&insidePolygon([x,y],g.points)))continue;
   const value=sampleLandscapeArt(world,context,seed,[b.left+x/scale,b.top+y/scale]),r=5+random(seed,wx,wy,22)*5;
   if(value.f>.48 && random(seed,wx,wy,23)<Math.min(.96,(value.f-.44)*4)){
    add(objects,ring(x+3,y+5,r,7,.62),"#343e2e",null,1,.22,"tree-shadow");
    if(value.h>62&&random(seed,wx,wy,25)<.65){
     add(objects,[[x-r,y+r*.5],[x,y-r*1.5],[x+r,y+r*.5]],"#48634a","#344d3a",.7,1,"pine");
     add(objects,[[x-r*.65,y-r*.1],[x,y-r*1.5],[x+r*.18,y-r*.25]],"#85956a",null,1,.62,"pine-light");
    }else{
     add(objects,ring(x,y,r,7,.95),value.f>.65?"#3e5944":"#55704d","#3d5139",.7,1,"canopy");
     add(objects,ring(x-2,y-2,r*.62,6,.85),"#87966b",null,1,.55,"canopy-light");
    }
   }else if(value.h>69 && random(seed,wx,wy,24)<.08){
    add(objects,[[x-5,y+3],[x-2,y-3],[x+3,y-5],[x+7,y+2],[x+4,y+5]],"#a19a80","#807965",.7,.85,"rock");
    line(objects,[[x-2,y-3],[x+1,y+2],[x+4,y+5]],"#d4c5a4",1,.75,"rock-light");
   }
  }
 for(let y=30;y<980;y+=36)for(let x=30;x<980;x+=55){
  if(random(seed,Math.floor((b.left+x/scale)*100),Math.floor((b.top+y/scale)*100),40)>.6)continue;
  const points=[[x-11,y],[x-4,y-2],[x+4,y-2],[x+11,y]];
  if(points.every(p=>!sourceDryLand(context,p)))water.push({kind:"water-ripple",points,fill:null,stroke:"#d9e3d2",width:1.1,alpha:.27});
 }
 objects.sort((a,b)=>Math.max(...a.points.map(p=>p[1]))-Math.max(...b.points.map(p=>p[1])));
 return {schema_version:1,id:"landscape-art:v1:"+hash(seed+":"+context.id+":art:v1"),source_context_id:context.id,
  source_world_sha256:seed,truth:"ILLUSTRATION_ONLY",terrain,water,ground,objects,
  claims:{walkable:"UNKNOWN",safe_routes:"UNKNOWN",surveyed_buildings:false},migration:"NOT_AUTOMATIC"};
}
export function renderSceneryPrimitives(primitives){
 return primitives.map(p=>`<${p.fill?"polygon":"polyline"} class="art-${p.kind}" points="${p.points.map(v=>v.join(",")).join(" ")}" fill="${p.fill||"none"}" stroke="${p.stroke||"none"}" stroke-width="${p.width}" opacity="${p.alpha}" stroke-linejoin="round"/>`).join("\n");
}
