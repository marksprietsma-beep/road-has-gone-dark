extends SceneTree
func _initialize() -> void:
 for folder in ["spell_repertoires","nature_repertoires","class_signatures"]:
  var script: GDScript=load("res://tests/"+folder+"/input_driver.gd")
  if script==null or not script.can_instantiate():quit(1);return
 print("HISTORICAL_INPUT_DRIVERS_COMPILE");quit(0)
