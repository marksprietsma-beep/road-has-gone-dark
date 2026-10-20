extends "res://tests/supernatural_signatures/mechanics.gd"
## Lawful development fixtures. Earned careers run separately through production services.
func run() -> void:
 base=OS.get_environment("GAME149_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v22.json")
 check(loaded.ok,"v22 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_cohort();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME149_RESTART")=="1":
  var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
  for id in saved.records:
   var d := kernel.derive_character(saved.records[id]);check(d.ok and d.snapshot.snapshot_hash==saved.hashes[id],"exact cold derived history/choices "+id)
   check(RulesJson.digest(saved.records[id])==saved.record_hashes[id],"exact cold known/retrieved/resources "+id)
  for id in saved.battles:
   var engine := TacticalAuras.new(saved.battles[id].units.a.record)
   check(engine.validate(saved.battles[id]).is_empty(),"exact cold legal battle "+id)
   var next := engine.command(saved.battles[id],saved.next[id]);check(next.ok and next.battle.state_hash==saved.after[id],"exact cold command/log/RNG "+id)
  finish_cohort(true);return
 fixtures.fighter=build("fighter",20)
 for cls in ["bard","beguiler","spirit-shaman"]:
  for at in [1,6,12,20]:
   var r := build(cls,at);check(not r.is_empty(),"lawful1/6/12/20 "+cls+str(at));records[cls+str(at)]=r
 if failures:finish_cohort();return
 test_baseline();test_performance();test_refrain();test_illusion();test_retrieval();test_guides();test_mixed();test_low_attributes();test_casting_competition();test_basic_illusions();test_descriptor_guards()
 var hashes := {};var record_hashes := {};var next := {};var after := {}
 for id in records:
  records[id]=RulesJson.string_keys(records[id]);var d := kernel.derive_character(records[id]);check(d.ok,"persist lawful candidate "+id)
  if d.ok:hashes[id]=d.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  check(engine.validate(battles[id]).is_empty(),"fresh battle validates "+id)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var result := engine.command(battles[id],next[id]);check(result.ok,"predict persisted command "+id)
  if result.ok:after[id]=result.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 finish_cohort()
func finish_cohort(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"campaign_xp_injected":false,"classes":["bard","beguiler","spirit-shaman"]}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof));print("GAME149 ",JSON.stringify(proof));get_tree().quit(1 if failures else 0)
func selected_spell(r: Dictionary,id: String) -> Dictionary:
 var result: Dictionary=r.duplicate(true);result.choices.prepared_abilities=[id];result.choices.spell_preparations={}
 check(kernel.validate_build(result).ok,"lawful selected development repertoire "+id);return result
func test_baseline() -> void:
 var old := RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v21.json").ok,"exact frozen21 loads")
 check(not old.definition("statuses","bard-rally-1-status").has("aura") and not old.definition("statuses","bard-rally-1-status").has("upkeep"),"21 rally is a timed snapshot, not a maintained aura")
 check(old.definition("abilities","bard-dirge-1").effects[0].op=="apply_status","21 dirge has no save")
 check(old.definition("abilities","beguiler-beguiling-control-7").effects[0].on_failure.any(func(e: Dictionary):return e.get("id")=="warded"),"21 hostile prismatic failure grants beneficial Warded")
 check(not source.definition("abilities","beguiler-beguiling-control-7").effects[0].on_failure.any(func(e: Dictionary):return e.get("id")=="warded"),"22 preserves21 but removes hostile buff")
