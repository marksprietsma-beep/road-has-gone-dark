extends Node2D

## GAME-69 public artwork, GAME-67 exact facility polygons; Godot-native input/draw.
signal facility_selected(facility: Dictionary)
var model: Dictionary = {}
var frame := Rect2()
var art: Texture2D
var camera: Camera2D
var selected_id := ""
var rendered_markers: Array[Dictionary] = []
var icons: Dictionary = {}

func open_town(slug: String, data: Dictionary, bounds: Dictionary) -> bool:
	model = data
	selected_id = ""
	frame = Rect2(float(bounds.x), float(bounds.y), float(bounds.width), float(bounds.height))
	var texture := load("res://research/game70/art/%s.png" % slug) as Texture2D
	if texture == null:
		model = {}
		return false
	art = texture
	for facility in model.establishments:
		var role: String = facility.type
		if not icons.has(role):
			var glyph := Image.new()
			if glyph.load_svg_from_string(FileAccess.get_file_as_string("res://research/game69/assets/%s.svg" % role)) == OK:
				icons[role] = ImageTexture.create_from_image(glyph)
	queue_redraw()
	return true

func select_facility(id: String) -> bool:
	for e in model.get("establishments", []):
		if e.id == id and e.knowledge != "unknown":
			selected_id = id
			facility_selected.emit(e)
			queue_redraw()
			return true
	return false

func inspect_at(point: Vector2) -> bool:
	# Only drawn markers are clickable; the index also exposes decluttered facilities.
	for e in rendered_markers:
		if point.distance_to(Vector2(e.position[0], e.position[1])) <= 15.0 / camera.zoom.x:
			return select_facility(e.id)
	# Exact known building footprints can also be clicked, including unlabelled roofs.
	for e in model.get("establishments", []):
		if e.locationType != "building" or e.knowledge == "unknown":
			continue
		for b in model.buildings:
			if b.id == e.buildingId and _inside(point, b.polygon):
				return select_facility(e.id)
	return false

func _inside(point: Vector2, rings: Array) -> bool:
	if not Geometry2D.is_point_in_polygon(point, _poly(rings[0])):
		return false
	for ring in rings.slice(1):
		if Geometry2D.is_point_in_polygon(point, _poly(ring)):
			return false
	return true

func _poly(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(Vector2(p[0], p[1]))
	return result

func selected_polygon() -> Array:
	for e in model.get("establishments", []):
		if e.id == selected_id and e.locationType == "building":
			for b in model.buildings:
				if b.id == e.buildingId:
					return b.polygon
	return []

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if art == null or model.is_empty() or camera == null:
		return
	draw_texture_rect(art, frame, false)
	var inv: float = 1.0 / camera.zoom.x
	for ring in selected_polygon():
		var polygon := _poly(ring)
		# Canonical exterior/interior outlines, no invented roof replacement.
		polygon.append(polygon[0])
		draw_polyline(polygon, Color("#9b4427"), 2.4 * inv, true)
	var priority := {"guildhall":100,"chapel":95,"warehouse":90,"manor":85,"pier":80,"inn":75,"smithy":70}
	var ordered: Array = model.establishments.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.id == selected_id: return true
		if b.id == selected_id: return false
		var pa: int = priority.get(a.type, 40)
		var pb: int = priority.get(b.type, 40)
		return pa > pb if pa != pb else str(a.id) < str(b.id)
	)
	rendered_markers.clear()
	var occupied: Array[Rect2] = []
	var screen: Rect2 = get_viewport_rect()
	for e in ordered:
		if e.knowledge == "unknown": continue
		var p := Vector2(e.position[0], e.position[1])
		var s: Vector2 = get_global_transform_with_canvas() * p
		if not screen.grow(-15).has_point(s): continue
		var labelled: bool = e.id == selected_id or camera.zoom.x * frame.size.x > 1400 or e.type in ["guildhall", "warehouse", "pier", "chapel"]
		var text: String = e.label
		var width: float = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 6 if labelled else 0
		var box := Rect2(s - Vector2(15, 15), Vector2(32 + width, 30))
		if box.end.x > screen.end.x - 5:
			labelled = false
			width = 0
			box.size.x = 30
		var clear := true
		for other in occupied:
			if other.grow(3).intersects(box): clear = false
		if not clear: continue
		occupied.append(box)
		rendered_markers.append(e)
		draw_circle(p, 13 * inv, Color("#fff2d4"))
		draw_arc(p, 13 * inv, 0, TAU, 32, Color("#795b38"), 1.2 * inv, true)
		if icons.has(e.type):
			draw_texture_rect(icons[e.type], Rect2(p - Vector2(9,9)*inv, Vector2(18,18)*inv), false)
		if labelled:
			draw_rect(Rect2(p + Vector2(15,-10)*inv, Vector2(width,20)*inv), Color("#fff2d4", .94))
			draw_set_transform(Vector2.ZERO, 0, Vector2(inv, inv))
			draw_string(ThemeDB.fallback_font, p / inv + Vector2(18,5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#30281d"))
			draw_set_transform(Vector2.ZERO)
