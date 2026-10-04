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
var show_hex_grid: bool = false
var show_encounter_demo: bool = false
var selected_encounter_demo_id: String = ""
var shared_icons := MapIconProvider.new()

func _draw_shared_icon(role: String, p: Vector2, danger: bool = false) -> void:
	var texture: Texture2D = shared_icons.texture_for(role)
	draw_circle(p, 16, Color("#efe1bd"))
	draw_arc(p, 16, 0, TAU, 32, Color("#9d4735") if danger else Color("#66583e"), 2)
	if texture != null:
		draw_texture_rect(texture, Rect2(p - Vector2(13, 13), Vector2(26, 26)), false)

func _draw_burg_icon(site: Dictionary, p: Vector2, radius: float, is_home: bool) -> void:
	var icons: Dictionary = region.get("world_icon_roles_v1", {})
	if icons.is_empty():
		super._draw_burg_icon(site, p, radius, is_home)
	else:
		_draw_shared_icon(str(icons.get("burg_roles", {}).get(str(site.get("source_id")), "town")), p)

func _ready() -> void:
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(GLYPHS))
	if decoded is Dictionary and int(decoded.get("schema_version", -1)) == 1:
		glyphs = decoded
	fit_map()
	load_region(SAMPLE_FOLDER + V2_CASES[0] + ".json")

func _base_info() -> String:
	return super._base_info() + "\nX: hex grid | E: encounter mock-up | H: reveal | A: route audit (developer only; no save)"

func load_region(path: String) -> bool:
	selected_local_id = ""
	reveal_hidden_for_developer = false
	show_route_audit = false
	show_hex_grid = false
	show_encounter_demo = false
	selected_encounter_demo_id = ""
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
	if region.has("world_icon_roles_v1"):
		_draw_shared_icon(str(region.world_icon_roles_v1.site_roles.get(kind, "statues")), p)
		if str(site.get("id", "")) == selected_local_id:
			draw_arc(p, 19, 0, TAU, 32, Color("#b78943"), 2)
		return
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
	if show_hex_grid or (show_encounter_demo and _encounter_preview_available()):
		_draw_hex_grid()
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
	if show_encounter_demo and _encounter_preview_available():
		_draw_encounter_demo()

func _encounter_preview_available() -> bool:
	var demo: Dictionary = region.get("encounter_demo_v1", {})
	var ctx: Dictionary = region.get("source_context", {})
	return int(demo.get("schema_version", -1)) == 1 and str(demo.get("meaning", "")) == "MOCKUP_NOT_SIMULATION" and str(demo.get("source_context_id", "")) == str(ctx.get("id", "")) and str(demo.get("source_world_sha256", "")) == str(ctx.get("parent_source_world_sha256", ""))

func select_encounter_demo_at(point: Vector2) -> bool:
	if not show_encounter_demo or not _encounter_preview_available():
		return false
	for occupant in region.get("encounter_demo_v1", {}).get("occupants", []):
		if point.distance_to(_point(occupant.get("position", []))) > 24:
			continue
		selected_encounter_demo_id = str(occupant.get("id", ""))
		selected_local_id = ""
		selected_source_id = -1
		var axial: Array = occupant.get("axial", [0, 0])
		info.text = _base_info() + "\nMOCK-UP ONLY | %s | hex (%d, %d)\n%s\n%d geometric hex steps from home; no combat or spawn rules" % [str(occupant.get("label", "")), int(axial[0]), int(axial[1]), str(occupant.get("placement", "")), hex_steps_to(_point(occupant.get("position", [])))]
		queue_redraw()
		return true
	selected_encounter_demo_id = ""
	return false

func _draw_encounter_demo() -> void:
	draw_rect(Rect2(590, 20, 390, 45), Color("#efe1bd", .96))
	draw_string(ThemeDB.fallback_font, Vector2(604, 48), "HEX OCCUPANTS · MOCK-UP, NOT LIVE", HORIZONTAL_ALIGNMENT_LEFT, 370, 18, Color("#843e30"))
	var demo: Dictionary = region.get("encounter_demo_v1", {})
	for occupant in demo.get("occupants", []):
		var p: Vector2 = _point(occupant.get("position", []))
		var active: bool = str(occupant.get("id", "")) == selected_encounter_demo_id
		for cell in region.get("hex_overlay_v1", {}).get("cells", []):
			if cell.get("axial", []) == occupant.get("axial", []):
				var shape: PackedVector2Array = _poly(cell.get("points", []))
				if shape.size() == 6:
					draw_colored_polygon(shape, Color("#9d4735", .16 if active else .08))
		_draw_shared_icon(str(occupant.get("role", "")), p, true)
		if active:
			draw_arc(p, 20, 0, TAU, 32, Color("#9d4735"), 2)
		var text_value: String = str(occupant.get("label", "")) + " · mock-up"
		var width: float = text_value.length() * 8.5 + 12
		draw_rect(Rect2(p + Vector2(21, -15), Vector2(width, 24)), Color("#efe1bd", .94))
		draw_string(ThemeDB.fallback_font, p + Vector2(25, 3), text_value, HORIZONTAL_ALIGNMENT_LEFT, width - 8, 15, Color("#843e30"))
	if not demo.get("omitted_roles", []).is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(604, 84), "Some mock-ups omitted: no suitable dry cell", HORIZONTAL_ALIGNMENT_LEFT, 370, 13, Color("#843e30"))

