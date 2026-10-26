extends SceneTree
func _initialize() -> void:call_deferred("launch")
func launch() -> void:
 var args := OS.get_cmdline_user_args()
 var phase: String=args[0] if not args.is_empty() else "probe"
 var paths := {"probe":"res://tests/martial_careers/probe.gd","mechanics":"res://tests/martial_careers/mechanics.gd","input":"res://tests/martial_careers/input.gd","journey":"res://tests/martial_careers/journey.gd","connected":"res://tests/martial_careers/connected.gd","capture":"res://tests/martial_careers/capture.gd","extended":"res://tests/martial_careers/extended.gd"}
 if phase=="compile":
  for path in paths.values():
   var script: GDScript=load(path)
   if script==null or not script.can_instantiate():quit(1);return
  print("MARTIAL_WORKERS_COMPILE");quit(0);return
 if not paths.has(phase):quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():quit(1);return
 root.add_child(worker.new())
