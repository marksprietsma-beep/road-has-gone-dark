import{readFile,writeFile}from'node:fs/promises';
import{sourceCellPolygon}from'../../../tools/regiongen/cell-region.mjs';
import{toLocalPoint}from'../../../tools/regiongen/local-source-context.mjs';
import{clipSegment}from'../../../tools/regiongen/source-projection.mjs';
const folder='research/game73',read=async p=>JSON.parse(await readFile(p)),cases=(await read(folder+'/examples/cases.json')).cases;
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
const svg=body=>`<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000"><defs><marker id="arrow" markerWidth="9" markerHeight="9" refX="7" refY="3" orient="auto"><path d="M0 0L8 3L0 6Z" fill="#a9462c"/></marker></defs>${body}</svg>`;
const polygon=(points,fill,stroke,width=2)=>`<polygon points="${points.map(p=>p.join(',')).join(' ')}" fill="${fill}" stroke="${stroke}" stroke-width="${width}"/>`;
const text=(p,value,size=18,color='#28251f')=>`<text x="${p[0]}" y="${p[1]}" font-family="DejaVu Sans,sans-serif" font-size="${size}" fill="${color}" stroke="#fff2d4" stroke-width="3" paint-order="stroke">${esc(value)}</text>`;
const line=(points,color,width=4,dash='')=>`<polyline points="${points.map(p=>p.join(',')).join(' ')}" fill="none" stroke="${color}" stroke-width="${width}" ${dash?`stroke-dasharray="${dash}"`:''}/>`;
const marker=(p,label,color='#a9462c')=>`<circle cx="${p[0]}" cy="${p[1]}" r="7" fill="${color}" stroke="#fff2d4" stroke-width="2"/><text x="${p[0]+(p[0]>650?-12:12)}" y="${p[1]+(p[1]<40?35:-12)}" text-anchor="${p[0]>650?'end':'start'}" font-family="DejaVu Sans,sans-serif" font-size="30" fill="#28251f" stroke="#fff2d4" stroke-width="4" paint-order="stroke">${esc(label)}</text>`;
for(const c of cases){
 const ctx=await read(`${folder}/examples/${c.slug}.context.json`),world=await read(`tests/worldgen/fixtures/${c.stem}.json`),sidecar=await read(`${folder}/inputs/${c.stem}.geography.json`),region=await read(`${folder}/regions/${c.slug}.json`),r=ctx.regional.window;
 const span=r.right-r.left,cx=(r.left+r.right)/2,cy=(r.top+r.bottom)/2;
 const bounds={left:Math.max(0,cx-span),right:Math.min(world.map.width,cx+span),top:Math.max(0,cy-span),bottom:Math.min(world.map.height,cy+span)};
 const project=p=>toLocalPoint(p,bounds),local=p=>toLocalPoint(p,r);
 let body='<rect width="1000" height="1000" fill="#7caaa7"/>';
 for(const feature of world.map.geography.filter(f=>f.vertices?.length&&['island','lake'].includes(f.type))){body+=polygon(feature.vertices.map(i=>project(sidecar.vertices[i])),feature.type==='lake'?'#7caaa7':'#d0ca9d','none',0)}
 for(let i=0;i<world.cells.ids.length;i++){
  const p=world.cells.points[i];if(p[0]<bounds.left-span*.2||p[0]>bounds.right+span*.2||p[1]<bounds.top-span*.2||p[1]>bounds.bottom+span*.2)continue;
  const poly=sourceCellPolygon(world,sidecar,world.cells.ids[i]),owned=world.cells.ids[i]===c.cellId;
  body+=polygon(poly.map(project),'none',owned?'#a9462c':'#888977',owned?5:1);
  body+=text(project(p),world.cells.ids[i],19,'#5b5b48');
 }
 for(const route of world.routes){for(let i=0;i<route.points.length-1;i++){const piece=clipSegment(route.points[i],route.points[i+1],bounds);if(piece)body+=line(piece.map(project),route.group==='roads'?'#825338':route.group==='searoutes'?'#53778c':'#b6925a',route.group==='roads'?4:2,route.group==='roads'?'':'7 4')}}
 for(const river of world.rivers){let pts=river.cells.map(id=>world.cells.points[world.cells.ids.indexOf(id)]);for(let i=0;i<pts.length-1;i++){const piece=clipSegment(pts[i],pts[i+1],bounds);if(piece)body+=line(piece.map(project),'#396fa0',3,'4 3')}}
 const outline=rect=>{const a=project([rect.left,rect.top]),b=project([rect.right,rect.bottom]);return `<rect x="${a[0]}" y="${a[1]}" width="${b[0]-a[0]}" height="${b[1]-a[1]}" fill="none" stroke="#a9462c" stroke-width="3" stroke-dasharray="12 7"/>`};
 body+=outline(r);
 const core=ctx.regional.unpaddedCoreBounds;body+=outline(core);
 if(c.slug.startsWith('neighbour-')){const pair=(await read(folder+'/examples/cases.json')).pair;for(const road of pair.directRoadSegments){const points=road.points.map(p=>project(p));body+=line(points,'#a9462c',6)+text([(points[0][0]+points[1][0])/2-135,(points[0][1]+points[1][1])/2],`Road ${road.routeId}`,25)}}
 for(const b of world.settlements.filter(b=>b?.i>0&&!b.hidden&&!b.removed&&b.x>=bounds.left&&b.x<=bounds.right&&b.y>=bounds.top&&b.y<=bounds.bottom))body+=marker(project([b.x,b.y]),`${b.name} #${b.i}`,b.cell===c.cellId?'#a9462c':'#634ba0');
 const ownerPoly=ctx.regional.cellPolygon.map(project),pt=project(ctx.position.value),rad=ctx.scale.aestheticEnvelope.value.equivalentDiscRadiusSourceUnits*1000/(bounds.right-bounds.left);
 body+=`<defs><clipPath id="owned">${polygon(ownerPoly,'white','none',0)}</clipPath></defs><circle cx="${pt[0]}" cy="${pt[1]}" r="${rad}" fill="#a9462c" opacity=".18" clip-path="url(#owned)"/>`;
 if(ctx.water.orientation.value){let theta=ctx.water.orientation.value.bearingDegrees*Math.PI/180,tip=[pt[0]+Math.sin(theta)*110,pt[1]-Math.cos(theta)*110];body+=`<path d="M${pt.join(' ')}L${tip.join(' ')}" stroke="#a9462c" stroke-width="5" marker-end="url(#arrow)"/>`+text([tip[0]+8,tip[1]],'Wet-cell side',17)}
 body+=text([25,34],`${ctx.label}: exact cells, original routes; dashed rivers are approximate`,18)+text([25,972],'Dashed squares: window + unpadded core; tint: hypothetical footprint clipped to owned cell',16);
 await writeFile(`${folder}/evidence/${c.slug}-source.svg`,svg(body));
 // Exact world-location inset, separately rendered from original feature polygons.
 let full='<rect width="1000" height="1000" fill="#7caaa7"/>';const wp=p=>[p[0]*1000/world.map.width,180+p[1]*640/world.map.height];
 for(const feature of world.map.geography.filter(f=>f.vertices?.length&&['island','lake'].includes(f.type)))full+=polygon(feature.vertices.map(i=>wp(sidecar.vertices[i])),feature.type==='lake'?'#7caaa7':'#c2c394','none',0);
 const source=wp(ctx.position.value);full+=`<circle cx="${source[0]}" cy="${source[1]}" r="14" fill="none" stroke="#a9462c" stroke-width="5"/>`+text([25,95],`${c.stem} / ${ctx.identity.worldSeed}`,26)+text([25,130],`${ctx.label} #${c.id}, cell ${c.cellId}; canonical location`,24);
 await writeFile(`${folder}/evidence/${c.slug}-world.svg`,svg(full));
 let overlay=polygon(ctx.regional.cellPolygon.map(local),'none','#a9462c',4);
 const inner=1000/7;overlay+=`<rect x="${inner}" y="${inner}" width="${1000-2*inner}" height="${1000-2*inner}" fill="none" stroke="#a9462c" stroke-width="2" stroke-dasharray="9 5"/>`;
 const cp=local(ctx.position.value),radius=ctx.scale.aestheticEnvelope.value.equivalentDiscRadiusSourceUnits*1000/span;
 overlay+=`<defs><clipPath id="envelope">${polygon(ctx.regional.cellPolygon.map(local),'white','none',0)}</clipPath></defs><circle cx="${cp[0]}" cy="${cp[1]}" r="${radius}" fill="#a9462c" opacity=".25" clip-path="url(#envelope)"/>`;
 for(const b of ctx.regional.visibleBurgs)overlay+=marker(b.local_position,`${b.name} #${b.source_id} (${b.ownership==='owned'?'OWNED':'NEIGHBOUR'})`,b.ownership==='owned'?'#a9462c':'#634ba0');
 const raw=await readFile(`${folder}/regions/${c.slug}.svg`,'utf8');await writeFile(`${folder}/evidence/${c.slug}-region.svg`,raw.slice(0,raw.lastIndexOf('</svg>'))+overlay+raw.slice(raw.lastIndexOf('</svg>')));
 if(!c.townAvailable)continue;
 const town=await read(`${folder}/examples/${c.slug}.town-assessment.json`),frame=town.frame,s=900/Math.max(frame.max_x-frame.min_x,frame.max_y-frame.min_y),tp=p=>[50+(p[0]-frame.min_x)*s,50+(p[1]-frame.min_y)*s],origin=tp([0,0]);
 for(const [suffix,rotation]of [['town',0],...(town.rotationExperiment?[['rotation',town.rotationExperiment.clockwiseDegrees]]:[])]){
  const embedded=(await readFile(`research/game69/art/${c.slug}.public.svg`)).toString('base64');
  let art=`<image href="data:image/svg+xml;base64,${embedded}" x="50" y="50" width="${(frame.max_x-frame.min_x)*s}" height="${(frame.max_y-frame.min_y)*s}"/>`;
  for(const [i,e] of town.entrances.entries())art+=marker(tp(e.position),String(i+1),'#634ba0');
  const painted=`<g transform="rotate(${rotation},${origin.join(',')})">${art}</g>`;
  let annotation='';for(const a of ctx.roadApproaches){const t=a.bearingDegrees*Math.PI/180,tip=[origin[0]+Math.sin(t)*190,origin[1]-Math.cos(t)*190];annotation+=`<path d="M${origin.join(' ')}L${tip.join(' ')}" stroke="#a9462c" stroke-width="4" marker-end="url(#arrow)"/>`+text([tip[0]+6,tip[1]],`${a.group} ${a.routeId}`,17)}
  if(ctx.water.orientation.value){const t=ctx.water.orientation.value.bearingDegrees*Math.PI/180,tip=[origin[0]+Math.sin(t)*260,origin[1]-Math.cos(t)*260];annotation+=`<path d="M${origin.join(' ')}L${tip.join(' ')}" stroke="#a9462c" stroke-width="5" marker-end="url(#arrow)"/>`+text([tip[0]+5,tip[1]],'Source water side',17)}
  await writeFile(`${folder}/evidence/${c.slug}-${suffix}.svg`,svg('<rect width="1000" height="1000" fill="#fff2c8"/>'+painted+annotation+text([20,975],rotation?`Display-only rotation ${rotation.toFixed(2)}°; source arrows fixed; NOT applied`:'Preserved PUBLIC artwork; source-bearing diagram, NOT world georeferencing',18)));
 }
}
console.log('Rendered source-backed SVG diagnostics for five actual cases; preserved public art referenced unchanged.');
