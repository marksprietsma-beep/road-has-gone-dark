import test from 'node:test';import assert from 'node:assert/strict';import {readFile} from 'node:fs/promises';import {execFileSync} from 'node:child_process';
const read=async p=>JSON.parse(await readFile('research/game71-72/evidence/'+p)),before=(await read('baseline.json')).records,after=(await read('presentation-results.json')).records;
for(const slug of ['albanes','batan','thilranlena'])test(`${slug}: selection-invariant IDs, exact fixed locations, stable complete known groups`,()=>{
 const records=after.filter(r=>r.name.startsWith(slug+'-'));assert.equal(records.length,4);for(const r of records){assert.deepEqual(r.markers,records[0].markers);assert.deepEqual(r.camera,records[0].camera);assert.equal(r.logicalZoom,records[0].logicalZoom)}
 const members=records[0].markers.flatMap(g=>g.members);assert.equal(new Set(members).size,members.length);
});
test('Actual before evidence reproduces all three selection churn defects',()=>{
 for(const slug of ['albanes','batan','thilranlena']){const r=before.filter(r=>r.name.startsWith(slug+'-'));assert(r.some(x=>JSON.stringify(x.markers)!==JSON.stringify(r[0].markers)))}
});
test('Measured native-pixel resolution corrects both integer and fractional output undersampling',()=>{
 for(const world of ['game-11-determinism','atlas-showcase'])for(const suffix of ['selected-2x','selected-125']){const a=after.find(r=>r.name===world+'-'+suffix),b=before.find(r=>r.name===world+'-'+suffix);assert.deepEqual(a.viewport,a.ratio===2?[2216,1690]:[1385,1056]);assert.equal(b.mapViewport,'(1108, 845)');assert(a.labels.some(l=>l.kind==='burg'))}
});
test('World names use real measurable font bounds and are collision controlled',()=>{
 for(const r of after.filter(r=>r.labels)){assert(r.labels.length>0);for(let i=0;i<r.labels.length;i++){const a=r.labels[i];assert(a.size/r.ratio>=12);for(const b of r.labels.slice(i+1)){const[x,y,w,h]=a.rect,[X,Y,W,H]=b.rect;assert(!(x<X+W&&x+w>X&&y<Y+H&&y+h>Y))}}}
});
test('Task scope: canonical data, accepted generators, research identity/art, main scene and saves unchanged',()=>{
 const paths=execFileSync('git',['diff','--name-only','10b8dcdfb480366e92018098923500efeb88db35'],{encoding:'utf8'}).trim().split('\n').filter(Boolean);
 const allowed=['scripts/debug/game70/town_layer.gd','scripts/debug/map_renderer/label_layer.gd','scripts/debug/map_renderer/landmark_layer.gd','scripts/debug/map_renderer/settlement_layer.gd','scripts/debug/map_renderer/screen_label_layout.gd','scripts/debug/world_fixture_renderer.gd','scripts/debug/world_region_town_flow.gd'];assert(paths.every(p=>p.startsWith('research/game71-72/')||allowed.includes(p)));
 assert.equal(execFileSync('git',['diff','10b8dcdfb480366e92018098923500efeb88db35','--','tools/regiongen','tests/worldgen/fixtures','research/game67','research/game69','research/game70','project.godot','scripts/game_world','data'],{encoding:'utf8'}),'');
});
