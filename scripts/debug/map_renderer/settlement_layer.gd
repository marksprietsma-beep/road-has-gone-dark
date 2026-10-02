class_name SettlementMapLayer
extends MapLayer

## World-scale burg glyphs. These are symbolic map marks, not generated town
## geometry: detailed towns are owned by the later settlement generator.
## Use Azgaar's own `group` assignment wherever available.
const INK := Color("#3b3026")
const STONE := Color("#c5b38a")
const ROOF := Color("#927a56")
const HIGHLIGHT := Color("#dfc998")

func _draw() -> void:
	if not model: return
	for settlement in model.fixture.get("settlements", []):
		if not settlement is Dictionary or settlement.is_empty(): continue
		if int(settlement.get("removed", 0)) != 0: continue
		var capital := int(settlement.get("capital", 0)) == 1
		var population := float(settlement.get("population", 0.0))
		var group := _burg_group(str(settlement.get("group", "")), capital, population)

		# Keep the quiet wilderness at world-fit zoom. Show important burgs at
		# medium zoom, then allow smaller villages and notable sites up close.
		if zoom_band == 0 and not capital: continue
		if zoom_band == 1 and not capital and group != "city" and population < 4.0: continue
		if zoom_band == 2 and population < 1.4 and not (group in ["fort", "monastery", "caravanserai", "trading_post"]): continue

		var p := Vector2(float(settlement.get("x", 0.0)), float(settlement.get("y", 0.0)))
		match group:
			"capital": _draw_capital(p)
			"city": _draw_city(p)
			"fort": _draw_fort(p)
			"monastery": _draw_monastery(p)
			"caravanserai", "trading_post": _draw_trade_post(p)
			"town": _draw_town(p)
			"village": _draw_village(p)
			_: _draw_hamlet(p)


func _burg_group(provider_group: String, capital: bool, population: float) -> String:
	if capital: return "capital"
	var group := provider_group.to_lower()
	if group in ["city", "town", "village", "hamlet", "fort", "monastery", "caravanserai", "trading_post"]:
		return group
	# Compatibility for older/missing provider groups; these are *display*
	# classes only and do not alter Azgaar's actual burg identity.
	if population >= 7.0: return "city"
	if population >= 3.0: return "town"
	if population >= 1.4: return "village"
	return "hamlet"


func _draw_capital(p: Vector2) -> void:
	# Compact three-tower citadel with a gate: the strongest civilization mark.
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-2.8, -1.0), p + Vector2(2.8, -1.0),
		p + Vector2(2.8, 2.5), p + Vector2(-2.8, 2.5)
	]), INK)
	draw_rect(Rect2(p + Vector2(-2.05, -0.5), Vector2(4.1, 2.4)), STONE)
	for dx in [-2.4, 0.0, 2.4]:
		draw_rect(Rect2(p + Vector2(dx - 0.6, -2.75), Vector2(1.2, 2.4)), INK)
		draw_rect(Rect2(p + Vector2(dx - 0.32, -2.35), Vector2(0.64, 1.15)), HIGHLIGHT)
	draw_rect(Rect2(p + Vector2(-0.55, 0.45), Vector2(1.1, 2.05)), INK)
	draw_circle(p + Vector2(0, -3.1), 0.42, HIGHLIGHT)


func _draw_city(p: Vector2) -> void:
	# Two watchtowers over a gated wall; visibly different from plain houses.
	draw_rect(Rect2(p + Vector2(-2.3, -0.65), Vector2(4.6, 3.0)), INK)
	draw_rect(Rect2(p + Vector2(-1.8, -0.2), Vector2(3.6, 1.95)), STONE)
	for dx in [-1.8, 1.8]:
		draw_rect(Rect2(p + Vector2(dx - 0.55, -2.2), Vector2(1.1, 2.4)), INK)
		draw_rect(Rect2(p + Vector2(dx - 0.25, -1.75), Vector2(0.5, 1.0)), HIGHLIGHT)
	draw_rect(Rect2(p + Vector2(-0.48, 0.6), Vector2(0.96, 1.75)), INK)


func _draw_fort(p: Vector2) -> void:
	# Fortified square with projecting bastions.
	draw_rect(Rect2(p + Vector2(-2.15, -2.15), Vector2(4.3, 4.3)), INK)
	draw_rect(Rect2(p + Vector2(-1.35, -1.35), Vector2(2.7, 2.7)), STONE)
	for dx in [-2.4, 1.45]:
		for dy in [-2.4, 1.45]:
			draw_rect(Rect2(p + Vector2(dx, dy), Vector2(0.95, 0.95)), ROOF)


func _draw_monastery(p: Vector2) -> void:
	# Single chapel and spire, intentionally not a faith-specific emblem.
	draw_rect(Rect2(p + Vector2(-1.55, -0.5), Vector2(3.1, 2.5)), STONE)
	draw_line(p + Vector2(-1.8, -0.5), p + Vector2(0, -2.0), INK, 0.7, true)
	draw_line(p + Vector2(0, -2.0), p + Vector2(1.8, -0.5), INK, 0.7, true)
	draw_line(p + Vector2(0, -1.65), p + Vector2(0, -3.3), INK, 0.7, true)
	draw_circle(p + Vector2(0, -3.3), 0.32, HIGHLIGHT)
	draw_rect(Rect2(p + Vector2(-0.35, 0.5), Vector2(0.7, 1.5)), INK)


func _draw_trade_post(p: Vector2) -> void:
	# Roadside outpost: open-roofed diamond rather than a walled town.
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -2.3), p + Vector2(2.1, 0),
		p + Vector2(0, 2.1), p + Vector2(-2.1, 0)
	]), INK)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -1.35), p + Vector2(1.2, 0),
		p + Vector2(0, 1.1), p + Vector2(-1.2, 0)
	]), STONE)
	draw_circle(p, 0.4, ROOF)


func _draw_town(p: Vector2) -> void:
	# Two adjoining rooftops, not an anonymous route node.
	draw_rect(Rect2(p + Vector2(-2.05, -0.35), Vector2(4.1, 2.15)), STONE)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-2.45, -0.35), p + Vector2(-1.0, -2.25),
		p + Vector2(0.3, -0.35)
	]), INK)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-0.35, -0.35), p + Vector2(1.0, -1.8),
		p + Vector2(2.4, -0.35)
	]), ROOF)
	draw_rect(Rect2(p + Vector2(-0.3, 0.55), Vector2(0.6, 1.25)), INK)


func _draw_village(p: Vector2) -> void:
	# One low cottage; small enough to keep dense rural regions readable.
	draw_rect(Rect2(p + Vector2(-1.15, -0.1), Vector2(2.3, 1.5)), STONE)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-1.45, -0.1), p + Vector2(0, -1.65),
		p + Vector2(1.45, -0.1)
	]), INK)
	draw_rect(Rect2(p + Vector2(-0.27, 0.4), Vector2(0.54, 1.0)), ROOF)


func _draw_hamlet(p: Vector2) -> void:
	# Tiny roofmark rather than a solid black dot.
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-1.0, 0.25), p + Vector2(0, -0.9),
		p + Vector2(1.0, 0.25)
	]), INK)
	draw_line(p + Vector2(-0.75, 0.55), p + Vector2(0.75, 0.55), ROOF, 0.65, true)
