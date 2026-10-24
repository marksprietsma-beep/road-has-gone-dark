extends SceneTree
func _initialize() -> void:
 for id in ["probe","mechanics","input","journey","connected"]:
  var script: GDScript=load("res://tests/hybrid_acceptance/"+id+".gd")
  if script==null or not script.can_instantiate():push_error("Hybrid worker does not compile: "+id);quit(1);return
 quit(0)
