extends Node2D

## GAME-47: developer-only view of Azgaar-authoritative neighbourhoods.
## Source roads, burgs, coastlines and lakes CANNOT be replaced by the
## separately labelled Town Forge illustrative vegetation. No save writes.
const CASES := [
 "constrained-game-11-determinism-shore",
 "constrained-game-11-determinism-river",
 "constrained-game-11-determinism-highland",
 "constrained-atlas-showcase-shore",
 "constrained-atlas-showcase-river",
 "constrained-atlas-showcase-highland"
]
const SAMPLE_FOLDER := "res://tools/regiongen/.tmp/"
const INK := Color("#3b352c")
const LAND := Color("#d1c19c")
const SEA := Color("#8babb2")
var region: Dictionary = {}
var selected_source_id: int = -1
var show_decorations: bool = true
@onready var camera: Camera2D = $Camera2D
@onready var info: Label = $HUD/Help

func _ready() -> void:
	fit_map()
	load_region(SAMPLE_FOLDER + CASES[0] + ".json")

func fit_map() -> void:
	camera.position = Vector2(500.0, 500.0)
	var size: Vector2 = get_viewport_rect().size
	var zoom_factor: float = clampf(minf(size.x / 1100.0, (size.y - 145.0) / 1100.0), 0.15, 1.8)
	camera.zoom = Vector2(zoom_factor, zoom_factor)

func _base_info() -> String:
	var context: Dictionary = region.get("source_context", {})
	var sites: Array = context.get("source_burgs", [])
	var home_id: int = int(context.get("source_home_burg_id", -1))
	var name: String = "?"
	for s in sites:
		if s is Dictionary and int(s.get("source_id", -1)) == home_id:
			name = str(s.get("name", "?"))
	return "SOURCE REGION | %s | World geometry by Azgaar; trees by Town Forge\n1–6: examples  F: fit  V: toggle decorative trees  ARROWS: pan  WHEEL: zoom  CLICK: burg\nRoutes not verified safe • River paths approximate • Kilometres uncalibrated" % name

func load_region(path: String) -> bool:
	region.clear()
	selected_source_id = -1
	queue_redraw()
	if not FileAccess.file_exists(path):
		info.text = "GAME-47 | Generate maps first: source-local-context CI or generate-constrained-examples.mjs"
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		info.text = "GAME-47 | Unable to read constrained region JSON"
		return false
	var parsed := JSON.new()
	var status: Error = parsed.parse(file.get_as_text())
	file.close()
	if status != OK or not parsed.data is Dictionary:
		info.text = "GAME-47 | Malformed constrained region"
		return false
	var data: Dictionary = parsed.data
	var ctx: Dictionary = data.get("source_context", {})
	var meta: Dictionary = data.get("provider", {})
	var mask: Dictionary = data.get("constraints", {})
	if int(data.get("schema_version", -1)) != 1 or str(meta.get("mode", "")) != "DECORATIONS_ONLY":
		info.text = "GAME-47 | Wrong composite provider"
		return false
	if str(ctx.get("parent_source_world_sha256", "")) == "" or str(mask.get("source_water_mask", "")) != "AZGAAR_LAND_MINUS_LAKES":
		info.text = "GAME-47 | Missing authoritative geography constraint"
		return false
	if ctx.get("source_features", []).is_empty() or ctx.get("source_burgs", []).is_empty():
		info.text = "GAME-47 | Empty authoritative world geometry"
		return false
	region = data
	info.text = _base_info()
	queue_redraw()
	return true

func _process(delta: float) -> void:
	var travel: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if travel.length_squared() > 0.0:
		camera.position += travel * 370.0 * delta / maxf(camera.zoom.x, 0.1)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			fit_map()
		elif event.keycode == KEY_V:
			show_decorations = not show_decorations
			queue_redraw()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			load_region(SAMPLE_FOLDER + CASES[event.keycode - KEY_1] + ".json")
			fit_map()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			select_burg_at(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.15).clamp(Vector2(0.15, 0.15), Vector2(1.8, 1.8))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom / 1.15).clamp(Vector2(0.15, 0.15), Vector2(1.8, 1.8))

