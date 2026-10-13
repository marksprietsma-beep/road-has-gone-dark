extends "res://tests/adventure_cycles/earned_driver.gd"
class FaultStore extends GamePlaythroughStore:
 var fault := ""
 var pending := false
 func save_existing(save_slot: String,candidate: Dictionary,world: GameWorldTemplate) -> Dictionary:
  if fault=="write":return _fail("Injected write failure")
  var result := super.save_existing(save_slot,candidate,world)
  if result.ok and fault=="reload":pending=true
  return result
 func load_save(save_slot: String,world: GameWorldTemplate) -> Dictionary:
  if pending:pending=false;return _fail("Injected immediate reload failure")
  return super.load_save(save_slot,world)
func run() -> void:
 base=OS.get_environment("GAME121_TEST_ROOT");DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 campaign(false)
 if failures>0:finish();return
 var original := FileAccess.get_file_as_string(service.store._slot_path(slot))
 var a := CycleAdventure.seek(service,entry,state);var b := CycleAdventure.seek(service,entry,state)
 check(a.ok and b.ok and RulesJson.digest(a.candidate)==RulesJson.digest(b.candidate),"seek previews are reproducible and do not write")
 check(FileAccess.get_file_as_string(service.store._slot_path(slot))==original,"generation preview preserves exact save")
 var faulty := FaultStore.new();faulty.save_root=service.store.save_root;service.store=faulty
 for mode in ["write","reload"]:
  faulty.fault=mode
  reject("cycle_seek")
  check(not FileAccess.file_exists(service._journal(slot)),"failed seek rolled back without abandoned journal")
 faulty.fault=""
 action("cycle_seek")
 reject("cycle_seek",{"revision":state.expedition.revision-1})
 var pin: Dictionary= state.mechanics.rules_ref.duplicate(true);var policy: String= state.character_builder.policy_sha
 travel(0);action("cycle_return")
 var record_hash: String= cycle().base_sha
 check(cycle().results.is_empty(),"unfinished return creates no reward")
 travel(0);reject("cycle_seek");check(cycle().base_sha==record_hash,"unfinished report retains the same identity")
 var options := OpportunityCycles.choices(state,SandboxRecords.site(cycle(),cycle().active.site_id))
 var skills: Array=options.filter(func(o: Dictionary):return o.id.begins_with("skill:"))
 check(not skills.is_empty(),"real skills provide mechanical noncombat options")
 var previews := OpportunityCycles.choices(state,SandboxRecords.site(cycle(),cycle().active.site_id))
 check(RulesJson.digest(previews)==RulesJson.digest(options),"skill check seed does not reroll on preview")
 action("cycle_activity",{"choice":"quick"})
 check(CharacterBuilderRecords.xp(state,state.party_ids[0])==0,"partial recovery earns no XP")
 action("cycle_return")
 travel(1);action("cycle_activity",{"choice":"careful"})
 check(CharacterBuilderRecords.xp(state,state.party_ids[0])==10,"successful investigation earns one objective reward")
 var before := FileAccess.get_file_as_string(service.store._slot_path(slot))
 var after := before
 # Exercise published-journal recovery exactly once without a second writer.
 FileAccess.open(service._journal(slot),FileAccess.WRITE).store_string(JSON.stringify({"before":before,"after_sha":after.sha256_text()}))
 var recovered := service.recover(slot,entry.world)
 check(recovered.ok and not FileAccess.file_exists(service._journal(slot)) and FileAccess.get_file_as_string(service.store._slot_path(slot))==after,"published objective journal recovers exactly once")
 reject("cycle_activity",{"choice":"careful"});action("cycle_return")
 travel(2)
 var site := SandboxRecords.site(cycle(),cycle().active.site_id)
 if OpportunityGenerator.template(site.activity_id).family=="contested":
  action("cycle_fight")
  engine.configure(state)
  var battle := AdventureService.active_battle(state)
  var command := engine.enemy_command(battle)
  var expected := engine.command(battle,command)
  action("cycle_command",{"command":command})
  check(AdventureService.active_battle(state).state_hash==expected.battle.state_hash and RulesJson.digest(AdventureService.active_battle(state).rng)==RulesJson.digest(expected.battle.rng),"cycle command preserves pure tactical authority/RNG")
  if failures>0:finish();return
  var replay := service.operate(entry,slot,"resume")
  check(replay.ok and AdventureService.active_battle(replay.state).state_hash==AdventureService.active_battle(state).state_hash,"mid-combat save reload exact")
  for n in 40:
   if failures>0 or engine.current(AdventureService.active_battle(state)).team!="enemy":break
   action("cycle_command",{"command":engine.enemy_command(AdventureService.active_battle(state))})
  battle=AdventureService.active_battle(state)
  action("cycle_command",{"command":{"revision":battle.revision,"actor_id":engine.current(battle).id,"kind":"retreat"}})
  check(cycle().results[site.id].xp_each==0,"actual defeat awards zero objective XP")
 else:action("cycle_activity",{"choice":"leave"})
 action("cycle_return")
 travel(3);action("cycle_activity",{"choice":"leave"});action("cycle_return")
 check(CharacterBuilderRecords.xp(state,state.party_ids[0])==10,"withdrawal awards no XP")
 var old_cycle := RulesJson.digest(cycle())
 action("cycle_seek")
 check(RulesJson.digest(state.adventure_cycles.cycles[0].record)==old_cycle,"historical outcomes remain intact across new reports")
 check(state.mechanics.rules_ref==pin and state.character_builder.policy_sha==policy,"rules and XP policy stay exact")
 for field in ["policy_sha","version"]:
  var bad := state.duplicate(true);bad.adventure_cycles[field]="tampered"
  check(not service.store._validate(bad,entry.world).is_empty(),"bad cycle pin rejected: "+field)
 for mutation in ["xp","result","profile","memory","seed","equipment"]:
  var bad := state.duplicate(true);var first: Dictionary=bad.adventure_cycles.cycles[0]
  if mutation=="xp":first.record.characters[bad.party_ids[0]].xp+=10
  elif mutation=="result":first.record.results.values()[0].xp_each+=10
  elif mutation=="profile":first.context.profiles[bad.party_ids[0]].base_attributes.INT=20
  elif mutation=="memory":bad.adventure_cycles.cycles[1].context.memories={}
  elif mutation=="equipment":bad.mechanics.records[bad.party_ids[0]].equipment=["staff"]
  else:first.record.base.seed="tampered"
  check(not service.store._validate(bad,entry.world).is_empty(),"corrupt/doubled consequence rejected: "+mutation)
 FileAccess.open(base.path_join("negative-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"xp":CharacterBuilderRecords.xp(state,state.party_ids[0]),"cycles":state.adventure_cycles.cycles.size()},"  "))
 finish()
