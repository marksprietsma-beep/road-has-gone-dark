class_name ReliefMapLayer
extends MapLayer

## Cartographic mountain ranges. High-elevation cells determine the underlying
## geography, but the player-facing artwork is sampled along a smoothed range
## spine so it does not expose cell graphs or stack dozens of mini-ranges.

const MOUNTAIN_HEIGHT := 62.0
const MIN_RANGE_CELLS := 3
const SPINE_BIN_SIZE := 28.0
const STAMPS: Array[Texture2D] = [
	preload("res://assets/map/mountains/range_01.svg"),
	preload("res://assets/map/mountains/range_02.svg"),
	preload("res://assets/map/mountains/range_03.svg"),
	preload("res://assets/map/mountains/range_04.svg"),
	preload("res://assets/map/mountains/range_05.svg"),
	preload("res://assets/map/mountains/range_06.svg"),
	preload("res://assets/map/mountains/range_07.svg"),
	preload("res://assets/map/mountains/range_08.svg"),
	preload("res://assets/map/mountains/range_09.svg"),
	preload("res://assets/map/mountains/range_10.svg"),
]

func _draw() -> void:
	if not model:
		return

	var ranges: Array = _mountain_ranges()
	for range_index in ranges.size():
		var cells: Array = ranges[range_index]
		if cells.size() < MIN_RANGE_CELLS:
			continue

		var spine := _build_spine(cells)
		if spine.size() < 2:
			continue

		_draw_backbone(spine)
		_draw_stamps(spine, range_index)

func _mountain_ranges() -> Array:
	var ranges: Array = []
	var visited: Dictionary = {}

	for start in model.points.size():
		if visited.has(start) or not _is_mountain(start):
			continue

		var cells: Array[int] = []
		var pending: Array[int] = [start]
		visited[start] = true

		while not pending.is_empty():
			var cell_id: int = pending.pop_back()
			cells.append(cell_id)

			if cell_id >= model.neighbors.size() or not model.neighbors[cell_id] is Array:
				continue

			for value in model.neighbors[cell_id]:
				var other := int(value)
				if not visited.has(other) and _is_mountain(other):
					visited[other] = true
					pending.append(other)

		ranges.append(cells)

	return ranges

func _is_mountain(cell_id: int) -> bool:
	return model.valid_cell(cell_id) 		and cell_id < model.heights.size() 		and float(model.heights[cell_id]) >= MOUNTAIN_HEIGHT

func _build_spine(cells: Array) -> PackedVector2Array:
	var center := Vector2.ZERO
	for value in cells:
		center += model.point(int(value))
	center /= float(cells.size())

	# Principal direction gives the broad range orientation.
	var xx := 0.0
	var xy := 0.0
	var yy := 0.0
	for value in cells:
		var delta := model.point(int(value)) - center
		xx += delta.x * delta.x
		xy += delta.x * delta.y
		yy += delta.y * delta.y

	var angle := 0.5 * atan2(2.0 * xy, xx - yy)
	var axis := Vector2.from_angle(angle)

	var low := INF
	var high := -INF
	for value in cells:
		var along := (model.point(int(value)) - center).dot(axis)
		low = minf(low, along)
		high = maxf(high, along)

	var span := maxf(high - low, SPINE_BIN_SIZE)
	var bin_count := maxi(3, int(ceil(span / SPINE_BIN_SIZE)) + 1)
	var sums: Array[Vector2] = []
	var counts: Array[int] = []
	for _index in bin_count:
		sums.append(Vector2.ZERO)
		counts.append(0)

	for value in cells:
		var point := model.point(int(value))
		var along := (point - center).dot(axis)
		var normalized := clampf((along - low) / maxf(high - low, 0.001), 0.0, 0.9999)
		var bin_index := clampi(int(floor(normalized * float(bin_count))), 0, bin_count - 1)
		sums[bin_index] += point
		counts[bin_index] += 1

	var raw := PackedVector2Array()
	for index in bin_count:
		if counts[index] > 0:
			raw.append(sums[index] / float(counts[index]))

	if raw.size() < 3:
		return raw

	# Small moving-average pass preserves bends while removing bin-to-bin kinks.
	var smoothed := PackedVector2Array()
	smoothed.append(raw[0])
	for index in range(1, raw.size() - 1):
		smoothed.append((raw[index - 1] + raw[index] * 2.0 + raw[index + 1]) / 4.0)
	smoothed.append(raw[raw.size() - 1])
	return smoothed

