extends SceneTree

## Real six-region renderer evidence, without game-world or save writes.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1100, 1100)
	root.content_scale_size = Vector2i(1100, 1100)
	var viewer: Node2D = load("res://scenes/debug/contextual_region_preview.tscn").instantiate()
	root.add_child(viewer)
	await process_frame
	for name in viewer.V2_CASES:
		assert(viewer.load_region(viewer.SAMPLE_FOLDER + name + ".json"))
		viewer.camera.position = Vector2(500, 500)
		viewer.camera.zoom = Vector2.ONE
		viewer.info.hide()
		var suffix: String = ".godot.png"
		if OS.get_cmdline_user_args().has("--encounter-review"):
			var encounter_key := InputEventKey.new()
			encounter_key.keycode = KEY_E
			encounter_key.pressed = true
			viewer._unhandled_input(encounter_key)
			assert(viewer.show_encounter_demo)
			suffix = ".encounter.godot.png"
		if OS.get_cmdline_user_args().has("--hex-review"):
			var key := InputEventKey.new()
			key.keycode = KEY_X
			key.pressed = true
			viewer._unhandled_input(key)
			assert(viewer.show_hex_grid)
			suffix = ".hex.godot.png"
		await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		assert(picture != null)
		assert(picture.save_png(viewer.SAMPLE_FOLDER + name + suffix) == OK)
	print("PASS: GAME-57 six actual Godot landscape screenshots")
	quit(0)
