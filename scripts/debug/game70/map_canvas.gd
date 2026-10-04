extends Node2D
var controller: Node
func _unhandled_input(event: InputEvent) -> void:
	if controller != null:
		controller.handle_map_input(event)
