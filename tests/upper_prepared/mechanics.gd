extends "res://tests/performance_spirit/mechanics.gd"
## Legal upper-tier development histories; earned careers use production services separately.
var upper_casts: Array=[]
func run() -> void:
 base=OS.get_environment("GAME150_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v23.json")
 check(loaded.ok,"v23 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_upper();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME150_RESTART")=="1":
  var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
  for id in saved.records:
   var registry := RulesRecords.registry(saved.records[id]);var d := RulesCharacter.new(registry).derive_character(saved.records[id])
   check(d.ok and d.snapshot.snapshot_hash==saved.hashes[id],"exact independent cold derived state "+id)
   check(RulesJson.digest(saved.records[id])==saved.record_hashes[id],"exact cold history/copies/slots/specialisations "+id)
  for id in saved.battles:
   var engine := TacticalAuras.new(saved.battles[id].units.a.record)
   validate_witness(engine,saved.battles[id],"cold",id)
   var after := engine.command(saved.battles[id],saved.next[id])
   check(after.ok and after.battle.state_hash==saved.after[id],"cold next command/status/HP/log/RNG "+id)
  finish_upper(true);return
 fixtures.fighter=build("fighter",20)
 for cls in ["wizard","cleric"]:
  for at in [1,5,6,14,15,16,17,20]:
   records[cls+str(at)]=build(cls,at)
   check(not records[cls+str(at)].is_empty(),"lawful class progression "+cls+str(at))
 if failures:finish_upper();return
 test_upper_spells();test_main_control();test_periodic_healing();test_specialisations();test_historical();test_upper_hybrids();test_descriptors();test_attributes_and_mitigation();test_repertoire()
 if failures:finish_upper();return
 var hashes := {};var record_hashes := {};var next := {};var after := {}
 for id in records:
  records[id]=RulesJson.string_keys(records[id])
  var registry := RulesRecords.registry(records[id]);var d := RulesCharacter.new(registry).derive_character(records[id])
  check(d.ok,"persist legitimate record "+id)
  if d.ok:hashes[id]=d.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  validate_witness(engine,battles[id],"fresh",id)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var outcome := engine.command(battles[id],next[id]);check(outcome.ok,"predict cold follow-up "+id)
  if outcome.ok:after[id]=outcome.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 finish_upper()

func finish_upper(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_level20":false,"classes":["wizard","cleric"],"executable_spells":upper_casts}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME150 ",JSON.stringify(proof));get_tree().quit(1 if failures else 0)

func prepare_upper(r: Dictionary,id: String,copies := 1) -> Dictionary:
 var result: Dictionary=r.duplicate(true);result.choices.prepared_abilities=[id];result.choices.spell_preparations={id:copies}
 var replay := kernel._replay(result)
 check(replay.ok,"lawful selected prepared fixture "+id+JSON.stringify(replay.get("errors",[])))
 if replay.ok:result.runtime.resources=replay.context.capacities.duplicate()
 return result

