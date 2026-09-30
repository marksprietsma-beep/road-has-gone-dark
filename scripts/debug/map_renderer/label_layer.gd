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
			if _claim_label(occupied, p, value, 8): _draw_label(font, p, value, 8, Color("#332b23", 0.8))
	if zoom_band < 1: return
	for settlement in model.fixture.get("settlements", []):
		if not settlement is Dictionary or settlement.is_empty(): continue
		var capital := int(settlement.get("capital", 0)) == 1
		var population := float(settlement.get("population", 0.0))
		if zoom_band == 1 and not capital: continue
		if zoom_band == 2 and not capital and population < 4.0: continue
		var p := Vector2(float(settlement.get("x", 0)) + 4, float(settlement.get("y", 0)) - 2)
		var value := str(settlement.get("name", ""))
		var size := 8 if capital else 7
		if _claim_label(occupied, p, value, size): _draw_label(font, p, value, size, Color("#3b3025", 0.94))

func _draw_label(font: Font, p: Vector2, value: String, size: int, color: Color) -> void:
	var halo := Color("#c2b58d", 0.55)
	for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_string(font, p + offset, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, halo)
	draw_string(font, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _claim_label(occupied: Array[Rect2], p: Vector2, value: String, size: int) -> bool:
	var bounds := Rect2(p + Vector2(-2, -size), Vector2(maxf(8.0, value.length() * size * 0.55), size + 3.0)).grow(3.0)
	for other: Rect2 in occupied:
		if other.intersects(bounds): return false
	occupied.append(bounds)
	return true
