extends SceneTree
func _initialize() -> void:call_deferred("launch")
func launch() -> void:
 var args: PackedStringArray=OS.get_cmdline_user_args()
 var phase: String=args[0]if not args.is_empty()else"probe"
 var paths: Dictionary={"probe":"res://tests/dragon_warshaper/probe.gd","mechanics":"res://tests/dragon_warshaper/mechanics.gd","input":"res://tests/dragon_warshaper/input.gd"}
 if not paths.has(phase):quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():quit(1);return
 root.add_child(worker.new())
