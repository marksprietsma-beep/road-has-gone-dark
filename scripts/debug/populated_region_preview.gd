extends "res://scripts/debug/local_region_preview.gd"

## GAME-40 developer-only populated preview. The underlying source-backed
## regional JSON, not this Node2D renderer, is the immutable data contract.
const POPULATED_CASES := [
	"first", "coast", "river", "mountain", "estuary", "second-world"
]
var reveal_hidden := false
var selected_id := ""
var selected_description := ""
const ICON_REGISTRY_PATH := "res://assets/map/region-site-icons.json"
var icon_registry: Dictionary = {}

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ICON_REGISTRY_PATH))
	if parsed is Dictionary and int(parsed.get("schema_version", -1)) == 1:
		icon_registry = parsed
	camera.position = Vector2(500, 500)
	fit_region()
	load_region("res://tools/regiongen/.tmp/populated-first.json")

func load_region(path: String) -> bool:
	selected_id = ""
	selected_description = ""
	if not super.load_region(path):
		return false
	var layer: Dictionary = region.get("local_sites", {})
	if int(layer.get("schema_version", -1)) != 1 or layer.get("region_id", "") != region.get("id", ""):
		region.clear()
		info.text = "GAME-40 | Missing or mismatched local site layer: generate previews first"
		queue_redraw()
		return false
	_update_description()
	return true

func _visible(site: Dictionary) -> bool:
	if reveal_hidden:
		return true
	return str(site.get("knowledge", "")) in ["discovered", "visited"]

func _update_description() -> void:
	if region.is_empty():
		return
	var area: Dictionary = region.get("region", {})
	var layer: Dictionary = region.get("local_sites", {})
	var all_sites: Array = layer.get("sites", [])
	var shown := 0
	var rumours := 0
	for value in all_sites:
		if not value is Dictionary:
			continue
		if _visible(value):
			shown += 1
		elif str(value.get("knowledge", "")) == "rumoured":
			rumours += 1
	info.text = "FRONTIER REGION | %s | %s km conceptual area | %s visible, %s rumours\n1-6: biome examples   F: fit   ARROWS: pan   WHEEL: zoom   H: %s\n%s" % [
		str(area.get("terrain", "unknown")), str(area.get("side_km", "?")),
		str(shown), str(rumours), "hide developer sites" if reveal_hidden else "developer reveal",
		"CLICK SITE: inspect | Routes and site coordinates are provisional, patrol status unverified"
	]
	if not selected_description.is_empty():
		info.text += "\n" + selected_description

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var choice: int = event.keycode - KEY_1
			reveal_hidden = false
			load_region("res://tools/regiongen/.tmp/populated-%s.json" % POPULATED_CASES[choice])
			fit_region()
			queue_redraw()
			return
		if event.keycode == KEY_H:
			reveal_hidden = not reveal_hidden
			selected_description = ""
			_update_description()
			queue_redraw()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cursor := get_global_mouse_position()
		for value in region.get("local_sites", {}).get("sites", []):
			if not value is Dictionary:
				continue
			var site: Dictionary = value
			if not _visible(site):
				continue
			var coords: Array = site.get("position", [])
			if coords.size() != 2:
				continue
			if cursor.distance_to(Vector2(float(coords[0]), float(coords[1]))) > 21.0:
				continue
			selected_id = str(site.get("id", ""))
			selected_description = "%s [%s] | %s | %s\n%s" % [
				str(site.get("label", "?")), str(site.get("kind", "?")),
				str(site.get("provenance", "?")), str(site.get("knowledge", "?")),
				str(site.get("description", "No inspection detail"))
			]
			_update_description()
			queue_redraw()
			return
	super._unhandled_input(event)

