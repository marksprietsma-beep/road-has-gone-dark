extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("UPPER_NATURE_PHASE")
 var paths := {"mechanics":"res://tests/upper_nature/mechanics.gd","input":"res://tests/upper_nature/input.gd","journey":"res://tests/upper_nature/journey.gd","connected":"res://tests/upper_nature/connected.gd","capture":"res://tests/upper_nature/capture.gd","audit":"res://tests/character_completeness/audit_driver.gd","current-upper":"res://tests/upper_nature/current_upper.gd","historical26":"res://tests/psychic_paths/mechanics.gd","historical18":"res://tests/nature_repertoires/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
