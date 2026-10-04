extends "res://scripts/debug/local_region_v1.gd"

## Accepted GAME-62 drawing, driven by the proof's shared camera and public data.
func _ready() -> void:
	$Camera2D.enabled = false
	$HUD.hide()

func _unhandled_input(_event: InputEvent) -> void:
	pass # The flow owns navigation/input; no stock-sample/developer shortcuts.

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
