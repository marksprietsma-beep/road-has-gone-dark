import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {generateCellRegion,publicRegion,renderRegion} from '../../tools/regiongen/generator-v1.mjs';
import {hash,buildCellContext,isOwnedDryLand,sourceCellPolygon} from '../../tools/regiongen/cell-region.mjs';
import {sampleLandscapeArt} from '../../tools/regiongen/inferred-fine-terrain.mjs';
import {fromLocalPoint,toLocalPoint} from '../../tools/regiongen/local-source-context.mjs';
import {clipSegment,clipPolygon} from '../../tools/regiongen/source-projection.mjs';
import {hexAt,hexCentre} from '../../tools/regiongen/hex-overlay.mjs';
const folder='review/local-region-v1',manifest=JSON.parse(await readFile(folder+'/manifest.json'));
const reports=[];
for(const [stem,geo] of [['game-11-determinism','game-11'],['atlas-showcase','atlas']]){
 const bytes=await readFile(`tests/worldgen/fixtures/${stem}.json`,'utf8'),world=JSON.parse(bytes),fp=hash(bytes),sidecar=JSON.parse(await readFile(`tools/regiongen/.tmp/geography-${geo}.json`));
 for(const c of manifest.cases.filter(c=>c.world===stem)){
  const region=await generateCellRegion(world,c.cell_id,fp,sidecar),again=await generateCellRegion(world,c.cell_id,fp,sidecar);
  assert.equal(JSON.stringify(region),JSON.stringify(again),'byte-identical replay');
  assert.equal(JSON.stringify(region)+'\n',await readFile(`${folder}/${c.name}.developer.json`,'utf8').then(s=>{let p=JSON.parse(s);delete p.export_scope;return JSON.stringify(p)+'\n'}));
  assert.deepEqual(region.source_context.parent_cell.world_polygon,sourceCellPolygon(world,sidecar,c.cell_id));
  const renamed=structuredClone(world);renamed.settlements.find(b=>b.i===c.burg_id).name='RENAMED';
  const r=await generateCellRegion(renamed,c.cell_id,fp,sidecar);
  assert.equal(r.id,region.id);assert.deepEqual(r.landscape_presentation_v1,region.landscape_presentation_v1);
  assert.deepEqual(r.source_context.parent_cell,region.source_context.parent_cell);
  const renamedBytes=JSON.stringify(renamed)+'\n',renamedFingerprint=hash(renamedBytes);
  const renamedSidecar={...sidecar,source_world_sha256:renamedFingerprint};
  const renamedWorld=await generateCellRegion(renamed,c.cell_id,renamedFingerprint,renamedSidecar);
  assert.equal(renamedWorld.id,region.id,'source-file rename cannot change cell identity');
  assert.equal(renamedWorld.provider.seed,region.provider.seed,'source-file rename cannot reroll Town Forge');
  for(const key of ['ground','objects','water','provider_marks'])assert.deepEqual(renamedWorld.landscape_presentation_v1[key],region.landscape_presentation_v1[key]);
  assert.deepEqual(renamedWorld.landscape_presentation_v1.terrain.vertices,region.landscape_presentation_v1.terrain.vertices);
  assert.deepEqual(renamedWorld.local_sites_v2.sites.filter(s=>s.kind!=='hometown'),region.local_sites_v2.sites.filter(s=>s.kind!=='hometown'));
  assert.deepEqual(r.local_sites_v2.sites.filter(s=>s.kind!=='hometown'),region.local_sites_v2.sites.filter(s=>s.kind!=='hometown'));
  const pub=publicRegion(region),text=JSON.stringify(pub)+renderRegion(pub);
  for(const site of [...region.local_sites_v2.sites,...region.source_context.source_landmarks]){
   if(!['discovered','visited'].includes(site.knowledge))for(const value of [site.id,site.label])assert(!text.includes(value),'secret leak '+value);
  }
  const hidden=region.local_sites_v2.sites.find(s=>s.knowledge==='hidden'||s.knowledge==='rumoured');
  if(hidden){const known=publicRegion(region,{[hidden.id]:'discovered'});assert(known.local_sites_v2.sites.some(s=>s.id===hidden.id&&s.label===hidden.label));assert.equal((renderRegion(known).match(/class="shared-game-icon"/g)||[]).length,(renderRegion(pub).match(/class="shared-game-icon"/g)||[]).length+1,'discovered site gains a public marker')}
  assert(pub.local_sites_v2.rumours.every(r=>!('id' in r)&&!('position' in r)&&!('label' in r)));
  for(const site of region.local_sites_v2.sites.filter(s=>s.kind!=='hometown'))assert(isOwnedDryLand(region.source_context,site.position),'owned dry-land placement');
  assert(region.local_sites_v2.sites.length<=9);
  const b=region.source_context.space.source_bounds;
  for(const p of region.source_context.parent_cell.world_polygon)assert(Math.hypot(...fromLocalPoint(toLocalPoint(p,b),b).map((x,i)=>x-p[i]))<1e-4);
  for(const cell of region.hex_overlay_v1.cells)assert.deepEqual(hexAt(cell.world_centre),cell.axial);
  const duplicate=structuredClone(world);duplicate.cells.ids[1]=duplicate.cells.ids[0];
  await assert.rejects(()=>generateCellRegion(duplicate,c.cell_id,fp,sidecar));
  await assert.rejects(()=>generateCellRegion(world,c.cell_id,'0'.repeat(64),sidecar),/match/);
  const malformed=structuredClone(sidecar);malformed.cell_vertex_ids[world.cells.ids.indexOf(c.cell_id)]=[0,0,0];
  assert.throws(()=>buildCellContext(world,c.cell_id,fp,malformed),/Malformed/);
 }
 const first=manifest.cases.find(c=>c.world===stem&&c.context==='shore'),i=world.cells.ids.indexOf(first.cell_id);
 const neighbour=world.cells.neighbors[i].find(id=>world.cells.heights[world.cells.ids.indexOf(id)]>=20);
 assert(neighbour!==undefined);
 const a=await generateCellRegion(world,first.cell_id,fp,sidecar),b=await generateCellRegion(world,neighbour,fp,sidecar);
 assert.notEqual(a.id,b.id);assert.notEqual(a.provider.seed,b.provider.seed);
 const A=a.source_context,B=b.source_context,ab=A.space.source_bounds,bb=B.space.source_bounds;
 const overlap={left:Math.max(ab.left,bb.left),top:Math.max(ab.top,bb.top),right:Math.min(ab.right,bb.right),bottom:Math.min(ab.bottom,bb.bottom)};
 assert(overlap.right>overlap.left&&overlap.bottom>overlap.top);
 const commonHexes=a.hex_overlay_v1.cells.filter(h=>b.hex_overlay_v1.cells.some(k=>h.id===k.id));assert(commonHexes.length>0);
 for(const h of commonHexes)assert.deepEqual(h.world_centre,b.hex_overlay_v1.cells.find(k=>h.id===k.id).world_centre);
 const sharedVertices=A.parent_cell.vertex_ids.filter(id=>B.parent_cell.vertex_ids.includes(id));assert(sharedVertices.length>=2);
 const points=Array.from({length:20},(_,i)=>[overlap.left+(overlap.right-overlap.left)*(i+1)/21,overlap.top+(overlap.bottom-overlap.top)*((i*7)%19+1)/21]);
 for(const p of points)assert.deepEqual(sampleLandscapeArt(world,A,fp,p),sampleLandscapeArt(world,B,fp,p));
 let routes=0,rivers=0;
 for(const [key,count] of [['source_routes','routes'],['source_rivers','rivers']])for(const line of A[key]){
  const other=B[key].find(l=>l.source_id===line.source_id);if(!other)continue;
  for(const seg of line.segments){
   const paired=other.segments.find(s=>s.source_segment===seg.source_segment);if(!paired)continue;
   const x=clipSegment(...seg.points,overlap),y=clipSegment(...paired.points,overlap);
   if(!x&&!y)continue;
   assert(x&&y);assert(x.flat().every((v,i)=>Math.abs(v-y.flat()[i])<1e-5));
   if(count==='routes')routes++;else rivers++;
  }
 }
 let features=0;
 for(const f of A.source_features){const g=B.source_features.find(g=>g.source_id===f.source_id);if(!g)continue;
  // Both views retain a common original feature identity, not invented water.
  assert.equal(f.provenance,g.provenance);features++;
 }
 assert(features>0);assert(routes+rivers>0,'nonempty source-line overlap');
 const dev={...b,export_scope:'DEVELOPER_FULL_TRUTH'};await writeFile(`${folder}/${stem}-neighbour.developer.json`,JSON.stringify(dev)+'\n');await writeFile(`${folder}/${stem}-neighbour.developer.svg`,renderRegion(dev));
 reports.push({world:stem,cells:[first.cell_id,neighbour],shared_source_vertex_ids:sharedVertices,shared_hex_ids:commonHexes.map(h=>h.id),common_hex_count:commonHexes.length,overlap_bounds:overlap,matched_route_segments:routes,matched_approximate_river_segments:rivers,shared_feature_count:features,identical_global_field_samples:20,provider_decoration_seams:'NOT_PROVEN',field_outline_seams:'NOT_PROVEN',render_grid_tessellation:'VIEW_DEPENDENT',traversability:'UNKNOWN'});
 assert.equal(hash(await readFile(`tests/worldgen/fixtures/${stem}.json`,'utf8')),fp);
}
await writeFile(folder+'/continuity.json',JSON.stringify({schema_version:1,comparisons:reports},null,2)+'\n');
console.log('PASS: GAME-62 six-case byte replay, rename stability, true polygons, dry sites, privacy, coordinates, hex identities, malformed-source rejection and two adjacent-cell overlaps');
