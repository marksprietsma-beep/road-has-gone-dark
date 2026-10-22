extends SceneTree
func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size()!=2:quit(1);return
 OS.set_environment("GAME127_RESTART","1" if args[1]=="cold" else "0")
 var worker: GDScript=load("res://tests/psychic_support/"+args[0]+".gd")
 if worker==null or not worker.can_instantiate():quit(1);return
 root.add_child(worker.new())
