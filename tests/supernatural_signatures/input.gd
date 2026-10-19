extends Node
var checks := 0
var failures := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME148_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for pair in [["warlock","warlock-career-pressure","bandit-blade"],["binder","binder-sentinel","b"],["dragon","dragon-wide-fire","bandit-blade"]]:
  var b: Dictionary=saved.battles[pair[0]].duplicate(true);b.cursor=b.order.find("a");b.budget={"main":1,"move":1}
  ui.engine=TacticalAuras.new(b.units.a.record);b=ui.engine.seal(b)
  ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}}
  ui.mode=pair[1];ui.refresh()
  check(ui.action_buttons.has(pair[1]),"real supernatural action button "+pair[1])
  var p: Array=b.units[pair[2]].position
  check(ui.tiles[str(p)].target_tile,"legal target highlighted "+pair[1])
  ui.tiles[str(p)].mouse_entered.emit()
  check(ui.targeting.text.contains("Affects:"),"actual hover gives affected character preview "+pair[1])
  ui.choose_tile(p);check(ui.sent.get("kind")==pair[1] and ui.sent.get("target")==pair[2],"actual click emits chosen identity "+pair[1])
  check(ui.detail.text.contains("Weapon:") and ui.detail.text.contains("Shared reaction:"),"existing production feedback retained")
 var recovering: Dictionary=saved.battles.dragon_focused.duplicate(true)
 recovering.cursor=recovering.order.find("a");recovering.budget={"main":1,"move":1}
 ui.engine=TacticalAuras.new(recovering.units.a.record);recovering=ui.engine.seal(recovering)
 ui.state={"first_adventure":{"battle":recovering},"party_ids":["a","b","c"],"party":{"members":[]}}
 ui.mode="attack";ui.refresh()
 check(ui.action_buttons.has("dragon-focused-fire") and ui.action_buttons["dragon-focused-fire"].disabled,"real focused breath button disabled during persisted recovery despite ready main")
 check(ui.detail.text.contains("recovering"),"actual recovery feedback visible")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual production Godot buttons, target hitboxes and affected-unit hover"}))
 get_tree().quit(1 if failures else 0)
