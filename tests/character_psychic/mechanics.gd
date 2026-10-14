extends SceneTree
func _initialize() -> void:
 var worker: GDScript=load("res://tests/character_psychic/mechanics_driver.gd")
 if worker==null or not worker.can_instantiate():quit(1);return
 root.call_deferred("add_child",worker.new())
