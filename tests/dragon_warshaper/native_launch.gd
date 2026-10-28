extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase: String=OS.get_environment("DRAGON_WARSHAPER_PHASE")
 var paths: Dictionary={"probe":"res://tests/dragon_warshaper/probe.gd","mechanics":"res://tests/dragon_warshaper/mechanics.gd"}
 if not paths.has(phase):get_tree().quit(1);return
 var worker: GDScript=load(paths[phase])
 if worker==null or not worker.can_instantiate():get_tree().quit(1);return
 get_tree().root.add_child(worker.new())
