extends "res://tests/character_completeness/journey_driver.gd"
## Render actual saved earned characters and an existing contextual opportunity.
func run() -> void:
 cohort=int(OS.get_environment("GAME126_COHORT"));base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-"+str(cohort))
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof := WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"load real earned campaign for visual proof")
 if not loaded.ok:finish_journey();return
 state=loaded.state
 for member in [0,1,2]:
  PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  CharacterScreen.handoff=PartyService.handoff.duplicate()
  get_tree().change_scene_to_file("res://scenes/ui/character_sheet.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var ui: Control=get_tree().current_scene
  while ui.thread!=null:await get_tree().process_frame
  ui._select_member(member);ui.detail_tabs.current_tab=2
  await photograph("earned-cohort%d-member%d"%[cohort,member+1])
  get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
  for frame in 2:await get_tree().process_frame
 if cohort==0:
  var alternate := GamePlaythroughStore.new();alternate.save_root=base.path_join("capture-save-"+str(Time.get_ticks_msec()))
  check(alternate.save_new(slot,state,entry.world).ok,"capture fork retains original campaign writer")
  service.store=alternate
  action("cycle_seek");travel(0)
  await capture("trained-opportunity-choice","expedition")
 FileAccess.open(base.path_join("screenshots.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":RulesRecords.registry(state).rules_ref(),"screenshots":screenshots}))
 finish_journey()
func photograph(name: String) -> void:
 get_tree().root.size=Vector2i(1280,720)
 for frame in 5:await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var folder := base.path_join("screenshots");DirAccess.make_dir_recursive_absolute(folder)
 var file := name+"-1280x720.png"
 check(get_tree().root.get_texture().get_image().save_png(folder.path_join(file))==OK,"actual Godot earned character render")
 screenshots.append({"file":file,"sha256":FileAccess.get_sha256(folder.path_join(file)),"earned_xp":360,"development_fixture":false})
