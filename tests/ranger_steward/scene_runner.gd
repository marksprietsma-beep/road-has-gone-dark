extends SceneTree
func _initialize() -> void:call_deferred("launch")
func launch() -> void:
 var script: GDScript=load("res://tests/ranger_steward/probe.gd")
 if script==null or not script.can_instantiate():quit(1);return
 root.add_child(script.new())
