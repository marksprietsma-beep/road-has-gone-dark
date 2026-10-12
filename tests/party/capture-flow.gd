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
 var ancestor := control.get_parent()
 while ancestor!=null:
  if ancestor is ScrollContainer:ancestor.ensure_control_visible(control)
  ancestor=ancestor.get_parent()
 await frames()
 check(control.is_visible_in_tree() and root.get_visible_rect().has_point(control.get_global_rect().get_center()),"clicked control is visible in viewport")
 if control is BaseButton:check(not control.disabled,"clicked action is enabled")
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
 check(ui.message.begins_with("Character saved") or ui.ready_view,"only verified save succeeds: "+ui.message)
 await frames()
func shot(name: String, ui: Control=null) -> void:
 await frames()
 if ui!=null:
  check(ui.origin.is_visible_in_tree() and ui.origin.get_theme_font_size("font_size") >= GameUI.META and root.get_visible_rect().encloses(ui.origin.get_global_rect()) and not ui.origin.text.is_empty(), "readable shared-theme origin reminder fits viewport: " + name)
  check(ui.finish_button.get_global_rect().end.y<=root.get_visible_rect().size.y-8,"footer visible: "+name)
  check(ui.detail_tabs.get_global_rect().end.y<ui.back_button.get_global_rect().position.y,"details above footer")
 if ui!=null:
  var picture := root.get_texture().get_image()
  var pixel_scale := Vector2(picture.get_size()) / root.get_visible_rect().size
  var logical: Rect2 = ui.origin.get_global_rect()
  var rect: Rect2i = Rect2i(Rect2(logical.position * pixel_scale, logical.size * pixel_scale))
  var ink := 0
  for y in range(rect.position.y, rect.end.y):
   for x in range(rect.position.x, rect.end.x):
    if picture.get_pixel(x,y).r > 0.3: ink += 1
  check(ink > 20, "origin reminder has rendered text: " + name)
 check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"real screenshot "+name)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 if not OS.get_environment("GAME81_CAPTURE_OUTPUT").is_empty():output=OS.get_environment("GAME81_CAPTURE_OUTPUT")
 var legacy := OS.get_environment("GAME81_CAPTURE_LEGACY")=="1"
 if legacy:output=output.path_join("pinned-legacy")
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
 if legacy:
  origin_ui.party_creation_requested.disconnect(origin_ui._open_party)
  origin_ui.party_creation_requested.connect(func(entry: Dictionary,slot: String):
   var old := PartyService.new();old.store.save_root=origin_ui.store.save_root;old.library.library_root=origin_ui.library.library_root
   var generated := old.operate(entry,slot,"generate")
   check(generated.ok,"create an original unpinned legacy party before opening the redesigned creator")
   origin_ui._open_party(entry,slot))
 var campaign_root: String = origin_ui.store.save_root
 await key(KEY_ENTER)
 await wait_scene("res://scenes/ui/party_creation.tscn")
 var ui = current_scene
 await wait_party(ui)
 var original_pin: Dictionary=ui.state.character_builder.rules_ref.duplicate(true)
 check(original_pin.pack_id==("trhgd-rules-v1" if legacy else RulesRecords.NEW_PACK),"legacy stays pinned; fresh New Game defaults to latest familiar classes")
 check(ui.state.party.members.size()==3,"exactly three adventurers")
 check(DirAccess.get_files_at(campaign_root).size()==1,"origin and party use one campaign")
 var id: String = ui.state.party.members[0].character_id
 var initial: Dictionary = ui.state.party.members[0].duplicate(true)
 for dimensions in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size=dimensions
  await frames()
  await shot("party-overview-%dx%d"%[dimensions.x,dimensions.y],ui)
  ui.detail_tabs.current_tab=0
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
 # A changed inherited INT modifier changes the real skill budget. Complete it
 # through the visible Skills action rather than attempting a disabled Save.
 for attempt in 3:
  if ui.editor.preview.get("ok",false):break
  check(ui.save_button.disabled and not ui.identity_validation.text.is_empty(),"incomplete ancestry build is visibly explained and cannot save")
  var reason: String=CharacterBuilderRecords.reason(ui.editor.preview).to_lower()
  var label: String="Suggested skill allocation" if "skill" in reason else "Suggested spell selections"
  await click(ui.review_build_button)
  var suggestions: Array = ui.editor.find_children("*","Button",true,false).filter(func(button: Button):return button.text==label)
  check(suggestions.size()==1,"visible recommendation action exists: "+label)
  await click(suggestions[0])
 check(ui.editor.preview.get("ok",false),"ancestry-adjusted skill and preparation budgets completed through actual UI")
 ui.detail_tabs.current_tab=0;await frames()
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
 ui.detail_tabs.current_tab=0
 await click(ui.reroll_button)
 await click(ui.save_button)
 await wait_party(ui)
 check(ui.state.character_builder.confirmed.has(id) and ui.state.party.members[0].name=="Mara of Home","deliberate background selection retains manual name")
 check(ui.state.party.members[1]==siblings[0] and ui.state.party.members[2]==siblings[1],"reroll leaves both siblings unchanged")
 await shot("regenerated-background-2560x1440",ui)
 ui.roster.grab_focus()
 await key(KEY_DOWN)
 check(ui.selected==2,"arrow selects second adventurer")
 await shot("second-background-2560x1440",ui)
 await click(ui.roster,ui.roster.get_global_rect().position+ui.roster.get_item_rect(2).get_center())
 check(ui.selected==3,"mouse selects third adventurer")
 await shot("third-background-2560x1440",ui)
 for member_index in [1,2]:
  ui.selected=member_index+1;ui.refresh();await click(ui.save_button);await wait_party(ui)
 await click(ui.finish_button)
 await wait_party(ui)
 check(ui.state.get("mechanics",{}).get("rules_ref")==original_pin,"ready-party transition preserves exact campaign pin")
 check(ui.ready_view and ui.state.onboarding_stage=="party_ready","ready is saved verified handoff without gameplay")
 await shot("party-ready-2560x1440",ui)
 var slot: String=ui.slot
 var saved: Dictionary=ui.state.duplicate(true)
 await key(KEY_ESCAPE)
 await wait_scene("res://scenes/ui/main_menu.tscn")
 var resume := ExpeditionService.new()
 resume.cache_root=base.path_join("expedition-cache")
 resume.store.save_root=campaign_root
 resume.library.library_root=base.path_join("library")
 var choice := resume.resumable()
 check(choice.slot==slot,"narrow restart resume points to same slot")
 current_scene.refresh_party_resume(resume)
 check(current_scene.menu_content.get_node("ResumePartyButton").get_index()==current_scene.new_game_button.get_index()+2,"resume follows New Game and disabled Continue")
 for n in 60: await process_frame
 await shot("main-menu-resume-party")
 await click(current_scene.menu_content.get_node("ResumePartyButton"))
 await wait_scene("res://scenes/gameplay/expedition.tscn")
 ui=current_scene
 var deadline := Time.get_ticks_msec()+180000
 while ui.thread!=null and Time.get_ticks_msec()<deadline: await process_frame
 check(ui.thread==null and ui.message.is_empty(),"ready party continues into verified hometown")
 check(ui.state.get("party")==saved.party and ui.state.get("party_ids")==saved.party_ids and ui.state.get("origin")==saved.origin,"hometown resume retains exact ready party and origin")
 await shot("resumed-ready-party-hometown")
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
 ui.detail_tabs.current_tab=0
 await shot("fresh-world-background-2560x1440",ui)
 FileAccess.open(output.path_join("input-render-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"legacy":legacy,"rules_ref":original_pin},"  "))
 print("GAME-81 actual input/render flow: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
