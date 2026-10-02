class_name SettlementMapLayer
extends MapLayer

var icon_provider: MapIconProvider

func set_icon_provider(value: MapIconProvider) -> void:
	icon_provider = value
	queue_redraw()

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
		var role := _role_for(settlement)
		var texture := icon_provider.texture_for(role) if icon_provider else null
		if texture:
			_draw_icon(texture, p, 9.0 if capital else (7.5 if major else 6.0))
			continue
		if icon_provider and icon_provider.family != "Procedural":
			_draw_missing_icon(p)
			continue
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

func _role_for(settlement: Dictionary) -> String:
	var group := str(settlement.get("group", ""))
	if group == "caravanserai" or group == "trading_post":
		return "trading"
	if group in MapIconProvider.ROLES:
		return group
	return "capital" if int(settlement.get("capital", 0)) == 1 else "town"

func _draw_icon(texture: Texture2D, center: Vector2, target: float) -> void:
	var source := texture.get_size()
	var size := source * (target / maxf(source.x, source.y))
	draw_texture_rect(texture, Rect2(center - size * 0.5, size), false)

func _draw_missing_icon(center: Vector2) -> void:
	draw_line(center + Vector2(-2, -2), center + Vector2(2, 2), Color("#a8493f"), 1.0)
	draw_line(center + Vector2(2, -2), center + Vector2(-2, 2), Color("#a8493f"), 1.0)
