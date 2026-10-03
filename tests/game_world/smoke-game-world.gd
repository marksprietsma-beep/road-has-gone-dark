extends SceneTree

const SOURCE := "res://tests/worldgen/fixtures/game-11-determinism.json"
const ALT := "res://tests/worldgen/fixtures/atlas-showcase.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := GameWorldTemplate.new()
	assert(world.load_fixture(SOURCE), "Could not load real world fixture: " + world.error)
	assert(world.seed == "game-11-determinism")
	assert(world.source_sha256.length() == 64)
	assert(world.raw_counts()["cells"] > 5000)
	assert(world.get_record("state", -1).is_empty())
	assert(world.entity_id("burg", 999999).is_empty())
	var original_sha := FileAccess.get_sha256(SOURCE)
	var first_world_id := world.world_id
	var candidate: Dictionary = {}
	var region := -1
	for sid in range(1, 1000):
		var options := world.home_candidates(sid)
		if not options.is_empty():
			region = sid
			candidate = options[0]
			break
	assert(region > 0, "No source-backed small hometown found")
	assert(world.validate_origin(region, int(candidate["id"])))
	assert(not world.validate_origin(region, -1))
	assert(world.home_candidates(0).is_empty())
	assert(world.home_candidates(999999).is_empty())
	assert(world.home_candidates(region) == world.home_candidates(region), "Candidate ranking must be deterministic")
	assert(candidate["road_access"] == "unknown" and candidate["outside_protection"] == "unverified")
	assert(world.entity_id("burg", int(candidate["id"])) == candidate["stable_id"])
	var burg := world.get_record("burg", int(candidate["id"]))
	burg["name"] = "Temporarily renamed for smoke test"
	assert(world.get_record("burg", int(candidate["id"])).get("name", "") != burg["name"], "World lookups must be defensive copies")
	assert(world.world_id == first_world_id, "Display rename changed stable world identity")
	var same_world := GameWorldTemplate.new()
	assert(same_world.load_fixture(SOURCE))
	assert(same_world.world_id == world.world_id)
	var other_world := GameWorldTemplate.new()
	assert(other_world.load_fixture(ALT), "Second Azgaar fixture invalid: " + other_world.error)
	assert(other_world.world_id != world.world_id, "Independent canonical worlds share fingerprint")

	var store := GamePlaythroughStore.new()
	store.save_root = "user://game7-smoke-saves"
	var root_path := ProjectSettings.globalize_path(store.save_root)
	DirAccess.make_dir_recursive_absolute(root_path)
	for slot in ["first", "second", "corrupt", "unsupported"]:
		for ext in [".json", ".json.bak", ".json.tmp"]:
			DirAccess.remove_absolute(root_path.path_join(slot + ext))
	var a := store.create_playthrough(world, region, int(candidate["id"]))
	var b := store.create_playthrough(world, region, int(candidate["id"]))
	assert(a["ok"] and b["ok"], "Could not create independent playthroughs")
	var state_a: Dictionary = a["state"]
	var state_b: Dictionary = b["state"]
	assert(state_a["playthrough_id"] != state_b["playthrough_id"])
	assert(state_a["characters"].size() == 3 and state_b["characters"].size() == 3)
	assert(state_a["characters"][0]["id"] != state_b["characters"][0]["id"])
	assert(state_a["world_ref"] == state_b["world_ref"])
	assert(state_a["origin"]["home_id"] == candidate["stable_id"])
	assert(state_a["player_knowledge"]["discovered_poi_ids"].is_empty(), "Objective POIs leaked into initial knowledge")
	assert(state_a["player_knowledge"]["rumoured_poi_ids"].is_empty())
	assert(state_a["player_knowledge"]["visited_poi_ids"].is_empty())
	assert(world.objective_marker_count() > 0)

	# Knowledge of a particular site is an explicit *mutable game event*,
	# independent of objective source existence, not a map-fixture default.
	var poi_id := ""
	for p in range(1, world.objective_marker_count() + 3):
		if not world.get_record("poi", p).is_empty():
			poi_id = world.entity_id("poi", p)
			break
	assert(not poi_id.is_empty(), "Fixture lacks referenceable POIs")
	state_a["player_knowledge"]["discovered_poi_ids"].append(poi_id)
	state_a["world_deltas"]["test_event"] = {"outcome": "investigated"}
	state_a["game_clock"]["tick"] = 41
	assert(store.save_new("first", state_a, world)["ok"], store.error)
	assert(store.save_new("second", state_b, world)["ok"], store.error)
	assert(not store.save_new("first", state_a, world)["ok"], "Save unexpectedly overwritten")
	assert(not store.save_new("../first", state_a, world)["ok"], "Unsafe slot name accepted")
	assert(not store.save_new("bad/slash", state_a, world)["ok"])

	var load_a := store.load_save("first", world)
	var load_b := store.load_save("second", world)
	assert(load_a["ok"] and load_b["ok"], store.error)
	assert(load_a["state"]["game_clock"]["tick"] == 41)
	assert(load_b["state"]["game_clock"]["tick"] == 0)
	assert(load_a["state"]["player_knowledge"]["discovered_poi_ids"] == [poi_id])
	assert(load_b["state"]["player_knowledge"]["discovered_poi_ids"].is_empty())
	assert(load_b["state"]["world_deltas"].is_empty())
	assert(load_a["state"]["characters"][0]["id"] == state_a["characters"][0]["id"])
	assert(load_a["state"]["origin"]["home_burg_id"] == candidate["id"])
	assert(not store.load_save("first", other_world)["ok"], "Cross-world save was loaded")
	assert(not store.load_save("missing", world)["ok"])

	# Save existing succeeds through a temporary + backup write while a new
	# save never overwrites. Opening the same world again changes neither slot.
	state_a["game_clock"]["tick"] = 42
	assert(store.save_existing("first", state_a, world)["ok"])
	assert(store.load_save("first", world)["state"]["game_clock"]["tick"] == 42)
	assert(store.load_save("second", world)["state"]["game_clock"]["tick"] == 0)
	assert(not store.save_existing("absent", state_a, world)["ok"])
	var broken := state_a.duplicate(true)
	broken["save_version"] = 999
	assert(not store.save_existing("first", broken, world)["ok"])
	var wrong_province := state_a.duplicate(true)
	wrong_province["origin"]["province_id"] = -999
	assert(not store.save_existing("first", wrong_province, world)["ok"], "Invalid province identity accepted")
	assert(store.load_save("first", world)["ok"], "Invalid save mutated original")

	# Confirm corrupted and unsupported data fail without panics/regeneration.
	var bad_file := FileAccess.open(store.save_root.path_join("corrupt.json"), FileAccess.WRITE)
	assert(bad_file != null)
	bad_file.store_string("not json!")
	bad_file.close()
	assert(not store.load_save("corrupt", world)["ok"])
	var unsupported := FileAccess.open(store.save_root.path_join("unsupported.json"), FileAccess.WRITE)
	assert(unsupported != null)
	unsupported.store_string(JSON.stringify(broken))
	unsupported.close()
	assert(not store.load_save("unsupported", world)["ok"])
	assert(FileAccess.get_sha256(SOURCE) == original_sha, "Source fixture unexpectedly changed")
	assert(world.world_id == first_world_id)
	for slot in ["first", "second", "corrupt", "unsupported"]:
		for ext in [".json", ".json.bak", ".json.tmp"]:
			DirAccess.remove_absolute(root_path.path_join(slot + ext))
	print("PASS: GAME-7 independent world/save IDs, origin, 3-member party, knowledge, mismatches and immutable fixtures")
	quit(0)
