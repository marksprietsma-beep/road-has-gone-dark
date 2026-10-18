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
 var base := OS.get_environment("GAME129_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for cls in ["soulknife","warblade","crusader","swordsage"]:
  var battle: Dictionary=saved.battles[cls].duplicate(true)
  battle.cursor=battle.order.find("a");battle.budget={"main":1,"move":1}
  ui.engine=TacticalAuras.new(battle.units.a.record);battle=ui.engine.seal(battle)
  ui.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  ui.mode="attack";ui.refresh()
  check(ui.detail.text.contains("Shared reaction:") and ui.detail.text.contains("Weapon:"),"production resource/weapon/reaction feedback "+cls)
  var action: String={"soulknife":"soulknife-hurl","warblade":"warblade-arm-riposte","crusader":"crusader-recover","swordsage":"swordsage-arm-afterimage"}[cls]
  check(ui.action_buttons.has(action),"production visible signature control "+action)
  check(ui.action_buttons[action].text.contains("Movement") if cls in ["warblade","swordsage"] else ui.action_buttons[action].text.contains("Action"),"visible actual action cost "+cls)
  check(not ui.action_buttons.has("warblade-riposte") and not ui.action_buttons.has("swordsage-afterimage") and not ui.action_buttons.has("crusader-renewal"),"trigger-only effects never manually invokable")
  if cls=="warblade" or cls=="swordsage":
   ui.sent={};ui.action_buttons[action].pressed.emit()
   check(ui.sent.get("kind")==action and ui.sent.get("target")=="a","visible arm action sends existing campaign command")
  if cls=="soulknife":
   ui.mode="soulknife-technique-8";ui.refresh();var p: Array=battle.units["bandit-blade"].position
   check(ui.tiles[str(p)].target_tile,"correct melee targeting hitbox")
   ui.choose_tile(p);check(ui.sent.get("kind")=="soulknife-technique-8" and ui.sent.get("target")=="bandit-blade","production target click preserves real enemy identity")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual production combat controls/targeting; authority tested separately."}))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
