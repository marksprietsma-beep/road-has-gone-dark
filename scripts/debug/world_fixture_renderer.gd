class_name WorldFixtureRenderer
extends Node2D

## Layer coordinator for the development-only fantasy map renderer.
signal cell_selected(cell_id: int, details: String)
signal landmark_selected(marker: Dictionary, details: String)
signal settlement_selected(settlement: Dictionary, details: String)

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
	$Labels.queue_redraw()

func select_at(map_position: Vector2) -> void:
	if package.is_empty() or not Rect2(Vector2.ZERO, Vector2(model.size)).has_point(map_position): return
	# Inspect only actually drawn glyphs, never a source-hidden site or
	# a glyph removed by zoom/decluttering. When hits compete, choose the
	# nearest physical icon center; a settlement wins an exact tie.
	var landmarks: LandmarkMapLayer = $Landmarks
	var settlements: SettlementMapLayer = $Settlements
	var zoom := maxf(landmarks.display_zoom, 0.25)
	var marker := landmarks.marker_near(map_position, maxf(4.0, 8.0 / zoom))
	var burg := settlements.settlement_near(map_position, maxf(4.0, 8.0 / zoom))
	var chosen_burg := not burg.is_empty()
	if chosen_burg and not marker.is_empty():
		var town_point := Vector2(float(burg.get("x", 0)), float(burg.get("y", 0)))
		var marker_point := Vector2(float(marker.get("x", 0)), float(marker.get("y", 0)))
		chosen_burg = map_position.distance_squared_to(town_point) <= map_position.distance_squared_to(marker_point)
	if chosen_burg:
		set_selected_burg(int(burg.get("i",-1)))
		settlement_selected.emit(burg, describe_settlement(burg))
	else:
		landmark_selected.emit(marker, describe_landmark(marker) if not marker.is_empty() else "")
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
	var kind := MapWorldText.plain(str(marker.get("type", "site")).replace("-", " ").capitalize(), 80)
	pieces.append("Type: %s" % kind)
	# Original Azgaar notes remain in the fixture. Never display embedded
	# iframe HTML or encoded inscriptions in the user-facing inspector.
	var note := MapWorldText.plain(str(marker.get("note", "")))
	if not note.is_empty():
		pieces.append(note)
	pieces.append_array(_area_context(int(marker.get("cell", -1))))
	var nearby := _nearby_settlement(Vector2(float(marker.get("x", 0)), float(marker.get("y", 0))))
	if not nearby.is_empty():
		pieces.append("Nearby: %s" % nearby)
	return "\n".join(pieces)

func describe_settlement(settlement: Dictionary) -> String:
	if settlement.is_empty() or bool(settlement.get("hidden", false)):
		return ""
	var pieces: PackedStringArray = []
	var group := MapWorldText.plain(str(settlement.get("group", "")).replace("_", " ").capitalize(), 64)
	pieces.append("Settlement: %s" % ("Capital" if int(settlement.get("capital", 0)) == 1 else (group if not group.is_empty() else "Town")))
	# Azgaar population is a generator-relative estimate, not a world
	# census in persons, so preserve its units rather than inventing headcount.
	pieces.append("Population (Azgaar scale): %.1f" % float(settlement.get("population", 0.0)))
	pieces.append_array(_area_context(int(settlement.get("cell", -1))))
	if bool(settlement.get("walls", false)):
		pieces.append("Fortifications: walls")
	if bool(settlement.get("citadel", false)):
		pieces.append("Citadel: present")
	if bool(settlement.get("temple", false)):
		pieces.append("Temple: present")
	return "\n".join(pieces)

func _area_context(cell: int) -> PackedStringArray:
	var pieces := PackedStringArray()
	if not model.valid_cell(cell):
		return pieces
	var state_id := int(model.states[cell]) if cell < model.states.size() else 0
	var state: Dictionary = model.state_records.get(state_id, {})
	if state_id != 0 and not state.is_empty():
		pieces.append("State: %s" % MapWorldText.plain(str(state.get("name", "Unknown")), 90))
	var cells: Dictionary = model.fixture.get("cells", {})
	var province_ids: Array = cells.get("province", [])
	if cell < province_ids.size():
		var province_id := int(province_ids[cell])
		if province_id != 0:
			for province in model.fixture.get("provinces", []):
				if province is Dictionary and int(province.get("i", -1)) == province_id:
					pieces.append("Province: %s" % MapWorldText.plain(str(province.get("name", "Unknown")), 90))
					break
	return pieces

func _nearby_settlement(point: Vector2) -> String:
	var name := ""
	var nearest_squared := 80.0 * 80.0
	for settlement in model.fixture.get("settlements", []):
		if not settlement is Dictionary or settlement.is_empty() or bool(settlement.get("hidden", false)):
			continue
		var location := Vector2(float(settlement.get("x", 0)), float(settlement.get("y", 0)))
		var distance_sq := point.distance_squared_to(location)
		if distance_sq < nearest_squared:
			nearest_squared = distance_sq
			name = MapWorldText.plain(str(settlement.get("name", "")), 90)
	return name

func set_selected_burg(id: int) -> void:
	$Settlements.selected_burg_id = id
	$Labels.selected_burg_id = id
	$Settlements.queue_redraw()
	$Landmarks.queue_redraw()
	$Labels.queue_redraw()
