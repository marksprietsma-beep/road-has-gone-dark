extends Node
## Same production controllers in source review and the exported diagnostic.
var tree: SceneTree
var ui: Control
var base: String
var visual := false
var checks := 0
var failures := 0
var engine := TacticalCombat.new()
var proof := {}
func _ready() -> void:
 tree=get_tree()
 # Keep this diagnostic driver while production scenes are replaced normally.
 tree.current_scene=null
 call_deferred("run")
func check(value: bool,why: String) -> void:
 checks+=1
 if not value:
  failures+=1;push_error(why)
  finish()
func frames() -> void:
 for i in 6: await tree.process_frame
 if visual: await RenderingServer.frame_post_draw
func click(control: Control) -> void:
 check(is_instance_valid(control) and not (control is Button and control.disabled),"available control")
 control.grab_focus();await frames()
 if visual:
  for down in [true,false]:
   var event := InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=control.get_global_rect().get_center();event.pressed=down;tree.root.push_input(event,true)
 else: control.pressed.emit()
 await frames()
func wait_scene(path: String) -> void:
 var deadline := Time.get_ticks_msec()+180000
 while (tree.current_scene==null or tree.current_scene.scene_file_path!=path) and Time.get_ticks_msec()<deadline: await tree.process_frame
 check(tree.current_scene!=null and tree.current_scene.scene_file_path==path,"production scene: "+path)
 ui=tree.current_scene
 if "thread" in ui: await wait_job()
 await frames()
func wait_job() -> void:
 var deadline := Time.get_ticks_msec()+180000
 while ui.thread!=null and Time.get_ticks_msec()<deadline: await tree.process_frame
 check(ui.thread==null and not ui.state.is_empty(),"production save/generation completed")
 if ui.scene_file_path.contains("party_creation"): check(ui.ready_view or ui.message.begins_with("Party saved"),"party verified")
 else: check(ui.message.is_empty(),"verified action: "+ui.message)
 await frames()
func shot(name: String) -> void:
 if not visual: return
 await frames()
 check(tree.root.get_texture().get_image().save_png(base.path_join(name+".png"))==OK,"captured "+name)
