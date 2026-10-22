extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME127_PHASE")
 var paths: Dictionary={"baseline":"res://tests/psychic_identities/baseline.gd","mechanics":"res://tests/psychic_identities/mechanics.gd","input":"res://tests/psychic_identities/input.gd","journey":"res://tests/psychic_identities/journey.gd","connected":"res://tests/psychic_identities/connected.gd","capture":"res://tests/psychic_identities/capture.gd","current-upper":"res://tests/psychic_identities/current_upper.gd","current-upper-input":"res://tests/upper_prepared/input.gd","current-performance":"res://tests/psychic_identities/current_performance.gd","current-performance-input":"res://tests/performance_spirit/input.gd","current-supernatural":"res://tests/psychic_identities/current_supernatural.gd","current-signatures":"res://tests/psychic_identities/current_signatures.gd","current-mobile":"res://tests/psychic_identities/current_mobile.gd","current-psychic":"res://tests/psychic_identities/current_psychic.gd","historical24":"res://tests/psychic_parity/mechanics.gd","historical24-input":"res://tests/psychic_parity/input.gd","historical23":"res://tests/upper_prepared/mechanics.gd","historical13":"res://tests/character_psychic/mechanics_driver.gd","legacy":"res://tests/character_completeness/repair_driver.gd","compatibility":"res://tests/character_completeness/compatibility_driver.gd","audit":"res://tests/character_completeness/audit_driver.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var path: String=paths[phase]
 var worker: GDScript=load(path)
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
