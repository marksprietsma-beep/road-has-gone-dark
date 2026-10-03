#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {createHash} from "node:crypto";
import {generateContextualSites,contextualPlayerSiteView} from "../../tools/regiongen/contextual-sites-v2.mjs";
import {sourceDryLand} from "../../tools/regiongen/compose-local-region.mjs";
import {buildSourceAuthority} from "../../tools/regiongen/source-authority.mjs";
import {buildInferredFineTerrain} from "../../tools/regiongen/inferred-fine-terrain.mjs";
const tmp="tools/regiongen/.tmp/";
let count=0,seen=0,masked=0;
for(const stem of ["game-11-determinism","atlas-showcase"]){
 const original=await readFile("tests/worldgen/fixtures/"+stem+".json");
 const world=JSON.parse(original),fp=createHash("sha256").update(original).digest("hex");
 for(const kind of ["shore","river","highland"]){
  const label=stem+"-"+kind;
  const region=JSON.parse(await readFile(tmp+"constrained-"+label+".json"));
  const context=region.source_context;
  const player=JSON.parse(await readFile(tmp+"unified-"+label+".json"));
  const audit=JSON.parse(await readFile(tmp+"unified-"+label+".developer.json"));
  const svg=await readFile(tmp+"unified-"+label+".svg","utf8");
  const fine=audit.inference,originalSource=audit.original,sites=audit.sites;
  assert.equal(context.space.kind,"source_neighbourhood_window");
  assert.equal(context.space.physical_km,"UNCALIBRATED");
  assert.equal(context.parent_source_world_sha256,fp);
  assert.equal(sites.source_context_id,fine.source_context_id);
  assert.equal(fine.source_context_id,originalSource.identity.source_context_id);
  assert.equal(player.source_context,sites.source_context_id);
  assert.equal(player.inferred_field_id,fine.id);
  assert.equal(player.km_scale,"UNCALIBRATED_SOURCE_UNITS");
  assert.equal(player.route_safety,"UNKNOWN");
  assert.equal(player.fine_walkable,"UNKNOWN");
  assert.equal(player.migration,"NOT_AUTOMATIC");
  assert.equal(player.role,"PLAYER_PREVIEW_NOT_GAME_SAVE");
  assert.equal(audit.role,"DEVELOPER_ONLY_UNFILTERED_NEVER_PLAYER_SAVE");
  assert.equal(sites.migration.from_site_generation_v1,"NOT_AUTOMATIC");
  assert.equal(sites.source_world_sha256,fp);
  assert.equal(sites.sites[0].id,"burg:"+context.source_home_burg_id);
  assert.deepEqual(sites.sites[0].position,context.space.home_local);
  assert.equal(originalSource.source_macro.scale,"ORIGINAL_AZGAAR_CANVAS_NOT_MICRO_EXACT");
  assert.equal(fine.reference_scale,"UNCALIBRATED");
  assert.equal(fine.truth,"INFERRED_VISUAL_FIELD_NOT_TRAVERSAL");
  assert.equal(fine.claims.validated_cross_tile_traversal,false);
  assert.equal(fine.claims.walkable,"UNKNOWN");
  assert.equal(fine.claims.bridges,"UNKNOWN");
  assert.equal(fine.migration,"NOT_AUTOMATIC");
  assert(svg.includes('data-provenance="inferred-only"'));
  assert(svg.includes('id="known-contextual-sites"'));
  assert(svg.includes("no kilometre calibration")&&!svg.includes("ASSUMED Earth-radius"),
   "Cannot label 16 Azgaar source units as 30 km");
  const localGenerated=sites.sites.filter(s=>s.provenance==="game_generated_local_site");
  assert(localGenerated.every(s=>sourceDryLand(context,s.position)),"Generated site lies outside source land or inside lake");
  const actual=world.settlements.find(b=>b?.i===sites.source_burg_id);
  assert(actual);
  assert.deepEqual(context.source_burgs.find(b=>b.source_id===actual.i).world_position,[actual.x,actual.y]);
  assert.deepEqual(sites,generateContextualSites(world,region),
   "Site IDs/selection changed when inference was generated");
  assert.deepEqual(originalSource,buildSourceAuthority(world,context,fp));
  assert.deepEqual(fine,buildInferredFineTerrain(world,context,fp));
  const expected=contextualPlayerSiteView(sites);
  assert.deepEqual(player.known_sites,expected.visible);
  assert.deepEqual(player.rumours,expected.rumours);
  assert(player.rumours.every(v=>!("id" in v)&&!("label" in v)&&!("position" in v)));
  for(const s of sites.sites){
   if(s.knowledge==="hidden"||s.knowledge==="rumoured"){
    assert(!svg.includes(s.id)&&!svg.includes(s.label),
     "Undiscovered/rumoured site details leaked into player map");
    assert(!JSON.stringify(player).includes(s.id));
    assert(!JSON.stringify(player).includes(s.label));
    assert(!JSON.stringify(player).includes(JSON.stringify(s.position)));
    masked++;
   }
  }
  seen+=player.known_sites.length;
  count++;
 }
}
assert.equal(count,6);
assert(masked>0);
assert(seen>=3);
console.log("PASS: GAME-54 six combined exact-source-window previews, inferred/known-site identity and hidden data isolation; "+seen+" visible places, "+masked+" withheld details");
