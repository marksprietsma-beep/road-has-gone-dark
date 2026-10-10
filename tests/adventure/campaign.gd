extends SceneTree
var checks := 0
var failures := 0
var service := AdventureService.new()
var base: String
var entry := {}
var engine := TacticalCombat.new()
func check(value: bool,why: String) -> void:
 checks+=1
 if not value: failures+=1;push_error(why)
func _initialize() -> void: call_deferred("run")
func action(slot: String,state: Dictionary,operation: String,extra: Dictionary={}) -> Dictionary:
 var changes := {"revision":state.expedition.revision};changes.merge(extra)
 var result := service.operate(entry,slot,operation,1,changes)
 check(result.ok,operation+": "+str(result.get("error","")))
 if not result.ok: quit(1)
 return result.get("state",state)
func create_campaign() -> Dictionary:
 var world: GameWorldTemplate=entry.world
 var profiles := OriginProfiles.new();check(profiles.load_world(world),profiles.error)
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var created := service.store.create_playthrough(world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(created.ok,"create real origin")
 var slot: String=created.state.playthrough_id
 check(service.store.save_new(slot,created.state,world).ok,"save origin")
 var party := PartyService.new();party.store=service.store;party.library=service.library
 var generated := party.operate(entry,slot,"generate");check(generated.ok,str(generated.get("error")))
 if not generated.ok: return {}
 for i in 3:
  var selected := party.operate(entry,slot,"edit",i+1,{"role_id":["vanguard","scout","adept"][i]})
  check(selected.ok,"select existing narrative role")
 var ready := party.operate(entry,slot,"ready");check(ready.ok,"ready existing identities")
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,str(resumed.get("error")))
 if not resumed.ok: return {}
 var state: Dictionary=resumed.state
 var historical := state.duplicate(true)
 state=action(slot,state,"prepare_adventure")
 if not state.has("first_adventure"): return {}
 var detached := state.duplicate(true);detached.erase("first_adventure");detached.erase("mechanics")
 check(detached==historical,"character life and mechanics are additive; origin/narrative/expedition unchanged")
 check(state.party.members[0].name==historical.party.members[0].name,"existing names retained")
 var lead: Dictionary=state.expedition.leads[0]
 state=action(slot,state,"accept",{"lead":lead.id})
 state=action(slot,state,"depart",{"lead":lead.id})
 if state.expedition.knowledge[lead.site_id]=="rumoured": state=action(slot,state,"scout")
 state=action(slot,state,"travel")
 return state
func command_for(b: Dictionary) -> Dictionary:
 var input := engine.enemy_command(b)
 var actor := engine.current(b)
 if actor.team=="party" and engine.characters.derive_character(actor.record).snapshot.abilities.has("spark") and int(b.budget.main)>0:
  for id in b.order:
   if engine.eligible(b,actor,b.units[id],"spark"):
    input.kind="spark";input.target_id=id;input.erase("destination");break
 return input
