extends SceneTree
var checks := 0
var failures := 0
var ui: CharacterScreen
var service := CharacterBuilderService.new()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func settle() -> void:
 for frame in 8:await process_frame
func wait_job() -> void:
 var deadline := Time.get_ticks_msec()+120000
 while ui.thread!=null and Time.get_ticks_msec()<deadline:await process_frame
 check(ui.thread==null and not ui.state.is_empty(),"UI transaction completes")
 await settle()
func press(button: Button) -> void:
 check(not button.disabled,"visible action is enabled")
 button.pressed.emit();await wait_job()
func run() -> void:
 var base := OS.get_environment("GAME103_TEST_ROOT")
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library")
 var entry: Dictionary=service.library.discover()[0]
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"source profiles")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var created := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(created.ok and service.store.save_new(created.state.playthrough_id,created.state,entry.world).ok,"isolated real origin save")
 PartyService.handoff={"entry":entry,"slot":created.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root}
 change_scene_to_file("res://scenes/ui/party_creation.tscn");await settle();ui=current_scene;await wait_job()
 check(ui.finish_button.disabled,"three confirmations required")
 ui.name_edit.text="Keyboard Adventurer";ui.name_edit.grab_focus()
 for down in [true,false]:
  var event := InputEventKey.new();event.keycode=KEY_ENTER;event.pressed=down;root.push_input(event,true)
  await process_frame
 check(ui.thread!=null and not ui.name_edit.editable,"Enter starts save and locks text editing")
 check(ui.editor.class_picker.disabled and ui.revert_button.disabled,"saving locks nested choices and revert")
 await wait_job()
 check(ui.state.party.members[0].name=="Keyboard Adventurer" and ui.name_edit.editable,"keyboard save retains edited name and unlocks draft")
 for index in [1,2]:
  ui.selected=index+1;ui.refresh();await press(ui.save_button)
 check(not ui.finish_button.disabled,"all three individually confirmed")
 await press(ui.finish_button)
 check(ui.ready_view and not ui.name_edit.editable and ui.people_picker.disabled and not ui.reroll_button.visible,"ready identity remains read-only after async unlock")
 check(ui.state.mechanics.records.size()==3,"finalisation retains one gameplay roster")
 var policy := CharacterBuilderRecords.preview_advancement(ui.state,ui.state.party_ids[0],ui.advance_editor.choice())
 check(not policy.ok and ui.advancement_button.disabled,"zero XP sheet cannot grant a level")
 FileAccess.open(base.path_join("ui-results.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
 print("GAME103 editor ",checks," / ",failures);quit(1 if failures else 0)
