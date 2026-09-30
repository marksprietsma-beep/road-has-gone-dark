class_name ReliefMapLayer
extends MapLayer

## Cartographic mountain ranges. High cells only decide where a range belongs;
## the rendered backbone and stamps deliberately do not trace the cell graph.

const MOUNTAIN_HEIGHT := 62.0
const MIN_RANGE_CELLS := 3
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
		var geometry: Dictionary = _range_geometry(cells)
		_draw_massif(geometry, range_index)
		_draw_stamps(geometry, range_index)


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
	return model.valid_cell(cell_id) and cell_id < model.heights.size() and float(model.heights[cell_id]) >= MOUNTAIN_HEIGHT


func _range_geometry(cells: Array) -> Dictionary:
	var center := Vector2.ZERO
	var average_height := 0.0
	for value in cells:
		var cell_id := int(value)
		center += model.point(cell_id)
		average_height += float(model.heights[cell_id])
	center /= float(cells.size())
	average_height /= float(cells.size())

	# Principal component gives one smooth atlas axis instead of cell-to-cell links.
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
	var normal := Vector2(-axis.y, axis.x)
	var low := 0.0
	var high := 0.0
	var spread := 0.0
	for value in cells:
		var delta := model.point(int(value)) - center
		var along := delta.dot(axis)
		low = minf(low, along)
		high = maxf(high, along)
		spread = maxf(spread, absf(delta.dot(normal)))
	return {
		"center": center,
		"axis": axis,
		"normal": normal,
		"angle": angle,
		"start": low - 8.0,
		"end": high + 8.0,
		"width": clampf(spread * 0.55 + 8.0, 9.0, 27.0),
		"height": average_height,
	}


func _draw_massif(geometry: Dictionary, range_index: int) -> void:
	var center: Vector2 = geometry["center"]
	var axis: Vector2 = geometry["axis"]
	var normal: Vector2 = geometry["normal"]
	var start: float = geometry["start"]
	var finish: float = geometry["end"]
	var width: float = geometry["width"]
	var steps := maxi(8, int((finish - start) / 12.0))
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for step in steps + 1:
		var t := float(step) / float(steps)
		var taper := sin(t * PI)
		var wobble := sin(t * 13.0 + float(range_index) * 1.71) * width * 0.10
		var half_width := width * (0.16 + taper * 0.84)
		var spine := center + axis * lerpf(start, finish, t) + normal * wobble
		upper.append(spine + normal * half_width)
		lower.append(spine - normal * half_width)
	var mass: PackedVector2Array = upper.duplicate()
	for lower_index in range(lower.size() - 1, -1, -1):
		mass.append(lower[lower_index])
	var mass_alpha: float = float([0.25, 0.29, 0.32][zoom_band])
	draw_colored_polygon(mass, Color("#332b25", mass_alpha))
	# A warmer inner wash makes separate stamps merge into a single landform.
	var inner := PackedVector2Array()
	for step in steps + 1:
		var t := float(step) / float(steps)
		inner.append(center + axis * lerpf(start, finish, t) + normal * sin(t * 11.0 + range_index) * width * 0.07)
	draw_polyline(inner, Color("#665747", mass_alpha * 0.82), maxf(3.0, width * 0.42), true)


func _draw_stamps(geometry: Dictionary, range_index: int) -> void:
	var center: Vector2 = geometry["center"]
	var axis: Vector2 = geometry["axis"]
	var normal: Vector2 = geometry["normal"]
	var start: float = geometry["start"]
	var finish: float = geometry["end"]
	var angle: float = geometry["angle"]
	var length := finish - start
	var cursor := start
	var anchor := 0
	while cursor <= finish:
		var seed := _hash(range_index * 4099 + anchor * 131)
		var t := clampf((cursor - start) / maxf(length, 1.0), 0.0, 1.0)
		var strength := 0.34 + 0.66 * sin(t * PI)
		var base_scale := (0.72 + float(seed % 23) / 100.0) * (0.78 + strength * 0.34)
		var side := (float((seed >> 7) % 17) - 8.0) * 0.48 * strength
		var position := center + axis * cursor + normal * side
		_draw_stamp(position, angle, base_scale, seed, strength, 1.0)

		# Strong sections get a rear/side cluster, offset enough to merge silhouettes.
		if strength > 0.58 and seed % 5 != 0:
			var rear_seed := _hash(seed + 7919)
			var rear_position := position - axis * (5.0 + float(rear_seed % 7)) + normal * (7.0 + float(rear_seed % 8))
			_draw_stamp(rear_position, angle, base_scale * 0.72, rear_seed, strength, 0.72)

		# Irregular overlap: central anchors are denser; ends naturally taper out.
		var gap := lerpf(23.0, 14.0, strength) + float(seed % 9) - 4.0
		cursor += maxf(10.0, gap)
		anchor += 1


func _draw_stamp(position: Vector2, angle: float, scale_amount: float, seed: int, strength: float, depth: float) -> void:
	var texture: Texture2D = STAMPS[seed % STAMPS.size()]
	var flip := -1.0 if ((seed >> 5) & 1) == 1 else 1.0
	var rotation := deg_to_rad(float((seed >> 11) % 9) - 4.0)
	var zoom_scale: float = float([1.12, 1.0, 0.82][zoom_band])
	var opacity: float = float([0.98, 0.94, 0.76][zoom_band]) * depth
	var size: Vector2 = texture.get_size() * scale_amount * zoom_scale
	draw_set_transform(position, rotation, Vector2(flip, 1.0))
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, Color(1.0, 1.0, 1.0, opacity * (0.86 + strength * 0.14)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _hash(value: int) -> int:
	# Stable integer mixing; independent of frame order and the global RNG.
	var mixed := value * 1103515245 + 12345
	mixed = mixed ^ (mixed >> 16)
	return absi(mixed)
