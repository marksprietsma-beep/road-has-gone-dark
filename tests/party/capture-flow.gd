extends SceneTree
var checks := 0
var failures := 0
var output := "res://docs/implementation/game81/screenshots"
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(why)
func frames() -> void:
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
func key(code: int) -> void:
 for down in [true,false]:
  var e := InputEventKey.new()
  e.keycode = code
  e.pressed = down
  root.push_input(e)
  await process_frame
 await frames()
func click(control: Control, point: Vector2 = Vector2(-1,-1)) -> void:
 await frames()
 for down in [true,false]:
  var e := InputEventMouseButton.new()
  e.button_index = MOUSE_BUTTON_LEFT
  e.position = control.get_global_rect().get_center() if point.x<0 else point
  e.pressed = down
  root.push_input(e,true)
 await frames()
func wait_scene(path: String) -> void:
 var deadline := Time.get_ticks_msec()+90000
 while (current_scene==null or current_scene.scene_file_path!=path) and Time.get_ticks_msec()<deadline: await process_frame
 check(current_scene!=null and current_scene.scene_file_path==path,"actual scene transition: "+path)
 await frames()
func wait_party(ui: Control) -> void:
 var deadline := Time.get_ticks_msec()+90000
 while ui.thread!=null and Time.get_ticks_msec()<deadline: await process_frame
 check(ui.thread==null and not ui.state.is_empty(),"async generation/save completes: "+ui.message)
 check(ui.message.begins_with("Party saved") or ui.ready_view,"only verified save succeeds")
 await frames()
