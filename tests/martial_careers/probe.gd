extends "res://tests/class_signatures/mechanics_driver.gd"
## Pinned v29 development witnesses. No campaign or earned XP is manufactured.
var observations := {}
func variant(cls: String,levels: int,options: Dictionary={},first_feat := "steady-study",ancestry := "heritage-human") -> Dictionary:
 var r := kernel.create("martial-probe",{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8},ancestry)
 for n in levels:
  var suggestion := kernel.suggested_choice(r,cls,first_feat if n==0 else "steady-study")
  check(suggestion.ok,"lawful proposed level "+cls+str(n+1))
  if not suggestion.ok:return {}
  for key in suggestion.choice.specialisations:
   if options.has(key):suggestion.choice.specialisations[key]=options[key]
  var step := kernel.preview_advancement(r,suggestion.choice)
  check(step.ok,"lawful chosen level "+cls+str(n+1)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  r=step.candidate
 r.equipment=["shortblade","leathers"]
 var d := kernel.derive_character(r);check(d.ok,"full development history valid")
 if not d.ok:return {}
 r.runtime.hp=int(d.snapshot.stats.HP);r.runtime.resources=d.snapshot.resource_capacities.duplicate()
 return RulesJson.string_keys(r)
func stats_of(r: Dictionary) -> Dictionary:
 var d := kernel.derive_character(r);check(d.ok,"derive actual observed state")
 return d.get("snapshot",{}).get("stats",{})
func contains_save(effects: Array) -> bool:
 for effect in effects:
  if effect.op=="save":return true
  for field in ["on_success","on_failure"]:
   if effect.has(field) and contains_save(effect[field]):return true
 return false
func run() -> void:
 base=OS.get_environment("MARTIAL_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v29.json").ok,"released29 reproduction")
 kernel=RulesCharacter.new(source)
 var f4 := variant("fighter",4);var f5 := variant("fighter",5)
 var a := stats_of(f4);var b := stats_of(f5)
 var increment: int=int(b.melee_attack)-int(a.melee_attack)-int(b.BAB)+int(a.BAB)
 check(increment==0,"reproduced: Veteran contributes no attack beyond normal BAB")
 observations.veteran={"level4":a,"level5":b,"extra_attack":increment}
 var plain := variant("fighter",1);var point := variant("fighter",1,{},"point-blank-shot")
 check(stats_of(point).ranged_attack==stats_of(plain).ranged_attack,"reproduced: Pointblank feat contributes no ranged attack to Fighter")
 observations.pointblank={"control":stats_of(plain),"selected":stats_of(point)}
 var bow := variant("fighter",3,{"fighter-choice-1":"bow"});bow.equipment=["bow","leathers"]
 var buffed := use(bow,bow,"fighter-bow-1");check(buffed.ok,"actual owned paid Bow discipline")
 if buffed.ok:
  check(stats_of(buffed.actor).damage==stats_of(bow).damage,"reproduced: discipline damage lost to permanent Specialization")
  observations.bow={"before":stats_of(bow),"after":stats_of(buffed.actor),"cost":source.definition("abilities","fighter-bow-1").cost}
 bow.equipment=["shortblade","leathers"]
 var wrong := use(bow,bow,"fighter-bow-1")
 check(wrong.ok,"reproduced: Bow discipline permits an actual held melee weapon")
 observations.wrong_equipment={"equipment":bow.equipment,"accepted":wrong.ok}
 var resilient := variant("barbarian",15,{"barbarian-choice-1":"resilient","barbarian-choice-6":"resilient","barbarian-choice-15":"resilient"})
 var saves := []
 for id in kernel.derive_character(resilient).snapshot.abilities:
  if contains_save(source.definition("abilities",id).effects):saves.append(id)
 check(saves.is_empty() and stats_of(resilient).save_dc==2,"reproduced: pure Resilient mastery grants DC with no own save action")
 observations.resilience={"stats":stats_of(resilient),"save_actions":saves,"feature":source.definition("features","barbarian-master-choice-resilient")}
 # Paid combinations are acceptance coverage, not an assumed redesign defect.
 var rage := variant("barbarian",6,{"barbarian-choice-1":"reckless","barbarian-choice-6":"resilient"})
 var initial: int=rage.runtime.resources["rage-uses"]
 for id in ["rage","barbarian-reckless-1","barbarian-resilient-6"]:
  var out := use(rage,rage,id);check(out.ok,"existing paid rage option "+id)
  if out.ok:
   check(out.budget.main==0 and out.actor.runtime.resources["rage-uses"]==rage.runtime.resources["rage-uses"]-1,"each combination spends its own action and use")
   rage=out.actor
 check(initial==3 and rage.runtime.resources["rage-uses"]==0 and not use(rage,rage,"rage").ok,"combination cannot create free or unlimited Rage")
 observations.paid_rage={"supplied_development_actions":3,"resources_before":initial,"resources_after":rage.runtime.resources["rage-uses"],"statuses":rage.runtime.statuses,"stats":stats_of(rage),"scope":"Direct effects with three separate action budgets; real turn-boundary counterplay is tested by candidate combat acceptance."}
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false,"observations":observations,"production_changed":false}
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("MARTIAL_V29_PROBE ",JSON.stringify({"checks":checks,"failures":failures}))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
