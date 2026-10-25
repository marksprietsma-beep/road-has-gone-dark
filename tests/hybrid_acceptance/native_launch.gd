extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("HYBRID_PHASE")
 var paths := {"entry":"res://tests/hybrid_acceptance/native_entry.gd","earned_probe":"res://tests/hybrid_acceptance/earned_probe.gd","probe":"res://tests/hybrid_acceptance/probe.gd","mechanics":"res://tests/hybrid_acceptance/mechanics.gd","input":"res://tests/hybrid_acceptance/input.gd","journey":"res://tests/hybrid_acceptance/native_progress.gd","connected":"res://tests/hybrid_acceptance/native_connected.gd","capture":"res://tests/hybrid_acceptance/capture.gd","audit":"res://tests/character_completeness/audit_driver.gd","current-upper":"res://tests/hybrid_acceptance/current_upper.gd","historical27":"res://tests/upper_nature/mechanics.gd","historical18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
