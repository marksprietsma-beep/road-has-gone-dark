extends "res://tests/martial_careers/probe.gd"
## Lawful development builds; separately earned campaign acceptance is mandatory.
var contracts := {}
var outcomes := {"misses":0,"hits":0,"criticals":0,"changed_hits":0}
func run() -> void:
 base=OS.get_environment("MARTIAL_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v30.json").ok,"candidate30 exact registry")
 kernel=RulesCharacter.new(source)
 if OS.get_environment("MARTIAL_RESTART")=="1":cold();return
 fixtures.fighter=variant("fighter",20)
 test_training();test_disciplines();test_mastery();test_rage();test_feat_chain();test_weapon_overrides()
 persist()
 finish_martial()
func step_options(cls: String,style: String) -> Dictionary:
 return {cls+"-choice-1":style,cls+"-choice-6":style,cls+"-choice-15":style}
func advance_more(record: Dictionary,cls: String,count: int) -> Dictionary:
 var r := record.duplicate(true)
 for _n in count:
  var choice := kernel.suggested_choice(r,cls,"steady-study");check(choice.ok,"lawful hybrid suggestion "+cls)
  if not choice.ok:return {}
  var step := kernel.preview_advancement(r,choice.choice);check(step.ok,"lawful hybrid advancement "+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  r=step.candidate
 var d := kernel.derive_character(r);check(d.ok,"lawful advanced record")
 if not d.ok:return {}
 r.runtime.hp=int(d.snapshot.stats.HP);r.runtime.resources=d.snapshot.resource_capacities.duplicate()
 return RulesJson.string_keys(r)
func encounter(record: Dictionary) -> Dictionary:
 var b := super.encounter(record)
 b.units.a.name=str(source.definition("classes",record.advancement_history[0].class_id).name)+" development adventurer"
 return TacticalAuras.new(record).seal(b)
func test_training() -> void:
 var a := stats_of(variant("fighter",4));var b := stats_of(variant("fighter",5))
 check(b.melee_attack-a.melee_attack-(b.BAB-a.BAB)==1 and b.ranged_attack-a.ranged_attack-(b.BAB-a.BAB)==1,"Veteran adds one actual attack beyond BAB in both modes")
 var plain := variant("fighter",1);var point := variant("fighter",1,{},"point-blank-shot")
 check(stats_of(point).ranged_attack==stats_of(plain).ranged_attack+1,"Pointblank actually stacks with Fighter training")
 records.pointblank=point;records.fighter5=variant("fighter",5)
 contracts.training=true
func test_disciplines() -> void:
 for style in ["blade","bow"]:
  for level in [1,6,20]:
   var r := variant("fighter",level,step_options("fighter",style))
   r.equipment=["bow","leathers"] if style=="bow" else ["shortblade","mail","shield"]
   var id: String="fighter-"+style+"-"+str(6 if level>=6 else 1)
   var before := stats_of(r);var used := use(r,r,id)
   check(used.ok,"actual paid discipline "+id+str(level)+JSON.stringify(used.get("errors",[])))
   if not used.ok:continue
   var after := stats_of(used.actor)
   check(used.budget.main==0 and used.budget.move==1 and used.actor.runtime.resources["fighter-resolve"]==r.runtime.resources["fighter-resolve"]-1,"discipline competes for main/resolve; movement retained")
   check(after["ranged_attack"if style=="bow"else"melee_attack"]==before["ranged_attack"if style=="bow"else"melee_attack"]+2,"actual advertised insight attack bonus")
   check(after.damage==before.damage+1 if style=="bow" else after.defence==before.defence+1,"actual advertised damage/defence bonus")
   if level>=6:check(used.actor.runtime.temporary_hp==level,"mastery finite nonstacking buffer")
   var engine := TacticalAuras.new(r)
   for die in [1,19,20]:
    var control := encounter(r);var enhanced := encounter(used.actor)
    control.rng=attack_seed(die);enhanced.rng=control.rng.duplicate(true);control=engine.seal(control);enhanced=engine.seal(enhanced)
    var result := {}
    var raw_trace := RulesAttackTrace.capture(func():result.raw=execute(engine,control,"attack","bandit-blade"))
    var buff_trace := RulesAttackTrace.capture(func():result.buff=execute(engine,enhanced,"attack","bandit-blade"))
    var raw: Dictionary=result.raw;var buff: Dictionary=result.buff
    check(raw.ok and buff.ok and raw_trace.size()==1 and buff_trace.size()==1,"actual numeric weapon command "+style+str(die))
    if not raw.ok or not buff.ok or raw_trace.is_empty() or buff_trace.is_empty():continue
    for pair in [[raw,raw_trace[0]],[buff,buff_trace[0]]]:
     var event: Dictionary=pair[1]
     check(event.roll==die and event.hit==(int(event.roll)+int(event.bonus)>=int(event.defence)),"original numeric attack authority, including high-bonus die1")
     var expected := RulesRng.roll("1d20",control.rng).rng
     if event.hit:expected=RulesRng.roll("1d6",expected).rng
     check(pair[0].battle.rng==expected,"exact authoritative attack/damage RNG consumption")
     outcomes["hits"if event.hit else"misses"]+=1
     if event.get("critical",false):outcomes.criticals+=1
    if not raw_trace[0].hit and not buff_trace[0].hit:
     check(raw.battle.units["bandit-blade"].record.runtime.hp==control.units["bandit-blade"].record.runtime.hp and buff.battle.units["bandit-blade"].record.runtime.hp==enhanced.units["bandit-blade"].record.runtime.hp,"genuine misses deliver no damage")
    elif raw_trace[0].hit and buff_trace[0].hit and style=="bow":check(raw.battle.units["bandit-blade"].record.runtime.hp-buff.battle.units["bandit-blade"].record.runtime.hp==1,"ranged hit/critical gains exactly one weapon damage")
    elif not raw_trace[0].hit and buff_trace[0].hit:
     check(buff.battle.units["bandit-blade"].record.runtime.hp<raw.battle.units["bandit-blade"].record.runtime.hp,"real accuracy bonus converts a miss into a hit")
     outcomes.changed_hits+=1
    check(engine._attack_weapon_context.is_empty(),"transient weapon context is always restored")
    var replay := execute(engine,RulesJson.normalize(JSON.parse_string(JSON.stringify(enhanced))),"attack","bandit-blade")
    check(replay.ok and replay.battle.state_hash==buff.battle.state_hash,"exact deterministic attack replay")
    if level==20 and die==19:battles[style]=buff.battle
   var wrong := r.duplicate(true);wrong.equipment=["shortblade","leathers"] if style=="bow"else["bow","mail","shield"]
   var untouched := RulesJson.digest(wrong)
   check(not use(wrong,wrong,id).ok and RulesJson.digest(wrong)==untouched,"wrong equipped weapon rejected without mutation")
   var swapped: Dictionary=used.actor.duplicate(true);swapped.equipment=wrong.equipment.duplicate()
   var unbuffed := wrong.duplicate(true)
   check(stats_of(swapped).damage==stats_of(unbuffed).damage if style=="bow"else stats_of(swapped).melee_attack==stats_of(unbuffed).melee_attack,"existing discipline bonus follows actual equipped weapon")
   records[style+str(level)]=used.actor
 check(outcomes.misses>0 and outcomes.hits>0 and outcomes.criticals>0,"genuine numeric misses, hits and criticals were observed")
 contracts.equipment_disciplines=true;contracts.actual_attacks=true
func test_mastery() -> void:
 for style in ["reckless","resilient"]:
  var early := variant("barbarian",1,step_options("barbarian",style))
  records["barbarian-"+style+"1"]=early
  for level in [15,20]:
   var r := variant("barbarian",level,step_options("barbarian",style))
   records["barbarian-"+style+str(level)]=r
   var base_stats := stats_of(r);var used := use(r,r,"barbarian-"+style+"-6");check(used.ok,"actual late chosen rage "+style+str(level))
   if not used.ok:continue
   var raised := stats_of(used.actor)
   if style=="resilient":
    check(base_stats.save_dc==0 and raised.fortitude==base_stats.fortitude+4,"resilient mastery no decorative DC; own rage retains full training benefit")
    var comparison := variant("barbarian",level,step_options("barbarian","reckless"))
    check(base_stats.fortitude==stats_of(comparison).fortitude+2,"mastery adds real permanent Fortitude")
   else:check(raised.defence==base_stats.defence-2 and raised.melee_attack>base_stats.melee_attack,"reckless mastery preserves relative defensive vulnerability")
   records["barbarian-"+style+str(level)+"-active"]=used.actor
 contracts.resilient_mastery=true
func next_activation(engine: TacticalAuras,battle: Dictionary) -> Dictionary:
 var b := battle
 for _n in b.order.size()+1:
  if engine.current(b).id=="a" and int(b.budget.main)==1:return b
  var out := engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"})
  check(out.ok,"ordinary turn boundary")
  if not out.ok:return b
  b=out.battle
 check(false,"next activation reached");return b
func test_rage() -> void:
 var r := variant("barbarian",6,{"barbarian-choice-1":"reckless","barbarian-choice-6":"resilient"})
 var engine := TacticalAuras.new(r);var b := encounter(r)
 for id in ["rage","barbarian-reckless-1","barbarian-resilient-6"]:
  var before := RulesJson.digest(b);var prior: int=b.units.a.record.runtime.resources["rage-uses"]
  var out := execute(engine,b,id);check(out.ok,"ordinary legal activation "+id)
  if not out.ok:continue
  check(out.battle.budget.main==0 and out.battle.units.a.record.runtime.resources["rage-uses"]==prior-1 and out.battle.rng==b.rng,"rage spends action/use without attack/RNG")
  check(not execute(engine,out.battle,"attack","bandit-blade").ok and not execute(engine,out.battle,id).ok,"no second activation/attack from same main action")
  check(RulesJson.digest(b)==before,"rage source battle untouched")
  b=next_activation(engine,out.battle)
 check(b.units.a.record.runtime.resources["rage-uses"]==0 and not execute(engine,b,"rage").ok,"no resource loop after three paid activations")
 battles.rage=b
 for _n in 4:b=next_activation(engine,execute(engine,b,"end").battle)
 check(not b.units.a.record.runtime.statuses.any(func(s: Dictionary):return s.id in ["raging","barbarian-reckless-1-status","barbarian-resilient-6-status"]),"real global boundaries expire all rage modifiers")
 var d := kernel.derive_character(b.units.a.record)
 var short := RulesEffects.new(source).refresh_resources(b.units.a.record.runtime,d.snapshot.resource_capacities,"encounter")
 check(short.ok and short.runtime.resources["rage-uses"]==0,"encounter cannot refill daily rage")
 var rest := RulesEffects.new(source).refresh_resources(b.units.a.record.runtime,d.snapshot.resource_capacities,"eligible_rest")
 check(rest.ok and rest.runtime.resources["rage-uses"]==d.snapshot.resource_capacities["rage-uses"],"eligible rest restores owned daily rage")
 records.rage_spent=b.units.a.record
 contracts.rage_tradeoffs=true;contracts.resources_and_expiry=true
func test_feat_chain() -> void:
 var r := variant("fighter",5,{},"weapon-focus")
 var choice: Dictionary=kernel.suggested_choice(r,"fighter").choice
 choice.bonus_feats=["veteran-weapon-training"]
 var step := kernel.preview_advancement(r,choice);check(step.ok,"genuine bonus feat meets BAB/Focus chain")
 if step.ok:
  check(step.snapshot.stats.damage==stats_of(r).damage+2,"chosen chain changes actual weapon damage")
  records.feat_chain=step.candidate
 var invalid: Dictionary=kernel.suggested_choice(variant("fighter",3),"fighter").choice;invalid.bonus_feats=["veteran-weapon-training"]
 check(not kernel.preview_advancement(variant("fighter",3),invalid).ok,"forged early/prerequisite-free bonus feat rejects")
 contracts.feat_choices=true
func test_weapon_overrides() -> void:
 var hybrid := advance_more(variant("fighter",6,{"fighter-choice-1":"blade","fighter-choice-6":"bow"}),"soulknife",4);hybrid.equipment=["bow","leathers"]
 var manifested := use(hybrid,hybrid,"soulknife-manifest");check(manifested.ok,"actual hybrid manifestation")
 if manifested.ok:
  check(kernel.derive_character(manifested.actor).snapshot.tags.has("active_melee_weapon"),"actual manifestation replaces held bow profile")
  check(not use(manifested.actor,manifested.actor,"fighter-bow-6").ok and use(manifested.actor,manifested.actor,"fighter-blade-1").ok,"active override controls both real discipline choices")
 var natural := variant("fighter",20,step_options("fighter","bow"),"steady-study","heritage-troglodyte");natural.equipment=["bow","leathers"]
 var enhanced := use(natural,natural,"fighter-bow-6");check(enhanced.ok,"paid bow discipline before inherited attack")
 if enhanced.ok:
  var engine := TacticalAuras.new(natural);var control := encounter(natural);var buffed := encounter(enhanced.actor)
  control.rng=attack_seed(19);buffed.rng=control.rng.duplicate(true);control=engine.seal(control);buffed=engine.seal(buffed)
  var raw := execute(engine,control,"troglodyte-natural-bite","bandit-blade");var hit := execute(engine,buffed,"troglodyte-natural-bite","bandit-blade")
  check(raw.ok and hit.ok,"real owned inherited natural-weapon command")
  if raw.ok and hit.ok:check(raw.battle.units["bandit-blade"].record.runtime.hp==hit.battle.units["bandit-blade"].record.runtime.hp and raw.battle.rng==hit.battle.rng,"bow damage cannot leak into a different actual attack weapon")
  check(engine._attack_weapon_context.is_empty(),"actual-weapon context restored after override")
  records.natural_bow=enhanced.actor
 var druid := advance_more(variant("fighter",6,step_options("fighter","bow")),"druid",5);druid.equipment=["bow","leathers"]
 var shaped := use(druid,druid,"wild-shape");check(shaped.ok,"actual owned natural transformation")
 if shaped.ok:check(kernel.derive_character(shaped.actor).snapshot.tags.has("active_natural_weapon") and not use(shaped.actor,shaped.actor,"fighter-bow-6").ok,"natural body suppresses held-weapon discipline without rewriting equipment")
 contracts.weapon_overrides=true
func persist() -> void:
 var payload := {"records":{},"hashes":{},"record_hashes":{},"battles":battles,"next":{},"after":{}}
 for key in records:
  var r: Dictionary=RulesJson.string_keys(records[key]);var d := kernel.derive_character(r);check(d.ok,"saved legal full state "+key)
  if not d.ok:continue
  payload.records[key]=r;payload.hashes[key]=d.snapshot.snapshot_hash;payload.record_hashes[key]=RulesJson.digest(r)
 for key in battles:
  var engine := TacticalAuras.new(battles[key].units.a.record);check(engine.validate(battles[key]).is_empty(),"saved battle validates "+key)
  var command := {"actor_id":engine.current(battles[key]).id,"revision":battles[key].revision,"kind":"end"}
  var out := engine.command(battles[key],command);check(out.ok,"predict next command "+key)
  if out.ok:payload.next[key]=command;payload.after[key]=out.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(payload)))
func cold() -> void:
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for key in saved.records:
  var r: Dictionary=saved.records[key];var d := kernel.derive_character(r)
  check(d.ok and d.snapshot.snapshot_hash==saved.hashes[key],"exact cold snapshot "+key)
  check(RulesJson.digest(r)==saved.record_hashes[key],"exact cold choices/resources/equipment/pin "+key)
 for key in saved.battles:
  var engine := TacticalAuras.new(saved.battles[key].units.a.record);check(engine.validate(saved.battles[key]).is_empty(),"cold valid battle "+key)
  var out := engine.command(saved.battles[key],saved.next[key]);check(out.ok and out.battle.state_hash==saved.after[key],"cold next command/log/RNG "+key)
 finish_martial(true)
func finish_martial(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"contracts":contracts,"attack_outcomes":outcomes,"development_fixtures":true,"earned_xp":false,"supported_level":20}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("MARTIAL_MECHANICS ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
