class_name AtlasFrameMapLayer
extends MapLayer

func _draw() -> void:
	if not model: return
	var bounds := Rect2(Vector2.ZERO, Vector2(model.size))
	draw_rect(bounds, Color("#1b1713"), false, 8.0)
	draw_rect(bounds.grow(-7.0), Color("#9d8558", 0.72), false, 2.0)
	# Simple cartographer's compass: ornamental, unobtrusive, and deterministic.
	var p := Vector2(model.size.x - 46, model.size.y - 48)
	draw_circle(p, 17.0, Color("#1c1915", 0.24))
	draw_arc(p, 17.0, 0.0, TAU, 32, Color("#bba777", 0.66), 1.0)
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_line(p, p + direction * 14.0, Color("#d0bc88", 0.72), 1.2)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -22), p + Vector2(-4, -8), p + Vector2(4, -8)]), Color("#d1b779", 0.86))
