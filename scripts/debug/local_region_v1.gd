extends "res://scripts/debug/constrained_region_preview.gd"

## Isolated GAME-62 map viewer. Public JSON never contains undiscovered sites.
const SAMPLES := ["game-11-determinism-shore", "game-11-determinism-river", "game-11-determinism-highland", "atlas-showcase-shore", "atlas-showcase-river", "atlas-showcase-highland"]
var sample_index: int = 0
var developer_truth: bool = false
var show_hexes: bool = false
var show_cell_context: bool = false
var selected_site: String = ""
var icons := MapIconProvider.new()

func _ready() -> void:
	if get_window().content_scale_size.x < 1000:
		get_window().content_scale_size = Vector2i(1200, 900)
		get_window().size = Vector2i(1200, 900)
	fit_map()
	_load_sample()

func _load_sample() -> bool:
	selected_site = ""
	var suffix: String = ".developer" if developer_truth else ""
	var ok: bool = load_region(SAMPLE_FOLDER + SAMPLES[sample_index] + suffix + ".json")
	if ok:
		info.text = _base_info()
	return ok

func _base_info() -> String:
	var ctx: Dictionary = region.get("source_context", {})
	var scale: Dictionary = region.get("scale", {})
	var view: String = "DEVELOPER FULL TRUTH • hidden locations shown" if developer_truth else "PUBLIC • minor sites undiscovered"
	return "LOCAL REGION V1 | %s | cell %s | %s\n1–6: samples  F: fit  ARROWS / MIDDLE DRAG: pan  WHEEL: zoom  CLICK: inspect  X: hexes  G: cell context  D: developer truth\nGold dashed: original parent cell | coast / roads / burgs: source exact | blue dashed rivers: approximate | terrain / fields: inferred\nSpan %.2f source units • %.0f cell-area hexes • %d owned dry hex centres • kilometres and crossings unverified" % [SAMPLES[sample_index], str(ctx.get("parent_cell", {}).get("source_id", "?")), view, float(scale.get("view_span_source_units", 0)), float(scale.get("cell_area_to_hex_area", 0)), int(scale.get("owned_dry_hex_centres", 0))]

func fit_map() -> void:
	camera.position = Vector2(500, 440)
	var size: Vector2 = get_viewport_rect().size
	var z: float = clampf(minf(size.x / 1120.0, (size.y - 170.0) / 1100.0), .15, 2.8)
	camera.zoom = Vector2(z, z)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			sample_index = event.keycode - KEY_1
			_load_sample()
			fit_map()
		elif event.keycode == KEY_D:
			developer_truth = not developer_truth
			_load_sample()
		elif event.keycode == KEY_X:
			show_hexes = not show_hexes
			queue_redraw()
		elif event.keycode == KEY_G:
			show_cell_context = not show_cell_context
			queue_redraw()
		elif event.keycode == KEY_F:
			fit_map()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		camera.position -= event.relative / camera.zoom
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			inspect_at(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.15).clamp(Vector2(.15, .15), Vector2(2.8, 2.8))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom / 1.15).clamp(Vector2(.15, .15), Vector2(2.8, 2.8))

func _draw_shared_icon(role: String, point: Vector2) -> void:
	# Constant screen size: shared artwork does not balloon with its footprint.
	var inv: float = 1.0 / camera.zoom.x
	var texture: Texture2D = icons.texture_for(role)
	draw_circle(point, 13 * inv, Color("#efe1bd"))
	draw_arc(point, 13 * inv, 0, TAU, 32, Color("#66583e"), inv)
	if texture != null:
		draw_texture_rect(texture, Rect2(point - Vector2(10, 10) * inv, Vector2(20, 20) * inv), false)

func _draw_burg_icon(site: Dictionary, point: Vector2, _radius: float, _home: bool) -> void:
	_draw_shared_icon(str(region.get("world_icon_roles_v1", {}).get("burg_roles", {}).get(str(site.get("source_id", "")), "town")), point)

