extends Node
signal completed
var no_quit := false
var failures := 0
var checks := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME133_ROOT")
 var saved := RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 var battle: Dictionary=saved.battle.duplicate(true)
 ui.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
 ui.engine=TacticalAuras.new(battle.units.a.record);ui.mode="druid-packward-canopy";ui.refresh()
 var pet_id := RulesEntities.identity("a");var p: Array=battle.units[pet_id].position
 check(ui.tiles.has(str(p)) and ui.tiles[str(p)].target_tile,"actual pet tile highlighted")
 ui.choose_tile(p)
 check(ui.sent.get("kind")=="druid-packward-canopy" and ui.sent.get("target")==pet_id,"production click selects companion identity")
 check(ui.action_buttons.has("druid-packward-canopy"),"real combat action exposes new spell")
 var spellbook := SpellbookEditor.new();var record: Dictionary=saved.records["sorcerer-crystal-reservoir"]
 spellbook.setup(record)
 check(spellbook.controls["sorcerer-crystal-reservoir"].button_pressed and spellbook.controls["sorcerer-crystal-reservoir"].disabled,"known spontaneous choice is visible and locked")
 check(not spellbook.controls["sorcerer-slipstream-veil"].disabled,"unknown legal spontaneous option can be learned")
 spellbook.free()
 var granted := RulesEffects.new(RulesRecords.registry(record)).use_ability(record,record,"sorcerer-crystal-reservoir",{"main":1,"move":1,"reaction":1},RulesRng.initial("visible-buffer"))
 check(granted.ok,"real spell supplies displayed buffer")
 if granted.ok:
  for id in battle.units.keys().duplicate():
   if battle.units[id].has("entity"):battle.units.erase(id);battle.order.erase(id)
  battle.units.a.record=granted.actor;battle.cursor=battle.order.find("a")
  ui.engine=TacticalAuras.new(granted.actor);battle=ui.engine.seal(battle)
  check(ui.engine.current(battle).id=="a","buffer fixture explicitly selects the displaying actor")
  check(ui.engine.validate(battle).is_empty(),"buffer UI fixture remains an authoritative valid battle")
  ui.state.first_adventure.battle=battle;ui.mode="attack";ui.refresh()
  check("18 temporary HP"in ui.detail.text,"active character sees actual finite HP buffer")
  check("18 temporary HP"in ui.tiles[str(battle.units.a.position)].tooltip_text,"hover targeting exposes real buffer")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Production combat click/highlights and persistent known-spell controls."}))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
