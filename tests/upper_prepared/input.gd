extends Node
var checks := 0
var failures := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME150_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var book := SpellbookEditor.new();add_child(book)
 for cls in ["wizard","cleric"]:
  var record: Dictionary=saved.records[cls+"20"].duplicate(true);var source := RulesRecords.registry(record);var kernel := RulesCharacter.new(source)
  var before := RulesJson.digest(record);book.setup(record)
  book.repertoire_search.text="tier 8";book.repertoire_search.text_changed.emit("tier 8")
  var upper: String="wizard-unweaving-tide" if cls=="wizard" else "cleric-concord-release"
  var first: String=book.controls.keys().filter(func(aid: String):return source.definition("abilities",aid).get("spell_tier")==1)[0]
  check(book.controls[upper].get_parent().visible,"actual typed tier search exposes new upper choice")
  check(not book.controls[first].get_parent().visible,"actual typed tier search hides unrelated early choices")
  check(book.preparation_summaries.has(cls),"actual prepared-tier budget summary "+cls)
  for id in book.controls:
   if book.controls[id] is SpinBox:book.controls[id].value=0
  var id: String="wizard-unweaving-tide" if cls=="wizard" else "cleric-concord-release"
  var capacity: int=int(kernel.derive_character(record).snapshot.resource_capacities[cls+"-slots-8"])
  var spin: SpinBox=book.controls[id]
  check(spin.editable,"real upper-tier spell control is selectable "+cls)
  spin.value=capacity+1
  check(book.preparation_summaries[cls].text.contains("Tier8: copies%d/%d OVER"%[capacity+1,capacity]),"actual SpinBox exposes over-budget preparation")
  check(book.preparation_summaries[cls].text.contains("slots%d/%d"%[record.runtime.resources[cls+"-slots-8"],capacity]),"actual unchanged current slots remain visible")
  var forged: Dictionary=record.duplicate(true);forged.choices.prepared_abilities=book.selection();forged.choices.spell_preparations=book.preparations()
  for pool in forged.runtime.resources:forged.runtime.resources[pool]=0
  var rejected := kernel.validate_build(forged)
  check(not rejected.ok and rejected.errors.any(func(e: Dictionary):return e.code=="spell.preparation_budget"),"rules reject same actual staged excess")
  spin.value=1
  check(not book.preparation_summaries[cls].text.contains("OVER") and book.selection().has(id),"actual corrected staging updates tier budget")
  check(RulesJson.digest(record)==before,"GUI staging never restores or mutates campaign resources")
  book.setup(saved.records["low-"+cls])
  var high: String="wizard-stillness-lattice" if cls=="wizard" else "cleric-renewing-benediction"
  check(not book.controls[high].editable and book.controls[high].tooltip_text.contains("Unavailable:"),"actual upper-tier attribute gate is explained")
  var editor: Control=load("res://scripts/ui/components/build_editor.gd").new();add_child(editor);editor.setup(saved.records[cls+"5"],true)
  check(editor.career_pickers.has(cls+"-choice-6"),"actual advancement specialisation picker exists")
  if editor.career_pickers.has(cls+"-choice-6"):
   var picker: OptionButton=editor.career_pickers[cls+"-choice-6"]
   for i in picker.item_count:
    var other: bool=str(picker.get_item_metadata(i))!=("evocation" if cls=="wizard" else "healing")
    check(picker.is_item_disabled(i)==other,"actual advanced school/domain locks mismatched origin")
    if other:check(not picker.get_popup().get_item_tooltip(i).is_empty(),"locked class option explains prerequisite")
  editor.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 var b: Dictionary=saved.battles.controlled_player.duplicate(true)
 ui.engine=TacticalAuras.new(b.units.a.record);ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode="attack";ui.refresh()
 check(ui.detail.text.contains("Stillness prevents"),"actual combat explains suppressed main action")
 check(ui.action_buttons.has("attack") and ui.action_buttons.attack.disabled,"actual attack control cannot bypass suppression")
 book.queue_free();ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual production prepared-copy, tier budgets, permanent requirements, advancement pickers and combat controls; no OS automation claim"}))
 get_tree().quit(1 if failures else 0)
