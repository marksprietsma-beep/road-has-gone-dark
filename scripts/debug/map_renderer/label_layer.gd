class_name LabelMapLayer
extends MapLayer

func _draw() -> void:
	if not model: return
	var font := ThemeDB.fallback_font
	var occupied: Array[Rect2] = []
	for state_id in model.state_records:
		if int(state_id) == 0: continue
		var state: Dictionary = model.state_records[state_id]
		var center := int(state.get("center", -1))
		if model.valid_cell(center):
			var value := str(state.get("name", "")).to_upper()
			var p := model.point(center)
			_draw_centered_label(font, p, value, 14, Color("#2a211b", 0.82), occupied)
	if zoom_band < 1: return
	var settlements: Array = model.fixture.get("settlements", []).duplicate()
	settlements.sort_custom(func(a: Variant, b: Variant) -> bool: return _importance(a) > _importance(b))
	for settlement in settlements:
		if not settlement is Dictionary or settlement.is_empty(): continue
		var capital := int(settlement.get("capital", 0)) == 1
		var population := float(settlement.get("population", 0.0))
		if zoom_band == 1 and not capital and population < 10.0: continue
		if zoom_band == 2 and not capital and population < 2.0: continue
		var p := Vector2(float(settlement.get("x", 0)) + 5, float(settlement.get("y", 0)) - 3)
		_draw_label(font, p, str(settlement.get("name", "")), 9 if not capital else 11, Color("#ead9ad"), occupied)

func _importance(value: Variant) -> float:
	if not value is Dictionary: return -1.0
	return float(value.get("population", 0.0)) + (1000.0 if int(value.get("capital", 0)) == 1 else 0.0)

func _draw_centered_label(font: Font, p: Vector2, value: String, size: int, color: Color, occupied: Array[Rect2]) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_draw_label(font, p - Vector2(width * 0.5, 0), value, size, color, occupied)

func _draw_label(font: Font, p: Vector2, value: String, size: int, color: Color, occupied: Array[Rect2]) -> void:
	var label_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var bounds := Rect2(p + Vector2(0, -size), Vector2(label_size.x, size + 3)).grow(2.0)
	for used in occupied:
		if bounds.intersects(used): return
	occupied.append(bounds)
	draw_string(font, p + Vector2(1, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#171310"))
	draw_string(font, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
