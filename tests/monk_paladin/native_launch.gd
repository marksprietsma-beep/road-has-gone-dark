extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("MONK_PALADIN_PHASE")
 var paths := {"probe":"res://tests/monk_paladin/probe.gd","mechanics":"res://tests/monk_paladin/mechanics.gd","input":"res://tests/monk_paladin/input.gd","journey":"res://tests/monk_paladin/journey.gd","connected":"res://tests/monk_paladin/connected.gd","capture":"res://tests/monk_paladin/capture.gd","audit":"res://tests/character_completeness/audit_driver.gd","current-upper":"res://tests/monk_paladin/current_upper.gd","historical30":"res://tests/martial_careers/mechanics.gd","historical30-extended":"res://tests/martial_careers/extended.gd","historical30-input":"res://tests/martial_careers/input.gd","historical29":"res://tests/dual_prestige_acceptance/mechanics.gd","historical18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var script: GDScript=load(paths[phase])
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(script.new())
