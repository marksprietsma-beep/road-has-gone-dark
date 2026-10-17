extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME133_PHASE")
 var script_path: String={"input":"res://tests/nature_repertoires/input_driver.gd","connected":"res://tests/nature_repertoires/connected_driver.gd","mechanics":"res://tests/nature_repertoires/mechanics_driver.gd","journey":"res://tests/nature_repertoires/journey_driver.gd","capture":"res://tests/nature_repertoires/capture_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd"}.get(phase,"")
 if script_path.is_empty():push_error("Unknown GAME133 phase");get_tree().quit(1);return
 var script: GDScript=load(script_path)
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 var worker: Node=script.new()
 if phase=="capture":get_tree().root.add_child(worker);return
 worker.no_quit=true;add_child(worker);await worker.completed
 get_tree().quit(1 if worker.failures else 0)
