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
		await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		assert(picture != null)
		assert(picture.save_png(viewer.SAMPLE_FOLDER + name + ".godot.png") == OK)
	print("PASS: GAME-57 six actual Godot landscape screenshots")
	quit(0)
