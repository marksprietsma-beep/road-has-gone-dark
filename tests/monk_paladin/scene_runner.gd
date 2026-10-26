extends SceneTree
func _initialize() -> void:call_deferred("launch")
func launch() -> void:
 var args := OS.get_cmdline_user_args()
 var phase: String=args[0] if not args.is_empty() else "probe"
 var paths := {"probe":"res://tests/monk_paladin/probe.gd","mechanics":"res://tests/monk_paladin/mechanics.gd"}
 if not paths.has(phase):quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():quit(1);return
 root.add_child(script.new())
