import {readFile,writeFile,mkdir,copyFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {generateCellRegion,publicRegion,renderRegion} from '../../../tools/regiongen/generator-v1.mjs';
import {hash} from '../../../tools/regiongen/cell-region.mjs';
import {clipSegment} from '../../../tools/regiongen/source-projection.mjs';
import {settlementContext,bearing,angularDifference,round} from '../src/context.mjs';
import {scanNeighbours} from '../src/neighbours.mjs';
const base='research/game73';await mkdir(base+'/inputs',{recursive:true});await mkdir(base+'/.tmp',{recursive:true});
const write=async(p,v)=>writeFile(base+'/'+p,JSON.stringify(v,null,2)+'\n');
const worlds={};
for(const stem of ['game-11-determinism','atlas-showcase']){
 const bytes=await readFile(`tests/worldgen/fixtures/${stem}.json`),world=JSON.parse(bytes),fp=hash(bytes),path=base+`/inputs/${stem}.geography.json`;
 try{await readFile(path)}catch{
  const existing=`tools/regiongen/.tmp/geography-${stem==='atlas-showcase'?'atlas':'game-11'}.json`;
  try{await copyFile(existing,path)}catch{
   const replay=base+`/.tmp/${stem}.json`,r=spawnSync(process.execPath,['tools/worldgen/generate-azgaar.mjs','--seed',world.seed,'--output',replay,'--geometry-output',path],{encoding:'utf8'});if(r.status!==0)throw Error(r.stderr);if(!(await readFile(replay)).equals(bytes))throw Error('Canonical replay differs');
  }
 }
 const sidecar=JSON.parse(await readFile(path));worlds[stem]={world,fp,sidecar};
 const scan=scanNeighbours(world,sidecar,fp);await write(`examples/${stem}-neighbours.json`,scan);
 console.log(stem,JSON.stringify({...scan,pairs:undefined,nearestPairs:undefined,selectedCandidate:scan.selectedCandidate}));
}
const cases=[{slug:'albanes',stem:'game-11-determinism',id:7},{slug:'batan',stem:'atlas-showcase',id:760},{slug:'thilranlena',stem:'atlas-showcase',id:68}];
const scan=JSON.parse(await readFile(base+'/examples/game-11-determinism-neighbours.json'));
const pair=scan.selectedCandidate;if(!pair)throw Error('No genuine mutually visible road-connected adjacent pair');
for(let i=0;i<2;i++)cases.push({slug:'neighbour-'+(i?'b':'a'),stem:'game-11-determinism',id:pair.burgIds[i]});
const results=[];
for(const c of cases){
 const {world,sidecar,fp}=worlds[c.stem],context=settlementContext(world,sidecar,fp,c.id);
 const originalTown=cases.indexOf(c)<3;
 context.regional.visibleBurgs.forEach(b=>{b.detailedMapAvailable=cases.slice(0,3).some(x=>x.stem===c.stem&&x.id===b.source_id)});
 await write(`examples/${c.slug}.context.json`,context);
 let region;
 if(originalTown){region=JSON.parse(await readFile(`research/game70/regions/${c.slug}.json`));if(region.source_context.parent_source_world_sha256!==fp||region.parent_source_world_sha256&&region.parent_source_world_sha256!==fp||region.source_context.parent_cell.source_id!==context.identity.parentCellId)throw Error('Wrong inherited region');}
 else{
  const full=await generateCellRegion(world,context.identity.parentCellId,fp,sidecar),again=await generateCellRegion(world,context.identity.parentCellId,fp,sidecar);
  if(JSON.stringify(full)!==JSON.stringify(again))throw Error('Region replay differs');region=publicRegion(full);
 }
 await writeFile(`${base}/regions/${c.slug}.json`,JSON.stringify(region)+'\n');
 await writeFile(`${base}/regions/${c.slug}.svg`,renderRegion(region));
 let townEvidence=null;
 if(originalTown){
  const source=JSON.parse(await readFile(`research/game67/fixtures/${c.slug}.json`)),pub=JSON.parse(await readFile(`research/game67/samples/${c.slug}.public.json`));
  if(pub.settlement.worldIdentity!==fp||pub.settlement.burgId!==c.id)throw Error('Wrong preserved town identity');
  const entrances=source.geojson.features.filter(f=>f.properties.layer==='entrance').map(f=>({id:f.properties.entrance_id,kind:f.properties.kind,position:f.geometry.coordinates,bearingDegrees:f.properties.bearing_deg,routes:(f.properties.matched_routes??[]).map(m=>({id:m.route_id??null,requestedBearing:m.requested_bearing_deg,reportedDelta:m.match_delta_deg,kind:m.kind}))}));
  const streetApproaches=source.geojson.features.filter(f=>f.properties.layer==='street'&&f.properties.route_role==='approach').map(f=>({id:f.properties.street_id,routeIds:f.properties.route_ids,ends:[f.geometry.coordinates[0],f.geometry.coordinates.at(-1)],bearingDegrees:bearing([0,0],f.geometry.coordinates.at(-1))}));
  const water=source.backdrop.water;
  // Measure only shoreline segments actually visible in the preserved art frame.
  // Exclude the remote closure edges of the synthetic water polygon.
  const bounds=pub.layout.bounds,rect={left:bounds.min_x,right:bounds.max_x,top:bounds.min_y,bottom:bounds.max_y};
  const visibleShore=[];let nx=0,ny=0;
  for(const ring of water){
   const centroid=ring.reduce((s,p)=>[s[0]+p[0]/ring.length,s[1]+p[1]/ring.length],[0,0]);
   for(let i=0;i<ring.length;i++){
    const clipped=clipSegment(ring[i],ring[(i+1)%ring.length],rect);if(!clipped)continue;
    const[a,b]=clipped,dx=b[0]-a[0],dy=b[1]-a[1],length=Math.hypot(dx,dy);if(length<1e-6)continue;
    const mid=[(a[0]+b[0])/2,(a[1]+b[1])/2],normal=[dy,-dx];
    const sign=normal[0]*(centroid[0]-mid[0])+normal[1]*(centroid[1]-mid[1])>0?1:-1;
    nx+=normal[0]*sign;ny+=normal[1]*sign;visibleShore.push(clipped);
   }
  }
  const nearest=visibleShore.length?{visibleSegments:visibleShore,bearingDegrees:bearing([0,0],[nx,ny]),method:'Length-weighted normal of actual visible source water-ring edges; remote closure edges excluded'}:null;
  townEvidence={buildingCount:pub.buildings.length,providerUnits:pub.layout.units,frame:pub.layout.bounds,scaleEvidence:pub.layout.scaleEvidence,footprintWorldTransform:null,physicalKm:'UNCALIBRATED',entrances,streetApproaches,waterOrientation:nearest,sourceRoadApproaches:context.roadApproaches,sourceWater:context.water.orientation,artSha256:hash(await readFile(`research/game69/art/${c.slug}.public.svg`)),originalArtSha256:hash(await readFile(`research/game69/art/${c.slug}.original.svg`)),providerRevision:pub.layout.providerRevision};
  if(nearest&&context.water.orientation.value){
   const turn=round(((context.water.cellCentreOrientation.value-nearest.bearingDegrees+540)%360)-180);
   const score=rotation=>entrances.flatMap(e=>e.routes.filter(r=>r.id).map(r=>({entranceId:e.id,routeId:r.id,kind:e.kind,deltaDegrees:round(angularDifference(e.bearingDegrees+rotation,r.requestedBearing))})));
   townEvidence.rotationExperiment={kind:'research_display_transform_only',target:'Parent-cell-centre approximation, intentionally contrasted with burg-anchor orientation',clockwiseDegrees:turn,originalRoadErrors:score(0),rotatedRoadErrors:score(turn),originalWaterDifference:round(angularDifference(context.water.orientation.value.bearingDegrees,nearest.bearingDegrees)),rotatedWaterDifference:round(angularDifference(context.water.orientation.value.bearingDegrees,nearest.bearingDegrees+turn)),notAppliedToOriginal:true};
  }
  await write(`examples/${c.slug}.town-assessment.json`,townEvidence);
 }
 results.push({...c,label:context.label,cellId:context.identity.parentCellId,contextId:context.id,canonicalSha256:fp,regionSha256:hash(JSON.stringify(region)+'\n'),townAvailable:originalTown});
 console.log('PASS context/region',c.slug,context.label,'burg',c.id,'cell',context.identity.parentCellId,'roads',context.roadApproaches.length);
}
await write('examples/cases.json',{schemaVersion:1,cases:results,pair,physicalKm:'UNCALIBRATED'});
