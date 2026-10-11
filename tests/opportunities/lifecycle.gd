extends "res://tests/sandbox/lifecycle.gd"
func index_for(family: String) -> int:
 for i in state.sandbox.base.sites.size():
  if OpportunityGenerator.template(state.sandbox.base.sites[i].activity_id).family==family:return i
 return -1
func choose(choice: String) -> void:action("sandbox_activity",{"choice":choice})
func options() -> Array:return OpportunityGenerator.choices(state,SandboxRecords.site(state.sandbox,state.sandbox.active.site_id))
func alternatives() -> void:
 var bytes := FileAccess.get_file_as_bytes(service.store._slot_path(slot))
 var original := state.duplicate(true);var outcomes := {}
 for option in options():
  if option.id=="fight":continue
  var changes := {"revision":state.expedition.revision,"choice":option.id}
  var first := OpportunityAdventure.transition(service,entry,state,"sandbox_activity",changes)
  var repeated := OpportunityAdventure.transition(service,entry,state,"sandbox_activity",changes)
  check(first.ok and repeated.ok and RulesJson.digest(first.candidate)==RulesJson.digest(repeated.candidate),"exact choice replay: "+option.id)
  check(service.store._validate(first.candidate,entry.world).is_empty(),"candidate fully valid: "+service.store._validate(first.candidate,entry.world))
  outcomes[RulesJson.digest(first.candidate.sandbox.actions.back())]=true
 check(outcomes.size()>=3,"meaningfully distinct choice states")
 check(state==original and FileAccess.get_file_as_bytes(service.store._slot_path(slot))==bytes,"preview does not write or consume RNG")
func corruptions() -> void:
 var id: String=state.sandbox.actions[0].site_id
 for field in ["xp_each","provisions_spent","supplies_after","participant","information","battle_hash"]:
  var bad := state.duplicate(true)
  bad.sandbox.actions[0][field]="bad" if field in ["participant","information","battle_hash"] else 99
  check(not service.store._validate(bad,entry.world).is_empty(),"tampered consequence rejected: "+field)
 var bad := state.duplicate(true);bad.sandbox.characters[state.party_ids[0]].xp+=10
 check(not service.store._validate(bad,entry.world).is_empty(),"duplicate reward rejected")
 bad=state.duplicate(true);bad.world_deltas[id].objective_completed=not bad.world_deltas[id].objective_completed
 check(not service.store._validate(bad,entry.world).is_empty(),"world consequence tamper rejected")
