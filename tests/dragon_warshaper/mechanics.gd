extends "res://tests/dragon_warshaper/probe.gd"
## Current34 lawful development fixtures; earned XP is a separate campaign phase.
var dragon_levels := {}
var morph_levels := {}
func run() -> void:
 base=OS.get_environment("DRAGON_WARSHAPER_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded: Dictionary=source.load_pack("res://data/rules/trhgd-character-v34.json")
 check(loaded.ok,"current34 complete typed schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_current();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("DRAGON_WARSHAPER_RESTART")=="1":cold_cohort();finish_current(true);return
 fixtures.fighter=build("fighter",12)
 var roots: Dictionary={"wizard":route(repeated("wizard",5),WIZARD_ARRAY,"dragon-disciple"),"sorcerer":route(repeated("sorcerer",6),{"STR":8,"DEX":12,"CON":10,"INT":14,"WIS":13,"CHA":15},"dragon-disciple"),"beguiler":route(repeated("beguiler",6),WIZARD_ARRAY,"dragon-disciple"),"druid":route(repeated("druid",6),GS_NATURE_ARRAY,"warshaper")}
 for key in roots:
  var r: Dictionary=roots[key];check(not r.is_empty(),"lawful existing parent "+key)
  if r.is_empty():continue
  saved_records[key+"-prefix"]=r.duplicate(true)
  var path: String="warshaper"if key=="druid"else"dragon-disciple"
  var cap: int=5 if path=="warshaper"else 1 if key=="beguiler"else 10
  for at in range(1,cap+1):
   r=advance_existing(r,path,str(key))
   if r.is_empty():break
   saved_records[key+str(at)]=r.duplicate(true)
   var d: Dictionary=kernel.derive_character(r)
   check(d.ok and d.snapshot.class_levels[path]==at,"every supported ordered prestige level "+path+str(at))
   if path=="dragon-disciple":
    dragon_levels[key]=range(1,at+1)
    check(d.snapshot.casting_levels[key]==roots[key].advancement_history.size()+at/2,"selected actual caster advances once per two Dragon levels")
   else:morph_levels[key]=range(1,at+1)
 if failures:finish_current();return
 test_current_entry();test_current_dragon();test_current_morph();test_current_bodies();test_current_limits();test_paid_exhaustion();test_ward_and_claws();test_incapacitation();test_current_late()
 persist_cohort();finish_current()
func advance_existing(record: Dictionary,path: String,parent: String) -> Dictionary:
 var suggested: Dictionary=kernel.suggested_choice(record,path,"steady-study")
 check(suggested.ok,"legally available next level "+path+JSON.stringify(suggested.get("errors",[])))
 if not suggested.ok:return {}
 if path=="dragon-disciple"and suggested.choice.specialisations.has("dragon-disciple-casting"):suggested.choice.specialisations["dragon-disciple-casting"]=parent
 if (record.advancement_history.size()+1)%4==0:suggested.choice.attribute_increase=source.definition("classes",parent).casting_attribute
 var out: Dictionary=kernel.preview_advancement(record,suggested.choice)
 check(out.ok,"explicit permanent level/parent "+path+JSON.stringify(out.get("errors",[])))
 return learn(out.candidate,out.snapshot)if out.ok else {}
func test_current_entry() -> void:
 for path in ["dragon-disciple","warshaper"]:
  check(not kernel.starting_classes().has(path),"prestige never a starting class "+path)
  var blank: Dictionary=kernel.create("forged-prestige",WIZARD_ARRAY,"heritage-human")
  var forged: Dictionary=kernel.suggested_choice(blank,path)
  var payload: Dictionary=forged.choice if forged.ok else {"class_id":path,"feat_id":"steady-study","skill_allocations":{},"attribute_increase":"","specialisations":{},"bonus_feats":[]}
  var rejected: Dictionary=kernel.preview_advancement(blank,payload)
  check(not rejected.ok and rejected.errors.any(func(e: Dictionary):return e.code=="advancement.prestige_start"),"actual first-history replay independently rejects starting prestige "+path)
  var r: Dictionary=saved_records["druid-prefix"if path=="warshaper"else"wizard-prefix"]
  var before: String=RulesJson.digest(r)
  check(kernel.available_advancement(r).classes[path].ok,"durable complete prestige prerequisites "+path)
  var alternative: Dictionary=kernel.suggested_choice(r,"druid"if path=="warshaper"else"wizard")
  check(alternative.ok and kernel.preview_advancement(r,alternative.choice).ok,"qualified character may deliberately decline "+path)
  check(RulesJson.digest(r)==before and not kernel.derive_character(r).snapshot.class_levels.has(path),"eligibility and preview never grant a level or change identity")
 var weak: Dictionary=route(["wizard"]+repeated("sorcerer",2)+repeated("fighter",2),DUAL_ARRAY,"dragon-disciple")
 check(not weak.is_empty()and not kernel.available_advancement(weak).classes["dragon-disciple"].ok,"aggregate score cannot replace actual tier3 magic")
 var cleric: Dictionary=route(repeated("cleric",6),WIZARD_ARRAY,"dragon-disciple")
 check(not cleric.is_empty()and not kernel.available_advancement(cleric).classes["dragon-disciple"].ok,"divine tier3 is not arcane qualification")
 var fighter: Dictionary=route(repeated("fighter",6),WIZARD_ARRAY,"warshaper")
 check(not fighter.is_empty()and not kernel.available_advancement(fighter).classes.warshaper.ok,"BAB without permanent Druid Shape is insufficient")
 var temporary: Dictionary=fighter.duplicate(true);temporary.runtime.granted_features.append("druid-shape")
 var replay: Dictionary=kernel._replay(temporary)
 if replay.ok:temporary.runtime.resources=replay.context.capacities.duplicate(true);RulesEntities.synchronize(temporary,source)
 check(kernel.validate_build(temporary).ok and not kernel.available_advancement(temporary).classes.warshaper.ok,"temporary granted Shape cannot unlock permanent prestige")
 var beguiler: Dictionary=saved_records["beguiler-prefix"]
 var step: Dictionary=kernel.suggested_choice(beguiler,"dragon-disciple")
 check(step.ok,"qualified existing Beguiler now has a genuine parent choice")
 if step.ok:
  step.choice.specialisations["dragon-disciple-casting"]="sorcerer"
  check(not kernel.preview_advancement(beguiler,step.choice).ok,"forged unowned parent cannot borrow casting")
 contracts.entry=true
func test_current_dragon() -> void:
 for parent in ["wizard","sorcerer"]:
  for at in [1,4,7,10]:
   var r: Dictionary=saved_records[parent+str(at)];var aid: String="dragon-disciple-technique-"+str(at);var engine:=TacticalAuras.new(r)
   var b: Dictionary=encounter(r);var target: String="a"if at==4 else"bandit-blade"
   if at==10:b.units["bandit-bow"].position=[2,2];b=engine.seal(b)
   var input_hash: String=RulesJson.digest(b);var before_hp: int=b.units["bandit-blade"].record.runtime.hp
   var out: Dictionary=execute(engine,b,aid,target)
   check(out.ok,"actual distinct early/middle/late Dragon command "+parent+str(at)+str(out.get("error","")))
   if not out.ok:continue
   var spent: int=2 if at==10 else 1
   check(RulesJson.digest(b)==input_hash and out.battle.budget.main==0 and out.battle.units.a.record.runtime.resources["dragon-disciple-uses"]==b.units.a.record.runtime.resources["dragon-disciple-uses"]-spent,"one action and exact shared finite reserve; input untouched")
   if at==4:
    check(out.battle.units.a.record.runtime.temporary_hp==4+at and out.battle.units.a.record.runtime.hp==r.runtime.hp,"Scale mantle creates real buffer, never healing")
    check(engine.stats(out.battle.units.a).defence==engine.stats(b.units.a).defence+2,"mantle's typed defence actually stacks with natural scales")
    check(out.battle.units["bandit-blade"].record.runtime.hp==before_hp,"self ward competes with offence rather than copying fire damage")
   else:check(out.battle.units["bandit-blade"].record.runtime.hp<before_hp,"breath deals actual saved/resisted damage")
   if at==10:check(out.battle.units["bandit-bow"].record.runtime.hp<b.units["bandit-bow"].record.runtime.hp,"clustered Crownfire resolves a real second enemy")
   battles[parent+"-dragon"+str(at)]=out.battle
 var r: Dictionary=saved_records.wizard10;var engine:=TacticalAuras.new(r)
 var fail_damage := 0;var resisted_damage := 0
 for roll in [1,20]:
  var b: Dictionary=encounter(r);b.rng=attack_seed(roll);b=engine.seal(b)
  var out: Dictionary=execute(engine,b,"dragon-disciple-technique-1","bandit-blade")
  check(out.ok,"real Reflex save branch "+str(roll))
  if not out.ok:continue
  var damage: int=b.units["bandit-blade"].record.runtime.hp-out.battle.units["bandit-blade"].record.runtime.hp
  if roll==1:fail_damage=damage;check("failed"in out.battle.log.back(),"actual failed Reflex log")
  else:resisted_damage=damage;check("resisted"in out.battle.log.back(),"actual successful Reflex log")
 check(fail_damage>resisted_damage and resisted_damage>0,"successful save meaningfully halves the original fire amount")
 var seed: Dictionary=attack_seed(1);var target: Dictionary=saved_records.wizard10.duplicate(true);target.character_id="resistant-target"
 var actual: Dictionary=RulesEffects.new(source).use_ability(saved_records.wizard1,target,"dragon-disciple-technique-1",{"main":1,"move":1,"reaction":1},seed)
 check(actual.ok and actual.target.runtime.hp==target.runtime.hp,"actual inherited fire10 resistance absorbs first-rank breath")
 var weak: Dictionary=encounter(r);weak.rng=save_pair_seed(1,1);weak=engine.seal(weak)
 var weakened: Dictionary=execute(engine,weak,"dragon-disciple-technique-7","bandit-blade")
 check(weakened.ok and weakened.battle.units["bandit-blade"].record.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened"),"Weakening breath applies actual three-round attack/damage counterplay on failed Fortitude")
 if weakened.ok:battles.weakening=weakened.battle
 contracts.dragon=true
func test_current_morph() -> void:
 var r: Dictionary=saved_records.druid5;var engine:=TacticalAuras.new(r);var results: Dictionary={}
 for at in [1,3,5]:
  var aid: String="warshaper-technique-"+str(at);var b: Dictionary=encounter(r)
  var out: Dictionary=execute(engine,b,aid,"a");check(out.ok,"actual paid natural frame "+str(at))
  if not out.ok:continue
  var changed: Dictionary=out.battle.units.a.record;results[at]=changed
  check(changed.runtime.hp==r.runtime.hp and changed.equipment==r.equipment and changed.ancestry_ref==r.ancestry_ref,"form preserves original health, gear ownership and ancestry")
  check(out.battle.budget.main==0 and changed.runtime.resources["warshaper-uses"]==b.units.a.record.runtime.resources["warshaper-uses"]-1,"form really spends one main and one morphic reserve")
  check(engine.active_weapon(out.battle.units.a)=="bear-claws"and engine.weapon_range(out.battle.units.a)==(3 if at==3 else 2),"real natural weapon and distinct reach "+str(at))
  saved_records["form"+str(at)]=changed;battles["form"+str(at)]=out.battle
 if results.size()!=3:return
 check(kernel.derive_character(results[3]).snapshot.stats.defence==kernel.derive_character(results[1]).snapshot.stats.defence+1 and kernel.derive_character(results[5]).snapshot.stats.defence==kernel.derive_character(results[1]).snapshot.stats.defence+2,"higher morph defence no longer disappears behind anatomy's training bonus")
 for at in [1,3,5]:
  var b: Dictionary=encounter(results[at]);b.units.a.position=[1,2];b.units["bandit-blade"].position=[4,2];b.rng=attack_seed(20);b=engine.seal(b)
  check(engine.eligible(b,b.units.a,b.units["bandit-blade"],"attack")== (at==3),"only Longclaw reaches a third tile; deliberate form tradeoff")
  if at==3:
   var hit: Dictionary=execute(engine,b,"attack","bandit-blade")
   check(hit.ok and hit.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp,"Longclaw causes real natural-weapon damage at reach3")
 for roll in [1,20]:
  var b: Dictionary=encounter(results[1]);b.rng=attack_seed(roll);b=engine.seal(b)
  # TacticalAuras owns an inner scoped trace, intentionally separate from an
  # outer observer. Verify actual battle/log/HP against the original pure roll.
  var expected: Dictionary=RulesRng.attack_roll(int(engine.stats(b.units.a).melee_attack),int(engine.stats(b.units["bandit-blade"]).defence),source.rule("critical"),b.rng)
  var before: String=RulesJson.digest(b);var outcome: Dictionary=execute(engine,b,"attack","bandit-blade")
  check(outcome.ok and before==RulesJson.digest(b),"actual natural strike resolves and preserves input authority")
  if outcome.ok:
   var damage: int=b.units["bandit-blade"].record.runtime.hp-outcome.battle.units["bandit-blade"].record.runtime.hp
   if expected.event.hit:
    check(damage>0 and " hits "in outcome.battle.log.back(),"actual natural hit agrees with the frozen roll and applies damage");attacks.hits+=1
   else:
    check(damage==0 and outcome.battle.log.back().ends_with("miss."),"actual numeric natural miss agrees with the frozen roll, HP and log");attacks.misses+=1
 check(attacks.hits>0 and attacks.misses>0,"genuine hit and numeric miss witnessed")
 var damage: Dictionary={}
 for at in [3,5]:
  var b: Dictionary=encounter(results[at]);b.cursor=b.order.find("bandit-blade");b.rng=attack_seed(19);b=engine.seal(b)
  var hit: Dictionary=engine.command(b,{"actor_id":"bandit-blade","revision":b.revision,"kind":"attack","target_id":"a"})
  check(hit.ok,"real incoming weapon attack against a natural frame")
  if hit.ok:damage[at]=b.units.a.record.runtime.hp-hit.battle.units.a.record.runtime.hp
 check(damage.size()==2 and damage[3]==damage[5]+2,"Ironhide's real physical resistance reduces incoming damage by2")
 observations.morph_tradeoffs={"incoming_damage":damage,"longclaw_reach":3,"ironhide_reach":2};contracts.morph=true
func test_current_bodies() -> void:
 var r: Dictionary=route(repeated("wizard",5)+repeated("druid",5)+["dragon-disciple"],WIZARD_ARRAY,"dragon-disciple",{"dragon-disciple-casting":"wizard"})
 var shaped: Dictionary=use(r,r,"wild-shape");check(shaped.ok,"owned Druid/Dragon transformation remains functional")
 if shaped.ok:
  var engine:=TacticalAuras.new(r);var b: Dictionary=encounter(shaped.actor)
  deny(engine,b,"dragon-disciple-technique-1","bandit-blade","supernatural breath suppressed by actual form")
  var reverted: Dictionary=use(shaped.actor,shaped.actor,"revert-form")
  check(reverted.ok and RulesEntities.form(reverted.actor,source).is_empty(),"original reversion restores Dragon body")
  if reverted.ok:check(execute(engine,encounter(reverted.actor),"dragon-disciple-technique-1","bandit-blade").ok,"original breath returns without new ancestry or restored uses")
  saved_records.dragon_form=shaped.actor
 for at in [1,3,5]:
  var changed: Dictionary=saved_records["form"+str(at)];var original: Dictionary=saved_records.druid5
  var reverted: Dictionary=use(changed,changed,"revert-form")
  check(reverted.ok and reverted.actor.runtime.hp==changed.runtime.hp and reverted.actor.equipment==original.equipment and reverted.actor.runtime.resources==changed.runtime.resources,"reversion restores gear/body without healing or reserve refill")
  if reverted.ok:check(kernel.derive_character(reverted.actor).snapshot.attributes==kernel.derive_character(original).snapshot.attributes,"exact original physical attributes after reversion")
  var engine:=TacticalAuras.new(changed);var b: Dictionary=encounter(changed);var expired: Dictionary=rounds(engine,b,3)
  check(RulesEntities.form(expired.units.a.record,source).is_empty()and expired.units.a.record.runtime.hp==b.units.a.record.runtime.hp,"exact three global boundaries expire the frame without changing health")
 contracts.forms=true
func test_current_limits() -> void:
 for spec in [["wizard1","dragon-disciple-technique-1","bandit-blade","dragon-disciple-uses"],["wizard10","dragon-disciple-technique-10","bandit-blade","dragon-disciple-uses"],["druid5","warshaper-technique-5","a","warshaper-uses"]]:
  var r: Dictionary=saved_records[spec[0]];var engine:=TacticalAuras.new(r);var b: Dictionary=encounter(r)
  var empty: Dictionary=b.duplicate(true);empty.units.a.record.runtime.resources[spec[3]]=0;empty=engine.seal(empty);deny(engine,empty,spec[1],spec[2],"empty exact class reserve")
  var busy: Dictionary=b.duplicate(true);busy.budget.main=0;busy=engine.seal(busy);deny(engine,busy,spec[1],spec[2],"spent main action")
  var rested: Dictionary=RulesEffects.new(source).refresh_resources(empty.units.a.record.runtime,kernel.derive_character(r).snapshot.resource_capacities,"eligible_rest")
  check(rested.ok and rested.runtime.resources[spec[3]]==kernel.derive_character(r).snapshot.resource_capacities[spec[3]],"eligible rest restores finite class reserve")
  deny(engine,b,spec[1],"bandit-blade"if spec[2]=="a"else"b","wrong team/self target")
 var r: Dictionary=saved_records.wizard10;var engine:=TacticalAuras.new(r);var b: Dictionary=encounter(r);b.units.a.record.runtime.resources["dragon-disciple-uses"]=1;b=engine.seal(b)
 deny(engine,b,"dragon-disciple-technique-10","bandit-blade","Crownfire requires two whole uses")
 check(execute(engine,b,"dragon-disciple-technique-1","bandit-blade").ok,"one remaining use still funds Ember breath")
 contracts.limits=true
func test_current_late() -> void:
 for spec in [["wizard10","wizard"],["sorcerer10","sorcerer"],["druid5","druid"]]:
  var r: Dictionary=saved_records[spec[0]]
  while r.advancement_history.size()<20:
   var proposed: Dictionary=kernel.suggested_choice(r,spec[1],"steady-study")
   check(proposed.ok,"lawful total20 alternative step")
   if not proposed.ok:break
   if (r.advancement_history.size()+1)%4==0:proposed.choice.attribute_increase=source.definition("classes",spec[1]).casting_attribute
   var out: Dictionary=kernel.preview_advancement(r,proposed.choice);check(out.ok,"legal total20 history, not campaign XP")
   if not out.ok:break
   r=learn(out.candidate,out.snapshot)
  check(r.advancement_history.size()==20,"supported total20 development alternative")
  saved_records[spec[0]+"-total20"]=r
 contracts.late=true
func finish_current(restart := false) -> void:
 var proof: Dictionary={"checks":checks,"failures":failures,"failed_checks":failed_checks,"rules_ref":source.rules_ref(),"contracts":contracts,"attacks":attacks,"observations":observations,"dragon_levels":dragon_levels,"morph_levels":morph_levels,"development_fixtures":true,"earned_xp":false}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof)))
 print("DRAGON_WARSHAPER_CURRENT ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)

func save_pair_seed(first: int,second: int) -> Dictionary:
 for n in 50000:
  var rng: Dictionary=RulesRng.initial("dragon-saves-"+str(n))
  var a: Dictionary=RulesRng.roll("1d20",rng);var b: Dictionary=RulesRng.roll("1d20",a.rng)
  if a.total==first and b.total==second:return rng
 check(false,"public original-RNG save-pair seed found");return RulesRng.initial("missing-save-pair")

func test_paid_exhaustion() -> void:
 for spec in [["wizard10","dragon-disciple-technique-1","bandit-blade","dragon-disciple-uses"],["druid5","warshaper-technique-5","a","warshaper-uses"]]:
  var record: Dictionary=saved_records[spec[0]];var engine:=TacticalAuras.new(record);var battle: Dictionary=encounter(record)
  var capacity: int=battle.units.a.record.runtime.resources[spec[3]]
  for n in capacity:
   battle=turn(engine,battle,"a");var paid: Dictionary=execute(engine,battle,spec[1],spec[2])
   check(paid.ok,"legitimate repeated activation spends a real finite use")
   if not paid.ok:break
   battle=paid.battle
   check(battle.units.a.record.runtime.resources[spec[3]]==capacity-n-1,"exact reserve declines to zero through paid actions")
  battle=turn(engine,battle,"a")
  check(battle.units.a.record.runtime.resources[spec[3]]==0,"genuinely exhausted class reserve")
  deny(engine,battle,spec[1],spec[2],"paid exhaustion cannot be bypassed by a new main action")
  battles[spec[0]+"-exhausted"]=battle
 contracts.paid_exhaustion=true
func test_ward_and_claws() -> void:
 var record: Dictionary=saved_records.wizard4;var protected: Dictionary=use(record,record,"dragon-disciple-technique-4")
 check(protected.ok,"owned Scale mantle executes through effects authority")
 if protected.ok:
  var again: Dictionary=use(protected.actor,protected.actor,"dragon-disciple-technique-4")
  check(again.ok and again.actor.runtime.temporary_hp==protected.actor.runtime.temporary_hp and again.actor.runtime.hp==record.runtime.hp,"paid ward refresh never stacks buffer or heals original health")
  var engine:=TacticalAuras.new(record);var bare: Dictionary=encounter(record);var warded: Dictionary=encounter(protected.actor)
  var attacker: Dictionary=build("fighter",1);attacker.character_id="bandit-blade";attacker.equipment=["shortblade"]
  for b in [bare,warded]:b.units["bandit-blade"].record=attacker.duplicate(true);b.cursor=b.order.find("bandit-blade")
  var roll: int=int(engine.stats(bare.units.a).defence)-int(engine.stats(bare.units["bandit-blade"]).melee_attack)
  check(roll>=1 and roll<20,"lawful attacker permits actual ward hit-to-miss counterplay")
  var rng: Dictionary=attack_seed(roll);bare.rng=rng;warded.rng=rng;bare=engine.seal(bare);warded=engine.seal(warded)
  var strike: Dictionary={"actor_id":"bandit-blade","revision":bare.revision,"kind":"attack","target_id":"a"}
  var first: Dictionary=engine.command(bare,strike);var second: Dictionary=engine.command(warded,strike)
  check(first.ok and second.ok and " hits "in first.battle.log.back()and second.battle.log.back().ends_with("miss."),"Scale mantle turns an actual original weapon hit into a miss")
  if second.ok:battles.scale_mantle_miss=second.battle
 var clawed: Dictionary=saved_records.wizard1.duplicate(true);clawed.equipment=["unarmed"]
 var engine:=TacticalAuras.new(clawed);var battle: Dictionary=encounter(clawed);battle.rng=attack_seed(19,6);battle=engine.seal(battle)
 check(engine.active_weapon(battle.units.a)=="unarmed"and kernel.derive_character(clawed).snapshot.capabilities.weapon_damage.unarmed=="1d6","actual equipped unarmed attack uses inherited draconic claws")
 var struck: Dictionary=execute(engine,battle,"attack","bandit-blade")
 check(struck.ok and battle.units["bandit-blade"].record.runtime.hp-struck.battle.units["bandit-blade"].record.runtime.hp==5,"original six-on-d6 claw strike and STR-1 produce real5 damage")
 if struck.ok:battles.draconic_claws=struck.battle
 contracts.ward_and_claws=true
func test_incapacitation() -> void:
 var record: Dictionary=saved_records.form5.duplicate(true);record.runtime.hp=1
 var engine:=TacticalAuras.new(record);var battle: Dictionary=encounter(record);battle.cursor=battle.order.find("bandit-blade");battle.rng=attack_seed(19);battle=engine.seal(battle)
 var hit: Dictionary=engine.command(battle,{"actor_id":"bandit-blade","revision":battle.revision,"kind":"attack","target_id":"a"})
 check(hit.ok and hit.battle.units.a.record.runtime.hp==0,"real incoming attack incapacitates the transformed owner")
 if hit.ok:
  var before: String=RulesJson.digest(hit.battle)
  var denied: Dictionary=engine.command(hit.battle,{"actor_id":"a","revision":hit.battle.revision,"kind":"warshaper-technique-1","target_id":"a"})
  check(not denied.ok and RulesJson.digest(hit.battle)==before and hit.battle.units.a.record.runtime.hp==0,"incapacitated owner cannot act, change form or heal itself")
  saved_records.morph_downed=hit.battle.units.a.record;battles.owner_down=hit.battle
 contracts.incapacitation=true
