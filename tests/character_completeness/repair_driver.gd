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
  check(int(RulesCompleteness.spell_tiers(record,permanent,source).arcane)>=7 if smart else int(RulesCompleteness.spell_tiers(record,permanent,source).arcane)<7,"permanent tier is projected from legal spells")
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
 test_skill_approaches()
 var dusk := build("duskblade",4)
 check(not RulesCoreContent.suggested_spells(kernel.derive_character(dusk).snapshot,source).any(func(id: String):return source.definition("abilities",id).has("channel_spell")),"spell suggestions never select a channel delivery wrapper")
 var hashes := {}
 for id in records:hashes[id]=kernel.derive_character(records[id]).snapshot.snapshot_hash
 FileAccess.open(base.path_join("records.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes})))
 done()

func skill_fixture(skill: String,trained: bool) -> Dictionary:
 var record := kernel.create("skill-probe",{"STR":14,"DEX":13,"CON":12,"INT":15,"WIS":10,"CHA":8},"heritage-human")
 var choice: Dictionary=kernel.suggested_choice(record,"fighter").choice
 var points := 0
 for n in choice.skill_allocations.values():points+=int(n)
 choice.skill_allocations={}
 if trained:choice.skill_allocations[skill]=1;points-=1
 for id in source.ids("skills"):
  if id==skill or points<=0:continue
  choice.skill_allocations[id]=1;points-=1
 return kernel.preview_advancement(record,choice).candidate
func test_skill_approaches() -> void:
 for profile in source.rule("skill_approaches"):
  var successes := 0;var failed := 0
  for trained in [false,true]:
   var record := skill_fixture(profile.skill,trained)
   var state := {"party_ids":[record.character_id],"party":{"members":[{"character_id":record.character_id,"name":"Probe","generated_facts":{"occupation_id":"none"}}]},"adventure_cycles":{"cycles":[{"context":{"profiles":{record.character_id:record},"threat_level":1}}]}}
   for n in 24:
    var site := {"id":"skill-probe:"+str(n),"activity_id":profile.activities[0]}
    var before := RulesJson.digest(state)
    var a := OpportunityCycles.choices(state,site)
    check(RulesJson.digest(a)==RulesJson.digest(OpportunityCycles.choices(state,site)) and before==RulesJson.digest(state),"skill projection never mutates state/RNG")
    var found: Array=a.filter(func(o: Dictionary):return o.profession=="skill:"+str(profile.skill))
    check(found.size()==(1 if trained else 0),"trained approach rank gate "+profile.skill)
    if not trained:continue
    var row: Dictionary=found[0]
    check(row.event==profile.event and row.provisions==profile.provisions and row.complete,"existing time/supply contract "+profile.skill)
    if row.outcome=="failed_check":
     failed+=1;check(OpportunityCycles.reward(row)==0 and row.gain==0 and not row.reveal,"failed skill has no reward/discovery")
    else:
     successes+=1;check(OpportunityCycles.reward(row)==10 and row.gain==profile.gain and row.reveal==profile.reveal,"successful skill uses original one-objective reward")
  check(successes>0 and failed>0,"both deterministic skill outcomes exercised "+profile.skill)
