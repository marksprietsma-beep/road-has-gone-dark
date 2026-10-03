#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {sourceDryLand} from "../../tools/regiongen/compose-local-region.mjs";
import {auditSourceRoutes} from "../../tools/regiongen/route-consistency.mjs";
import {generateContextualSites,contextualPlayerSiteView} from "../../tools/regiongen/contextual-sites-v2.mjs";
const sha=s=>createHash("sha256").update(s).digest("hex");
const length=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
const classes=new Set(),counts=[],visibleCounts=[],individual=[],allLayerIds=new Set();
let generated=0,knownGenerated=0,rumours=0,hidden=0,conflicts=0;
const routeTest={
 constraints:{shorelines:"original_source_features"},
 source_features:[{classification:"land_boundary",local_polygon:[[100,100],[900,100],[900,900],[100,900]]}],
 source_routes:[
  {source_id:1,classification:"land_road",segments:[{source_segment:0,local_points:[[200,200],[600,200]]}]},
  {source_id:2,classification:"land_road",segments:[{source_segment:0,local_points:[[0,300],[200,300]]}]},
  {source_id:3,classification:"sea_lane",segments:[{source_segment:0,local_points:[[300,350],[550,350]]}]},
  {source_id:4,classification:"sea_lane",segments:[{source_segment:0,local_points:[[10,10],[30,80]]}]}
 ]};
const testAudit=auditSourceRoutes(routeTest);
assert.equal(testAudit.conflicts.length,2,"Wet road and dry sea lane must both be reported");
assert.equal(testAudit.trustedApproaches.length,1,"Only the wholly dry overland route qualifies for POI siting");
assert.equal(testAudit.trustedApproaches[0].source_route_id,1);

