extends SceneTree
func _initialize() -> void:
 var path := "journey_driver" if OS.get_environment("GAME112W4_PHASE")=="journey" else "mechanics_driver"
 var script: GDScript=load("res://tests/character_wave_four/"+path+".gd")
 if script==null or not script.can_instantiate():quit(1);return
 root.call_deferred("add_child",script.new())
