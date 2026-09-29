extends Node

## Standalone development tool. It is intentionally not linked from New Game.

const FIXTURE_PATH := "res://tests/worldgen/fixtures/game-11-determinism.json"
const PAN_SPEED := 520.0
const MIN_ZOOM := 0.25
const MAX_ZOOM := 4.0
const ZOOM_STEP := 1.2

@onready var map_renderer: WorldFixtureRenderer = $WorldMap
@onready var camera: Camera2D = $WorldCamera
@onready var info_label: Label = $DebugOverlay/Panel/Margin/Info
@onready var help_label: Label = $DebugOverlay/Help

var _world_size := Vector2(1280.0, 800.0)
var _dragging := false


func _ready() -> void:
	var world := _load_fixture()
	if world.is_empty():
		return

	var map_data: Dictionary = world.get("map", {})
	_world_size = Vector2(float(map_data.get("width", 1280)), float(map_data.get("height", 800)))
	map_renderer.display_fixture(world)
	info_label.text = _build_info(world)
	camera.position = _world_size * 0.5
	_fit_map()


func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction != Vector2.ZERO:
		camera.position += direction.normalized() * PAN_SPEED * delta / camera.zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x * ZOOM_STEP)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x / ZOOM_STEP)
	elif event is InputEventMouseMotion and _dragging:
		camera.position -= event.relative / camera.zoom.x
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			camera.position = _world_size * 0.5
			_fit_map()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()


func _load_fixture() -> Dictionary:
	var file := FileAccess.open(FIXTURE_PATH, FileAccess.READ)
	if file == null:
		_show_error("Could not open fixture: %s" % FIXTURE_PATH)
		return {}

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		_show_error("JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return {}

	var parsed: Variant = json.data
	if not parsed is Dictionary:
		_show_error("Fixture is not a JSON object: %s" % FIXTURE_PATH)
		return {}
	return parsed


func _build_info(world: Dictionary) -> String:
	var generator: Dictionary = world.get("generator", {})
	return "WORLD FIXTURE DEBUG VIEW\nSeed: %s\nGenerator: %s %s\nStates: %d\nSettlements: %d\nRivers: %d\nRoutes: %d" % [
		str(world.get("seed", "unknown")),
		str(generator.get("provider", "unknown")),
		str(generator.get("version", "unknown")),
		world.get("states", []).size(),
		_count_records(world.get("settlements", [])),
		_count_records(world.get("rivers", [])),
		_count_records(world.get("routes", [])),
	]


func _count_records(collection: Array) -> int:
	var count := 0
	for item in collection:
		if item is Dictionary:
			count += 1
	return count


func _fit_map() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var scale := minf(viewport_size.x / _world_size.x, viewport_size.y / _world_size.y) * 0.92
	_set_zoom(scale)


func _set_zoom(value: float) -> void:
	var limited := clampf(value, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(limited, limited)


func _show_error(message: String) -> void:
	push_error(message)
	info_label.text = "WORLD FIXTURE DEBUG VIEW\n\nERROR\n%s" % message
	help_label.text = "Press Escape to close"
