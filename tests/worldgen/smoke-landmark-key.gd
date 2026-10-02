extends SceneTree

## Headless interaction check for the map key; Godot loads the real atlas scene.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var scene := load("res://scenes/debug/world_fixture_viewer.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var key := scene.get_node("DebugOverlay/MapKey")
	var scroll := scene.get_node("DebugOverlay/MapKey/Layout/Scroll")
	var entries := scene.get_node("DebugOverlay/MapKey/Layout/Scroll/Entries")
	var landmarks := scene.get_node("WorldMap/Landmarks")
	assert(not scroll.visible, "Map Key must initially be collapsed")
	assert(landmarks.declutter_enabled, "Collision avoidance must default to ON")
	assert(entries.get_child_count() > 36, "Map key must include all 36 icons")
	key._toggle()
	assert(scroll.visible, "Map Key must expand on demand")
	var qa := entries.get_child(1) as CheckBox
	assert(qa != null, "Missing Show all overlaps QA checkbox")
	qa.button_pressed = true
	assert(not landmarks.declutter_enabled, "QA mode must reveal overlapping markers")
	qa.button_pressed = false
	assert(landmarks.declutter_enabled, "Normal mode must restore decluttering")
	key._toggle()
	assert(not scroll.visible, "Map Key must collapse again")
	print("PASS: Map Key starts collapsed, expands/collapses, and QA overlap switch works")
	scene.queue_free()
	quit()
