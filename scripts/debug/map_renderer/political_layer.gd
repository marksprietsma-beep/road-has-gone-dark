class_name PoliticalMapLayer
extends MapLayer

func _draw() -> void:
	if not model: return
	# Ownership is a whisper of old map wash, not the map's base colour.
	for cell_id in model.points.size():
		if cell_id >= model.states.size() or cell_id >= model.heights.size(): continue
		var state_id := int(model.states[cell_id])
		if state_id <= 0 or float(model.heights[cell_id]) < model.LAND_HEIGHT: continue
		var record: Dictionary = model.state_records.get(state_id, {})
		var source := Color(str(record.get("color", "#8c7a65")))
		var color := source.lerp(Color("#766854"), 0.72)
		color.a = 0.035
		draw_circle(model.point(cell_id), 9.5, color)