func test_upper_spells() -> void:
 for cls in ["wizard","cleric"]:
  for at in [14,15,16,17,20]:
   var available: Array=kernel.derive_character(records[cls+str(at)]).snapshot.abilities
   for tier in [8,9]:
    var required: int=15 if tier==8 else 17
    var id: String=cls+"-"+("unweaving-tide" if tier==8 else "stillness-lattice") if cls=="wizard" else cls+"-"+("concord-release" if tier==8 else "renewing-benediction")
    check(available.has(id)==(at>=required),"actual tier unlock boundary "+cls+str(at)+"/"+str(tier))
 for id in ["wizard-unweaving-tide","wizard-stillness-lattice","cleric-concord-release","cleric-renewing-benediction"]:
  var a := source.definition("abilities",id);var r := prepare_upper(records[a.casting_class+"20"],id)
  var target := defender(false);target.runtime.hp=maxi(1,int(target.runtime.hp)-40)
  var before := RulesJson.digest([r,target]);var casted := use(r,target,id)
  check(casted.ok,"new prepared effect executes "+id+JSON.stringify(casted.get("errors",[])))
  if not casted.ok:continue
  check(before==RulesJson.digest([r,target]),"cast preserves input records "+id)
  check(RulesJson.digest(casted)==RulesJson.digest(use(JSON.parse_string(JSON.stringify(r)),JSON.parse_string(JSON.stringify(target)),id)),"exact deterministic effect replay "+id)
  for pool in a.cost.resources:check(casted.actor.runtime.resources[pool]==r.runtime.resources[pool]-1,"one real copy/shared slot "+pool)
  check(casted.budget.main==0 and casted.budget.move==1,"one main action, movement retained")
  check(not use(casted.actor,target,id).ok,"exhausted prepared copy rejected")
  var empty: Dictionary=r.duplicate(true);empty.runtime.resources[a.casting_class+"-slots-"+str(a.spell_tier)]=0
  check(not use(empty,target,id).ok,"spare copies cannot bypass exhausted tier slots")
  check(not RulesEffects.new(source).use_ability(r,target,id,{"main":0,"move":1,"reaction":1},RulesRng.initial("spent")).ok,"spent main rejects")
  var unprepared: Dictionary=r.duplicate(true);unprepared.choices.prepared_abilities=[];unprepared.choices.spell_preparations={};unprepared.runtime.resources=kernel._replay(unprepared).context.capacities.duplicate()
  check(not use(unprepared,target,id).ok,"unprepared ownership does not permit casting")
  var effects := RulesEffects.new(source);var cap: Dictionary=kernel.derive_character(casted.actor).snapshot.resource_capacities
  check(effects.refresh_resources(casted.actor.runtime,cap,"encounter").runtime.resources==casted.actor.runtime.resources,"no encounter/daily recovery loophole")
  var rested: Dictionary=casted.actor.duplicate(true);rested.runtime=effects.refresh_resources(rested.runtime,cap,"eligible_rest").runtime
  check(use(rested,target,id).ok,"eligible rest recovers matching copy and slot")
  var engine := TacticalAuras.new(r);var b := encounter(r);b.units.b.position=[2,2];b.units.c.position=[1,2];b.rng=RulesRng.initial("wave-four");b=engine.seal(b)
  var enemy: bool=a.targeting.kind=="creature";var target_id: String="bandit-blade" if enemy else "b"
  var tactical := execute(engine,b,id,target_id)
  check(tactical.ok,"actual tactical delivery "+id+str(tactical.get("error","")))
  check(not engine.eligible(b,b.units.a,b.units["b" if enemy else "bandit-blade"],id),"wrong-team targeting rejects "+id)
  b.units[target_id].position=[7,5];b=engine.seal(b);check(not execute(engine,b,id,target_id).ok,"range and sight authority reject unreachable target")
  if tactical.ok:battles[id]=tactical.battle.duplicate(true);records[id]=tactical.battle.units.a.record
  if enemy:
   var saved := use(r,defender(true),id)
   check(saved.ok and saved.events.any(func(e: Dictionary):return e.type=="save_resolved" and e.success),"real Will counterplay "+id)
   if saved.ok:
    for pool in a.cost.resources:check(saved.actor.runtime.resources[pool]==r.runtime.resources[pool]-1,"successful save still costs slot/copy")

