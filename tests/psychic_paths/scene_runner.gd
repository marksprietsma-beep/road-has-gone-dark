extends SceneTree
func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size()!=2:quit(1);return
 OS.set_environment("GAME127_PATH_RESTART","1" if args[1]=="cold" else "0")
 var script: GDScript=load("res://tests/psychic_paths/"+args[0]+".gd")
 if script==null or not script.can_instantiate():quit(1);return
 root.add_child(script.new())
