extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var script: GDScript=load("res://tests/sentinel_turn/probe.gd")
 if script==null or not script.can_instantiate():quit(1);return
 root.add_child(script.new())