func test_main_control() -> void:
 var r := prepare_upper(records.wizard20,"wizard-stillness-lattice");var victim := defender(false)
 var hit := use(r,victim,"wizard-stillness-lattice");check(hit.ok and has_status(hit.target,"stillness-lattice"),"failed Will applies finite main-action control")
 if not hit.ok:return
 var engine := TacticalAuras.new(r);var b := encounter(r)
 hit.target.character_id="bandit-blade";b.units["bandit-blade"].record=hit.target
 b.cursor=(b.order.find("bandit-blade")-1+b.order.size())%b.order.size();engine.next_turn(b);b=engine.seal(b)
 check(engine.current(b).id=="bandit-blade" and b.budget.main==0 and b.budget.move==1,"target activation loses main but retains movement")
 check(not engine.paths(b,engine.current(b)).is_empty(),"Stillness is not immobilisation")
 check(not execute(engine,b,"attack","a").ok,"controlled enemy cannot make a main weapon attack")
 var quick := source.ids("abilities").filter(func(id: String):return source.definition("abilities",id).cost.main==0)
 check(not quick.is_empty() and b.units["bandit-blade"].reaction==1,"shared reaction is not consumed by control")
 var finished := execute(engine,b,"end");check(finished.ok and not has_status(finished.battle.units["bandit-blade"].record,"stillness-lattice"),"one target activation expires control exactly")
 var priest := prepare_upper(records.cleric20,"cleric-concord-release")
 var released := use(priest,hit.target,"cleric-concord-release")
 check(released.ok and not has_status(released.target,"stillness-lattice") and released.target.runtime.hp==hit.target.runtime.hp,"divine release clears control without healing")
 if released.ok:
  var resisted := use(r,released.target,"wizard-stillness-lattice")
  check(resisted.ok and not has_status(resisted.target,"stillness-lattice") and resisted.events.any(func(e: Dictionary):return e.type=="status_resisted"),"actual condition immunity counters a failed save")
  records.release_target=released.target
 battles.controlled=b.duplicate(true)
 var player: Dictionary=records.wizard20.duplicate(true);player.runtime.statuses=hit.target.runtime.statuses.duplicate(true)
 var player_board := encounter(player);RulesMartial.start_activation(engine,player_board);player_board=engine.seal(player_board)
 check(player_board.budget.main==0 and not engine.eligible(player_board,player_board.units.a,player_board.units["bandit-blade"],"attack"),"controlled player has the same action authority as an enemy")
 battles.controlled_player=player_board.duplicate(true)
 var suppressed := prepare_upper(records.cleric20,"cleric-concord-release");suppressed.runtime.statuses=hit.target.runtime.statuses.duplicate(true)
 check(not use(suppressed,suppressed,"cleric-concord-release").ok,"forged full budget cannot bypass main suppression in rules effects")

func test_periodic_healing() -> void:
 var r := prepare_upper(records.cleric20,"cleric-renewing-benediction");var target := defender(false);target.runtime.hp-=60
 var blessed := use(r,target,"cleric-renewing-benediction")
 check(blessed.ok and blessed.target.runtime.hp==target.runtime.hp+20,"divine renewal has a bounded immediate heal")
 if not blessed.ok:return
 var engine := TacticalAuras.new(r);var b := encounter(r);blessed.target.character_id="b";b.units.b.record=blessed.target
 b.cursor=(b.order.find("b")-1+b.order.size())%b.order.size();var before: int=int(b.units.b.record.runtime.hp);var rng := RulesJson.digest(b.rng)
 engine.next_turn(b);b=engine.seal(b)
 check(b.units.b.record.runtime.hp==before+12 and b.budget.main==1 and b.budget.move==1,"own activation heals12 without consuming/granting actions")
 check(RulesJson.digest(b.rng)==rng,"fixed periodic healing consumes no RNG")
 var capped: Dictionary=b.duplicate(true);capped.units.b.record.runtime.hp=int(engine.stats(capped.units.b).HP)-2
 RulesMartial.start_activation(engine,capped)
 check(capped.units.b.record.runtime.hp==int(engine.stats(capped.units.b).HP),"periodic recovery respects actual HP cap")
 var down: Dictionary=b.duplicate(true);down.units.b.record.runtime.hp=0;RulesMartial.start_activation(engine,down)
 check(down.units.b.record.runtime.hp==0,"activation healing never resurrects a downed unit")
 var expired: Dictionary=b.duplicate(true)
 for i in 3:expired.units.b.record.runtime=RulesEffects.new(source).expire_statuses(expired.units.b.record.runtime,"global_round_start").runtime
 var hp: int=int(expired.units.b.record.runtime.hp);RulesMartial.start_activation(engine,expired)
 check(expired.units.b.record.runtime.hp==hp and not has_status(expired.units.b.record,"renewing-benediction"),"global expiry really stops later healing")
 var wizard := prepare_upper(records.wizard20,"wizard-unweaving-tide");var dispelled := use(wizard,b.units.b.record,"wizard-unweaving-tide")
 check(dispelled.ok and not has_status(dispelled.target,"renewing-benediction"),"arcane counter removes the ongoing divine boon on failed Will")
 records.blessed=blessed.target;battles.renewal=b.duplicate(true)

