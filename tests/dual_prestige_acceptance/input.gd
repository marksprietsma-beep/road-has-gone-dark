extends "res://tests/hybrid_acceptance/input.gd"
func run() -> void:
 var base := OS.get_environment("DUAL_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var source := RulesRecords.registry(saved.records.wizard_qualified);var kernel := RulesCharacter.new(source)
 var creator := BuildEditor.new();add_child(creator)
 var first: Dictionary=saved.records.wizard_qualified.duplicate(true)
 first.advancement_history=first.advancement_history.slice(0,1)
 # Use an actual legal starting record, not a truncated advanced runtime.
 first=kernel.preview_advancement(kernel.create("creator-probe",first.base_attributes,first.ancestry_ref),kernel.suggested_choice(kernel.create("creator-probe",first.base_attributes,first.ancestry_ref),"wizard").choice).candidate
 creator.setup(first,false)
 check(creator.class_options().has("wizard") and not creator.class_options().has("mystic-theurge") and not creator.class_options().has("abjurant-champion"),"all initial class controls exclude prestige")
 creator.queue_free()
 for spec in [["wizard_qualified","mystic-theurge","mystic-theurge-arcane","wizard"],["sorcerer_qualified","mystic-theurge","mystic-theurge-arcane","sorcerer"],["champion_qualified","abjurant-champion","abjurant-casting","duskblade"]]:
  var record: Dictionary=saved.records[spec[0]];var before := RulesJson.digest(record)
  var editor := BuildEditor.new();add_child(editor);editor.setup(record,true)
  var index := find(editor.class_picker,spec[1])
  check(index>=0 and not editor.class_picker.is_item_disabled(index),"qualified path remains deliberate UI option "+spec[0])
  if index>=0:editor.class_picker.select(index);editor.class_picker.item_selected.emit(index)
  check(editor.career_pickers.has(spec[2]),"actual permanent parent selector exists "+spec[0])
  if editor.career_pickers.has(spec[2]):
   var picker: OptionButton=editor.career_pickers[spec[2]];var parent := find(picker,spec[3])
   check(parent>=0 and not picker.is_item_disabled(parent),"own lawful parent selectable "+spec[0])
   if parent>=0:picker.select(parent);picker.item_selected.emit(parent)
   if spec[1]=="mystic-theurge":
    check(editor.career_pickers.has("mystic-theurge-divine"),"separate divine track selection")
    var divine: OptionButton=editor.career_pickers["mystic-theurge-divine"];var cleric := find(divine,"cleric")
    if cleric>=0:divine.select(cleric);divine.item_selected.emit(cleric)
   else:
    var doctrine: OptionButton=editor.career_pickers["abjurant-doctrine-1"];var ret := find(doctrine,"retaliation")
    if ret>=0:doctrine.select(ret);doctrine.item_selected.emit(ret)
   var choice := editor.choice();check(kernel.preview_advancement(record,choice).ok,"actual selected controls yield legal persistent choice "+spec[0])
  check(RulesJson.digest(record)==before,"preview/control exploration cannot grant prestige or XP")
  editor.queue_free()
 var book := SpellbookEditor.new();add_child(book);book.setup(saved.records["wizard:theurge10"])
 check(book.controls.has("wizard-arcane-bolt") and book.controls.has("cleric-bless"),"actual spellbook exposes both independent traditions")
 book.queue_free()
 book=SpellbookEditor.new();add_child(book);book.setup(saved.records.junior_parent)
 check(not book.controls.has("sorcerer-tier2-tempest"),"junior Sorcerer spellbook cannot borrow qualifying Wizard's tier2")
 book.queue_free()
 var helper: Node=load("res://tests/dual_prestige_acceptance/base.gd").new();helper.source=source;helper.kernel=kernel;helper.fixtures.fighter=saved.records.fighter
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 var record: Dictionary=saved.records["champion:retaliation1"]
 var b: Dictionary=helper.encounter(record);ui.engine=TacticalAuras.new(record)
 var id := "abjurant-retaliation-1";var target: Array=b.units["bandit-blade"].position
 show(ui,b,id)
 check(ui.action_buttons.has(id) and not ui.action_buttons[id].disabled and ui.tiles[str(target)].target_tile,"legal melee power has enabled button and precise target")
 ui.choose_tile(target)
 check(ui.sent.kind==id and ui.sent.target=="bandit-blade","actual target click retains exact ability/enemy intent")
 var out: Dictionary=ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":id,"target_id":"bandit-blade"})
 check(out.ok,"production UI intent executes through existing authority")
 for reason in ["spent-main","empty-resolve","bow"]:
  var blocked := b.duplicate(true)
  if reason=="spent-main":blocked.budget.main=0
  elif reason=="empty-resolve":blocked.units.a.record.runtime.resources["abjurant-resolve"]=0
  else:blocked.units.a.record.equipment=["bow"];blocked.units.a.weapon="bow"
  blocked=ui.engine.seal(blocked);show(ui,blocked,id);ui.sent={};ui.choose_tile(target)
  check(ui.action_buttons[id].disabled and not ui.tiles[str(target)].target_tile and ui.sent.is_empty(),"unavailable power has no misleading target or click intent "+reason)
  check(not ui.engine.command(blocked,{"actor_id":"a","revision":blocked.revision,"kind":id,"target_id":"bandit-blade"}).ok,"authority still rejects unavailable power "+reason)
 ui.queue_free();helper.free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"scope":"Actual production creator/advancement/parent/spellbook/melee-power controls; development fixtures, no XP granted"}))
 print("DUAL_PRESTIGE_INPUT ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
