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
 var skill_pack := registry.source_data();skill_pack.skills[0].modifiers=[{"type":"circumstance","value":{"op":"const","value":2}}]
 var skill_registry := RulesRegistry.new();check(skill_registry.load_data(skill_pack).ok,"data-driven skill modifier validates")
 var skill_character := RulesCharacter.new(skill_registry)
 var skill_record := first.duplicate(true);skill_record.rules_ref=skill_registry.rules_ref()
 check(skill_character.derive_character(skill_record).snapshot.skills.athletics.total==characters.derive_character(first).snapshot.skills.athletics.total+2,"skill modifiers derive through generic stacking")
 effect_checks(first,first_adept,records.prestige)
 start=Time.get_ticks_usec()
 for i in 1000: check(characters.derive_character(first_adept).ok,"1000 derivations")
 timings.derive_1000_us=Time.get_ticks_usec()-start
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
 var second := effects.use_ability(illusion.actor,martial,"false-guard",budget,rng,{"event_id":"wall2"})
 check(second.ok and second.actor.runtime.apparent_effects.size()==1 and second.actor.runtime.apparent_effects[0].apparent_id!=descriptor.apparent_id,"maintained illusion replacement")
 var hook := effects.use_ability(prestige,martial,"veil-echo",budget,rng,{"trigger":"illusion_disbelieved","apparent_id":descriptor.apparent_id,"observer_id":"observer"})
 check(hook.ok and hook.budget.reaction==0 and hook.events.any(func(e: Dictionary): return e.type=="hook_intent"),"original prestige trusted hook")
 check(not effects.use_ability(hook.actor,martial,"veil-echo",hook.budget,rng,{"trigger":"illusion_disbelieved","apparent_id":descriptor.apparent_id,"observer_id":"observer"}).ok,"one shared reaction for all kinds")
 check(effects.activation_budget(0).budget.reaction==0,"activation does not refresh reaction")
 check(not effects.refresh_shared_reaction(hook.budget,"source_activation_start").ok,"activation cannot refresh shared reaction")
 check(effects.refresh_shared_reaction(hook.budget,"global_round_start").budget.reaction==1,"explicit global-round reaction refresh")
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
