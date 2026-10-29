extends "res://tests/grove_summoner/mechanics.gd"
## Released-v33 diagnostic histories, not earned campaigns or native acceptance.
func run() -> void:
 base=OS.get_environment("DRAGON_WARSHAPER_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded: Dictionary=source.load_pack("res://data/rules/trhgd-character-v33.json")
 check(loaded.ok,"exact released33 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_probe();return
 kernel=RulesCharacter.new(source);fixtures.fighter=build("fighter",12)
 var shallow: Dictionary=route(["wizard"]+repeated("sorcerer",2)+repeated("fighter",2),DUAL_ARRAY,"dragon-disciple")
 if not shallow.is_empty():
  var replay: Dictionary=kernel._replay(shallow)
  var tiers: Dictionary=RulesCompleteness.spell_tiers(shallow,replay.context,source)
  observations.shallow_entry={"offered":kernel.available_advancement(shallow).classes["dragon-disciple"].ok,"casting":replay.context.casting,"tiers":tiers,"history":shallow.advancement_history}
  check(observations.shallow_entry.offered and tiers.arcane==1,"released33 aggregate casting permits Dragon entry with actual tier1 magic")
 var stranded: Dictionary=route(repeated("beguiler",6),WIZARD_ARRAY,"dragon-disciple")
 if not stranded.is_empty():
  var context: Dictionary=kernel._replay(stranded).context
  check(RulesCompleteness.spell_tiers(stranded,context,source).arcane==3,"stranded existing Beguiler really has permanent tier3 magic")
  var parents: Array=[]
  for option in RulesCareer.groups(source,"dragon-disciple",1)[0].options:
   if RulesCareer.option_eligibility(source,"dragon-disciple",1,option,context).ok:parents.append(option.id)
  observations.stranded_entry={"offered":kernel.available_advancement(stranded).classes["dragon-disciple"].ok,"parents":parents,"history":stranded.advancement_history}
  check(observations.stranded_entry.offered and parents.is_empty(),"released33 offers Dragon prestige with no legal authored casting parent")
 var dragon: Dictionary=route(repeated("wizard",5)+repeated("druid",5)+["dragon-disciple"],WIZARD_ARRAY,"dragon-disciple",{"dragon-disciple-casting":"wizard"})
 if not dragon.is_empty():
  var shaped: Dictionary=use(dragon,dragon,"wild-shape")
  check(shaped.ok and not RulesEntities.form(shaped.actor,source).is_empty(),"real owned Druid ability produces a spell-suppressed Dragon body")
  if shaped.ok:
   var engine := TacticalAuras.new(dragon)
   var original: Dictionary=encounter(shaped.actor)
   var cast: Dictionary=execute(engine,original,"dragon-disciple-technique-1","bandit-blade")
   observations.breath_form={"accepted":cast.ok,"error":cast.get("error",""),"tags":source.definition("abilities","dragon-disciple-technique-1").tags,"form":RulesEntities.form(shaped.actor,source)}
   check(cast.ok,"released33 untyped supernatural breath bypasses transformed-body suppression")
   if cast.ok:check(cast.battle.budget.main==0 and cast.battle.units.a.record.runtime.resources["dragon-disciple-uses"]==original.units.a.record.runtime.resources["dragon-disciple-uses"]-1,"body bypass is an actual paid tactical command")
 var morph: Dictionary=route(repeated("druid",6)+repeated("warshaper",5),GS_NATURE_ARRAY,"warshaper")
 if not morph.is_empty():
  var defences: Array=[];var strengths: Array=[];var outcomes: Array=[]
  for level in [1,3,5]:
   var ability: String="warshaper-technique-"+str(level)
   var changed: Dictionary=use(morph,morph,ability)
   check(changed.ok,"existing paid Warshaper body technique "+str(level))
   if not changed.ok:continue
   var derived: Dictionary=kernel.derive_character(changed.actor)
   check(derived.ok and changed.actor.runtime.hp==morph.runtime.hp and changed.actor.runtime.resources["warshaper-uses"]==morph.runtime.resources["warshaper-uses"]-1,"working form preserves original health and spends its finite pool")
   defences.append(derived.snapshot.stats.defence);strengths.append(derived.snapshot.attributes.STR)
   outcomes.append({"ability":ability,"defence":derived.snapshot.stats.defence,"applied":derived.context.applied_modifiers.defence,"body":RulesEntities.form(changed.actor,source)})
  observations.morphic_defence={"defences":defences,"strengths":strengths,"outcomes":outcomes}
  check(defences.size()==3 and defences[0]==defences[1]and defences[1]==defences[2],"released33 tier3/5 morph defence is swallowed by the bear anatomy training bonus")
 finish_probe()
func finish_probe() -> void:
 var proof: Dictionary={"checks":checks,"failures":failures,"failed_checks":failed_checks,"observations":observations,"development_fixtures":true,"earned_xp":false,"production_changed":false,"rules_ref":source.rules_ref()}
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof),"  "))
 print("DRAGON_WARSHAPER_RELEASED33 ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
