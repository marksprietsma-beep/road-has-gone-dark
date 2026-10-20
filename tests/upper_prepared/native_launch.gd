extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME150_PHASE")
 if phase.is_empty():phase="mechanics"
 var paths := {"mechanics":"res://tests/upper_prepared/mechanics.gd","input":"res://tests/upper_prepared/input.gd","journey":"res://tests/upper_prepared/journey.gd","connected":"res://tests/upper_prepared/connected.gd","capture":"res://tests/upper_prepared/capture.gd","current-performance":"res://tests/upper_prepared/inherited_performance.gd","current-performance-input":"res://tests/performance_spirit/input.gd","v22":"res://tests/performance_spirit/mechanics.gd","current-supernatural":"res://tests/upper_prepared/inherited_supernatural.gd","current-signatures":"res://tests/upper_prepared/inherited_signatures.gd","current-mobile":"res://tests/upper_prepared/inherited_mobile.gd","v21":"res://tests/supernatural_signatures/mechanics.gd","v20":"res://tests/mobile_precision/mechanics.gd","v19":"res://tests/class_signatures/mechanics_driver.gd","v18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd","audit":"res://tests/character_completeness/audit_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(script.new())
