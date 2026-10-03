extends SceneTree

## GAME-47: prove the *new* Godot viewer consumes only constrained composite
## JSON from genuine original Azgaar worlds; legacy region viewer untouched.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var scene: PackedScene = load("res://scenes/debug/constrained_region_preview.tscn")
	assert(scene != null, "Missing constrained preview Godot scene")
	var viewer: Node2D = scene.instantiate()
	root.add_child(viewer)
	await process_frame
	assert(not viewer.region.is_empty(), "Constrained map did not load its actual output")
	assert(viewer.show_decorations)
	assert(viewer.camera.zoom.x > 0.0)
	for name in [
		"constrained-game-11-determinism-shore",
		"constrained-game-11-determinism-river",
		"constrained-game-11-determinism-highland",
		"constrained-atlas-showcase-shore",
		"constrained-atlas-showcase-river",
		"constrained-atlas-showcase-highland"
	]:
		assert(viewer.load_region("res://tools/regiongen/.tmp/%s.json" % name))
		await process_frame
		var region: Dictionary = viewer.region
		var context: Dictionary = region["source_context"]
		assert(str(region["provider"]["mode"]) == "DECORATIONS_ONLY")
		assert(str(region["constraints"]["source_water_mask"]) == "AZGAAR_LAND_MINUS_LAKES")
		assert(region["landscape"]["procedural_roads_used"] == false)
		assert(region["landscape"]["procedural_water_used"] == false)
		assert(not context["source_burgs"].is_empty(), "Real source hometown missing")
		assert(not context["source_features"].is_empty(), "Real source geography missing")
		assert(str(context["constraints"]["route_protection"]) == "unverified")
		assert(str(context["space"]["physical_km"]) == "UNCALIBRATED")
		var stem: String = "atlas-showcase" if name.contains("atlas") else "game-11-determinism"
		var world := GameWorldTemplate.new()
		assert(world.load_fixture("res://tests/worldgen/fixtures/%s.json" % stem))
		assert(context["parent_source_world_sha256"] == world.source_sha256)
		var home_id: int = int(context["source_home_burg_id"])
		assert(not world.get_record("burg", home_id).is_empty())
		var selected: Dictionary = {}
		for site in context["source_burgs"]:
			if int(site["source_id"]) == home_id:
				selected = site
				break
		assert(not selected.is_empty(), "Real home missing from region burg list")
		var coordinates: Array = selected["local_position"]
		assert(viewer.select_burg_at(Vector2(float(coordinates[0]), float(coordinates[1]))))
		assert(viewer.selected_source_id == home_id)
		assert(viewer.info.text.contains(str(selected["name"])))
		assert(not viewer.select_burg_at(Vector2(-200, -200)))
		assert(viewer.selected_source_id == -1)
	viewer.show_decorations = false
	viewer.queue_redraw()
	await process_frame
	assert(viewer.show_decorations == false)
	assert(not viewer.load_region("res://tools/regiongen/.tmp/not-a-real-region.json"))
	assert(viewer.region.is_empty(), "Missing file did not clear old source geometry")
	print("PASS: GAME-47 Godot source-local preview inspected all 6 original source views without Town Forge roads or invented water")
	quit(0)
