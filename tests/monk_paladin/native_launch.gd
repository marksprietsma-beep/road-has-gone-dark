extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("MONK_PALADIN_PHASE")
 var paths := {"probe":"res://tests/monk_paladin/probe.gd","mechanics":"res://tests/monk_paladin/mechanics.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(script.new())
