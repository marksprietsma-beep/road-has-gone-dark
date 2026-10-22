extends SceneTree
func _initialize() -> void:
 var failures := 0
 for name in ["baseline","mechanics","input","journey","connected","capture","current_psychic","current_upper","current_performance","current_supernatural","current_signatures","current_mobile"]:
  var script: GDScript=load("res://tests/psychic_identities/"+name+".gd")
  if script==null or not script.can_instantiate():failures+=1;push_error("Cannot compile identity script "+name)
 quit(1 if failures else 0)
