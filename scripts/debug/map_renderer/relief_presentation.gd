class_name ReliefPresentation
extends RefCounted

## Deterministic, renderer-only LOD and ridge projection for generated relief.
## This deliberately consumes only provider-neutral icon placements.

const MOUNTAIN_KINDS := [&"mount", &"mountSnow"]

static func stable_key(icon: Dictionary) -> int:
	var x := int(round(float(icon.get("x", 0.0)) * 10.0))
	var y := int(round(float(icon.get("y", 0.0)) * 10.0))
	var variant := int(icon.get("variant", 1))
	return absi((x * 73856093) ^ (y * 19349663) ^ (variant * 83492791))

static func visible_icons(relief: Array, zoom_band: int) -> Array:
	var mountains: Array = []
	for value in relief:
		if value is Dictionary and StringName(value.get("kind", "")) in MOUNTAIN_KINDS:
			mountains.append(value)

	var result: Array = []
	var occupied: Array[Vector2] = []

	var modulus: int
	var keep_below: int
	var separation: float
	if zoom_band <= 0:
		modulus = 12
		keep_below = 1
		separation = 56.0
	elif zoom_band == 1:
		modulus = 4
		keep_below = 1
		separation = 24.0
	else:
		modulus = 5
		keep_below = 3
		separation = 14.0

	for value in relief:
		if not value is Dictionary:
			continue
		var icon: Dictionary = value
		var kind := StringName(icon.get("kind", ""))

		if kind in MOUNTAIN_KINDS:
			if stable_key(icon) % modulus >= keep_below:
				continue
		elif kind == &"hill":
			# Hills do not appear at fitted overview and are sparse elsewhere.
			if zoom_band <= 0:
				continue
			if stable_key(icon) % (10 if zoom_band == 1 else 5) != 0:
				continue
			if _near_mountain(icon, mountains, 34.0):
				continue
		else:
			continue

		var point := _point(icon)
		if _near_any(point, occupied, separation):
			continue
		occupied.append(point)
		result.append(icon)

	return result

static func ridge_segments(relief: Array, maximum_distance := 76.0) -> Array:
	var mountains: Array = []
	for value in relief:
		if value is Dictionary and StringName(value.get("kind", "")) in MOUNTAIN_KINDS:
			mountains.append(value)
	mountains.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return stable_key(a) < stable_key(b))

	var segments: Array = []
	var used_edges := {}
	for icon in mountains:
		var origin := _point(icon)
		var nearest: Dictionary = {}
		var nearest_distance := maximum_distance
		for candidate in mountains:
			if candidate == icon:
				continue
			var distance := origin.distance_to(_point(candidate))
			if distance < nearest_distance:
				nearest = candidate
				nearest_distance = distance
		if nearest.is_empty():
			continue
		var a := stable_key(icon)
		var b := stable_key(nearest)
		var edge := "%d:%d" % [mini(a, b), maxi(a, b)]
		if used_edges.has(edge):
			continue
		used_edges[edge] = true
		segments.append([origin, _point(nearest)])
	return segments

static func _point(icon: Dictionary) -> Vector2:
	return Vector2(float(icon.get("x", 0.0)), float(icon.get("y", 0.0)))

static func _near_mountain(icon: Dictionary, mountains: Array, distance: float) -> bool:
	var point := _point(icon)
	for mountain in mountains:
		if point.distance_squared_to(_point(mountain)) < distance * distance:
			return true
	return false

static func _near_any(point: Vector2, occupied: Array[Vector2], distance: float) -> bool:
	for other in occupied:
		if point.distance_squared_to(other) < distance * distance:
			return true
	return false
