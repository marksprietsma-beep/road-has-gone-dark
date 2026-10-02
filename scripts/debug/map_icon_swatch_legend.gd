class_name MapIconSwatchLegend
extends Control

var provider: MapIconProvider

func set_provider(value: MapIconProvider) -> void:
	provider = value
	queue_redraw()

func _draw() -> void:
	if not provider or provider.family == "Procedural":
		draw_string(ThemeDB.fallback_font, Vector2(8, 22), "Procedural baseline (no authored swatches)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d8c9a5"))
		return
	for index in MapIconProvider.ROLES.size():
		var column := index % 4
		var row := index / 4
		var origin := Vector2(8 + column * 82, 7 + row * 38)
		var texture := provider.texture_for(MapIconProvider.ROLES[index])
		if texture:
			draw_rect(Rect2(origin, Vector2(24, 24)), Color("#dfcfaa"))
			var size := _fit_size(texture.get_size(), Vector2(24, 24))
			draw_texture_rect(texture, Rect2(origin + Vector2(12, 0) - size * 0.5 + Vector2(0, 12), size), false)
		elif provider.is_declared_absent(MapIconProvider.ROLES[index]):
			draw_string(ThemeDB.fallback_font, origin + Vector2(0, 16), "N/A", HORIZONTAL_ALIGNMENT_LEFT, 24, 9, Color("#d8c9a5"))
		else:
			draw_rect(Rect2(origin, Vector2(24, 24)), Color("#a8493f"), false, 1.0)
		draw_string(ThemeDB.fallback_font, origin + Vector2(28, 16), MapIconProvider.ROLES[index], HORIZONTAL_ALIGNMENT_LEFT, 52, 9, Color("#d8c9a5"))

func _fit_size(source: Vector2, bounds: Vector2) -> Vector2:
	if source.x <= 0.0 or source.y <= 0.0:
		return bounds
	return source * minf(bounds.x / source.x, bounds.y / source.y)
