extends SceneTree
var checks := 0
var failures := 0
var evidence: Array = []
var output := "res://docs/implementation/game80/screenshots"
func check(value: bool, why: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(why)
func _initialize() -> void: call_deferred("run")
func frames() -> void:
 for n in 4: await process_frame
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
  root.push_input(e,true)
 await frames()
func shot(ui: Control, name: String) -> void:
 await frames()
 check(ui.next_button.get_global_rect().end.y <= root.get_visible_rect().size.y - 8, "footer visible: " + name)
 check(ui.map.size.y >= 146, "map retains useful size")
 check(ui.lore_scroll.get_global_rect().end.y < ui.next_button.get_global_rect().position.y, "profile panel stays above controls")
 check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "actual screenshot")
 evidence.append({"image":name+".png","world":ui.worlds[ui.world_index].world_id,"state":ui.state_id,"province":ui.province_id,"burg":ui.burg_id,"profile":ui.lore_label.text,"facts":ui.facts.text,"resolution":[root.size.x,root.size.y]})
func area_check(ui: Control, group: String, id: String) -> void:
 var row: Dictionary = ui._profiles().public_profile(group, id)
 check(not row.is_empty() and ui.lore_label.text == row.full_summary, "immediate stored profile update")
 var expected: Dictionary = ui._origin_context().region_summary(ui.state_id, ui.province_id if group == "regions" else -1)
 check(ui.facts.text == expected.summary, "facts and political ownership aligned")
 var ids: PackedInt32Array = ui.map.package.cell_ids
 var c: Dictionary = ui.previews[ui.world_index].cells
 var image: Image = ui.map.overlay.get_image()
 var inside := false
 var outside := false
 for i in ids.size():
  var cell: int = ids[i]
  if cell < 0 or cell >= c.ids.size(): continue
  var selected: bool = int(c.state[cell]) == ui.state_id and (group != "regions" or int(c.province[cell]) == ui.province_id)
  var colour: Color = image.get_pixel(i % image.get_width(), i / image.get_width())
  if selected and not inside:
   check(colour.a > 0, "map wash contains authoritative selected area")
   inside = true
  elif not selected and not outside:
   check(colour.a == 0, "map wash excludes other political cells")
   outside = true
  if inside and outside: break
 check(inside, "selected political area has visible source cells")
