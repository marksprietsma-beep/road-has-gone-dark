extends SceneTree
var checks := 0
var failures := 0
var evidence: Array = []
var output := "res://docs/implementation/game79/screenshots"
func check(value: bool, why: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(why)
func _initialize() -> void:
 call_deferred("run")
func frames() -> void:
 for n in 5: await process_frame
 await RenderingServer.frame_post_draw
func key(code: int) -> void:
 for down in [true, false]:
  var e := InputEventKey.new()
  e.keycode = code
  e.pressed = down
  root.push_input(e)
  await process_frame
 await frames()
func click(control: Control, point: Vector2 = Vector2(-1,-1)) -> void:
 await frames()
 for down in [true, false]:
  var e := InputEventMouseButton.new()
  e.button_index = MOUSE_BUTTON_LEFT
  e.position = control.get_global_rect().get_center() if point.x < 0 else point
  e.pressed = down
  root.push_input(e, true)
 await frames()
func save_image(ui: Control, name: String) -> void:
 await frames()
 check(ui.next_button.get_global_rect().end.y <= root.get_visible_rect().size.y - 8, "footer inside viewport: " + name)
 check(ui.map.size.y >= 146, "map remains readable: " + name)
 check(ui.lore_scroll.get_global_rect().end.y < ui.next_button.get_global_rect().position.y, "lore above controls")
 check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "actual Godot screenshot saved")
 evidence.append({"image": name + ".png", "world_id": ui.worlds[ui.world_index].world_id, "burg_id": ui.burg_id, "page": ui.page, "lore": ui.lore_label.text, "resolution": [root.size.x, root.size.y]})
func verify_alignment(ui: Control) -> void:
 var world: GameWorldTemplate = ui.worlds[ui.world_index]
 var row: Dictionary = ui._lore().public_origin(world, ui.burg_id)
 var home := world.get_record("burg", ui.burg_id)
 check(not row.is_empty() and row.burg_id == ui.burg_id and row.cell_id == home.cell, "lore matches source")
 check(ui.lore_label.text.contains("Local memory: " + str(row.memory)), "comparison retains stored hometown memory")
 check(ui.lore_label.text.begins_with(ui._profiles().public_profile("hometowns", str(ui.burg_id)).full_summary), "profile identity is primary")
 check(ui.facts.text == ui._origin_context().hometown_summary(ui.burg_id).summary, "factual summary changes with lore")
 check(ui.map.burg == Vector2(float(home.x), float(home.y)), "map highlights matching source coordinates")
func wait_scene(path: String) -> void:
 for n in 300:
  await process_frame
  if current_scene != null and current_scene.scene_file_path == path: return
 check(false, "scene transition: " + path)
 quit(1)

func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 root.size = Vector2i(1280,720)
 change_scene_to_file("res://scenes/ui/main_menu.tscn")
 await wait_scene("res://scenes/ui/main_menu.tscn")
 await create_timer(0.6).timeout
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/new_game_origin.tscn")
 var ui = current_scene
 check(ui.scene_file_path == "res://scenes/ui/new_game_origin.tscn", "main-menu New Game enters onboarding")
 ui.library.library_root = OS.get_environment("GAME79_TEST_ROOT").path_join("library")
 ui.store.save_root = OS.get_environment("GAME79_TEST_ROOT").path_join("visual-saves-" + Crypto.new().generate_random_bytes(8).hex_encode())
 ui.library.save_root = ui.store.save_root
 ui._reload_library()
 ui.show_page()
 var chosen: Array[Dictionary] = []
 for wi in [0,1,2]:
  ui.choose_world(wi)
  var count := 0
  for state in ui.states():
   for home in ui.worlds[wi].home_candidates(int(state.i), -1, 8):
    chosen.append({"world": wi, "state": int(state.i), "burg": int(home.id)})
    count += 1
    if count >= (10 if wi < 2 else 2): break
   if count >= (10 if wi < 2 else 2): break
 check(chosen.size() >= 22, "twenty preset towns and two generated towns available")
 for dimensions in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size = dimensions
  for n in chosen.size():
   var choice: Dictionary = chosen[n]
   ui.choose_world(choice.world)
   ui.page = 1
   ui.choose_state(choice.state)
   ui.choose_province(-1)
   ui.show_page()
   await click(ui.next_button)
   var index := -1
   for i in ui.candidates.size():
    if ui.candidates[i].id == choice.burg: index = i
   check(index >= 0, "actual offered hometown")
   ui.options.grab_focus()
   var current := int(ui.options.get_selected_items()[0])
   for i in absi(index - current): await key(KEY_DOWN if index > current else KEY_UP)
   check(ui.burg_id == choice.burg, "keyboard selects real hometown")
   verify_alignment(ui)
   if n == 0 and ui.candidates.size() > 1:
    await click(ui.options, ui.options.get_global_rect().position + ui.options.get_item_rect(1).get_center())
    check(ui.burg_id == ui.candidates[1].id, "mouse selects hometown and updates lore")
    await key(KEY_UP)
    verify_alignment(ui)
    var focused: Control = root.gui_get_focus_owner()
    await key(KEY_TAB)
    check(root.gui_get_focus_owner() != focused, "Tab advances keyboard focus")
    ui.options.grab_focus()
   for i in [0,mini(1,ui.candidates.size()-1),mini(2,ui.candidates.size()-1),index]:
    ui.choose_home(i)
    verify_alignment(ui)
   await frames()
   check(ui.next_button.get_global_rect().end.y <= root.get_visible_rect().size.y - 8, "rapid selection never overflows footer")
   if n in [0,1,20] and dimensions in [Vector2i(640,360),Vector2i(1280,720)]:
    await save_image(ui, "hometown-%d-%dx%d" % [n,dimensions.x,dimensions.y])
  await click(ui.next_button)
  check(ui.page == 3, "mouse Next enters confirmation")
  await save_image(ui, "confirmation-%dx%d" % [dimensions.x, dimensions.y])
  var same_lore: String = ui.lore_label.text
  if dimensions == Vector2i(2560,1440):
   await key(KEY_ENTER)
   check(ui.page == 4 and not ui.saved_slot.is_empty(), "keyboard confirms validated persistent origin")
   check(ui.store.load_save(ui.saved_slot,ui.worlds[ui.world_index]).ok, "pinned origin reloads through GAME-7")
   check(ui.lore_label.text == same_lore, "handoff preserves stored lore")
   await save_image(ui,"origin-established")
   await click(ui.next_button)
   check(ui.page == 3 and ui.lore_label.text == same_lore, "Review Origin preserves lore")
   check(DirAccess.get_files_at(ui.store.save_root).size()==1, "exactly one playthrough created")
   await click(ui.next_button)
   await click(ui.back_button)
   await wait_scene("res://scenes/ui/main_menu.tscn")
   check(current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn", "mouse returns main menu")
  else:
   await key(KEY_ESCAPE)
   check(ui.page == 2, "Escape returns comparison")
 var f := FileAccess.open("res://docs/implementation/game79/visual-proof.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"failures":failures,"screens":evidence,"distinct_towns":chosen.size(),"godot":Engine.get_version_info().string},"  ") + "\n")
 f.close()
 print("GAME-79 actual input/render: %d checks, %d failures across %d towns and three resolutions" % [checks,failures,chosen.size()])
 quit(0 if failures == 0 else 1)
