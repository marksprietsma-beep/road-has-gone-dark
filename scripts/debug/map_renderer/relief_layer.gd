class_name ReliefMapLayer
extends MapLayer

## Hand-drawn mountain ranges. High-elevation cell adjacency is used only to
## discover coherent ranges; player-facing relief is rendered from overlapping
## atlas-style range stamps rather than cell graph edges or isolated triangles.

const MOUNTAIN_HEIGHT := 48.0
const MIN_RANGE_CELLS := 3
const ANCHOR_SPACING := 18.0

const RANGE_01: Texture2D = preload("res://assets/map/mountains/range_01.svg")
const RANGE_02: Texture2D = preload("res://assets/map/mountains/range_02.svg")
const RANGE_03: Texture2D = preload("res://assets/map/mountains/range_03.svg")

func _draw() -> void:
	if not model:
		return

	var zoom_scale: float = 1.18 if zoom_band == 0 else (1.0 if zoom_band == 1 else 0.84)
	var opacity: float = 0.92 if zoom_band == 0 else (0.86 if zoom_band == 1 else 0.66)

	for cluster_value in _mountain_clusters():
		var cluster: Array = cluster_value
		_draw_range(cluster, zoom_scale, opacity)

func _mountain_clusters() -> Array:
	var clusters: Array = []
	var visited := PackedByteArray()
	visited.resize(model.points.size())

	for seed in model.points.size():
		if visited[seed] != 0 or not _is_mountain(seed):
			continue

		var cluster: Array[int] = []
		var frontier: Array[int] = [seed]
		visited[seed] = 1

		while not frontier.is_empty():
			var cell_id: int = frontier.pop_back()
			cluster.append(cell_id)

			if cell_id >= model.neighbors.size():
				continue

			for neighbor_value in model.neighbors[cell_id]:
				var neighbor: int = int(neighbor_value)
				if neighbor < 0 or neighbor >= visited.size():
					continue
				if visited[neighbor] == 0 and _is_mountain(neighbor):
					visited[neighbor] = 1
					frontier.append(neighbor)

		if cluster.size() >= MIN_RANGE_CELLS:
			clusters.append(cluster)

	return clusters

func _is_mountain(cell_id: int) -> bool:
	return model.valid_cell(cell_id) \
		and cell_id < model.heights.size() \
		and float(model.heights[cell_id]) >= MOUNTAIN_HEIGHT

func _draw_range(cluster: Array, zoom_scale: float, opacity: float) -> void:
	var center := Vector2.ZERO
	for cell_value in cluster:
		center += model.point(int(cell_value))
	center /= float(cluster.size())

	var axis := _dominant_axis(cluster, center)
	var normal := Vector2(-axis.y, axis.x)

	var ordered: Array = []
	for cell_value in cluster:
		var cell_id: int = int(cell_value)
		var offset := model.point(cell_id) - center
		ordered.append({
			"cell_id": cell_id,
			"along": offset.dot(axis),
			"across": offset.dot(normal),
		})

	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["along"]) < float(b["along"])
	)

	var last_projection := -INF
	var stamp_index := 0

	for sample_value in ordered:
		var sample: Dictionary = sample_value
		var along := float(sample["along"])
		if along - last_projection < ANCHOR_SPACING:
			continue

		var cell_id: int = int(sample["cell_id"])
		var height := float(model.heights[cell_id])
		var across := float(sample["across"]) * 0.32
		var jitter := _signed_hash(cell_id, 31) * 2.2
		var anchor := center + axis * along + normal * (across + jitter)

		var base_size := clampf(7.0 + (height - MOUNTAIN_HEIGHT) * 0.10, 7.0, 10.5)
		var stamp_width := base_size * 5.5 * zoom_scale
		var stamp_height := base_size * 3.25 * zoom_scale

		var texture := _range_texture(stamp_index + cell_id)
		var rect := Rect2(
			anchor - Vector2(stamp_width, stamp_height) * 0.5,
			Vector2(stamp_width, stamp_height)
		)
		draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, opacity))

		# A smaller offset stamp makes long ranges feel layered and continuous
		# instead of like evenly spaced repeated icons.
		if posmod(cell_id * 17, 4) != 0:
			var side := -1.0 if posmod(cell_id, 2) == 0 else 1.0
			var child_anchor := anchor + axis * stamp_width * 0.28 + normal * side * stamp_height * 0.14
			var child_size := Vector2(stamp_width, stamp_height) * 0.72
			var child_rect := Rect2(child_anchor - child_size * 0.5, child_size)
			draw_texture_rect(_range_texture(stamp_index + cell_id + 1), child_rect, false, Color(1.0, 1.0, 1.0, opacity * 0.78))

		last_projection = along
		stamp_index += 1

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

func _range_texture(value: int) -> Texture2D:
	match posmod(value, 3):
		0:
			return RANGE_01
		1:
			return RANGE_02
		_:
			return RANGE_03

func _signed_hash(value: int, salt: int) -> float:
	return float(posmod(value * 37 + salt * 101, 997)) / 498.0 - 1.0
