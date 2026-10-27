extends "res://tests/dual_prestige_acceptance/base.gd"
## Small released32 witnesses, not native acceptance or earned progression.
var observations := {}
var failed_checks := []
func execute(engine: TacticalAuras,battle: Dictionary,ability: String,target := "a") -> Dictionary:
 return engine.command(battle,{"actor_id":engine.current(battle).id,"revision":battle.revision,"kind":ability,"target_id":target})
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;failed_checks.append(label);print("ASSERTION_FAILED ",label)
func run() -> void:
 base=OS.get_environment("GROVE_SUMMONER_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v32.json").ok,"exact released32 source")
 kernel=RulesCharacter.new(source);fixtures.fighter=build("fighter",8)
 var dead_end: Dictionary=route(["spirit-shaman"]+repeated("cleric",5),WIZARD_ARRAY,"grove-warden")
 if not dead_end.is_empty():
  var context: Dictionary=kernel._replay(dead_end).context
  var parents := []
  for option in RulesCareer.groups(source,"grove-warden",1)[0].options:
   if RulesCareer.option_eligibility(source,"grove-warden",1,option,context).ok:parents.append(option.id)
  observations.grove_dead_end={"offered":kernel.available_advancement(dead_end).classes["grove-warden"].ok,"parents":parents,"history":dead_end.advancement_history}
  check(observations.grove_dead_end.offered and parents.is_empty(),"released32 offers Grove entry with no legal nature-caster parent")
 var shallow: Dictionary=route(repeated("spirit-shaman",3)+repeated("cleric",3),WIZARD_ARRAY,"grove-warden")
 if not shallow.is_empty():
  var context: Dictionary=kernel._replay(shallow).context
  observations.grove_weak_magic={"casting":context.casting,"tiers":RulesCompleteness.spell_tiers(shallow,context,source),"offered":kernel.available_advancement(shallow).classes["grove-warden"].ok}
  check(observations.grove_weak_magic.offered and observations.grove_weak_magic.tiers.divine==2,"released32 aggregate divine score qualifies Grove with only actual tier2 magic")
 var grove: Dictionary=route(["spirit-shaman"]+repeated("druid",5)+["grove-warden"],WIZARD_ARRAY,"grove-warden",{"grove-casting":"druid"})
 if not grove.is_empty():
  var shaped: Dictionary=use(grove,grove,"wild-shape")
  check(shaped.ok and not RulesEntities.form(shaped.actor,source).is_empty(),"actual owned Druid transformation")
  if shaped.ok:
   var engine := TacticalAuras.new(grove)
   var normal: Dictionary=encounter(grove)
   var natural: Dictionary=encounter(shaped.actor)
   var normal_before: int=int(engine.stats(normal.units.b).defence)
   var natural_before: int=int(engine.stats(natural.units.b).defence)
   var first: Dictionary=execute(engine,normal,"grove-protection-1","a")
   var second: Dictionary=execute(engine,natural,"grove-protection-1","a")
   observations.transformed_sanctuary={"normal_ok":first.ok,"form_ok":second.ok,"form_error":second.get("error",""),"favour":natural.units.a.record.runtime.resources["grove-favour"],"form":RulesEntities.form(natural.units.a.record,source),"form_defence":natural_before}
   check(first.ok and not second.ok,"preserve correct released32 rejection of supernatural Grove action in a transformed body")
   if first.ok:
    observations.transformed_sanctuary.normal_defence=int(engine.stats(first.battle.units.b).defence)-normal_before
    check(observations.transformed_sanctuary.normal_defence==3,"already-functional sanctuary protects normal nearby allies")
 var aggregate: Dictionary=route(["wizard"]+repeated("sorcerer",2)+repeated("fighter",2),DUAL_ARRAY,"bonded-summoner")
 if not aggregate.is_empty():
  var permanent: Dictionary=kernel._replay(aggregate).context
  observations.bonded_entry={"casting":permanent.casting,"tiers":RulesCompleteness.spell_tiers(aggregate,permanent,source),"offered":kernel.available_advancement(aggregate).classes["bonded-summoner"].ok}
  check(observations.bonded_entry.offered and observations.bonded_entry.tiers.arcane==1,"released32 aggregate caster score qualifies Bonded Summoner without actual tier3 magic")
 var bonded: Dictionary=route(repeated("wizard",5)+repeated("bonded-summoner",3),WIZARD_ARRAY,"bonded-summoner")
 if not bonded.is_empty():
  var snapshot: Dictionary=kernel.derive_character(bonded).snapshot
  observations.bonded_progression={"casting_levels":snapshot.casting_levels,"wizard_tier4_slots":snapshot.resource_capacities.get("wizard-slots-4",0),"choices":source.definition("classes","bonded-summoner").career_choices,"history":bonded.advancement_history}
  check(int(snapshot.casting_levels.wizard)==5 and observations.bonded_progression.wizard_tier4_slots==0 and observations.bonded_progression.choices.is_empty(),"released32 Bonded prestige has no parent-caster advancement or selection")
  var engine := TacticalAuras.new(bonded)
  var battle: Dictionary=encounter(bonded)
  var called: Dictionary=execute(engine,battle,"bonded-summoner-technique-3","a")
  check(called.ok,"preserve already-functional finite prestige summon")
  if called.ok:
   var actors: Array=called.battle.units.values().filter(func(u: Dictionary):return u.get("entity",{}).get("kind")=="summon")
   check(actors.size()==1 and actors[0].entity.remaining==6 and called.battle.budget.main==0,"existing duration, ownership and action budget really work")
   observations.existing_summon={"actors":actors,"log":called.battle.log,"uses_before":battle.units.a.record.runtime.resources["bonded-summoner-uses"],"uses_after":called.battle.units.a.record.runtime.resources["bonded-summoner-uses"]}
  var druid: Dictionary=prep(build("druid",20),"druid-wildheart-mantle")
  var altered: Dictionary=use(druid,bonded,"druid-wildheart-mantle")
  check(altered.ok,"real owned ally spell creates a magic-suppressed Bonded body")
  if altered.ok:
   var shaped_battle: Dictionary=encounter(altered.target)
   var bypass: Dictionary=execute(engine,shaped_battle,"bonded-summoner-technique-3","a")
   observations.bonded_form_bypass={"accepted":bypass.ok,"error":bypass.get("error",""),"tags":source.definition("abilities","bonded-summoner-technique-3").tags,"form":RulesEntities.form(altered.target,source)}
   check(bypass.ok,"released32 untyped magical Bonded call bypasses existing transformed-body suppression")
   if bypass.ok:check(bypass.battle.budget.main==0 and bypass.battle.units.a.record.runtime.resources["bonded-summoner-uses"]==shaped_battle.units.a.record.runtime.resources["bonded-summoner-uses"]-1,"bypass is an actual paid summoned-actor command")
 var proof := {"checks":checks,"failures":failures,"failed_checks":failed_checks,"rules_ref":source.rules_ref(),"observations":observations,"development_fixtures":true,"earned_xp":false,"production_changed":false}
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof),"  "))
 print("GROVE_SUMMONER_V32 ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
