extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase: String=OS.get_environment("DRAGON_WARSHAPER_PHASE")
 var paths: Dictionary={"pins":"res://tests/dragon_warshaper/pins.gd","probe":"res://tests/dragon_warshaper/probe.gd","mechanics":"res://tests/dragon_warshaper/mechanics.gd","input":"res://tests/dragon_warshaper/input.gd","journey":"res://tests/dragon_warshaper/journey.gd","connected":"res://tests/dragon_warshaper/connected.gd","capture":"res://tests/dragon_warshaper/capture.gd","sentinel-probe":"res://tests/sentinel_turn/probe.gd","sentinel-campaign":"res://tests/sentinel_turn/campaign.gd","audit":"res://tests/character_completeness/audit_driver.gd","current-upper":"res://tests/dragon_warshaper/current_upper.gd","historical33":"res://tests/grove_summoner/mechanics.gd","historical33-input":"res://tests/grove_summoner/input.gd","historical32":"res://tests/ranger_steward/mechanics.gd","historical32-input":"res://tests/ranger_steward/input.gd","historical31":"res://tests/monk_paladin/mechanics.gd","historical31-input":"res://tests/monk_paladin/input.gd","historical30":"res://tests/martial_careers/mechanics.gd","historical30-extended":"res://tests/martial_careers/extended.gd","historical30-input":"res://tests/martial_careers/input.gd","historical29":"res://tests/dual_prestige_acceptance/mechanics.gd","historical18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
