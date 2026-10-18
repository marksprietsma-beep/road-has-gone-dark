extends Node
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 var script: GDScript=load("res://tests/class_signatures/mechanics_driver.gd")
 if script==null or not script.can_instantiate():get_tree().quit(1);return
 var worker: Node=script.new();worker.no_quit=true;add_child(worker);await worker.completed
 get_tree().quit(1 if worker.failures else 0)
