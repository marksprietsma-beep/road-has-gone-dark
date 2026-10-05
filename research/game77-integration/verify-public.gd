extends SceneTree
const Adapter = preload("res://research/game77/src/origin_lore.gd")
const UI = preload("res://scripts/ui/new_game_origin.gd")
const World = preload("res://scripts/game_world/game_world_template.gd")
var checks := 0
func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  push_error(message)
  quit(1)
func _initialize() -> void:
 var service := Adapter.new()
 expect(service.load_projection(UI.LORE_PATH, UI.LORE_SHA),"Pinned public projection")
 var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(UI.LORE_PATH))
 expect(data.entries.size()==3,"Explicit limited demonstration")
 for key in ["game-11-determinism","atlas-showcase"]:
  var world := World.new()
  expect(world.load_fixture("res://tests/worldgen/fixtures/"+key+".json"),"Original GameWorld template")
  var sidecar: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://research/game77-integration/data/"+key+"-enrichment.json"))
  expect(sidecar.base_world.id==world.world_id and sidecar.base_world.sha256==world.source_sha256,"Base identity unchanged")
  for record in sidecar.records:
   var burg_id := int(record.source.id)
   var town: Dictionary = world.get_record("burg",burg_id)
   expect(not town.is_empty() and not town.get("hidden",false) and not town.get("removed",false),"Real public hometown")
   expect(int(town.get("capital",0))==0 and float(town.get("population",0))>0 and float(town.population)<=5,"Existing small-town eligibility")
   expect(record.source.cell_id==town.cell and record.source.world_id==world.world_id,"Correct immutable source anchor")
   var row: Dictionary = service.get_public(world.world_id,burg_id)
   expect(row.text==record.facts.local_memory,"UI text renders stored fact, never newly invented prose")
   expect(row.enrichment_sha==sidecar.enrichment_sha,"Pinned enrichment reference")
   expect(not row.has("secret") and not row.has("rumours") and not row.has("context"),"Public allowlist only")
 expect(service.get_public("other-world",771).is_empty(),"No cross-world story")
 expect(service.get_public(str(data.entries[0].world_id),645).is_empty(),"Missing demo lore is empty")
 expect(not service.load_projection(UI.LORE_PATH,"0".repeat(64)),"Reject bad digest")
 expect(service.get_public(str(data.entries[0].world_id),771).is_empty(),"Failure clears stale lore")
 print("PASS: GAME-77 integration public adapter %d checks" % checks)
 quit(0)
