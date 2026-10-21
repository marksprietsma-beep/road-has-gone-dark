extends SceneTree
func _initialize() -> void:
 var failures := 0
 for name in ["baseline","mechanics","input","journey","connected"]:
  var script: GDScript=load("res://tests/psychic_parity/"+name+".gd")
  if script==null or not script.can_instantiate():failures+=1;push_error("Cannot compile focused script "+name)
 quit(1 if failures else 0)
