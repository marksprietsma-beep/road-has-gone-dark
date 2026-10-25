extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("MARTIAL_PHASE")
 var paths := {"probe":"res://tests/martial_careers/probe.gd","mechanics":"res://tests/martial_careers/mechanics.gd","input":"res://tests/martial_careers/input.gd","journey":"res://tests/martial_careers/journey.gd","connected":"res://tests/martial_careers/connected.gd","capture":"res://tests/martial_careers/capture.gd","extended":"res://tests/martial_careers/extended.gd","audit":"res://tests/character_completeness/audit_driver.gd","current-upper":"res://tests/martial_careers/current_upper.gd","historical29":"res://tests/dual_prestige_acceptance/mechanics.gd","historical18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