func select_local_site_at(point: Vector2) -> bool:
	if region.is_empty():
		return false
	selected_encounter_demo_id = ""
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
	if show_hex_grid:
		info.text += "\nDistance from hometown: %d hex steps (geometric; hours and terrain routing pending)" % hex_steps_to(_point(chosen["position"]))
	queue_redraw()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			if _encounter_preview_available():
				show_encounter_demo = not show_encounter_demo
			selected_encounter_demo_id = ""
			info.text = _base_info()
			queue_redraw()
			return
		if event.keycode == KEY_X:
			show_hex_grid = not show_hex_grid
			info.text = _base_info()
			queue_redraw()
			return
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
		if select_encounter_demo_at(get_global_mouse_position()):
			return
		if select_local_site_at(get_global_mouse_position()):
			return
	super._unhandled_input(event)

# GAME-58: display-only world-anchored hex ruler. No travel/save changes.
func _hex_at_local(point: Vector2) -> Vector2i:
	var bounds: Dictionary = region.get("source_context", {}).get("space", {}).get("source_bounds", {})
	var x: float = float(bounds.get("left", 0)) + point.x * (float(bounds.get("right", 1000)) - float(bounds.get("left", 0))) / 1000.0
	var y: float = float(bounds.get("top", 0)) + point.y * (float(bounds.get("bottom", 1000)) - float(bounds.get("top", 0))) / 1000.0
	var size: float = 1.0 / sqrt(3.0)
	var q: float = (sqrt(3.0) / 3.0 * x - y / 3.0) / size
	var r: float = 2.0 * y / 3.0 / size
	var s: float = -q - r
	var a: int = roundi(q)
	var b: int = roundi(r)
	var c: int = roundi(s)
	var da: float = absf(a - q)
	var db: float = absf(b - r)
	var dc: float = absf(c - s)
	if da > db and da > dc:
		a = -b - c
	elif db > dc:
		b = -a - c
	return Vector2i(a, b)

func hex_steps_to(point: Vector2) -> int:
	var overlay: Dictionary = region.get("hex_overlay_v1", {})
	if overlay.is_empty():
		return -1
	var h: Array = overlay.get("home_axial", [0, 0])
	var d: Vector2i = _hex_at_local(point) - Vector2i(int(h[0]), int(h[1]))
	return maxi(absi(d.x), maxi(absi(d.y), absi(d.x + d.y)))

func _draw_hex_grid() -> void:
	var overlay: Dictionary = region.get("hex_overlay_v1", {})
	if overlay.is_empty():
		return
	var target := Vector2i(-99999, -99999)
	var steps: int = -1
	for site in region.get("local_sites_v2", {}).get("sites", []):
		if str(site.get("id", "")) == selected_local_id and _site_is_visible(site):
			target = _hex_at_local(_point(site["position"]))
			steps = hex_steps_to(_point(site["position"]))
	for cell in overlay.get("cells", []):
		var shape: PackedVector2Array = _poly(cell.get("points", []))
		var axial: Array = cell.get("axial", [0, 0])
		if shape.size() != 6:
			continue
		# Clip edge hexes to the map rectangle; no invented boundary crop.
		var border := PackedVector2Array([Vector2.ZERO, Vector2(1000, 0), Vector2(1000, 1000), Vector2(0, 1000)])
		for clipped in Geometry2D.intersect_polygons(shape, border):
			if Vector2i(int(axial[0]), int(axial[1])) == target:
				draw_colored_polygon(clipped, Color("#d8a749", .3))
			var outline := PackedVector2Array(clipped)
			outline.append(outline[0])
			draw_polyline(outline, Color("#584b32", .28), .85, true)
	var message: String = "HEX DISTANCE | 1 source unit spacing; physical scale undecided"
	if steps >= 0:
		message = "DISTANCE FROM HOMETOWN: %d hex steps | Terrain routing / hours pending" % steps
	draw_rect(Rect2(18, 950, 960, 32), Color("#eee0bd", .95))
	draw_string(ThemeDB.fallback_font, Vector2(30, 972), message, HORIZONTAL_ALIGNMENT_LEFT, 930, 16, Color("#534c39"))
