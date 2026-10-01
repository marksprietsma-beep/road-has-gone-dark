class_name WorldFixtureRenderer
extends Node2D

## Layer coordinator for the development-only fantasy map renderer.
signal cell_selected(cell_id: int, details: String)

var model: MapRenderModel
var package: Dictionary
@onready var terrain: TerrainMapLayer = $Terrain
@onready var selection: SelectionMapLayer = $Selection
@onready var relief: ReliefMapLayer = $Relief

func display_fixture(world: Dictionary, relief_path: String = "") -> void:
	model = MapRenderModel.new(world)
	package = MapRenderBaker.new().bake(model)
	relief.load_sidecar(relief_path)
	for child in get_children():
		if child is MapLayer:
			child.setup(model)
			if child.has_method("set_package"): child.set_package(package)

func set_layer_enabled(layer_name: String, enabled: bool) -> void:
	var layer := get_node_or_null(NodePath(layer_name))
	if layer: layer.visible = enabled

func set_zoom(value: float) -> void:
	var band := 0 if value < 0.7 else (1 if value < 1.65 else 2)
	for child in get_children():
		if child is MapLayer: child.set_zoom_band(band)

func select_at(map_position: Vector2) -> void:
	if package.is_empty() or not Rect2(Vector2.ZERO, Vector2(model.size)).has_point(map_position): return
	var baked_size: Vector2i = package["baked_size"]
	var scale: int = package["pixel_scale"]
	var x := clampi(int(map_position.x / scale), 0, baked_size.x - 1)
	var y := clampi(int(map_position.y / scale), 0, baked_size.y - 1)
	var cell_id: int = package["cell_ids"][y * baked_size.x + x]
	selection.select_cell(cell_id)
	cell_selected.emit(cell_id, _cell_details(cell_id))

func _cell_details(cell_id: int) -> String:
	if not model.valid_cell(cell_id): return ""
	var height := float(model.heights[cell_id])
	var biome_id := int(model.biomes[cell_id]) if cell_id < model.biomes.size() else 0
	var state_id := int(model.states[cell_id]) if cell_id < model.states.size() else 0
	var biome: Dictionary = model.biome_records.get(biome_id, {})
	var state: Dictionary = model.state_records.get(state_id, {})
	return "Cell %d  •  %s  •  elevation %.0f  •  %s" % [cell_id, str(biome.get("name", "Unknown")), height, str(state.get("name", "Unclaimed"))]
