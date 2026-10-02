class_name LandmarkMapLayer
extends MapLayer

const ROLE_BY_TYPE := {"ruins": "ruins", "caves": "cave", "lighthouses": "lighthouse", "mines": "mine"}
var icon_provider: MapIconProvider

func set_icon_provider(value: MapIconProvider) -> void:
	icon_provider = value
	queue_redraw()

func _draw() -> void:
	if not model or zoom_band == 0:
		return

	for marker in model.fixture.get("markers", []):
		if not marker is Dictionary:
			continue
		var kind := str(marker.get("type", ""))
		if zoom_band == 1 and kind not in ["volcanoes", "ruins", "battlefields", "lighthouses"]:
			continue
		var p := Vector2(float(marker.get("x", 0.0)), float(marker.get("y", 0.0)))
		var role := str(ROLE_BY_TYPE.get(kind, ""))
		var texture := icon_provider.texture_for(role) if icon_provider and not role.is_empty() else null
		if texture:
			var source := texture.get_size()
			var size := source * (7.0 / maxf(source.x, source.y))
			draw_texture_rect(texture, Rect2(p - size * 0.5, size), false)
			continue
		if icon_provider and icon_provider.family != "Procedural" and not role.is_empty():
			draw_line(p + Vector2(-2, -2), p + Vector2(2, 2), Color("#a8493f"), 1.0)
			draw_line(p + Vector2(2, -2), p + Vector2(-2, 2), Color("#a8493f"), 1.0)
			continue
		_draw_marker(p, kind)

func _draw_marker(p: Vector2, kind: String) -> void:
	var ink := Color("#2b231f", 0.9)
	var accent := Color("#b68154", 0.82)

	if kind == "volcanoes":
		_draw_volcano(p)
	elif kind in ["ruins", "battlefields"]:
		draw_line(p + Vector2(-3, -3), p + Vector2(3, 3), ink, 1.35)
		draw_line(p + Vector2(3, -3), p + Vector2(-3, 3), ink, 1.35)
	else:
		draw_circle(p, 2.5, Color("#201a17", 0.88))
		draw_circle(p, 1.25, accent)

func _draw_volcano(p: Vector2) -> void:
	# Atlas-style volcanic cone: readable as a landform rather than a warning icon.
	var scale := 0.82 if zoom_band == 1 else 1.0
	var peak := p + Vector2(0.0, -5.2 * scale)
	var left := p + Vector2(-5.0 * scale, 3.2 * scale)
	var right := p + Vector2(5.0 * scale, 3.2 * scale)
	var crater_left := p + Vector2(-1.25 * scale, -3.6 * scale)
	var crater_right := p + Vector2(1.25 * scale, -3.6 * scale)

	var cone := PackedVector2Array([left, crater_left, peak, crater_right, right])
	draw_colored_polygon(cone, Color("#6f5848", 0.48))
	draw_polyline(cone, Color("#2b231f", 0.92), maxf(1.0, 1.35 * scale), true)

	# Crater and restrained ember accent.
	draw_line(crater_left, crater_right, Color("#241d1a", 0.9), maxf(0.9, 1.15 * scale))
	draw_circle(p + Vector2(0.0, -3.55 * scale), 0.85 * scale, Color("#9e503c", 0.78))

	# Two faint smoke curls. They make volcanoes distinct without looking like UI alerts.
	var smoke := Color("#5a5048", 0.46)
	draw_arc(p + Vector2(1.4 * scale, -7.0 * scale), 2.0 * scale, 0.15 * PI, 1.15 * PI, 10, smoke, maxf(0.75, 0.9 * scale))
	draw_arc(p + Vector2(-0.3 * scale, -10.0 * scale), 1.7 * scale, 0.05 * PI, 1.05 * PI, 10, smoke, maxf(0.65, 0.8 * scale))
