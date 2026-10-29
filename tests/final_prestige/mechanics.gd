extends "res://tests/final_prestige/probe.gd"
## Lawful DEVELOPMENT builds; actual earned campaigns are separate phases.
var knight_levels := {}
var shadow_levels := []
var defender_levels := []
var roots := {}
var channel_cases := []
var hit_rng := {}
var miss_rng := {}
func run() -> void:
 base=OS.get_environment("FINAL_PRESTIGE_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded: Dictionary=source.load_pack("res://data/rules/trhgd-character-v35.json")
 check(loaded.ok,"complete current35 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_current();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("FINAL_PRESTIGE_RESTART")=="1":cold_cohort();finish_current(true);return
 fixtures.fighter=build("fighter",12);fixtures.defender=warded_defender()
 hit_rng=attack_seed(19,6);miss_rng=attack_seed(1)
 for spec in [["wizard",repeated("wizard",5)+repeated("fighter",2)],["sorcerer",repeated("sorcerer",6)+["fighter"]],["bard",repeated("bard",8)],["beguiler",repeated("beguiler",8)],["duskblade",repeated("duskblade",9)]]:
  var parent: String=spec[0];var attrs: Dictionary=DUAL_ARRAY if parent in ["sorcerer","bard"]else WIZARD_ARRAY
  var record: Dictionary=career_build(spec[1],attrs,"eldritch-knight","heritage-human",{},parent)
  roots[parent]=record;saved_records[parent+"-prefix"]=record.duplicate(true)
  if record.is_empty():continue
  var original_level: int=record.advancement_history.size()
  for at in range(1,6):
   record=career_next(record,"eldritch-knight","eldritch-knight",{},parent)
   if record.is_empty():break
   saved_records[parent+str(at)]=record.duplicate(true);knight_levels[parent]=range(1,at+1)
   var snap: Dictionary=kernel.derive_character(record).snapshot
   check(snap.class_levels["eldritch-knight"]==at and snap.casting_levels[parent]==original_level-(2 if parent=="wizard"else 1 if parent=="sorcerer"else 0)+at,"every Knight level advances only its chosen existing parent "+parent+str(at))
 var shade: Dictionary=career_build(repeated("rogue",5),STEALTH_ARRAY,"shadowdancer")
 saved_records["shadow-prefix"]=shade
 for at in range(1,11):
  shade=career_next(shade,"shadowdancer","shadowdancer")
  if shade.is_empty():break
  saved_records["shadow"+str(at)]=shade.duplicate(true);shadow_levels=range(1,at+1)
  check(kernel.derive_character(shade).snapshot.class_levels.shadowdancer==at,"every supported ordered Shadow level "+str(at))
 var dwarf: Dictionary=career_build(repeated("fighter",5),MARTIAL_ARRAY,"dwarven-defender","heritage-dwarf")
 saved_records["defender-prefix"]=dwarf
 for at in range(1,11):
  dwarf=career_next(dwarf,"dwarven-defender","dwarven-defender")
  if dwarf.is_empty():break
  saved_records["defender"+str(at)]=dwarf.duplicate(true);defender_levels=range(1,at+1)
  check(kernel.derive_character(dwarf).snapshot.class_levels["dwarven-defender"]==at,"every supported ordered Defender level "+str(at))
 if failures:finish_current();return
 test_current_entry();test_channels();test_knight_choices();test_shadow_choices();test_defender_choices();test_current_resources();test_current_suppression();test_current_late()
 persist_cohort();finish_current()
func build_goals(path: String,sequence: Array=[]) -> Dictionary:
 var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new();planner.source=source;planner.kernel=kernel
 var goals: Dictionary=planner.requirements(path,0)
 for cls in sequence:
  if source.definition("classes",cls).get("class_kind")!="prestige"or cls==path:continue
  var extra: Dictionary=planner.requirements(cls,0)
  for node in extra.nodes:
   if not goals.nodes.has(node):goals.nodes.append(node)
  for feat in extra.feats:
   if not goals.feats.has(feat):goals.feats.append(feat)
 planner.free();return goals
func career_build(sequence: Array,attrs: Dictionary,path: String,ancestry := "heritage-human",options: Dictionary={},parent := "") -> Dictionary:
 var r: Dictionary=kernel.create("final-prestige-development",attrs,ancestry);var goals: Dictionary=build_goals(path,sequence)
 for cls in sequence:
  r=career_next(r,cls,path,options,parent,goals)
  if r.is_empty():return {}
 r.equipment=source.definition("classes",sequence[0]).recommended_equipment.duplicate()
 var d: Dictionary=kernel.derive_character(r);check(d.ok,"lawful complete development equipment/history "+path+JSON.stringify(d.get("errors",[])))
 if not d.ok:return {}
 r.runtime.hp=int(d.snapshot.stats.HP);return RulesJson.string_keys(r)
func career_next(record: Dictionary,cls: String,path: String,options: Dictionary={},parent := "",goals: Dictionary={}) -> Dictionary:
 if record.is_empty():check(false,"cannot advance missing lawful fixture");return {}
 var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new();planner.source=source;planner.kernel=kernel
 var target: Dictionary=build_goals(path)if goals.is_empty()else goals
 var proposed: Dictionary=planner.advance(record,cls,target);planner.free()
 check(proposed.ok,"actual legal step "+cls+str(record.advancement_history.size()+1)+JSON.stringify(proposed.get("errors",[])))
 if not proposed.ok:return {}
 var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 if choice.specialisations.has("eldritch-knight-arcane")and not parent.is_empty():choice.specialisations["eldritch-knight-arcane"]=parent
 if choice.specialisations.has("eldritch-channel-3"):choice.specialisations["eldritch-channel-3"]=options.get("eldritch-channel-3","battle-reserve")
 if choice.specialisations.has("eldritch-channel-5"):
  var pool: Array=source.definition("classes","eldritch-knight").career_choices.filter(func(g: Dictionary):return g.id=="eldritch-channel-5")[0].options
  var legal: Array=pool.filter(func(o: Dictionary):return o.id!="battle-reserve"and o.id.begins_with(parent+"-")and int(source.definition("abilities",o.id).get("spell_tier",0))==1)
  check(not legal.is_empty(),"real chosen parent has a lawful tier1 channel fallback")
  if not legal.is_empty():choice.specialisations["eldritch-channel-5"]=options.get("eldritch-channel-5",legal[0].id)
 for group in options:
  if choice.specialisations.has(group):choice.specialisations[group]=options[group]
 if (record.advancement_history.size()+1)%4==0:
  var attribute: String=str(source.definition("classes",parent if not parent.is_empty()and cls=="eldritch-knight"else cls).get("casting_attribute",""))
  choice.attribute_increase=attribute if not attribute.is_empty()else"DEX"if path=="shadowdancer"else"STR"
 choice=align_skills(record,choice)
 var out: Dictionary=kernel.preview_advancement(record,choice);check(out.ok,"explicit choice/attribute preview "+cls+JSON.stringify(out.get("errors",[])))
 return learn(out.candidate,out.snapshot)if out.ok else{}
func real_field(record: Dictionary) -> Dictionary:
 var b: Dictionary=encounter(record);var e:=TacticalAuras.new(record)
 b.units.a.position=[1,3];b.units["bandit-blade"].position=[2,3];b.order=["a","bandit-blade","bandit-bow","b","c"];b.cursor=0
 check(not e.blocked(b,[1,3])and not e.blocked(b,[2,3]),"controlled development positions are genuine clear board tiles")
 return e.seal(b)
func incoming_field(record: Dictionary,ranged := false) -> Dictionary:
 var b: Dictionary=real_field(record);var e:=TacticalAuras.new(record);var attacker: Dictionary=build("fighter",3)
 attacker.character_id="bandit-blade";attacker.equipment=["bow"if ranged else"shortblade"]
 b.units["bandit-blade"].record=attacker;b.units["bandit-blade"].weapon="bow"if ranged else"shortblade"
 return e.seal(b)
func scripted_rng(draws: Array) -> Dictionary:
 for n in 100000:
  var original: Dictionary=RulesRng.initial("final-prestige-scripted-"+str(n));var rng: Dictionary=original;var match_all := true
  for row in draws:
   var draw: Dictionary=RulesRng.roll(row[0],rng);rng=draw.rng
   if int(draw.total)!=int(row[1]):match_all=false;break
  if match_all:return original
 check(false,"original public RNG provides finite scripted development witness");return RulesRng.initial("missing-scripted-witness")
func current_record(b: Dictionary) -> Dictionary:return b.units.a.record
func test_current_entry() -> void:
 for path in ["eldritch-knight","shadowdancer","dwarven-defender"]:
  check(not kernel.starting_classes().has(path),"advanced career is never a starting class "+path)
  var blank: Dictionary=kernel.create("forged-start",WIZARD_ARRAY,"heritage-human")
  var forged: Dictionary={"class_id":path,"feat_id":"steady-study","skill_allocations":{},"attribute_increase":"","specialisations":{},"bonus_feats":[]}
  var denied: Dictionary=kernel.preview_advancement(blank,forged)
  check(not denied.ok and denied.errors.any(func(e: Dictionary):return e.code=="advancement.prestige_start"),"first-history authority independently rejects forged prestige "+path)
 var weak: Dictionary=career_build(["wizard"]+repeated("sorcerer",2)+repeated("fighter",3),DUAL_ARRAY,"eldritch-knight")
 check(not weak.is_empty()and not kernel.available_advancement(weak).classes["eldritch-knight"].ok,"actual tier1 cannot satisfy permanent tier3")
 for key in ["wizard","sorcerer","bard","beguiler","duskblade"]:
  var r: Dictionary=roots[key];var before: String=RulesJson.digest(r)
  check(kernel.available_advancement(r).classes["eldritch-knight"].ok,"actual permanent parent qualifies "+key)
  var alternate: Dictionary=kernel.suggested_choice(r,key);check(alternate.ok and kernel.preview_advancement(r,alternate.choice).ok,"eligible player can decline Knight "+key)
  check(before==RulesJson.digest(r)and not kernel.derive_character(r).snapshot.class_levels.has("eldritch-knight"),"eligibility and previews assign no class")
 var false_parent: Dictionary=kernel.suggested_choice(roots.beguiler,"eldritch-knight")
 false_parent.choice.specialisations["eldritch-knight-arcane"]="wizard"
 check(not kernel.preview_advancement(roots.beguiler,false_parent.choice).ok,"unowned parent cannot borrow progression")
 var human: Dictionary=career_build(repeated("fighter",5),MARTIAL_ARRAY,"dwarven-defender")
 check(not human.is_empty()and not kernel.available_advancement(human).classes["dwarven-defender"].ok,"culture/equipment cannot substitute for actual Dwarf ancestry")
 var junior: Dictionary=career_build(repeated("wizard",5)+["sorcerer"]+repeated("fighter",2)+repeated("eldritch-knight",2),DUAL_ARRAY,"eldritch-knight","heritage-human",{},"sorcerer")
 if not junior.is_empty():
  var d: Dictionary=kernel.derive_character(junior);check(d.snapshot.casting_levels.wizard==5 and d.snapshot.casting_levels.sorcerer==3,"junior selected Sorcerer progresses independently from Wizard")
  saved_records.junior_parent=junior
 for key in ["shadow-prefix","defender-prefix"]:
  var r: Dictionary=saved_records[key];var path: String="shadowdancer"if key.begins_with("shadow")else"dwarven-defender"
  check(kernel.available_advancement(r).classes[path].ok,"permanent ranks/feats/BAB/ancestry entry "+path)
  var alternative: Dictionary=kernel.suggested_choice(r,"rogue"if path=="shadowdancer"else"fighter")
  check(alternative.ok and kernel.preview_advancement(r,alternative.choice).ok,"qualified character can manually decline "+path)
 contracts.entry=true
func test_channels() -> void:
 for id in source.ids("abilities"):
  if not id.begins_with("eldritch-channel-"):continue
  var a: Dictionary=source.definition("abilities",id);var spell: String=a.channel_spell;var parent: String=a.casting_class;var tier: int=a.spell_tier
  var choices: Dictionary={"eldritch-channel-3":spell if tier==1 else"battle-reserve","eldritch-channel-5":"battle-reserve"if tier==1 else spell}
  var r: Dictionary=roots[parent].duplicate(true)
  for n in 5:
   r=career_next(r,"eldritch-knight","eldritch-knight",choices,parent)
   if r.is_empty():break
  if r.is_empty():continue
  r=prep(r,spell);r.equipment=["shortblade","mail","shield"];check(kernel.validate_build(r).ok,"actual selected/prepared channel character "+id)
  saved_records[id]=r;var e:=TacticalAuras.new(r)
  var costs: Array=[]
  for hit in [false,true]:
   var b: Dictionary=real_field(r);b.units["bandit-blade"].record=fixtures.defender.duplicate(true);b.units["bandit-blade"].record.character_id="bandit-blade"
   b.rng=hit_rng if hit else miss_rng;b=e.seal(b)
   check(int(e.stats(b.units.a).melee_attack)+1<int(e.stats(b.units["bandit-blade"]).defence),"lawful defensive equipment creates an actual numeric miss")
   var before: String=RulesJson.digest(b);var plain: Dictionary=execute(e,b,"attack","bandit-blade");var cast: Dictionary=execute(e,b,id,"bandit-blade")
   check(plain.ok and cast.ok,"actual channel command "+id+" hit="+str(hit)+str(cast.get("error","")))
   if not plain.ok or not cast.ok:continue
   check(before==RulesJson.digest(b)and cast.battle.budget=={"main":0,"move":1},"one shared main action; input/RNG untouched by previews")
   for pool in a.cost.resources:check(current_record(cast.battle).runtime.resources[pool]==current_record(b).runtime.resources[pool]-a.cost.resources[pool],"exact original class slot/prepared copy "+id+pool)
   check(current_record(cast.battle).runtime.resources["eldritch-knight-uses"]==current_record(b).runtime.resources["eldritch-knight-uses"],"spell channel never borrows Knight reserve or unrelated focus")
   if hit:
    attacks.hits+=1;var expected: Dictionary=RulesWaveFive.channel_effects(current_record(cast.battle),plain.battle.units["bandit-blade"].record,spell,plain.battle.rng,source)
    check(expected.ok and cast.battle.units["bandit-blade"].record==expected.target and cast.battle.rng==expected.rng,"exactly one original spell effect/save after a real melee hit")
   else:
    attacks.misses+=1;check(cast.battle.units["bandit-blade"].record==plain.battle.units["bandit-blade"].record and cast.battle.rng==plain.battle.rng,"accuracy miss spends slot but delivers no spell effect or save")
   check(execute(e,b,id,"bandit-blade").battle.state_hash==cast.battle.state_hash,"deterministic full channel replay")
   deny(e,cast.battle,spell,"bandit-blade","ordinary casting competes with the channel's spent main")
   costs.append({"hit":hit,"resources":current_record(cast.battle).runtime.resources,"rng":cast.battle.rng});battles[id+("-hit"if hit else"-miss")]=cast.battle
  var dry: Dictionary=real_field(r);var slot: String=parent+"-slots-"+str(tier);dry.units.a.record.runtime.resources[slot]=0;dry=e.seal(dry)
  check(kernel.validate_build(dry.units.a.record).ok,"zero matching slots is a valid exhausted character")
  deny(e,dry,id,"bandit-blade","empty matching caster slot")
  var bow: Dictionary=r.duplicate(true);bow.equipment=["bow","mail","shield"];var ranged: Dictionary=real_field(bow)
  deny(e,ranged,id,"bandit-blade","a bow cannot deliver a melee channel")
  deny(e,real_field(r),id,"b","a hostile weapon/spell cannot target an ally")
  channel_cases.append({"id":id,"spell":spell,"parent":parent,"tier":tier,"cost_cases":costs})
 check(channel_cases.size()==19,"every advertised class-bound delivery reference executes; zero new spell identities")
 var unknown: Dictionary=prep(saved_records["eldritch-channel-sorcerer-enfeeble"],"sorcerer-arcane-bolt");var unknown_engine:=TacticalAuras.new(unknown);var unknown_battle: Dictionary=real_field(unknown)
 check(kernel.validate_build(unknown).ok and unknown.choices.prepared_abilities.has("sorcerer-arcane-bolt")and not unknown.choices.prepared_abilities.has("sorcerer-enfeeble"),"legal spontaneous build with genuinely different permanent knowledge")
 deny(unknown_engine,unknown_battle,"eldritch-channel-sorcerer-enfeeble","bandit-blade","unselected original spontaneous spell cannot be borrowed")
 var saved: Dictionary=saved_records["eldritch-channel-wizard-enfeeble"];var save_engine:=TacticalAuras.new(saved)
 for result in [1,20]:
  var field: Dictionary=real_field(saved);var target: Dictionary=build("fighter",3);target.character_id="bandit-blade";target.equipment=["shortblade"];field.units["bandit-blade"].record=target
  field.rng=scripted_rng([["1d20",19],["1d6",1],["1d20",result]]);field=save_engine.seal(field)
  var cast: Dictionary=execute(save_engine,field,"eldritch-channel-wizard-enfeeble","bandit-blade")
  check(cast.ok,"original channel save resolves "+str(result))
  if cast.ok:check(cast.battle.units["bandit-blade"].record.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened")==bool(result==1),"actual failed/successful Fortitude outcome, no automatic debuff")
 contracts.channels=true
func test_knight_choices() -> void:
 var r: Dictionary=saved_records.wizard5.duplicate(true);r.equipment=["shortblade","mail","shield"];var e:=TacticalAuras.new(r);var b: Dictionary=real_field(r)
 var ward: Dictionary=execute(e,b,"eldritch-knight-power-1","bandit-blade");check(ward.ok,"real equipped spellguard melee action")
 if ward.ok:check(int(e.stats(ward.battle.units.a).defence)>int(e.stats(b.units.a).defence)and ward.battle.budget.main==0,"ward contributes actual defence and competes with casting")
 var ready: Dictionary=execute(e,incoming_field(r),"eldritch-knight-power-3","a");check(ready.ok,"real paid riposte preparation")
 if ready.ok:
  var field: Dictionary=ready.battle;field=e.seal(field);field=turn(e,field,"bandit-blade");field.rng=scripted_rng([["1d20",1],["1d20",19],["1d6",6]]);field=e.seal(field)
  var counter: Dictionary=execute(e,field,"attack","a")
  check(counter.ok and counter.battle.units.a.reaction==0 and counter.battle.units["bandit-blade"].record.runtime.hp<field.units["bandit-blade"].record.runtime.hp,"actual melee-miss counter consumes one shared reaction and lands damage")
  if counter.ok:check(not counter.battle.units.a.record.runtime.statuses.any(func(s: Dictionary):return s.id=="eldritch-knight-power-3-stance"),"riposte readiness consumed on its one counter attempt");battles.knight_counter=counter.battle
  var armed: Dictionary=turn(e,ready.battle,"a");var shield: Dictionary=execute(e,armed,"eldritch-knight-power-5","a")
  check(shield.ok and shield.battle.budget.main==1 and shield.battle.budget.move==1 and shield.battle.units.a.reaction==0 and shield.battle.units.a.record.runtime.hp==armed.units.a.record.runtime.hp,"instant bulwark costs reaction/two uses, preserves main/move and never heals")
  if shield.ok:
   var field2: Dictionary=turn(e,shield.battle,"bandit-blade");field2.rng=miss_rng;field2=e.seal(field2)
   var missed: Dictionary=execute(e,field2,"attack","a")
   check(missed.ok and missed.battle.units["bandit-blade"].record.runtime.hp==field2.units["bandit-blade"].record.runtime.hp and missed.battle.units.a.reaction==0,"spent shield reaction prevents an otherwise armed riposte")
   battles.knight_shield=shield.battle
 contracts.knight=true
func test_shadow_choices() -> void:
 for at in [1,4,7,10]:
  var r: Dictionary=saved_records["shadow"+str(at)];var e:=TacticalAuras.new(r);var b: Dictionary=real_field(r);var aid: String="shadowdancer-technique-"+str(at);var out: Dictionary=execute(e,b,aid,"a")
  check(out.ok,"actual early/mid/late Shadow choice "+str(at))
  if not out.ok:continue
  check(current_record(out.battle).runtime.resources["shadowdancer-uses"]==current_record(b).runtime.resources["shadowdancer-uses"]-(2 if at==10 else 1),"exact finite shadow cost")
  if at==4:
   check(out.battle.budget=={"main":1,"move":0}and not RulesMartial.moved_this_activation(out.battle,"a"),"slipping shroud spends movement but never pretends displacement")
   deny(e,out.battle,aid,"a","movement token cannot be spent twice")
  else:check(out.battle.budget.main==0,"main-funded Shadow action competes with ordinary attacks")
  if at==7:check(kernel.derive_character(current_record(out.battle)).snapshot.tags.has("true_sight"),"temporary unmasking focus genuinely grants engine-recognised detection")
  saved_records["active-shadow"+str(at)]=current_record(out.battle);battles["shadow-action"+str(at)]=out.battle
 var chance := {};var basic: Dictionary=saved_records["active-shadow1"]
 for value in [1,100]:
  var b: Dictionary=incoming_field(basic);var e:=TacticalAuras.new(basic);b=turn(e,b,"bandit-blade");b.rng=scripted_rng([["1d100",value],["1d20",19],["1d6",6]]);b=e.seal(b)
  var hit: Dictionary=execute(e,b,"attack","a");check(hit.ok,"enemy can legally detect/target the shrouded unit")
  if hit.ok:
   var blocked: bool="concealment"in" ".join(hit.battle.log)
   check(blocked==bool(value==1),"real finite weapon miss chance permits both loss and successful targeting")
   chance[str(value)]={"before_hp":b.units.a.record.runtime.hp,"after_hp":hit.battle.units.a.record.runtime.hp,"log":hit.battle.log};battles["shadow-chance"+str(value)]=hit.battle
 observations.shadow_chance=chance
 var double: Dictionary=saved_records["active-shadow10"];var ordinary: Dictionary=saved_records.shadow7;var focused: Dictionary=saved_records["active-shadow7"]
 for sight in [false,true]:
  var attacker: Dictionary=focused if sight else ordinary;var e:=TacticalAuras.new(attacker);var b: Dictionary=real_field(attacker)
  b.units["bandit-blade"].record=double.duplicate(true);b.units["bandit-blade"].record.character_id="bandit-blade";b.rng=hit_rng;b=e.seal(b)
  var before: String=RulesJson.digest(b.rng);var hit: Dictionary=execute(e,b,"attack","bandit-blade");check(hit.ok,"real weapon attempts against one finite double")
  if not hit.ok:continue
  var remains: bool=hit.battle.units["bandit-blade"].record.runtime.statuses.any(func(s: Dictionary):return s.id=="shadowdancer-technique-10-shroud")
  if sight:check(remains and hit.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp,"actual owned unmasking focus bypasses the double; ordinary roll/damage applies")
  else:check(not remains and RulesJson.digest(hit.battle.rng)==before and hit.battle.units["bandit-blade"].record.runtime.hp==b.units["bandit-blade"].record.runtime.hp,"one double consumed before RNG/accuracy/rider; no immunity")
  battles["shadow-double-sight"+str(sight)]=hit.battle
 var caster: Dictionary=prep(saved_records.wizard5,"wizard-arcane-bolt");var spell_engine:=TacticalAuras.new(caster);var spell_battle: Dictionary=real_field(caster)
 spell_battle.units["bandit-blade"].record=double.duplicate(true);spell_battle.units["bandit-blade"].record.character_id="bandit-blade";spell_battle=spell_engine.seal(spell_battle)
 var spell: Dictionary=execute(spell_engine,spell_battle,"wizard-arcane-bolt","bandit-blade")
 check(spell.ok and spell.battle.units["bandit-blade"].record.runtime.hp<spell_battle.units["bandit-blade"].record.runtime.hp and spell.battle.units["bandit-blade"].record.runtime.statuses.any(func(s: Dictionary):return s.id=="shadowdancer-technique-10-shroud"),"ordinary hostile spell bypasses the finite weapon-only double")
 for key in ["shadow-action1","shadow-action4","shadow-action7","shadow-action10"]:
  var field: Dictionary=battles[key];var e2:=TacticalAuras.new(field.units.a.record);var expired: Dictionary=rounds(e2,field,3)
  check(not current_record(expired).runtime.statuses.any(func(s: Dictionary):return s.id.begins_with("shadowdancer-technique-")),"ordinary global expiry removes concealment/detection/double without moving identity")
 contracts.shadow=true
func test_defender_choices() -> void:
 for at in [1,4,7,10]:
  var r: Dictionary=saved_records["defender"+str(at)];var e:=TacticalAuras.new(r);var b: Dictionary=real_field(r);var aid: String="dwarven-defender-technique-"+str(at);var out: Dictionary=execute(e,b,aid,"a")
  check(out.ok,"actual paid Defender stance "+str(at))
  if not out.ok:continue
  var d: Dictionary=kernel.derive_character(current_record(out.battle))
  check(d.snapshot.capabilities.immobile and e.paths(out.battle,out.battle.units.a).is_empty()and out.battle.budget.move==0,"stance genuinely consumes movement and prevents legal displacement")
  check(out.battle.budget.main==(1 if at==4 else 0),"fast bulwark versus full-turn anchor is a real main-action trade-off")
  check(int(d.snapshot.stats.defence)>int(e.stats(b.units.a).defence),"retain working armour-stacking defensive contribution")
  if at==7:check(d.snapshot.stats.reach==kernel.derive_character(r).snapshot.stats.reach+1,"line stance extends real melee threat instead of only describing reach")
  var before: String=RulesJson.digest(out.battle)
  check(e.paths(b,b.units.a).has(str([1,4])),"the tested movement destination is genuinely reachable before anchoring")
  var passed: Dictionary=execute(e,out.battle,"end");check(passed.ok,"anchored activation may end normally")
  if passed.ok:
   var renewed: Dictionary=turn(e,passed.battle,"a");var unchanged: String=RulesJson.digest(renewed)
   var moved: Dictionary=e.command(renewed,{"actor_id":"a","revision":renewed.revision,"kind":"move","destination":[1,4]})
   check(renewed.budget.move==1 and not moved.ok and unchanged==RulesJson.digest(renewed),"a genuine unspent movement token cannot bypass active stance immobility")
  check(before==RulesJson.digest(out.battle),"failed movement leaves the exact battle untouched")
  saved_records["active-defender"+str(at)]=current_record(out.battle);battles["defender-stance"+str(at)]=out.battle
 var high_record: Dictionary=saved_records.defender10;var defender_engine:=TacticalAuras.new(high_record);var high_battle: Dictionary=incoming_field(high_record)
 var stance: Dictionary=execute(defender_engine,high_battle,"dwarven-defender-technique-1","a");check(stance.ok,"genuine paid stance before counter")
 if stance.ok:
  var field: Dictionary=turn(defender_engine,stance.battle,"bandit-blade");field.rng=scripted_rng([["1d20",1],["1d20",19],["1d6",6]]);field=defender_engine.seal(field)
  var counter: Dictionary=execute(defender_engine,field,"attack","a")
  check(counter.ok and counter.battle.units.a.reaction==0 and counter.battle.units["bandit-blade"].record.runtime.hp<field.units["bandit-blade"].record.runtime.hp,"living anchored Defender actually counters an incoming melee miss")
  if counter.ok:battles.defender_counter=counter.battle
  var ranged: Dictionary=incoming_field(current_record(stance.battle),true);ranged=turn(defender_engine,ranged,"bandit-blade");ranged.rng=miss_rng;ranged=defender_engine.seal(ranged)
  var arrow: Dictionary=execute(defender_engine,ranged,"attack","a")
  check(arrow.ok and arrow.battle.units.a.reaction==1,"a ranged miss does not trigger a melee counter")
 var line:=TacticalAuras.new(high_record);var wide: Dictionary=real_field(high_record);wide.units["bandit-blade"].position=[3,3];wide=line.seal(wide)
 var widened: Dictionary=execute(line,wide,"dwarven-defender-technique-7","a");check(widened.ok,"same late Defender chooses actual line stance")
 if widened.ok:
  var after_end: Dictionary=execute(line,widened.battle,"end");var fresh: Dictionary=turn(line,after_end.battle,"a")
  fresh.rng=hit_rng;fresh=line.seal(fresh);var reached: Dictionary=execute(line,fresh,"attack","bandit-blade")
  check(reached.ok and reached.battle.units["bandit-blade"].record.runtime.hp<fresh.units["bandit-blade"].record.runtime.hp,"line stance actually strikes an enemy two tiles away")
  if reached.ok:
   var ended: Dictionary=execute(line,reached.battle,"end");var next: Dictionary=turn(line,ended.battle,"a");var change: Dictionary=execute(line,next,"dwarven-defender-technique-10","a")
   check(change.ok,"player deliberately trades coverage for heavier redoubt")
   if change.ok:
    check(current_record(change.battle).runtime.statuses.filter(func(s: Dictionary):return source.definition("statuses",s.id).get("stance_group")=="martial-stance").size()==1,"exclusive stances never stack defence/reach")
    check(not line.eligible(change.battle,change.battle.units.a,change.battle.units["bandit-blade"],"attack"),"redoubt returns ordinary reach; no inherited line exploit")
 for key in ["defender-stance1","defender-stance4","defender-stance7","defender-stance10"]:
  var field: Dictionary=battles[key];var e2:=TacticalAuras.new(field.units.a.record);var ended: Dictionary=rounds(e2,field,4)
  check(not kernel.derive_character(current_record(ended)).snapshot.capabilities.immobile and not e2.paths(ended,ended.units.a).is_empty(),"actual expiry restores normal movement")
 contracts.defender=true
func test_current_resources() -> void:
 for spec in [["wizard5","eldritch-knight-power-3","eldritch-knight-uses"],["shadow10","shadowdancer-technique-7","shadowdancer-uses"],["defender10","dwarven-defender-technique-1","dwarven-defender-uses"]]:
  var r: Dictionary=saved_records[spec[0]];var e:=TacticalAuras.new(r);var b: Dictionary=real_field(r);var cap: int=current_record(b).runtime.resources[spec[2]]
  for n in cap:
   b=turn(e,b,"a");var out: Dictionary=execute(e,b,spec[1],"a");check(out.ok,"actual paid reserve depletion "+str(spec[1]))
   if not out.ok:break
   b=out.battle;check(current_record(b).runtime.resources[spec[2]]==cap-n-1,"exact finite uses decline through real actions")
  b=turn(e,b,"a");deny(e,b,spec[1],"a","genuinely exhausted reserve")
  var record: Dictionary=current_record(b);var derived: Dictionary=kernel.derive_character(record);var rest: Dictionary=RulesEffects.new(source).refresh_resources(record.runtime,derived.snapshot.resource_capacities,"eligible_rest")
  check(rest.ok and rest.runtime.resources[spec[2]]==derived.snapshot.resource_capacities[spec[2]],"shared eligible-rest policy restores the actual reserve")
  saved_records[str(spec[0])+"-exhausted"]=record;battles[str(spec[0])+"-exhausted"]=b
 contracts.resources=true
func test_current_suppression() -> void:
 var druid: Dictionary=prep(build("druid",20),"druid-wildheart-mantle")
 for spec in [["wizard5","eldritch-knight-power-1","bandit-blade"],["shadow10","shadowdancer-technique-1","a"],["shadow10","shadowdancer-technique-4","a"],["shadow10","shadowdancer-technique-7","a"],["shadow10","shadowdancer-technique-10","a"]]:
  var r: Dictionary=saved_records[spec[0]];var altered: Dictionary=use(druid,r,"druid-wildheart-mantle");check(altered.ok,"actual ally spell produces the existing magic-suppressed body")
  if altered.ok:
   var e:=TacticalAuras.new(altered.target);var b: Dictionary=real_field(altered.target);deny(e,b,spec[1],spec[2],"supernatural activation suppressed without spending reserve")
   saved_records[str(spec[0])+"-body"]=altered.target
 for spec in [["wizard5","eldritch-knight-power-5"],["shadow10","shadowdancer-technique-7"],["defender10","dwarven-defender-technique-4"]]:
  var r: Dictionary=saved_records[spec[0]].duplicate(true);r.runtime.hp=1;var e:=TacticalAuras.new(r);var b: Dictionary=incoming_field(r);b=turn(e,b,"bandit-blade");b.rng=hit_rng;b=e.seal(b)
  var down: Dictionary=execute(e,b,"attack","a");check(down.ok and down.battle.units.a.record.runtime.hp==0,"real incoming strike incapacitates the actual career")
  if down.ok:
   var before: String=RulesJson.digest(down.battle);var out: Dictionary=e.command(down.battle,{"actor_id":"a","revision":down.battle.revision,"kind":spec[1],"target_id":"a"})
   check(not out.ok and RulesJson.digest(down.battle)==before,"downed actor cannot activate/refill a career power")
   battles[str(spec[0])+"-downed"]=down.battle
 contracts.suppression=true
func test_current_late() -> void:
 for spec in [["wizard5","wizard","eldritch-knight"],["sorcerer5","sorcerer","eldritch-knight"],["shadow10","rogue","shadowdancer"],["defender10","fighter","dwarven-defender"]]:
  var r: Dictionary=saved_records[spec[0]]
  while r.advancement_history.size()<20:
   r=career_next(r,spec[1],spec[2],{},spec[1]if spec[2]=="eldritch-knight"else"")
   if r.is_empty():break
  if r.is_empty():continue
  check(r.advancement_history.size()==20 and not kernel.available_advancement(r).classes[spec[1]].ok,"actual total20 ceiling, labelled development fixture")
  saved_records[str(spec[0])+"-total20"]=r
 contracts.late=true
func finish_current(restart := false) -> void:
 var proof: Dictionary={"checks":checks,"failures":failures,"failed_checks":failed_checks,"rules_ref":source.rules_ref(),"contracts":contracts,"attacks":attacks,"knight_levels":knight_levels,"shadow_levels":shadow_levels,"defender_levels":defender_levels,"channel_cases":channel_cases,"observations":observations,"development_fixtures":true,"earned_xp":false}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof)))
 print("FINAL_PRESTIGE_CURRENT ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)

func align_skills(record: Dictionary,choice: Dictionary) -> Dictionary:
 var summary: Dictionary=kernel.preview_choices(record,choice.class_id,{"attribute_increase":choice.attribute_increase})
 check(summary.ok,"actual selected-attribute skill budget")
 if not summary.ok:return choice
 var spent := 0
 for amount in choice.skill_allocations.values():spent+=int(amount)
 var excess: int=spent-int(summary.skill_points);var order: Array=choice.skill_allocations.keys();order.reverse()
 for id in order:
  if excess<=0:break
  var removed: int=mini(excess,int(choice.skill_allocations[id]));choice.skill_allocations[id]-=removed;excess-=removed
  if choice.skill_allocations[id]==0:choice.skill_allocations.erase(id)
 var missing: int=int(summary.skill_points)-mini(spent,int(summary.skill_points))
 for id in summary.skill_rank_room:
  if missing<=0:break
  var room: int=int(summary.skill_rank_room[id])-int(choice.skill_allocations.get(id,0));var add: int=mini(missing,room)
  if add>0:choice.skill_allocations[id]=int(choice.skill_allocations.get(id,0))+add;missing-=add
 check(missing==0,"exact remaining skill points assigned legally")
 return choice
