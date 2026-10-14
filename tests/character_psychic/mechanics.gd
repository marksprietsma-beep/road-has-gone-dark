extends SceneTree
func _initialize() -> void:
 root.call_deferred("add_child",load("res://tests/character_psychic/mechanics_driver.gd").new())
