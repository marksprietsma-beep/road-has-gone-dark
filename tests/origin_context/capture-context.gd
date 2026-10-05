extends SceneTree
var checks := 0
var failures := 0
var output := "res://docs/implementation/game75/screenshots"
var evidence: Array = []
func check(value: bool, reason: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(reason)
func _initialize() -> void:
 call_deferred("run")
func frames() -> void:
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
func click(control: Control) -> void:
 await frames()
 for down in [true,false]:
  var event := InputEventMouseButton.new()
  event.position = control.get_global_rect().get_center()
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = down
  root.push_input(event,true)
 await frames()
func key(code: int) -> void:
 for down in [true,false]:
  var event := InputEventKey.new()
  event.keycode = code
  event.pressed = down
  root.push_input(event)
  await process_frame
 await frames()
func capture(ui: Control, name: String) -> void:
 await frames()
 check(ui.facts.get_global_rect().end.y<=ui.next_button.get_global_rect().position.y,"context fits above footer: "+name)
 check(ui.map.size.y>=146,"map retains useful logical height: "+name)
 check(ui.facts.get_line_count()<=4,"context stays within four readable lines: "+name)
 check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"actual screenshot saved")
 var ctx = ui._origin_context()
 var context: Dictionary = ctx.world_summary() if ui.page==0 else (ctx.hometown_summary(ui.burg_id) if ui.page>=2 else ctx.region_summary(ui.state_id,ui.province_id))
 evidence.append({"image":name+".png","world_ref":ui.worlds[ui.world_index].source_metadata(),"state_id":ui.state_id,"province_id":ui.province_id,"burg_id":ui.burg_id,"page":ui.page,"context":context,"resolution":[root.size.x,root.size.y]})
func wait_scene(path: String) -> void:
 for i in 300:
  await process_frame
  if current_scene!=null and current_scene.scene_file_path==path: return
 check(false,"scene transition: "+path)
