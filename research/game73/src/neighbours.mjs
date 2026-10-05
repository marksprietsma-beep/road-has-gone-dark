import {buildCellContext} from '../../../tools/regiongen/cell-region.mjs';
export const visibleBurg=b=>b?.i>0&&!b.hidden&&!b.removed&&Number.isFinite(b.x)&&Number.isFinite(b.y);
export const inWindow=(b,r)=>b.x>=r.left&&b.x<=r.right&&b.y>=r.top&&b.y<=r.bottom;
export function scanNeighbours(world,sidecar,fingerprint){
 const burgs=world.settlements.filter(visibleBurg).sort((a,b)=>a.i-b.i),byCell=new Map(),index=new Map(world.cells.ids.map((id,i)=>[id,i]));
 for(const b of burgs){if(!byCell.has(b.cell))byCell.set(b.cell,[]);byCell.get(b.cell).push(b)}
 const contexts=new Map([...byCell.keys()].map(id=>[id,buildCellContext(world,id,fingerprint,sidecar)]));
 const directRoads=new Map();
 for(const route of world.routes.filter(r=>r.group==='roads'))for(let s=0;s<route.points.length-1;s++){
  const a=route.points[s][2],b=route.points[s+1][2];if(a===b)continue;const key=[Math.min(a,b),Math.max(a,b)].join(':');if(!directRoads.has(key))directRoads.set(key,[]);directRoads.get(key).push({routeId:route.i,sourceSegment:s,points:route.points.slice(s,s+2)});
 }
 const pairs=[];
 for(const A of burgs)for(const B of [A.cell,...world.cells.neighbors[index.get(A.cell)]].flatMap(id=>byCell.get(id)??[])){
  if(B.i<=A.i)continue;
  const adjacent=world.cells.neighbors[index.get(A.cell)].includes(B.cell),same=A.cell===B.cell;
  if(!same&&!adjacent)continue;
  const ca=contexts.get(A.cell),cb=contexts.get(B.cell),routes=directRoads.get([Math.min(A.cell,B.cell),Math.max(A.cell,B.cell)].join(':'))??[];
  const da=Math.hypot(A.x-B.x,A.y-B.y),spanA=ca.space.original_map_units,spanB=cb.space.original_map_units;
  pairs.push({burgIds:[A.i,B.i],names:[A.name,B.name],cellIds:[A.cell,B.cell],sameCell:same,adjacent,sourceDistance:da,physicalKm:'UNCALIBRATED',relativeToSmallerWindow:da/Math.min(spanA,spanB),aSeesB:inWindow(B,ca.space.source_bounds),bSeesA:inWindow(A,cb.space.source_bounds),directRoadSegments:routes});
 }
 pairs.sort((a,b)=>a.sourceDistance-b.sourceDistance||a.burgIds[0]-b.burgIds[0]);
 const near=pairs.filter(p=>p.relativeToSmallerWindow<=.5);
 const windows=[...contexts.values()];
 const coverage=windows.map(c=>{const p=c.parent_cell.world_polygon,xs=p.map(p=>p[0]),ys=p.map(p=>p[1]),extent=Math.max(Math.max(...xs)-Math.min(...xs),Math.max(...ys)-Math.min(...ys)),cx=(Math.max(...xs)+Math.min(...xs))/2,cy=(Math.max(...ys)+Math.min(...ys))/2,core={left:cx-extent/2,right:cx+extent/2,top:cy-extent/2,bottom:cy+extent/2};const neighbours=c.source_burgs.filter(b=>b.source_cell_id!==c.parent_cell.source_id),fringe=neighbours.filter(b=>!inWindow({x:b.world_position[0],y:b.world_position[1]},core));return{core:neighbours.length-fringe.length,fringe:fringe.length}});

 return {worldSeed:world.seed,canonicalWorldSha256:fingerprint,visibleBurgCount:burgs.length,occupiedCellCount:byCell.size,multiBurgCells:[...byCell].filter(([id,b])=>b.length>1).map(([id,b])=>({cellId:id,burgIds:b.map(x=>x.i)})),adjacentPairCount:pairs.filter(p=>p.adjacent).length,closeAdjacentPairs:near.length,closeDefinition:'Adjacent source cells and burg separation <= half the smaller existing GAME-62 viewing-window span; source-relative threshold, not kilometres',pairsVisibleInAtLeastOneWindow:pairs.filter(p=>p.aSeesB||p.bSeesA).length,pairsMutuallyVisible:pairs.filter(p=>p.aSeesB&&p.bSeesA).length,windowsWithNeighbourBurg:windows.filter(c=>c.source_burgs.some(b=>b.source_cell_id!==c.parent_cell.source_id)).length,totalWindowCount:windows.length,fringeCoverage:{windowsWithAddedFringeNeighbours:coverage.filter(c=>c.fringe>0).length,windowsWhereFringeAddsFirstNeighbour:coverage.filter(c=>c.fringe>0&&c.core===0).length,neighbourVisibilityRecordsInCore:coverage.reduce((n,c)=>n+c.core,0),neighbourVisibilityRecordsInFringe:coverage.reduce((n,c)=>n+c.fringe,0),denominator:'All occupied-cell windows; records count each visible neighbour separately per view'},directRoadPairCount:pairs.filter(p=>p.directRoadSegments.length).length,nearestPairs:pairs.slice(0,8),selectedCandidate:pairs.find(p=>p.directRoadSegments.length&&p.aSeesB&&p.bSeesA),pairs};
}
