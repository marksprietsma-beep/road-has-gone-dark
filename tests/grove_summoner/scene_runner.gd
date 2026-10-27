extends SceneTree
func _initialize() -> void:call_deferred("launch")
func launch() -> void:
 var args := OS.get_cmdline_user_args();var phase: String=args[0]if not args.is_empty()else"probe"
 var paths := {"probe":"res://tests/grove_summoner/probe.gd","mechanics":"res://tests/grove_summoner/mechanics.gd","input":"res://tests/grove_summoner/input.gd","journey":"res://tests/grove_summoner/journey.gd","connected":"res://tests/grove_summoner/connected.gd","capture":"res://tests/grove_summoner/capture.gd"}
 if phase=="compile":
  for path in paths.values()+["res://tests/grove_summoner/native_launch.gd","res://tests/grove_summoner/current_upper.gd"]:
   var script: GDScript=load(path)
   if script==null or not script.can_instantiate():quit(1);return
  print("GROVE_SUMMONER_COMPILE");quit(0);return
 if not paths.has(phase):quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():quit(1);return
 root.add_child(worker.new())