func home_check(ui: Control) -> void:
 var row: Dictionary = ui._profiles().public_profile("hometowns",str(ui.burg_id))
 var home: Dictionary = ui.worlds[ui.world_index].get_record("burg",ui.burg_id)
 check(ui.lore_label.text.begins_with(row.full_summary), "hometown identity is primary")
 check(ui.lore_label.text.contains("Local memory: " + str(row.memory)), "history is retained as secondary content")
 check(ui.facts.text == ui._origin_context().hometown_summary(ui.burg_id).summary, "hometown facts aligned")
 check(ui.map.burg == Vector2(float(home.x),float(home.y)), "exact hometown coordinates highlighted")
 check(row.state_id == ui.state_id and row.world_id == ui.worlds[ui.world_index].world_id, "hometown world and parent source identity")
 check(ui.next_button.get_global_rect().end.y <= root.get_visible_rect().size.y - 8, "live selection preserves footer")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 change_scene_to_file("res://scenes/ui/new_game_origin.tscn")
 for n in 20: await process_frame
 var ui = current_scene
 var base := OS.get_environment("GAME80_TEST_ROOT")
 ui.library.library_root = base.path_join("library")
 ui.store.save_root = base.path_join("visual-saves")
 ui.library.save_root = ui.store.save_root
 ui._reload_library()
 var towns: Array = []
 for wi in [0,1,2]:
  ui.choose_world(wi)
  var count := 0
  for s in ui.states():
   for home in ui.worlds[wi].home_candidates(int(s.i),-1,8):
    towns.append({"world":wi,"state":int(s.i),"burg":int(home.id)})
    count += 1
    if count >= (10 if wi < 2 else 2): break
   if count >= (10 if wi < 2 else 2): break
 check(towns.size() == 22, "twenty preset hometowns plus genuine generated hometowns")
 for dimensions in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size = dimensions
  ui.choose_world(1)
  ui.page = 0
  ui.area_view = "state"
  ui.show_page()
  await click(ui.next_button)
  check(ui.state_picker is ItemList, "themed state list replaces grey popup")
  for n in 16:
   if n: await key(KEY_DOWN)
   area_check(ui,"states",str(ui.state_id))
   if n in [0,5]: await shot(ui,"state-%d-%dx%d" % [n,dimensions.x,dimensions.y])
  check(ui.state_picker.get_v_scroll_bar().value > 0, "state list scrolls through at least fifteen choices")
  ui.choose_state(int(ui.states()[0].i))
  ui.show_page()
  await key(KEY_ENTER)
  check(ui.page == 1 and ui.area_view == "region", "Enter advances state to explicit region list")
  var parent: int = ui.state_id
  for n in mini(7,ui.province_picker.item_count):
   if n: await key(KEY_DOWN)
   if ui.province_id > 0: area_check(ui,"regions","%d:%d" % [ui.state_id,ui.province_id])
   check(ui.state_id == parent, "province selection preserves parent state")
   if n in [1,3]: await shot(ui,"region-%d-%dx%d" % [n,dimensions.x,dimensions.y])
  await key(KEY_ESCAPE)
  check(ui.page == 1 and ui.area_view == "state" and ui.state_id == parent, "Escape from region preserves state choice")
  await key(KEY_ESCAPE)
  check(ui.page == 0, "Escape state returns world")
  for n in towns.size():
   var choice: Dictionary = towns[n]
   ui.choose_world(choice.world)
   ui.page = 1
   ui.area_view = "state"
   ui.choose_state(choice.state)
   ui.show_page()
   await click(ui.next_button)
   ui.choose_province(-1)
   await click(ui.next_button)
   var index := -1
   for i in ui.candidates.size():
    if ui.candidates[i].id == choice.burg: index = i
   check(index >= 0,"eligible offered hometown")
   ui.options.grab_focus()
   var current: int = ui.options.get_selected_items()[0]
   for i in absi(index-current): await key(KEY_DOWN if index>current else KEY_UP)
   check(ui.burg_id == choice.burg,"keyboard selects actual hometown")
   home_check(ui)
   if n == 0:
    await click(ui.options,ui.options.get_global_rect().position + ui.options.get_item_rect(1).get_center())
    check(ui.burg_id == ui.candidates[1].id,"mouse hometown selection")
    home_check(ui)
    var focus: Control = root.gui_get_focus_owner()
    await key(KEY_TAB)
    check(root.gui_get_focus_owner()!=focus,"Tab moves focus")
   for i in [0,mini(1,ui.candidates.size()-1),mini(2,ui.candidates.size()-1),index]:
    ui.choose_home(i)
    home_check(ui)
   if n in [0,1,20]: await shot(ui,"hometown-%d-%dx%d" % [n,dimensions.x,dimensions.y])
  await click(ui.next_button)
  check(ui.page == 3,"mouse confirmation")
  await shot(ui,"confirmation-%dx%d" % [dimensions.x,dimensions.y])
  var lore: String = ui.lore_label.text
  if dimensions == Vector2i(2560,1440):
   await key(KEY_ENTER)
   check(ui.page == 4 and not ui.saved_slot.is_empty(),"validated persisted handoff")
   var saved: Dictionary = ui.store.load_save(ui.saved_slot,ui.worlds[ui.world_index])
   check(saved.ok and saved.state.has("origin_profiles") and saved.state.has("origin_enrichment"),"both versioned packages survive reload")
   check(lore==ui.lore_label.text,"handoff retains identical profile/history")
   await shot(ui,"origin-established")
   await click(ui.next_button)
   await click(ui.next_button)
   check(DirAccess.get_files_at(ui.store.save_root).size()==1,"review never duplicates saves")
   await click(ui.back_button)
   for n in 20: await process_frame
   check(current_scene.scene_file_path=="res://scenes/ui/main_menu.tscn","returns main menu")
  else: await key(KEY_ESCAPE)
 var f := FileAccess.open("res://docs/implementation/game80/visual-proof.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"failures":failures,"towns":towns.size(),"states_scrolled":16,"resolutions":3,"screens":evidence},"  ")+"\n")
 f.close()
 print("GAME-80 real input/render: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
