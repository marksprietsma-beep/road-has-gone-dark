extends SceneTree
func _initialize() -> void:call_deferred("launch")
func launch() -> void:
 var args := OS.get_cmdline_user_args()
 var phase: String=args[0] if not args.is_empty() else "probe"
 var paths := {"probe":"res://tests/ranger_steward/probe.gd","mechanics":"res://tests/ranger_steward/mechanics.gd","input":"res://tests/ranger_steward/input.gd","journey":"res://tests/ranger_steward/journey.gd","connected":"res://tests/ranger_steward/connected.gd","capture":"res://tests/ranger_steward/capture.gd"}
 if phase=="compile":
  for path in paths.values()+["res://tests/ranger_steward/native_launch.gd","res://tests/ranger_steward/current_upper.gd","res://tests/monk_paladin/mechanics.gd","res://tests/monk_paladin/input.gd"]:
   var worker: GDScript=load(path)
   if worker==null or not worker.can_instantiate():quit(1);return
  print("RANGER_STEWARD_COMPILE");quit(0);return
 if not paths.has(phase):quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():quit(1);return
 root.add_child(script.new())
