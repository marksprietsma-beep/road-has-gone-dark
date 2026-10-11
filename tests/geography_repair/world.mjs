// One independently generated real source. No seed filtering or repair by reroll.
import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {checkGeographySidecar} from '../../tools/worldgen/geography-sidecar.mjs';
import {sourceCellPolygon,buildCellContext,isOwnedDryLand} from '../../tools/regiongen/cell-region.mjs';
import {generateCellRegion} from '../../tools/regiongen/generator-v1.mjs';
import {buildTileConstraints,sideShorelineCrossings,clipPolygon} from '../../tools/regiongen/source-projection.mjs';
import {localContent} from '../../tools/expedition/content.mjs';
import {loadWorld,eligible} from '../../tools/world_enrichment/source.mjs';
const [seed,directory,fixture]=process.argv.slice(2).filter(a=>!a.startsWith('--')),out=resolve(directory);mkdirSync(out,{recursive:true});
const path=join(out,'world.json'),geo=join(out,'geography.json'),hash=b=>createHash('sha256').update(b).digest('hex');
const started=performance.now();
let generation_seconds;
if(process.argv.includes('--validate-only')){generation_seconds=JSON.parse(readFileSync(join(out,'generation.json'))).seconds;}else{
 execFileSync(process.execPath,['tools/worldgen/offline-generate.mjs','--seed',seed,'--output',path,'--geometry-output',geo],{stdio:'inherit',timeout:150000});
 generation_seconds=(performance.now()-started)/1000;writeFileSync(join(out,'generation.json'),JSON.stringify({seed,seconds:generation_seconds})+'\n');
}
if(process.argv.includes('--generate-only'))process.exit(0);
const bytes=readFileSync(path),fingerprint=hash(bytes),w=JSON.parse(bytes),s=JSON.parse(readFileSync(geo));
if(fixture)assert.equal(fingerprint,hash(readFileSync(fixture)),'immutable preset replay');
if(seed==='game96-sandbox-review-v2')assert.equal(fingerprint,'c9eb47dacfe4560df8cdd4bb128ab578ff2997e288c79665fb2cf9ab5791cbe1');
checkGeographySidecar(w,s,fingerprint);
let neighbor_edges=0;
const rings=s.cell_vertex_ids.map(p=>new Set(p));
for(let i=0;i<w.cells.ids.length;i++){
 sourceCellPolygon(w,s,w.cells.ids[i]);
 assert(w.map.geography.some(f=>f?.i===w.cells.features[i]),'source feature reference');
 for(const id of w.cells.neighbors[i]){
  assert(Number.isSafeInteger(id)&&id>=0&&id<rings.length,'neighbor reference');
  if(id<i)continue;
  const shared=s.cell_vertex_ids[i].filter(v=>rings[id].has(v));
  assert.equal(shared.length,2,`continuous original border ${i}/${id}`);neighbor_edges++;
 }
}
const off_canvas=s.vertices.map((p,id)=>({id,p})).filter(({p})=>p[0]<0||p[1]<0||p[0]>w.map.width||p[1]>w.map.height);
const source=loadWorld(path),homes=w.settlements.filter(eligible).filter(b=>source.cell(b.cell).state>0),chosen=[];
const add=b=>{if(b&&!chosen.includes(b))chosen.push(b)};
const categories={};
const coast=b=>w.cells.terrain[b.cell]===1;
const lake=b=>[b.cell,...w.cells.neighbors[b.cell]].some(i=>w.map.geography[w.cells.features[i]]?.type==='lake');
const edge=b=>Math.min(b.x,b.y,w.map.width-b.x,w.map.height-b.y);
for(const [kind,predicate] of [['coastal',coast],['inland',b=>!coast(b)],['lake_adjacent',lake]]){const b=homes.find(predicate);if(b){add(b);categories[kind]=b.i;}}
const nearest=[...homes].sort((a,b)=>edge(a)-edge(b))[0];add(nearest);categories.nearest_map_edge={home:nearest?.i,distance:nearest?edge(nearest):null};
const biomes=new Set();for(const b of homes){if(chosen.length>=7)break;const name=source.record('biomes',w.cells.biome[b.cell])?.name;if(!biomes.has(name)){add(b);biomes.add(name);}}
assert(chosen.length>0,'eligible hometowns');
const regions=[];
for(const b of chosen){
 const r=await generateCellRegion(w,b.cell,fingerprint,s),again=await generateCellRegion(w,b.cell,fingerprint,s);
 assert.equal(JSON.stringify(r),JSON.stringify(again),'local-region deterministic replay');
 assert.deepEqual(r.source_context.parent_cell.vertex_ids,s.cell_vertex_ids[b.cell]);
 const c=localContent(source,b,r);assert(c.sites.every(site=>isOwnedDryLand(r.source_context,site.position)),'all sites owned dry land');
 assert.equal(JSON.stringify(c),JSON.stringify(localContent(source,b,again)));
 for(const f of r.source_context.source_features)assert(f.local_polygon.every(p=>p.every(n=>n>=-0.01&&n<=1000.01)),'feature clipped at projection boundary');
 regions.push({home:b.i,cell:b.cell,biome:source.record('biomes',w.cells.biome[b.cell])?.name,region_id:r.id,region_sha:hash(JSON.stringify(r)),content_sha:c.sha});
}
// Boundary cells include original off-canvas vertices; display context remains
// on-canvas while the source polygon and every ID remain unchanged.
const boundary_cells=[];
for(const item of off_canvas){const cell=s.cell_vertex_ids.findIndex(ids=>ids.includes(item.id)&&w.cells.heights[s.cell_vertex_ids.indexOf(ids)]>=20);if(cell>=0&&!boundary_cells.includes(cell))boundary_cells.push(cell);}
for(const cell of boundary_cells){const c=buildCellContext(w,cell,fingerprint,s);assert.deepEqual(c.parent_cell.world_polygon,sourceCellPolygon(w,s,cell));assert(c.space.source_bounds.bottom<=w.map.height&&c.space.source_bounds.right<=w.map.width);}
let shoreline_seams=0,lake_seams=0;
for(const type of ['island','lake']){
 const feature=w.map.geography.find(f=>f?.type===type&&f.vertices?.length>=3);if(!feature)continue;
 let found=false;
 for(let i=0;i<feature.vertices.length;i++){
  const a=s.vertices[feature.vertices[i]],b=s.vertices[feature.vertices[(i+1)%feature.vertices.length]],x=(a[0]+b[0])/2,y=(a[1]+b[1])/2;
  const tx=Math.floor(x/64),ty=Math.floor(y/64);if(tx<0||ty<0||tx+1>=Math.ceil(w.map.width/64)||ty+1>=Math.ceil(w.map.height/64))continue;
  const A=buildTileConstraints(w,tx,ty,fingerprint,s),E=buildTileConstraints(w,tx+1,ty,fingerprint,s),S=buildTileConstraints(w,tx,ty+1,fingerprint,s);
  assert.deepEqual(sideShorelineCrossings(A,'E'),sideShorelineCrossings(E,'W'));assert.deepEqual(sideShorelineCrossings(A,'S'),sideShorelineCrossings(S,'N'));
  if(A.source_shoreline.segments.some(p=>p.feature_id===feature.i)||A.source_shoreline.polygons.length){found=true;break;}
 }
 assert(found,type+' projected geography');shoreline_seams++;if(type==='lake')lake_seams++;
}
assert.equal(hash(readFileSync(path)),fingerprint,'read-only canonical source');
const report={seed,success:true,source_sha:fingerprint,geography_sha:hash(readFileSync(geo)),generation_seconds,seconds:(performance.now()-started)/1000+(process.argv.includes('--validate-only')?generation_seconds:0),cells:w.cells.ids.length,features:w.map.geography.filter(f=>f?.vertices?.length).length,map:{width:w.map.width,height:w.map.height,land_cells:w.cells.heights.filter(h=>h>=20).length,islands:w.map.geography.filter(f=>f?.type==='island').length,lakes:w.map.geography.filter(f=>f?.type==='lake').length},off_canvas,neighbor_edges,shoreline_seams,lake_seams,boundary_cells,categories,regions};
writeFileSync(join(out,'result.json'),JSON.stringify(report,null,2)+'\n');console.log('PASS '+seed+' '+regions.length+' hometowns');
