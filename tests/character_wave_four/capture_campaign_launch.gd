extends SceneTree
func _initialize() -> void:
 var script: GDScript=load("res://tests/character_wave_four/capture_campaign.gd")
 if script==null or not script.can_instantiate():quit(1);return
 root.call_deferred("add_child",script.new())
