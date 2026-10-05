/** Research-only source adapter. No provider, gameplay, distances or saves. */
import {buildCellContext,sourceCellPolygon,polygonArea} from '../../../tools/regiongen/cell-region.mjs';
export const VERSION=1;
export const round=x=>Math.round(x*1e6)/1e6;
export const bearing=(a,b)=>round((Math.atan2(b[0]-a[0],a[1]-b[1])*180/Math.PI+360)%360);
export const angularDifference=(a,b)=>Math.abs(((a-b+540)%360)-180);
export const fact=(value,kind,provenance,confidence='high')=>({value,kind,confidence,provenance});
export const unknown=reason=>fact(null,'unknown',reason,'unavailable');
export function intersection(a,b,c,d){
 const dx=b[0]-a[0],dy=b[1]-a[1],ex=d[0]-c[0],ey=d[1]-c[1],den=dx*ey-dy*ex;
 if(Math.abs(den)<1e-10)return null;
 const t=((c[0]-a[0])*ey-(c[1]-a[1])*ex)/den,u=((c[0]-a[0])*dy-(c[1]-a[1])*dx)/den;
 return t>=-1e-8&&t<=1+1e-8&&u>=-1e-8&&u<=1+1e-8?[round(a[0]+t*dx),round(a[1]+t*dy)]:null;
}
function crossingRoutes(world,polygon,burg){
 const result=[];
 for(const route of world.routes.filter(r=>r.group==='roads'||r.group==='trails')){
  const points=route.points,seen=new Set();
  for(let s=0;s<points.length-1;s++)for(let edge=0;edge<polygon.length;edge++){
   const point=intersection(points[s],points[s+1],polygon[edge],polygon[(edge+1)%polygon.length]);
   if(!point||seen.has(point.join(',')))continue;seen.add(point.join(','));
   result.push({routeId:route.i,group:route.group,sourceSegment:s,worldPoint:point,bearingDegrees:bearing([burg.x,burg.y],point),kind:'source_derived',confidence:'medium',provenance:'Exact original route/cell-boundary intersection; bearing from burg is a broad approach, not a town gate'});
  }
 }
 return result.sort((a,b)=>a.routeId-b.routeId||a.bearingDegrees-b.bearingDegrees);
}
function shoreEdges(world,sidecar,cellId){
 const i=world.cells.ids.indexOf(cellId),own=sidecar.cell_vertex_ids[i],edges=[];
 for(const other of world.cells.neighbors[i]){
  const n=world.cells.ids.indexOf(other);if(world.cells.heights[n]>=20)continue;
  const wet=sidecar.cell_vertex_ids[n];
  for(let e=0;e<own.length;e++){
   const a=own[e],b=own[(e+1)%own.length];
   if(!wet.some((v,k)=>v===a&&wet[(k+1)%wet.length]===b||v===b&&wet[(k+1)%wet.length]===a))continue;
   edges.push({wetCellId:other,vertexIds:[a,b],points:[sidecar.vertices[a],sidecar.vertices[b]],featureId:world.cells.features[n]});
  }
 }
 return edges.sort((a,b)=>a.wetCellId-b.wetCellId||a.vertexIds[0]-b.vertexIds[0]);
}
function sourceWater(world,sidecar,burg,cell){
 const edges=shoreEdges(world,sidecar,burg.cell);
 const i=world.cells.ids.indexOf(burg.cell),wet=world.cells.neighbors[i].filter(id=>world.cells.heights[world.cells.ids.indexOf(id)]<20);
 let dx=0,dy=0,cx=0,cy=0;const centre=world.cells.points[i];
 for(const id of wet){const p=world.cells.points[world.cells.ids.indexOf(id)],length=Math.hypot(p[0]-burg.x,p[1]-burg.y),clength=Math.hypot(p[0]-centre[0],p[1]-centre[1]);if(length){dx+=(p[0]-burg.x)/length;dy+=(p[1]-burg.y)/length}if(clength){cx+=(p[0]-centre[0])/clength;cy+=(p[1]-centre[1])/clength}}
 const angle=Math.hypot(dx,dy)>1e-8?bearing([0,0],[dx,dy]):null;const cellAngle=Math.hypot(cx,cy)>1e-8?bearing([0,0],[cx,cy]):null;
 const features=[...new Set(edges.map(e=>e.featureId))].map(id=>({id,type:world.map.geography.find(f=>f.i===id)?.type??null}));
 return {shorelineEdges:fact(edges,'source_exact','Shared original pack.cells.v edges with neighbouring wet cells'),wetNeighbourIds:fact(wet,'source_exact','cells.neighbors/heights'),waterFeatureTypes:features.length?fact(features,'source_derived','Wet cells.features matched to map.geography; missing feature records stay null'):unknown('No adjacent wet cell edges'),orientation:angle===null?unknown('No unambiguous adjacent-water direction'):fact({bearingDegrees:angle,cardinal:['N','NE','E','SE','S','SW','W','NW'][Math.round(angle/45)%8]},'source_derived','Mean unit vectors from original burg position toward actual wet neighbour centres; broad water side, not shoreline shape','medium'),cellCentreOrientation:cellAngle===null?unknown('No adjacent-water direction'):fact(cellAngle,'source_derived','Parent-cell-centre bearing to wet neighbour centres; contrast with original burg anchor','medium'),shorelineLand:fact(cell.terrain===1,'source_exact','cells.terrain === 1'),portFlag:Object.hasOwn(burg,'port')?fact(burg.port,'source_exact','burg.port requests maritime significance; does not imply a metric harbour'):unknown('burg.port omitted; do not treat absent as an explicit false')};
}
function riverContext(world,burg){
 const i=world.cells.ids.indexOf(burg.cell),id=world.cells.river[i];
 if(!id)return {cellRiver:fact(0,'source_exact','cells.river'),orientation:unknown('No river ID in parent cell; nearby rivers may exist'),width:unknown('No calibrated local river width in canonical export')};
 const river=world.rivers.find(r=>r.i===id),at=river?.cells?.indexOf(burg.cell)??-1;
 const before=at>0?world.cells.points[world.cells.ids.indexOf(river.cells[at-1])]:null,after=at>=0&&at<river.cells.length-1?world.cells.points[world.cells.ids.indexOf(river.cells[at+1])]:null;
 return {cellRiver:fact(id,'source_exact','cells.river'),orientation:before&&after?fact({bearingDegrees:bearing(before,after),riverId:id},'source_derived','Ordered source river cell centres; approximate chain axis only, not surveyed flow/meanders','low'):unknown('Insufficient exported river-chain neighbours'),width:unknown('No calibrated local river width')};
}
export function relativeScale(burg,area,world){
 const pop=Number.isFinite(burg.population)?burg.population:null;
 const populations=world.settlements.filter(b=>b?.i>0&&!b.hidden&&!b.removed&&Number.isFinite(b.population)).map(b=>b.population).sort((a,b)=>a-b);
 const rank=pop===null?null:round(populations.filter(p=>p<=pop).length/populations.length);
 const capital=burg.capital===1,port=!!burg.port;
 const category=capital?'capital_or_major_fortified':port?'coastal_port':burg.group==='village'?'village':burg.group==='town'?'town':'unclassified';
 // Area envelope is a bounded aesthetic guide; population affects area, not metres.
 const target=pop===null?null:round(Math.max(.008,Math.min(.12,.02*Math.sqrt(Math.max(pop,0)/.306))));
 return {category:fact(category,'source_derived','burg.capital/port/group; port is a character overlay, not a mandatory size rank'),population:pop===null?unknown('Population absent'):fact(pop,'source_exact','burg.population in uncalibrated source units'),populationPercentile:rank===null?unknown('Population absent'):fact(rank,'source_derived','Within the same canonical fixture, inclusive empirical rank'),cellPolygonArea:fact(round(area),'source_derived','Shoelace area of original cell polygon; square source-map units'),aestheticEnvelope:target===null?unknown('No population input'):fact({targetCellAreaFraction:target,maximumCellAreaFraction:.12,equivalentDiscRadiusSourceUnits:round(Math.sqrt(area*target/Math.PI)),physicalKm:'UNCALIBRATED',rule:'0.02*sqrt(population/0.306), bounded 0.008..0.12; hypothesis, not demographic law',placement:'Do not cross source wet masks or overlap nearby burg envelopes; reduce/clip if the cell cannot contain it'},'inferred_visual','Research-only comparative envelope; not measured town land or a provider conversion','low')};
}
export function settlementContext(world,sidecar,fingerprint,burgId){
 const matches=world.settlements.filter(b=>b?.i===burgId&&!b.hidden&&!b.removed);if(matches.length!==1)throw Error('Unknown/ambiguous public burg');
 const b=matches[0],ctx=buildCellContext(world,b.cell,fingerprint,sidecar),i=world.cells.ids.indexOf(b.cell),biome=world.cells.biome[i],cell={terrain:world.cells.terrain[i]};
 const id=`settlement-context:v1:${ctx.generation_world_seed}:burg:${b.i}:cell:${b.cell}`;
 return {schemaVersion:VERSION,id,label:b.name,identity:{worldSeed:world.seed,structuralWorldId:ctx.generation_world_seed,canonicalWorldSha256:fingerprint,burgId:b.i,parentCellId:b.cell},position:fact([b.x,b.y],'source_exact','burg.x/y; canonical source map coordinates, x-right/y-down'),terrain:{biome:fact({id:biome,name:world.biomes.find(x=>x.i===biome)?.name??null},'source_exact','cells.biome + canonical biomes'),height:fact(world.cells.heights[i],'source_exact','cells.heights; source elevation index, not metres'),broadClass:fact(cell.terrain===1?'shoreline':world.cells.river[i]>0?'river_cell':world.cells.heights[i]>=68?'highland':'inland','source_derived','Source shoreline flag, river ID and >=68 height heuristic; lake/ocean distinguished separately'),surroundings:fact([5,6,7,8,9].includes(biome)?'woodland-biome; local cultivated clearing permitted':[1,2,10,11].includes(biome)?'sparse vegetation-biome':'mixed open/vegetated landscape','inferred_visual','Existing source-context vegetation families; not exact woodland/crop boundaries','low')},water:sourceWater(world,sidecar,b,cell),river:riverContext(world,b),roadApproaches:crossingRoutes(world,ctx.parent_cell.world_polygon,b),fortifications:Object.fromEntries(['walls','citadel','capital'].map(k=>[k,Object.hasOwn(b,k)?fact(b[k],'source_exact','burg.'+k):unknown('Source flag omitted')])),scale:relativeScale(b,polygonArea(ctx.parent_cell.world_polygon),world),regional:{cellPolygon:ctx.parent_cell.world_polygon,window:ctx.space.source_bounds,fringe:ctx.space.fringe,visibleBurgs:ctx.source_burgs.map(x=>({...x,ownership:x.source_cell_id===b.cell?'owned':'neighbour_in_view',detailedMapAvailable:false})),physicalKm:'UNCALIBRATED'},unsupported:{gatePositions:unknown('No source town gates'),coastToTownTransform:unknown('No world-to-provider scale calibration'),localFarmBoundaries:unknown('Provider artistic detail; not canonical'),travelTimes:unknown('No travel/movement research authorised')}};
}
