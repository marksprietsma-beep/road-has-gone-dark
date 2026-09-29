class_name PoliticalMapLayer
extends MapLayer

func _draw() -> void:
	if not model: return
	for cell_id in model.points.size():
		if cell_id >= model.states.size() or cell_id >= model.heights.size(): continue
		var state_id := int(model.states[cell_id])
		if state_id <= 0 or float(model.heights[cell_id]) < model.LAND_HEIGHT: continue
		var record: Dictionary = model.state_records.get(state_id, {})
		var color := Color(str(record.get("color", "#ffffff")), 0.18)
		draw_circle(model.point(cell_id), 8.0, color)
