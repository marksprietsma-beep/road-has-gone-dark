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
var marker_groups: Array[Dictionary] = []
var displayed_labels: Array[Dictionary] = []
var _marker_key := ""

func open_town(slug: String, data: Dictionary, bounds: Dictionary) -> bool:
	model = data
	_marker_key = ""
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
	if not visible: return false
	# Native roof hit testing keeps known premises accessible even in a cluster.
	for e in model.get("establishments", []):
		if e.locationType != "building" or e.knowledge == "unknown": continue
		for b in model.buildings:
			if b.id == e.buildingId and _inside(point,b.polygon): return select_facility(e.id)
	var ratio: float = get_viewport().get_meta("map_pixel_ratio",1.0)
	var nearest: Dictionary = {}
	var best: float = pow(15*ratio/camera.zoom.x,2)
	for group in marker_groups:
		if point.distance_to(Vector2(group.representative.position[0],group.representative.position[1])) > 16*ratio/camera.zoom.x: continue
		for e in group.members:
			var distance: float = point.distance_squared_to(Vector2(e.position[0],e.position[1]))
			if distance < best: best = distance; nearest = e
	return select_facility(nearest.id) if not nearest.is_empty() else false

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

func _build_markers(ratio: float) -> void:
	var key: String = str([model.settlement.id,get_global_transform_with_canvas(),get_viewport_rect(),ratio])
	if key == _marker_key: return
	_marker_key = key
	marker_groups.clear()
	rendered_markers.clear()
	var priority := {"guildhall":100,"chapel":95,"warehouse":90,"manor":85,"pier":80,"inn":75,"smithy":70}
	var ordered: Array = model.establishments.filter(func(e: Dictionary) -> bool:return e.knowledge != "unknown")
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var pa: int = priority.get(a.type,40)
		var pb: int = priority.get(b.type,40)
		return pa > pb if pa != pb else str(a.id)<str(b.id)
	)
	var transform := get_global_transform_with_canvas()
	for e in ordered:
		var screen_point: Vector2 = transform*Vector2(e.position[0],e.position[1])
		if not get_viewport_rect().grow(-15*ratio).has_point(screen_point): continue
		var box := Rect2(screen_point-Vector2.ONE*14*ratio,Vector2.ONE*28*ratio)
		var group_index := -1
		var best := INF
		for i in marker_groups.size():
			var group: Dictionary = marker_groups[i]
			if group.rect.grow(2*ratio).intersects(box):
				var distance: float = screen_point.distance_squared_to(group.screenPosition)
				if distance < best: best = distance; group_index = i
		if group_index >= 0:
			marker_groups[group_index].members.append(e)
		else:
			marker_groups.append({"representative":e,"members":[e],"rect":box,"screenPosition":screen_point})
			rendered_markers.append(e)

func _draw() -> void:
	if art == null or model.is_empty() or camera == null: return
	var ratio: float = get_viewport().get_meta("map_pixel_ratio",1.0)
	_build_markers(ratio)
	draw_texture_rect(art,frame,false)
	var inv: float = ratio/camera.zoom.x
	for ring in selected_polygon():
		var polygon := _poly(ring); polygon.append(polygon[0])
		draw_polyline(polygon,Color("#9b4427"),2.4*inv,true)
	for group in marker_groups:
		var e: Dictionary = group.representative
		var p := Vector2(e.position[0],e.position[1])
		draw_circle(p,13*inv,Color("#fff2d4"))
		draw_arc(p,13*inv,0,TAU,32,Color("#795b38"),1.2*inv,true)
		if icons.has(e.type): draw_texture_rect(icons[e.type],Rect2(p-Vector2(9,9)*inv,Vector2(18,18)*inv),false)
	# Labels and badges are native pixel draws, independent of marker layout.
	draw_set_transform_matrix(get_global_transform_with_canvas().affine_inverse())
	var font := ThemeDB.fallback_font
	var occupied: Array[Rect2] = []
	for group in marker_groups:
		occupied.append(group.rect)
		if group.members.size()>1:
			var point: Vector2 = group.screenPosition+Vector2(9,-9)*ratio
			draw_circle(point,6*ratio,Color("#e7d4a9"))
			var value := str(group.members.size())
			var size := roundi(9*ratio)
			var width: float = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
			draw_string(font,point+Vector2(-width/2,3*ratio),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("#30281d"))
	displayed_labels.clear()
	var labels: Array = rendered_markers.duplicate()
	for e in model.establishments:
		if e.id == selected_id:
			labels.erase(e); labels.push_front(e); break
	for e in labels:
		if e.knowledge == "unknown": continue
		if e.id != selected_id and camera.zoom.x/ratio*frame.size.x <= 1400 and e.type not in ["guildhall","warehouse","pier","chapel"]: continue
		var point: Vector2 = get_global_transform_with_canvas()*Vector2(e.position[0],e.position[1])
		var label := ScreenLabelLayout.place(font,e.label,roundi(13*ratio),point,15*ratio,occupied,get_viewport_rect(),ratio)
		if label.is_empty(): continue
		label.merge({"id":e.id,"selected":e.id==selected_id})
		displayed_labels.append(label)
		draw_rect(label.rect,Color("#fff2d4",.92))
		draw_string(font,label.baseline,label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.size,Color("#30281d"))
	draw_set_transform_matrix(Transform2D.IDENTITY)
