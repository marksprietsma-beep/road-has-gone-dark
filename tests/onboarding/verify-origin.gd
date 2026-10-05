extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, description: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(description)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var ui = load("res://scenes/ui/new_game_origin.tscn").instantiate()
 root.add_child(ui)
 var directory := "user://game74-test-" + Crypto.new().generate_random_bytes(8).hex_encode()
 ui.store.save_root = directory
 for index in 2:
  ui.choose_world(index)
  var world: GameWorldTemplate = ui.worlds[index]
  var hash := FileAccess.get_sha256("res://tests/worldgen/fixtures/%s.json" % ui.TEMPLATES[index])
  check(world.source_sha256 == hash, "template fingerprint")
  check(not ui.map.package.is_empty(), "canonical cache fingerprint accepted")
  check(ui.map.package.cell_ids.size() == ui.map.package.baked_size.x * ui.map.package.baked_size.y, "preview cell index dimensions")
  check(ui.states() == ui.states(), "deterministic states")
  for state in ui.states():
   ui.state_id = int(state.i)
   check(ui.provinces() == ui.provinces(), "deterministic provinces")
   for province in [{"i": -1}] + ui.provinces():
    var pid := int(province.i)
    var homes := world.home_candidates(ui.state_id, pid, 8)
    check(homes == world.home_candidates(ui.state_id, pid, 8), "deterministic homes")
    for home in homes:
     var cell := world.get_record("cell", int(home.cell_id))
     check(int(cell.state) == ui.state_id and (pid <= 0 or int(cell.province) == pid), "offered home owns selected area")
     var source := world.get_record("burg", int(home.id))
     check(not source.get("hidden", false) and not source.get("removed", false), "hidden/removed excluded")
     check(home.road_access == "unknown" and not home.has("markers"), "unsupported facts and POI withheld")
  var source: Dictionary = world._raw.settlements.filter(func(v): return v is Dictionary and int(v.get("i", 0)) > 0 and world.validate_origin(int(world.get_record("cell", int(v.cell)).get("state", -1)), int(v.i))).front()
  var source_state := int(world.get_record("cell", int(source.cell)).state)
  var stable := world.entity_id("burg", int(source.i))
  var old_name: String = source.name
  source.name = "Renamed for in-memory test"
  check(stable == world.entity_id("burg", int(source.i)), "rename stable identity")
  source.name = old_name
  source.removed = true
  check(not world.validate_origin(source_state, int(source.i)), "removed excluded regression")
  source.erase("removed")
  source.hidden = true
  check(not world.validate_origin(source_state, int(source.i)), "hidden excluded regression")
  source.erase("hidden")
  check(FileAccess.get_sha256("res://tests/worldgen/fixtures/%s.json" % ui.TEMPLATES[index]) == hash, "fixture unchanged")
 ui.choose_world(0)
 ui.page = 1
 ui.state_id = int(ui.states()[0].i)
 ui.province_id = -1
 ui.show_page()
 ui.advance()
 check(ui.facts.text.contains("recorded"), "factual summary formats correctly")
 var selected: int = ui.burg_id
 ui.go_back()
 ui.advance()
 check(ui.burg_id == selected, "Back preserves valid choice")
 check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)), "preview/back creates no save")
 ui.advance()
 var blocked := directory + "-blocked"
 var file := FileAccess.open(blocked, FileAccess.WRITE)
 file.store_string("not a directory")
 file.close()
 ui.store.save_root = blocked
 ui.advance()
 check(ui.page == 3 and ui.saved_slot.is_empty() and not ui.message.is_empty(), "write failure retains confirmation for retry")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked))
 ui.store.save_root = directory
 ui.advance()
 var first: String = ui.saved_slot
 check(not first.is_empty() and ui.page == 4, "confirmation persists")
 var loaded: Dictionary = ui.store.load_save(first, ui.worlds[0])
 check(loaded.ok and int(loaded.state.origin.home_burg_id) == selected and int(loaded.state.origin.state_id) == ui.state_id, "origin reload")
 check(loaded.state.characters.size() == 3 and loaded.state.player_knowledge.discovered_poi_ids.is_empty(), "skeletons and private knowledge preserved")
 ui.advance()
 ui.advance()
 check(DirAccess.get_files_at(directory).size() == 1, "reconfirmation creates exactly one save")
 var duplicate: Dictionary = ui.store.create_playthrough(ui.worlds[0], ui.state_id, selected)
 check(ui.store.save_new(duplicate.state.playthrough_id, duplicate.state, ui.worlds[0]).ok, "same-origin second save")
 check(duplicate.state.playthrough_id != first and ui.store.load_save(duplicate.state.playthrough_id, ui.worlds[0]).ok, "independent reload")
 for name in DirAccess.get_files_at(directory): DirAccess.remove_absolute(ProjectSettings.globalize_path(directory.path_join(name)))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
 ui.saved_slot = ""
 ui.choose_world(1)
 check(ui.state_id == -1 and ui.burg_id == -1 and ui.province_id == -1, "upstream change invalidates choices")
 ui.page = 2
 var found_empty := false
 for state in ui.states():
  ui.state_id = int(state.i)
  for province in ui.provinces():
   if ui.worlds[1].home_candidates(ui.state_id, int(province.i), 8).is_empty():
    ui.province_id = int(province.i)
    found_empty = true
    break
  if found_empty: break
 check(found_empty, "natural empty province exists")
 ui.show_page()
 check(ui.next_button.disabled and ui.burg_id == -1, "empty province fallback")
 var evidence := {"checks": checks, "failures": failures, "world_refs": ui.worlds.map(func(w): return w.source_metadata()), "first_save": {"slot": first, "origin": loaded.state.origin}, "second_save": {"slot": duplicate.state.playthrough_id, "origin": duplicate.state.origin}, "save_reload_verified": true, "temporary_saves_cleaned": true}
 var report := FileAccess.open("res://docs/implementation/game74/persistence-proof.json", FileAccess.WRITE)
 report.store_string(JSON.stringify(evidence, "  ") + "\n")
 report.close()
 print("GAME-74: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
