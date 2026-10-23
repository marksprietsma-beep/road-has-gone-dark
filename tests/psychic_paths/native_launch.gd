extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME127_PATH_PHASE")
 var paths := {"mechanics":"res://tests/psychic_paths/mechanics.gd","input":"res://tests/psychic_paths/input.gd","journey":"res://tests/psychic_paths/journey.gd","connected":"res://tests/psychic_paths/connected.gd","capture":"res://tests/psychic_paths/capture.gd","current-support":"res://tests/psychic_support/mechanics.gd","current-support-input":"res://tests/psychic_support/input.gd","legacy":"res://tests/character_completeness/repair_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
