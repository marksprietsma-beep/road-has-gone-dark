extends Node2D

## DEVELOPMENT VIEWER ONLY. The canonical region JSON owns geometry; the
## SVG preview and this renderer do not own travel routes or gameplay state.
const PREVIEW_PATH := "res://tools/regiongen/.tmp/first.json"
const CASES := ["first", "coast", "river", "mountain", "estuary", "second-world"]
const BG := Color("#b5af93")
var region: Dictionary = {}
@onready var camera: Camera2D = $Camera2D
@onready var info: Label = $HUD/Help

func _ready() -> void:
	camera.position = Vector2(500,500)
	fit_region()
	load_region(PREVIEW_PATH)

func load_region(path: String) -> bool:
	region.clear()
	queue_redraw()
	if not FileAccess.file_exists(path):
		info.text = "GAME-21 Town Forge | No preview: run node tests/regiongen/verify-region.mjs"
		return false
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		info.text = "GAME-21 Town Forge | Preview cannot be opened"
		return false
	var parsed := JSON.new()
	var result := parsed.parse(file.get_as_text())
	file.close()
	if result != OK or not parsed.data is Dictionary:
		info.text = "GAME-21 Town Forge | Invalid region JSON"
		return false
	var data: Dictionary = parsed.data
	if int(data.get("schema_version",-1)) != 1 or str(data.get("provider",{}).get("name","")) != "town-forge":
		info.text = "GAME-21 Town Forge | Unsupported region/provider version"
		return false
	region = data
	var source: Dictionary = region.get("source",{})
	var meta: Dictionary = region.get("region",{})
	info.text = "REGION PREVIEW | Azgaar cell %s  •  Town Forge %s  •  %s km conceptual span\n1–6: examples  |  F: fit  |  ARROWS: pan  |  WHEEL: zoom\nProvisional local routes (not authoritative travel)" % [str(source.get("cell_id","?")),str(meta.get("terrain","?")),str(meta.get("side_km","?"))]
	if region.get("constraints",{}).get("rivers","") == "source_river_not_rendered":
		info.text += "\nWARNING: source river exists; river mouth is not generated in this shoreline preview"
	queue_redraw()
	return true

func fit_region() -> void:
	camera.position = Vector2(500,500)
	var size := get_viewport_rect().size
	var factor := clampf(minf(size.x / 1120.0, (size.y - 150.0) / 1120.0),0.15,1.8)
	camera.zoom = Vector2(factor,factor)

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if direction.length_squared() > 0.0:
		camera.position += direction * 380.0 * delta / maxf(camera.zoom.x,0.1)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			fit_region()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			load_region("res://tools/regiongen/.tmp/%s.json" % CASES[event.keycode - KEY_1])
			fit_region()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.15
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom /= 1.15
		camera.zoom = camera.zoom.clamp(Vector2(0.15,0.15),Vector2(1.8,1.8))

func _points(items: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in items:
		if point is Array and point.size() >= 2:
			result.append(Vector2(float(point[0]),float(point[1])))
	return result

func _draw() -> void:
	draw_rect(Rect2(0,0,1000,1000),BG)
	if region.is_empty(): return
	var geometry: Dictionary = region.get("geometry",{})
	for forest in geometry.get("forests",[]):
		var pts := _points(forest)
		if pts.size()>=3:
			draw_colored_polygon(pts,Color("#536b48",0.7))
	var water := _points(geometry.get("water",[]))
	if water.size()>=3:
		draw_colored_polygon(water,Color("#71989e"))
	for ridge in geometry.get("ridges",[]):
		var pts := _points(ridge)
		if pts.size()>1:
			draw_polyline(pts,Color("#7b6853"),4.0,true)
	for road in geometry.get("roads",[]):
		if not road is Dictionary: continue
		var pts := _points(road.get("points",[]))
		if pts.size()>1:
			draw_polyline(pts,Color("#554b3c"),7.0,true)
			draw_polyline(pts,Color("#c9b889"),4.0,true)
	draw_rect(Rect2(0,0,1000,1000),Color("#322e28"),false,2.0)
