extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/debug/populated_region_preview.tscn")
	assert(packed != null, "GAME-40 populated preview scene missing")
	var viewer: Node2D = packed.instantiate()
	root.add_child(viewer)
	await process_frame
	assert(viewer.region is Dictionary and not viewer.region.is_empty(), "Run Node source generator tests before scene smoke")
	assert(viewer.region.get("provider",{}).get("name","") == "town-forge")
	var sites: Dictionary = viewer.region.get("local_sites", {})
	assert(int(sites.get("site_generation_version", -1)) == 1)
	assert(sites.get("region_id","") == viewer.region.get("id",""))
	assert(str(sites.get("placement","")).begins_with("PROVISIONAL"))
	assert(sites.get("sites",[]).size() >= 5)
	assert(not viewer.reveal_hidden, "Developer-only reveal enabled by default")
	var first: Dictionary = sites["sites"][0]
	assert(first.get("id","") == "burg:"+str(viewer.region["source"]["burg_id"]))
	assert(first.get("provenance","") == "azgaar_burg")
	var source := GameWorldTemplate.new()
	assert(source.load_fixture("res://tests/worldgen/fixtures/game-11-determinism.json"))
	assert(source.source_sha256 == viewer.region["source"]["world_sha256"])
	assert(not source.get_record("burg",int(first.get("source_id", -1))).is_empty())
	var hidden := 0
	for value in sites["sites"]:
		if str(value.get("knowledge","")) == "hidden":
			hidden += 1
			assert(not viewer._visible(value), "Hidden site visible without developer reveal")
		elif str(value.get("knowledge","")) == "rumoured":
			assert(not viewer._visible(value), "Rumour leaked exact location")
	assert(hidden > 0, "No hidden site to test")
	viewer.reveal_hidden = true
	for value in sites["sites"]:
		assert(viewer._visible(value))
	viewer.reveal_hidden = false
	assert(viewer.load_region("res://tools/regiongen/.tmp/populated-coast.json"))
	assert(viewer.region["region"]["terrain"] == "coastal")
	assert(viewer.load_region("res://tools/regiongen/.tmp/populated-mountain.json"))
	assert(viewer.region["region"]["terrain"] == "mountain")
	assert(not viewer.load_region("res://tools/regiongen/.tmp/not-a-real-region.json"))
	assert(viewer.region.is_empty(), "Failed load retained stale sites")
	print("PASS: GAME-40 F6 preview, actual Azgaar burg ID, Godot site labels, privacy and example-switching")
	quit(0)
