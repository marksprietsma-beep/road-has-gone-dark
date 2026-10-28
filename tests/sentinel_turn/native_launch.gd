extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var paths := {"probe":"res://tests/sentinel_turn/probe.gd","campaign":"res://tests/sentinel_turn/campaign.gd","legacy":"res://tests/character_completeness/compatibility_driver.gd"}
 var phase := OS.get_environment("SENTINEL_PHASE")
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(script.new())
