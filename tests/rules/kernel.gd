extends SceneTree
var checks := 0
var failures := 0
var registry := RulesRegistry.new()
var characters: RulesCharacter
var effects: RulesEffects
var timings := {}
var golden := {}
func check(value: bool,why: String) -> void:
 checks+=1
 if not value: failures+=1;push_error(why)
func _initialize() -> void: call_deferred("run")
func build(role: String,sequence: Array,prestige: bool = false) -> Dictionary:
 var r := registry.recommendation(role)
 var record := characters.create("reference:"+role+":"+RulesJson.digest(sequence).left(12),r.attributes,"heritage-human")
 record.equipment=r.equipment.duplicate()
 for i in sequence.size():
  var feat: String= "veiled-casting" if prestige and i==2 else (r.feat if i==0 else "steady-study")
  var suggestion := characters.suggested_choice(record,sequence[i],feat)
  if not suggestion.ok: check(false,"suggest "+str(suggestion));return {}
  var result := characters.apply_advancement(record,suggestion.choice,int(record.revision))
  if not result.ok: check(false,"advance "+str(i)+" "+str(result));return {}
  check(result.snapshot.level==i+1,"ordered total level")
  check(RulesJson.digest(record)==result.before_hash,"pure preview")
  record=result.candidate
 return record
func negative_content() -> void:
 var source := registry.source_data()
 var fixtures: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/rules/fixtures/negative-content.json"))
 for fixture in fixtures:
  var kind: String=fixture.case
  var p := source.duplicate(true)
  var parent: Variant=p
  for i in fixture.path.size()-1: parent=parent[fixture.path[i]]
  parent[fixture.path[-1]]=fixture.value.duplicate(true) if fixture.value is Array or fixture.value is Dictionary else fixture.value
  var other := RulesRegistry.new()
  var result := other.load_data(p)
  check(not result.ok and not other.ready() and not result.errors.is_empty(),"reject content: "+kind)
  golden["negative:"+kind]=result.errors[0].code
