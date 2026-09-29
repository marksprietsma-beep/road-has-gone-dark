class_name LandmarkMapLayer
extends MapLayer

func _draw() -> void:
	if not model or zoom_band == 0: return
	for marker in model.fixture.get("markers", []):
		if not marker is Dictionary: continue
		var kind := str(marker.get("type", ""))
		if zoom_band == 1 and kind not in ["volcanoes", "ruins", "battlefields", "lighthouses"]: continue
		var p := Vector2(float(marker.get("x", 0.0)), float(marker.get("y", 0.0)))
		_draw_marker(p, kind)

func _draw_marker(p: Vector2, kind: String) -> void:
	var ink := Color("#2a1e1b", 0.94)
	var accent := Color("#b68154", 0.9)
	if kind == "volcanoes":
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 3), p + Vector2(0, -5), p + Vector2(4, 3)]), ink)
		draw_circle(p + Vector2(0, -2), 1.2, Color("#a24e38"))
	elif kind in ["ruins", "battlefields"]:
		draw_line(p + Vector2(-3, -3), p + Vector2(3, 3), ink, 1.5)
		draw_line(p + Vector2(3, -3), p + Vector2(-3, 3), ink, 1.5)
	else:
		draw_circle(p, 3.0, Color("#201a17"))
		draw_circle(p, 1.6, accent)
