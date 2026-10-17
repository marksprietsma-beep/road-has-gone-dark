extends "res://tests/character_completeness/prestige_driver.gd"
## Preserve the v15 observation; v16 acceptance must correct the false qualification.
func run() -> void:
 base=OS.get_environment("GAME126_PROBE_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v15.json").ok,"v15 source")
 kernel=RulesCharacter.new(source)
 var goals := requirements("archmage",0)
 var record := kernel.create("probe:low-int-archmage",{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8},"heritage-human")
 for n in 13:
  var step := advance(record,"wizard",goals)
  check(step.ok,"lawful low-INT Wizard history "+str(n))
  if not step.ok:done();return
  record=step.candidate
 var context: Dictionary=kernel._replay(record).context
 var highest := 0
 for id in context.abilities:
  var a := source.definition("abilities",id)
  if a.get("casting_class")=="wizard" and RulesExpressions.evaluate_requirements(a.requirements,context).ok:highest=maxi(highest,int(a.get("spell_tier",0)))
 var eligible: Dictionary=kernel.available_advancement(record).classes.archmage
 check(eligible.ok and highest<7,"reproduced v15 capacity-only false qualification, not claimed fixed")
 var result := {"rules_ref":source.rules_ref(),"development_fixture":true,"earned_xp":false,"record":record,"INT":context.attributes.INT,"wizard_tier7_capacity":context.capacities["wizard-slots-7"],"highest_attribute_eligible_owned_tier":highest,"archmage_eligibility":eligible,"checks":checks,"failures":failures}
 FileAccess.open(base.path_join("archmage-gap.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(result),"  "))
 print("ARCHMAGE GAP ",JSON.stringify({"INT":context.attributes.INT,"highest_legal_tier":highest,"eligible":eligible.ok,"failures":failures}))
 done()