func run() -> void:
 var start := Time.get_ticks_usec()
 var loaded := registry.load_pack()
 timings.registry_load_us=Time.get_ticks_usec()-start
 check(loaded.ok,"validated original content "+str(loaded))
 if not loaded.ok: finish();return
 characters=RulesCharacter.new(registry);effects=RulesEffects.new(registry)
 negative_content()
 var records := {}
 start=Time.get_ticks_usec()
 records.martial=build("vanguard",Array(range(20)).map(func(_i: int): return "roadwarden"))
 records.skirmisher=build("scout",Array(range(20)).map(func(_i: int): return "wayfinder"))
 records.arcane=build("adept",Array(range(20)).map(func(_i: int): return "lantern-adept"))
 records.mixed=build("scout",Array(range(20)).map(func(i: int): return "roadwarden" if i%2==0 else "wayfinder"))
 records.arcane_mixed=build("adept",Array(range(20)).map(func(i: int): return "lantern-adept" if i%2==0 else "wayfinder"))
 records.prestige=build("adept",Array(range(20)).map(func(i: int): return "lantern-adept" if i<4 or i>=14 else "veil-adept"),true)
 timings.reference_progression_us=Time.get_ticks_usec()-start
 if records.values().any(func(r: Dictionary): return r.is_empty()): finish();return
 for name in records:
  var derived := characters.derive_character(records[name])
  check(derived.ok and derived.snapshot.is_read_only() and derived.snapshot.stats.is_read_only(),"deep immutable snapshot "+name)
  golden[name]={"snapshot_hash":derived.snapshot.snapshot_hash,"stats":derived.snapshot.stats,"capacities":derived.snapshot.resource_capacities,"classes":derived.snapshot.class_levels}
  check(not characters.available_advancement(records[name]).classes["roadwarden"].ok,"level20 cap "+name)
 # Independently calculated expectations anchor the golden oracle to the V1 data.
 var level20_expected := {"martial":{"HP":166,"BAB":20,"fortitude":14,"reflex":7,"will":16},"skirmisher":{"HP":106,"BAB":15,"fortitude":7,"reflex":17,"will":16},"arcane":{"HP":86,"BAB":10,"fortitude":7,"reflex":7,"will":23},"mixed":{"HP":126,"BAB":17,"fortitude":11,"reflex":15,"will":16},"arcane_mixed":{"HP":96,"BAB":12,"fortitude":7,"reflex":11,"will":21},"prestige":{"HP":86,"BAB":10,"fortitude":7,"reflex":7,"will":25}}
 for name in level20_expected:
  for stat in level20_expected[name]: check(golden[name].stats[stat]==level20_expected[name][stat],"independent level20 "+name+" "+stat)
 var first := build("vanguard",["roadwarden"])
 var first_adept := build("adept",["lantern-adept"])
 check(characters.derive_character(first).snapshot.stats.HP==14,"independent initial martial HP6+6+CON2")
 check(characters.derive_character(first).snapshot.stats.defence==16,"initial defence10+DEX1+mail3+shield1+training1")
 check(characters.derive_character(first_adept).snapshot.resource_capacities.focus==2,"initial focus2")
 check(not characters.available_advancement(first_adept).classes["veil-adept"].ok,"early prestige blocked")
 var suggestion := characters.suggested_choice(first,"wayfinder")
 start=Time.get_ticks_usec()
 for i in 2000:
  var advanced := characters.preview_advancement(first,suggestion.choice)
  check(advanced.ok and advanced.snapshot.class_levels=={"roadwarden":1,"wayfinder":1},"stress pure multiclass progression")
 timings.progression_2000_us=Time.get_ticks_usec()-start
 var options := characters.preview_choices(first,"wayfinder")
 check(options.ok and options.level==2 and options.skill_points==4 and options.feat_choices.is_empty(),"partial next-level option preview")
 check(not characters.preview_choices(first,"veil-adept").ok,"option preview explains invalid prestige entry")
 var before := RulesJson.canonical(first)
 for i in 400:
  var invalid: Dictionary=suggestion.choice.duplicate(true)
  match i%5:
   0: invalid.class_id="absent"
   1: invalid.skill_allocations={"absent":1}
   2: invalid.feat_id="steady-study" # level2 has no feat
   3: invalid.attribute_increase="STR" # level2 has no increase
   4: invalid.skill_allocations=[]
  check(not characters.apply_advancement(first,invalid,int(first.revision)).ok,"invalid advancement is rejected")
  check(RulesJson.canonical(first)==before,"invalid progression preserves source bytes")
 check(not characters.apply_advancement(first,suggestion.choice,0).ok,"stale revision")
 var malformed := first.duplicate(true);malformed.base_attributes.STR=null
 check(not characters.validate_build(malformed).ok,"malformed attributes reject without sorting invalid values")
 malformed=first.duplicate(true);malformed.runtime.senses=[42]
 check(not characters.validate_build(malformed).ok,"malformed senses reject before derivation")
 malformed=first.duplicate(true);malformed.runtime.granted_features=["steady-study","steady-study"]
 check(not characters.validate_build(malformed).ok,"duplicate runtime feature cannot multiply untyped grants")
 start=Time.get_ticks_usec()
 for i in 1000:
  var chosen: Dictionary=records.values()[i%6]
  var restored: Dictionary=RulesJson.normalize(JSON.parse_string(RulesJson.canonical(chosen)))
  check(characters.derive_character(restored).snapshot.snapshot_hash==golden[records.keys()[i%6]].snapshot_hash,"serialization snapshot equivalence")
 timings.serialization_1000_us=Time.get_ticks_usec()-start
 var context: Dictionary=characters.derive_character(records.prestige).context
 var requirements := {"op":"all","args":[{"op":"level","min":20},{"op":"any","args":[{"op":"attribute","id":"INT","min":13},{"op":"feat","id":"absent"}]},{"op":"not","arg":{"op":"tag","id":"absent"}},{"op":"class_level","id":"veil-adept","min":10},{"op":"skill","id":"arcana","min":4},{"op":"feature","id":"veil-savant"},{"op":"bab","min":1},{"op":"save","id":"will","min":1},{"op":"casting","id":"arcane","min":2},{"op":"resource","id":"focus","min":2},{"op":"ancestry","id":"mortal"}]}
 start=Time.get_ticks_usec()
 for i in 5000: check(RulesExpressions.evaluate_requirements(requirements,context).ok,"5000 compound prerequisite evaluations")
 timings.requirements_5000_us=Time.get_ticks_usec()-start
 check(RulesExpressions.evaluate_formula({"op":"floor_divide","args":[{"op":"const","value":-3},{"op":"const","value":2}]},{}).value==-2,"negative floor division")
 check(not RulesExpressions.evaluate_formula({"op":"floor_divide","args":[{"op":"const","value":1},{"op":"const","value":0}]},{}).ok,"zero divisor runtime reject")
 var mods := [{"source":"a","type":"armor","value":2},{"source":"b","type":"armor","value":4},{"source":"c","type":"armor","value":-2},{"source":"d","type":"armor","value":-3},{"source":"e","type":"untyped","value":2},{"source":"f","type":"untyped","value":2}]
 check(RulesModifiers.combine(10,mods,{}).value==15,"typed highestbonus/worstpenalty; untyped stack")
 mods.reverse();check(RulesModifiers.combine(10,mods,{}).value==15,"modifier input permutation")
 var rng1 := RulesRng.initial("GAME32-cross-platform");var rng2 := rng1.duplicate(true);var sequence: Array=[]
 for i in 10000:
  var one := RulesRng.draw(rng1,20);var two := RulesRng.draw(rng2,20)
  check(one==two and one.value>=1 and one.value<=20,"10000 explicit RNG equivalence draws")
  rng1=one.rng;rng2=two.rng;sequence.append(one.value)
 golden.rng_sha=RulesJson.digest(sequence)
 check(rng1.counter==10000,"explicit counter preserved")
 check(not RulesRng.parse_dice("1d20;execute").ok and not RulesRng.roll("1d1",rng1).ok,"safe dice only")
 check(RulesRng.roll("2d6+3",rng1)==RulesRng.roll({"count":2,"sides":6,"bonus":3},rng1),"dice syntax equivalence")
 var attack := RulesRng.attack_roll(100,10,registry.rule("critical"),RulesRng.initial("critical"))
 check(attack.ok and attack.hit,"numeric attack contest")
 var changed_critical := {"natural":2,"bonus_damage":9}
 var critical := RulesRng.attack_roll(100,10,changed_critical,RulesRng.initial("critical"))
 check(critical.critical==true and critical.critical_bonus==9 and critical.rng==attack.rng,"critical metadata is configurable without extra random draws")
 var failures_by_context := {"level":0,"classes":{},"skills":{},"feats":[],"attributes":{"INT":8},"casting":{}}
 var failed := RulesExpressions.evaluate_requirements(registry.definition("classes","veil-adept").requirements,failures_by_context)
 for code in ["requirement.level","requirement.attribute","requirement.skill","requirement.feat","requirement.casting"]:
  check(failed.errors.any(func(e: Dictionary): return e.code==code),"prestige structured failure "+code)
 var status_pack := registry.source_data();status_pack.statuses[0].effects=[{"op":"temporary_hp","amount":{"op":"const","value":3}}]
 var status_registry := RulesRegistry.new();check(status_registry.load_data(status_pack).ok,"noncyclic declarative status effects validate")
 var status_effect := RulesEffects.new(status_registry).resolve_rules_effect({"op":"apply_status","id":"slowed"},first_adept.runtime,first.runtime,{},RulesRng.initial("status"))
 check(status_effect.ok and status_effect.target.temporary_hp==3,"status effects execute through generic effect vocabulary")
 var external_pack := registry.source_data();external_pack.equipment[0].requirements={"op":"not","arg":{"op":"tag","id":"frontliner"}}
 var external_registry := RulesRegistry.new();check(external_registry.load_data(external_pack).ok,"tag-based equipment requirement validates")
 var external_character := RulesCharacter.new(external_registry)
 var external_record := first_adept.duplicate(true);external_record.rules_ref=external_registry.rules_ref();external_record.equipment.append("shortblade")
 check(external_character.derive_character(external_record).ok,"equipment legal before external feature grant")
 external_record.runtime.granted_features=["held-ground"]
 check(not external_character.derive_character(external_record).ok,"external feature tags explain current equipment conflict")
 var external_grant := effects.resolve_rules_effect({"op":"grant_feature","id":"light-step"},first_adept.runtime,first_adept.runtime,{},RulesRng.initial("external-grant"))
 var granted_record := first_adept.duplicate(true);granted_record.runtime=external_grant.target
 var granted := characters.derive_character(granted_record)
 check(granted.ok and granted.snapshot.stats.stride==5 and granted.snapshot.tags.has("mobile") and granted.snapshot.features.has("light-step"),"non-class feature grants tags and mechanics through existing extensions")
 var entry_pack := registry.source_data();entry_pack.classes[1].requirements={"op":"tag","id":"mobile"}
 var entry_registry := RulesRegistry.new();check(entry_registry.load_data(entry_pack).ok,"temporary-qualification fixture validates")
 var entry_character := RulesCharacter.new(entry_registry)
 var entry_record := first_adept.duplicate(true);entry_record.rules_ref=entry_registry.rules_ref();entry_record.runtime.granted_features=["light-step"]
 check(entry_character.derive_character(entry_record).snapshot.tags.has("mobile"),"temporary grants remain available to current abilities and snapshots")
 check(not entry_character.available_advancement(entry_record).classes["wayfinder"].ok and not entry_character.preview_choices(entry_record,"wayfinder").ok,"entry preview agrees with replay rather than using temporary qualification")
 var entry_choice := entry_character.suggested_choice(entry_record,"wayfinder")
 check(entry_choice.ok and not entry_character.preview_advancement(entry_record,entry_choice.choice).ok,"unqualified advancement agrees with the rejected option")
 var skill_pack := registry.source_data();skill_pack.skills[0].modifiers=[{"type":"circumstance","value":{"op":"const","value":2}}]
 var skill_registry := RulesRegistry.new();check(skill_registry.load_data(skill_pack).ok,"data-driven skill modifier validates")
 var skill_character := RulesCharacter.new(skill_registry)
 var skill_record := first.duplicate(true);skill_record.rules_ref=skill_registry.rules_ref()
 check(skill_character.derive_character(skill_record).snapshot.skills.athletics.total==characters.derive_character(first).snapshot.skills.athletics.total+2,"skill modifiers derive through generic stacking")
 effect_checks(first,first_adept,records.prestige)
 start=Time.get_ticks_usec()
 for i in 1000: check(characters.derive_character(first_adept).ok,"1000 derivations")
 timings.derive_1000_us=Time.get_ticks_usec()-start
 start=Time.get_ticks_usec()
 for i in 1000: check(characters.validate_build(first_adept).ok,"1000 build validations")
 timings.validation_1000_us=Time.get_ticks_usec()-start
 check(not RulesModifiers.combine(10,[{"type":"unregistered","value":1,"source":"invalid"}],{}).ok,"unknown modifier type rejected")
 check(not RulesModifiers.combine(10,[{"type":"untyped","value":1,"source":"invalid","when":{"op":"execute"}}],{}).ok,"malformed conditional modifier rejected")
 check(registry.loads==1,"registry loaded once across stress loops")
 finish()
