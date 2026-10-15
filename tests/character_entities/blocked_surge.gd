extends SceneTree
func _initialize() -> void:
 root.call_deferred("add_child",load("res://tests/character_entities/blocked_surge_driver.gd").new())
