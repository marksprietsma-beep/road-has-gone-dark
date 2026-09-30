class_name LineMapLayer
extends MapLayer

enum Kind { RIVERS, ROUTES, BORDERS }
@export var kind := Kind.RIVERS

func _draw() -> void:
	if not model: return
	match kind:
		Kind.RIVERS: _draw_rivers()
		Kind.ROUTES: _draw_routes()
		Kind.BORDERS: _draw_borders()

func _draw_rivers() -> void:
	for river in model.fixture.get("rivers", []):
		if not river is Dictionary: continue
		var line := PackedVector2Array()
		for raw_id in river.get("cells", []):
			var cell_id := int(raw_id)
			if model.valid_cell(cell_id): line.append(model.point(cell_id))
		if line.size() > 1:
			draw_polyline(line, Color("#283a3b", 0.86), clampf(float(river.get("width", 0.4)) * 2.0, 1.0, 2.8), true)
			draw_polyline(line, Color("#657a70", 0.72), clampf(float(river.get("width", 0.4)), 0.6, 1.5), true)

func _draw_routes() -> void:
	if zoom_band == 0: return
	for route in model.fixture.get("routes", []):
		if not route is Dictionary: continue
		var line := PackedVector2Array()
		for value in route.get("points", []):
			if value is Array and value.size() >= 2: line.append(Vector2(float(value[0]), float(value[1])))
		if line.size() > 1:
			draw_polyline(line, Color("#44372b", 0.72), 1.6, true)
			draw_polyline(line, Color("#a98d62", 0.5), 0.65, true)

func _draw_borders() -> void:
	for cell_id in model.points.size():
		if cell_id >= model.states.size() or cell_id >= model.neighbors.size(): continue
		var state_id := int(model.states[cell_id])
		if state_id == 0: continue
		for raw_neighbor in model.neighbors[cell_id]:
			var neighbor := int(raw_neighbor)
			if neighbor > cell_id and neighbor < model.states.size() and int(model.states[neighbor]) != state_id:
				draw_dashed_line(model.point(cell_id), model.point(neighbor), Color("#40352e", 0.64), 1.0, 6.0, true)
