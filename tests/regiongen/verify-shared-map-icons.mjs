import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {buildSharedIcons,buildEncounterDemo,renderSharedIcon,SITE_ROLES,hexSourceDry,sourceRoadDistance,encounterTerrainAt} from '../../tools/regiongen/shared-map-icons.mjs';
import {contextualPlayerSiteView} from '../../tools/regiongen/contextual-sites-v2.mjs';
import {sourceDryLand} from '../../tools/regiongen/compose-local-region.mjs';
for(const stem of ['game-11-determinism','atlas-showcase'])for(const kind of ['shore','river','highland']){
 const name=`tools/regiongen/.tmp/contextual-${stem}-${kind}`;
 const r=JSON.parse(await readFile(name+'.json','utf8')),world=JSON.parse(await readFile(`tests/worldgen/fixtures/${stem}.json`,'utf8'));
 assert.deepEqual(buildSharedIcons(world,r.source_context),r.world_icon_roles_v1);
 const visible=contextualPlayerSiteView(r.local_sites_v2).visible.filter(s=>s.kind!=='hometown');
 assert.deepEqual(buildEncounterDemo(r.source_context,r.hex_overlay_v1,visible,r.landscape_presentation_v1.terrain),r.encounter_demo_v1);
 const changed=structuredClone(r.local_sites_v2);
 for(const site of changed.sites)if(['hidden','rumoured'].includes(site.knowledge)){site.position=[1,1];site.label='PRIVATE_CHANGED';}
 const changedVisible=contextualPlayerSiteView(changed).visible.filter(s=>s.kind!=='hometown');
 assert.deepEqual(buildEncounterDemo(r.source_context,r.hex_overlay_v1,changedVisible,r.landscape_presentation_v1.terrain),r.encounter_demo_v1,'Hidden POIs influenced encounter illustration');
 assert.throws(()=>buildEncounterDemo(r.source_context,r.hex_overlay_v1,visible,{...r.landscape_presentation_v1.terrain,source_context_id:'OTHER'}));
 assert.equal(r.world_icon_roles_v1.marker_diameter,32);
 assert.equal(r.world_icon_roles_v1.scale.local_window_area,256);
 assert.ok(r.world_icon_roles_v1.scale.window_to_home_cell_area>1&&r.world_icon_roles_v1.scale.window_to_home_cell_area<5);
 for(const o of r.encounter_demo_v1.occupants){
  const c=r.hex_overlay_v1.cells.find(c=>String(c.axial)===String(o.axial));
  assert.deepEqual(o.position,c.centre);assert.ok(c.points.every(p=>sourceDryLand(r.source_context,p)));
  assert.ok(hexSourceDry(r.source_context,c));
  if(o.role==='brigands')assert.ok(sourceRoadDistance(r.source_context,o.position)<=65);
  else{const v=encounterTerrainAt(r.landscape_presentation_v1.terrain,o.position);assert.ok(v.f>=.57||v.h>=69);}
  assert.ok(o.id.startsWith('mock:'));
 }
 const svg=await readFile(name+'.svg','utf8');assert.ok(!svg.includes('MOCK-UP, NOT LIVE'));
 assert.ok(!svg.includes('data-role="brigands"'));assert.ok(!svg.includes('data-role="hill-monsters"'));
 assert.ok(svg.indexOf('id="known-game-owned-pois"')>svg.indexOf('Landscape illustration</text>'),'Nested icon SVG swallowed overlay');
}
const cell={centre:[500,500],points:Array.from({length:6},(_,i)=>[500+10*Math.cos(i*Math.PI/3),500+10*Math.sin(i*Math.PI/3)])};
const dry={constraints:{shorelines:'original_source_features'},source_features:[{classification:'land_boundary',local_polygon:[[0,0],[1000,0],[1000,1000],[0,1000]]}],source_routes:[]};
assert.ok(hexSourceDry(dry,cell));
for(const lake of [[[502,502],[503,502],[503,503],[502,503]],[[503.9,490],[504,490],[504,510],[503.9,510]]]){
 const ctx={...dry,source_features:[...dry.source_features,{classification:'freshwater_lake',local_polygon:lake}]};
 assert.ok(sourceDryLand(ctx,cell.centre)&&cell.points.every(p=>sourceDryLand(ctx,p)),'Regression case must fool corner-only check');
 assert.ok(!hexSourceDry(ctx,cell),'Small lake / narrow channel accepted as wholly dry');
}
const notch={...dry,source_features:[{classification:'land_boundary',local_polygon:[[0,0],[1000,0],[1000,502],[503,502],[503,503],[1000,503],[1000,1000],[0,1000]]}]};
assert.ok(cell.points.every(p=>sourceDryLand(notch,p))&&sourceDryLand(notch,cell.centre));
assert.ok(!hexSourceDry(notch,cell),'Thin coastal inlet accepted');
const ctx={...dry,id:'test',parent_source_world_sha256:'test',source_burgs:[]};
const terrain={source_context_id:'test',source_world_sha256:'test',truth:'INFERRED_VISUAL_FIELD_NOT_TRAVERSAL',grid_steps:1,vertices:Array.from({length:4},()=>({f:.1,h:30,land:true}))};
const empty=buildEncounterDemo(ctx,{cells:[cell]},[],terrain);
assert.deepEqual(empty.occupants,[]);assert.deepEqual(empty.omitted_roles,['brigands','hill-monsters']);
for(const role of Object.values(SITE_ROLES))assert.ok(renderSharedIcon(role,[0,0]).includes('viewBox="0 0 512 512"'));
console.log('PASS: shared actual SVG assets, deterministic scale, dry hex mock-ups, no normal-view encounters');
