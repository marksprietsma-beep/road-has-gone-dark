extends Node
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME129_PHASE")
 if phase.is_empty():phase="mechanics"
 var paths := {"mechanics":"res://tests/class_signatures/mechanics_driver.gd","input":"res://tests/class_signatures/input_driver.gd","journey":"res://tests/class_signatures/journey_driver.gd","connected":"res://tests/class_signatures/connected_driver.gd","capture":"res://tests/class_signatures/capture_driver.gd","audit":"res://tests/character_completeness/audit_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd","v18":"res://tests/nature_repertoires/mechanics_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 var worker: Node=script.new()
 if phase=="capture":get_tree().root.add_child(worker);return
 worker.no_quit=true;add_child(worker);await worker.completed
 get_tree().quit(1 if worker.failures else 0)
