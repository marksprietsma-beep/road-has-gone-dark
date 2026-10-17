extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME130_PHASE")
 var script_path: String={"mechanics":"res://tests/spell_repertoires/mechanics_driver.gd","journey":"res://tests/spell_repertoires/journey_driver.gd","capture":"res://tests/spell_repertoires/capture_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd"}.get(phase,"")
 if script_path.is_empty():push_error("Unknown GAME130 phase");get_tree().quit(1);return
 var script: GDScript=load(script_path)
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 var worker: Node=script.new()
 if phase=="capture":get_tree().root.add_child(worker);return
 worker.no_quit=true;add_child(worker);await worker.completed
 get_tree().quit(1 if worker.failures else 0)
