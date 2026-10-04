extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func _check() -> void:
	var viewer: Node2D = load("res://scenes/debug/contextual_region_preview.tscn").instantiate()
	root.add_child(viewer)
	await process_frame
	var routes_checked := 0
	for name in viewer.V2_CASES:
		assert(viewer.load_region(viewer.SAMPLE_FOLDER + name + ".json"))
		assert(not viewer.show_route_preview and not viewer.show_hex_grid)
		viewer._unhandled_input(_key(KEY_P))
		assert(viewer.show_route_preview)
		assert(not viewer.show_hex_grid, "P must preserve the independent X setting")
		await process_frame
		var layer: Dictionary = viewer.region.hex_route_preview_v1
		for site in viewer.region.local_sites_v2.sites:
			if str(site.kind) == "hometown":
				continue
			var point := Vector2(float(site.position[0]), float(site.position[1]))
			if str(site.knowledge) in ["hidden", "rumoured"]:
				assert(not viewer.select_local_site_at(point))
				assert(viewer._selected_route_preview().is_empty())
			else:
				assert(viewer.select_local_site_at(point))
				var route: Dictionary = viewer._selected_route_preview()
				assert(str(route.get("site_id", "")) == str(site.id))
				assert(viewer.info.text.contains("ROUTE PREVIEW"))
				assert(viewer.info.text.contains("hours undecided"))
				assert(int(route.route_steps) >= int(route.shortest_steps))
				routes_checked += 1
				await process_frame
		viewer._unhandled_input(_key(KEY_E))
		assert(not viewer.show_route_preview and viewer.show_encounter_demo)
		viewer._unhandled_input(_key(KEY_P))
		assert(viewer.show_route_preview and not viewer.show_encounter_demo)
		viewer._unhandled_input(_key(KEY_P))
		assert(not viewer.show_route_preview)
		var saved: Dictionary = layer.duplicate(true)
		viewer.region.hex_route_preview_v1.source_world_sha256 = "other-world"
		viewer._unhandled_input(_key(KEY_P))
		assert(not viewer.show_route_preview)
		viewer.region.erase("hex_route_preview_v1")
		viewer._unhandled_input(_key(KEY_P))
		assert(not viewer.show_route_preview)
		viewer.region.hex_route_preview_v1 = saved
		viewer._unhandled_input(_key(KEY_P))
		assert(viewer.show_route_preview) # Next load must clear the flag.
	assert(routes_checked >= 10)
	var player: Node2D = load("res://scenes/gameplay/expedition_prototype.tscn").instantiate()
	root.add_child(player)
	await process_frame
	player._unhandled_input(_key(KEY_P))
	assert(not player.show_route_preview and not player._route_preview_available())
	assert(player.expedition.hours == 0 and player.expedition.supplies == 12)
	print("PASS: Godot route preview across six regions, known-only selection, draw frames, context guards, toggle/reset and gameplay isolation")
	quit(0)
