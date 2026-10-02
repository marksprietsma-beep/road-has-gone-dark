extends SceneTree

## Headless smoke test uses the real atlas scene and its authored world fixture.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://scenes/debug/world_fixture_viewer.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var world := scene.get_node("WorldMap") as WorldFixtureRenderer
	var landmarks := scene.get_node("WorldMap/Landmarks") as LandmarkMapLayer
	var settlements := scene.get_node("WorldMap/Settlements") as SettlementMapLayer
	var inspector := scene.get_node("DebugOverlay/LandmarkInspector") as PanelContainer
	var key := scene.get_node("DebugOverlay/MapKey") as MapLandmarkKey
	var layer_options := scene.get_node("DebugOverlay/Layers/Options") as VBoxContainer
	var title := scene.get_node("DebugOverlay/LandmarkInspector/Content/HeadingRow/Title") as Label
	var details := scene.get_node("DebugOverlay/LandmarkInspector/Content/Details") as RichTextLabel
	assert(not inspector.visible, "Inspector must start hidden")
	assert(not layer_options.visible, "Debug layer controls must start collapsed")
	assert(not key.scroll.visible, "Glossary should not obscure the map initially")
	var plain := MapWorldText.plain('<div>You have encountered a character.</div><iframe src="https://deorum.vercel.app/encounter/2831" sandbox="allow-scripts"></iframe>')
	assert(plain == "You have encountered a character.", "Embedded character preview leaked into inspector")
	var effigy := MapWorldText.plain('An ancient effigy. It has an inscription, but no one can translate it: <div style="font-size: 1.8em;">\uFFFD\uFFFD nonsense</div>')
	assert(effigy == "An ancient effigy. It has an inscription, but no one can translate it:", "Illegible inscription should not be shown")
	assert(MapWorldText.plain("A &amp; B") == "A & B", "Entities should be decoded")
	world.set_zoom(2.0)
	await process_frame
	await process_frame
	assert(landmarks.displayed_markers.size() > 0, "Fixture must draw at least one landmark")
	for displayed in landmarks.displayed_markers:
		assert(not bool(displayed.get("hidden", false)), "Hidden source marker leaked into drawn icons")
	var marker: Dictionary = landmarks.displayed_markers[0]
	var pos := Vector2(float(marker.get("x", 0.0)), float(marker.get("y", 0.0)))
	assert(not landmarks.marker_near(pos, 4.0).is_empty(), "Marker hit test missed drawn icon")
	world.select_at(pos)
	assert(inspector.visible, "Selecting a visible marker must show a small inspector")
	assert(title.text == str(marker.get("name", "")) or title.text == str(marker.get("type", "")).replace("-", " ").capitalize())
	assert(details.text.contains("Type:"), "Inspector must show marker's canonical type")
	var note := MapWorldText.plain(str(marker.get("note", "")))
	if not note.is_empty():
		assert(details.text.contains(note), "Inspector must show readable source narrative")
	assert(not details.text.contains("<iframe") and not details.text.contains("<div"), "Raw source HTML leaked into map inspector")
	var key_bounds := key.get_rect()
	var inspector_bounds := inspector.get_rect()
	assert(not key_bounds.intersects(inspector_bounds), "Map Key and inspector panels overlap")
	var layers := scene.get_node("DebugOverlay/Layers") as VBoxContainer
	assert(not layers.get_rect().intersects(inspector_bounds), "Layer controls overlap the inspector")
	key._toggle()
	assert(key.scroll.visible, "Glossary failed to expand")
	assert(not inspector.visible, "Opening glossary must hide inspector")
	world.set_layer_enabled("Landmarks", false)
	assert(landmarks.marker_near(pos, 100.0).is_empty(), "Hidden landmark layer must not be clickable")
	scene.call("_on_layer_toggled", false, "Landmarks")
	assert(not inspector.visible, "Disabling landmark layer must dismiss stale inspect UI")
	world.set_layer_enabled("Landmarks", true)
	world.set_zoom(2.0)
	await process_frame
	assert(settlements.displayed_settlements.size() > 0, "Fixture should draw towns")
	var town: Dictionary = settlements.displayed_settlements[0]
	var center := Vector2(float(town.get("x", 0.0)), float(town.get("y", 0.0)))
	assert(not settlements.settlement_near(center, 4.0).is_empty())
	world.select_at(center)
	assert(inspector.visible, "Clicking visible town should show shared inspector")
	assert(title.text == MapWorldText.plain(str(town.get("name", "Settlement")), 90), "Wrong settlement selected")
	assert(details.text.contains("Population (Azgaar scale)"), "Town inspector missing source population")
	assert(not key.scroll.visible, "Clicking town should close expanded key")
	scene.call("_toggle_dev_layers")
	assert(layer_options.visible, "Developer layer controls should expand on demand")
	scene.call("_toggle_dev_layers")
	assert(not layer_options.visible, "Developer layer controls should collapse")
	world.set_layer_enabled("Settlements", false)
	assert(settlements.settlement_near(center, 100.0).is_empty(), "Hidden settlement sprites cannot be inspected")
	scene.call("_on_layer_toggled", false, "Settlements")
	assert(not inspector.visible, "Disabling settlements must close inspector")
	world.set_layer_enabled("Landmarks", true)
	world.set_zoom(0.2)
	await process_frame
	assert(landmarks.marker_near(pos, 100.0).is_empty(), "Overview mode must not disclose landmarks")
	print("PASS: safe Azgaar text, bounded shared landmark/settlement inspector, hidden/zoom protection and compact developer controls")
	scene.queue_free()
	quit()
