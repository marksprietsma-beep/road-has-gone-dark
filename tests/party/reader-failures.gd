extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(why)
func write(path: String, value: Dictionary) -> void:
 var file := FileAccess.open(path,FileAccess.WRITE)
 file.store_string(JSON.stringify(value))
 file.close()
func _initialize() -> void:
 var world := GameWorldTemplate.new()
 check(world.load_fixture("res://tests/worldgen/fixtures/game-11-determinism.json"),world.error)
 var source := WorldPeoples.directory(world)
 var original := WorldOriginLore.read_json(source.path_join("enrichment.json"))
 var descriptor := WorldOriginLore.read_json(source.path_join("descriptor.json"))
 var target := ProjectSettings.globalize_path("user://game81-reader-failures-"+Crypto.new().generate_random_bytes(8).hex_encode())
 DirAccess.make_dir_recursive_absolute(target)
 for name in ["base_type","missing_world","row_field","weight","status","people_id","culture","secret"]:
  var data := original.duplicate(true)
  var key: String=data.records.hometowns.keys()[0]
  match name:
   "base_type": data.base_world="bad"
   "missing_world": data.records.world={}
   "row_field": data.records.hometowns[key].erase("id")
   "weight": data.records.hometowns[key].peoples[0].presence_weight=1.5
   "status": data.records.hometowns[key].peoples[0].status="invented"
   "people_id": data.records.hometowns[key].peoples[0].people_id="bad"
   "culture": data.records.hometowns[key].source_culture_ids=[1.5]
   "secret": data.records.hometowns[key].hidden_truth="never expose"
  write(target.path_join("enrichment.json"),data)
  var d := descriptor.duplicate(true)
  d.enrichment_sha=FileAccess.get_sha256(target.path_join("enrichment.json"))
  write(target.path_join("descriptor.json"),d)
  var reader := WorldPeoples.new()
  check(not reader.load_world(world,target),"malformed " + name + " rejected even with recomputed file hash")
  check(reader.records.is_empty() and not reader.error.is_empty(),"controlled diagnostic and empty public projection")
 print("GAME-81 reader corruption checks: ",checks,"; failures: ",failures)
 quit(1 if failures else 0)
