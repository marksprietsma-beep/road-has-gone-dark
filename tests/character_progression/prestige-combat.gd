extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func run():
 var source := RulesRecords.registry(RulesRecords.installed_packs().filter(func(row: Dictionary):return row.rules_ref.pack_id=="trhgd-character-v9")[0].rules_ref);var kernel := RulesCharacter.new(source)
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
   check(engine.validate(JSON.parse_string(JSON.stringify(battle))).is_empty(),"initial battle checksum survives JSON; fresh enemy histories use String keys")
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
 check(RulesCareer.quarry_matches(snap,{"team":"enemy","weapon":"bow"},source),"archer quarry targets actual hostile bow equipment")
 check(not RulesCareer.quarry_matches(snap,{"team":"enemy","weapon":"shortblade"},source),"archer quarry excludes blade bandit")
 check(not RulesCareer.quarry_matches(snap,{"team":"party","weapon":"bow"},source),"quarry never targets allies")
 # Compare actual attacks under the same RNG, not just matching descriptors.
 archer.equipment=["bow","leathers"]
 var raider := archer.duplicate(true);raider.advancement_history[0].specialisations["ranger-quarry-choice"]="raiders"
 var base_state := {"world_ref":{"id":"quarry-test"},"origin":{"home_burg_id":1},"party_ids":["quarry","b","c"],"party":{"members":[{"name":"Tracker"},{"name":"B"},{"name":"C"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":{"quarry":archer}}}
 for id in ["b","c"]:
  var ally := kernel.create(id,source.recommendation("vanguard").attributes,"heritage-human")
  ally.equipment=["shortblade"];base_state.mechanics.records[id]=kernel.preview_advancement(ally,kernel.suggested_choice(ally,"fighter").choice).candidate
 for seed in 30:
  var outcomes: Array=[]
  for selected in [archer,raider]:
   var state := base_state.duplicate(true);state.mechanics.records.quarry=selected
   var combat := TacticalCombat.new(state);var battle := combat.create(state,"quarry-site")
   battle.cursor=battle.order.find("quarry");battle.units.quarry.position=[0,0];battle.units.b.position=[0,1];battle.units.c.position=[0,2]
   battle.units["bandit-blade"].position=[2,0];battle.units["bandit-bow"].position=[4,0]
   battle.rng=RulesRng.initial("quarry-proof:"+str(seed));battle=combat.seal(battle)
   var result := combat.command(battle,{"actor_id":"quarry","revision":battle.revision,"kind":"attack","target_id":"bandit-blade"})
   check(result.ok,"actual chosen quarry attack: "+str(result.get("error","")))
   if not result.ok:quit(1);return
   outcomes.append(result.battle)
  if outcomes.all(func(b: Dictionary):return b.log.any(func(line: String):return "hits" in line)):
   check(outcomes[0].units["bandit-blade"].record.runtime.hp==outcomes[1].units["bandit-blade"].record.runtime.hp+2,"selected raider quarry adds actual two damage; archer quarry does not affect blade bandit")
   check(outcomes[0].rng==outcomes[1].rng,"quarry evaluation consumes no additional RNG")
   break
  if seed==29:check(false,"deterministic hit comparison found")
 print("GAME119 PRESTIGE COMBAT ",checks," / ",failures)
 quit(1 if failures else 0)