func test_performance() -> void:
 for at in [1,6,12,20]:
  var r := alternative(records["bard"+str(at)],{"bard-choice-1":"rally","bard-choice-6":"rally","bard-choice-15":"rally"})
  var engine := TacticalAuras.new(r);var b := encounter(r);var ability: String="bard-rally-6"if at>=6 else"bard-rally-1"
  var before := RulesJson.digest(b);var started := execute(engine,b,ability)
  check(started.ok,"real maintained rally "+str(at))
  if not started.ok:continue
  check(RulesJson.digest(b)==before,"start is pure")
  var active: Dictionary=started.battle;var pool: int=int(active.units.a.record.runtime.resources.performance)
  check(active.budget.main==0 and pool==int(r.runtime.resources.performance)-1,"starting competes for main and finite use")
  check(engine.stats(active.units.b).defence>engine.stats(b.units.b).defence,"live ally receives projected defence")
  var repeated := engine.seal(active.duplicate(true));check(repeated.units.a.record.runtime.resources.performance==pool and repeated.rng==active.rng,"projection spends no resource/RNG")
  var far: Dictionary=active.duplicate(true);far.units.b.position=[7,5];far=engine.seal(far)
  check(engine.stats(far.units.b).defence==engine.stats(b.units.b).defence,"moving out loses aura")
  check(not execute(engine,active,ability).ok,"no second main to restart")
  for i in active.order.size():engine.next_turn(active)
  active=engine.seal(active);check(active.units.a.record.runtime.resources.performance==pool-1 and active.budget.main==1,"own activation pays upkeep once but allows main action")
  var stop := execute(engine,active,"bard-stop-performance");check(stop.ok and stop.battle.budget.main==1 and not has_status(stop.battle.units.a.record,"bard-rally-1-status") and not has_status(stop.battle.units.a.record,"bard-rally-6-status"),"explicit free stop no refund or main cost")
  active.units.a.record.runtime.resources.performance=0
  for i in active.order.size():engine.next_turn(active)
  active=engine.seal(active);check(not active.units.a.record.runtime.statuses.any(func(s: Dictionary):return source.definition("statuses",s.id).has("upkeep")),"zero pool ends maintenance")
  var exhausted: Dictionary=r.duplicate(true);exhausted.runtime.resources.performance=0;check(not use(exhausted,exhausted,ability).ok,"exhausted start rejected")
  battles["bard"+str(at)]=started.battle;records["rally"+str(at)]=r
 var dirge := use(records.bard20,defender(false),"bard-dirge-6");var saved := use(records.bard20,defender(true),"bard-dirge-6")
 check(dirge.ok and saved.ok and has_status(dirge.target,"bard-dirge-6-status") and not has_status(saved.target,"bard-dirge-6-status"),"dirge has real saved enemy control")
func test_refrain() -> void:
 var r := selected_spell(records.bard12,"bard-unbinding-refrain");var target := defender(false)
 target.runtime.statuses.append({"id":"slowed","source":"fixture","remaining":1,"expiry":"target_activation_end"})
 var used := use(r,target,"bard-unbinding-refrain")
 check(used.ok and not has_status(used.target,"slowed") and used.target.runtime.hp==target.runtime.hp,"tier3 relief differs from lightning damage")
 check(used.ok and used.actor.runtime.resources["bard-slots-3"]==r.runtime.resources["bard-slots-3"]-1 and used.budget.main==0,"relief costs real slot/main")
 var unknown: Dictionary=r.duplicate(true);unknown.choices.prepared_abilities=[];check(not use(unknown,target,"bard-unbinding-refrain").ok,"unknown spontaneous relief rejected")
 var low: Dictionary=selected_spell(records.bard1,"bard-spark") if source.definition("abilities","bard-spark").size()>0 else records.bard1
 check(not use(low,target,"bard-unbinding-refrain").ok,"low character cannot use higher spell")
 records.bard_refrain=r
func test_illusion() -> void:
 for at in [6,12,20]:
  var r := selected_spell(records["beguiler"+str(at)],"beguiler-unmasking-chime");var target := defender(false)
  target.runtime.statuses.append({"id":"beguiling-veil","source":"fixture","remaining":3,"expiry":"global_round_start"})
  var revealed := use(r,target,"beguiler-unmasking-chime");check(revealed.ok and not has_status(revealed.target,"beguiling-veil") and revealed.target.runtime.hp==target.runtime.hp,"selected nondamaging counter concealment "+str(at))
  var resistant := defender(true);resistant.runtime.statuses=target.runtime.statuses.duplicate(true)
  var saved := use(r,resistant,"beguiler-unmasking-chime");check(saved.ok and has_status(saved.target,"beguiling-veil"),"Will save preserves real concealment")
  check(revealed.ok and revealed.actor.runtime.resources["beguiler-slots-2"]==r.runtime.resources["beguiler-slots-2"]-1,"saved or failed cast spends matching slot")
  var engine := TacticalAuras.new(r);var b := encounter(r);target.character_id="bandit-blade";b.units["bandit-blade"].record=target;b=engine.seal(b)
  var casted := execute(engine,b,"beguiler-unmasking-chime","bandit-blade");check(casted.ok and not has_status(casted.battle.units["bandit-blade"].record,"beguiling-veil"),"actual tactical unmask uses spell save, not weapon concealment")
  check(not engine.eligible(b,b.units.a,b.units.b,"beguiler-unmasking-chime"),"hostile counter cannot hit ally")
  battles["beguiler"+str(at)]=casted.battle if casted.ok else b;records["unmask"+str(at)]=r
 var late := selected_spell(records.beguiler20,"beguiler-beguiling-control-7");var outcome := use(late,defender(false),"beguiler-beguiling-control-7")
 check(outcome.ok and has_status(outcome.target,"prismatic-fracture") and not has_status(outcome.target,"warded"),"late failure harms enemy without granting defence")
