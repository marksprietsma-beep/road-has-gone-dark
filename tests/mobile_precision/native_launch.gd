extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME146_PHASE")
 if phase.is_empty():phase="mechanics"
 var paths := {"mechanics":"res://tests/mobile_precision/mechanics.gd","input":"res://tests/mobile_precision/input.gd","journey":"res://tests/mobile_precision/journey.gd","capture":"res://tests/mobile_precision/capture.gd","v19":"res://tests/class_signatures/mechanics_driver.gd","v18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd","audit":"res://tests/character_completeness/audit_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 var worker: Node=script.new()
 # Capture changes production scenes; keep the driver outside current_scene.
 get_tree().root.add_child(worker)
