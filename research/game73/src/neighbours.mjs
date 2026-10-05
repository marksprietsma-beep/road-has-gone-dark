import {buildCellContext} from '../../../tools/regiongen/cell-region.mjs';
export const visibleBurg=b=>b?.i>0&&!b.hidden&&!b.removed&&Number.isFinite(b.x)&&Number.isFinite(b.y);
export const inWindow=(b,r)=>b.x>=r.left&&b.x<=r.right&&b.y>=r.top&&b.y<=r.bottom;
export function scanNeighbours(world,sidecar,fingerprint){
 const burgs=world.settlements.filter(visibleBurg).sort((a,b)=>a.i-b.i),byCell=new Map(),index=new Map(world.cells.ids.map((id,i)=>[id,i]));
 for(const b of burgs){if(!byCell.has(b.cell))byCell.set(b.cell,[]);byCell.get(b.cell).push(b)}
 const contexts=new Map([...byCell.keys()].map(id=>[id,buildCellContext(world,id,fingerprint,sidecar)]));
 const pairs=[];
 for(let a=0;a<burgs.length;a++)for(let b=a+1;b<burgs.length;b++){
  const A=burgs[a],B=burgs[b],adjacent=world.cells.neighbors[index.get(A.cell)].includes(B.cell),same=A.cell===B.cell;
  if(!same&&!adjacent)continue;
  const ca=contexts.get(A.cell),cb=contexts.get(B.cell),routes=[];
  for(const r of world.routes.filter(r=>r.group==='roads')){
   // A genuinely direct connection requires consecutive original cell-tagged points.
   for(let s=0;s<r.points.length-1;s++)if(r.points[s][2]===A.cell&&r.points[s+1][2]===B.cell||r.points[s][2]===B.cell&&r.points[s+1][2]===A.cell)routes.push({routeId:r.i,sourceSegment:s,points:r.points.slice(s,s+2)});
  }
  const da=Math.hypot(A.x-B.x,A.y-B.y),spanA=ca.space.original_map_units,spanB=cb.space.original_map_units;
  pairs.push({burgIds:[A.i,B.i],names:[A.name,B.name],cellIds:[A.cell,B.cell],sameCell:same,adjacent,sourceDistance:da,physicalKm:'UNCALIBRATED',relativeToSmallerWindow:da/Math.min(spanA,spanB),aSeesB:inWindow(B,ca.space.source_bounds),bSeesA:inWindow(A,cb.space.source_bounds),directRoadSegments:routes});
 }
 pairs.sort((a,b)=>a.sourceDistance-b.sourceDistance||a.burgIds[0]-b.burgIds[0]);
 const near=pairs.filter(p=>p.relativeToSmallerWindow<=.5);
 const windows=[...contexts.values()];
 return {worldSeed:world.seed,canonicalWorldSha256:fingerprint,visibleBurgCount:burgs.length,occupiedCellCount:byCell.size,multiBurgCells:[...byCell].filter(([id,b])=>b.length>1).map(([id,b])=>({cellId:id,burgIds:b.map(x=>x.i)})),adjacentPairCount:pairs.filter(p=>p.adjacent).length,closeAdjacentPairs:near.length,closeDefinition:'Adjacent source cells and burg separation <= half the smaller existing GAME-62 viewing-window span; source-relative threshold, not kilometres',pairsVisibleInAtLeastOneWindow:pairs.filter(p=>p.aSeesB||p.bSeesA).length,pairsMutuallyVisible:pairs.filter(p=>p.aSeesB&&p.bSeesA).length,windowsWithNeighbourBurg:windows.filter(c=>c.source_burgs.some(b=>b.source_cell_id!==c.parent_cell.source_id)).length,totalWindowCount:windows.length,directRoadPairCount:pairs.filter(p=>p.directRoadSegments.length).length,nearestPairs:pairs.slice(0,8),selectedCandidate:pairs.find(p=>p.directRoadSegments.length&&p.aSeesB&&p.bSeesA),pairs};
}