func run() -> void:
 base=OS.get_environment("ADVENTURE_REVIEW_ROOT")
 if base.is_empty(): base=ProjectSettings.globalize_path("user://first-adventure-review-proof")
 DirAccess.make_dir_recursive_absolute(base)
 visual=DisplayServer.get_name()!="headless"
 tree.root.size=Vector2i(1280,720)
 proof={"platform":OS.get_name(),"visual":visual,"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"empty_path":OS.get_environment("PATH").is_empty()}
 tree.change_scene_to_file("res://scenes/ui/main_menu.tscn");await wait_scene("res://scenes/ui/main_menu.tscn")
 await click(ui.new_game_button);await wait_scene("res://scenes/ui/new_game_origin.tscn")
 ui.library.library_root=base.path_join("library");ui.store.save_root=base.path_join("saves");ui.library.save_root=ui.store.save_root
 ui._reload_library();ui.choose_world(0);ui.show_page()
 check(ui.library.helper_status().ok,"compatible offline helper available")
 # Same generation controller and button, with a reproducible review seed.
 ui.generation_button.pressed.disconnect(ui._start_generation)
 ui.generation_button.pressed.connect(func():ui._start_generation("first-adventure-review-v1"))
 await click(ui.generation_button)
 var deadline := Time.get_ticks_msec()+240000
 while ui.job_thread!=null and Time.get_ticks_msec()<deadline: await tree.process_frame
 check(ui.job_thread==null and not ui.entries[ui.world_index].preset,"fresh world generated and selected")
 print("REVIEW: generated world selected")
 proof.world_sha=ui.entries[ui.world_index].world.source_sha256
 await shot("world-created")
 for i in 3: await click(ui.next_button)
 check(ui.page==2 and ui.burg_id>=0,"origin, region and hometown selected")
 await shot("hometown-choice")
 await click(ui.next_button) # Review origin
 await click(ui.next_button) # Confirm origin
 await wait_scene("res://scenes/ui/party_creation.tscn")
 # Explicit review composition, through the existing party editor service path.
 for i in 3:
  ui.selected=i+1;ui._start("edit",{"role_id":["vanguard","scout","adept"][i]});await wait_job()
 ui.selected=1;ui.refresh();await shot("party")
 await click(ui.finish_button);await wait_job()
 await click(ui.finish_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 await click(ui.action_buttons.prepare_adventure);await wait_job()
 print("REVIEW: origin, party and adventure prepared")
 await shot("party-prepared")
 var first_lead: String=ui.state.expedition.leads[0].id
 await click(ui.action_buttons[first_lead]);await click(ui.action_buttons.accept);await wait_job()
 await click(ui.action_buttons.depart);await wait_job();await shot("expedition")
 if ui.action_buttons.has("scout"): await click(ui.action_buttons.scout);await wait_job()
 await click(ui.action_buttons.travel);await wait_job();await shot("site")
 # Fork only the isolated fixture to exercise both outcomes from identical context.
 var original: Dictionary=ui.state.duplicate(true)
 var entry: Dictionary=ui.entry
 var slot: String=ui.slot
 var service: AdventureService=ui.service
 var save_path := service.store._slot_path(slot)
 await click(ui.action_buttons.begin_battle);await wait_scene("res://scenes/combat/first_adventure.tscn")
 while ui.thread!=null or engine.current(ui.battle()).team=="enemy": await tree.process_frame
 if visual:
  for size in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
   tree.root.size=size;await frames()
   check(ui.end_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"combat footer fits")
   check(ui.targeting.get_visible_line_count()>=1,"targeting hint has a visible text line")
   await shot("combat-%dx%d"%[size.x,size.y])
  tree.root.size=Vector2i(1280,720);await frames()
 var paused_hash: String=ui.battle().state_hash
 await click(ui.menu_button);await wait_scene("res://scenes/ui/main_menu.tscn")
 ui.refresh_party_resume(service);await click(ui.menu_content.get_node("ResumePartyButton"));await wait_scene("res://scenes/combat/first_adventure.tscn")
 check(ui.battle().state_hash==paused_hash,"exact saved battle resumed through menu")
 deadline=Time.get_ticks_msec()+240000
 while ui.battle().status=="active" and Time.get_ticks_msec()<deadline:
  if ui.thread!=null or engine.current(ui.battle()).team=="enemy": await tree.process_frame;continue
  var b: Dictionary=ui.battle();var actor := engine.current(b)
  var mode := "spark" if engine.characters.derive_character(actor.record).snapshot.abilities.has("spark") else "attack"
  var target := ""
  if int(b.budget.main)>0:
   for id in b.order:
    if engine.eligible(b,actor,b.units[id],mode): target=id;break
  if not target.is_empty():
   await click(ui.action_buttons[mode]);await click(ui.tiles[str(b.units[target].position)]);await wait_job()
  elif int(b.budget.move)>0:
   var command := engine.enemy_command(b)
   if command.kind=="move": await click(ui.action_buttons.move);await click(ui.tiles[str(command.destination)]);await wait_job()
   else: await click(ui.end_button);await wait_job()
  else: await click(ui.end_button);await wait_job()
 check(ui.battle().status=="victory","production fight reaches victory")
 print("REVIEW: victory achieved")
 proof.victory_battle_hash=ui.battle().state_hash
 await shot("victory")
 await click(ui.return_button);await wait_scene("res://scenes/gameplay/expedition.tscn");await shot("results")
 await click(ui.home_button);await wait_job()
 check(ui.state.expedition.active.is_empty() and ui.state.first_adventure.characters.values().all(func(c: Dictionary):return c.xp==10 and c.history.size()==1),"returned victory is remembered")
 # Reveal one concise identity/history card for the review screenshot.
 await click(ui.action_buttons["companion:"+ui.state.party_ids[0]]);await shot("returned-home")
 check(service.store.load_save(slot,entry.world).ok,"victory save valid from bundled resources")
 # Separate cloned test campaign, preserving the completed victory campaign.
 var failed := original.duplicate(true)
 var failed_slot := "review-defeat-"+str(Time.get_ticks_msec())
 check(service.store.save_new(failed_slot,failed,entry.world).ok,"isolated defeat fixture saved")
 PartyService.handoff={"entry":entry,"slot":failed_slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 tree.change_scene_to_file("res://scenes/gameplay/expedition.tscn");await wait_scene("res://scenes/gameplay/expedition.tscn")
 await click(ui.action_buttons.begin_battle);await wait_scene("res://scenes/combat/first_adventure.tscn")
 while ui.thread!=null or engine.current(ui.battle()).team=="enemy": await tree.process_frame
 await click(ui.retreat_button);await wait_job()
 check(ui.battle().status=="defeat","explicit defeat path")
 await shot("defeat")
 await click(ui.return_button);await wait_scene("res://scenes/gameplay/expedition.tscn");await shot("defeat-results")
 await click(ui.home_button);await wait_job()
 check(ui.state.expedition.active.is_empty() and ui.state.first_adventure.characters.values().all(func(c: Dictionary):return c.xp==0 and c.history.size()==1),"defeat returns with no victory reward")
 check(service.store.load_save(failed_slot,entry.world).ok,"defeat save valid from bundled resources")
 finish()
func finish() -> void:
 proof.checks=checks;proof.failures=failures
 var file := FileAccess.open(base.path_join("review-proof.json"),FileAccess.WRITE)
 if file!=null: file.store_string(JSON.stringify(proof,"  ")+"\n")
 print("FIRST ADVENTURE REVIEW PROOF "+JSON.stringify(proof))
 tree.quit(1 if failures else 0)
