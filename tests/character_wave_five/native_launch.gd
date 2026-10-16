extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 for name in ["mechanics_driver","earned_driver"]:
  var worker: Node=load("res://tests/character_wave_five/"+name+".gd").new()
  worker.no_quit=true;add_child(worker);await worker.completed
  if worker.failures>0:get_tree().quit(1);return
  worker.queue_free()
 get_tree().quit(0)
