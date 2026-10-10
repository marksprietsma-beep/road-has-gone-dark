extends SceneTree
var failures := 0
var checks := 0
var output := "res://docs/implementation/game76/screenshots"
func check(value: bool, description: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(description)
func _initialize() -> void:
 call_deferred("run")
func frames() -> void:
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
func capture(name: String) -> void:
 await frames()
 root.get_texture().get_image().save_png(output.path_join(name + ".png"))
func click(control: Control) -> void:
 await frames()
 var position := control.get_global_rect().get_center()
 for down in [true, false]:
  var event := InputEventMouseButton.new()
  event.position = position
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = down
  root.push_input(event, true)
 await frames()
func key(code: int) -> void:
 for down in [true, false]:
  var event := InputEventKey.new()
  event.keycode = code
  event.pressed = down
  root.push_input(event)
  await process_frame
 await frames()
func wait_scene(path: String) -> void:
 for i in 300:
  await process_frame
  if current_scene != null and current_scene.scene_file_path == path: return
 check(false, "scene transition: " + path)
func wait_job(ui: Control) -> void:
 var start := Time.get_ticks_msec()
 var iterations := 0
 while ui.job_thread != null and Time.get_ticks_msec() - start < 180000:
  await create_timer(0.1).timeout
  iterations += 1
 check(ui.job_thread == null and iterations > 3, "background job finishes while main UI keeps processing")
func configure(ui: Control, directory: String, selected: String = "") -> void:
 ui.library.library_root = directory.path_join("worlds")
 ui.store.save_root = directory.path_join("saves")
 ui.library.save_root = ui.store.save_root
 ui._reload_library(selected)
 ui.show_page()
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 root.size = Vector2i(1280, 720)
 change_scene_to_file("res://scenes/ui/main_menu.tscn")
 await wait_scene("res://scenes/ui/main_menu.tscn")
 await create_timer(0.6).timeout
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/new_game_origin.tscn")
 var ui = current_scene
 # Keep this origin regression at its persistence boundary; GAME-81
 # capture-flow exercises the real default party scene routing.
 ui.party_creation_requested.disconnect(ui._open_party)
 var directory := "user://game76-ui-test-" + Crypto.new().generate_random_bytes(8).hex_encode()
 configure(ui, directory)
 check(ui.entries.size() == 2 and ui.deletion_button.disabled, "preset worlds visible and deletion disabled")
 await capture("01-world-library")
 ui.generation_button.grab_focus()
 await capture("02-generate-action")
 await click(ui.generation_button)
 var first_job: Thread = ui.job_thread
 ui._start_generation()
 check(ui.job_thread == first_job and ui.back_button.disabled and ui.next_button.disabled, "duplicate job and conflicting actions blocked")
 await key(KEY_ESCAPE)
 check(ui.page == 0 and ui.job_thread != null, "Escape cannot abandon active generation")
 await capture("03-generating")
 await wait_job(ui)
 check(ui.entries.size() == 3 and not ui.entries[ui.world_index].preset, "genuine generated world registered and selected")
 var first: Dictionary = ui.entries[ui.world_index]
 check(first.world.seed.begins_with("world-") and first.world.source_sha256 != ui.worlds[0].source_sha256, "fresh persisted seed and genuinely different source world")
 await capture("04-generated-library")
 ui.next_button.grab_focus()
 await capture("05-generated-preview")
 await click(ui.deletion_button)
 check(not ui.delete_target.is_empty() and ui.next_button.text == "Delete world", "explicit exact-world delete confirmation")
 await capture("06-delete-confirmation")
 await click(ui.back_button)
 check(ui.delete_target.is_empty() and ui.entries.size() == 3, "delete cancellation preserves world")
 await click(ui.deletion_button)
 await click(ui.next_button)
 check(ui.entries.size() == 2 and not FileAccess.file_exists(first.path), "unused generated world and cache deleted")
 await capture("07-world-deleted")
 await click(ui.generation_button)
 await wait_job(ui)
 var second: Dictionary = ui.entries[ui.world_index]
 check(ui.entries.size() == 3 and second.id != first.id, "second genuine generated world")
 await click(ui.next_button)
 check(ui.page == 1, "generated world enters accepted region flow")
 var searches := 0
 while ui.worlds[ui.world_index].home_candidates(ui.state_id, -1).is_empty() and searches < ui.state_picker.item_count:
  await key(KEY_DOWN)
  searches += 1
 await capture("09-generated-region")
 await click(ui.next_button)
 check(ui.page == 1 and ui.area_view == "region", "explicit region choice for generated world")
 await click(ui.next_button)
 check(ui.page == 2 and ui.burg_id > 0, "eligible real hometowns from generated source")
 await capture("10-generated-hometown")
 await click(ui.next_button)
 await key(KEY_ENTER)
 check(ui.page == 4 and not ui.saved_slot.is_empty(), "generated-world origin persisted and reload validated")
 var saved_slot: String = ui.saved_slot
 check(ui.store.load_save(saved_slot, second.world).ok, "generated-world playthrough reload proof")
 await click(ui.back_button)
 await wait_scene("res://scenes/ui/main_menu.tscn")
 await create_timer(0.6).timeout
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/new_game_origin.tscn")
 ui = current_scene
 # Keep this origin regression at its persistence boundary; GAME-81
 # capture-flow exercises the real default party scene routing.
 ui.party_creation_requested.disconnect(ui._open_party)
 configure(ui, directory, second.id)
 check(ui.entries.size() == 3 and ui.entries[ui.world_index].id == second.id, "new onboarding instance retains generated template")
 await click(ui.deletion_button)
 check(ui.delete_target.is_empty() and ui.message.contains("used by 1 saved game") and FileAccess.file_exists(second.path), "dependent save blocks deletion without confirmation")
 await capture("08-deletion-blocked")
 # Missing helper fails cleanly: no system Node fallback and no partial world.
 var helper: String = ui.library.helper_root
 ui.library.helper_root = ProjectSettings.globalize_path(directory.path_join("missing-helper"))
 await click(ui.generation_button)
 while ui.job_thread != null: await process_frame
 check(ui.entries.size() == 3 and ui.job_thread == null and not ui.next_button.disabled and not ui.back_button.disabled and ui.message.contains("unavailable") and ui.message.contains("bootstrap"), "missing helper fails preflight, restores UI and registers no partial world")
 ui.library.helper_root = helper
 var partial := false
 for name in DirAccess.get_directories_at(ui.library.library_root):
  if name.begins_with(".pending-"): partial = true
 check(not partial, "failed generator staging cleaned")
 var report := {"checks": checks, "failures": failures, "deleted_world": first.world.source_metadata(),
  "persisted_world": second.world.source_metadata(), "persisted_slot": saved_slot,
  "actual_helper_generation": true, "runtime": "Godot 4.6.3", "resolution": "1280x720"}
 var file := FileAccess.open("res://docs/implementation/game76/ui-proof.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(report, "  ") + "\n")
 file.close()
 for name in DirAccess.get_files_at(ui.store.save_root): DirAccess.remove_absolute(ProjectSettings.globalize_path(ui.store.save_root.path_join(name)))
 check(ui.library.delete_world(second).ok, "test-only cleanup after removing its own save")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(ui.store.save_root))
 for name in DirAccess.get_files_at(ui.library.library_root): DirAccess.remove_absolute(ui.library._root().path_join(name))
 DirAccess.remove_absolute(ui.library._root())
 DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
 report.checks = checks
 report.failures = failures
 file = FileAccess.open("res://docs/implementation/game76/ui-proof.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(report, "  ") + "\n")
 file.close()
 print("GAME-76 real Godot library/input/render: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
