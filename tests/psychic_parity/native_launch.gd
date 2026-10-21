extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME152_PHASE")
 var path: String={"baseline":"res://tests/psychic_parity/baseline.gd","mechanics":"res://tests/psychic_parity/mechanics.gd","input":"res://tests/psychic_parity/input.gd"}.get(phase,"res://tests/psychic_parity/mechanics.gd")
 var worker: GDScript=load(path)
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
