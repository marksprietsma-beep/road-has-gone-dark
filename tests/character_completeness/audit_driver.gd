extends "res://tests/character_wave_five/mechanics_driver.gd"
## Audit witnesses call production rules. High-level records are development fixtures, never earned XP.
var report := {}
var snapshots := {}
var saved_records := {}
func run() -> void:
 base=OS.get_environment("GAME126_AUDIT_ROOT")
 DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new()
 var path := OS.get_environment("GAME126_PACK")
 if path.is_empty():path="res://data/rules/trhgd-character-v15.json"
 var loaded := source.load_pack(path)
 check(loaded.ok,"exact audit pack schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:complete_audit();return
 kernel=RulesCharacter.new(source)
 report={"rules_ref":source.rules_ref(),"authority":"RulesCharacter/RulesEffects/TacticalCombat","scope":"Development fixtures: legal birth and every level, owned direct effects; not earned XP, every career choice, tactical adapter coverage or player acceptance.","classes":{},"options":{"classes":{},"abilities":{}},"prestige":{}}
 if OS.get_environment("GAME126_AUDIT_RESTART")=="1":
  var saved: Dictionary=WorldOriginLore.read_json(base.path_join("records.json"))
  for id in saved.records:
   var derived := kernel.derive_character(saved.records[id])
   check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"exact independent restart "+id)
  complete_audit(true);return
 fixtures.fighter=build("fighter",20)
 for cls in kernel.starting_classes():
  print("AUDIT CLASS ",cls)
  audit_class(cls)
 FileAccess.open(base.path_join("witnesses.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(report),"  "))
 var hashes := {}
 for id in saved_records:hashes[id]=kernel.derive_character(saved_records[id]).snapshot.snapshot_hash
 FileAccess.open(base.path_join("records.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":saved_records,"hashes":hashes})))
 complete_audit()

func audit_class(cls: String) -> void:
 var final := build(cls,20)
 if final.is_empty():
  report.classes[cls]={"levels":{},"blocked":true};return
 var record := kernel.create("audit:"+cls,final.base_attributes,final.ancestry_ref)
 var levels := {};var prior := {}
 for step in final.advancement_history:
  var choice: Dictionary=step.duplicate(true);choice.erase("level")
  var next := kernel.preview_advancement(record,choice)
  check(next.ok,"replay actual level choice "+cls+":"+str(step.level))
  if not next.ok:break
  record=next.candidate
  var s: Dictionary=next.snapshot
  var abilities: Array=s.abilities.filter(func(id: String):return not prior.get("abilities",[]).has(id))
  var new_features: Array=s.features.filter(func(id: String):return not prior.get("features",[]).has(id))
  var changed_resources := {}
  for id in s.resource_capacities:
   if int(s.resource_capacities[id])!=int(prior.get("resource_capacities",{}).get(id,-1)):changed_resources[id]=s.resource_capacities[id]
  var groups: Array=RulesCareer.groups(source,cls,int(step.level))
  levels[str(int(step.level))]={"ok":true,"snapshot_hash":s.snapshot_hash,"stats":s.stats,"new_owned_abilities":abilities,"new_features":new_features,"resource_capacity_changes":changed_resources,"career_choices":step.specialisations,"feat":step.feat_id,"bonus_feats":step.bonus_feats,"attribute_increase":step.attribute_increase,"quiet_class_level":abilities.is_empty() and new_features.is_empty() and groups.is_empty() and changed_resources.is_empty(),"development_fixture":true,"earned_xp":false}
  prior=s
 check(levels.size()==20,"all twenty actual levels "+cls)
 report.classes[cls]={"levels":levels,"complete_track":levels.size()==20,"equipment":source.definition("classes",cls).recommended_equipment}
 var evidence := ["tests/character_completeness/audit_driver.gd", "witnesses.json#classes/"+cls]
 report.options.classes[cls]={"selectable":{"status":"yes","evidence":evidence},"mechanically_functional":{"status":"partial","scope":"Legal progression and owned direct effects; not complete career/tactical coverage","evidence":evidence},"automated_tested":{"status":"yes","scope":"Class birth, every level and exact cold snapshot","evidence":evidence}}
 saved_records[cls]=record
 snapshots[cls]=prior
 audit_direct_actions(cls,record,prior)

func audit_direct_actions(cls: String,record: Dictionary,snapshot: Dictionary) -> void:
 for id in snapshot.abilities:
  var a := source.definition("abilities",id)
  if a.tags.has("passive") or a.has("trigger") or a.tags.has("weapon_strike") or a.has("channel_spell") or a.has("aura") or a.targeting.kind not in ["self","creature"]:continue
  var actor: Dictionary=record.duplicate(true)
  var ability_id: String=str(a.get("channel_spell",id))
  if a.tags.has("spell"):
   actor.choices.prepared_abilities=[ability_id]
   actor.choices.spell_preparations={}
   if a.tags.has("prepared"):actor.choices.spell_preparations[ability_id]=1
  actor.runtime.resources=kernel._replay(actor).context.capacities.duplicate()
  var eligible := kernel.derive_character(actor)
  if not eligible.ok:continue
  actor.runtime.hp=maxi(1,int(eligible.snapshot.stats.HP)-2)
  var target: Dictionary=actor if a.targeting.kind=="self" else fixtures.fighter.duplicate(true)
  if a.targeting.kind!="self":target.runtime.hp=maxi(1,int(kernel.derive_character(target).snapshot.stats.HP)-2)
  var result := use(actor,target,id)
  var row := {"class":cls,"ability":id,"ok":result.ok,"errors":result.get("errors",[]),"scope":"Direct RulesEffects only; no targeting/adapter claim","development_fixture":true}
  if result.ok:
   var replay := use(JSON.parse_string(JSON.stringify(actor)),JSON.parse_string(JSON.stringify(target)),id)
   check(replay.ok and RulesJson.digest(replay)==RulesJson.digest(result),"exact direct-effect replay "+cls+":"+id)
   row.events=result.events;row.budget=result.budget
   row.observable_effect=effect_signature(result.actor)!=effect_signature(actor) or effect_signature(result.target)!=effect_signature(target)
   row.resource_change=result.actor.runtime.resources!=actor.runtime.resources
   if not saved_records.has(cls+":used"):
    saved_records[cls+":used"]=result.actor
   var ev := {"status":"yes","scope":"Direct RulesEffects execution/replay on a lawful development build; not tactical targeting","evidence":["witnesses.json#classes/"+cls+"/direct_actions/"+id]}
   if row.observable_effect:report.options.abilities[id]={"mechanically_functional":ev,"automated_tested":ev}
  report.classes[cls].get_or_add("direct_actions",{})[id]=row

func effect_signature(record: Dictionary) -> String:
 var runtime: Dictionary=record.runtime.duplicate(true)
 runtime.erase("resources")
 runtime.erase("manifested_powers")
 return RulesJson.digest(runtime)

func complete_audit(restart := false) -> void:
 var proof := {"rules_ref":source.rules_ref(),"checks":checks,"failures":failures,"development_fixtures":true,"earned_xp":false}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("CHARACTER COMPLETENESS ",JSON.stringify(proof))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
