extends "res://tests/character_completeness/journey_driver.gd"
## Fork an actually earned campaign through the one production save writer.
## Exercise new spells via campaign commands, cold battle restart and return.
var connected_folder := ""
var performed := {}
func run() -> void:
 var earned_base := OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0")
 connected_folder=OS.get_environment("GAME133_CONNECTED_ROOT")
 if connected_folder.is_empty():connected_folder=OS.get_environment("GAME133_ROOT").get_base_dir().path_join("connected")
 DirAccess.make_dir_recursive_absolute(connected_folder)
 service.library.library_root=earned_base.path_join("library");service.cache_root=earned_base.path_join("cache")
 entry=service.library.discover()[0];var earned := WorldOriginLore.read_json(earned_base.path_join("proof.json"));slot=earned.slot
 service.store.save_root=connected_folder.path_join("saves");service.library.save_root=service.store.save_root
 if OS.get_environment("GAME133_RESTART")=="1":
  var saved := WorldOriginLore.read_json(connected_folder.path_join("proof.json"))
  var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"cold connected campaign "+str(loaded.get("error","")))
  if not loaded.ok:finish_connected(true);return
  state=loaded.state;source=RulesRecords.registry(state);kernel=RulesCharacter.new(source)
  var battle := AdventureService.active_battle(state);var tactical := TacticalAuras.new(state)
  check(RulesJson.digest(state)==saved.state_hash and battle.state_hash==saved.battle_hash,"exact full campaign and active battle after process restart")
  for id in saved.casts:
   var spell: String=saved.casts[id];var a := source.definition("abilities",spell)
   for pool in a.cost.resources:check(int(battle.units[id].record.runtime.resources[pool])==int(saved.resources[id][pool]),"spent slot/copy survives actual campaign restart "+pool)
  var expected := tactical.command(battle,saved.next_command)
  check(expected.ok and expected.battle.state_hash==saved.next_hash,"cold next command/log/RNG matches prediction")
  action(saved.command_operation,{"command":saved.next_command})
  check(AdventureService.active_battle(state).state_hash==saved.next_hash,"cold campaign command uses exact deterministic authority")
  for n in 250:
   battle=AdventureService.active_battle(state)
   if battle.status!="active":break
   action(saved.command_operation,{"command":tactical.enemy_command(battle)})
   if failures:finish_connected(true);return
  battle=AdventureService.active_battle(state)
  check(battle.status in ["victory","defeat"],"connected battle resolves normally")
  var xp: int=490+(10 if battle.status=="victory" else 0)
  for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==xp,"only normal victory reward, no fixture XP")
  reject(saved.command_operation,{"command":saved.next_command})
  var before_rest := {}
  for id in saved.casts:
   var spell := source.definition("abilities",saved.casts[id]);before_rest[id]={}
   for pool in spell.cost.resources:
    before_rest[id][pool]=state.mechanics.records[id].runtime.resources[pool]
    check(before_rest[id][pool]==saved.resources[id][pool],"resolved campaign owns exact spent spell resources "+pool)
  if saved.command_operation=="battle_command":
   action("return")
   if cycle().results.size()==4:action("cycle_seek")
   var unfinished := -1
   for i in cycle().base.sites.size():
    if not cycle().results.has(cycle().base.sites[i].id):unfinished=i;break
   check(unfinished>=0,"unresolved real opportunity exists for return/rest")
   if unfinished<0:finish_connected(true);return
   travel(unfinished)
  action("cycle_return")
  for id in saved.casts:
   var snapshot: Dictionary=kernel.derive_character(state.mechanics.records[id]).snapshot
   for pool in before_rest[id]:check(int(state.mechanics.records[id].runtime.resources[pool])==int(snapshot.resource_capacities[pool]),"real return restores slot/copy "+pool)
   check(CharacterBuilderRecords.xp(state,id)==xp,"rest never grants XP")
  var resumed := service.operate(entry,slot,"resume")
  check(resumed.ok and RulesJson.digest(resumed.state)==RulesJson.digest(state),"resolved/rested campaign reload exact through production writer")
  finish_connected(true);return
 var original := GamePlaythroughStore.new();original.save_root=earned_base.path_join("saves")
 var loaded := original.load_save(slot,entry.world);check(loaded.ok,"load earned490XP primary campaign "+str(loaded.get("error","")))
 if not loaded.ok:finish_connected();return
 state=loaded.state;source=RulesRecords.registry(state);kernel=RulesCharacter.new(source)
 check(service.store.save_new(slot,state,entry.world).ok,"fork uses existing campaign writer, no edits to identities/history/XP")
 var index := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id) and OpportunityGenerator.template(cycle().base.sites[i].activity_id).family=="contested":index=i;break
 if index>=0:travel(index);action("cycle_fight")
 else:
  # Peacefully resolved occupations stay peaceful. Use the untouched original
  # Old Road lead instead of rerolling world truth or resurrecting occupants.
  action("prepare_adventure")
  var lead: Dictionary=state.expedition.leads[0]
  action("accept",{"lead":lead.id});action("depart",{"lead":lead.id})
  if state.expedition.knowledge[lead.site_id]=="rumoured":action("scout")
  action("travel");action("begin_battle")
 var command_operation: String=AdventureService.command_operation(state)
 var tactical := TacticalAuras.new(state)
 var wanted := {state.party_ids[0]:"sorcerer-crystal-reservoir",state.party_ids[1]:"druid-bramble-tether"}
 for n in 100:
  var battle := AdventureService.active_battle(state)
  if battle.status!="active":break
  var actor := tactical.current(battle);var command := tactical.enemy_command(battle)
  if actor.team=="party" and (not wanted.has(actor.id) or performed.has(actor.id)):
   command={"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
  elif wanted.has(actor.id) and not performed.has(actor.id) and int(battle.budget.main)>0:
   for target in battle.units.values():
    var proposed := {"actor_id":actor.id,"revision":battle.revision,"kind":wanted[actor.id],"target_id":target.id}
    if tactical.eligible(battle,actor,target,wanted[actor.id]) and tactical.command(battle,proposed).ok:command=proposed;break
  var expected := tactical.command(battle,command);check(expected.ok,"pure generated encounter command preview")
  action(command_operation,{"command":command})
  if failures:finish_connected();return
  check(AdventureService.active_battle(state).state_hash==expected.battle.state_hash,"new spell and other actual campaign commands match pure engine")
  if wanted.has(actor.id) and command.kind==wanted[actor.id]:performed[actor.id]=str(command.kind)
  if performed.size()==2:break
 var battle := AdventureService.active_battle(state)
 check(performed.size()==2 and battle.status=="active","both new spells cast and saved during actual active campaign battle")
 var resources := {}
 for id in performed:
  resources[id]={}
  for pool in source.definition("abilities",performed[id]).cost.resources:resources[id][pool]=battle.units[id].record.runtime.resources[pool]
 var next_command := tactical.enemy_command(battle);var expected := tactical.command(battle,next_command)
 check(expected.ok,"connected next-command deterministic prediction")
 var resumed := service.operate(entry,slot,"resume")
 check(resumed.ok and RulesJson.digest(resumed.state)==RulesJson.digest(state),"actual mid-battle save is exact before cold restart")
 FileAccess.open(connected_folder.path_join("active-state.json"),FileAccess.WRITE).store_string(JSON.stringify(state))
 FileAccess.open(connected_folder.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"slot":slot,"state_hash":RulesJson.digest(state),"battle_hash":battle.state_hash,"casts":performed,"resources":resources,"next_command":next_command,"next_hash":expected.get("battle",{}).get("state_hash",""),"earned_xp_before_combat":490,"xp_injected":false,"command_operation":command_operation,"source":"AdventureService/"+command_operation+"/GamePlaythroughStore","scope":"Verification fork of actual earned campaign; primary campaign remains unchanged."}))
 finish_connected()
func finish_connected(restart := false) -> void:
 if restart:FileAccess.open(connected_folder.path_join("restart-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"resolved_and_returned":failures==0}))
 print("GAME133 CONNECTED ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