func test_retrieval() -> void:
 var before: Dictionary=records["spirit-shaman12"].duplicate(true);before.choices.prepared_abilities=["spirit-shaman-spirit-rebuke-1"];before.runtime.resources["spirit-shaman-slots-1"]=0
 var after: Dictionary=before.duplicate(true);after.choices.prepared_abilities=["spirit-shaman-spirit-refuge-1"]
 var pool: String=source.definition("classes","spirit-shaman").retrieval_resource
 check(kernel.validate_build(before).ok and kernel.validate_build(after).ok,"two legitimate retrieved repertoires")
 check(RulesWaveFive.commit_retrieval(before,after,source).ok and after.runtime.resources[pool]==before.runtime.resources[pool]-1,"existing retrieval consumes one permit")
 check(after.runtime.resources["spirit-shaman-slots-1"]==0,"retrieval never restores spent spell slot")
 var again: Dictionary=after.duplicate(true);again.choices.prepared_abilities=before.choices.prepared_abilities.duplicate()
 check(not RulesWaveFive.commit_retrieval(after,again,source).ok,"cannot exchange again without eligible rest")
 var same: Dictionary=after.duplicate(true);check(RulesWaveFive.commit_retrieval(after,same,source).ok and same.runtime.resources==after.runtime.resources,"unchanged selection is free and order independent")
 var caps: Dictionary=kernel.derive_character(after).snapshot.resource_capacities
 var no_rest := RulesEffects.new(source).refresh_resources(after.runtime,caps,"encounter")
 check(no_rest.runtime.resources[pool]==0,"encounter boundary does not refresh retrieval")
 var rested := RulesEffects.new(source).refresh_resources(after.runtime,caps,"eligible_rest")
 check(rested.runtime.resources[pool]==1 and rested.runtime.resources["spirit-shaman-slots-1"]==caps["spirit-shaman-slots-1"],"eligible rest recovers permit and actual shared slots")
 records.retrieved=after
func test_guides() -> void:
 for at in [1,6,12,20]:
  for guide in ["hearth","watcher","storm"]:
   var picks := {}
   for n in [1,5,10,15,20]:picks["spirit-guide-"+str(n)]=guide
   var r := alternative(records["spirit-shaman"+str(at)],picks);var tier: int=20 if at==20 else 10 if at>=10 else 5 if at>=5 else 1
   var target := defender(false);var action: String="spirit-guide-"+guide+"-"+str(tier)
   target.runtime.hp=maxi(1,int(target.runtime.hp)-15)
   var result := use(r,target,action);check(result.ok,"actual selected guide "+guide+str(at))
   if result.ok:check(result.actor.runtime.resources["spirit-favour"]==r.runtime.resources["spirit-favour"]-int(source.definition("abilities",action).cost.resources["spirit-favour"]),"guide spends favour not spell slot")
   var other: String="watcher"if guide=="storm"else"storm";check(not use(r,target,"spirit-guide-"+other+"-1").ok,"unselected guide cannot execute")
   records[guide+str(at)]=r
   if at in [1,12,20]:
    var engine := TacticalAuras.new(r);var b := encounter(r);var target_id: String="bandit-blade"if guide=="storm"else"b"
    b.units[target_id].record.runtime.hp=maxi(1,int(b.units[target_id].record.runtime.hp)-2);b=engine.seal(b)
    var casted := execute(engine,b,action,target_id);check(casted.ok,"actual tactical spirit guide "+guide+str(at))
    if casted.ok:battles["spirit-"+guide+str(at)]=casted.battle
