import{readFile,writeFile}from'node:fs/promises';
import{sampleLandscapeArt}from'../../../tools/regiongen/inferred-fine-terrain.mjs';
import{sourceDryLand}from'../../../tools/regiongen/compose-local-region.mjs';
import{toLocalPoint,fromLocalPoint}from'../../../tools/regiongen/local-source-context.mjs';
import{clipSegment}from'../../../tools/regiongen/source-projection.mjs';
import{round}from'../src/context.mjs';
const read=async p=>JSON.parse(await readFile(p));
const world=await read('tests/worldgen/fixtures/game-11-determinism.json'),A=await read('research/game73/regions/neighbour-a.json'),B=await read('research/game73/regions/neighbour-b.json');
const ca=A.source_context,cb=B.source_context,a=ca.space.source_bounds,b=cb.space.source_bounds;
const overlap={left:Math.max(a.left,b.left),right:Math.min(a.right,b.right),top:Math.max(a.top,b.top),bottom:Math.min(a.bottom,b.bottom)};
const inside=p=>p[0]>overlap.left&&p[0]<overlap.right&&p[1]>overlap.top&&p[1]<overlap.bottom;
const error=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
let maxRoundTrip=0,dryMismatches=0,scalarMismatches=0,samples=[];
for(let y=0;y<9;y++)for(let x=0;x<9;x++){
 const p=[overlap.left+(x+.5)*(overlap.right-overlap.left)/9,overlap.top+(y+.5)*(overlap.bottom-overlap.top)/9];
 const pa=toLocalPoint(p,a),pb=toLocalPoint(p,b),da=sourceDryLand(ca,pa),db=sourceDryLand(cb,pb);
 maxRoundTrip=Math.max(maxRoundTrip,error(p,fromLocalPoint(pa,a)),error(p,fromLocalPoint(pb,b)));
 if(da!==db)dryMismatches++;
 const sa=sampleLandscapeArt(world,ca,ca.parent_source_world_sha256,p),sb=sampleLandscapeArt(world,cb,cb.parent_source_world_sha256,p);if(JSON.stringify(sa)!==JSON.stringify(sb))scalarMismatches++;
 samples.push({worldPoint:p.map(round),dryA:da,dryB:db,scalarA:sa,scalarB:sb});
}
function sourceLines(ctx,field){
 return ctx[field].flatMap(r=>r.segments.map(s=>{
  const pts=s.local_points.map(p=>fromLocalPoint(p,ctx.space.source_bounds)),clipped=clipSegment(...pts,overlap);return clipped?{id:r.source_id,sourceSegment:s.source_segment,points:clipped}:null;
 })).filter(Boolean).sort((a,b)=>a.id-b.id||a.sourceSegment-b.sourceSegment);
}
let routesA=sourceLines(ca,'source_routes'),routesB=sourceLines(cb,'source_routes'),riversA=sourceLines(ca,'source_rivers'),riversB=sourceLines(cb,'source_rivers');
function lineComparison(A,B){let maximum=0;let missing=0;for(const a of A){const b=B.find(x=>x.id===a.id&&x.sourceSegment===a.sourceSegment);if(!b){missing++;continue}maximum=Math.max(maximum,error(a.points[0],b.points[0]),error(a.points[1],b.points[1]))}for(const b of B)if(!A.some(a=>a.id===b.id&&a.sourceSegment===b.sourceSegment))missing++;return{piecesA:A.length,piecesB:B.length,missing,maxCoordinateDifference:maximum}}
function primitives(region,field,kinds){
 return region.landscape_presentation_v1[field].filter(p=>kinds.includes(p.kind)).map(p=>{const points=p.points.map(x=>fromLocalPoint(x,region.source_context.space.source_bounds)),centre=points.reduce((s,p)=>[s[0]+p[0]/points.length,s[1]+p[1]/points.length],[0,0]);return{kind:p.kind,centre,sourceRadius:Math.max(...points.map(p=>error(p,centre)))}}).filter(p=>inside(p.centre));
}
const treesA=primitives(A,'objects',['canopy','pine']),treesB=primitives(B,'objects',['canopy','pine']);
let matching=0,differentRadii=0;for(const t of treesA){const other=treesB.find(o=>o.kind===t.kind&&error(o.centre,t.centre)<.0001);if(other){matching++;if(Math.abs(other.sourceRadius-t.sourceRadius)>.001)differentRadii++}}
const fieldsA=primitives(A,'ground',['field','town-clearing']),fieldsB=primitives(B,'ground',['field','town-clearing']);
const sharedCells=ca.source_cells.filter(c=>cb.source_cells.some(d=>d.source_id===c.source_id)).map(c=>({cellId:c.source_id,identicalPolygon:JSON.stringify(c.world_polygon)===JSON.stringify(cb.source_cells.find(d=>d.source_id===c.source_id).world_polygon)}));
const result={overlap,sourceUnitsOnly:true,physicalKm:'UNCALIBRATED',gridSamples:samples.length,dryMismatches,scalarMismatches,maxRoundTripError:maxRoundTrip,sharedCells,routes:lineComparison(routesA,routesB),rivers:lineComparison(riversA,riversB),decoration:{treesInOverlapA:treesA.length,treesInOverlapB:treesB.length,matchingCentres:matching,matchingCentresWithDifferentSourceRadii:differentRadii,clearingsAndFieldsA:fieldsA,clearingsAndFieldsB:fieldsB,interpretation:'Exact source coordinates and scalar tendency can agree while fixed display-unit clearings/tree sizes and per-view filtered provider decoration differ; these are illustration seams, not altered roads/coasts'},samples};
await writeFile('research/game73/evidence/continuity.json',JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({...result,samples:undefined,decoration:{...result.decoration,clearingsAndFieldsA:fieldsA.length,clearingsAndFieldsB:fieldsB.length}},null,2));
if(dryMismatches||scalarMismatches||maxRoundTrip>1e-5||sharedCells.some(c=>!c.identicalPolygon)||result.routes.missing||result.routes.maxCoordinateDifference>1e-5||result.rivers.missing||result.rivers.maxCoordinateDifference>1e-5)throw Error('Authoritative continuity failed');
