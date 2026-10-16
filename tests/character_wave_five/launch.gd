extends SceneTree
func _initialize() -> void:
 var phase := "earned_driver" if OS.get_environment("GAME112W5_PHASE")=="earned" else "mechanics_driver"
 var script: GDScript=load("res://tests/character_wave_five/"+phase+".gd")
 if script==null or not script.can_instantiate():quit(1);return
 root.call_deferred("add_child",script.new())
