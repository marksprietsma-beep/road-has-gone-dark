extends SceneTree
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	root.size = Vector2i(1200, 1200)
	root.content_scale_size = Vector2i(1200, 1200)
	var viewer: Node2D = load("res://scenes/debug/local_region_v1.tscn").instantiate()
	root.add_child(viewer)
	await process_frame
	for i in 6:
		viewer.sample_index = i
		for developer in [false, true]:
			viewer.developer_truth = developer
			assert(viewer._load_sample())
			viewer.fit_map()
			await process_frame
			await RenderingServer.frame_post_draw
			var suffix: String = ".developer" if developer else ""
			var path: String = viewer.SAMPLE_FOLDER + viewer.SAMPLES[i] + suffix + ".godot.png"
			var image: Image = root.get_texture().get_image()
			if OS.get_cmdline_user_args().has("--verify-render"):
				assert(Image.load_from_file(path).get_data() == image.get_data(), "Rendered pixels changed")
			assert(image.save_png(path) == OK)
	viewer.show_hexes = true
	viewer.show_cell_context = true
	viewer.sample_index = 0
	assert(viewer._load_sample())
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(viewer.SAMPLE_FOLDER + "cell-hex-scale.godot.png") == OK)
	for stem in ["game-11-determinism", "atlas-showcase"]:
		assert(viewer.load_region(viewer.SAMPLE_FOLDER + stem + "-neighbour.developer.json"))
		viewer.info.text = "ADJACENT CELL COMPARISON | " + stem + " | cell " + str(viewer.region.source_context.parent_cell.source_id) + "\nGold: original selected cell • grey: original neighbours • hex pitch: one source unit • no traversability claim"
		viewer.fit_map()
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(viewer.SAMPLE_FOLDER + stem + "-neighbour.godot.png") == OK)
	print("PASS: GAME-62 twelve actual Godot screenshots and source-cell/hex diagnostic")
	quit(0)
