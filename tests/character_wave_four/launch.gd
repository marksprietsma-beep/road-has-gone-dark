extends SceneTree
func _initialize() -> void:
 var phase := OS.get_environment("GAME112W4_PHASE")
 var path: String={"journey":"journey_driver","cohort":"cohort_driver","earned":"earned_driver"}.get(phase,"mechanics_driver")
 var script: GDScript=load("res://tests/character_wave_four/"+path+".gd")
 if script==null or not script.can_instantiate():quit(1);return
 root.call_deferred("add_child",script.new())
