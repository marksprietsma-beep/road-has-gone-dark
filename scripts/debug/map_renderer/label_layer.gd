class_name LabelMapLayer
extends MapLayer

var selected_burg_id := -1
var displayed_labels: Array[Dictionary] = []
var _layout_key := ""

func _process(_delta: float) -> void:
	if is_visible_in_tree() and model:
		if _key() != _layout_key: queue_redraw()

func _key() -> String:
	return str([model.get_instance_id(),get_global_transform_with_canvas(),get_viewport_rect(),zoom_band,selected_burg_id,get_viewport().get_meta("map_pixel_ratio",1.0),get_parent().get_node("Landmarks").visible,get_parent().get_node("Landmarks").declutter_enabled,get_parent().get_node("Settlements").visible])

func _draw() -> void:
	if not model: return
	if _key() != _layout_key:
		_build_layout()
		_layout_key = _key()
	draw_set_transform_matrix(get_global_transform_with_canvas().affine_inverse())
	var font := ThemeDB.fallback_font
	var ratio: float = get_viewport().get_meta("map_pixel_ratio",1.0)
	for label in displayed_labels:
		if label.extended:
			var p: Vector2 = get_global_transform_with_canvas()*label.anchor
			var r: Rect2 = label.rect
			draw_line(p,Vector2(clampf(p.x,r.position.x,r.end.x),clampf(p.y,r.position.y,r.end.y)),Color("#5a4633",.65),ratio,true)
		var color := Color("#382d22") if label.kind == "burg" else Color("#5a4633")
		draw_string_outline(font,label.baseline,label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.size,maxi(1,roundi(ratio)),Color("#efe1be",.97))
		draw_string(font,label.baseline,label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.size,color)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _build_layout() -> void:
	displayed_labels.clear()
	var font := ThemeDB.fallback_font
	var ratio: float = get_viewport().get_meta("map_pixel_ratio",1.0)
	var transform := get_global_transform_with_canvas()
	var scale: float = transform.get_scale().x
	var screen := get_viewport_rect()
	var occupied: Array[Rect2] = []
	var settlements: SettlementMapLayer = get_parent().get_node("Settlements")
	var landmarks: LandmarkMapLayer = get_parent().get_node("Landmarks")
	if settlements.visible:
		for b in settlements.displayed_settlements:
			var p: Vector2 = transform*Vector2(b.x,b.y)
			var width: float = settlements.icon_size(b)*scale+4*ratio
			if screen.grow(width).has_point(p): occupied.append(Rect2(p-Vector2.ONE*width/2,Vector2.ONE*width))
	if landmarks.visible:
		for m in landmarks.displayed_markers:
			var p: Vector2 = transform*Vector2(m.x,m.y)
			var width: float = 7*scale+4*ratio
			if screen.grow(width).has_point(p): occupied.append(Rect2(p-Vector2.ONE*width/2,Vector2.ONE*width))
	var ordered: Array = settlements.displayed_settlements.duplicate() if settlements.visible else []
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if int(a.i) == selected_burg_id: return int(b.i) != selected_burg_id
		if int(b.i) == selected_burg_id: return false
		if int(a.get("capital",0)) != int(b.get("capital",0)): return int(a.get("capital",0)) > int(b.get("capital",0))
		if float(a.get("population",0)) != float(b.get("population",0)): return float(a.get("population",0)) > float(b.get("population",0))
		return int(a.i)<int(b.i)
	)
	for b in ordered:
		var p: Vector2 = transform*Vector2(b.x,b.y)
		if not screen.has_point(p): continue
		var selected: bool = int(b.i)==selected_burg_id
		var capital: bool = int(b.get("capital",0))==1
		var size := roundi((17 if selected else (15 if capital else 13))*ratio)
		var label := ScreenLabelLayout.place(font,MapWorldText.plain(b.get("name",""),90),size,p,settlements.icon_size(b)*scale/2+2*ratio,occupied,screen,ratio,64 if selected else 0)
		if not label.is_empty():
			label.merge({"kind":"burg","sourceId":int(b.i),"anchor":Vector2(b.x,b.y),"selected":selected})
			displayed_labels.append(label)
	# Context names occupy remaining space; capitals are never displaced by them.
	var ids: Array = model.state_records.keys(); ids.sort()
	for id in ids:
		if int(id)==0: continue
		var state: Dictionary = model.state_records[id]
		var center: int = int(state.get("center",-1))
		if not model.valid_cell(center): continue
		var p: Vector2 = transform*model.point(center)
		if not screen.has_point(p): continue
		var label := ScreenLabelLayout.place(font,str(state.get("name","")).to_upper(),roundi(12*ratio),p,0,occupied,screen,ratio)
		if not label.is_empty():
			label.merge({"kind":"state","sourceId":int(id),"anchor":model.point(center),"selected":false})
			displayed_labels.append(label)