func test_specialisations() -> void:
 for cls in ["wizard","cleric"]:
  for branch in (["evocation","abjuration"] if cls=="wizard" else ["healing","war"]):
   for at in [1,6,20]:
    var choices := {};choices[cls+"-choice-1"]=branch;choices[cls+"-choice-6"]=branch;choices[cls+"-choice-15"]=branch
    var r := alternative(records[cls+str(at)],choices)
    var id: String=cls+"-"+branch+"-"+str(1 if at==1 else 6)
    var target := defender(false);target.runtime.hp-=40
    var used := use(r,target,id);check(used.ok,"selected school/domain actually executes "+id+str(at))
    if not used.ok:continue
    var pool: String="school-uses" if cls=="wizard" else "channel"
    check(used.actor.runtime.resources[pool]==r.runtime.resources[pool]-1,"finite specialisation reserve spent")
    var empty: Dictionary=r.duplicate(true);empty.runtime.resources[pool]=0;check(not use(empty,target,id).ok,"exhausted specialisation rejected")
    if at>=6 and branch in ["abjuration","war"]:
     check(used.target.runtime.temporary_hp==at and used.actor.runtime.temporary_hp==0,"selected ally owns the advanced ward buffer")
    if branch=="healing":check(used.target.runtime.hp>target.runtime.hp,"healing domain restores actual HP")
    if branch=="evocation":check(used.target.runtime.hp<target.runtime.hp,"evocation school deals actual saved damage")
    records[cls+branch+str(at)]=r
  var forged: Dictionary=records[cls+"6"].duplicate(true)
  forged.advancement_history[5].specialisations[cls+"-choice-6"]="abjuration" if cls=="wizard" else "war"
  check(not kernel.validate_build(forged).ok,"mismatched permanent advanced school/domain rejected "+cls)

func test_historical() -> void:
 var current := source;var current_kernel := kernel
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v22.json").ok,"historical22 schema remains valid");kernel=RulesCharacter.new(source)
 var old := build("cleric",6);old.advancement_history[5].specialisations["cleric-choice-6"]="war"
 check(kernel.validate_build(old).ok,"historical22 cross-domain history retains its original validation")
 records.historical22_domain=old
 for cls in ["wizard","cleric"]:
  var branch: String="abjuration" if cls=="wizard" else "war"
  var choices := {};choices[cls+"-choice-1"]=branch;choices[cls+"-choice-6"]=branch
  var r := alternative(build(cls,6),choices);var target := build("fighter",6);target.character_id="old-target"
  var used := use(r,target,cls+"-"+branch+"-6")
  check(used.ok and used.actor.runtime.temporary_hp==6 and used.target.runtime.temporary_hp==0,"historical22 ward beneficiary is unchanged")
 source=current;kernel=current_kernel

func test_upper_hybrids() -> void:
 var planner: Node=load("res://tests/character_completeness/prestige_driver.gd").new();planner.source=source;planner.kernel=kernel
 var goals: Dictionary=planner.requirements("mystic-theurge",0)
 for primary in ["wizard","cleric"]:
  var attrs := {"STR":8,"DEX":10,"CON":13,"INT":15 if primary=="wizard" else 14,"WIS":15 if primary=="cleric" else 14,"CHA":12}
  var r := kernel.create("upper-hybrid-"+primary,attrs,"heritage-human")
  var route: Array=["wizard","wizard","wizard","cleric","cleric","cleric"]
  for i in 5:route.append("mystic-theurge")
  for i in 9:route.append(primary)
  for cls in route:
   var step: Dictionary=planner.advance(r,cls,goals);check(step.ok,"lawful ordered prestige route "+primary+"/"+cls+JSON.stringify(step.get("errors",[])))
   if not step.ok:planner.free();return
   r=step.candidate
  r.runtime.hp=kernel.derive_character(r).snapshot.stats.HP
  var d := kernel.derive_character(r)
  check(d.ok and d.snapshot.casting_levels[primary]==17 and d.snapshot.class_levels["mystic-theurge"]==5,"hybrid legitimately reaches one tier9 track, not blended double19")
  var id: String="wizard-stillness-lattice" if primary=="wizard" else "cleric-renewing-benediction"
  r=prepare_upper(r,id);var casted := use(r,defender(false),id)
  check(casted.ok,"hybrid actually spends upper primary slot/copy "+primary)
  var other: String="cleric" if primary=="wizard" else "wizard"
  var unavailable: String="cleric-renewing-benediction" if other=="cleric" else "wizard-stillness-lattice"
  check(not use(r,defender(false),unavailable).ok,"hybrid cannot borrow primary tier for secondary casting")
  if casted.ok:records["hybrid-"+primary]=casted.actor
 planner.free()

