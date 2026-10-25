extends SceneTree
func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 if args.is_empty():quit(1);return
 var worker: GDScript=load("res://tests/hybrid_acceptance/"+args[0]+".gd")
 if worker==null or not worker.can_instantiate():quit(1);return
 root.add_child(worker.new())
