extends SceneTree
func _initialize() -> void:
 var failed := false
 for name in ["mechanics","input","scene_runner","journey","connected","capture","native_launch","current_upper"]:
  var worker: GDScript=load("res://tests/upper_nature/"+name+".gd")
  if worker==null or not worker.can_instantiate():failed=true
 quit(1 if failed else 0)
