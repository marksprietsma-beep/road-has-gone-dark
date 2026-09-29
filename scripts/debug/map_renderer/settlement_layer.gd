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
		var p := Vector2(float(settlement.get("x", 0)), float(settlement.get("y", 0)))
		var radius := 3.5 if capital else 2.0
		draw_circle(p, radius + 1.2, Color("#211a17"))
		draw_circle(p, radius, Color("#f3cf78") if capital else Color("#eee0bd"))
