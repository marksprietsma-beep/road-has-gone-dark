extends "res://tests/character_completeness/prestige_driver.gd"
## Focused permanent-competence regressions; high-level records are development fixtures.
func run() -> void:
 base=OS.get_environment("GAME126_REPAIR_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v16.json")
 check(loaded.ok,"v16 typed pack "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:done();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME126_AUDIT_RESTART")=="1":
  var saved := WorldOriginLore.read_json(base.path_join("records.json"))
  for id in saved.records:
   var derived := kernel.derive_character(saved.records[id])
   check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"v16 competence exact restart "+id)
  done();return
 var goals := requirements("archmage",0)
 for smart in [false,true]:
  var attrs := {"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8} if not smart else {"STR":8,"DEX":14,"CON":13,"INT":15,"WIS":12,"CHA":10}
  var record := kernel.create("competence:"+str(smart),attrs,"heritage-human")
  for n in 13:
   var step := advance(record,"wizard",goals)
   check(step.ok,"lawful competence prefix "+str(smart)+":"+str(n)+JSON.stringify(step.get("errors",[])))
   if not step.ok:done();return
   record=step.candidate
  var context: Dictionary=kernel._replay(record).context
  var eligible: Dictionary=kernel.available_advancement(record).classes.archmage
  check(eligible.ok==smart,"actual spell access gates Archmage, not nominal slots")
  check(int(context.capacities["wizard-slots-7"])>0,"both fixtures have nominal tier-seven capacity")
  var permanent := kernel._context(context.attributes,context.classes,context.skills,context.feats,record,false)
  check(int(permanent.spell_tiers.arcane)>=7 if smart else int(permanent.spell_tiers.arcane)<7,"permanent tier is projected from legal spells")
  var altered: Dictionary=record.duplicate(true)
  for pool in altered.runtime.resources:altered.runtime.resources[pool]=0
  check(kernel.available_advancement(altered).classes.archmage.ok==smart,"spent resources do not change permanent entry")
  if not source.definition("features","wizard-spells-7").is_empty():altered.runtime.granted_features.append("wizard-spells-7")
  else:altered.runtime.senses.append("hearing")
  check(kernel.available_advancement(altered).classes.archmage.ok==smart,"runtime grants cannot supply permanent entry")
  var before := RulesJson.digest(record)
  if smart:
   var joined := advance(record,"archmage",goals)
   check(joined.ok,"qualified optional manual entry "+JSON.stringify(joined.get("errors",[])))
   check(advance(record,"wizard",goals).ok,"qualified player may decline prestige")
   check(RulesJson.digest(record)==before,"eligibility never assigns prestige")
   if joined.ok:record=joined.candidate
  else:
   check(not advance(record,"archmage",goals).ok,"forged prestige choice rejected by replay")
  var result := kernel.derive_character(record)
  if result.ok:records[record.character_id]=record
 for row in source.rule("skill_approaches"):
  check(source.definition("skills",row.skill).size()>0 and row.min_ranks==1,"real trained skill approach "+row.skill)
 var hostile: Dictionary=WorldOriginLore.read_json("res://data/rules/trhgd-character-v16.json")
 hostile.rules.skill_approaches[0].skill="not-a-skill"
 check(not RulesRegistry.new().load_data(hostile).ok,"unknown approach skill rejected")
 hostile=WorldOriginLore.read_json("res://data/rules/trhgd-character-v16.json");hostile.rules.skill_approaches[0].provisions=-1
 check(not RulesRegistry.new().load_data(hostile).ok,"negative approach cost rejected")
 var old := RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v15.json").ok,"v15 still supported")
 var original := WorldOriginLore.read_json("res://docs/implementation/game126/evidence/archmage-v15-gap.json")
 check(RulesCharacter.new(old).available_advancement(original.record).classes.archmage.ok,"historical v15 exact qualification preserved")
 var hashes := {}
 for id in records:hashes[id]=kernel.derive_character(records[id]).snapshot.snapshot_hash
 FileAccess.open(base.path_join("records.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes})))
 done()
