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
		assert(str(layer.get("source_context_id", "")) == str(ctx.get("id", "")))
		assert(str(layer.get("migration", {}).get("from_site_generation_v1", "")) == "NOT_AUTOMATIC")
		assert(layer.get("sites", []).size() >= 1, "Original burg not retained")
		var home: Dictionary = layer["sites"][0]
		assert(str(home["id"]) == "burg:%d" % int(ctx["source_home_burg_id"]))
		assert(home["position"] == ctx["space"]["home_local"])
		assert(viewer.selected_local_id == "")
		assert(not viewer.reveal_hidden_for_developer)
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
	assert(inspected >= 2, "No generated and inspectable sites across six original worlds")
	assert(not viewer.load_region("res://tools/regiongen/.tmp/no-such-v2-layer.json"))
	assert(viewer.region.is_empty())
	print("PASS: GAME-44 Godot six real source-region POI maps, clicks, labels and developer-only hidden-site reveal")
	quit(0)
