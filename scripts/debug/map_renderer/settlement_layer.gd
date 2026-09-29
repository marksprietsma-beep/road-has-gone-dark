class_name SettlementMapLayer
extends MapLayer

func _draw() -> void:
	if not model: return
	for settlement in model.fixture.get("settlements", []):
		if not settlement is Dictionary or settlement.is_empty(): continue
		var capital := int(settlement.get("capital", 0)) == 1
		var population := float(settlement.get("population", 0.0))
		var rank := _rank(capital, population)
		if rank > zoom_band + 1: continue
		var p := Vector2(float(settlement.get("x", 0)), float(settlement.get("y", 0)))
		_draw_settlement(p, rank, capital, int(settlement.get("walls", 0)) == 1)

func _rank(capital: bool, population: float) -> int:
	if capital: return 0
	if population >= 10.0: return 1
	if population >= 3.0: return 2
	return 3

func _draw_settlement(p: Vector2, rank: int, capital: bool, walled: bool) -> void:
	var ink := Color("#201916")
	var parchment := Color("#e2ca91") if rank < 2 else Color("#cbbd98")
	var radius := float([4.5, 3.4, 2.4, 1.5][rank])
	if walled: draw_arc(p, radius + 2.0, 0.0, TAU, 12, ink, 1.2)
	draw_circle(p, radius + 0.9, ink)
	if capital:
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -radius), p + Vector2(radius, 0), p + Vector2(0, radius), p + Vector2(-radius, 0)]), parchment)
		draw_circle(p, 1.1, ink)
	elif rank == 1:
		draw_rect(Rect2(p - Vector2(radius, radius), Vector2.ONE * radius * 2.0), parchment)
	else:
		draw_circle(p, radius, parchment)