func run() -> void:
 SandboxAdventure.legacy_review=false
 base=OS.get_environment("GAME101_TEST_ROOT");DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 var phase := OS.get_environment("GAME101_PHASE")
 if phase=="create":
  campaign();check(state.sandbox.version==OpportunityGenerator.VERSION,"new campaign opts into V2")
  var identities: Dictionary=state.party.duplicate(true)
  travel(index_for("recovery"));alternatives()
  var contributions := options().filter(func(o: Dictionary):return not o.participant.is_empty())
  var selection: String=contributions[0].id if not contributions.is_empty() else "careful"
  var before_revision: int=state.expedition.revision
  choose(selection)
  var result: Dictionary=state.sandbox.results[state.sandbox.active.site_id]
  check(result.xp_each==0 and result.provisions_gained>0 and state.sandbox.encounters.is_empty(),"real recovery, no invented battle victory")
  check(state.party==identities,"persistent character identity unchanged")
  if not contributions.is_empty():check(result.participant==contributions[0].participant and result.provisions_spent==0,"saved profession reduces an actual provision cost")
  reject("sandbox_activity",{"choice":selection,"revision":before_revision});reject("sandbox_activity",{"choice":selection})
  action("sandbox_return")
  travel(index_for("investigation"));alternatives()
  var raw := FileAccess.get_file_as_string(service.store._slot_path(slot))
  var faulty := FaultStore.new();faulty.save_root=service.store.save_root;service.store=faulty
  for mode in ["write","reload"]:
   faulty.fault=mode
   var failed := service.operate(entry,slot,"sandbox_activity",1,{"revision":state.expedition.revision,"choice":"careful"})
   check(not failed.ok and FileAccess.get_file_as_string(faulty._slot_path(slot))==raw,"activity journal exact rollback: "+mode)
  faulty.fault=""
  FileAccess.open(base.path_join("checkpoint.json"),FileAccess.WRITE).store_string(JSON.stringify({"slot":slot,"state_sha":RulesJson.digest(state),"party_ids":state.party_ids,"base_sha":state.sandbox.base_sha}))
 elif phase=="replay":
  var checkpoint: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("checkpoint.json")));slot=checkpoint.slot
  var resumed := service.operate(entry,slot,"resume");check(resumed.ok,str(resumed.get("error","")));state=resumed.state
  check(RulesJson.digest(state)==checkpoint.state_sha,"separate process resumes exact mid-activity save")
  choose("careful");check(state.sandbox.results[state.sandbox.active.site_id].outcome=="investigated","investigation resolves without combat")
  action("sandbox_return")
  travel(index_for("contested"));alternatives();choose("inspect")
  var observed_id: String=state.sandbox.active.site_id
  check(not state.sandbox.results.has(observed_id) and state.sandbox.information[observed_id].size()==1,"inspection preserves unresolved choice with real information")
  reject("sandbox_activity",{"choice":"inspect"})
  action("sandbox_return")
  travel(index_for("contested"));action("sandbox_fight")
  var b := AdventureService.active_battle(state);var c := command(b)
  var pure := engine.command(b,c);action("sandbox_command",{"command":c})
  check(AdventureService.active_battle(state).state_hash==pure.battle.state_hash,"V2 presentation leaves tactical authority/RNG exact")
  checkpoint.battle_hash=AdventureService.active_battle(state).state_hash;checkpoint.rng=AdventureService.active_battle(state).rng
  FileAccess.open(base.path_join("checkpoint.json"),FileAccess.WRITE).store_string(JSON.stringify(checkpoint))
 else:
  var checkpoint: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("checkpoint.json")));slot=checkpoint.slot
  var resumed := service.operate(entry,slot,"resume");check(resumed.ok,str(resumed.get("error","")));state=resumed.state
  check(AdventureService.active_battle(state).state_hash==checkpoint.battle_hash and RulesJson.digest(AdventureService.active_battle(state).rng)==RulesJson.digest(checkpoint.rng),"separate process resumes exact V2 combat/RNG")
  fight_to_result();var result: Dictionary=state.sandbox.results[state.sandbox.active.site_id]
  check(result.xp_each==(10 if result.outcome=="victory" else 0) and not result.battle_hash.is_empty(),"only authoritative combat earns battle XP")
  action("sandbox_return")
  for i in state.sandbox.base.sites.size():
   if not state.sandbox.results.has(state.sandbox.base.sites[i].id):
    travel(i)
    var journal_before := FileAccess.get_file_as_string(service.store._slot_path(slot))
    choose("leave")
    var journal_after := FileAccess.get_file_as_string(service.store._slot_path(slot))
    FileAccess.open(service._journal(slot),FileAccess.WRITE).store_string(JSON.stringify({"before":journal_before,"after_sha":journal_after.sha256_text()}))
    var recovery := service.recover(slot,entry.world)
    check(recovery.ok and journal_before!=journal_after and not FileAccess.file_exists(service._journal(slot)) and FileAccess.get_file_as_string(service.store._slot_path(slot))==journal_after,"interrupted published consequence recovers exactly once")
    action("sandbox_return");break
  check(state.sandbox.results.size()==4 and state.sandbox.base_sha==checkpoint.base_sha and state.party_ids==checkpoint.party_ids,"all sites persisted without reroll/identity changes")
  check(state.sandbox.results.values().any(func(r: Dictionary):return r.outcome=="withdrawn" and r.xp_each==0),"avoidance not counted as defeat of enemies")
  corruptions()
  FileAccess.open(base.path_join("final-state.json"),FileAccess.WRITE).store_string(JSON.stringify(state,"  "))
 var proof := {"phase":phase,"checks":checks,"failures":failures,"base_sha":state.sandbox.base_sha,"results":state.sandbox.results,"actions":state.sandbox.actions,"party_ids":state.party_ids}
 FileAccess.open(base.path_join("lifecycle-"+phase+".json"),FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print("GAME101 LIFECYCLE ",phase," ",checks," / ",failures);quit(1 if failures else 0)
