extends Node
## Fast deterministic replay of the actual failed build and a lawful new plan.
var checks := 0
var failures := 0
var source: RulesRegistry
var kernel: RulesCharacter
var base := ""
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 base=OS.get_environment("HYBRID_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v28.json").ok,"actual immutable28")
 kernel=RulesCharacter.new(source)
 if OS.get_environment("HYBRID_RESTART")=="1":cold();return
 var archive: Dictionary=RulesJson.normalize(WorldOriginLore.read_json("res://tests/hybrid_acceptance/earned-planner-fixtures.json"))
 var rows: Dictionary=archive.records.duplicate(true);var evidence := {}
 for key in ["sorcerer13","sorcerer14"]:
  var r: Dictionary=rows[key];var before := RulesJson.digest(r);var d := kernel.derive_character(r)
  check(d.ok,"actual failed earned record still validates "+key)
  if not d.ok:finish();return
  var eligible: Dictionary=kernel.available_advancement(r).classes.archmage
  check(not eligible.ok,"genuine permanent prerequisites correctly reject original low-skill plan "+key)
  check(d.snapshot.attributes.INT==8 and d.context.skills.arcana==10 and d.context.skills.spellcraft==(3 if key=="sorcerer13" else 4),"exact reproduced INT8/rank shortage "+key)
  check(d.context.feats.has("spell-focus") and d.context.feats.has("greater-spell-focus"),"actual focus chain was present")
  check(r.choices.prepared_abilities.any(func(id: String):return source.definition("abilities",id).get("casting_class")=="sorcerer" and source.definition("abilities",id).get("spell_tier")==7),"actual permanent tier7 knowledge was present")
  var missed := []
  for node in source.definition("classes","archmage").requirements.args:
   if not RulesCompleteness.entry_requirements(node,d.context,r,source).ok:missed.append(node)
  check(missed==[{"op":"skill","id":"spellcraft","min":10}],"Spellcraft is the precise sole failed permanent predicate")
  var draft := kernel.suggested_choice(r,"archmage")
  check(draft.ok and not kernel.preview_advancement(r,draft.choice).ok and not kernel.preview_choices(r,"archmage").ok and RulesJson.digest(r)==before,"generated draft cannot bypass actual preview/UI eligibility or mutate the original build")
  evidence[key]={"attributes":d.snapshot.attributes,"ranks":d.context.skills,"eligibility":eligible,"failed_predicates":missed,"record_hash":before}
 var driver: Node=load("res://tests/hybrid_acceptance/journey.gd").new()
 driver.source=source;driver.kernel=kernel;driver.configs=[["duskblade","human",""],["wizard","human","archmage"],["sorcerer","human","archmage"]]
 var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new();planner.source=source;planner.kernel=kernel;driver.planner=planner;driver.configure_planner()
 for index in [1,2]:
  var cls: String=driver.configs[index][0];var goals: Dictionary=driver.goals_for(index)
  var attributes: Dictionary=planner.attributes_for(cls,goals.nodes)
  var values: Array=attributes.values();values.sort();var standard: Array=source.rule("standard_array").duplicate();standard.sort()
  check(values==standard,"new plan spends the original standard array, no artificial score grant")
  var r := kernel.create("planner-fixture:"+cls,attributes,"heritage-human")
  for at in 13:
   var step: Dictionary=driver.planned(r,cls,index);check(step.ok,"actual planned class/feat/rank choice "+cls+str(at+1))
   if not step.ok:planner.free();driver.free();finish();return
   r=step.candidate
   var selection: Dictionary=driver.spell_selection(r);r.choices.prepared_abilities=selection.spells;r.choices.spell_preparations=selection.preparations
   RulesCoreContent.refill_prepared(r,source) # Same home-preparation policy, no shared slot refill.
   check(kernel.validate_build(r).ok,"every planned permanent spell selection remains legal")
  var before := RulesJson.digest(r);var d := kernel.derive_character(r)
  check(d.ok and d.context.skills.arcana>=10 and d.context.skills.spellcraft>=10,"lawful13 satisfies both permanent rank10 requirements "+cls)
  check(kernel.available_advancement(r).classes.archmage.ok,"corrected normal starting choices qualify at13 "+cls)
  var decline: Dictionary=driver.planned(r,cls,index);check(decline.ok and not kernel.derive_character(decline.candidate).snapshot.class_levels.has("archmage"),"can explicitly decline prestige "+cls)
  var selected: Dictionary=driver.planned(r,"archmage",index);check(selected.ok,"manual original prestige choice "+cls)
  if selected.ok:
   var snapshot := kernel.derive_character(selected.candidate)
   check(snapshot.ok and snapshot.snapshot.class_levels.archmage==1 and snapshot.snapshot.casting_levels[cls]==14,"actual original parent advancement and first path feature")
   check(snapshot.snapshot.abilities.has("high-arcana-ward-1" if cls=="sorcerer" else "high-arcana-force-1"),"actual selected advanced ability is owned")
   rows[cls+":selected"]=selected.candidate
  check(RulesJson.digest(r)==before,"eligibility/decline/choice previews never assign prestige automatically")
  rows[cls+":planned13"]=r
  evidence[cls+":planned13"]={"attributes":attributes,"ranks":d.context.skills,"eligibility":kernel.available_advancement(r).classes.archmage,"scope":"Lawful development fixture, no earned-XP claim. Fresh full earned campaign still required."}
 planner.free();driver.free()
 var failed_root := OS.get_environment("HYBRID_FAILED_ROOT")
 if not failed_root.is_empty():
  var raw := failed_root.path_join("hybrid-earned/journeys/cohort-0/earned-qualified-wizard.json")
  check(FileAccess.get_sha256(raw)==archive.original_witness_sha256,"exact actual earned pre-entry campaign, not a reconstructed XP fixture")
  var state := WorldOriginLore.read_json(raw);var before := RulesJson.digest(state)
  for index in [1,2]:
   var id: String=state.party_ids[index];var r: Dictionary=state.mechanics.records[id]
   check(CharacterBuilderRecords.xp(state,id)==1690,"real archived objective XP was earned")
   var offered := kernel.suggested_choice(r,"archmage")
   if index==1:
    check(offered.ok,"actual earned Wizard13 qualifies")
    if offered.ok:check(CharacterBuilderRecords.preview_advancement(state,id,offered.choice).ok,"actual1690XP funds legitimate Wizard prestige")
   else:check(offered.ok and not CharacterBuilderRecords.preview_advancement(state,id,offered.choice).ok,"real1690XP cannot override missing Sorcerer rank prerequisites")
   var choice := kernel.suggested_choice(r,str(r.advancement_history.back().class_id))
   check(choice.ok and CharacterBuilderRecords.preview_advancement(state,id,choice.choice).ok,"actual earned qualifying/ineligible characters can keep advancing their legal base class")
  check(RulesJson.digest(state)==before,"funded previews preserve the archived actual campaign")
 var hashes := {};var snapshots := {}
 for key in rows:
  var d := kernel.derive_character(rows[key]);check(d.ok,"all diagnostic/planned histories are valid")
  hashes[key]=RulesJson.digest(rows[key]);snapshots[key]=d.snapshot.snapshot_hash
 FileAccess.open(base.path_join("planner-saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":rows,"hashes":hashes,"snapshots":snapshots})))
 FileAccess.open(base.path_join("planner-diagnostics.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(evidence),"  "))
 finish()
func cold() -> void:
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("planner-saved.json")))
 for key in saved.records:
  var d := kernel.derive_character(saved.records[key])
  check(d.ok and d.snapshot.snapshot_hash==saved.snapshots[key] and RulesJson.digest(saved.records[key])==saved.hashes[key],"exact diagnostic/choice cold restart "+key)
 finish(true)
func finish(restart := false) -> void:
 var p := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"scope":"Exact failed1690XP records and small lawful corrected13→14 planning; corrected histories are development fixtures, not yet an earned campaign."}
 FileAccess.open(base.path_join("planner-restart-proof.json" if restart else "planner-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(p))
 print("HYBRID_PLANNER ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
