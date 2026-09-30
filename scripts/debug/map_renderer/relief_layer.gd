class_name ReliefMapLayer
extends MapLayer

func _draw() -> void:
	if not model: return
	# Join neighbouring high cells first so elevation reads as a continuous
	# range at world scale instead of a field of unrelated glyphs.
	for cell_id in model.points.size():
		if not _is_ridge(cell_id): continue
		for raw_neighbor in model.neighbors[cell_id]:
			var neighbor := int(raw_neighbor)
			if neighbor <= cell_id or not _is_ridge(neighbor): continue
			var a := model.point(cell_id)
			var b := model.point(neighbor)
			if a.distance_to(b) > 25.0: continue
			draw_line(a + Vector2(0, 1.5), b + Vector2(0, 1.5), Color("#332d27", 0.28), 4.0, true)
			draw_line(a, b, Color("#665c4b", 0.68), 1.4, true)
	if zoom_band == 0: return
	for cell_id in model.points.size():
		if not _is_ridge(cell_id): continue
		var height := float(model.heights[cell_id])
		if posmod(cell_id * 37, 13) > 1: continue
		var p := model.point(cell_id)
		var size := clampf((height - 42.0) / 24.0, 2.0, 4.5)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-size, 2), p + Vector2(0, -size), p + Vector2(size, 2)]), Color("#51483b", 0.72))
		draw_line(p + Vector2(0, -size), p + Vector2(size, 2), Color("#b2a37e", 0.38), 0.7)

func _is_ridge(cell_id: int) -> bool:
	return model.valid_cell(cell_id) and cell_id < model.heights.size() and cell_id < model.neighbors.size() and float(model.heights[cell_id]) >= 52.0