for(const stem of ["game-11-determinism","atlas-showcase"])
 for(const kind of ["shore","river","highland"]){
  const worldBytes=await readFile("tests/worldgen/fixtures/"+stem+".json");
  const world=JSON.parse(worldBytes);
  const base=JSON.parse(await readFile("tools/regiongen/.tmp/constrained-"+stem+"-"+kind+".json","utf8"));
  const finalBytes=await readFile("tools/regiongen/.tmp/contextual-"+stem+"-"+kind+".json","utf8");
  const final=JSON.parse(finalBytes),layer=final.local_sites_v2;
  const preview=await readFile("tools/regiongen/.tmp/contextual-"+stem+"-"+kind+".svg","utf8");
  const auditPreview=await readFile("tools/regiongen/.tmp/contextual-"+stem+"-"+kind+".audit.svg","utf8");
  assert.equal(sha(worldBytes),base.source_context.parent_source_world_sha256);
  assert.equal(layer.region_id,base.id);
  assert.equal(layer.source_context_id,base.source_context.id);
  assert.equal(layer.migration.from_site_generation_v1,"NOT_AUTOMATIC");
  assert.equal(layer.migration.existing_v1_states,"UNCHANGED");
  assert.equal(layer.source_km,"UNCALIBRATED");
  const audit=auditSourceRoutes(base.source_context);
  assert.deepEqual(layer.route_consistency.conflicts,audit.conflicts);
  assert.equal(layer.route_consistency.eligible_approach_segments,audit.trustedApproaches.length);
  conflicts+=audit.conflicts.length;
  if(audit.trustedApproaches.length===0)
   assert(!layer.sites.some(s=>["farmstead","roadside_inn","watchtower","shrine"].includes(s.kind)),
    "A local service appeared despite no consistent overland segment");
  assert(layer.site_generation_version===2);
  assert(layer.sites.length>=1);
  assert.equal(layer.sites[0].id,"burg:"+base.source_context.source_home_burg_id);
  assert.equal(layer.sites[0].provenance,"azgaar_burg");
  assert.deepEqual(layer.sites[0].position,base.source_context.space.home_local);
  assert.deepEqual(layer,generateContextualSites(world,base),"v2 sites not deterministic");
  assert.deepEqual(final.local_sites_v2,layer);
  const terrain=final.inferred_fine_v1;
  assert(terrain&&terrain.schema_version===1&&
   terrain.source_context_id===base.source_context.id,
   "Inferred scenery must share the original v2 sites source context");
  assert(terrain.source_world_sha256===layer.source_world_sha256);
  assert(terrain.truth==="INFERRED_VISUAL_FIELD_NOT_TRAVERSAL");
  assert(terrain.migration==="NOT_AUTOMATIC");
  assert(terrain.claims.safe_routes==="UNKNOWN"&&terrain.claims.walkable==="UNKNOWN");
  assert(terrain.vertices.length===(terrain.grid_steps+1)**2);
  assert(preview.includes('data-provenance="inferred-only"'),
   "Normal player SVG is missing the composed inferred woodland/relief");
  assert(preview.includes('mask="url(#game53-macro-source-land)"'),
   "Source land/lakes must clip the inferred terrain layer");
  assert(!preview.includes('Town Forge vegetation only'),
   "Inferred terrain must replace the old scattered symbol presentation");
  assert(!JSON.stringify(layer).includes("PROVISIONAL_CONCEPTUAL_NOT_SOURCE_WORLD_COORDINATES"));
  const display=contextualPlayerSiteView(layer);
  const canonicalOther=base.source_context.source_burgs.filter(b=>b.source_id!==base.source_context.source_home_burg_id);
  assert(!layer.sites.some(s=>s.provenance==="azgaar_burg"&&s.kind!=="hometown"),"Extra source towns were fabricated as game sites");
  assert(new Set(layer.sites.map(s=>s.id)).size===layer.sites.length);
  assert(new Set(layer.sites.map(s=>s.label.toLowerCase())).size===layer.sites.length);
  assert.equal(display.visible.length,layer.sites.filter(s=>["discovered","visited"].includes(s.knowledge)).length);
  assert.equal(display.rumours.length,layer.sites.filter(s=>s.knowledge==="rumoured").length);
  visibleCounts.push(display.visible.length);
  assert(display.rumours.every(s=>s.hint && !s.id && !s.label && !s.position));
  assert(!preview.includes("FAKE_ROAD"));
  assert(preview.includes('id="known-game-owned-pois"'));
  assert(preview.includes("Known nearby sites"));
  assert(!preview.includes("Route/coast conflicts: "), "Developer audit leaked into ordinary map");
  assert(!preview.includes('class="source-geometry-conflict"'), "Red audit strokes leaked into ordinary map");
  assert(auditPreview.includes("Route/coast conflicts: "+audit.conflicts.length),
   "Explicit audit SVG must retain the full source inconsistency count");
  assert.equal((auditPreview.match(/class="source-geometry-conflict"/g)||[]).length,audit.conflicts.length,
   "Audit view must preserve every source conflict without hiding or inventing routes");
  assert(preview.includes("Known nearby sites: ")&&auditPreview.includes("Known nearby sites: "));
  assert.deepEqual(layer.route_consistency.conflicts,audit.conflicts,"Underlying audit evidence changed");
  for(const s of layer.sites){
   assert(s.patrol_protection==="unverified");
   assert(s.position.every(Number.isFinite));
   assert(s.kind==="hometown"||s.provenance==="game_generated_local_site");
   if(s.kind==="hometown")continue;
   assert(sourceDryLand(base.source_context,s.position),"Local site put on sea or lake");
   assert(s.position[0]>=38&&s.position[0]<=962&&s.position[1]>=115&&s.position[1]<=915);
   assert(layer.sites.filter(x=>x!==s).every(x=>length(x.position,s.position)>=57),"Site overlap");
   assert(base.source_context.source_burgs.every(b=>length(b.local_position,s.position)>=57),"Original burg collision");
   assert(!s.id.includes("site:v1"),"Unmigrated GAME-40 v1 namespace incorrectly reused");
   assert.equal(s.id,layer.source_context_id+":site:v2:"+s.kind,
    "Generated site IDs must be independent of other kinds and site ordering");
   assert(["dungeongen","local_event"].includes(s.detail_hook.provider));
   assert(!s.description.includes("protected route"));
   if(s.knowledge!=="discovered"&&s.knowledge!=="visited") {
    assert(!preview.includes(s.label),"Unseen site label leaked into player SVG: "+s.id);
    assert(!preview.includes(s.id),"Unseen site identifier leaked into player SVG");
    assert(!JSON.stringify(display).includes(s.label),"Unseen site label leaked into player view");
    assert(!JSON.stringify(display).includes(s.id),"Unseen site id leaked into player view");
    assert(!JSON.stringify(display).includes(JSON.stringify(s.position)),"Unseen coordinates leaked");
   }
   if(s.knowledge==="hidden")hidden++;
   if(s.knowledge==="rumoured")rumours++;
   if(s.knowledge==="discovered")knownGenerated++;
   generated++;
   classes.add(s.kind);
  }
  assert.throws(()=>contextualPlayerSiteView(layer,{[layer.sites[0].id]:"invalid"}));
  assert.equal(contextualPlayerSiteView(layer,{},true).visible.length,layer.sites.length);
  if(layer.sites.length>1){
   let site=layer.sites[1];
   assert(contextualPlayerSiteView(layer,{[site.id]:"visited"}).visible.some(s=>s.id===site.id&&s.knowledge==="visited"));
  }
  counts.push(layer.sites.length);
  individual.push(stem+"/"+kind+"="+layer.sites.length);
  assert(!allLayerIds.has(layer.source_context_id),"Two different home contexts share a generated region identity");
  allLayerIds.add(layer.source_context_id);
 }
assert(conflicts>0,"Actual sample worlds missed all known road/sea inconsistencies");
assert(generated>5,"Too few contextual POIs across six original neighbourhoods");
assert(knownGenerated>=2,"No discoverable nearby sites");
assert(classes.size>=3,"Insufficient variety in site types");
assert(new Set(counts).size>=2,"All worlds still have the identical fixed checklist size");
assert(new Set(visibleCounts).size>=3,"All worlds still reveal the same static discovered-site checklist");
console.log("PASS: GAME-44 six v2 contextual source worlds; "+generated+" unique generated sites, "+knownGenerated+
 " known, "+rumours+" rumours, "+hidden+" hidden, "+conflicts+" classified source-route conflicts; varieties "+[...classes].join(",")+"; by map "+individual.join(" "));
