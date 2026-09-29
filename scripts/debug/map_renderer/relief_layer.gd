class_name ReliefMapLayer
extends MapLayer

func _draw() -> void:
	if not model or zoom_band == 0: return
	for cell_id in model.points.size():
		if cell_id >= model.heights.size(): continue
		var height := float(model.heights[cell_id])
		if height < 44.0 or posmod(cell_id * 37, 11) > 3: continue
		var p := model.point(cell_id)
		var size := clampf((height - 38.0) / 22.0, 2.0, 6.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-size, 2), p + Vector2(0, -size), p + Vector2(size, 2)]), Color("#40382f", 0.68))
		draw_line(p + Vector2(0, -size), p + Vector2(size, 2), Color("#d2bd89", 0.58), 0.8)
		if height > 67.0: draw_line(p + Vector2(-size * 0.35, -size * 0.25), p + Vector2(0, -size), Color("#ded4b1", 0.62), 0.7)
