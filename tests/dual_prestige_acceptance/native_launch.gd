extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("DUAL_PHASE")
 var paths := {"interactions":"res://tests/dual_prestige_acceptance/champion_interactions.gd","probe":"res://tests/dual_prestige_acceptance/probe.gd","mechanics":"res://tests/dual_prestige_acceptance/mechanics.gd","input":"res://tests/dual_prestige_acceptance/input.gd","journey":"res://tests/dual_prestige_acceptance/journey.gd","entry":"res://tests/dual_prestige_acceptance/entry.gd","connected-a":"res://tests/dual_prestige_acceptance/connected.gd","connected-b":"res://tests/dual_prestige_acceptance/connected.gd","capture":"res://tests/dual_prestige_acceptance/capture.gd","audit":"res://tests/character_completeness/audit_driver.gd","current-upper":"res://tests/dual_prestige_acceptance/current_upper.gd","historical28":"res://tests/hybrid_acceptance/current_upper.gd","historical18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
