extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func run():
 var source := RulesRecords.new_character_registry();var kernel := RulesCharacter.new(source)
 var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("GAME119_TEST_ROOT").path_join("advanced-fixtures.json")))
 for path in fixtures:
  var record: Dictionary=fixtures[path];record.character_id="a"
  var snapshot: Dictionary=kernel.derive_character(record).snapshot
  record.runtime.hp=1;record.runtime.resources=snapshot.resource_capacities.duplicate()
  var state := {"world_ref":{"id":"career-test"},"origin":{"home_burg_id":1},"party_ids":["a","b","c"],"party":{"members":[{"name":path},{"name":"Ally"},{"name":"Companion"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":{"a":record}}}
  for id in ["b","c"]:
   var ally := kernel.create(id,source.recommendation("vanguard").attributes,"heritage-human")
   ally.equipment=["shortblade"];ally=kernel.preview_advancement(ally,kernel.suggested_choice(ally,"fighter").choice).candidate
   ally.runtime.hp=1;state.mechanics.records[id]=ally
  var engine := TacticalCombat.new(state)
  for level in [1,3,5]:
   var battle := engine.create(state,"career-site");battle.cursor=battle.order.find("a")
   battle.units.a.position=[0,0];battle.units.b.position=[0,1];battle.units.c.position=[0,2]
   var enemies: Array=battle.order.filter(func(id: String):return battle.units[id].team=="enemy")
   battle.units[enemies[0]].position=[1,0];battle.units[enemies[1]].position=[2,0]
   battle=engine.seal(battle)
   var id: String=path+"-power-"+str(level)
   var target: String="a" if source.definition("abilities",id).targeting.kind=="ally" else enemies[0]
   var command := {"actor_id":"a","revision":battle.revision,"kind":id,"target_id":target}
   var result := engine.command(battle,command)
   check(result.ok,"actual tactical prestige "+id+" "+str(result.get("error","")))
   if not result.ok:continue
   check(engine.validate(result.battle).is_empty(),"prestige combat validates bounded resources")
   var repeat := engine.command(battle,command)
   check(result.battle.state_hash==repeat.battle.state_hash and result.battle.log==repeat.battle.log and result.battle.rng==repeat.battle.rng,"identical prestige combat/RNG/log replay")
   check(result.battle.units.a.record.runtime.resources[path+"-uses"]==battle.units.a.record.runtime.resources[path+"-uses"]-1,"spends one finite prestige use")
   if path in ["duelist","eldritch-knight"]:check(result.battle.log.any(func(line: String):return 'hits' in line or 'miss.' in line),"prestige weapon action rolls actual attack")
   if path=="mystic-theurge":check(result.battle.units.b.record.runtime.hp>1 and result.battle.units.c.record.runtime.hp>1,"hybrid restoration affects both allies once")
  # A prestige caster can select and cast an unlocked prepared tier, using both budgets.
  if path!="duelist":
   var caster := record.duplicate(true);caster.choices.prepared_abilities=["wizard-ice-lance"];caster.choices.spell_preparations={"wizard-ice-lance":1}
   RulesCoreContent.refill_prepared(caster,source)
   var enemy: Dictionary=state.mechanics.records.b
   var used := RulesEffects.new(source).use_ability(caster,enemy,"wizard-ice-lance",{"main":1,"move":1,"reaction":1},RulesRng.initial("prestige-cast"))
   check(used.ok and used.events.any(func(event: Dictionary):return event.type=="save_resolved"),"hybrid actually casts earned tier with original authority")
   check(used.actor.runtime.resources["wizard-prepared-ice-lance"]==0,"hybrid spends individual prepared copy")
 # Target-dependent quarry bonus distinguishes blade and bow, without new ancestry mechanics.
 var archer := kernel.create("quarry",source.recommendation("scout").attributes,"heritage-human")
 var choice := kernel.suggested_choice(archer,"ranger");choice.choice.specialisations["ranger-quarry-choice"]="archers"
 archer=kernel.preview_advancement(archer,choice.choice).candidate
 var snap: Dictionary=kernel.derive_character(archer).snapshot
 var engine := TacticalCombat.new()
 check(engine.quarry_matches(snap,{"team":"enemy","weapon":"bow"}),"archer quarry targets actual hostile bow equipment")
 check(not engine.quarry_matches(snap,{"team":"enemy","weapon":"shortblade"}),"archer quarry excludes blade bandit")
 check(not engine.quarry_matches(snap,{"team":"party","weapon":"bow"}),"quarry never targets allies")
 print("GAME119 PRESTIGE COMBAT ",checks," / ",failures)
 quit(1 if failures else 0)
