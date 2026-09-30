class_name SettlementMapLayer
extends MapLayer

func _draw() -> void:
	if not model: return
	for settlement in model.fixture.get("settlements", []):
		if not settlement is Dictionary or settlement.is_empty(): continue
		var capital := int(settlement.get("capital", 0)) == 1
		if zoom_band == 0 and not capital: continue
		var population := float(settlement.get("population", 0.0))
		if zoom_band == 1 and not capital and population < 4.0: continue
		if zoom_band == 2 and not capital and population < 1.4: continue
		var p := Vector2(float(settlement.get("x", 0)), float(settlement.get("y", 0)))
		var major := population >= 7.0
		if capital:
			var crown := PackedVector2Array([p + Vector2(0, -3.2), p + Vector2(3.2, 0), p + Vector2(0, 3.2), p + Vector2(-3.2, 0)])
			draw_colored_polygon(crown, Color("#372c23"))
			draw_circle(p, 1.35, Color("#bda66f"))
		elif major:
			draw_circle(p, 2.25, Color("#302720"))
			draw_circle(p, 1.05, Color("#b9aa83"))
		elif population >= 3.0:
			draw_circle(p, 1.25, Color("#41362b"))
		else:
			draw_circle(p, 0.75, Color("#504536", 0.82))
