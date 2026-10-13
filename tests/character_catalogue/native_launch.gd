extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 if OS.get_environment("GAME112_RESTART")!="1":
  for script in ["mechanics_driver","tactical_driver"]:
   var worker: Node=load("res://tests/character_catalogue/"+script+".gd").new();worker.no_quit=true
   add_child(worker);await worker.completed
   if worker.failures>0:get_tree().quit(1);return
   worker.queue_free()
 get_tree().root.call_deferred("add_child",load("res://tests/character_catalogue/fresh_driver.gd").new())
