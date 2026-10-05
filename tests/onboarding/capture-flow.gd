extends SceneTree
var failures := 0
var checks := 0
var output := "res://docs/implementation/game74/screenshots"
func check(value: bool, why: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(why)
func _initialize() -> void:
 call_deferred("run")
func frames() -> void:
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
func capture(name: String) -> void:
 await frames()
 root.get_texture().get_image().save_png(output.path_join(name + ".png"))
func key(code: int) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.pressed = true
 root.push_input(event)
 await process_frame
 event = InputEventKey.new()
 event.keycode = code
 root.push_input(event)
 await frames()
func click(control: Control) -> void:
 await frames()
 var point := control.get_global_rect().get_center()
 var event := InputEventMouseButton.new()
 event.position = point
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = true
 root.push_input(event, true)
 event = InputEventMouseButton.new()
 event.position = point
 event.button_index = MOUSE_BUTTON_LEFT
 root.push_input(event, true)
 await frames()
func wait_scene(path: String) -> void:
 for i in 300:
  await process_frame
  if current_scene != null and current_scene.scene_file_path == path: return
 check(false, "scene transition: " + path)
func run() -> void:
 root.size = Vector2i(1280, 720)
 change_scene_to_file("res://scenes/intro/intro_sequence.tscn")
 await wait_scene("res://scenes/intro/intro_sequence.tscn")
 await create_timer(0.6).timeout
 await key(KEY_ESCAPE)
 await wait_scene("res://scenes/ui/main_menu.tscn")
 await create_timer(0.6).timeout
 await capture("01-main-menu")
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/new_game_origin.tscn")
 var ui = current_scene
 var directory := "user://game74-visual-" + Crypto.new().generate_random_bytes(8).hex_encode()
 ui.store.save_root = directory
 await capture("02-world")
 await key(KEY_DOWN)
 check(ui.world_index == 1, "keyboard world selection")
 await key(KEY_UP)
 check(ui.world_index == 0, "keyboard world return")
 await click(ui.next_button)
 check(ui.page == 1, "mouse Next region")
 await capture("03-region")
 var previous_state: int = ui.state_id
 await key(KEY_ENTER)
 await key(KEY_DOWN)
 await key(KEY_ENTER)
 check(ui.state_id != previous_state, "keyboard state popup selection")
 # Restore canonical first region for the sequential evidence.
 ui.choose_state(previous_state)
 await frames()
 await click(ui.next_button)
 check(ui.page == 2, "mouse Next hometown")
 await capture("04-hometown")
 var mouse_point: Vector2 = ui.options.get_global_rect().position + Vector2(20, 36)
 var mouse := InputEventMouseButton.new()
 mouse.position = mouse_point
 mouse.button_index = MOUSE_BUTTON_LEFT
 mouse.pressed = true
 root.push_input(mouse, true)
 mouse = InputEventMouseButton.new()
 mouse.position = mouse_point
 mouse.button_index = MOUSE_BUTTON_LEFT
 root.push_input(mouse, true)
 await frames()
 check(ui.burg_id == int(ui.candidates[1].id), "mouse selects hometown row")
 var first: int = ui.burg_id
 await key(KEY_DOWN)
 check(ui.burg_id != first, "keyboard hometown selection")
 await key(KEY_ESCAPE)
 check(ui.page == 1, "Escape returns region")
 await click(ui.next_button)
 await click(ui.next_button)
 check(ui.page == 3, "mouse confirmation")
 check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)), "no preview saves")
 await capture("05-confirm")
 await key(KEY_ENTER)
 check(ui.page == 4 and not ui.saved_slot.is_empty(), "keyboard persists origin")
 check(DirAccess.get_files_at(directory).size() == 1, "one final save")
 await capture("06-established")
 await click(ui.next_button)
 await click(ui.next_button)
 check(DirAccess.get_files_at(directory).size() == 1, "review cannot duplicate save")
 for dimensions in [Vector2i(640, 360), Vector2i(2560, 1440)]:
  root.size = dimensions
  await frames()
  check(ui.next_button.get_global_rect().end.y <= ui.size.y and ui.facts.get_global_rect().end.y <= ui.next_button.get_global_rect().position.y, "scaled layout stays within viewport")
  await capture("07-established-%dx%d" % [dimensions.x, dimensions.y])
 root.size = Vector2i(1280, 720)
 await click(ui.back_button)
 await wait_scene("res://scenes/ui/main_menu.tscn")
 await create_timer(0.6).timeout
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/new_game_origin.tscn")
 ui = current_scene
 ui.store.save_root = directory.path_join("cancelled")
 await key(KEY_ESCAPE)
 await wait_scene("res://scenes/ui/main_menu.tscn")
 check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory.path_join("cancelled"))), "cancel creates no saves")
 await create_timer(0.6).timeout
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/new_game_origin.tscn")
 ui = current_scene
 ui.choose_world(1)
 ui.page = 2
 var found := false
 for state in ui.states():
  ui.state_id = int(state.i)
  for province in ui.provinces():
   if ui.worlds[1].home_candidates(ui.state_id, int(province.i), 8).is_empty():
    ui.province_id = int(province.i)
    found = true
    break
  if found: break
 ui.show_page()
 check(found and ui.next_button.disabled, "natural empty area fallback")
 await capture("08-no-hometowns")
 for name in DirAccess.get_files_at(directory): DirAccess.remove_absolute(ProjectSettings.globalize_path(directory.path_join(name)))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
 print("GAME-74 real-render/input: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
