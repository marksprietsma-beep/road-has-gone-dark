extends Node
var checks := 0
var failures := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME146_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for pair in [["flourish-true","swashbuckler-technique-4"],["knight","knight-technique-4"]]:
  var b: Dictionary=saved.battles[pair[0]].duplicate(true);b.cursor=b.order.find("a");b.budget={"main":1,"move":1}
  ui.engine=TacticalAuras.new(b.units.a.record);b=ui.engine.seal(b)
  ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}}
  ui.mode="attack";ui.refresh()
  check(ui.detail.text.contains("Shared reaction:") and ui.detail.text.contains("Weapon:"),"production resource and weapon feedback "+pair[0])
  check(ui.action_buttons.has(pair[1]),"actual signature button "+pair[1])
  ui.mode=pair[1];ui.refresh();var p: Array=b.units["bandit-blade"].position
  check(ui.tiles[str(p)].target_tile,"actual target highlight "+pair[1])
  ui.choose_tile(p);check(ui.sent.get("kind")==pair[1] and ui.sent.get("target")=="bandit-blade","actual tile click emits authoritative identity "+pair[1])
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Real production Godot combat buttons and hitboxes"}))
 get_tree().quit(1 if failures else 0)
