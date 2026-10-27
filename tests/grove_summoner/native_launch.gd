extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GROVE_SUMMONER_PHASE")
 var paths := {"probe":"res://tests/grove_summoner/probe.gd","mechanics":"res://tests/grove_summoner/mechanics.gd","input":"res://tests/grove_summoner/input.gd","journey":"res://tests/grove_summoner/journey.gd","connected":"res://tests/grove_summoner/connected.gd","capture":"res://tests/grove_summoner/capture.gd","historical32":"res://tests/ranger_steward/mechanics.gd","historical32-input":"res://tests/ranger_steward/input.gd","audit":"res://tests/character_completeness/audit_driver.gd","current-upper":"res://tests/grove_summoner/current_upper.gd","historical31":"res://tests/monk_paladin/mechanics.gd","historical31-input":"res://tests/monk_paladin/input.gd","historical30":"res://tests/martial_careers/mechanics.gd","historical30-extended":"res://tests/martial_careers/extended.gd","historical30-input":"res://tests/martial_careers/input.gd","historical29":"res://tests/dual_prestige_acceptance/mechanics.gd","historical18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
