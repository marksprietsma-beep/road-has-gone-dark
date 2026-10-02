extends Node

## Standalone development tool. It is intentionally not linked from New Game.
const FIXTURE_PATH := "res://tests/worldgen/fixtures/game-11-determinism.json"
const SHOWCASE_FIXTURE_PATH := "res://tests/worldgen/fixtures/atlas-showcase.json"
const PAN_SPEED := 520.0
const MIN_ZOOM := 0.25
const MAX_ZOOM := 4.0
const ZOOM_STEP := 1.2

@onready var map_renderer: WorldFixtureRenderer = $WorldMap
@onready var camera: Camera2D = $WorldCamera
@onready var info_label: Label = $DebugOverlay/InfoPanel/Margin/Info
@onready var selection_label: Label = $DebugOverlay/Selection
var _world_size := Vector2(1280, 800)
var _dragging := false
var _fixture_paths: Array[String] = [FIXTURE_PATH]
var _fixture_index := 0

func _ready() -> void:
	if FileAccess.file_exists(SHOWCASE_FIXTURE_PATH):
		_fixture_paths.append(SHOWCASE_FIXTURE_PATH)
	map_renderer.cell_selected.connect(func(_id: int, details: String) -> void: selection_label.text = details)
	for button in get_tree().get_nodes_in_group("map_layer_toggle"):
		button.toggled.connect(_on_layer_toggled.bind(button.name))
	_load_fixture(_fixture_index)

func _load_fixture(index: int) -> void:
	_fixture_index = clampi(index, 0, _fixture_paths.size() - 1)
	var path := _fixture_paths[_fixture_index]
	var world := WorldFixtureLoader.new().load_fixture(path)
	if world.is_empty():
		info_label.text = "FANTASY MAP VIEWER\nERROR: fixture unavailable\n%s" % path
		return
	var map_data: Dictionary = world.get("map", {})
	_world_size = Vector2(float(map_data.get("width", 1280)), float(map_data.get("height", 800)))
	var sidecar_base := path.trim_suffix(".json")
	map_renderer.display_fixture(world, sidecar_base + ".relief.svg", sidecar_base + ".vegetation.svg")
	selection_label.text = "Click a map cell to inspect it"
	info_label.text = _build_info(world)
	camera.position = _world_size * 0.5
	_fit_map()

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO: camera.position += direction * PAN_SPEED * delta / camera.zoom.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE: _dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT: map_renderer.select_at(get_viewport().get_canvas_transform().affine_inverse() * event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP: _zoom_about_cursor(camera.zoom.x * ZOOM_STEP, event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _zoom_about_cursor(camera.zoom.x / ZOOM_STEP, event.position)
	elif event is InputEventMouseMotion and _dragging: camera.position -= event.relative / camera.zoom.x
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F: camera.position = _world_size * 0.5; _fit_map()
		elif event.keycode == KEY_N and _fixture_paths.size() > 1: _load_fixture((_fixture_index + 1) % _fixture_paths.size())
		elif event.keycode == KEY_ESCAPE: get_tree().quit()

func _zoom_about_cursor(value: float, cursor: Vector2) -> void:
	var before := get_viewport().get_canvas_transform().affine_inverse() * cursor
	_set_zoom(value)
	var after := get_viewport().get_canvas_transform().affine_inverse() * cursor
	camera.position += before - after

func _set_zoom(value: float) -> void:
	var limited := clampf(value, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(limited, limited)
	map_renderer.set_zoom(limited)

func _fit_map() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_set_zoom(minf(viewport_size.x / _world_size.x, viewport_size.y / _world_size.y) * 0.92)

func _on_layer_toggled(enabled: bool, layer_name: String) -> void:
	map_renderer.set_layer_enabled(layer_name, enabled)

func _build_info(world: Dictionary) -> String:
	var fixture_hint := "\nN: next fixture" if _fixture_paths.size() > 1 else ""
	return "FANTASY MAP • DEV VIEW\nSeed  %s\n%d states  •  %d settlements%s" % [str(world.get("seed", "unknown")), world.get("states", []).size() - 1, world.get("settlements", []).size() - 1, fixture_hint]
