class_name WorldFixtureRenderer
extends Node2D

## Development-only renderer for the current generated-world fixture shape.
## This deliberately consumes fixture dictionaries directly; it is not GameWorld.

const LAND_HEIGHT := 20.0
const CELL_RADIUS := 6.5

var _world: Dictionary = {}
var _points: Array = []
var _heights: Array = []


func display_fixture(world: Dictionary) -> void:
	_world = world
	var cells: Dictionary = world.get("cells", {})
	_points = cells.get("points", [])
	_heights = cells.get("heights", [])
	queue_redraw()


func _draw() -> void:
	if _world.is_empty():
		return

	_draw_cells()
	_draw_routes()
	_draw_rivers()
	_draw_settlements()


func _draw_cells() -> void:
	for index in mini(_points.size(), _heights.size()):
		var point := _as_vector(_points[index])
		var height := float(_heights[index])
		draw_circle(point, CELL_RADIUS, _height_color(height))


func _draw_routes() -> void:
	for route in _world.get("routes", []):
		if not route is Dictionary:
			continue
		var line := PackedVector2Array()
		for route_point in route.get("points", []):
			line.append(_as_vector(route_point))
		if line.size() > 1:
			draw_polyline(line, Color("8f7650"), 1.4, false)


func _draw_rivers() -> void:
	for river in _world.get("rivers", []):
		if not river is Dictionary:
			continue
		var line := PackedVector2Array()
		for cell_id in river.get("cells", []):
			var index := int(cell_id)
			if index >= 0 and index < _points.size():
				line.append(_as_vector(_points[index]))
		if line.size() > 1:
			var width := clampf(float(river.get("width", 0.5)) * 2.0, 1.0, 3.0)
			draw_polyline(line, Color("65b7d8"), width, false)


func _draw_settlements() -> void:
	for settlement in _world.get("settlements", []):
		if not settlement is Dictionary:
			continue
		var position := Vector2(float(settlement.get("x", 0.0)), float(settlement.get("y", 0.0)))
		var is_capital := int(settlement.get("capital", 0)) == 1
		var radius := 3.2 if is_capital else 2.0
		draw_circle(position, radius + 1.0, Color("201b19"))
		draw_circle(position, radius, Color("ffd166") if is_capital else Color("f2e8cf"))


func _height_color(height: float) -> Color:
	if height < LAND_HEIGHT:
		var depth := clampf(height / LAND_HEIGHT, 0.0, 1.0)
		return Color("183a59").lerp(Color("28627c"), depth)

	var elevation := clampf((height - LAND_HEIGHT) / 80.0, 0.0, 1.0)
	if elevation < 0.45:
		return Color("577a45").lerp(Color("8d9857"), elevation / 0.45)
	if elevation < 0.78:
		return Color("8d9857").lerp(Color("8b6d4f"), (elevation - 0.45) / 0.33)
	return Color("8b6d4f").lerp(Color("ddd6c2"), (elevation - 0.78) / 0.22)


func _as_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