func effect_checks(martial: Dictionary,adept: Dictionary,prestige: Dictionary) -> void:
 var rng := RulesRng.initial("effects");var budget := {"move":1,"main":1,"reaction":1}
 var actor_before := RulesJson.canonical(adept);var target_before := RulesJson.canonical(martial)
 var cast := effects.use_ability(adept,martial,"spark",budget,rng)
 check(cast.ok and cast.budget.main==0 and cast.target.runtime.hp<martial.runtime.hp and cast.rng.counter>0,"damage/rng/action cost")
 check(cast==effects.use_ability(adept,martial,"spark",budget,rng),"effect exact deterministic repeat")
 var damaged: Dictionary=cast.target
 var heal := effects.use_ability(adept,damaged,"healing-thread",budget,rng)
 check(heal.ok and heal.target.runtime.hp<=characters.derive_character(martial).snapshot.stats.HP and heal.actor.runtime.resources.focus==1,"healing clamp and focus spend")
 var drained: Dictionary=adept.duplicate(true);drained.runtime.resources.focus=0
 check(not effects.use_ability(drained,martial,"slow",budget,rng).ok,"no negative resource")
 check(not effects.use_ability(adept,martial,"slow",{"move":1,"main":0,"reaction":1},rng).ok,"spent main prevents second ability")
 check(not effects.use_ability(prestige,martial,"delayed-burst",budget,{}).ok,"deferred ability also validates RNG")
 var delayed := effects.use_ability(prestige,martial,"delayed-burst",budget,rng)
 check(delayed.ok and delayed.target==martial and delayed.actor.runtime.resources.focus==prestige.runtime.resources.focus-1 and delayed.rng==rng and delayed.has("deferred"),"delay is paid intent without scheduling/damage")
 check(not effects.use_ability(adept,martial,"spark",budget,rng,{"stats":{"HP":999}}).ok,"caller cannot override authoritative stats")
 var illusion := effects.use_ability(adept,martial,"apparent-wall",budget,rng,{"event_id":"wall1"})
 check(illusion.ok and illusion.actor.runtime.apparent_effects[0].collision==false,"illusory wall nonphysical")
 var descriptor: Dictionary=illusion.actor.runtime.apparent_effects[0]
 var visible := RulesEffects.public_appearance(descriptor)
 check(visible.size()==3 and not visible.has("kind") and not visible.has("source_character_id") and visible.apparent_id.begins_with("apparent:"),"public projection hides authority truth")
 check(not effects.use_ability(martial,adept,"departure-attack",budget,rng).ok,"reaction requires explicit departure trigger")
 var departure := effects.use_ability(martial,adept,"departure-attack",budget,rng,{"trigger":"leave_melee_threat"})
 check(departure.ok and departure.budget.reaction==0,"departure uses same shared reaction")
 var second := effects.use_ability(illusion.actor,martial,"false-guard",budget,rng,{"event_id":"wall2"})
 check(second.ok and second.actor.runtime.apparent_effects.size()==1 and second.actor.runtime.apparent_effects[0].apparent_id!=descriptor.apparent_id,"maintained illusion replacement")
 var hook := effects.use_ability(prestige,martial,"veil-echo",budget,rng,{"trigger":"illusion_disbelieved","apparent_id":descriptor.apparent_id,"observer_id":"observer"})
 check(hook.ok and hook.budget.reaction==0 and hook.events.any(func(e: Dictionary): return e.type=="hook_intent"),"original prestige trusted hook")
 check(not effects.use_ability(hook.actor,martial,"veil-echo",hook.budget,rng,{"trigger":"illusion_disbelieved","apparent_id":descriptor.apparent_id,"observer_id":"observer"}).ok,"one shared reaction for all kinds")
 check(effects.activation_budget(0).budget.reaction==0,"activation does not refresh reaction")
 check(not effects.refresh_shared_reaction(hook.budget,"source_activation_start").ok,"activation cannot refresh shared reaction")
 check(effects.refresh_shared_reaction(hook.budget,"global_round_start").budget.reaction==1,"explicit global-round reaction refresh")
 var encounter_runtime: Dictionary=martial.runtime.duplicate(true);encounter_runtime.resources={"stamina":0}
 check(effects.refresh_resources(encounter_runtime,{"stamina":2},"encounter").runtime.resources.stamina==2,"generic encounter pool refresh")
 check(effects.refresh_resources(encounter_runtime,{"stamina":2},"daily").runtime.resources.stamina==0,"refresh scopes do not cross-refill")
 for scope in ["short_rest","explicit"]:
  var pack := registry.source_data();pack.resources[1].refresh=scope
  var source := RulesRegistry.new();check(source.load_data(pack).ok,"generic resource refresh definition "+scope)
  check(RulesEffects.new(source).refresh_resources(encounter_runtime,{"stamina":2},scope).runtime.resources.stamina==2,"generic resource refresh execution "+scope)
 check(RulesRng.saving_throw(1000,0,rng).success and not RulesRng.saving_throw(-1000,1000,rng).success,"numeric save outcomes with explicit RNG")
 var refreshed := effects.refresh_resources(drained.runtime,{"focus":2},"encounter")
 check(refreshed.ok and refreshed.runtime.resources.focus==0,"encounter does not refill Focus")
 check(effects.refresh_resources(drained.runtime,{"focus":2},"eligible_rest").runtime.resources.focus==2,"explicit eligible rest refresh")
 var runtime: Dictionary=martial.runtime.duplicate(true)
 var context := {"source_character_id":"caster","target_id":martial.character_id,"target_stats":characters.derive_character(martial).snapshot.stats,"capacities":{"stamina":2}}
 var applied := effects.resolve_rules_effect({"op":"apply_status","id":"slowed"},adept.runtime,runtime,context,rng)
 check(applied.ok and applied.target.statuses.size()==1,"status applied")
 var slowed: Dictionary=martial.duplicate(true);slowed.runtime=applied.target
 check(characters.derive_character(slowed).snapshot.stats.stride==2,"slow modifies stride, preserves main action")
 check(effects.expire_statuses(slowed.runtime,"global_round_start").runtime.statuses.size()==1,"unrelated boundary preserves status")
 check(effects.expire_statuses(slowed.runtime,"target_activation_end").runtime.statuses.is_empty(),"caller-driven status expiry")
 var repeat := effects.resolve_rules_effect({"op":"apply_status","id":"slowed"},adept.runtime,slowed.runtime,context,rng)
 check(repeat.target.statuses.size()==1,"status refresh avoids stacking")
 var denial := effects.resolve_rules_effect({"op":"apply_status","id":"rare-denial"},adept.runtime,runtime,context,rng)
 check(denial.ok and not effects.resolve_rules_effect({"op":"apply_status","id":"rare-denial"},adept.runtime,denial.target,context,rng).ok,"explicit reject status stacking")
 var save_effect := effects.resolve_rules_effect({"op":"save","save":"will","dc":{"op":"const","value":1000},"on_failure":[{"op":"apply_status","id":"slowed"}]},adept.runtime,runtime,context,rng)
 check(save_effect.ok and save_effect.target.statuses[0].id=="slowed" and save_effect.rng.counter==1,"save failure resolves declarative child effect")
 var temporary := effects.resolve_rules_effect({"op":"temporary_hp","amount":{"op":"const","value":4}},adept.runtime,runtime,context,rng)
 var hit := effects.resolve_rules_effect({"op":"damage","amount":{"op":"const","value":6},"damage_type":"physical"},adept.runtime,temporary.target,context,rng)
 check(hit.ok and hit.target.hp==runtime.hp-2 and hit.target.temporary_hp==0,"temporaryHP absorbed before currentHP")
 check(RulesJson.canonical(adept)==actor_before and RulesJson.canonical(martial)==target_before,"effects leave original inputs byte equivalent")
 var start := Time.get_ticks_usec()
 for i in 1000: check(effects.use_ability(adept,martial,"spark",budget,rng).ok,"1000 deterministic effect calls")
 timings.effects_1000_us=Time.get_ticks_usec()-start
func finish() -> void:
 var output := OS.get_environment("GAME32_EVIDENCE")
 if output.is_empty(): output="res://docs/implementation/game32"
 DirAccess.make_dir_recursive_absolute(output)
 var file := FileAccess.open(output.path_join("kernel-results.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"rules_ref":registry.rules_ref(),"timings":timings,"golden":golden},"  ")+"\n");file.close()
 print("GAME-32 kernel checks=",checks," failures=",failures)
 quit(1 if failures else 0)
