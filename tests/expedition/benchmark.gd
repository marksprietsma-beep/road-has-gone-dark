extends SceneTree
## Fresh owned cache: real immutable replay, regional illustration and resume.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var base:=OS.get_environment("GAME84_TEST_ROOT")
 var service:=ExpeditionService.new()
 service.store.save_root=base.path_join("saves")
 service.library.library_root=base.path_join("library")
 service.library.save_root=service.store.save_root
 service.cache_root=base.path_join("cold-benchmark-"+Crypto.new().generate_random_bytes(8).hex_encode())
 var rows: Array=[]
 var failed:=false
 for entry in service.library.discover():
  var states: Array=[]
  for name in DirAccess.get_files_at(service.store.save_root):
   var raw:=WorldOriginLore.read_json(service.store.save_root.path_join(name))
   if raw.get("world_ref",{}).get("id")==entry.id:states.append(raw)
  if states.is_empty():failed=true;continue
  var slot: String=states[0].playthrough_id
  var path:=service.store._slot_path(slot)
  var before:=FileAccess.get_file_as_bytes(path)
  var start:=Time.get_ticks_msec()
  var cold:=service.operate(entry,slot,"resume")
  var elapsed:=Time.get_ticks_msec()-start
  start=Time.get_ticks_msec()
  var warm:=service.operate(entry,slot,"resume")
  var cached:=Time.get_ticks_msec()-start
  var unchanged:=FileAccess.get_file_as_bytes(path)==before
  if not cold.ok or not warm.ok or not unchanged:failed=true;push_error("Benchmark failed immutable resume: "+str(cold)+str(warm))
  rows.append({"world":entry.world.seed,"world_sha":entry.world.source_sha256,"cold_replay_and_region_ms":elapsed,"warm_resume_ms":cached,"campaign_bytes_unchanged":unchanged})
  print(rows[-1])
 var file:=FileAccess.open("res://docs/implementation/game84/cold-cache-performance.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"fresh_owned_cache":true,"offline_canonical_replay":true,"worlds":rows},"  ")+"\n")
 file.close()
 quit(1 if failed else 0)