func test_mixed() -> void:
 var r := build("bard",4)
 for n in 4:
  var choice := kernel.suggested_choice(r,"beguiler","");check(choice.ok,"multiclass choice")
  if not choice.ok:return
  var advanced := kernel.preview_advancement(r,choice.choice);check(advanced.ok,"mixed history")
  if not advanced.ok:return
  r=advanced.candidate
 check(kernel.derive_character(r).snapshot.class_levels.bard==4 and kernel.derive_character(r).snapshot.class_levels.beguiler==4,"ordered distinct caster histories")
 records.mixed=r

func test_low_attributes() -> void:
 for cls in ["bard","beguiler","spirit-shaman"]:
  var attrs := {"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8}
  var attr: String="CHA"if cls=="bard"else"INT"if cls=="beguiler"else"WIS"
  var swap: int=int(attrs[attr]);attrs.CHA=swap;attrs[attr]=8
  var r := build_with_feats(cls,20,{},attrs)
  check(not r.is_empty(),"lawful low-attribute advanced history "+cls)
  records["low-"+cls]=r

func test_casting_competition() -> void:
 var r := selected_spell(alternative(records.bard12,{"bard-choice-1":"rally","bard-choice-6":"rally","bard-choice-15":"rally"}),"bard-unbinding-refrain")
 var engine := TacticalAuras.new(r);var b := encounter(r);var started := execute(engine,b,"bard-rally-6")
 check(started.ok,"rally/spell shared authority")
 if not started.ok:return
 check(not execute(engine,started.battle,"bard-unbinding-refrain","b").ok,"starting a rally competes with casting")
 var active: Dictionary=started.battle
 for i in active.order.size():engine.next_turn(active)
 active=engine.seal(active);var cost: int=int(active.units.a.record.runtime.resources.performance)
 var casted := execute(engine,active,"bard-unbinding-refrain","b")
 check(casted.ok and has_status(casted.battle.units.a.record,"bard-rally-6-status") and casted.battle.units.a.record.runtime.resources.performance==cost,"later spell works during maintained song without a second upkeep")
 var formed: Dictionary=r.duplicate(true);formed.runtime.statuses.append({"id":"leopard-form","source":"fixture","remaining":3,"expiry":"global_round_start"})
 check(not use(formed,formed,"bard-rally-6").ok,"transformed body cannot start vocal rally")
 var down: Dictionary=started.battle.duplicate(true);down.units.a.record.runtime.hp=0;down=engine.seal(down)
 check(not has_status(down.units.a.record,"bard-rally-6-status") and engine.stats(down.units.b).defence==engine.stats(b.units.b).defence,"defeated performer loses aura immediately")
 var ended: Dictionary=started.battle.duplicate(true);ended.status="victory";ended=engine.seal(ended)
 check(not has_status(ended.units.a.record,"bard-rally-6-status"),"battle end clears maintained state")
 records.performance_caster=r;battles.performance_cast=casted.battle if casted.ok else active

func test_basic_illusions() -> void:
 for at in [1,6,12,20]:
  var r := selected_spell(records["beguiler"+str(at)],"beguiler-beguiling-control-1")
  var failed := use(r,defender(false),"beguiler-beguiling-control-1");var saved := use(r,defender(true),"beguiler-beguiling-control-1")
  check(failed.ok and saved.ok and has_status(failed.target,"beguiling-doubt") and not has_status(saved.target,"beguiling-doubt"),"original early/mid/late doubt has save counterplay "+str(at))
  r=selected_spell(r,"beguiler-beguiling-ward-1");var veil := use(r,r,"beguiler-beguiling-ward-1")
  check(veil.ok and kernel.derive_character(veil.actor).snapshot.capabilities.concealment==25,"owned allied illusion has real weapon concealment "+str(at))

func test_descriptor_guards() -> void:
 var errors: Array=[]
 RulesMartial.validate_definition("statuses",{"id":"forged","stance_group":"unknown-group"},{},errors)
 check(not errors.is_empty(),"unknown exclusive group still rejects")
 errors=[];RulesMartial.validate_definition("statuses",{"id":"forged","stance_group":"maintained-performance"},{},errors)
 check(not errors.is_empty(),"maintained group without declared upkeep rejects")
 errors=[];RulesWaveFour.validate_definition("statuses",{"id":"forged","aura":{},"upkeep":{"resource":"performance","amount":0}},{},errors)
 check(not errors.is_empty(),"zero-cost upkeep descriptor rejects")
