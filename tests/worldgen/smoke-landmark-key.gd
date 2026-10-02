extends SceneTree

## Headless interaction check for the map key; Godot loads the real atlas scene.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://scenes/debug/world_fixture_viewer.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var key := scene.get_node("DebugOverlay/MapKey") as MapLandmarkKey
	var scroll := scene.get_node("DebugOverlay/MapKey/Layout/Scroll") as ScrollContainer
	var entries := scene.get_node("DebugOverlay/MapKey/Layout/Scroll/Entries")
	var landmarks := scene.get_node("WorldMap/Landmarks") as LandmarkMapLayer
	assert(not scroll.visible, "Map Key must initially be collapsed")
	assert(landmarks.declutter_enabled, "Collision avoidance must default to ON")
	assert(entries.get_child_count() > 36, "Map key must include all 36 icons")
	var first_row := entries.get_child(4) as HBoxContainer
	assert(first_row != null, "No landmark row in glossary")
	var first_icon := first_row.get_child(0) as TextureRect
	assert(first_icon.material is ShaderMaterial, "Legend glyph must use the white-only material")
	var ink_shader := (first_icon.material as ShaderMaterial).shader
	assert(ink_shader.code.contains("vec4(1.0, 1.0, 1.0, source.a)"), "Icon shader must render pure white")
	var labels := first_row.get_child(1) as VBoxContainer
	for label in labels.get_children():
		assert(label is Label)
		assert(label.get_theme_color("font_color") == Color.WHITE, "All glossary text must be white")
	var toggle := scene.get_node("DebugOverlay/MapKey/Layout/Toggle") as Button
	assert(toggle.get_theme_color("font_color") == Color.WHITE, "Legend header must be white")
	key._toggle()
	assert(scroll.visible, "Map Key must expand on demand")
	var qa := entries.get_child(1) as CheckBox
	assert(qa != null, "Missing Show all overlaps QA checkbox")
	qa.button_pressed = true
	assert(not landmarks.declutter_enabled, "QA mode must reveal overlapping markers")
	# Closing the key also clears an accidentally left-on QA toggle.
	key._toggle()
	assert(not scroll.visible, "Map Key must collapse again")
	assert(landmarks.declutter_enabled, "Closing the key must reset QA mode")
	assert(not qa.button_pressed, "QA checkbox must be reset on close")
	key._toggle()
	assert(scroll.visible, "Map Key must reopen")
	qa.button_pressed = true
	assert(not landmarks.declutter_enabled)
	qa.button_pressed = false
	assert(landmarks.declutter_enabled, "Normal mode must restore decluttering")
	key._toggle()
	assert(not scroll.visible)
	print("PASS: Map Key starts collapsed, expands/collapses, and QA overlap switch works")
	scene.queue_free()
	quit()
