extends "res://tests/character_wave_five/mechanics_driver.gd"
## Lawful development histories, not XP grants. Native cold restart is separate.
var records := {}
var battles := {}
var receipts := {}
func run() -> void:
 base=OS.get_environment("GAME129_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack(signature_pack_path())
 check(loaded.ok,"v19 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_signatures();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME129_RESTART")=="1":
  var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
  for id in saved.records:
   var r: Dictionary=saved.records[id];var d := kernel.derive_character(r)
   check(d.ok and d.snapshot.snapshot_hash==saved.hashes[id],"cold exact derived history/resources/features "+id)
   check(RulesJson.digest(r)==saved.record_hashes[id],"cold exact character bytes "+id)
  for id in saved.battles:
   var engine := TacticalAuras.new(saved.battles[id].units.a.record)
   check(engine.validate(saved.battles[id]).is_empty(),"cold tactical validity "+id)
   var next := engine.command(saved.battles[id],saved.next[id])
   check(next.ok and next.battle.state_hash==saved.after[id],"cold next command/log/RNG exact "+id)
  finish_signatures(true);return
 fixtures.fighter=build("fighter",20)
 for cls in ["soulknife","warblade","crusader","swordsage"]:
  for at in [1,4,8,13,20]:
   var r := build(cls,at)
   check(not r.is_empty(),"lawful early/middle/high "+cls+str(at))
   if not r.is_empty():records[cls+str(at)]=r
 if failures:finish_signatures();return
 test_blade();test_confirmed_hits();test_stances();test_riposte();test_afterimage();test_recovery();test_feats();test_multiclass();test_early_late();test_actual_movement();test_adamant();test_counter_defeat();test_virtual_equipment();test_legacy()
 var hashes := {};var record_hashes := {};var after := {};var next := {}
 for id in records:
  # Lawful development records may still contain engine StringName dictionary
  # keys from builder literals. Establish the same primitive JSON boundary used
  # by the production writer BEFORE hashing; no mechanical field is changed.
  var before_record: Dictionary=records[id]
  records[id]=RulesJson.string_keys(before_record)
  check(before_record==records[id],"primitive fixture canonicalisation preserves every field "+id)
  var d := kernel.derive_character(records[id]);check(d.ok,"saved candidate valid "+id)
  if d.ok:hashes[id]=d.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var result := engine.command(battles[id],next[id]);check(result.ok,"predict next command "+id)
  if result.ok:after[id]=result.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 FileAccess.open(base.path_join("traces.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(receipts),"  "))
 finish_signatures()
func finish_signatures(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"xp_injected_into_campaign":false,"classes":["soulknife","warblade","crusader","swordsage"]}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME129 ",JSON.stringify(proof))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
func execute(engine: TacticalAuras,b: Dictionary,kind: String,target := "a") -> Dictionary:
 return engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":kind,"target_id":target})
func manifest(r: Dictionary) -> Dictionary:
 var result := RulesEffects.new(source).use_ability(r,r,"soulknife-manifest",{"main":1,"move":1,"reaction":1},RulesRng.initial("manifest"))
 check(result.ok,"manifest through effect authority")
 return result.get("actor",r)
func test_blade() -> void:
 for at in [1,8,20]:
  var r: Dictionary=records["soulknife"+str(at)].duplicate(true);r.equipment=["shortblade","leathers"]
  var engine := TacticalAuras.new(r);var b := encounter(r)
  check(engine.active_weapon(b.units.a)=="shortblade","held weapon before manifestation")
  var m := execute(engine,b,"soulknife-manifest")
  check(m.ok and engine.active_weapon(m.battle.units.a)=="mind-blade","manifest overrides held weapon "+str(at))
  if not m.ok:continue
  var snap: Dictionary=kernel.derive_character(m.battle.units.a.record).snapshot
  var dice: String=snap.capabilities.weapon_damage.get("mind-blade",source.definition("equipment","mind-blade").damage)
  check(dice==("1d8"if at==1 else"2d6"if at==8 else"2d8"),"real scaling blade dice "+str(at))
  var expired := RulesEffects.new(source).expire_statuses(m.battle.units.a.record.runtime,"global_round_start")
  expired=RulesEffects.new(source).expire_statuses(expired.runtime,"global_round_start");expired=RulesEffects.new(source).expire_statuses(expired.runtime,"global_round_start")
  var unit: Dictionary=m.battle.units.a.duplicate(true);unit.record.runtime=expired.runtime
  check(engine.active_weapon(unit)=="shortblade" and unit.record.equipment==r.equipment,"expiry restores held weapon without equipment mutation")
 var r := manifest(records.soulknife8);var b := encounter(r);var engine := TacticalAuras.new(r)
 b.units["bandit-blade"].position=[2,3];b.rng=attack_seed(19);b=engine.seal(b)
 check(not engine.eligible(b,b.units.a,b.units["bandit-blade"],"soulknife-technique-8"),"melee charge cannot become ranged")
 var hurl := execute(engine,b,"soulknife-hurl","bandit-blade")
 check(hurl.ok and hurl.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp,"hurl actual ranged weapon plus hit rider")
 check(not execute(engine,encounter(records.soulknife8),"soulknife-hurl","bandit-blade").ok,"hurl requires actual manifestation")
 var form: Dictionary=r.duplicate(true);form.runtime.statuses.append({"id":"leopard-form","source":"fixture","remaining":3,"expiry":"global_round_start"})
 check(engine.active_weapon(engine.unit("a","Natural form","party",[1,1],form,"unarmed"))!="mind-blade","natural form wins over manifested weapon")
func test_confirmed_hits() -> void:
 for pair in [["soulknife","soulknife-technique-8"],["warblade","warblade-technique-8"],["crusader","crusader-technique-4"],["swordsage","swordsage-technique-4"]]:
  var r: Dictionary=records[str(pair[0])+"8"]
  if pair[0]=="soulknife":r=manifest(r)
  var engine := TacticalAuras.new(r)
  for hit in [false,true]:
   var b := encounter(r);b.units.a.record.runtime.hp-=5;b.rng=attack_seed(19 if hit else 1);b=engine.seal(b)
   var before := RulesJson.digest(b)
   var attack := execute(engine,b,"attack","bandit-blade")
   var used := execute(engine,b,pair[1],"bandit-blade")
   check(attack.ok and used.ok,"hit/miss actual strike "+pair[1]+str(hit)+str(used.get("error","")))
   if not used.ok or not attack.ok:continue
   check(RulesJson.digest(b)==before,"source battle immutable")
   check(used.battle.budget.main==0,"one real main action")
   for pool in source.definition("abilities",pair[1]).cost.resources:check(used.battle.units.a.record.runtime.resources[pool]==b.units.a.record.runtime.resources[pool]-int(source.definition("abilities",pair[1]).cost.resources[pool]),"resource paid even if missed")
   if not hit:
    check(used.battle.units["bandit-blade"].record.runtime==attack.battle.units["bandit-blade"].record.runtime and used.battle.rng==attack.battle.rng,"miss no rider or rider RNG "+pair[1])
    check(used.battle.units.a.record.runtime.hp==b.units.a.record.runtime.hp and used.battle.units.a.record.runtime.statuses==b.units.a.record.runtime.statuses,"miss no pre-hit healing/stance "+pair[1])
   else:check(used.battle.units["bandit-blade"].record.runtime!=attack.battle.units["bandit-blade"].record.runtime or used.battle.units.a.record.runtime!=attack.battle.units.a.record.runtime,"observable hit-only effect "+pair[1])
   var replay := execute(engine,JSON.parse_string(JSON.stringify(b)),pair[1],"bandit-blade")
   check(replay.ok and replay.battle.state_hash==used.battle.state_hash,"exact deterministic replay "+pair[1])
   check(engine.validate(used.battle).is_empty(),"poststrike native state valid "+pair[1])
   if hit:battles[pair[0]]=used.battle;receipts[pair[1]]=used.battle.log
  var empty := encounter(r)
  for pool in source.definition("abilities",pair[1]).cost.resources:empty.units.a.record.runtime.resources[pool]=0
  empty=engine.seal(empty)
  check(not execute(engine,empty,pair[1],"bandit-blade").ok,"empty resource rejects strike "+pair[1])
  var ranged := encounter(r);ranged.units.a.weapon="bow";ranged.units.a.record.equipment=["bow"];ranged.units.a.record.runtime.statuses=[];ranged=engine.seal(ranged)
  check(not execute(engine,ranged,pair[1],"bandit-blade").ok,"bow cannot execute melee manoeuvre "+pair[1])
 var actor := manifest(records.soulknife8);var b := encounter(actor);var engine := TacticalAuras.new(actor)
 b.units["bandit-blade"].record.runtime.statuses=[{"id":"perfect-shadow","source":"fixture","remaining":2,"expiry":"global_round_start"}];b.rng=attack_seed(1,0,true);b=engine.seal(b)
 var conceal := execute(engine,b,"soulknife-technique-8","bandit-blade")
 check(conceal.ok and conceal.battle.units["bandit-blade"].record.runtime==b.units["bandit-blade"].record.runtime,"concealment miss no psychic rider")
func test_stances() -> void:
 var engine := TacticalAuras.new(records.warblade8);var b := encounter(records.warblade8)
 var stance := execute(engine,b,"warblade-stance-pressure")
 check(stance.ok and stance.battle.budget.main==1 and stance.battle.budget.move==0,"stance spends movement retains attack")
 if not stance.ok:return
 check(not execute(engine,stance.battle,"warblade-stance-shelter").ok,"cannot stance twice with one movement token")
 var changed: Dictionary=stance.battle.duplicate(true);changed.budget.move=1;changed=engine.seal(changed)
 var swapped := execute(engine,changed,"warblade-stance-shelter")
 check(swapped.ok and swapped.battle.units.a.record.runtime.statuses.size()==1 and swapped.battle.units.a.record.runtime.statuses[0].id=="warblade-shelter","stance switch replaces prior modifiers")
func incoming(r: Dictionary,kind := "attack",hit := false) -> Dictionary:
 var engine := TacticalAuras.new(r);var b := encounter(r)
 b.cursor=b.order.find("bandit-blade");b.rng=attack_seed(19 if hit else 1);return engine.seal(b)
func test_riposte() -> void:
 var engine := TacticalAuras.new(records.warblade8);var b := encounter(records.warblade8)
 var arm := execute(engine,b,"warblade-arm-riposte")
 check(arm.ok,"visible arm action valid")
 if not arm.ok:return
 var armed: Dictionary=arm.battle;var attacker := build("fighter",1);attacker.character_id="bandit-blade";attacker.equipment=["shortblade"];armed.units["bandit-blade"].record=attacker;armed.cursor=armed.order.find("bandit-blade");armed.budget={"main":1,"move":1};armed.rng=attack_seed(1);armed=engine.seal(armed)
 var reply := execute(engine,armed,"attack","a")
 check(reply.ok and reply.battle.units.a.reaction==0,"melee miss spends shared reaction on armed riposte")
 if reply.ok:
  check(reply.battle.log.any(func(v: String):return v.contains("triggers Riposte")),"actual counter observable in battle log")
  check(not reply.battle.units.a.record.runtime.statuses.any(func(s: Dictionary):return s.id=="warblade-riposte-ready"),"arm consumed once")
  battles.riposte=reply.battle;receipts.riposte=reply.battle.log
 for reason in ["unarmed","reaction-spent","ranged","hit"]:
  var bad: Dictionary=armed.duplicate(true)
  if reason=="unarmed":bad.units.a.record.runtime.statuses=[]
  if reason=="reaction-spent":bad.units.a.reaction=0
  if reason=="ranged":bad.units["bandit-blade"].weapon="bow";bad.units["bandit-blade"].record.equipment=["bow"]
  if reason=="hit":bad.rng=attack_seed(19)
  bad=engine.seal(bad);var result := execute(engine,bad,"attack","a")
  check(result.ok and not result.battle.log.slice(bad.log.size()).any(func(v: String):return v.contains("triggers Riposte")),"negative riposte trigger "+reason)
 check(not execute(engine,b,"warblade-riposte","bandit-blade").ok,"forged direct counter invocation rejected")
func test_afterimage() -> void:
 var engine := TacticalAuras.new(records.swordsage8);var b := encounter(records.swordsage8)
 var arm := execute(engine,b,"swordsage-arm-afterimage");check(arm.ok,"afterimage explicitly armed")
 if not arm.ok:return
 var armed: Dictionary=arm.battle;var attacker := build("fighter",1);attacker.character_id="bandit-blade";attacker.equipment=["shortblade"];armed.units["bandit-blade"].record=attacker;armed.cursor=armed.order.find("bandit-blade");armed.budget={"main":1,"move":1};armed.rng=attack_seed(19);armed=engine.seal(armed)
 var result := execute(engine,armed,"attack","a")
 check(result.ok and result.battle.units.a.record.runtime.hp<armed.units.a.record.runtime.hp,"afterimage never erases triggering hit")
 if result.ok:check(result.battle.units.a.reaction==0 and kernel.derive_character(result.battle.units.a.record).snapshot.capabilities.concealment==50,"shared reaction grants actual subsequent weapon concealment")
 var miss: Dictionary=armed.duplicate(true);miss.rng=attack_seed(1);miss=engine.seal(miss)
 var denied := execute(engine,miss,"attack","a")
 check(denied.ok and denied.battle.units.a.reaction==1,"melee miss does not trigger afterimage")
func test_recovery() -> void:
 for cls in ["soulknife","warblade","crusader","swordsage"]:
  var r: Dictionary=records[cls+"8"].duplicate(true);var pool: String=cls+("-focus"if cls=="soulknife"else"-readiness");r.runtime.resources[pool]=0
  var engine := TacticalAuras.new(r);var b := encounter(r);b.units.a.record.runtime.resources[pool]=0;b=engine.seal(b)
  var result := execute(engine,b,cls+"-recover")
  check(result.ok and result.battle.units.a.record.runtime.resources[pool]==2,"bounded main recovery "+cls)
  if result.ok:check(result.battle.budget.main==0 and result.battle.budget.move==(0 if cls=="swordsage"else 1),"distinct recovery action budget "+cls)
  var next: Dictionary=b.duplicate(true);next.units.a.record.runtime.resources[pool]=0;next.cursor=(next.order.find("a")-1+next.order.size())%next.order.size();next=engine.seal(next)
  var turn := execute(engine,next,"end")
  check(turn.ok and turn.battle.units.a.record.runtime.resources[pool]==(1 if cls=="crusader"else 0),"own activation recovery class identity "+cls)
func test_feats() -> void:
 var fresh := kernel.create("negative-feat",records.warblade1.base_attributes,"heritage-human")
 var illegal: Dictionary=kernel.suggested_choice(fresh,"warblade","steady-study").choice
 illegal.feat_id="martial-recovery"
 check(not kernel.preview_advancement(fresh,illegal).ok,"martial recovery rejected at level one")
 var r := build_with_feats("warblade",8,{7:"martial-recovery"})
 var pool := "warblade-readiness";r.runtime.resources[pool]=0
 var engine := TacticalAuras.new(r);var b := encounter(r);b.units.a.record.runtime.resources[pool]=0;b.cursor=(b.order.find("a")-1+b.order.size())%b.order.size();b=engine.seal(b)
 var result := execute(engine,b,"end")
 check(result.ok and result.battle.units.a.record.runtime.resources[pool]==1,"feat has actual conditional recovery consumer")
 records.martial_feat=r
 var s := build_with_feats("soulknife",12,{5:"iron-soul",9:"mindblade-echo"});s=manifest(s)
 var battle := encounter(s);battle.rng=attack_seed(19);battle=engine.seal(battle);engine=TacticalAuras.new(s)
 var echo := execute(engine,battle,"attack","bandit-blade")
 check(echo.ok and echo.battle.units.a.reaction==0 and echo.battle.units.a.record.runtime.temporary_hp==6,"feat chain confirmed melee hit consumes reaction for real buffer")
 if echo.ok:battles.echo=echo.battle
 records.echo=s
func build_with_feats(cls: String,level: int,picks: Dictionary,attributes: Dictionary={}) -> Dictionary:
 var first := build(cls,1);var r := kernel.create(cls,first.base_attributes if attributes.is_empty() else attributes,"heritage-human")
 for at in range(1,level+1):
  var choice := kernel.suggested_choice(r,cls,str(picks.get(at,"steady-study")))
  check(choice.ok,"lawful feat chain suggestion "+cls+str(at))
  if not choice.ok:return {}
  if picks.has(at):check(choice.choice.feat_id==picks[at],"requested lawful feat actually selected")
  var step := kernel.preview_advancement(r,choice.choice);check(step.ok,"lawful feat progression "+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  r=step.candidate
 r.equipment=source.definition("classes",cls).recommended_equipment.duplicate();r.runtime.hp=kernel.derive_character(r).snapshot.stats.HP;r.runtime.resources=kernel._replay(r).context.capacities.duplicate();return r
func test_multiclass() -> void:
 var r: Dictionary=records.warblade8.duplicate(true)
 for n in 4:
  var choice := kernel.suggested_choice(r,"swordsage","steady-study");check(choice.ok,"ordered adept multiclass")
  if choice.ok:r=kernel.preview_advancement(r,choice.choice).candidate
 check(kernel.validate_build(r).ok and r.advancement_history[0].class_id=="warblade" and r.advancement_history.back().class_id=="swordsage","ordered multiclass history preserved")
 check(not kernel.available_advancement(records.warblade1).classes.duelist.ok,"ineligible prestige still rejected")
 records.hybrid=r
 var qualified := build_with_feats("warblade",8,{3:"dodge",5:"mobility"},{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8})
 var before := RulesJson.digest(qualified)
 var options := kernel.available_advancement(qualified)
 check(options.ok and options.classes.duelist.ok,"permanent skill/feat/BAB chain recognises earned-eligible path")
 check(RulesJson.digest(qualified)==before and not kernel.derive_character(qualified).snapshot.class_levels.has("duelist"),"eligibility never automatically assigns a path")
 var decline := kernel.suggested_choice(qualified,"warblade","steady-study")
 check(decline.ok and kernel.preview_advancement(qualified,decline.choice).ok,"qualified martial character can decline prestige")
 var selected := kernel.suggested_choice(qualified,"duelist","steady-study")
 var step := kernel.preview_advancement(qualified,selected.choice)
 check(step.ok and step.candidate.advancement_history.back().class_id=="duelist","qualified path selected explicitly in ordered history")
 var unfunded := {"mechanics":{"rules_ref":source.rules_ref(),"records":{qualified.character_id:qualified}}}
 check(not CharacterBuilderRecords.preview_advancement(unfunded,qualified.character_id,selected.choice).ok,"legal class selector never manufactures XP for prestige")
 if step.ok:records.earned_eligible_development_prestige=step.candidate
func test_legacy() -> void:
 var expected: Dictionary={}
 for row in RulesRecords.installed_packs():
  if row.rules_ref.pack_id==RulesRecords.NEW_PACK:expected=RulesJson.normalize(row.rules_ref)
 var fresh := RulesRecords.new_character_registry()
 check(expected.size()==5 and fresh.ready() and fresh.rules_ref()==expected,"source/export default exact full manifest pin: "+RulesJson.canonical({"expected":expected,"actual":fresh.rules_ref(),"errors":fresh.errors}))
 var legacy := RulesRegistry.new();check(legacy.load_pack("res://data/rules/trhgd-character-v18.json").ok,"accepted v18 still exact loadable")
 check(not RulesMartial.enabled(legacy),"new hooks never enter historical v18")
 var effect: Dictionary=legacy.definition("abilities","swordsage-technique-1")
 check(not effect.has("strike_effects") and not legacy.definition("abilities","swordsage-recover").cost.move,"historical pre-hit/recovery policy untouched")

func test_early_late() -> void:
 for cls in ["soulknife","warblade","crusader","swordsage"]:
  for at in [1,20]:
   var r: Dictionary=records[cls+str(at)]
   if cls=="soulknife":r=manifest(r)
   var engine := TacticalAuras.new(r);var battle := encounter(r);battle.rng=attack_seed(19);battle=engine.seal(battle)
   var action: String=cls+("-master-20" if cls in ["soulknife","warblade"] and at==20 else "-technique-"+str(at))
   var result := execute(engine,battle,action,"bandit-blade")
   check(result.ok,"actual early/late signature "+action+str(result.get("error","")))
   if result.ok:
    check(result.battle.budget.main==0 and result.battle.units["bandit-blade"].record.runtime!=battle.units["bandit-blade"].record.runtime,"early/late actual hit/cost "+action)
    records[cls+str(at)+":used"]=result.battle.units.a.record
func test_actual_movement() -> void:
 var r := build("scout",4)
 var choice := kernel.suggested_choice(r,"swordsage","steady-study")
 var advanced := kernel.preview_advancement(r,choice.choice);check(advanced.ok,"legal scout/adept movement interaction")
 if not advanced.ok:return
 r=advanced.candidate;r.equipment=["shortblade"];r.runtime.hp=kernel.derive_character(r).snapshot.stats.HP
 var engine := TacticalAuras.new(r);var b := encounter(r)
 var stance := execute(engine,b,"swordsage-stance-flow");check(stance.ok,"stance spends movement in multiclass")
 if not stance.ok:return
 var ready: Dictionary=stance.battle;ready.rng=attack_seed(19);ready=engine.seal(ready)
 var no_travel := execute(engine,ready,"attack","bandit-blade")
 check(no_travel.ok and not no_travel.battle.log.any(func(v: String):return v.contains("exploits movement")),"stance token spend is not actual skirmish movement")
 var moved := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":"move","destination":[2,0]})
 check(moved.ok,"genuine displacement command")
 if not moved.ok:return
 var travelled: Dictionary=moved.battle;travelled.rng=attack_seed(19);travelled=engine.seal(travelled)
 var hit := execute(engine,travelled,"attack","bandit-blade")
 check(hit.ok and hit.battle.log.any(func(v: String):return v.contains("exploits movement")),"actual movement enables one qualifying skirmish hit")
 records.scout_adept=r
func test_adamant() -> void:
 var r := build_with_feats("warblade",8,{5:"adamant-stance"})
 check(not r.is_empty(),"legal Adamant stance feat prerequisite")
 if r.is_empty():return
 var engine := TacticalAuras.new(r);var b := encounter(r)
 var shelter := execute(engine,b,"warblade-stance-shelter");check(shelter.ok,"explicit shelter stance")
 if not shelter.ok:return
 var incoming: Dictionary=shelter.battle
 var attacker := build("fighter",1);attacker.character_id="bandit-blade";attacker.equipment=["shortblade"];incoming.units["bandit-blade"].record=attacker
 incoming.cursor=incoming.order.find("bandit-blade");incoming.budget={"main":1,"move":1};incoming.rng=attack_seed(19);incoming=engine.seal(incoming)
 var hit := execute(engine,incoming,"attack","a")
 check(hit.ok and hit.battle.units.a.reaction==0 and hit.battle.units.a.record.runtime.temporary_hp==4,"existing feat has actual conditional shared-reaction effect")
 var absent: Dictionary=incoming.duplicate(true);absent.units.a.record.runtime.statuses=[];absent=engine.seal(absent)
 var ignored := execute(engine,absent,"attack","a")
 check(ignored.ok and ignored.battle.units.a.reaction==1 and ignored.battle.units.a.record.runtime.temporary_hp==0,"Adamant answer cannot trigger without shelter")
 records.adamant=r

func encounter(record: Dictionary) -> Dictionary:
 var battle := super.encounter(record)
 if not battle.is_empty():
  battle.units.a.name=source.definition("classes",record.advancement_history[0].class_id).name+" fixture"
  return TacticalAuras.new(record).seal(battle)
 return battle
func test_counter_defeat() -> void:
 var actor := build("monk",1);actor.runtime.hp=1
 var engine := TacticalAuras.new(actor);var battle := encounter(actor)
 var defender: Dictionary=records.warblade8.duplicate(true);defender.character_id="bandit-blade";defender.equipment=["shortblade","mail"]
 var arm := use(defender,defender,"warblade-arm-riposte");check(arm.ok,"opponent legally arms a counter")
 if not arm.ok:return
 battle.units["bandit-blade"].record=arm.actor;battle.units["bandit-blade"].name="Warblade fixture"
 var found := false
 for n in 1000:
  var rng := RulesRng.initial("counter-defeat-"+str(n))
  var first := RulesRng.attack_roll(int(engine.stats(battle.units.a).melee_attack)-2,int(engine.stats(battle.units["bandit-blade"]).defence),source.rule("critical"),rng)
  var reply := RulesRng.attack_roll(int(engine.stats(battle.units["bandit-blade"]).melee_attack),int(engine.stats(battle.units.a).defence),source.rule("critical"),first.rng)
  if not first.hit and reply.hit:battle.rng=rng;found=true;break
 check(found,"numeric miss followed by genuine counter hit fixture")
 if not found:return
 battle=engine.seal(battle)
 var once: Dictionary=battle.duplicate(true)
 engine.weapon_attack(once,once.units.a,once.units["bandit-blade"],false,"flurry")
 check(not engine.alive(once.units.a),"one wounded attacker actually defeated by counter")
 var result := execute(engine,battle,"flurry","bandit-blade")
 check(result.ok,"flurry command resolves despite lethal counter")
 if result.ok:
  check(not engine.alive(result.battle.units.a) and engine.current(result.battle).id!="a" and engine.alive(engine.current(result.battle)),"dead actor cannot keep active turn")
  check(result.battle.rng==once.rng,"lethal counter prevents the remaining flurry strike and its RNG")
  check(result.battle.budget=={"main":1,"move":1},"next living actor receives exactly one normal activation")
  check(engine.validate(result.battle).is_empty(),"counter defeat produces valid saved battle")
  battles.counter_defeat=result.battle;receipts.counter_defeat=result.battle.log

func test_virtual_equipment() -> void:
 for id in ["mind-blade","mind-blade-thrown"]:
  check(not RulesWaveFour.starting_equipment_allowed(source.definition("equipment",id),source),"creator excludes virtual manifestation "+id)
  var forged: Dictionary=records.soulknife1.duplicate(true);forged.equipment=[id]
  check(not kernel.validate_build(forged).ok,"rules authority rejects virtual inventory even for Soulknife "+id)
  var payload := CharacterBuilderRecords.definition(forged)
  check(not CharacterBuilderRecords.create("forged-gear",payload,source.rules_ref()).ok,"forged creation payload cannot purchase a manifestation "+id)
 var engine := TacticalAuras.new(records.soulknife8);var b := encounter(records.soulknife8);b.units.a.weapon="mind-blade";b=engine.seal(b)
 check(not engine.validate(b).is_empty(),"save validation rejects a physical virtual-weapon reference")
 check(not execute(engine,b,"attack","bandit-blade").ok,"forged held-weapon input cannot bypass manifestation")

func signature_pack_path() -> String:return "res://data/rules/trhgd-character-v19.json"
