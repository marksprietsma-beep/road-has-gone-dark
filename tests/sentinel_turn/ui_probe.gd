extends "res://scripts/ui/first_adventure.gd"
## Keep production buttons/send/gating. Capture the dispatched intent, then use
## the original pure authority. Campaign/save-path testing is a separate phase.
var intents := []
var last_result := {}
func operate(_operation: String,input: Dictionary={}) -> void:
 if input.is_empty():return
 intents.append(input.duplicate(true));last_result=engine.command(battle(),input)
 if last_result.ok:state.first_adventure.battle=last_result.battle;refresh()
