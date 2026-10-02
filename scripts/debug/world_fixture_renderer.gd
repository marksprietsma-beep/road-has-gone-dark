class_name WorldFixtureRenderer
extends Node2D

## Layer coordinator for the development-only fantasy map renderer.
signal cell_selected(cell_id: int, details: String)
signal landmark_selected(marker: Dictionary, details: String)

var model: MapRenderModel
var package: Dictionary
var icon_provider := MapIconProvider.new()
@onready var terrain: TerrainMapLayer = $Terrain
@onready var selection: SelectionMapLayer = $Selection
@onready var vegetation: SvgSidecarMapLayer = $Vegetation
@onready var relief: SvgSidecarMapLayer = $Relief

func display_fixture(world: Dictionary, relief_path: String = "", vegetation_path: String = "") -> void:
	model = MapRenderModel.new(world)
	package = MapRenderBaker.new().bake(model)
	relief.load_sidecar(relief_path)
	vegetation.load_sidecar(vegetation_path)
	for child in get_children():
		if child is MapLayer:
			if child.has_method("set_icon_provider"): child.set_icon_provider(icon_provider)
			child.setup(model)
			if child.has_method("set_package"): child.set_package(package)

func set_layer_enabled(layer_name: String, enabled: bool) -> void:
	var layer := get_node_or_null(NodePath(layer_name))
	if layer: layer.visible = enabled
	# Landmark occupancy depends on the visible civilization/labels.
	if layer_name in ["Settlements", "Labels"]:
		$Landmarks.queue_redraw()

func set_landmark_declutter(enabled: bool) -> void:
	$Landmarks.set_declutter_enabled(enabled)

func set_icon_family(family: String) -> void:
	icon_provider.set_family(family)
	for child in get_children():
		if child.has_method("set_icon_provider"): child.set_icon_provider(icon_provider)

func set_zoom(value: float) -> void:
	var band := 0 if value < 0.7 else (1 if value < 1.65 else 2)
	for child in get_children():
		if child is MapLayer: child.set_zoom_band(band)
		# Recalculate icon spacing after every zoom, not just at band edges.
		if child is LandmarkMapLayer: child.set_display_zoom(value)

func select_at(map_position: Vector2) -> void:
	if package.is_empty() or not Rect2(Vector2.ZERO, Vector2(model.size)).has_point(map_position): return
	# Inspect only glyphs actually drawn in the active layer/zoom, never
	# secret, source-hidden or declutter-suppressed objective markers.
	var landmarks: LandmarkMapLayer = $Landmarks
	var radius := maxf(4.0, 12.0 / maxf(landmarks.display_zoom, 0.25))
	var selected := landmarks.marker_near(map_position, radius)
	landmark_selected.emit(selected, describe_landmark(selected) if not selected.is_empty() else "")
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

func describe_landmark(marker: Dictionary) -> String:
	if marker.is_empty() or bool(marker.get("hidden", false)):
		return ""
	var pieces: PackedStringArray = []
	var kind := str(marker.get("type", "site")).replace("-", " ").capitalize()
	pieces.append("Type: %s" % kind)
	var note := str(marker.get("note", "")).strip_edges()
	if not note.is_empty():
		pieces.append(note)
	var cell := int(marker.get("cell", -1))
	if model.valid_cell(cell):
		var state_id := int(model.states[cell]) if cell < model.states.size() else 0
		var state: Dictionary = model.state_records.get(state_id, {})
		if not state.is_empty():
			pieces.append("State: %s" % str(state.get("name", "Unknown")))
		var cell_data: Dictionary = model.fixture.get("cells", {})
		var province_ids: Array = cell_data.get("province", [])
		if cell < province_ids.size():
			var province_id := int(province_ids[cell])
			for province in model.fixture.get("provinces", []):
				if province is Dictionary and int(province.get("i", -1)) == province_id and province_id != 0:
					pieces.append("Province: %s" % str(province.get("name", "Unknown")))
					break
	var location := Vector2(float(marker.get("x", 0)), float(marker.get("y", 0)))
	var nearest_name := ""
	var nearest_sq := 80.0 * 80.0
	for settlement in model.fixture.get("settlements", []):
		if not settlement is Dictionary or settlement.is_empty():
			continue
		var point := Vector2(float(settlement.get("x", 0)), float(settlement.get("y", 0)))
		var distance_sq := location.distance_squared_to(point)
		if distance_sq < nearest_sq:
			nearest_sq = distance_sq
			nearest_name = str(settlement.get("name", ""))
	if not nearest_name.is_empty():
		pieces.append("Nearby: %s" % nearest_name)
	return "\n".join(pieces)
