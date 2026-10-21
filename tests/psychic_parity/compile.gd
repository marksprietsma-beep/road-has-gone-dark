extends SceneTree
func _initialize() -> void:
 var failures := 0
 for name in ["baseline","mechanics","input","journey","connected","capture","current_upper","current_performance","current_supernatural","current_signatures","current_mobile"]:
  var script: GDScript=load("res://tests/psychic_parity/"+name+".gd")
  if script==null or not script.can_instantiate():failures+=1;push_error("Cannot compile focused script "+name)
 quit(1 if failures else 0)
