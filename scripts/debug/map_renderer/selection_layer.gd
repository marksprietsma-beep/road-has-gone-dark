class_name SelectionMapLayer
extends MapLayer
var selected_cell := -1
func select_cell(cell_id: int) -> void:
	selected_cell = cell_id
	queue_redraw()
func _draw() -> void:
	if model and model.valid_cell(selected_cell):
		draw_circle(model.point(selected_cell), 9.0, Color("#ffe49a", 0.16))
		draw_arc(model.point(selected_cell), 9.0, 0, TAU, 16, Color("#ffe49a"), 1.5, false)