func _symbol_points(vertices: Array, center: Vector2, scale: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for entry in vertices:
		if entry is Array and entry.size() == 2:
			result.append(center + Vector2(float(entry[0]), float(entry[1])) * scale)
	return result


func _draw_symbol(site: Dictionary) -> void:
	var xy: Array = site.get("position", [])
	if xy.size() != 2:
		return
	var p := Vector2(float(xy[0]), float(xy[1]))
	var kind := str(site.get("kind", ""))
	var specs: Dictionary = icon_registry.get("symbols", {})
	var spec: Dictionary = specs.get(kind, specs.get("ancient_stones", {}))
	var palette: Dictionary = icon_registry.get("palette", {})
	var scale := float(spec.get("scale", 1.0))
	var selected := str(site.get("id", "")) == selected_id
	var radius := 23.0 if selected else 20.0
	var rim := Color("#b78943") if kind == "hometown" else Color("#6f6c50")
	draw_circle(p + Vector2(2.0, 3.0), radius + 1.0, Color("#262b23", 0.18))
	draw_circle(p, radius, Color("#e6d9b7"))
	draw_arc(p, radius, 0.0, TAU, 32, rim, 3.0 if selected else 2.0)
	for entry in spec.get("polygons", []):
		if not entry is Dictionary:
			continue
		var points := _symbol_points(entry.get("points", []), p, scale)
		if points.size() < 3:
			continue
		var shade := Color(str(palette.get(str(entry.get("role", "")), "#a69e82")))
		draw_colored_polygon(points, shade)
		var closed_points := PackedVector2Array(points)
		closed_points.append(points[0])
		draw_polyline(closed_points, Color("#242920"), 1.35)
	for entry in spec.get("lines", []):
		if not entry is Dictionary:
			continue
		var points := _symbol_points(entry.get("points", []), p, scale)
		if points.size() > 1:
			draw_polyline(points, Color(str(palette.get(str(entry.get("role", "")), "#242920"))), float(entry.get("width", 1.3)))


func _draw_sparse_labels() -> void:
	var font: Font = ThemeDB.fallback_font
	var occupied: Array[Rect2] = []
	# Only primary locations and selected inspections get map labels.
	var preferred := ["hometown", "ruins", "roadside_inn", "watchtower"]
	for kind in preferred:
		for value in region.get("local_sites", {}).get("sites", []):
			if not value is Dictionary or not _visible(value):
				continue
			var site: Dictionary = value
			var is_selected := str(site.get("id", "")) == selected_id
			if str(site.get("kind", "")) != kind and not is_selected:
				continue
			var xy: Array = site.get("position", [])
			if xy.size() != 2:
				continue
			var p := Vector2(float(xy[0]), float(xy[1]))
			var name := str(site.get("label", "Unknown"))
			var width := clampf(float(name.length()) * 7.3 + 18.0, 87.0, 220.0)
			var corners := [Vector2(p.x + 25.0, p.y - 16.0),
					Vector2(p.x - width - 25.0, p.y - 16.0),
					Vector2(p.x - width * 0.5, p.y + 27.0),
					Vector2(p.x - width * 0.5, p.y - 47.0)]
			for corner in corners:
				var rect := Rect2(corner, Vector2(width, 25.0))
				if rect.position.x < 18.0 or rect.end.x > 981.0 or rect.position.y < 116.0 or rect.end.y > 928.0:
					continue
				var collision := false
				for used in occupied:
					if rect.grow(5.0).intersects(used):
						collision = true
						break
				if collision:
					continue
				occupied.append(rect)
				draw_rect(rect, Color("#f1dfae", 0.96) if kind == "hometown" else Color("#e5d8b8", 0.94))
				draw_rect(rect, Color("#4c4736"), false, 1.6 if kind == "hometown" else 0.8)
				draw_string(font, corner + Vector2(9.0, 17.0), name,
						HORIZONTAL_ALIGNMENT_LEFT, width - 12.0, 15 if kind == "hometown" else 13, Color("#292b22"))
				break
			if is_selected and kind != str(site.get("kind", "")):
				return


func _draw() -> void:
	super._draw()
	if region.is_empty():
		return
	for value in region.get("local_sites", {}).get("sites", []):
		if value is Dictionary and _visible(value):
			_draw_symbol(value)
	_draw_sparse_labels()
