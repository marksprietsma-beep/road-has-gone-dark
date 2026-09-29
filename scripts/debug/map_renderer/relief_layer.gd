class_name ReliefMapLayer
extends MapLayer

func _draw() -> void:
	if not model or zoom_band == 0: return
	for cell_id in model.points.size():
		if cell_id >= model.heights.size(): continue
		var height := float(model.heights[cell_id])
		if height < 48.0 or posmod(cell_id * 37, 11) > 2: continue
		var p := model.point(cell_id)
		var size := clampf((height - 38.0) / 22.0, 2.0, 6.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-size, 2), p + Vector2(0, -size), p + Vector2(size, 2)]), Color("#584d3d", 0.62))
		draw_line(p + Vector2(0, -size), p + Vector2(size, 2), Color("#d8c89b", 0.52), 0.8)
