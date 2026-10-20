extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME149_PHASE")
 if phase.is_empty():phase="mechanics"
 var paths := {"mechanics":"res://tests/performance_spirit/mechanics.gd","input":"res://tests/performance_spirit/input.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(script.new())
