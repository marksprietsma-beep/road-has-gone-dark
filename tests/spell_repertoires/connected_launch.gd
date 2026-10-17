extends SceneTree
func _initialize() -> void:root.call_deferred("add_child",load("res://tests/spell_repertoires/connected_driver.gd").new())
