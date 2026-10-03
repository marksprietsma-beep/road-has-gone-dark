extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://scenes/debug/local_region_preview.tscn")
	assert(packed != null, "Missing Town Forge preview scene")
	var viewer: Node2D = packed.instantiate()
	root.add_child(viewer)
	await process_frame
	assert(viewer.region is Dictionary and not viewer.region.is_empty(), "Preview did not load the generated JSON fixture")
	assert(int(viewer.region.get("schema_version", -1)) == 1)
	assert(str(viewer.region.get("provider",{}).get("name","")) == "town-forge")
	assert(int(viewer.region.get("source",{}).get("burg_id",0)) > 0)
	assert(viewer.region.get("geometry",{}).get("roads",[]).size() > 0, "Provider emitted no readable road geometry")
	var home_cell := int(viewer.region.get("source",{}).get("cell_id",-1))
	assert(home_cell >= 0)
	assert(viewer.camera.zoom.x > 0.1)
	var origin: String = "res://tests/worldgen/fixtures/game-11-determinism.json"
	var world := GameWorldTemplate.new()
	assert(world.load_fixture(origin), "GAME-7 model cannot load source fixture")
	assert(not world.get_record("cell", home_cell).is_empty())
	assert(not world.get_record("burg", int(viewer.region["source"]["burg_id"])).is_empty())
	assert(viewer.region["source"]["world_sha256"] == world.source_sha256, "GameWorld template and region do not share a world")
	assert(viewer.info.text.contains("Provisional local routes"))
	print("PASS: GAME-21 Godot preview loads Town Forge geometry against GameWorld IDs")
	quit(0)