func _draw_backbone(spine: PackedVector2Array) -> void:
	# A narrow, quiet ridge shadow makes separate range stamps read as one landform
	# without the large translucent polygon patches from earlier iterations.
	var outer_alpha: float = float([0.12, 0.10, 0.035][zoom_band])
	var inner_alpha: float = float([0.10, 0.085, 0.03][zoom_band])
	draw_polyline(spine, Color("#43382f", outer_alpha), 8.0 if zoom_band == 0 else 6.0, true)
	draw_polyline(spine, Color("#79664e", inner_alpha), 3.0 if zoom_band == 0 else 2.2, true)

func _draw_stamps(spine: PackedVector2Array, range_index: int) -> void:
	var spacing: float = float([30.0, 34.0, 40.0][zoom_band])
	var base_scale: float = float([0.34, 0.31, 0.27][zoom_band])
	var opacity: float = float([0.96, 0.92, 0.78][zoom_band])

	var anchor_index := 0
	var distance_to_next := spacing * 0.45
	var previous_position := Vector2.ZERO
	var has_previous := false

	for segment_index in range(spine.size() - 1):
		var segment_start := spine[segment_index]
		var segment_end := spine[segment_index + 1]
		var direction := segment_end - segment_start
		var segment_length := direction.length()
		if segment_length <= 0.001:
			continue

		direction /= segment_length
		var normal := Vector2(-direction.y, direction.x)
		var travelled := 0.0

		while travelled + distance_to_next <= segment_length:
			travelled += distance_to_next
			var position := segment_start + direction * travelled

			var seed := _hash(range_index * 4099 + anchor_index * 131)
			var jitter_along := float(posmod(seed, 9) - 4) * 0.55
			var jitter_across := float(posmod(seed >> 6, 9) - 4) * 0.60
			position += direction * jitter_along + normal * jitter_across

			var scale_jitter := 0.90 + float(posmod(seed >> 10, 17)) / 100.0
			_draw_stamp(position, base_scale * scale_jitter, seed, opacity)

			# Bridge the gap with a smaller secondary peak-group. This keeps
			# long ranges visually connected without piling full-size stamps.
			if has_previous:
				var bridge_seed := _hash(seed + 7919)
				var bridge := previous_position.lerp(position, 0.5)
				var bridge_side := -1.0 if posmod(bridge_seed, 2) == 0 else 1.0
				bridge += normal * bridge_side * (2.0 + float(posmod(bridge_seed >> 5, 5)))
				var bridge_scale := base_scale * (0.48 + float(posmod(bridge_seed >> 9, 9)) / 100.0)
				_draw_stamp(bridge, bridge_scale, bridge_seed, opacity * 0.72)

			previous_position = position
			has_previous = true
			anchor_index += 1

			var gap_jitter := float(posmod(seed >> 16, 11) - 5) * 1.0
			distance_to_next = maxf(24.0, spacing + gap_jitter)

		distance_to_next -= maxf(0.0, segment_length - travelled)

func _draw_stamp(position: Vector2, scale_amount: float, seed: int, opacity: float) -> void:
	var texture: Texture2D = STAMPS[seed % STAMPS.size()]
	var flip := -1.0 if ((seed >> 5) & 1) == 1 else 1.0
	var rotation := deg_to_rad(float(posmod(seed >> 11, 5)) - 2.0)
	var size: Vector2 = texture.get_size() * scale_amount

	draw_set_transform(position, rotation, Vector2(flip, 1.0))
	draw_texture_rect(
		texture,
		Rect2(-size * 0.5, size),
		false,
		Color(1.0, 1.0, 1.0, opacity)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _hash(value: int) -> int:
	var mixed := value * 1103515245 + 12345
	mixed = mixed ^ (mixed >> 16)
	return absi(mixed)
