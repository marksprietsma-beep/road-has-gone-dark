class_name ReliefMapLayer
extends MapLayer

## Draws provider-neutral, generated presentation data. Rivers, routes, borders,
## settlements and labels are later scene layers so these subdued marks cannot
## obscure map information.

func _draw() -> void:
	if not model or zoom_band == 0:
		return
	_draw_hachures()
	for icon in model.relief:
		if icon is Dictionary:
			_draw_icon(icon)

func _draw_hachures() -> void:
	for stroke in model.slope_hachures:
		if not stroke is Dictionary: continue
		var start := Vector2(float(stroke.get("x", 0)), float(stroke.get("y", 0)))
		var delta := Vector2(float(stroke.get("dx", 0)), float(stroke.get("dy", 0)))
		var strength := float(stroke.get("strength", 0.4))
		draw_line(start - delta * 0.5, start + delta * 0.5, Color("#493f32", 0.12 + strength * 0.16), 0.65, true)

func _draw_icon(icon: Dictionary) -> void:
	var kind := str(icon.get("kind", "hill"))
	# Vegetation remains deliberately quieter than terrain emphasis.
	if kind not in ["mount", "mountSnow", "hill"]:
		_draw_vegetation(icon, kind)
		return
	var center := Vector2(float(icon.get("x", 0)), float(icon.get("y", 0)))
	var size := clampf(float(icon.get("size", 4)), 3.0, 15.0)
	var half := size * 0.5
	var peak := center + Vector2(0, -half * 0.72)
	var left := center + Vector2(-half * 0.72, half * 0.55)
	var right := center + Vector2(half * 0.72, half * 0.55)
	var ink := Color("#40382e", 0.82 if kind != "hill" else 0.64)
	draw_colored_polygon(PackedVector2Array([left, peak, right]), Color("#746851", 0.38))
	draw_polyline(PackedVector2Array([left, peak, right]), ink, 0.9, true)
	draw_line(peak, center + Vector2(half * 0.17, half * 0.48), Color("#d4c59b", 0.48), 0.7, true)
	if kind == "mountSnow":
		draw_polyline(PackedVector2Array([peak + Vector2(-half * 0.2, half * 0.22), peak + Vector2.ZERO, peak + Vector2(half * 0.22, half * 0.24)]), Color("#e3d9ba", 0.8), 0.85, true)

func _draw_vegetation(icon: Dictionary, kind: String) -> void:
	var center := Vector2(float(icon.get("x", 0)), float(icon.get("y", 0)))
	var size := clampf(float(icon.get("size", 3)), 2.0, 8.0)
	var color := Color("#394638", 0.42)
	if kind in ["dune", "grass"]: color = Color("#746646", 0.34)
	draw_line(center, center + Vector2(0, size * 0.35), color, 0.7, true)
	draw_circle(center - Vector2(0, size * 0.12), size * 0.25, color)
