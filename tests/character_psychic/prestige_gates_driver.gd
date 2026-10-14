extends "res://tests/character_psychic/mechanics_driver.gd"
## Prestige remains an explicit career choice; these qualification fixtures grant no XP.
func run() -> void:
 source=RulesRecords.new_character_registry();kernel=RulesCharacter.new(source)
 base=OS.get_environment("GAME112W3_TEST_ROOT")
 if base.is_empty():base=OS.get_environment("GAME112_TEST_ROOT")
 if not base.is_empty():DirAccess.make_dir_recursive_absolute(base)
 for cls in ["fighter","wizard","ardent","lurk"]:
  var record := build("starting:"+cls,cls,1)
  check(not record.is_empty() and record.advancement_history[0].class_id==cls,"legal base-class level one "+cls)
 var editor := BuildEditor.new();add_child(editor)
 var starting := build("selector","fighter",1)
 editor.setup(starting,false)
 check(editor.class_options()==kernel.starting_classes(),"embedded creation choices are authoritative base classes")
 for id in source.ids("classes"):
  if source.definition("classes",id).get("class_kind")!="prestige":continue
  check(not editor.class_options().has(id),"prestige absent from level-one creation "+id)
 editor.class_filter.text="Cerebremancer"
 for index in editor.class_picker.item_count:check(source.definition("classes",str(editor.class_picker.get_item_metadata(index))).class_kind=="base","search cannot reveal a starting prestige option")
 editor.setup(starting,true)
 check(editor.class_options().has("cerebremancer"),"future paths remain visible during advancement")
 var forged_payload := CharacterBuilderRecords.definition(starting)
 forged_payload.class_id="cerebremancer"
 var creation := CharacterBuilderRecords.create("forged-player",forged_payload,starting)
 check(not creation.ok,"forged player creation payload cannot start as prestige")
 var raw := kernel.create("forged",starting.base_attributes,"heritage-human")
 check(not kernel.available_advancement(raw).classes.cerebremancer.ok,"ineligible first prestige unavailable")
 var copied := source.source_data().duplicate(true)
 for definition in copied.classes:
  if definition.id=="cerebremancer":definition.requirements=source.definition("classes","fighter").requirements.duplicate(true)
 var permissive := RulesRegistry.new();check(permissive.load_data(copied).ok,"isolated permissive-prerequisite fixture loads")
 if permissive.ready():
  var authority := RulesCharacter.new(permissive)
  var forged := authority.create("permissive-first",starting.base_attributes,"heritage-human")
  var chosen := authority.suggested_choice(forged,"cerebremancer")
  var denied := authority.preview_advancement(forged,chosen.choice)
  check(not denied.ok and denied.errors[0].code=="advancement.prestige_start","rules reject first prestige even with accidentally permissive entry requirements")
  check(not authority.available_advancement(forged).classes.cerebremancer.ok,"eligibility also enforces prior progression independently of content requirements")
 test_prestige()
 for path in advanced_examples:
  var advanced: Dictionary=advanced_examples[path]
  var record := kernel.create(advanced.character_id,advanced.base_attributes,advanced.ancestry_ref)
  for step in advanced.advancement_history:
   if step.class_id==path:break
   var choice: Dictionary=step.duplicate(true);choice.erase("level")
   var applied := kernel.preview_advancement(record,choice)
   check(applied.ok,"permanent prerequisite history reconstructed "+path)
   if not applied.ok:finish();return
   record=applied.candidate
  var before := RulesJson.digest(record)
  check(kernel.available_advancement(record).classes[path].ok,"real saved class/skill/feat/power qualification "+path)
  check(RulesJson.digest(record)==before and not kernel.derive_character(record).snapshot.class_levels.has(path),"eligibility never assigns a prestige class "+path)
  var alternate := "wizard" if path=="cerebremancer" else "druid"
  var declined := kernel.preview_advancement(record,kernel.suggested_choice(record,alternate).choice)
  check(declined.ok and declined.candidate.advancement_history.back().class_id==alternate and not declined.snapshot.class_levels.has(path),"qualified character can deliberately continue base class "+path)
  var selected := kernel.preview_advancement(record,kernel.suggested_choice(record,path).choice)
  check(selected.ok and selected.candidate.advancement_history.back().class_id==path,"prestige requires explicit manual selection "+path)
  check(RulesJson.digest(record)==before,"choice previews generate no progression or resource mutation "+path)
  if selected.ok:check(kernel.derive_character(JSON.parse_string(JSON.stringify(selected.candidate))).snapshot.snapshot_hash==selected.snapshot.snapshot_hash,"chosen ordered prestige and resources preserve exact JSON pin "+path)
 # Runtime feature grants are excluded from permanent qualification.
 var unqualified := build("temporary","wizard",5)
 var features: Array=source.ids("features").filter(func(id: String):return source.definition("features",id).has("companion"))
 check(not features.is_empty(),"temporary-companion feature fixture is substantive")
 unqualified.runtime.granted_features.append_array(features)
 var temporary := kernel.derive_character(unqualified)
 check(temporary.ok and temporary.context.tags.has("permanent_nature_bond"),"runtime grant can display bond tags without rewriting permanent history")
 check(kernel.validate_build(unqualified).ok and RulesEntities.bonds(unqualified,source).is_empty(),"runtime grants do not create a permanent owned companion")
 var eligibility := kernel.available_advancement(unqualified)
 check(eligibility.ok and not eligibility.classes["beast-steward"].ok,"temporary grants cannot satisfy permanent companion prestige entry")
 editor.queue_free()
 finish()
func finish() -> void:
 print("PRESTIGE_GATES ",checks," / ",failures)
 if not base.is_empty():FileAccess.open(base.path_join("prestige-gates-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"qualification_fixtures":true,"earned_xp_granted":false}))
 completed.emit()
 if not no_quit:get_tree().quit(1 if failures else 0)
