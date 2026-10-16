extends "res://tests/character_psychic/capture_driver.gd"
## Genuine earned campaign views; high-level mechanics fixtures are explicitly labelled.
func run() -> void:
 base=OS.get_environment("GAME112W5_CAPTURE_ROOT");DirAccess.make_dir_recursive_absolute(base)
 var input := OS.get_environment("GAME112W5_SOURCE_ROOT")
 var earned_root := input.path_join("earned")
 var proof: Dictionary=WorldOriginLore.read_json(earned_root.path_join("proof.json"));slot=proof.slot
 service.library.library_root=earned_root.path_join("library");entry=service.library.discover()[0]
 service.cache_root=base.path_join("cache");service.store.save_root=earned_root.path_join("saves");service.library.save_root=service.store.save_root
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual earned Abjurant Champion reload")
 if not loaded.ok:finish();return
 state=loaded.state
 var original: Dictionary=state.duplicate(true)
 service.store.save_root=base.path_join("earned-copy");service.library.save_root=service.store.save_root
 check(service.store.save_new(slot,state,entry.world).ok,"original writer isolates earned render interactions")
 await capture("earned-abjurant-reloaded-sheet","sheet",2)
 await capture("earned-prestige-next-choice","sheet",3)
 await spirit_view("earned-spirit-retrieval-spent")
 action("cycle_seek")
 var found := false
 for i in 4:
  if OpportunityGenerator.template(cycle().base.sites[i].activity_id).family!="contested":continue
  travel(i);action("cycle_fight");found=true;break
 check(found,"ordinary generated combat for real channel demonstration")
 if found:
  engine=TacticalAuras.new(state)
  var owner_id: String=state.party_ids[0];var performed := false
  for n in 100:
   var battle := AdventureService.active_battle(state)
   if battle.status!="active":break
   var actor := engine.current(battle)
   var command := {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
   if actor.team=="enemy":command=engine.enemy_command(battle)
   elif actor.id==owner_id and int(battle.budget.main)>0:
    var ability := "channel-duskblade-searing-grasp"
    var targets: Array=battle.order.filter(func(id: String):return battle.units[id].team=="enemy" and engine.alive(battle.units[id]))
    for id in targets:
     if engine.eligible(battle,actor,battle.units[id],ability):command.kind=ability;command.target_id=id;break
    if command.kind=="end" and int(battle.budget.move)>0:
     var paths: Array=engine.paths(battle,actor).values()
     paths.sort_custom(func(a: Array,b: Array):return a.size()<b.size() if a.size()!=b.size() else str(a.back())<str(b.back()))
     for path in paths:
      var proposed: Dictionary=actor.duplicate(false);proposed.position=path.back()
      if targets.any(func(id: String):return engine.eligible(battle,proposed,battle.units[id],ability)):
       command.kind="move";command.destination=path.back();break
    if command.kind==ability and int(battle.budget.main)>0:
     await capture("earned-channel-before-attack","combat")
     var before := battle.duplicate(true)
     action("cycle_command",{"command":command})
     var after := AdventureService.active_battle(state)
     check(after.units[owner_id].record.runtime.resources["duskblade-slots-1"]==before.units[owner_id].record.runtime.resources["duskblade-slots-1"]-1,"rendered saved channel spends exactly one slot")
     await capture("earned-channel-resolved","combat");performed=true;break
   action("cycle_command",{"command":command})
   if failures:break
  check(performed,"real generated campaign channel action rendered")
 # Exact high-level mechanics fixtures; no production XP grants or invented earned claims.
 var saved: Dictionary=WorldOriginLore.read_json(input.path_join("saved.json"))
 for cls in ["duskblade","spirit-shaman","abjurant-champion","grove-warden"]:
  var fixture: Dictionary=original.duplicate(true);var id: String=fixture.party_ids[0]
  var record: Dictionary=saved.records[cls].duplicate(true);record.character_id=id
  record.equipment=RulesRecords.registry(fixture).definition("classes",record.advancement_history[0].class_id).recommended_equipment.duplicate()
  fixture.mechanics.records[id]=record;fixture.character_builder.initial_levels[id]=record.advancement_history.size()
  var store := GamePlaythroughStore.new();store.save_root=base.path_join("fixtures/"+cls)
  var wrote := store.save_new(slot,fixture,entry.world)
  check(wrote.ok,"writer-owned labelled advanced character "+cls+str(wrote.get("error","")))
  if wrote.ok:await advanced_capture(fixture,store.save_root,cls)
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source_commit":OS.get_environment("GAME112W5_SOURCE_SHA"),"screenshots":screenshots,"ordinary_earned_xp":proof.earned_xp,"advanced_fixtures_earned":false}))
 finish()
func spirit_view(name: String) -> void:
 var ui := await open_screen("res://scenes/ui/character_sheet.tscn")
 if ui==null:return
 ui.selected=2;ui.refresh();ui.detail_tabs.current_tab=4
 var record: Dictionary=ui.state.mechanics.records[ui.state.party_ids[1]]
 check(int(record.runtime.resources["spirit-retrieval"])==0,"actual persisted exhausted retrieval permit displayed")
 check(not ui.spellbook.controls.is_empty() and ui.spellbook.controls.values().all(func(c: Control):return c.disabled),"production retrieval controls locked until rest")
 await screenshot(name,false)
 await close_screen()
