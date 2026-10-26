extends "res://tests/hybrid_acceptance/input.gd"
signal completed
var no_quit := false
func run() -> void:
 var folder := OS.get_environment("MARTIAL_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(folder.path_join("saved.json")))
 var source := RulesRecords.registry(saved.records.pointblank);var kernel := RulesCharacter.new(source)
 var helper: Node=load("res://tests/martial_careers/mechanics.gd").new();helper.source=source;helper.kernel=kernel
 helper.fixtures.fighter=helper.variant("fighter",20)
 for spec in [["fighter","bow"],["barbarian","resilient"]]:
  var r: Dictionary=helper.variant(spec[0],1)
  var before := RulesJson.digest(r);var editor := BuildEditor.new();add_child(editor);editor.setup(r,false)
  check(editor.class_options().has("fighter") and editor.class_options().has("barbarian") and not editor.class_options().has("mystic-theurge"),"actual first-open creator exposes base careers only")
  var class_index := find(editor.class_picker,spec[0]);check(class_index>=0,"actual class control "+spec[0])
  if class_index>=0:editor.class_picker.select(class_index);editor.class_picker.item_selected.emit(class_index)
  editor.class_filter.text="barbarian";editor.class_filter.text_changed.emit("barbarian")
  check(find(editor.class_picker,"barbarian")>=0,"real class search retains matching base career")
  editor.class_filter.text="";editor.class_filter.text_changed.emit("")
  check(editor.class_picker.item_count==kernel.starting_classes().size(),"clearing class search restores all base options")
  var group: String=spec[0]+"-choice-1"
  check(editor.career_pickers.has(group),"real early specialisation control "+group)
  if editor.career_pickers.has(group):
   var picker: OptionButton=editor.career_pickers[group];var index := find(picker,spec[1])
   check(index>=0 and not picker.is_item_disabled(index),"alternative player choice is legal "+str(spec))
   if index>=0:picker.select(index);picker.item_selected.emit(index)
  if spec[0]=="fighter":
   for id in editor.equipment_pickers:
    var selected: bool=id in ["bow","leathers"]
    if editor.equipment_pickers[id].button_pressed!=selected:editor.equipment_pickers[id].button_pressed=selected
   var dex: OptionButton=editor.attribute_pickers.DEX;var high := find(dex,"15")
   check(high>=0,"real standard-array score option")
   if high>=0:dex.select(high);dex.item_selected.emit(high)
   editor.feat_filter.text="Archery";editor.feat_filter.text_changed.emit("Archery")
   check(find(editor.feat_picker,"point-blank-shot")>=0,"real feat search finds a different legal feat")
   editor.feat_filter.text="";editor.feat_filter.text_changed.emit("")
   check(editor.feat_picker.item_count==source.ids("feats").size(),"empty search restores all legal and prerequisite-locked feats")
   var feat := find(editor.feat_picker,"point-blank-shot")
   check(feat>=0 and not editor.feat_picker.is_item_disabled(feat),"real ranged feat choice "+JSON.stringify({"index":feat,"budget":editor.budget.text,"preview":editor.preview,"attributes":editor.attributes,"allocation":editor.allocation,"items":range(editor.feat_picker.item_count).map(func(n: int):return [editor.feat_picker.get_item_metadata(n),editor.feat_picker.is_item_disabled(n),editor.feat_picker.get_popup().get_item_tooltip(n)])}))
   if feat>=0:editor.feat_picker.select(feat);editor.feat_picker.item_selected.emit(feat)
  var payload := editor.definition()
  var created := CharacterBuilderRecords.create(r.character_id,payload,r)
  check(created.ok,"real creator controls produce a legal persistent character "+str(spec)+JSON.stringify(created.get("errors",[])))
  if created.ok:
   check(created.candidate.advancement_history[0].specialisations[group]==spec[1],"selected mechanical identity survives creator payload")
   if spec[0]=="fighter":check(created.candidate.equipment.has("bow") and created.candidate.base_attributes.DEX==15 and created.candidate.advancement_history[0].feat_id=="point-blank-shot","actual gear/score-picker/feat handlers preserve deliberate ranged build")
  check(RulesJson.digest(r)==before,"creator exploration never mutates existing campaign record")
  editor.queue_free()
 var qualified: Dictionary=helper.variant("fighter",5,{},"weapon-focus")
 var editor := BuildEditor.new();add_child(editor);editor.setup(qualified,true)
 check(editor.feat_picker!=null,"actual Fighter scheduled feat advancement control")
 if editor.feat_picker!=null:
  var feat := find(editor.feat_picker,"veteran-weapon-training")
  check(feat>=0 and not editor.feat_picker.is_item_disabled(feat),"legitimate feat chain is available at its earned class level")
  if feat>=0:editor.feat_picker.select(feat);editor.feat_picker.item_selected.emit(feat)
  check(kernel.preview_advancement(qualified,editor.choice()).ok,"actual selected feat control produces lawful next level")
 editor.queue_free()
 var resilient: Dictionary=helper.variant("barbarian",14,helper.step_options("barbarian","resilient"))
 editor=BuildEditor.new();add_child(editor);editor.setup(resilient,true)
 check(editor.career_pickers.has("barbarian-choice-15"),"late Rage power mastery choice remains visible")
 if editor.career_pickers.has("barbarian-choice-15"):
  var picker: OptionButton=editor.career_pickers["barbarian-choice-15"];var index := find(picker,"resilient")
  check(index>=0 and not picker.is_item_disabled(index),"late mastery meets its actual permanent prerequisites")
  if index>=0:picker.select(index);picker.item_selected.emit(index)
  for n in editor.sections.get_tab_count():
   if editor.sections.get_tab_title(n)=="Specialisation":editor.sections.current_tab=n
  var row: Node=picker.get_parent();var detail: Label=row.get_parent().get_child(row.get_index()+1)as Label
  check(detail!=null and detail.is_visible_in_tree() and "+2 Fortitude"in detail.text,"selected late mastery visibly explains its actual save benefit")
  var step := kernel.preview_advancement(resilient,editor.choice());check(step.ok,"late UI choice is actually executable")
  if step.ok:check(step.snapshot.stats.fortitude==kernel.derive_character(resilient).snapshot.stats.fortitude+2,"late UI choice yields exact real numerical benefit")
 editor.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for spec in [["bow20","fighter-bow-6"],["blade20","fighter-blade-6"],["barbarian-resilient20","barbarian-resilient-6"]]:
  var r: Dictionary=saved.records[spec[0]];var b: Dictionary=helper.encounter(r);var id: String=spec[1]
  ui.engine=TacticalAuras.new(r);show(ui,b,id);ui.sent={};var p: Array=b.units.a.position
  check(ui.action_buttons.has(id) and not ui.action_buttons[id].disabled and ui.tiles[str(p)].target_tile,"affordable real class action has a self-target highlight "+id)
  ui.choose_tile(p)
  check(ui.sent.get("kind")==id and ui.sent.get("target")=="a","production tile selects the exact actor/action")
  check(ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":id,"target_id":"a"}).ok,"real UI intent executes through inherited authority")
  for reason in ["spent-main","empty-resource","suppressed"]+(["wrong-weapon"]if spec[0]in ["bow20","blade20"]else[]):
   var blocked := b.duplicate(true)
   match reason:
    "spent-main":blocked.budget.main=0
    "empty-resource":blocked.units.a.record.runtime.resources["rage-uses"if id.begins_with("barbarian")else"fighter-resolve"]=0
    "suppressed":blocked.units.a.record.runtime.statuses.append({"id":"stillness-lattice","source":"fixture","remaining":1,"expiry":"global_round_start"})
    "wrong-weapon":
     var weapon: String="shortblade"if spec[0]=="bow20"else"bow"
     blocked.units.a.record.equipment=[weapon,"leathers"];blocked.units.a.weapon=weapon
   blocked=ui.engine.seal(blocked);var before := RulesJson.digest(blocked);show(ui,blocked,id);ui.sent={};ui.choose_tile(p)
   check(ui.action_buttons[id].disabled and not ui.tiles[str(p)].target_tile and ui.sent.is_empty(),"unavailable action has no misleading target/intent "+id+reason)
   check(not ui.engine.command(blocked,{"actor_id":"a","revision":blocked.revision,"kind":id,"target_id":"a"}).ok,"authority rejects unavailable power "+reason)
   check(RulesJson.digest(blocked)==before and RulesJson.digest(ui.state.first_adventure.battle)==before,"denial preserves exact battle/log/RNG")
 ui.queue_free();check(helper.failures==0,"all UI fixture histories are legal");helper.free()
 FileAccess.open(folder.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false,"scope":"Actual original creator/advancement/attribute/gear/feat and combat controls; campaign writer exercised separately."}))
 print("MARTIAL_INPUT ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
