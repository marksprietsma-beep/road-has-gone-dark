extends Node
func _ready() -> void:get_tree().root.call_deferred("add_child",load("res://tests/adventure_cycles/earned_driver.gd").new())
