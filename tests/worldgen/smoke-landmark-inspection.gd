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
	var inspector := scene.get_node("DebugOverlay/LandmarkInspector") as PanelContainer
	var title := scene.get_node("DebugOverlay/LandmarkInspector/Content/HeadingRow/Title") as Label
	var details := scene.get_node("DebugOverlay/LandmarkInspector/Content/Details") as RichTextLabel
	assert(not inspector.visible, "Inspector must start hidden")
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
	var note := str(marker.get("note", "")).strip_edges()
	if not note.is_empty():
		assert(details.text.contains(note), "Inspector must use the actual generated note")
	world.set_layer_enabled("Landmarks", false)
	assert(landmarks.marker_near(pos, 100.0).is_empty(), "Hidden landmark layer must not be clickable")
	scene.call("_on_layer_toggled", false, "Landmarks")
	assert(not inspector.visible, "Disabling landmark layer must dismiss stale inspect UI")
	world.set_layer_enabled("Landmarks", true)
	world.set_zoom(0.2)
	await process_frame
	assert(landmarks.marker_near(pos, 100.0).is_empty(), "Overview mode must not disclose landmarks")
	print("PASS: visible-only landmark inspection, exact notes and layer/zoom protection")
	scene.queue_free()
	quit()
