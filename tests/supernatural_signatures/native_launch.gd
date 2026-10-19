extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME148_PHASE")
 if phase.is_empty():phase="mechanics"
 var paths := {"mechanics":"res://tests/supernatural_signatures/mechanics.gd","input":"res://tests/supernatural_signatures/input.gd","journey":"res://tests/supernatural_signatures/journey.gd","connected":"res://tests/supernatural_signatures/connected.gd","capture":"res://tests/supernatural_signatures/capture.gd","current-signatures":"res://tests/supernatural_signatures/inherited_signatures.gd","current-mobile":"res://tests/supernatural_signatures/inherited_mobile.gd","v20":"res://tests/mobile_precision/mechanics.gd","v19":"res://tests/class_signatures/mechanics_driver.gd","v18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd","audit":"res://tests/character_completeness/audit_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(script.new())
