extends SceneTree
func _initialize() -> void:
	call_deferred("_verify")
func _verify() -> void:
	var viewer: Node2D = load("res://scenes/debug/local_region_v1.tscn").instantiate()
	root.add_child(viewer)
	await process_frame
	for i in 6:
		viewer.sample_index = i
		viewer.developer_truth = false
		assert(viewer._load_sample())
		assert(viewer.region.export_scope == "PUBLIC_KNOWN_ONLY")
		for site in viewer.region.local_sites_v2.sites:
			assert(site.knowledge in ["discovered", "visited"])
		assert(viewer.region.source_context.parent_cell.local_polygon.size() >= 3)
		var ctx: Dictionary = viewer.region.source_context
		assert(viewer.inspect_at(viewer._point(ctx.space.home_local)))
		viewer.developer_truth = true
		assert(viewer._load_sample())
		assert(viewer.region.export_scope == "DEVELOPER_FULL_TRUTH")
		for code in [KEY_X, KEY_G, KEY_F]:
			var key := InputEventKey.new()
			key.pressed = true
			key.keycode = code
			viewer._unhandled_input(key)
		await process_frame
	for stem in ["game-11-determinism", "atlas-showcase"]:
		assert(viewer.load_region(viewer.SAMPLE_FOLDER + stem + "-neighbour.developer.json"))
		await process_frame
	assert(not viewer.load_region("res://missing-region.json"))
	assert(viewer.region.is_empty())
	assert(viewer.icons.errors.is_empty())
	print("PASS: GAME-62 six Godot scenes, public privacy, inspection, overlays and failed-load reset")
	quit(0)
