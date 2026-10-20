extends Node
func _ready() -> void:
 var phase := OS.get_environment("GAME150_PHASE")
 var paths := {"mechanics":"res://tests/upper_prepared/mechanics.gd","input":"res://tests/upper_prepared/input.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(script.new())