func select_burg_at(point: Vector2) -> bool:
	var nearest: Dictionary = {}
	var best: float = 25.0
	var ctx: Dictionary = region.get("source_context", {})
	for value in ctx.get("source_burgs", []):
		if not value is Dictionary:
			continue
		var site: Dictionary = value
		var position: Vector2 = _point(site.get("local_position", []))
		var distance: float = point.distance_to(position)
		if distance <= best:
			nearest = site
			best = distance
	if nearest.is_empty():
		selected_source_id = -1
		info.text = _base_info() if not region.is_empty() else "GAME-47 | No region"
		queue_redraw()
		return false
	selected_source_id = int(nearest.get("source_id", -1))
	info.text = _base_info() + "\nSOURCE BURG | %s | ID %d | cell %d | coordinates %s" % [
		str(nearest.get("name", "")), selected_source_id,
		int(nearest.get("source_cell_id", -1)), str(nearest.get("world_position", []))]
	queue_redraw()
	return true

func _point(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO

func _poly(value: Variant) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not value is Array:
		return result
	for p in value:
		if p is Array and p.size() >= 2:
			result.append(_point(p))
	return result

func _dash(a: Vector2, b: Vector2, colour: Color, width: float, dash: float = 9.0, gap: float = 7.0) -> void:
	var length: float = a.distance_to(b)
	if length <= 0.001:
		return
	var direction: Vector2 = (b - a).normalized()
	var step: float = 0.0
	while step < length:
		draw_line(a + direction * step, a + direction * minf(step + dash, length), colour, width, true)
		step += dash + gap

# Display-only dry-land mask for original macro Azgaar roads/trails.
# Source route coordinates still exist unchanged in the region JSON. A source
# wet crossing is not evidence for a safe ford or bridge.
func _source_point_is_dry(p: Vector2, features: Array) -> bool:
	var land: bool = false
	for value in features:
		if not value is Dictionary:
			continue
		var feature: Dictionary = value
		if str(feature.get("classification", "")) == "land_boundary":
			var ring: PackedVector2Array = _poly(feature.get("local_polygon", []))
			if ring.size() >= 3 and Geometry2D.is_point_in_polygon(p, ring):
				land = true
	if not land:
		return false
	for value in features:
		if not value is Dictionary:
			continue
		var feature: Dictionary = value
		if str(feature.get("classification", "")) == "freshwater_lake":
			var lake: PackedVector2Array = _poly(feature.get("local_polygon", []))
			if lake.size() >= 3 and Geometry2D.is_point_in_polygon(p, lake):
				return false
	return true

func _draw_dry_source_route(points: PackedVector2Array, features: Array, route_class: String) -> void:
	if points.size() < 2:
		return
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var length: float = a.distance_to(b)
		if length < 0.01:
			continue
		var parts: int = maxi(1, int(ceilf(length / 3.0)))
		for k in range(parts):
			var from_point: Vector2 = a.lerp(b, float(k) / parts)
			var to_point: Vector2 = a.lerp(b, float(k + 1) / parts)
			if not _source_point_is_dry((from_point + to_point) * 0.5, features):
				continue
			draw_line(from_point, to_point, Color("#5c503a"),
				3.0 if route_class == "trail" else 5.0, true)
			if route_class == "land_road":
				draw_line(from_point, to_point, Color("#cbb98b"), 2.0, true)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1000, 1000), SEA)
	if region.is_empty():
		return
	var ctx: Dictionary = region.get("source_context", {})
	var terrain: Dictionary = region.get("landscape", {})
	var features: Array = ctx.get("source_features", [])
	# Render original Azgaar *sea* lanes beneath genuine source land/lake
	# polygons, masking the parts which cross land at coarse source resolution.
	# Original source route records are retained in the input for audit.
	for route_value in ctx.get("source_routes", []):
		if not route_value is Dictionary:
			continue
		var sea_route: Dictionary = route_value
		if str(sea_route.get("classification", "")) != "sea_lane":
			continue
		for segment in sea_route.get("segments", []):
			var sea_line: PackedVector2Array = _poly(segment.get("local_points", []))
			if sea_line.size() >= 2:
				_dash(sea_line[0], sea_line[1], Color("#4b8392"), 3.0)
	# Land/ocean/lakes are from original Azgaar indexed source vertices.
	for feature in features:
		if not feature is Dictionary or str(feature.get("classification", "")) != "land_boundary":
			continue
		var vertices: PackedVector2Array = _poly(feature.get("local_polygon", []))
		if vertices.size() >= 3:
			draw_colored_polygon(vertices, LAND)
	for feature in features:
		if not feature is Dictionary or str(feature.get("classification", "")) != "freshwater_lake":
			continue
		var vertices: PackedVector2Array = _poly(feature.get("local_polygon", []))
		if vertices.size() >= 3:
			draw_colored_polygon(vertices, Color("#87b0b9"))
	# Godot never takes any road or water from Town Forge provider geometry.
	if show_decorations:
		for value in terrain.get("ridges", []):
			if not value is Dictionary:
				continue
			var p: Vector2 = Vector2(float(value.get("x", 0)), float(value.get("y", 0)))
			draw_polyline(PackedVector2Array([p + Vector2(-12, 7), p + Vector2(0, -9), p + Vector2(12, 7)]), Color("#857556", 0.55), 1.6, true)
		for value in terrain.get("trees", []):
			if not value is Dictionary:
				continue
			var p: Vector2 = Vector2(float(value.get("x", 0)), float(value.get("y", 0)))
			var s: float = float(value.get("size", 7.0))
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(-s * 0.65, s * 0.5), p + Vector2(0, -s * 0.9),
				p + Vector2(s * 0.65, s * 0.5)]), Color("#4a6550"))
			draw_line(p + Vector2(0, s * 0.4), p + Vector2(0, s * 1.1), Color("#2c4337"), 1.0)
	for river in ctx.get("source_rivers", []):
		if not river is Dictionary:
			continue
		for segment in river.get("segments", []):
			var line: PackedVector2Array = _poly(segment.get("local_points", []))
			if line.size() >= 2:
				_dash(line[0], line[1], Color("#4e8498"), 3.0, 6.0, 4.0)
	for route in ctx.get("source_routes", []):
		if not route is Dictionary:
			continue
		var cls: String = str(route.get("classification", ""))
		for segment in route.get("segments", []):
			var line: PackedVector2Array = _poly(segment.get("local_points", []))
			if line.size() < 2:
				continue
			if cls != "land_road" and cls != "trail":
				continue # Sea lanes handled separately; unknown is not a road
			_draw_dry_source_route(line, features, cls)
	var font: Font = ThemeDB.fallback_font
	for item in ctx.get("source_burgs", []):
		if not item is Dictionary:
			continue
		var site: Dictionary = item
		var p: Vector2 = _point(site.get("local_position", []))
		var site_id: int = int(site.get("source_id", -1))
		var is_home: bool = site_id == int(ctx.get("source_home_burg_id", -1))
		var radius: float = 12.0 if is_home else 7.0
		draw_circle(p, radius, Color("#efe1bd"))
		draw_arc(p, radius, 0.0, TAU, 32, Color("#382e25"), 2.0)
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-radius * .6, radius * .5),
			p + Vector2(-radius * .6, -radius * .35),
			p + Vector2(0, -radius),
			p + Vector2(radius * .6, -radius * .35),
			p + Vector2(radius * .6, radius * .5)]),
			Color("#9b5644") if is_home else Color("#806953"))
		if is_home or site_id == selected_source_id:
			var name: String = str(site.get("name", ""))
			var text_size: int = 18 if is_home else 14
			var width: float = maxf(80.0, minf(200.0, name.length() * 11.0))
			var label_position: Vector2 = Vector2(clampf(p.x + 18.0, 5.0, 1000.0 - width), clampf(p.y - 14.0, 95.0, 930.0))
			draw_rect(Rect2(label_position - Vector2(4, 18), Vector2(width, 25)), Color("#efe1be", 0.94))
			draw_string(font, label_position, name, HORIZONTAL_ALIGNMENT_LEFT, width - 8.0, text_size, INK)
	draw_rect(Rect2(0, 0, 1000, 1000), INK, false, 1.5)
