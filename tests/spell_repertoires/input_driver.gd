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
 var base := OS.get_environment("GAME130_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 var battle: Dictionary=saved.battle.duplicate(true)
 battle.units.b.record.runtime.hp=0
 ui.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
 ui.engine=TacticalAuras.new(battle.units.a.record);ui.mode="cleric-return-to-breath";ui.refresh()
 check(ui.tiles.has(str(battle.units.b.position)) and ui.tiles[str(battle.units.b.position)].target_tile,"real downed tile is highlighted")
 ui.choose_tile(battle.units.b.position)
 check(ui.sent.get("kind")=="cleric-return-to-breath" and ui.sent.get("target")=="b","real production click handler resolves downed identity")
 var record: Dictionary=saved.records.suppressed.duplicate(true)
 record.choices.prepared_abilities.append("cleric-summon-sentinel");record.choices.spell_preparations["cleric-summon-sentinel"]=1
 record.runtime.resources=RulesCharacter.new(RulesRecords.registry(record))._replay(record).context.capacities.duplicate()
 record.character_id="a";battle.units.a.record=record;battle.budget.main=1
 ui.state.first_adventure.battle=battle;ui.engine=TacticalAuras.new(record);ui.refresh()
 for id in ["cleric-freedom-path","cleric-summon-sentinel"]:
  check(ui.action_buttons.has(id) and ui.action_buttons[id].disabled,"targeted and self spell UI disabled by suppression "+id)
 check(ui.action_buttons.has("attack") and not ui.action_buttons.attack.disabled,"weapon action remains available while suppressed")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual production combat UI click/highlight/action controls; intent captured before campaign writer."}))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
