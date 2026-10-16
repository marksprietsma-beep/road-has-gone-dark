extends SceneTree
func _initialize() -> void:
 var script: GDScript=load("res://tests/character_completeness/prestige_driver.gd")
 if script==null or not script.can_instantiate():quit(1);return
 root.call_deferred("add_child",script.new())
