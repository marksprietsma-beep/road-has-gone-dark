extends SceneTree
func _initialize() -> void:call_deferred("launch")
func launch() -> void:
 var worker: GDScript=load("res://tests/grove_summoner/probe.gd")
 if worker==null or not worker.can_instantiate():quit(1);return
 root.add_child(worker.new())
