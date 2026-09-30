class_name ReliefMapLayer
extends MapLayer

## Mountain ranges are derived from high-cell clusters, but drawn as overlapping
## cartographic stamps so the source cell graph is never visible.

const MOUNTAIN_HEIGHT := 48.0
const MIN_RANGE_CELLS := 3
const ANCHOR_SPACING := 11.0
const INK := Color("#40382f")
const REAR_INK := Color("#675c4b")
const SHADE := Color("#756650")
const REAR_SHADE := Color("#9a896c")
const PAPER_LIGHT := Color("#cbbb91")

func _draw() -> void:
	if not model:
		return
	var zoom_scale: float = float([1.18, 1.0, 0.76][zoom_band])
	var opacity: float = float([0.9, 0.82, 0.55][zoom_band])
	for cluster in _mountain_clusters():
		_draw_range_stamp(cluster, zoom_scale, opacity)

func _mountain_clusters() -> Array:
	var clusters: Array = []
	var visited := PackedByteArray()
	visited.resize(model.points.size())
	for seed in model.points.size():
		if visited[seed] or not _is_mountain(seed):
			continue
		var cluster: Array[int] = []
		var frontier: Array[int] = [seed]
		visited[seed] = 1
		while not frontier.is_empty():
			var cell_id: int = frontier.pop_back()
			cluster.append(cell_id)
			if cell_id >= model.neighbors.size():
				continue
			var adjacent: Array[int] = []
			for neighbor_value in model.neighbors[cell_id]:
				var neighbor := int(neighbor_value)
				if _is_mountain(neighbor):
					adjacent.append(neighbor)
			for entry: Vector2i in adjacent:
				var neighbor: int = entry.x
				if not visited[neighbor]:
					visited[neighbor] = 1
					frontier.append(neighbor)
		if cluster.size() >= MIN_RANGE_CELLS:
			clusters.append(cluster)
	return clusters

func _is_mountain(cell_id: int) -> bool:
	return model.valid_cell(cell_id) and cell_id < model.heights.size() and float(model.heights[cell_id]) >= MOUNTAIN_HEIGHT

func _draw_range_stamp(cluster: Array, zoom_scale: float, opacity: float) -> void:
	var center := Vector2.ZERO
	for cell_value in cluster:
		center += model.point(int(cell_value))
	center /= float(cluster.size())
	var axis := _dominant_axis(cluster, center)
	var normal := Vector2(-axis.y, axis.x)
	var ordered: Array[Vector3] = []
	for cell_value in cluster:
		var cell_id := int(cell_value)
		var offset := model.point(cell_id) - center
		ordered.append(Vector3(offset.dot(axis), float(cell_id), offset.dot(normal)))
	ordered.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x < b.x)

	var last_projection := -INF
	for sample: Vector3 in ordered:
		var cell_id := int(sample.y)
		var jitter := _signed_hash(cell_id, 17) * 2.2
		if sample.x - last_projection < ANCHOR_SPACING + jitter:
			continue
		last_projection = sample.x
		var anchor := model.point(cell_id) + normal * _signed_hash(cell_id, 29) * 2.5
		var elevation := float(model.heights[cell_id])
		var primary_size := clampf(4.2 + (elevation - MOUNTAIN_HEIGHT) * 0.09, 4.2, 8.2) * zoom_scale
		_draw_peak_group(anchor, axis, normal, primary_size, cell_id, opacity)

func _dominant_axis(cluster: Array, center: Vector2) -> Vector2:
	var xx := 0.0
	var xy := 0.0
	var yy := 0.0
	for cell_value in cluster:
		var offset := model.point(int(cell_value)) - center
		xx += offset.x * offset.x
		xy += offset.x * offset.y
		yy += offset.y * offset.y
	var angle := 0.5 * atan2(2.0 * xy, xx - yy)
	return Vector2(cos(angle), sin(angle)).normalized()

func _draw_peak_group(anchor: Vector2, axis: Vector2, normal: Vector2, size: float, seed: int, opacity: float) -> void:
	# Rear peaks are deliberately lighter and are painted first. Their offsets
	# overlap the dominant foreground peak, forming one broad range silhouette.
	var secondary_count := 1 + posmod(seed * 13, 3)
	for index in secondary_count:
		var side := -1.0 if index % 2 == 0 else 1.0
		var along := side * size * (0.42 + 0.22 * float(index))
		var behind := -normal * size * (0.20 + 0.08 * float(index))
		var secondary_size := size * (0.56 + 0.09 * float(posmod(seed + index, 3)))
		_draw_peak(anchor + axis * along + behind, secondary_size, opacity * 0.68, true)
	_draw_peak(anchor, size, opacity, false)

	# Small side peaks bridge adjacent stamps and remove the dotted-glyph rhythm.
	var bridge_size := size * 0.42
	_draw_peak(anchor - axis * size * 0.72 + normal * size * 0.08, bridge_size, opacity * 0.78, false)
	if posmod(seed * 7, 3) != 0:
		_draw_peak(anchor + axis * size * 0.76 + normal * size * 0.12, bridge_size * 0.86, opacity * 0.72, false)

func _draw_peak(base: Vector2, size: float, opacity: float, rear: bool) -> void:
	var summit := base - Vector2(0.0, size)
	var left := base + Vector2(-size * 0.78, size * 0.42)
	var right := base + Vector2(size * 0.82, size * 0.42)
	var ink := REAR_INK if rear else INK
	var shade := REAR_SHADE if rear else SHADE
	draw_colored_polygon(PackedVector2Array([left, summit, right]), Color(shade, opacity * 0.72))
	draw_polyline(PackedVector2Array([left, summit, right]), Color(ink, opacity), 1.05, true)
	draw_line(summit, base + Vector2(-size * 0.12, size * 0.2), Color(PAPER_LIGHT, opacity * 0.72), 0.75, true)
	draw_line(summit, base + Vector2(size * 0.28, size * 0.42), Color(ink, opacity * 0.8), 0.75, true)

func _signed_hash(value: int, salt: int) -> float:
	return float(posmod(value * 37 + salt * 101, 997)) / 498.0 - 1.0
