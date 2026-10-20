extends Node
var checks := 0
var failures := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME149_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var book := SpellbookEditor.new();add_child(book)
 for cls in ["bard","beguiler","spirit-shaman"]:
  var r: Dictionary=saved.records["low-"+cls].duplicate(true)
  # Lawful high-level history with low current permanent casting attribute: legal build,
  # but some granted higher-tier abilities cannot be learned/cast at this attribute.
  r.choices.prepared_abilities=[]
  var registry := RulesRecords.registry(r);var valid := RulesCharacter.new(registry).derive_character(r)
  check(valid.ok,"lawful low-attribute advanced UI fixture "+cls)
  if not valid.ok:continue
  book.setup(r)
  var unavailable := 0
  for id in book.controls:
   var a := registry.definition("abilities",id)
   if not RulesCoreContent.spell_eligible(valid.snapshot,a):
    unavailable+=1;check(book.controls[id].disabled and book.controls[id].tooltip_text.contains("Unavailable:"),"real ineligible spontaneous control disabled "+id)
  check(unavailable>0,"fixture actually exposes unavailable tier choices "+cls)
  check(book.selection_summaries.has(cls),"class staged selection summary")
 var r: Dictionary=saved.records["spirit-shaman12"].duplicate(true)
 r.choices.prepared_abilities=["spirit-shaman-spirit-rebuke-1"];r.runtime.resources["spirit-retrieval"]=1
 book.setup(r);var prior := RulesJson.digest(r)
 var control: CheckBox=book.controls["spirit-shaman-spirit-refuge-1"]
 check(not control.disabled,"real retrieval control available with permit")
 control.button_pressed=true
 check(book.selection().has("spirit-shaman-spirit-refuge-1") and RulesJson.digest(r)==prior,"actual checkbox stages selection without mutating saved permit/slots")
 check(book.selection_summaries["spirit-shaman"].text.begins_with("Proposed selection: 2"),"staged summary follows actual checkbox")
 r.runtime.resources["spirit-retrieval"]=0;book.setup(r)
 check(book.controls.values().all(func(c: Control):return c.disabled),"all retrieved choices lock when actual permit exhausted")
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 var b: Dictionary=saved.battles.bard6.duplicate(true);b.cursor=b.order.find("a");b.budget={"main":1,"move":1}
 ui.engine=TacticalAuras.new(b.units.a.record);b=ui.engine.seal(b);ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode="attack";ui.refresh()
 check(ui.detail.text.contains("Maintained rally:") and ui.detail.text.contains("Performance uses:"),"real combat shows maintained state and finite pool")
 check(ui.action_buttons.has("bard-stop-performance"),"actual free stop control")
 ui.action_buttons["bard-stop-performance"].pressed.emit()
 check(ui.sent.get("kind")=="bard-stop-performance","actual button emits existing authoritative command")
 book.queue_free();ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual production spellbook checkboxes, staged summaries, permanent eligibility and combat controls"}))
 get_tree().quit(1 if failures else 0)
func source_attribute(cls: String) -> String:return "CHA"if cls=="bard"else"INT"if cls=="beguiler"else"WIS"
