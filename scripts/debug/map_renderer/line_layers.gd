class_name LineMapLayer
extends MapLayer

enum Kind { RIVERS, ROUTES, BORDERS }
@export var kind := Kind.RIVERS
var border_texture: Texture2D

func set_package(package: Dictionary) -> void:
	border_texture = package.get("border_texture")
	queue_redraw()

func _draw() -> void:
	if not model: return
	match kind:
		Kind.RIVERS: _draw_rivers()
		Kind.ROUTES: _draw_routes()
		Kind.BORDERS: _draw_borders()

func _draw_rivers() -> void:
	for river in model.fixture.get("rivers", []):
		if not river is Dictionary: continue
		var line := PackedVector2Array()
		for raw_id in river.get("cells", []):
			var cell_id := int(raw_id)
			if not model.valid_cell(cell_id): continue
			var point := model.point(cell_id)
			var is_land := cell_id < model.heights.size() and float(model.heights[cell_id]) >= model.LAND_HEIGHT
			if is_land:
				line.append(point)
			elif not line.is_empty():
				# Stop at an approximate shoreline point instead of carrying the
				# river through the centre of an offshore water cell.
				line.append((line[line.size() - 1] + point) * 0.5)
				break
		if line.size() > 1:
			draw_polyline(line, Color("#283a3b", 0.86), clampf(float(river.get("width", 0.4)) * 2.0, 1.0, 2.8), true)
			draw_polyline(line, Color("#657a70", 0.72), clampf(float(river.get("width", 0.4)), 0.6, 1.5), true)

func _draw_routes() -> void:
	if zoom_band == 0: return
	for route in model.fixture.get("routes", []):
		if not route is Dictionary: continue
		var line := PackedVector2Array()
		for value in route.get("points", []):
			if value is Array and value.size() >= 2:
				line.append(Vector2(float(value[0]), float(value[1])))
		if line.size() <= 1: continue

		var group := str(route.get("group", "roads"))
		if group == "searoutes":
			# Sea lanes should be discoverable, not a bright dotted coastline.
			# Smaller, fainter, more widely spaced marks preserve navigation
			# cues while keeping the land and the waterways visually dominant.
			draw_polyline(line, Color("#aea07c", 0.16), 0.55, true)
			_draw_dotted_polyline(line, Color("#b8aa84", 0.40), 0.62, 13.0)
		else:
			# Roads and inland trade links: restrained dark ink and a fine
			# inner highlight so terrain and settlements remain the focus.
			draw_polyline(line, Color("#51483a", 0.48), 1.12, true)
			draw_polyline(line, Color("#ae9f7d", 0.30), 0.42, true)

func _draw_dotted_polyline(line: PackedVector2Array, color: Color, radius: float, spacing: float) -> void:
	var carry := 0.0
	for index in range(line.size() - 1):
		var start := line[index]
		var finish := line[index + 1]
		var delta := finish - start
		var length := delta.length()
		if length <= 0.001:
			continue
		var direction := delta / length
		var distance := spacing - carry
		while distance <= length:
			draw_circle(start + direction * distance, radius, color)
			distance += spacing
		carry = fmod(maxf(0.0, length - distance + spacing), spacing)

func _draw_borders() -> void:
	if not border_texture: return
	var zoom_alpha := 1.0 if zoom_band == 0 else (0.82 if zoom_band == 1 else 0.28)
	draw_texture_rect(border_texture, Rect2(Vector2.ZERO, Vector2(model.size)), false, Color(1.0, 1.0, 1.0, zoom_alpha))