func shot(name: String, ui: Control=null) -> void:
 await frames()
 if ui!=null:
  check(ui.finish_button.get_global_rect().end.y<=root.get_visible_rect().size.y-8,"footer visible: "+name)
  check(ui.detail_tabs.get_global_rect().end.y<ui.back_button.get_global_rect().position.y,"details above footer")
 check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"real screenshot "+name)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 var base := OS.get_environment("GAME81_TEST_ROOT")
 change_scene_to_file("res://scenes/ui/main_menu.tscn")
 await wait_scene("res://scenes/ui/main_menu.tscn")
 for i in 90: await process_frame
 await shot("main-menu")
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/new_game_origin.tscn")
 var origin_ui = current_scene
 origin_ui.library.library_root=base.path_join("library")
 origin_ui.store.save_root=base.path_join("visual-saves-"+Crypto.new().generate_random_bytes(8).hex_encode())
 origin_ui.library.save_root=origin_ui.store.save_root
 origin_ui._reload_library()
 origin_ui.choose_world(0)
 await click(origin_ui.next_button)
 await click(origin_ui.next_button)
 await click(origin_ui.next_button)
 await click(origin_ui.next_button)
 check(origin_ui.page==3,"main menu to origin confirmation")
 await shot("origin-confirmation")
 var campaign_root: String = origin_ui.store.save_root
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/party_creation.tscn")
 var ui = current_scene
 await wait_party(ui)
 check(ui.state.party.members.size()==3,"exactly three adventurers")
 check(DirAccess.get_files_at(campaign_root).size()==1,"origin and party use one campaign")
 var id: String = ui.state.party.members[0].character_id
 var initial: Dictionary = ui.state.party.members[0].duplicate(true)
 for dimensions in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size=dimensions
  await frames()
  await shot("party-overview-%dx%d"%[dimensions.x,dimensions.y],ui)
  ui.detail_tabs.current_tab=1
  await shot("background-%dx%d"%[dimensions.x,dimensions.y],ui)
  ui.detail_tabs.current_tab=0
 # Actual OptionButton popup and keyboard ancestry selection.
 await click(ui.people_picker)
 await shot("people-popup-2560x1440")
 await key(KEY_ESCAPE)
 ui.people_picker.grab_focus()
 await key(KEY_ENTER)
 await key(KEY_DOWN)
 await key(KEY_ENTER)
 await click(ui.save_button)
 await wait_party(ui)
 check(ui.state.party.members[0].character_id==id,"ancestry selection retains stable ID")
 check(ui.state.party.members[0].background_variant<=1,"one deliberate ancestry variant")
 ui.name_edit.grab_focus()
 var focus: Control = root.gui_get_focus_owner()
 await key(KEY_TAB)
 check(root.gui_get_focus_owner()!=focus,"Tab moves focus")
 await click(ui.name_edit)
 for e in [InputEventKey.new()]:
  e.keycode=KEY_A;e.ctrl_pressed=true;e.pressed=true;root.push_input(e)
  e.pressed=false;root.push_input(e)
 for character in "Mara of Home":
  for down in [true,false]:
   var typing := InputEventKey.new()
   typing.unicode=character.unicode_at(0)
   typing.pressed=down
   root.push_input(typing)
  await process_frame
 await key(KEY_ENTER)
 await wait_party(ui)
 check(ui.state.party.members[0].name=="Mara of Home" and ui.state.party.members[0].character_id==id,"edited name commits same ID via Enter")
 await shot("edited-name-2560x1440",ui)
 var siblings: Array = [ui.state.party.members[1].duplicate(true),ui.state.party.members[2].duplicate(true)]
 var variant: int = ui.state.party.members[0].background_variant
 ui.detail_tabs.current_tab=1
 await click(ui.reroll_button)
 await wait_party(ui)
 check(ui.state.party.members[0].background_variant==variant+1 and ui.state.party.members[0].name=="Mara of Home","deliberate reroll retains manual name")
 check(ui.state.party.members[1]==siblings[0] and ui.state.party.members[2]==siblings[1],"reroll leaves both siblings unchanged")
 await shot("regenerated-background-2560x1440",ui)
 ui.roster.grab_focus()
 await key(KEY_DOWN)
 check(ui.selected==2,"arrow selects second adventurer")
 await shot("second-background-2560x1440",ui)
 await click(ui.roster,ui.roster.get_global_rect().position+ui.roster.get_item_rect(2).get_center())
 check(ui.selected==3,"mouse selects third adventurer")
 await shot("third-background-2560x1440",ui)
 await click(ui.finish_button)
 await wait_party(ui)
 check(ui.ready_view and ui.state.onboarding_stage=="party_ready","ready is saved verified handoff without gameplay")
 await shot("party-ready-2560x1440",ui)
 var slot: String=ui.slot
 var saved: Dictionary=ui.state.duplicate(true)
 await key(KEY_ESCAPE)
 await wait_scene("res://scenes/ui/main_menu.tscn")
 var resume := PartyService.new()
 resume.store.save_root=campaign_root
 resume.library.library_root=base.path_join("library")
 var choice := resume.resumable()
 check(choice.slot==slot,"narrow restart resume points to same slot")
 current_scene.refresh_party_resume(resume)
 for n in 60: await process_frame
 await shot("main-menu-resume-party")
 await click(current_scene.menu_content.get_node("ResumePartyButton"))
 await wait_scene("res://scenes/ui/party_creation.tscn")
 ui=current_scene
 await wait_party(ui)
 check(ui.state==saved,"scene restart reloads exact ready party")
 await shot("resumed-party-ready",ui)
 var entries := resume.library.discover()
 var generated: Dictionary = entries.filter(func(e: Dictionary): return not e.preset)[0]
 var reader := OriginProfiles.new()
 check(reader.load_world(generated.world),reader.error)
 var h: Dictionary=reader.projection.hometowns.values()[0]
 var created := resume.store.create_playthrough(generated.world,int(h.state_id),int(h.burg_id),int(h.province_id))
 created.state.origin_profiles=reader.descriptor
 var old := WorldOriginLore.new()
 check(old.load_world(generated.world,generated.world.enrichment_directory),old.error)
 created.state.origin_enrichment=old.descriptor
 check(resume.store.save_new(created.state.playthrough_id,created.state,generated.world).ok,"fresh-world origin")
 PartyService.handoff={"entry":generated,"slot":created.state.playthrough_id,"save_root":campaign_root,"library_root":base.path_join("library")}
 change_scene_to_file("res://scenes/ui/party_creation.tscn")
 await wait_scene("res://scenes/ui/party_creation.tscn")
 ui=current_scene
 await wait_party(ui)
 await shot("fresh-world-party-2560x1440",ui)
 ui.detail_tabs.current_tab=1
 await shot("fresh-world-background-2560x1440",ui)
 print("GAME-81 actual input/render flow: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
