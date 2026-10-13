extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:root.add_child(load("res://tests/adventure_cycles/negative_driver.gd").new())
