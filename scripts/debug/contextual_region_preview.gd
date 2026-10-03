extends "res://scripts/debug/constrained_region_preview.gd"

## GAME-44: new optional developer-only source-grounded site inspection.
## Existing GAME-47 and GAME-40 scenes and player saves are untouched.
const V2_CASES := [
 "contextual-game-11-determinism-shore",
 "contextual-game-11-determinism-river",
 "contextual-game-11-determinism-highland",
 "contextual-atlas-showcase-shore",
 "contextual-atlas-showcase-river",
 "contextual-atlas-showcase-highland"
]
const GLYPHS := "res://assets/map/region-site-icons.json"
var glyphs: Dictionary = {}
var selected_local_id: String = ""
var reveal_hidden_for_developer: bool = false
var show_route_audit: bool = false

func _ready() -> void:
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(GLYPHS))
	if decoded is Dictionary and int(decoded.get("schema_version", -1)) == 1:
		glyphs = decoded
	fit_map()
	load_region(SAMPLE_FOLDER + V2_CASES[0] + ".json")

func _base_info() -> String:
	return super._base_info() + "\nGAME-44 | Pictograms = game-owned sites | H: developer reveal | A: route audit (off by default; no save)"

func load_region(path: String) -> bool:
	selected_local_id = ""
	reveal_hidden_for_developer = false
	show_route_audit = false
	if not super.load_region(path):
		return false
	var layer: Dictionary = region.get("local_sites_v2", {})
	if int(layer.get("schema_version", -1)) != 2 or str(layer.get("source_context_id", "")) != str(region["source_context"].get("id", "")):
		info.text = "GAME-44 | v2 contextual site layer absent or does not match source geography"
		region.clear()
		queue_redraw()
		return false
	queue_redraw()
	return true

func _site_is_visible(site: Dictionary) -> bool:
	var state: String = str(site.get("knowledge", "hidden"))
	return reveal_hidden_for_developer or state == "discovered" or state == "visited"

func _symbol_points(vertices: Variant, point: Vector2, scaling: float) -> PackedVector2Array:
	var output := PackedVector2Array()
	if not vertices is Array:
		return output
	for pair in vertices:
		if pair is Array and pair.size() == 2:
			output.append(point + Vector2(float(pair[0]), float(pair[1])) * scaling)
	return output

func _draw_site(site: Dictionary) -> void:
	var p: Vector2 = _point(site.get("position", []))
	var kind: String = str(site.get("kind", ""))
	var symbols: Dictionary = glyphs.get("symbols", {})
	var spec: Dictionary = symbols.get(kind, symbols.get("ancient_stones", {}))
	var palette: Dictionary = glyphs.get("palette", {})
	var scale: float = float(spec.get("scale", 1.0))
	var active: bool = str(site.get("id", "")) == selected_local_id
	draw_circle(p + Vector2(2, 3), 21, Color("#252b25", .2))
	draw_circle(p, 20, Color("#e6d9b7"))
	draw_arc(p, 20, 0, TAU, 32, Color("#b78943") if kind == "hometown" else Color("#6f6c50"), 3.0 if active else 2.0)
	for entry in spec.get("polygons", []):
		if not entry is Dictionary:
			continue
		var shape: PackedVector2Array = _symbol_points(entry.get("points", []), p, scale)
		if shape.size() < 3:
			continue
		draw_colored_polygon(shape, Color(str(palette.get(str(entry.get("role", "")), "#a69e82"))))
		var outline: PackedVector2Array = PackedVector2Array(shape)
		outline.append(shape[0])
		draw_polyline(outline, Color("#242920"), 1.35, true)
	for entry in spec.get("lines", []):
		if not entry is Dictionary:
			continue
		var line: PackedVector2Array = _symbol_points(entry.get("points", []), p, scale)
		if line.size() >= 2:
			draw_polyline(line, Color(str(palette.get(str(entry.get("role", "")), "#242920"))), float(entry.get("width", 1.3)), true)

func _draw() -> void:
	super._draw()
	if region.is_empty():
		return
	var layer: Dictionary = region.get("local_sites_v2", {})
	# Original route/shore conflicts remain in source JSON and are visible
	# ONLY under an explicit no-save developer audit overlay (A key).
	if show_route_audit:
		for flag in layer.get("route_consistency", {}).get("conflicts", []):
			var original_id: int = int(flag.get("source_route_id", -1))
			var segment_id: int = int(flag.get("source_segment", -1))
			for source_route in region.get("source_context", {}).get("source_routes", []):
				if int(source_route.get("source_id", -1)) != original_id:
					continue
				for edge in source_route.get("segments", []):
					if int(edge.get("source_segment", -1)) != segment_id:
						continue
					var path: PackedVector2Array = _poly(edge.get("local_points", []))
					if path.size() >= 2:
						_dash(path[0], path[1], Color("#9d4735", .92), 3.5, 7.0, 5.0)
	var font: Font = ThemeDB.fallback_font
	for value in layer.get("sites", []):
		if not value is Dictionary:
			continue
		var site: Dictionary = value
		if str(site.get("kind", "")) == "hometown" or not _site_is_visible(site):
			continue
		_draw_site(site)
		if str(site.get("id", "")) == selected_local_id:
			var p: Vector2 = _point(site.get("position", []))
			var text_value: String = str(site.get("label", ""))
			var width: float = clampf(text_value.length() * 9.0 + 24.0, 80.0, 225.0)
			var x: float = clampf(p.x + 25.0, 8.0, 995.0 - width)
			var y: float = clampf(p.y - 8.0, 112.0, 929.0)
			draw_rect(Rect2(x - 4, y - 18, width, 24), Color("#eee0be", .96))
			draw_string(font, Vector2(x, y), text_value, HORIZONTAL_ALIGNMENT_LEFT, width - 8.0, 15, Color("#292d25"))

func select_local_site_at(point: Vector2) -> bool:
	if region.is_empty():
		return false
	var best: float = 24.0
	var chosen: Dictionary = {}
	for value in region.get("local_sites_v2", {}).get("sites", []):
		if not value is Dictionary:
			continue
		var site: Dictionary = value
		if str(site.get("kind", "")) == "hometown" or not _site_is_visible(site):
			continue
		var delta: float = point.distance_to(_point(site.get("position", [])))
		if delta <= best:
			best = delta
			chosen = site
	if chosen.is_empty():
		selected_local_id = ""
		return false
	selected_local_id = str(chosen.get("id", ""))
	selected_source_id = -1
	info.text = _base_info() + "\nLOCAL SITE | %s | %s | %s | generated, road protection unverified" % [
		str(chosen.get("label", "")),str(chosen.get("kind", "")),str(chosen.get("knowledge", ""))]
	queue_redraw()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			show_route_audit = not show_route_audit
			info.text = _base_info()
			queue_redraw()
			return
		if event.keycode == KEY_H:
			reveal_hidden_for_developer = not reveal_hidden_for_developer
			selected_local_id = ""
			info.text = _base_info()
			queue_redraw()
			return
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			load_region(SAMPLE_FOLDER + V2_CASES[event.keycode - KEY_1] + ".json")
			fit_map()
			return
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if select_local_site_at(get_global_mouse_position()):
			return
	super._unhandled_input(event)
