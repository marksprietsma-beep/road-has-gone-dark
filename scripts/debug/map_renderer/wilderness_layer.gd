class_name WildernessMapLayer
extends MapLayer

const FOREST_NAMES := ["forest", "rainforest", "taiga"]

func _draw() -> void:
	if not model: return
	for cell_id in model.points.size():
		if cell_id >= model.biomes.size() or cell_id >= model.heights.size(): continue
		if float(model.heights[cell_id]) < model.LAND_HEIGHT: continue
		var biome: Dictionary = model.biome_records.get(int(model.biomes[cell_id]), {})
		var name := str(biome.get("name", "")).to_lower()
		if _contains_any(name, FOREST_NAMES) and posmod(cell_id * 43, 17) < (3 if zoom_band > 0 else 1):
			_draw_tree(model.point(cell_id), 1.5 if zoom_band == 0 else 2.2)
		elif ("desert" in name or "tundra" in name) and zoom_band > 0 and posmod(cell_id * 31, 29) == 0:
			var p := model.point(cell_id)
			draw_arc(p, 3.0, PI, TAU, 7, Color("#4d4434", 0.38), 0.8)

func _contains_any(value: String, needles: Array) -> bool:
	for needle in needles:
		if needle in value: return true
	return false

func _draw_tree(p: Vector2, size: float) -> void:
	var ink := Color("#25382f", 0.62)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-size, size), p + Vector2(0, -size * 1.8), p + Vector2(size, size)]), ink)
	draw_line(p + Vector2(0, size * 0.5), p + Vector2(0, size * 1.7), Color("#3b3027", 0.6), 0.7)
