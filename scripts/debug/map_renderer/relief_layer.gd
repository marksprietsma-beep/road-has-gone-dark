class_name ReliefMapLayer
extends MapLayer

## Cartographic mountain chains derived from high-elevation clusters. Cell adjacency is
## used only to discover ranges; none of the fixture's graph edges are drawn.

const MOUNTAIN_HEIGHT := 48.0
const MIN_RANGE_CELLS := 3
const GLYPH_SPACING := 15.0
const RIDGE_INK := Color("#4a4034", 0.72)
const RIDGE_SHADE := Color("#685a45", 0.34)
const RIDGE_LIGHT := Color("#cbbd91", 0.42)

var _ranges: Array[Dictionary] = []

func setup(value: MapRenderModel) -> void:
	model = value
	_ranges = _build_ranges()
	queue_redraw()

func _draw() -> void:
	# At close zoom the individual symbols compete with local roads and places.
	if not model or zoom_band == 2: return
	for range_data: Dictionary in _ranges:
		var direction: Vector2 = range_data["direction"]
		var glyphs: Array = range_data["glyphs"]
		for glyph_value: Variant in glyphs:
			var glyph: Dictionary = glyph_value
			_draw_mountain(glyph["position"], float(glyph["size"]), direction)

func _build_ranges() -> Array[Dictionary]:
	var ranges: Array[Dictionary] = []
	var visited := {}
	for seed in model.points.size():
		if visited.has(seed) or not _is_high(seed): continue
		var cluster: Array[int] = []
		var pending: Array[int] = [seed]
		visited[seed] = true
		while not pending.is_empty():
			var cell_id: int = pending.pop_back()
			cluster.append(cell_id)
			if cell_id >= model.neighbors.size(): continue
			var adjacent: Variant = model.neighbors[cell_id]
			if not adjacent is Array: continue
			for neighbor_value: Variant in adjacent:
				var neighbor := int(neighbor_value)
				if not visited.has(neighbor) and _is_high(neighbor):
					visited[neighbor] = true
					pending.append(neighbor)
		if cluster.size() >= MIN_RANGE_CELLS:
			var range_data := _make_range(cluster)
			if not range_data.is_empty(): ranges.append(range_data)
	return ranges

func _is_high(cell_id: int) -> bool:
	return model.valid_cell(cell_id) and cell_id < model.heights.size() \
		and float(model.heights[cell_id]) >= MOUNTAIN_HEIGHT

func _make_range(cluster: Array[int]) -> Dictionary:
	var center := Vector2.ZERO
	for cell_id in cluster: center += model.point(cell_id)
	center /= float(cluster.size())

	# Principal component analysis gives the range's broad direction without tracing
	# jagged neighbor-to-neighbor links.
	var xx := 0.0
	var xy := 0.0
	var yy := 0.0
	for cell_id in cluster:
		var offset := model.point(cell_id) - center
		xx += offset.x * offset.x
		xy += offset.x * offset.y
		yy += offset.y * offset.y
	var angle := 0.5 * atan2(2.0 * xy, xx - yy)
	var direction := Vector2(cos(angle), sin(angle)).normalized()
	var normal := Vector2(-direction.y, direction.x)

	var ordered: Array[Dictionary] = []
	for cell_id in cluster:
		var offset := model.point(cell_id) - center
		ordered.append({
			"cell_id": cell_id,
			"along": offset.dot(direction),
			"across": offset.dot(normal),
		})
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["along"]) < float(b["along"]))

	var glyphs: Array[Dictionary] = []
	var last_along := -INF
	for candidate: Dictionary in ordered:
		var along := float(candidate["along"])
		if along - last_along < GLYPH_SPACING: continue
		var cell_id := int(candidate["cell_id"])
		var height := float(model.heights[cell_id])
		# Pull symbols gently toward the principal ridge. This preserves the range's
		# natural breadth while avoiding a dotted copy of cell-centre locations.
		var across := float(candidate["across"]) * 0.38
		var position := center + direction * along + normal * across
		glyphs.append({"position": position, "size": clampf(3.2 + (height - MOUNTAIN_HEIGHT) * 0.075, 3.2, 7.2)})
		last_along = along
	return {"direction": direction, "glyphs": glyphs}

func _draw_mountain(position: Vector2, size: float, range_direction: Vector2) -> void:
	# A tiny deterministic drift keeps repeated peaks hand-drawn rather than stamped.
	var lean := clampf(range_direction.x * 0.16, -0.14, 0.14)
	var summit := position + Vector2(size * lean, -size)
	var left := position + Vector2(-size * 0.82, size * 0.55)
	var right := position + Vector2(size * 0.82, size * 0.55)
	var silhouette := PackedVector2Array([left, summit, right, left])
	draw_colored_polygon(PackedVector2Array([left, summit, right]), RIDGE_SHADE)
	draw_polyline(silhouette, RIDGE_INK, 1.05, true)
	var shoulder := summit.lerp(left, 0.48)
	draw_polyline(PackedVector2Array([summit, shoulder, position + Vector2(-size * 0.08, size * 0.1)]), RIDGE_LIGHT, 0.75, true)
	# A short overlapping foothill makes consecutive glyphs read as one mountain chain.
	draw_polyline(PackedVector2Array([
		position + Vector2(size * 0.18, size * 0.5),
		position + Vector2(size * 0.5, -size * 0.06),
		position + Vector2(size * 0.92, size * 0.5),
	]), Color(RIDGE_INK, 0.52), 0.7, true)
