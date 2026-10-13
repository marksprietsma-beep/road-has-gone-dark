extends "res://tests/adventure_cycles/earned_driver.gd"
func run() -> void:
 base=OS.get_environment("GAME121_TEST_ROOT");DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 var original: Dictionary=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/map_icons/existing-game99-save.json")))
 entry=service.library.discover().filter(func(row: Dictionary):return row.world.source_sha256==original.world_ref.sha256)[0]
 slot=original.playthrough_id
 DirAccess.make_dir_recursive_absolute(service.store.save_root)
 FileAccess.open(service.store._slot_path(slot),FileAccess.WRITE).store_buffer(FileAccess.get_file_as_bytes("res://tests/map_icons/existing-game99-save.json"))
 var cache := service.cache_root.path_join(original.world_ref.sha256);DirAccess.make_dir_recursive_absolute(cache)
 var packet := cache.path_join(str(int(original.origin.home_burg_id))+".json")
 FileAccess.open(packet,FileAccess.WRITE).store_buffer(FileAccess.get_file_as_bytes("res://tests/map_icons/existing-game99-packet.json"))
 FileAccess.open(packet+".sha",FileAccess.WRITE).store_string(FileAccess.get_sha256(packet))
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,str(resumed.get("error","")));state=resumed.state
 check(FileAccess.get_file_as_bytes(service.store._slot_path(slot))==FileAccess.get_file_as_bytes("res://tests/map_icons/existing-game99-save.json"),"legacy Resume retains exact original bytes")
 var saved_results := RulesJson.digest(state.sandbox.results)
 var ids: Array=state.party_ids.duplicate();var pin: Dictionary=state.mechanics.rules_ref.duplicate(true)
 engine.configure(state)
 for site in state.sandbox.base.sites:
  if state.sandbox.results.has(site.id):continue
  action("sandbox_accept",{"lead":site.id})
  if state.sandbox.knowledge[site.id]=="rumoured":action("sandbox_scout")
  action("sandbox_travel");action("sandbox_fight")
  for n in 30:
   var b := AdventureService.active_battle(state)
   if engine.current(b).team=="party":
    action("sandbox_command",{"command":{"revision":b.revision,"actor_id":engine.current(b).id,"kind":"retreat"}});break
   action("sandbox_command",{"command":engine.enemy_command(b)})
  action("sandbox_return")
 var archived := RulesJson.digest(state.sandbox)
 check(state.sandbox.results.size()==4,"old remaining encounter resolves normally")
 for id in original.sandbox.results:check(RulesJson.digest(state.sandbox.results[id])==RulesJson.digest(original.sandbox.results[id]),"previous terminal result unchanged")
 action("cycle_seek")
 check(RulesJson.digest(state.sandbox)==archived,"cycle extension leaves entire historical sandbox unchanged")
 check(state.mechanics.rules_ref==pin and state.party_ids==ids,"old mechanical pin and identities preserved")
 check(CharacterBuilderRecords.threshold(2,state)==20,"old campaign retains original XP thresholds")
 travel(0);action("cycle_activity",{"choice":"careful"});action("cycle_return")
 check(RulesJson.digest(state.sandbox)==archived,"new reward cannot rewrite old outcomes or XP")
 check(OpportunityCycles.xp(state,ids[0])==10,"new objective reward stored separately")
 var reload := service.operate(entry,slot,"resume")
 check(reload.ok and RulesJson.digest(reload.state)==RulesJson.digest(state),"old campaign and new history reload together")
 FileAccess.open(base.path_join("legacy-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":pin,"old_sandbox_sha":archived,"new_xp":OpportunityCycles.xp(state,ids[0]),"old_policy_level2":CharacterBuilderRecords.threshold(2,state)},"  "))
 finish()
