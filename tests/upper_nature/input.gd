extends Node
var checks := 0
var failures := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("UPPER_NATURE_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for cls in ["sorcerer","druid"]:
  var record: Dictionary=saved.records[cls+"20"];var book := SpellbookEditor.new();add_child(book);book.setup(record)
  var first: String="sorcerer-refraction-guard" if cls=="sorcerer" else "druid-heartwood-renewal"
  var second: String="sorcerer-cascade-well" if cls=="sorcerer" else "druid-wildheart-mantle"
  book.repertoire_search.text="tier 8";book.repertoire_search.text_changed.emit("tier 8")
  check(book.controls.has(first) and book.controls[first].get_parent().visible,"actual tier8 search exposes choice "+cls)
  check(not book.controls[second].get_parent().visible,"actual tier search hides other tier")
  if cls=="sorcerer":
   book.controls[first].button_pressed=true;check(book.selection().has(first),"actual spontaneous known checkbox")
  else:
   book.controls[first].value=1;check(book.selection().has(first) and book.preparations()[first]==1,"actual prepared-copy selector")
  var original := RulesJson.digest(record);book.repertoire_search.text="tier 9";book.repertoire_search.text_changed.emit("tier 9")
  check(book.controls[second].get_parent().visible and RulesJson.digest(record)==original,"search/staging changes no saved state")
  book.queue_free()
  var creator := BuildEditor.new();add_child(creator);creator.setup(saved.records[cls+"1"],false)
  check(creator.class_options().has(cls),"actual starting base class "+cls)
  creator.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for id in ["sorcerer-refraction-guard","sorcerer-cascade-well","druid-heartwood-renewal","druid-wildheart-mantle"]:
  var b: Dictionary=saved.battles[id].duplicate(true);var cls: String="sorcerer" if id.begins_with("sorcerer") else "druid"
  b.units.a.record=saved.records[cls+"20"].duplicate(true);b.units.a.record.character_id="a"
  b.units.a.record.runtime.companions={};RulesEntities.synchronize(b.units.a.record,RulesRecords.registry(b.units.a.record))
  b.units.a.record.choices.prepared_abilities=[id];b.units.a.record.choices.spell_preparations={id:1} if cls=="druid" else {}
  var kernel := RulesCharacter.new(RulesRecords.registry(b.units.a.record));b.units.a.record.runtime.resources=kernel._replay(b.units.a.record).context.capacities.duplicate()
  ui.engine=TacticalAuras.new(b.units.a.record);b.budget={"main":1,"move":1};b.cursor=b.order.find("a");b=ui.engine.seal(b)
  ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode="attack";ui.refresh()
  check(ui.action_buttons.has(id) and not ui.action_buttons[id].disabled,"actual affordable combat spell button "+id)
  if not ui.action_buttons.has(id):continue
  ui.action_buttons[id].pressed.emit()
  var target: String="a" if cls=="sorcerer" else "b"
  if target=="b":
   var position: Array=b.units.b.position;check(ui.tiles[str(position)].target_tile,"actual ally target hitbox")
   ui.tiles[str(position)].pressed.emit()
  check(ui.sent.get("kind")==id and ui.sent.get("target")==target,"production spell intent "+id)
  var result: Dictionary=ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":id,"target_id":target})
  check(result.ok,"production intent executes "+id)
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual Godot creator, known/prepared spellbook, tactical action buttons and tile targeting"}))
 get_tree().quit(1 if failures else 0)
