extends SceneTree

## GAME-44: separate real-world Godot contextual-site smoke (no saved writes).
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var scene: PackedScene = load("res://scenes/debug/contextual_region_preview.tscn")
	assert(scene != null, "Missing contextual-site debug scene")
	var viewer: Node2D = scene.instantiate()
	root.add_child(viewer)
	await process_frame
	assert(not viewer.region.is_empty(), "Contextual map failed to initialise")
	assert(viewer.glyphs.has("symbols"), "Illustrated site registry missing")
	var inspected := 0
	for name in [
		"contextual-game-11-determinism-shore",
		"contextual-game-11-determinism-river",
		"contextual-game-11-determinism-highland",
		"contextual-atlas-showcase-shore",
		"contextual-atlas-showcase-river",
		"contextual-atlas-showcase-highland"
	]:
		assert(viewer.load_region("res://tools/regiongen/.tmp/%s.json" % name))
		await process_frame
		var ctx: Dictionary = viewer.region.get("source_context", {})
		var layer: Dictionary = viewer.region.get("local_sites_v2", {})
		assert(int(layer.get("schema_version", 0)) == 2)
		var inferred: Dictionary = viewer.region.get("inferred_fine_v1", {})
		assert(int(inferred.get("schema_version", -1)) == 1, "Source-matched inferred landscape missing")
		assert(str(inferred.get("source_context_id", "")) == str(ctx.get("id", "")))
		assert(str(inferred.get("source_world_sha256", "")) == str(ctx.get("parent_source_world_sha256", "")))
		assert(str(inferred.get("truth", "")) == "INFERRED_VISUAL_FIELD_NOT_TRAVERSAL")
		assert(str(inferred.get("claims", {}).get("walkable", "")) == "UNKNOWN")
		assert(inferred.get("vertices", []).size() == 1089)
		assert(viewer.show_decorations)
		# V is a visual layer switch, not a migration or revealed knowledge change.
		var visual_key := InputEventKey.new()
		visual_key.keycode = KEY_V
		visual_key.pressed = true
		viewer._unhandled_input(visual_key)
		assert(not viewer.show_decorations)
		viewer._unhandled_input(visual_key)
		assert(viewer.show_decorations)
		assert(str(layer.get("source_context_id", "")) == str(ctx.get("id", "")))
		assert(str(layer.get("migration", {}).get("from_site_generation_v1", "")) == "NOT_AUTOMATIC")
		assert(layer.get("sites", []).size() >= 1, "Original burg not retained")
		var home: Dictionary = layer["sites"][0]
		assert(str(home["id"]) == "burg:%d" % int(ctx["source_home_burg_id"]))
		assert(home["position"] == ctx["space"]["home_local"])
		assert(viewer.selected_local_id == "")
		assert(not viewer.reveal_hidden_for_developer)
		assert(not viewer.show_route_audit, "Route audit must default to OFF")
		assert(not viewer.show_hex_grid)
		assert(not viewer.show_encounter_demo)
		assert(viewer.selected_encounter_demo_id == "")
		var encounter_key := InputEventKey.new()
		encounter_key.keycode = KEY_E
		encounter_key.pressed = true
		for occupant in viewer.region.get("encounter_demo_v1", {}).get("occupants", []):
			var mock_point := Vector2(float(occupant.position[0]), float(occupant.position[1]))
			assert(not viewer.select_encounter_demo_at(mock_point))
		viewer._unhandled_input(encounter_key)
		assert(viewer.show_encounter_demo)
		await process_frame
		assert(not viewer.show_hex_grid, "E must not change the user's independent X setting")
		for occupant in viewer.region.get("encounter_demo_v1", {}).get("occupants", []):
			var mock_point := Vector2(float(occupant.position[0]), float(occupant.position[1]))
			assert(viewer.select_encounter_demo_at(mock_point))
			assert(viewer.selected_encounter_demo_id == str(occupant.id))
			assert(viewer.info.text.contains("MOCK-UP ONLY"))
			assert(viewer.info.text.contains("no combat or spawn rules"))
			await process_frame
		viewer._unhandled_input(encounter_key)
		assert(not viewer.show_encounter_demo and viewer.selected_encounter_demo_id == "")
		var good_demo: Dictionary = viewer.region.encounter_demo_v1.duplicate(true)
		viewer.region.encounter_demo_v1.source_context_id = "wrong-context"
		viewer._unhandled_input(encounter_key)
		assert(not viewer.show_encounter_demo, "Foreign-world mock-up displayed")
		viewer.region.encounter_demo_v1 = good_demo
		viewer.region.erase("encounter_demo_v1")
		viewer._unhandled_input(encounter_key)
		assert(not viewer.show_encounter_demo, "Legacy region without mock-ups must remain usable")
		viewer.region.encounter_demo_v1 = good_demo
		assert(viewer.hex_steps_to(Vector2(500, 500)) == 0)
		var hex_key := InputEventKey.new()
		hex_key.keycode = KEY_X
		hex_key.pressed = true
		viewer._unhandled_input(hex_key)
		assert(viewer.show_hex_grid)
		viewer._unhandled_input(hex_key)
		assert(not viewer.show_hex_grid)
		for s in layer["sites"]:
			if not s is Dictionary or s.get("kind", "") == "hometown":
				continue
			var p: Vector2 = Vector2(float(s["position"][0]), float(s["position"][1]))
			var state: String = str(s.get("knowledge", "hidden"))
			if state == "hidden" or state == "rumoured":
				assert(not viewer.select_local_site_at(p), "Unknown source site was shown to the player")
				assert(not viewer.info.text.contains(str(s.get("label", ""))), "Hidden label leaked into HUD")
			else:
				assert(viewer.select_local_site_at(p), "Discovered site is not clickable")
				assert(viewer.selected_local_id == str(s["id"]))
				assert(viewer.info.text.contains(str(s["label"])))
				inspected += 1
		# Route/shoreline warning marks are developer-only, off by default.
		var audit_key := InputEventKey.new()
		audit_key.keycode = KEY_A
		audit_key.pressed = true
		viewer._unhandled_input(audit_key)
		assert(viewer.show_route_audit, "A must reveal route audit")
		assert(viewer.region["local_sites_v2"]["route_consistency"].has("conflicts"),
			"Do not remove source route conflict evidence")
		viewer._unhandled_input(audit_key)
		assert(not viewer.show_route_audit, "A must conceal route audit again")
		# H is strictly a developer preview toggle and never persists.
		var toggle := InputEventKey.new()
		toggle.keycode = KEY_H
		toggle.pressed = true
		viewer._unhandled_input(toggle)
		assert(viewer.reveal_hidden_for_developer)
		for s in layer["sites"]:
			if not s is Dictionary or s.get("kind", "") == "hometown":
				continue
			var p: Vector2 = Vector2(float(s["position"][0]), float(s["position"][1]))
			assert(viewer.select_local_site_at(p))
		viewer._unhandled_input(toggle)
		assert(not viewer.reveal_hidden_for_developer)
		viewer._unhandled_input(encounter_key)
		assert(viewer.show_encounter_demo)
		# Next loop's load_region must reset both the layer and its selection.
	assert(inspected >= 2, "No generated and inspectable sites across six original worlds")
	assert(not viewer.load_region("res://tools/regiongen/.tmp/no-such-v2-layer.json"))
	assert(viewer.region.is_empty())
	print("PASS: GAME-44 Godot six real source-region POI maps, clicks, labels and developer-only hidden-site reveal")
	quit(0)
