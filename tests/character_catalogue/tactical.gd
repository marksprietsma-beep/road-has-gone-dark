extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:root.add_child(load("res://tests/character_catalogue/tactical_driver.gd").new())
