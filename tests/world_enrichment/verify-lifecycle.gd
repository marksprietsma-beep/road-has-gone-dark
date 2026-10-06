extends SceneTree
var checks := 0
var failures := 0
var proof: Dictionary = {"worlds": []}
var base := OS.get_environment("GAME79_TEST_ROOT")
func check(value: bool, why: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(why)
func json_write(path: String, data: Dictionary) -> void:
 var f := FileAccess.open(path, FileAccess.WRITE)
 f.store_string(JSON.stringify(data))
 f.close()
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var library := GameWorldLibrary.new()
 library.library_root = base.path_join("library")
 library.save_root = base.path_join("saves")
 var store := GamePlaythroughStore.new()
 store.save_root = library.save_root
 var replay := OS.get_environment("GAME79_PHASE") == "replay"
 if not replay:
  for n in 5:
   var source := OS.get_environment("GAME79_GENERATED_DIR").path_join("game79-world-%d/world.json" % n)
   var stage := library.create_staging()
   check(stage.ok, "staging created")
   check(DirAccess.copy_absolute(source, stage.directory.path_join("world.json")) == OK, "copy genuine generated source")
   var result := library.import_generated(stage.directory)
   check(result.ok, "world transaction includes enrichment")
   if not result.ok: continue
   check(FileAccess.get_sha256(source) == result.entry.world.source_sha256, "canonical bytes unchanged by enrichment")
 var entries := library.discover()
 check(entries.size() == 7, "two presets and five genuine generated worlds discovered")
 var total := 0
 for entry in entries:
  var world: GameWorldTemplate = entry.world
  var lore := WorldOriginLore.new()
  check(lore.load_world(world, library.enrichment_directory(entry)), "every template has validated complete origin projection")
  var count := 0
  for state in world.raw_counts().states:
   for home in world.home_candidates(state, -1, -1):
    var row := lore.public_origin(world, int(home.id))
    check(not row.is_empty() and row.burg_id == home.id and row.state_id == state and row.cell_id == home.cell_id, "all eligible towns retain source identity")
    check(not row.memory.is_empty() and not row.tradition.is_empty(), "each eligible hometown has public memory and tradition")
    count += 1
  total += count
  proof.worlds.append({"world_id": world.world_id, "sha": world.source_sha256, "origins": count, "descriptor": lore.descriptor})
  check(lore.public_origin(world, -1).is_empty(), "unknown hometown never substituted")
 var generated: Dictionary = entries.filter(func(e: Dictionary): return not e.preset)[0]
 var world: GameWorldTemplate = generated.world
 var candidates: Array[Dictionary] = []
 for state in world.raw_counts().states:
  candidates.append_array(world.home_candidates(state, -1, -1))
 var home: Dictionary = candidates[0]
 var reader := WorldOriginLore.new()
 check(reader.load_world(world, library.enrichment_directory(generated)), "selected generated lore loads")
 if not replay:
  var legacy := store.create_playthrough(world, int(home.state_id), int(home.id))
  check(legacy.ok and store.save_new("legacy", legacy.state, world).ok, "legacy unpinned save remains valid")
  var created := store.create_playthrough(world, int(home.state_id), int(home.id))
  created.state.origin_enrichment = reader.descriptor.duplicate(true)
  check(store.save_new("pinned", created.state, world).ok, "new save pins full descriptor")
  check(store.load_save("pinned", world).ok, "immediate pinned reload passes")
 else:
  check(store.load_save("legacy", world).ok, "old save loads after process restart without destructive migration")
  var restored := store.load_save("pinned", world)
  check(restored.ok and restored.state.origin.home_burg_id == home.id, "pinned save survives process restart with source IDs")
  var save_path := store.save_root.path_join("pinned.json")
  var original_save := FileAccess.get_file_as_string(save_path)
  var state: Dictionary = JSON.parse_string(original_save)
  state.origin_enrichment.enrichment_sha = "0".repeat(64)
  json_write(save_path, state)
  check(not store.load_save("pinned", world).ok and store.error.contains("mismatch"), "corrupted campaign pin fails clearly")
  check(FileAccess.file_exists(save_path), "invalid enrichment never deletes campaign")
  var f := FileAccess.open(save_path, FileAccess.WRITE)
  f.store_string(original_save)
  f.close()
  # File corruption is refused and factual discovery still exposes the template.
  var public_path := library.enrichment_directory(generated).path_join("public.json")
  var public_bytes := FileAccess.get_file_as_bytes(public_path)
  f = FileAccess.open(public_path, FileAccess.WRITE)
  f.store_string("{}")
  f.close()
  check(not reader.load_world(world, library.enrichment_directory(generated)) and reader.origins.is_empty(), "corruption clears cached lore rather than showing stale text")
  check(not store.load_save("pinned", world).ok and FileAccess.file_exists(save_path), "corrupt sidecar prevents save validation without deleting save")
  check(library.discover().size() == 7, "factual world remains discoverable when lore is corrupt")
  check(not library.ensure_enrichment(generated).ok, "corrupt existing lore is not silently regenerated")
  f = FileAccess.open(public_path, FileAccess.WRITE)
  f.store_buffer(public_bytes)
  f.close()
  check(store.load_save("pinned", world).ok, "restoring exact pinned bytes recovers campaign")
  check(not library.delete_world(generated).ok, "referenced world deletion blocked")
  check(FileAccess.file_exists(public_path) and FileAccess.file_exists(save_path), "blocked deletion preserves lore and save")
  var unused: Dictionary = entries.filter(func(e: Dictionary): return not e.preset and e.id != generated.id)[0]
  var unused_dir: String = unused.directory
  check(library.delete_world(unused).ok and not DirAccess.dir_exists_absolute(unused_dir), "unused-world deletion removes geography, preview and enrichment tree")
  # Simulate a genuine pre-enrichment GAME-76 world, not a replacement fixture.
  var legacy_entry: Dictionary = entries.filter(func(e: Dictionary): return not e.preset and e.id != generated.id and e.id != unused.id)[0]
  var legacy_path := library.enrichment_directory(legacy_entry)
  check(library._remove_flat_directory(legacy_path, true), "test removes only legacy test enrichment")
  var meta := WorldOriginLore.read_json(legacy_entry.directory.path_join("metadata.json"))
  meta.erase("origin_enrichment")
  json_write(legacy_entry.directory.path_join("metadata.json"), meta)
  check(library.discover().size() == 6, "legacy world lacking lore remains discoverable")
  var upgraded := library.ensure_enrichment(legacy_entry)
  check(upgraded.ok and upgraded.descriptor.base_world_sha == legacy_entry.world.source_sha256, "missing-only legacy upgrade preserves base identity")
  var first_sha := FileAccess.get_sha256(legacy_path.path_join("public.json"))
  check(library.ensure_enrichment(legacy_entry).ok and FileAccess.get_sha256(legacy_path.path_join("public.json")) == first_sha, "upgrade retry is deterministic and immutable")
  # Failure before commit leaves no new library entry or orphan staging tree.
  var stage := library.create_staging()
  var source := OS.get_environment("GAME79_GENERATED_DIR").path_join("game79-world-1/world.json")
  var failed_world := WorldOriginLore.read_json(source)
  failed_world.seed = "game79-injected-failure"
  json_write(stage.directory.path_join("world.json"), failed_world)
  var normal_helper := library.helper_root
  library.helper_root = base.path_join("missing-helper")
  var failed := library.import_generated(stage.directory)
  library.helper_root = normal_helper
  check(not failed.ok and not DirAccess.dir_exists_absolute(stage.directory), "missing renderer/helper fails transaction and cleans staging")
  check(library.discover().size() == 6, "failure cannot publish partial world")
 proof.checks = checks
 proof.failures = failures
 proof.eligible_hometowns = total
 proof.phase = "replay" if replay else "create"
 json_write("res://docs/implementation/game79/lifecycle-" + str(proof.phase) + ".json", proof)
 print("GAME-79 lifecycle %s: %d checks, %d failures; %d eligible hometowns" % [proof.phase, checks, failures, total])
 quit(0 if failures == 0 else 1)
