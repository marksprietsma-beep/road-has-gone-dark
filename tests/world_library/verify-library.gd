extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func write_bytes(path: String, bytes: PackedByteArray) -> void:
 var file := FileAccess.open(path, FileAccess.WRITE)
 file.store_buffer(bytes)
 file.close()
func stage_world(library: GameWorldLibrary, source: String) -> String:
 var stage := library.create_staging()
 check(stage.ok, "create owned stage")
 write_bytes(stage.directory.path_join("world.json"), FileAccess.get_file_as_bytes(source))
 return stage.directory
func origin(world: GameWorldTemplate) -> Dictionary:
 for id in world.raw_counts().states:
  var homes := world.home_candidates(id)
  if not homes.is_empty(): return {"state": id, "home": int(homes[0].id)}
 return {}
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var generated := OS.get_environment("GAME76_GENERATED_TEST_DIR")
 if generated.is_empty(): generated = ProjectSettings.globalize_path("res://tools/worldgen/.tmp/game76-generated")
 var root_path := "user://game76-library-test-" + Crypto.new().generate_random_bytes(8).hex_encode()
 var library := GameWorldLibrary.new()
 library.library_root = root_path.path_join("worlds")
 library.save_root = root_path.path_join("saves")
 check(library.discover().size() == 2, "two immutable presets")
 check(not library.delete_world(library.discover()[0]).ok, "preset cannot be deleted")
 var empty_stage := library.create_staging()
 check(library.discover().size() == 2, "live incomplete generation not registered")
 write_bytes(empty_stage.directory.path_join("world.json"), "{}".to_utf8_buffer())
 check(not library.import_generated(empty_stage.directory).ok, "invalid canonical import fails")
 check(not DirAccess.dir_exists_absolute(empty_stage.directory), "failed import removes staging")
 var source_a := generated.path_join("game76-library-a-0/world.json")
 var source_b := generated.path_join("game76-library-b-0/world.json")
 var imported := library.import_generated(stage_world(library, source_a))
 check(imported.ok and not imported.entry.preset, "real generated world imported")
 var a: Dictionary = imported.entry
 check(a.world.source_sha256 == FileAccess.get_sha256(source_a), "canonical generated identity retained")
 check(library.preview_valid(a.directory, a.world.source_sha256), "renderer preview built and reloadable")
 var restart := GameWorldLibrary.new()
 restart.library_root = library.library_root
 restart.save_root = library.save_root
 check(restart.discover().size() == 3 and restart.discover()[2].id == a.id, "new library instance discovers persistent world")
 check(not origin(a.world).is_empty(), "real state/home candidates")
 var duplicate := library.import_generated(stage_world(library, source_a))
 check(duplicate.ok and duplicate.deduplicated and library.discover().size() == 3, "same canonical identity deduplicated")
 var preset_duplicate := library.import_generated(stage_world(library, ProjectSettings.globalize_path("res://tests/worldgen/fixtures/game-11-determinism.json")))
 check(preset_duplicate.ok and preset_duplicate.entry.preset and library.discover().size() == 3, "preset identity never duplicated into generated entries")
 var meta := library._json(a.directory.path_join("metadata.json"))
 meta.label = "My local label"
 meta.created = "2000-01-01T00:00:00"
 library._write_json(a.directory.path_join("metadata.json"), meta)
 check(library.discover()[2].id == a.id and library.discover()[2].label == "My local label", "label/date independent of identity")
 DirAccess.remove_absolute(a.directory.path_join("preview.cells"))
 check(restart.discover()[2].id == a.id and not restart.discover()[2].cache_ok, "missing derived cache does not lose world")
 check(library.build_preview(a.directory, a.raw, a.world.source_sha256), "cache rebuilt from same canonical data")
 write_bytes(a.directory.path_join("preview.cells"), "corrupt".to_utf8_buffer())
 check(not library.preview_valid(a.directory, a.world.source_sha256), "corrupt cache rejected by fingerprint")
 check(library.build_preview(a.directory, a.raw, a.world.source_sha256), "corrupt cache rebuild succeeds")
 var broken_meta := meta.duplicate(true)
 broken_meta.world_ref.sha256 = "0".repeat(64)
 library._write_json(a.directory.path_join("metadata.json"), broken_meta)
 check(library.discover().size() == 2 and not library.delete_world(a).ok, "corrupt metadata excluded and not destructively repaired")
 library._write_json(a.directory.path_join("metadata.json"), meta)
 var b_result := library.import_generated(stage_world(library, source_b))
 check(b_result.ok and b_result.entry.id != a.id, "second source-backed seed distinct")
 var b: Dictionary = b_result.entry
 var ready := library.create_staging()
 for name in ["world.json", "metadata.json", "preview.png", "preview.cells", "preview.meta.json"]:
  write_bytes(ready.directory.path_join(name), FileAccess.get_file_as_bytes(b.directory.path_join(name)))
 var enrichment := ready.directory.path_join("enrichment/origin-v1")
 DirAccess.make_dir_recursive_absolute(enrichment)
 for name in ["descriptor.json", "enrichment.json", "public.json"]:
  write_bytes(enrichment.path_join(name), FileAccess.get_file_as_bytes(b.directory.path_join("enrichment/origin-v1").path_join(name)))
 library._write_json(ready.directory.path_join("owner.json"), {"pid": 2147483647})
 check(library.delete_world(b).ok and not DirAccess.dir_exists_absolute(b.directory), "unreferenced world/cache removed")
 check(FileAccess.get_sha256(a.path) == a.world.source_sha256, "unrelated world intact")
 check(restart.discover().size() == 4 and FileAccess.file_exists(b.path), "completed staging recovered after crash")
 check(library.delete_world(b).ok and restart.discover().size() == 3, "deletion persists through restart")
 var store := GamePlaythroughStore.new()
 store.save_root = library.save_root
 var home := origin(a.world)
 var first := store.create_playthrough(a.world, home.state, home.home)
 var second := store.create_playthrough(a.world, home.state, home.home)
 check(first.ok and second.ok and first.state.playthrough_id != second.state.playthrough_id, "same-world independent playthrough IDs")
 check(first.state.world_ref == second.state.world_ref, "playthroughs share immutable world reference")
 first.state.world_deltas["test-only"] = {"changed": true}
 check(store.save_new(first.state.playthrough_id, first.state, a.world).ok, "first generated-world save")
 check(library.reference_status(a).count == 1 and not library.delete_world(a).ok, "one dependent save blocks deletion")
 check(store.save_new(second.state.playthrough_id, second.state, a.world).ok, "second generated-world save")
 check(restart.reference_status(a).count == 2 and not restart.delete_world(a).ok, "two dependent saves block deletion after restart")
 check(store.load_save(first.state.playthrough_id, a.world).ok and store.load_save(second.state.playthrough_id, a.world).state.world_deltas.is_empty(), "independent mutable state survives reload")
 check(FileAccess.get_sha256(a.path) == a.world.source_sha256, "mutable saves never alter canonical template")
 check(first.state.player_knowledge.discovered_poi_ids.is_empty() and first.state.player_knowledge.rumoured_poi_ids.is_empty(), "objective hidden POIs not exposed")
 var backup := ProjectSettings.globalize_path(store.save_root.path_join(first.state.playthrough_id + ".json.bak"))
 write_bytes(backup, FileAccess.get_file_as_bytes(store.save_root.path_join(first.state.playthrough_id + ".json")))
 check(library.reference_status(a).count == 2, "backup counted without duplicating same campaign")
 DirAccess.remove_absolute(backup)
 b = library.import_generated(stage_world(library, source_b)).entry
 var corrupt := ProjectSettings.globalize_path(store.save_root.path_join("unknown.json"))
 for value in ["not JSON", JSON.stringify({"save_version":1,"world_ref":[]}), JSON.stringify({"save_version":1,"world_ref":{"generator":[]}})]:
  write_bytes(corrupt, value.to_utf8_buffer())
  check(not library.delete_world(b).ok and FileAccess.file_exists(b.path), "ambiguous save blocks deletion of even unrelated world")
 DirAccess.remove_absolute(corrupt)
 var hidden := ProjectSettings.globalize_path(store.save_root.path_join(".unknown.json"))
 write_bytes(hidden, "broken header".to_utf8_buffer())
 check(not library.delete_world(b).ok and FileAccess.file_exists(b.path), "hidden ambiguous save header also blocks deletion")
 DirAccess.remove_absolute(hidden)
 var temporary := ProjectSettings.globalize_path(store.save_root.path_join("interrupted.json.tmp"))
 var third := store.create_playthrough(b.world, origin(b.world).state, origin(b.world).home)
 write_bytes(temporary, JSON.stringify(third.state).to_utf8_buffer())
 check(library.reference_status(b).count == 1 and not library.delete_world(b).ok, "interrupted save's reference blocks deletion")
 DirAccess.remove_absolute(temporary)
 check(library.reference_status(b).count == 0, "unrelated valid saves do not block deletion")
 check(library._acquire_lock(), "single writer lock acquired")
 check(not library.delete_world(b).ok and FileAccess.file_exists(b.path), "failed/busy delete leaves valid world")
 check(not library.begin_origin(b).ok, "concurrent generated-world origin write blocked")
 library._release_lock()
 var guard := library.begin_origin(b)
 check(guard.ok and guard.locked, "origin guard validates world presence under same lock")
 library.end_origin(guard)
 check(store.save_new(third.state.playthrough_id, third.state, b.world).ok, "save added after earlier zero-reference check")
 check(not library.delete_world(b).ok, "delete rechecks dependencies at commit time")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_root.path_join(third.state.playthrough_id + ".json")))
 # Interrupted deletion must restore a world if references now exist.
 var a_trash := library._root().path_join(".trash-" + a.world.source_sha256 + "-restore")
 check(DirAccess.rename_absolute(a.directory, a_trash) == OK, "simulate interrupted referenced deletion")
 check(restart.discover().any(func(e: Dictionary): return e.id == a.id) and FileAccess.file_exists(a.path), "recovery restores referenced world instead of purging")
 # Unreferenced trash is recoverably purged, even if first removal was blocked.
 var b_trash := library._root().path_join(".trash-" + b.world.source_sha256 + "-cleanup")
 DirAccess.rename_absolute(b.directory, b_trash)
 DirAccess.make_dir_absolute(b_trash.path_join("hold"))
 check(restart.discover().size() == 3 and DirAccess.dir_exists_absolute(b_trash), "failed trash cleanup stays excluded and recoverable")
 DirAccess.remove_absolute(b_trash.path_join("hold"))
 check(restart.discover().size() == 3 and not DirAccess.dir_exists_absolute(b_trash), "restart finishes interrupted deletion")
 var stale := library.create_staging()
 library._write_json(stale.directory.path_join("owner.json"), {"pid":2147483647})
 restart.discover()
 check(not DirAccess.dir_exists_absolute(stale.directory), "abandoned incomplete stage removed safely")
 check(DirAccess.get_files_at(store.save_root).size() == 2, "no cascade save deletion")
 for name in DirAccess.get_files_at(store.save_root): DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_root.path_join(name)))
 check(library.delete_world(a).ok and restart.discover().size() == 2, "world deletable only after test saves removed")
 var report := {"checks": checks, "failures": failures, "world_a": a.id, "world_b": b.id,
  "two_independent_saves": [first.state.playthrough_id, second.state.playthrough_id], "canonical_templates_unchanged": true}
 var file := FileAccess.open("res://docs/implementation/game76/library-proof.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  ") + "\n")
 file.close()
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_root))
 for name in DirAccess.get_files_at(library.library_root): DirAccess.remove_absolute(library._root().path_join(name))
 DirAccess.remove_absolute(library._root())
 DirAccess.remove_absolute(ProjectSettings.globalize_path(root_path))
 print("GAME-76 library lifecycle: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
