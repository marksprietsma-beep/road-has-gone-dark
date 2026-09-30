class_name WildernessMapLayer
extends MapLayer

const FOREST_NAMES := ["forest", "rainforest", "taiga"]

func _draw() -> void:
	if not model:
		return

	for cell_id in model.points.size():
		if cell_id >= model.biomes.size() or cell_id >= model.heights.size():
			continue
		if float(model.heights[cell_id]) < model.LAND_HEIGHT:
			continue

		var biome: Dictionary = model.biome_records.get(int(model.biomes[cell_id]), {})
		var name := str(biome.get("name", "")).to_lower()

		if _contains_any(name, FOREST_NAMES):
			_draw_forest_cell(cell_id, name)
		elif ("desert" in name or "tundra" in name) and zoom_band > 0 and posmod(cell_id * 31, 29) == 0:
			var p := model.point(cell_id)
			draw_arc(p, 3.0, PI, TAU, 7, Color("#4d4434", 0.32), 0.7)

func _contains_any(value: String, needles: Array) -> bool:
	for needle in needles:
		if needle in value:
			return true
	return false

func _draw_forest_cell(cell_id: int, biome_name: String) -> void:
	# A forest should read as a patch of woodland, not one tree icon per cell.
	# Draw deterministic micro-clusters at a restrained subset of forest cells.
	var density_gate := 13 if zoom_band == 0 else (8 if zoom_band == 1 else 5)
	if posmod(cell_id * 43 + 17, density_gate) != 0:
		return

	var center := model.point(cell_id)
	var cluster_count := 2 if zoom_band == 0 else (3 if zoom_band == 1 else 4)
	var base_size := 1.15 if zoom_band == 0 else (1.65 if zoom_band == 1 else 2.0)

	for index in cluster_count:
		var seed := cell_id * 97 + index * 53
		var offset := Vector2(
			(float(posmod(seed * 37, 17)) - 8.0) * 0.58,
			(float(posmod(seed * 61, 15)) - 7.0) * 0.44
		)
		var scale_jitter := 0.82 + float(posmod(seed, 7)) * 0.055
		var p := center + offset
		if "taiga" in biome_name:
			_draw_conifer(p, base_size * scale_jitter, Color("#31413a", 0.52))
		elif "rainforest" in biome_name:
			_draw_broadleaf(p, base_size * scale_jitter * 1.05, Color("#2f4335", 0.48))
		else:
			if posmod(seed, 3) == 0:
				_draw_broadleaf(p, base_size * scale_jitter, Color("#394939", 0.44))
			else:
				_draw_conifer(p, base_size * scale_jitter, Color("#35463b", 0.46))

func _draw_conifer(p: Vector2, size: float, ink: Color) -> void:
	var crown := PackedVector2Array([
		p + Vector2(-size * 0.9, size * 0.65),
		p + Vector2(0.0, -size * 1.65),
		p + Vector2(size * 0.9, size * 0.65),
	])
	draw_colored_polygon(crown, ink)
	draw_line(
		p + Vector2(0.0, size * 0.35),
		p + Vector2(0.0, size * 1.25),
		Color("#473b30", 0.46),
		maxf(0.45, size * 0.28)
	)

func _draw_broadleaf(p: Vector2, size: float, ink: Color) -> void:
	draw_circle(p + Vector2(0.0, -size * 0.35), size * 0.82, ink)
	draw_circle(p + Vector2(-size * 0.52, 0.0), size * 0.58, ink.darkened(0.05))
	draw_circle(p + Vector2(size * 0.52, 0.0), size * 0.58, ink.darkened(0.03))
	draw_line(
		p + Vector2(0.0, size * 0.2),
		p + Vector2(0.0, size * 1.1),
		Color("#473b30", 0.44),
		maxf(0.45, size * 0.26)
	)