func select_home(ui: Control, id: int) -> void:
 var town: Dictionary = ui.worlds[0].get_record("burg",id)
 var cell: Dictionary = ui.worlds[0].get_record("cell",int(town.cell))
 ui.page = 1
 ui.choose_state(int(cell.state))
 ui.choose_province(int(cell.province))
 await click(ui.next_button)
 var index := -1
 for i in ui.candidates.size():
  if int(ui.candidates[i].id)==id: index=i
 check(index>=0,"screenshot uses real offered candidate")
 if index<0: return
 ui.options.select(index)
 ui.options.item_selected.emit(index)
 await frames()
 check(ui.burg_id==id,"hometown selection updates source identity")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 root.size=Vector2i(1280,720)
 change_scene_to_file("res://scenes/ui/main_menu.tscn")
 await wait_scene("res://scenes/ui/main_menu.tscn")
 await create_timer(0.6).timeout
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/new_game_origin.tscn")
 var ui = current_scene
 check(ui.scene_file_path=="res://scenes/ui/new_game_origin.tscn","real menu enters onboarding")
 var directory := "user://game75-visual-"+Crypto.new().generate_random_bytes(8).hex_encode()
 ui.store.save_root=directory.path_join("saves")
 ui.library.library_root=directory.path_join("worlds")
 ui.library.save_root=ui.store.save_root
 ui._reload_library()
 ui.show_page()
 await capture(ui,"01-world-i")
 await key(KEY_DOWN)
 check(ui.world_index==1,"keyboard selects second world")
 await capture(ui,"02-world-ii")
 await key(KEY_UP)
 check(ui.world_index==0,"keyboard returns first world")
 # Find actual eligible candidates offered by the unchanged eight-town selector.
 var choices := {}
 var ctx = ui._origin_context()
 for state in ui.states():
  ui.state_id=int(state.i)
  for province in ui.provinces():
   for candidate in ui.worlds[0].home_candidates(int(state.i),int(province.i),8):
    var info: Dictionary=ctx.hometown_summary(int(candidate.id))
    var f: Dictionary=info.facts
    if f.water=="Inland" and str(f.landscape).contains("woodland") and not choices.has("forest"): choices.forest=int(candidate.id)
    if f.water=="Coastal" and f.port!=null and int(f.port)>0 and not choices.has("coastal_port"): choices.coastal_port=int(candidate.id)
    if f.walls and not choices.has("walled"): choices.walled=int(candidate.id)
    if not f.walls and not choices.has("unwalled"): choices.unwalled=int(candidate.id)
    if f.nearby_ids.size()==0 and not choices.has("sparse"): choices.sparse=int(candidate.id)
    if f.nearby_ids.size()>=3 and not choices.has("clustered"): choices.clustered=int(candidate.id)
    if f.river_port and not choices.has("river_port"): choices.river_port=int(candidate.id)
 check(["forest","coastal_port","walled","unwalled","sparse","clustered"].all(func(k: String): return choices.has(k)),"all required genuine contrasting offered choices found")
 for kind in ["forest","coastal_port","walled","unwalled","sparse","clustered","river_port"]:
  if not choices.has(kind): continue
  await select_home(ui,choices[kind])
  await capture(ui,"home-"+kind)
 # Full-state and province summaries, using two genuinely contrasting areas.
 for kind in ["forest","coastal_port"]:
  await select_home(ui,choices[kind])
  await key(KEY_ESCAPE)
  check(ui.page==1,"Escape returns region without losing valid area")
  await capture(ui,"region-"+kind)
  ui.choose_province(-1)
  await capture(ui,"state-"+kind)
 await select_home(ui,choices.coastal_port)
 await click(ui.next_button)
 check(ui.page==3,"mouse reaches confirmation")
 check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ui.store.save_root)),"context browsing never creates save")
 await capture(ui,"confirm-coastal-port")
 for dimensions in [Vector2i(640,360),Vector2i(2560,1440)]:
  root.size=dimensions
  await capture(ui,"confirm-%dx%d"%[dimensions.x,dimensions.y])
 root.size=Vector2i(1280,720)
 await key(KEY_ENTER)
 check(ui.page==4 and ui.store.load_save(ui.saved_slot,ui.worlds[0]).ok,"context preserves successful save and immediate reload")
 await capture(ui,"origin-established")
 # Genuine fresh helper generation through the existing UI job, not fixture import.
 ui.page=0
 ui.saved_slot=""
 ui.show_page()
 ui._start_generation("game75-context-visual")
 var start := Time.get_ticks_msec()
 while ui.job_thread!=null and Time.get_ticks_msec()-start<180000: await create_timer(0.1).timeout
 check(ui.job_thread==null and ui.entries.size()==3 and not ui.entries[ui.world_index].preset,"real UI helper generates and persists source")
 await capture(ui,"03-generated-world")
 var generated: Dictionary=ui.entries[ui.world_index]
 await click(ui.next_button)
 await capture(ui,"generated-region")
 await click(ui.next_button)
 check(ui.page==2 and ui.burg_id>0,"generated source reaches real hometown candidates")
 await capture(ui,"generated-hometown")
 var report := {"checks":checks,"failures":failures,"runtime":Engine.get_version_info().string,"choices":choices,"screens":evidence,"genuine_ui_generation":true}
 var file := FileAccess.open("res://docs/implementation/game75/visual-proof.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  ")+"\n")
 file.close()
 # Remove only this test's own template and save.
 for name in DirAccess.get_files_at(ui.store.save_root): DirAccess.remove_absolute(ProjectSettings.globalize_path(ui.store.save_root.path_join(name)))
 check(ui.library.delete_world(generated).ok,"test-only generated world cleanup")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(ui.store.save_root))
 DirAccess.remove_absolute(ui.library._root())
 DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
 print("GAME-75 actual Godot context/input/render: %d checks, %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
