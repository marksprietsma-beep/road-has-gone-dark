extends SceneTree
func _initialize() -> void:call_deferred("launch")
func launch() -> void:
 var args := OS.get_cmdline_user_args()
 var phase: String=args[0] if not args.is_empty() else "probe"
 var paths := {"probe":"res://tests/dual_prestige_acceptance/probe.gd","mechanics":"res://tests/dual_prestige_acceptance/mechanics.gd","input":"res://tests/dual_prestige_acceptance/input.gd"}
 if not paths.has(phase):quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():quit(1);return
 root.add_child(worker.new())
