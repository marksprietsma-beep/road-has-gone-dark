extends Node
## Isolated exported diagnostic delegates to the same production UI drivers.
func _ready() -> void:
 get_tree().current_scene=null
 var driver := Node.new()
 driver.set_script(load("res://tests/geography_repair/recovery-ui.gd" if OS.get_environment("GAME99_RECOVERY_UI")=="1" else ("res://tests/adventure/review-flow.gd" if OS.get_environment("GAME96_REVIEW")=="legacy" else "res://tests/sandbox/review-flow.gd")))
 add_child(driver)
