import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {buildSharedIcons,buildEncounterDemo,renderSharedIcon,SITE_ROLES} from '../../tools/regiongen/shared-map-icons.mjs';
import {contextualPlayerSiteView} from '../../tools/regiongen/contextual-sites-v2.mjs';
import {sourceDryLand} from '../../tools/regiongen/compose-local-region.mjs';
for(const stem of ['game-11-determinism','atlas-showcase'])for(const kind of ['shore','river','highland']){
 const name=`tools/regiongen/.tmp/contextual-${stem}-${kind}`;
 const r=JSON.parse(await readFile(name+'.json','utf8')),world=JSON.parse(await readFile(`tests/worldgen/fixtures/${stem}.json`,'utf8'));
 assert.deepEqual(buildSharedIcons(world,r.source_context),r.world_icon_roles_v1);
 const visible=contextualPlayerSiteView(r.local_sites_v2).visible.filter(s=>s.kind!=='hometown');
 assert.deepEqual(buildEncounterDemo(r.source_context,r.hex_overlay_v1,visible),r.encounter_demo_v1);
 assert.equal(r.world_icon_roles_v1.marker_diameter,32);
 assert.equal(r.world_icon_roles_v1.scale.local_window_area,256);
 assert.ok(r.world_icon_roles_v1.scale.window_to_home_cell_area>1&&r.world_icon_roles_v1.scale.window_to_home_cell_area<5);
 for(const o of r.encounter_demo_v1.occupants){
  const c=r.hex_overlay_v1.cells.find(c=>String(c.axial)===String(o.axial));
  assert.deepEqual(o.position,c.centre);assert.ok(c.points.every(p=>sourceDryLand(r.source_context,p)));
 }
 const svg=await readFile(name+'.svg','utf8');assert.ok(!svg.includes('MOCK-UP, NOT LIVE'));
 assert.ok(!svg.includes('data-role="brigands"'));assert.ok(!svg.includes('data-role="hill-monsters"'));
}
for(const role of Object.values(SITE_ROLES))assert.ok(renderSharedIcon(role,[0,0]).includes('viewBox="0 0 512 512"'));
console.log('PASS: shared actual SVG assets, deterministic scale, dry hex mock-ups, no normal-view encounters');
