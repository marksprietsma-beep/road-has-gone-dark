class_name LabelMapLayer
extends MapLayer

func _draw() -> void:
	if not model: return
	var font := ThemeDB.fallback_font
	for state_id in model.state_records:
		if int(state_id) == 0: continue
		var state: Dictionary = model.state_records[state_id]
		var center := int(state.get("center", -1))
		if model.valid_cell(center):
			_draw_label(font, model.point(center), str(state.get("name", "")), 13, Color("#241d19"))
	if zoom_band < 1: return
	for settlement in model.fixture.get("settlements", []):
		if not settlement is Dictionary or settlement.is_empty(): continue
		var capital := int(settlement.get("capital", 0)) == 1
		if zoom_band == 1 and not capital: continue
		var p := Vector2(float(settlement.get("x", 0)) + 5, float(settlement.get("y", 0)) - 3)
		_draw_label(font, p, str(settlement.get("name", "")), 9 if not capital else 11, Color("#f4e7c6"))

func _draw_label(font: Font, p: Vector2, value: String, size: int, color: Color) -> void:
	draw_string(font, p + Vector2(1, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#171310"))
	draw_string(font, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
