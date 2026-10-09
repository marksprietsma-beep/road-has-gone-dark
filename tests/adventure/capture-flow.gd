extends SceneTree
var checks := 0
var failures := 0
var ui: Control
var base: String
var service := AdventureService.new()
var entry := {}
var slot := ""
var output: String
func check(value: bool,why: String) -> void:
 checks+=1
 if not value: failures+=1;push_error(why)
func _initialize() -> void: call_deferred("run")
func frames() -> void:
 for i in 8: await process_frame
 await RenderingServer.frame_post_draw
func click(control: Control) -> void:
 control.grab_focus();await frames()
 for down in [true,false]:
  var input := InputEventMouseButton.new();input.button_index=MOUSE_BUTTON_LEFT;input.position=control.get_global_rect().get_center();input.pressed=down;root.push_input(input,true)
 await frames()
func wait_scene(path: String) -> void:
 var deadline := Time.get_ticks_msec()+10000
 while (current_scene==null or current_scene.scene_file_path!=path) and Time.get_ticks_msec()<deadline: await process_frame
 check(current_scene!=null and current_scene.scene_file_path==path,"scene transition: "+path)
 ui=current_scene
 await wait_job()
func wait_job() -> void:
 var deadline := Time.get_ticks_msec()+180000
 while ui.thread!=null and Time.get_ticks_msec()<deadline: await process_frame
 if ui.has_method("is_presenting"):
  while (ui.is_presenting() or ui.presentation_active) and Time.get_ticks_msec()<deadline:await process_frame
 check(ui.thread==null and not ui.state.is_empty() and ui.message.is_empty(),"real persisted action: "+ui.message)
 await frames()
func shot(name: String) -> void:
 await frames()
 root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
 base=OS.get_environment("ADVENTURE_TEST_ROOT");output=base.path_join("screenshots");DirAccess.make_dir_recursive_absolute(output)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 slot=str(JSON.parse_string(FileAccess.get_file_as_string(base.path_join("ui.json"))).slot)
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 root.size=Vector2i(1280,720)
 change_scene_to_file("res://scenes/gameplay/expedition.tscn");await wait_scene("res://scenes/gameplay/expedition.tscn")
 check(ui.action_buttons.has("begin_battle"),"actual site exposes authored fight")
 await shot("site-encounter")
 await click(ui.action_buttons.begin_battle);await wait_scene("res://scenes/combat/first_adventure.tscn")
 # Pause rendering-driven AI by waiting for a player before any input.
 while ui.engine.current(ui.battle()).team=="enemy" or ui.thread!=null or ui.is_presenting(): await process_frame
 await frames()
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size=resolution;await frames();await frames()
  check(ui.grid.get_global_rect().end.x<root.get_visible_rect().size.x,"board fits width")
  check(ui.end_button.get_global_rect().end.y<=root.get_visible_rect().size.y,"turn controls fit height")
  await shot("battle-%dx%d"%[resolution.x,resolution.y])
 root.size=Vector2i(1280,720);await frames()
 var engine := TacticalCombat.new()
 var initial: Dictionary=ui.battle()
 var reachable := engine.paths(initial,engine.current(initial))
 var destination: Array=reachable.values()[1].back()
 await click(ui.action_buttons.move);await click(ui.tiles[str(destination)]);await wait_job()
 check(ui.battle().budget.move==0 and engine.current(ui.battle()).position==destination,"real Move and tile clicks commit movement")
 var paused_hash: String=ui.battle().state_hash
 await click(ui.menu_button);await wait_scene_menu()
 var menu: Control=current_scene;menu.refresh_party_resume(service)
 check(menu.menu_content.get_node("ResumePartyButton").text=="Resume Expedition","main menu exposes existing resume flow")
 await click(menu.menu_content.get_node("ResumePartyButton"));await wait_scene("res://scenes/combat/first_adventure.tscn")
 check(ui.battle().state_hash==paused_hash,"menu resumes exact saved battlefield")
 # Drive actual attack/ability/end buttons through victory. AI remains live.
 var deadline := Time.get_ticks_msec()+180000
 while ui.battle().status=="active" and Time.get_ticks_msec()<deadline:
  if ui.thread!=null or ui.is_presenting() or ui.presentation_active or engine.current(ui.battle()).team=="enemy": await process_frame;continue
  var b: Dictionary=ui.battle();var a := engine.current(b)
  var ability := "spark" if engine.characters.derive_character(a.record).snapshot.abilities.has("spark") else "attack"
  var target_id := ""
  if int(b.budget.main)>0:
   for id in b.order:
    if engine.eligible(b,a,b.units[id],ability): target_id=id;break
  if not target_id.is_empty():
   await click(ui.action_buttons[ability]);await click(ui.tiles[str(b.units[target_id].position)]);await wait_job()
  elif int(b.budget.move)>0:
   var command := engine.enemy_command(b)
   if command.kind=="move": await click(ui.action_buttons.move);await click(ui.tiles[str(command.destination)]);await wait_job()
   else: await click(ui.end_button);await wait_job()
  else: await click(ui.end_button);await wait_job()
 check(ui.battle().status=="victory","real UI inputs complete victory")
 await shot("victory")
 await click(ui.return_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 check(ui.state.expedition.active.phase=="result","battle return shows regional consequences")
 await shot("regional-consequences")
 await click(ui.home_button);await wait_job()
 check(ui.state.expedition.active.is_empty(),"return-home button completes loop")
 await shot("party-history")
 print(JSON.stringify({"suite":"visual","checks":checks,"failures":failures}))
 quit(1 if failures else 0)
func wait_scene_menu() -> void:
 while current_scene==null or current_scene.scene_file_path!="res://scenes/ui/main_menu.tscn": await process_frame
 await frames()
