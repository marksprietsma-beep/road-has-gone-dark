extends "res://tests/character_psychic/capture_driver.gd"
## Existing writer-owned ordinary earned campaign; advanced view is separately labelled.
func run() -> void:
 base=OS.get_environment("GAME112W4_CAPTURE_ROOT");DirAccess.make_dir_recursive_absolute(base)
 var source_root := OS.get_environment("GAME112W4_SOURCE_ROOT").path_join("journey")
 var proof: Dictionary=WorldOriginLore.read_json(source_root.path_join("proof.json"));slot=proof.slot
 service.library.library_root=source_root.path_join("library");entry=service.library.discover()[0]
 service.cache_root=base.path_join("cache");service.store.save_root=source_root.path_join("saves");service.library.save_root=service.store.save_root
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual earned campaign reload");state=loaded.get("state",{})
 if state.is_empty():finish();return
 engine=TacticalAuras.new(state)
 await capture("earned-v14-reloaded-sheet","sheet",2)
 await capture("earned-v14-advancement","sheet",3)
 # Copy through the original writer to isolate render interactions from the verified save.
 var fixture: Dictionary=state.duplicate(true)
 service.store.save_root=base.path_join("combat-copy");service.library.save_root=service.store.save_root
 check(service.store.save_new(slot,fixture,entry.world).ok,"original writer isolates combat capture")
 action("cycle_seek")
 var found := false
 for i in 4:
  if OpportunityGenerator.template(cycle().base.sites[i].activity_id).family!="contested":continue
  travel(i);action("cycle_fight");found=true;break
 check(found,"real generated encounter")
 if found:
  var owner_id: String=state.party_ids[2]
  for n in 30:
   var b := AdventureService.active_battle(state)
   if engine.current(b).id==owner_id:break
   action("cycle_command",{"command":engine.enemy_command(b) if engine.current(b).team=="enemy" else {"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"}})
  var b := AdventureService.active_battle(state)
  action("cycle_command",{"command":{"actor_id":owner_id,"revision":b.revision,"kind":"marshal-aura-assault","target_id":owner_id}})
  check(AdventureService.active_battle(state).units[owner_id].record.runtime.statuses.any(func(s: Dictionary):return s.id=="marshal-aura-assault"),"real saved active aura")
  await capture("earned-v14-marshal-aura","combat")
 # High-level history from the focused mechanics fixture, never represented as earned XP.
 var saved: Dictionary=WorldOriginLore.read_json(OS.get_environment("GAME112W4_SOURCE_ROOT").path_join("saved.json"))
 var initial_store := GamePlaythroughStore.new();initial_store.save_root=proof.development_saves[0].save_root
 var original := initial_store.load_save(slot,entry.world)
 check(original.ok,"verified pre-cycle development campaign")
 fixture=original.state.duplicate(true)
 var identity: String=fixture.party_ids[0]
 var record: Dictionary=saved.records.prestige.duplicate(true)
 record.character_id=identity;record.ancestry_ref=fixture.mechanics.records[identity].ancestry_ref
 fixture.mechanics.records[identity]=record;fixture.character_builder.initial_levels[identity]=record.advancement_history.size()
 var store := GamePlaythroughStore.new();store.save_root=base.path_join("development-prestige")
 var wrote := store.save_new(slot,fixture,entry.world)
 check(wrote.ok,"writer-owned labelled prestige fixture "+str(wrote.get("error","")))
 if wrote.ok:await advanced_capture(fixture,store.save_root,"cognition-adept")
 # Additional advanced histories are clearly development fixtures, not earned levels.
 var cohort: Dictionary=WorldOriginLore.read_json(OS.get_environment("GAME112W4_SOURCE_ROOT").path_join("cohort/saved.json"))
 for path in ["war-chanter","archmage","metamind"]:
  fixture=original.state.duplicate(true)
  record=cohort.records[path].duplicate(true);record.character_id=identity;record.ancestry_ref=fixture.mechanics.records[identity].ancestry_ref
  fixture.mechanics.records[identity]=record;fixture.character_builder.initial_levels[identity]=record.advancement_history.size()
  store=GamePlaythroughStore.new();store.save_root=base.path_join("development-"+path)
  wrote=store.save_new(slot,fixture,entry.world)
  check(wrote.ok,"writer-owned advanced cohort "+path+str(wrote.get("error","")))
  if wrote.ok:await advanced_capture(fixture,store.save_root,path)
 # Ordinary, XP-funded prestige history is rendered separately from those fixtures.
 var earned_root := OS.get_environment("GAME112W4_SOURCE_ROOT").path_join("earned-cohort")
 var earned: Dictionary=WorldOriginLore.read_json(earned_root.path_join("proof.json"))
 slot=earned.slot;service.store.save_root=earned_root.path_join("saves");service.library.library_root=earned_root.path_join("library");service.library.save_root=service.store.save_root
 entry=service.library.discover()[0]
 loaded=service.operate(entry,slot,"resume")
 check(loaded.ok,"actual360XP prestige campaign reload")
 if loaded.ok:
  state=loaded.state
  await capture("earned-war-chanter-history","sheet",2)
  await capture("earned-war-chanter-next-level","sheet",3)
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source_commit":OS.get_environment("GAME112W4_SOURCE_SHA"),"screenshots":screenshots,"ordinary_earned_xp":proof.earned_xp,"prestige_earned_xp":earned.earned_xp,"advanced_fixture_earned":false}))
 finish()
