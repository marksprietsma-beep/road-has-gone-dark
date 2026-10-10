extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(why)
func _initialize() -> void: call_deferred("run")
func bytes(path: String,data: PackedByteArray) -> void:
 var file:=FileAccess.open(path,FileAccess.WRITE)
 file.store_buffer(data);file.close()
func run() -> void:
 var base:=OS.get_environment("GAME84_TEST_ROOT")
 var original:=GameWorldTemplate.new()
 check(original.load_fixture("res://tests/worldgen/fixtures/game-11-determinism.json"),"read-only canonical input")
 var owned:=base.path_join("cache-integrity")
 for pair in [[WorldOriginLore.directory(original),"origin-v1"],[OriginProfiles.directory(original),"profiles-v2"]]:
  var target:=owned.path_join(pair[1])
  DirAccess.make_dir_recursive_absolute(target)
  for name in ["descriptor.json","enrichment.json","public.json"]: check(DirAccess.copy_absolute(ProjectSettings.globalize_path(str(pair[0]).path_join(name)),target.path_join(name))==OK,"owned byte-exact sidecar copy")
 original.enrichment_directory=owned.path_join("origin-v1")
 original.profiles_directory=owned.path_join("profiles-v2")
 var profiles:=OriginProfiles.new()
 check(profiles.load_world(original),"full successful immutable validation")
 check(profiles.load_world(original) and not original._validation_cache.is_empty(),"warm immutable cache")
 var path:=original.profiles_directory.path_join("public.json")
 var descriptor_path:=original.profiles_directory.path_join("descriptor.json")
 var before:=FileAccess.get_file_as_bytes(path)
 var descriptor_before:=FileAccess.get_file_as_bytes(descriptor_path)
 var public_data:=WorldOriginLore.read_json(path)
 public_data.hometowns.values()[0].secret="THIS MUST NOT ENTER A PUBLIC ROW"
 var file:=FileAccess.open(path,FileAccess.WRITE)
 file.store_string(JSON.stringify(public_data));file.close()
 var d:=WorldOriginLore.read_json(descriptor_path)
 d.public_projection_sha=FileAccess.get_sha256(path)
 file=FileAccess.open(descriptor_path,FileAccess.WRITE)
 file.store_string(JSON.stringify(d));file.close()
 check(not profiles.load_world(original),"recomputed-hash malformed sidecar misses cache and is rejected")
 bytes(path,before);bytes(descriptor_path,descriptor_before)
 check(profiles.load_world(original),"exact restoration valid again")
 var service:=ExpeditionService.new()
 service.library.library_root=base.path_join("library")
 service.store.save_root=base.path_join("saves")
 service.cache_root=base.path_join("cache")
 var entries:=service.library.discover()
 for name in DirAccess.get_files_at(service.store.save_root):
  if not name.ends_with(".json"):continue
  var state:=WorldOriginLore.read_json(service.store.save_root.path_join(name))
  var entry: Dictionary=entries.filter(func(e: Dictionary):return e.id==state.world_ref.id)[0]
  var slot: String=state.playthrough_id
  var loaded:=service.operate(entry,slot,"resume")
  check(loaded.ok,"ready campaign resumes")
  if not loaded.ok:break
  var cache:=service.cache_root.path_join(entry.world.source_sha256).path_join(str(int(state.origin.home_burg_id))+".json")
  var cache_before:=FileAccess.get_file_as_bytes(cache)
  var pin_before:=FileAccess.get_file_as_bytes(cache+".sha")
  var packet:=WorldOriginLore.read_json(cache)
  packet.content.sites[0].name="CORRUPTED SITE"
  file=FileAccess.open(cache,FileAccess.WRITE)
  file.store_string(JSON.stringify(packet));file.close()
  file=FileAccess.open(cache+".sha",FileAccess.WRITE)
  file.store_string(FileAccess.get_sha256(cache));file.close()
  var save_before:=FileAccess.get_sha256(service.store._slot_path(slot))
  check(not service.operate(entry,slot,"resume").ok,"recomputed cache pin cannot rewrite campaign objective content")
  check(FileAccess.get_sha256(service.store._slot_path(slot))==save_before,"corrupt cache preserves campaign bytes")
  bytes(cache,cache_before);bytes(cache+".sha",pin_before)
  check(service.operate(entry,slot,"resume").ok,"restored immutable cache resumes same save")
  break
 print("GAME-84 cache integrity: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