func run() -> void:
 base=OS.get_environment("ADVENTURE_TEST_ROOT")
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 var phase := OS.get_environment("ADVENTURE_PHASE")
 if phase=="create":
  var state := create_campaign()
  if state.is_empty(): finish();return
  var slot: String=state.playthrough_id
  check(AdventureRecords.identity(state,state.party.members[0]).hook.contains("Worries"),"meaningful source-backed hook")
  state=action(slot,state,"begin_battle")
  if state.first_adventure.battle.is_empty(): finish();return
  var b: Dictionary=state.first_adventure.battle
  var before_bytes := FileAccess.get_file_as_string(service.store._slot_path(slot))
  var invalid := service.operate(entry,slot,"return",1,{"revision":state.expedition.revision})
  check(not invalid.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==before_bytes,"cannot bypass active battle by returning")
  state=action(slot,state,"battle_command",{"command":command_for(b)})
  var copy: Dictionary=state.first_adventure.battle.duplicate(true)
  for i in 600:
   if copy.status!="active": break
   copy=engine.command(copy,command_for(copy)).battle
  check(copy.status=="victory","real source party can win fixed encounter")
  var file := FileAccess.open(base.path_join("metadata.json"),FileAccess.WRITE)
  file.store_string(JSON.stringify({"slot":slot,"paused_hash":RulesJson.digest(state),"expected_battle_hash":copy.state_hash}))
 else:
  var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("metadata.json")))
  var loaded := service.operate(entry,metadata.slot,"resume");check(loaded.ok,str(loaded.get("error")))
  if not loaded.ok: finish();return
  var state: Dictionary=loaded.state
  check(RulesJson.digest(state)==metadata.paused_hash,"whole encounter survives separate Godot process restart")
  var initial_record: Dictionary = state.party.duplicate(true)
  var slot: String=metadata.slot
  var old_command := command_for(state.first_adventure.battle)
  for i in 600:
   if state.first_adventure.battle.status!="active": break
   state=action(slot,state,"battle_command",{"command":command_for(state.first_adventure.battle)})
  check(state.first_adventure.result.outcome=="victory","saved encounter victory")
  check(state.first_adventure.battle.state_hash==metadata.expected_battle_hash,"save/reload on every action preserves uninterrupted outcome hash")
  check(state.party==initial_record,"battle never rewrites life identities")
  check(state.expedition.active.phase=="result" and state.world_deltas[state.first_adventure.result.site_id].first_adventure=="victory","victory connects site and world memory")
  for c in state.first_adventure.characters.values(): check(c.xp==10 and c.history.size()==1,"exactly one XP/history award")
  check(state.first_adventure.consequence_hooks.size()==4,"four future consequence hooks saved")
  var bytes := FileAccess.get_file_as_string(service.store._slot_path(slot))
  var duplicate := service.operate(entry,slot,"battle_command",1,{"revision":state.expedition.revision,"command":old_command})
  check(not duplicate.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==bytes,"duplicate/stale command cannot reward again")
  state=action(slot,state,"resolve_battle")
  check(FileAccess.get_file_as_string(service.store._slot_path(slot))==bytes,"duplicate result leaves exact bytes unchanged")
  state=action(slot,state,"return")
  check(state.expedition.active.is_empty() and state.expedition.leads[0].status=="completed","victory return closes lead")
  check(service.store.load_save(slot,entry.world).ok,"returned victory reload validates")
  var failed := create_campaign()
  if failed.is_empty(): finish();return
  var failed_slot: String=failed.playthrough_id
  failed=action(failed_slot,failed,"begin_battle")
  var b: Dictionary=failed.first_adventure.battle
  # Let any deterministic enemy opening play before choosing the player retreat.
  while engine.current(b).team=="enemy":
   failed=action(failed_slot,failed,"battle_command",{"command":engine.enemy_command(b)});b=failed.first_adventure.battle
  failed=action(failed_slot,failed,"battle_command",{"command":{"revision":b.revision,"actor_id":engine.current(b).id,"kind":"retreat"}})
  check(failed.first_adventure.result.outcome=="defeat" and failed.first_adventure.characters.values().all(func(c: Dictionary):return c.xp==0 and c.history.size()==1),"defeat has clear history and no victory XP")
  check(failed.mechanics.records.values().all(func(r: Dictionary):return r.runtime.hp>=1),"minimal recovery provides a continuing party")
  failed=action(failed_slot,failed,"return")
  check(failed.expedition.active.is_empty() and failed.expedition.leads[0].status=="withdrawn","defeat returns with unresolved lead")
  check(service.store.load_save(failed_slot,entry.world).ok,"defeat return reload validates")
  var unresolved: Dictionary=failed.expedition.leads[0]
  failed=action(failed_slot,failed,"accept",{"lead":unresolved.id})
  failed=action(failed_slot,failed,"depart",{"lead":unresolved.id})
  failed=action(failed_slot,failed,"travel")
  failed=action(failed_slot,failed,"record")
  check(failed.world_deltas[unresolved.site_id].first_adventure=="defeat" and failed.first_adventure.characters.values().all(func(c: Dictionary):return c.history.size()==1),"subsequent investigation preserves battle memory")
  failed=action(failed_slot,failed,"return")
  var ui_state := create_campaign()
  var file := FileAccess.open(base.path_join("ui.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"slot":ui_state.playthrough_id}))
 finish()
func finish() -> void:
 print(JSON.stringify({"suite":"campaign","phase":OS.get_environment("ADVENTURE_PHASE"),"checks":checks,"failures":failures}))
 quit(1 if failures else 0)
