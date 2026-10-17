extends SceneTree
func _initialize() -> void:root.call_deferred("add_child",load("res://tests/character_completeness/compatibility_driver.gd").new())