func inspect_at(point: Vector2) -> bool:
	var best: float = 20.0 / camera.zoom.x
	var chosen: Dictionary = {}
	for site in region.get("local_sites_v2", {}).get("sites", []) + region.source_context.get("source_landmarks", []):
		var d: float = point.distance_to(_point(site.get("position", [])))
		if d < best:
			best = d
			chosen = site
	if chosen.is_empty():
		return select_burg_at(point)
	selected_site = str(chosen.get("id", ""))
	info.text = _base_info() + "\n%s | %s | %s | %s" % [str(chosen.get("label", "")), str(chosen.get("kind", "")), str(chosen.get("knowledge", "")), str(chosen.get("provenance", ""))]
	queue_redraw()
	return true

func _process(delta: float) -> void:
	super._process(delta)
	queue_redraw() # markers/labels retain screen dimensions while zoom changes

func _draw() -> void:
	super._draw()
	if region.is_empty():
		return
	var ctx: Dictionary = region.source_context
	var inv: float = 1.0 / camera.zoom.x
	if show_cell_context:
		var b: Dictionary = ctx.space.source_bounds
		for cell in ctx.get("source_cells", []):
			var poly := PackedVector2Array()
			for p in cell.world_polygon:
				poly.append(Vector2((float(p[0]) - b.left) * 1000 / (b.right - b.left), (float(p[1]) - b.top) * 1000 / (b.bottom - b.top)))
			var square := PackedVector2Array([Vector2(0, 0), Vector2(1000, 0), Vector2(1000, 1000), Vector2(0, 1000)])
			for clipped in Geometry2D.intersect_polygons(poly, square):
				clipped.append(clipped[0])
				draw_polyline(clipped, Color("#5e6965", .55), inv, true)
	if show_hexes:
		for cell in region.get("hex_overlay_v1", {}).get("cells", []):
			var poly: PackedVector2Array = _poly(cell.points)
			poly.append(poly[0])
			draw_polyline(poly, Color("#4d5142", .22), .7 * inv, true)
	var boundary: PackedVector2Array = _poly(ctx.get("parent_cell", {}).get("local_polygon", []))
	for i in boundary.size():
		_dash(boundary[i], boundary[(i + 1) % boundary.size()], Color("#ad8743", .85), 1.4 * inv, 7 * inv, 5 * inv)
	for mark in region.get("landscape_presentation_v1", {}).get("provider_marks", []):
		var p := Vector2(float(mark.x), float(mark.y))
		draw_polyline(PackedVector2Array([p + Vector2(-3, 3), p + Vector2(0, -4), p + Vector2(3, 3)]), Color("#36523f", .6), .8, true)
	for landmark in ctx.get("source_landmarks", []):
		_draw_shared_icon(str(landmark.kind), _point(landmark.position))
	var occupied: Array[Rect2] = []
	for site in region.get("local_sites_v2", {}).get("sites", []):
		if site.get("kind", "") == "hometown":
			continue
		var p: Vector2 = _point(site.position)
		var role: String = str(region.world_icon_roles_v1.site_roles.get(str(site.kind), "statues"))
		_draw_shared_icon(role, p)
		if camera.zoom.x >= .85 or selected_site == str(site.id):
			var label: String = str(site.label)
			var width: float = ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var rect := Rect2(p + Vector2(18, -12) * inv, Vector2(width + 10, 20) * inv)
			if rect.end.x > 990:
				rect.position.x = p.x - (width + 28) * inv
			var clear: bool = true
			for other in occupied:
				if other.intersects(rect):
					clear = false
			if clear and rect.position.y > 10 and rect.end.y < 990:
				occupied.append(rect)
				draw_rect(rect, Color("#efe1be", .94))
				draw_set_transform(Vector2.ZERO, 0, Vector2(inv, inv))
				draw_string(ThemeDB.fallback_font, (rect.position + Vector2(5, 14) * inv) / inv, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
				draw_set_transform(Vector2.ZERO)
