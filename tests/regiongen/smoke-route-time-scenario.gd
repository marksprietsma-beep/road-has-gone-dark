extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func _check() -> void:
	var fixtures: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tools/regiongen/.tmp/route-time-fixtures.json"))
	assert(fixtures is Array and fixtures.size() >= 48)
	for fixture in fixtures:
		var route: Dictionary = fixture.route
		var original: Dictionary = route.duplicate(true)
		var estimate: Dictionary = RouteTimeScenario.estimate(route, int(fixture.minutes_per_effort))
		# JSON numbers arrive as floats; normalise native integer fields for comparison.
		assert(JSON.parse_string(JSON.stringify(estimate)) == fixture.expected, "Native and SVG timing model disagree")
		assert(route == original, "Timing model mutated a route")
	var viewer: Node2D = load("res://scenes/debug/contextual_region_preview.tscn").instantiate()
	root.add_child(viewer)
	await process_frame
	for name in viewer.V2_CASES:
		assert(viewer.load_region(viewer.SAMPLE_FOLDER + name + ".json"))
		assert(viewer.timing_preset_index == 0)
		var original: Dictionary = viewer.region.duplicate(true)
		viewer._unhandled_input(_key(KEY_BRACKETRIGHT))
		assert(viewer.timing_preset_index == 0, "Inactive preview changed timing")
		viewer._unhandled_input(_key(KEY_P))
		assert(viewer.show_route_preview)
		assert(viewer.route_timing(viewer._selected_route_preview()).status == "UNSET")
		for preset in [15, 30, 60]:
			viewer._unhandled_input(_key(KEY_BRACKETRIGHT))
			var estimate: Dictionary = viewer.route_timing(viewer._selected_route_preview())
			assert(int(estimate.minutes_per_effort) == preset)
			assert(estimate.total_journey_minutes == null)
			if not viewer._selected_route_preview().is_empty():
				assert(viewer.info.text.contains("scenario"))
				assert(viewer.info.text.contains("no rests/crossing delays"))
			await process_frame
		viewer._unhandled_input(_key(KEY_BRACKETRIGHT))
		assert(viewer.timing_preset_index == 3, "Preset must clamp at 60")
		viewer._unhandled_input(_key(KEY_BRACKETLEFT))
		assert(viewer.timing_preset_index == 2)
		viewer._unhandled_input(_key(KEY_0))
		assert(viewer.timing_preset_index == 0)
		viewer._unhandled_input(_key(KEY_BRACKETLEFT))
		assert(viewer.timing_preset_index == 0)
		assert(viewer.region == original, "Timing controls mutated source/generated data")
		viewer._unhandled_input(_key(KEY_BRACKETRIGHT)) # Next region must reset.
	var player: Node2D = load("res://scenes/gameplay/expedition_prototype.tscn").instantiate()
	root.add_child(player)
	await process_frame
	for code in [KEY_P, KEY_BRACKETRIGHT, KEY_BRACKETLEFT, KEY_0]:
		player._unhandled_input(_key(code))
	assert(player.timing_preset_index == 0 and not player.show_route_preview)
	assert(player.expedition.hours == 0 and player.expedition.supplies == 12)
	print("PASS: native/SVG timing parity, six region controls, preset clamps/reset, no source mutation and gameplay isolation")
	quit(0)
