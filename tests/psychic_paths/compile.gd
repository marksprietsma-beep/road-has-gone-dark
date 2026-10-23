extends SceneTree
func _initialize() -> void:
 var failures := 0
 for name in ["mechanics","input","journey","connected","capture","native_launch"]:
  var script: GDScript=load("res://tests/psychic_paths/"+name+".gd")
  if script==null or not script.can_instantiate():failures+=1;push_error("Cannot compile path worker "+name)
 quit(1 if failures else 0)
