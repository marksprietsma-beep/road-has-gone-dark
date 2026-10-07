extends "res://tests/expedition/capture-flow.gd"

func _initialize() -> void:
 Engine.max_fps = 60
 output = "res://docs/implementation/game83/" + OS.get_environment("GAME83_STAGE") + "/expedition"
 super._initialize()