func test_descriptors() -> void:
 for effect in [{"op":"restore_resource","id":"channel","amount":{"op":"const","value":1}},{"op":"heal","amount":{"op":"const","value":0}},{"op":"heal","amount":{"op":"const","value":51}}]:
  var errors: Array=[];RulesMartial.validate_definition("statuses",{"id":"forged","activation_effects":[effect]},{},errors)
  check(not errors.is_empty(),"periodic descriptors cannot grant resources or unbounded healing")

func test_attributes_and_mitigation() -> void:
 for cls in ["wizard","cleric"]:
  var attrs := {"STR":15,"DEX":14,"CON":13,"INT":8 if cls=="wizard" else 12,"WIS":8 if cls=="cleric" else 12,"CHA":10}
  var low := build_with_feats(cls,20,{},attrs)
  check(not low.is_empty(),"lawful low casting-attribute career "+cls)
  if low.is_empty():continue
  records["low-"+cls]=low
  var id: String="wizard-stillness-lattice" if cls=="wizard" else "cleric-renewing-benediction"
  check(not RulesCoreContent.spell_eligible(kernel.derive_character(low).snapshot,source.definition("abilities",id)),"class level alone cannot satisfy permanent tier9 attribute")
  var forged: Dictionary=low.duplicate(true);forged.choices.prepared_abilities=[id];forged.choices.spell_preparations={id:1}
  var rejected := kernel.validate_build(forged)
  check(not rejected.ok and rejected.errors.any(func(e: Dictionary):return e.code=="spell.requirements"),"forged preparation reports actual permanent casting requirement")
 var wizard := prepare_upper(records.wizard20,"wizard-prismatic-volley");var bare := defender(false);bare.runtime.hp=int(kernel.derive_character(bare).snapshot.stats.HP)
 var warded: Dictionary=bare.duplicate(true);warded.runtime.statuses.append({"id":"elemental-covenant","source":"fixture","remaining":3,"expiry":"global_round_start"})
 var normal := use(wizard,bare,"wizard-prismatic-volley");var protected := use(wizard,warded,"wizard-prismatic-volley")
 check(normal.ok and protected.ok and protected.target.runtime.hp-normal.target.runtime.hp==16,"existing fire/electricity packets independently consume resistance8")
 records.mitigated=warded

func test_repertoire() -> void:
 for cls in ["wizard","cleric"]:
  for at in [1,6,20]:
   var r: Dictionary=records[cls+str(at)];var snapshot: Dictionary=kernel.derive_character(r).snapshot
   for id in snapshot.abilities:
    var a := source.definition("abilities",id)
    if a.get("casting_class")!=cls or not a.tags.has("spell") or not RulesCoreContent.spell_eligible(snapshot,a):continue
    var selected := prepare_upper(r,id);var engine := TacticalAuras.new(selected);var b := encounter(selected)
    var target: String="a" if a.targeting.kind=="self" else "b" if a.targeting.kind=="ally" else "bandit-blade"
    var outcome := execute(engine,b,id,target)
    check(outcome.ok,"real selected early/middle/late spell "+cls+str(at)+"/"+id+str(outcome.get("error","")))
    if not outcome.ok:return
    upper_casts.append({"class_id":cls,"level":at,"ability":id})
