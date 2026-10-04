extends SceneTree

## A genuine model + UI interaction check across six canonical Azgaar regions.
## No mutable player-save files are created or touched.
func _initialize() -> void:
	call_deferred("_check")

func _read_region(path: String) -> Dictionary:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert(f != null, "Missing generated canonical-context region " + path)
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	assert(data is Dictionary, "Invalid contextual region JSON " + path)
	return data

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func _check() -> void:
	var names := [
		"contextual-game-11-determinism-shore",
		"contextual-game-11-determinism-river",
		"contextual-game-11-determinism-highland",
		"contextual-atlas-showcase-shore",
		"contextual-atlas-showcase-river",
		"contextual-atlas-showcase-highland"]
	var visits := 0
	var clues_earned := 0
	for name in names:
		var data: Dictionary = _read_region("res://tools/regiongen/.tmp/" + name + ".json")
		var original: Array = (data["local_sites_v2"]["sites"] as Array).duplicate(true)
		var session := ExpeditionSession.new()
		assert(session.begin(data), session.error)
		var control_data: Dictionary = data.duplicate(true)
		control_data.erase("encounter_demo_v1")
		control_data.erase("hex_route_preview_v1")
		var control := ExpeditionSession.new()
		assert(control.begin(control_data))
		assert(session.ready)
		assert(session.supplies == 12 and session.danger == 0 and session.hours == 0)
		assert(session.visible_sites().size() == original.filter(func(s: Dictionary) -> bool:
			return ["discovered", "visited"].has(str(s.get("knowledge", "")))).size())
		assert(session.current_id == "burg:%d" % int(data["source_context"]["source_home_burg_id"]))
		assert(not session.is_dry(Vector2(-20, -20)), "Uncharted sea must not be treated as dry land")
		assert(not session.corridor_uncontradicted(session.home, Vector2(-20, -20)),
			"Cannot assume a walkable water crossing")
		assert(session.known.size() == original.size())
		assert(session.notes.size() > 0)
		for site in original:
			var id: String = str(site.get("id", ""))
			if str(site.get("knowledge", "")) == "hidden":
				assert(not session.select_site(id), "Secret site accepted as known")
				assert(not session.visible_sites().any(func(v: Dictionary) -> bool: return str(v["id"]) == id),
					"Hidden name or coordinates leaked into player UI")
		for site in session.visible_sites():
			if str(site.get("kind", "")) == "hometown":
				continue
			var id: String = str(site.get("id", ""))
			var dest: Vector2 = session._point(site)
			if not session.corridor_uncontradicted(session.home, dest):
				assert(session.select_site(id))
				assert(not session.travel_to_selected(), "Macro water crossing accepted")
				continue
			assert(session.select_site(id))
			assert(session.travel_to_selected(), session.error)
			assert(control.select_site(id) and control.travel_to_selected())
			assert(session.hours == control.hours and session.supplies == control.supplies and session.danger == control.danger,
				"Presentation-only occupants changed expedition travel")
			assert(session.current_id == id)
			var hour_after: int = session.hours
			assert(session.investigate("careful"), session.error)
			assert(session.known[id] == "visited")
			assert(session.clues == 1 and session.hours > hour_after)
			assert(not session.investigate("bold"), "Visited site exploited twice")
			visits += 1
			clues_earned += session.clues
			break
		assert(session.rest_at_home(), session.error)
		assert(session.supplies == 12 and session.position == session.home)
		var known_before: int = session.visible_sites().size()
		assert(session.scout(), session.error)
		assert(session.visible_sites().size() >= known_before)
		# Replaying from same source/seed must reset the exact original state.
		var replay := ExpeditionSession.new()
		assert(replay.begin(data))
		assert(replay.visible_sites().size() == original.filter(func(s: Dictionary) -> bool:
			return ["discovered", "visited"].has(str(s.get("knowledge", "")))).size())
		assert(original == data["local_sites_v2"]["sites"],
			"Session-only knowledge mutated generated data or original source")
	assert(visits >= 2 and clues_earned >= 2,
		"Not enough actual playable expeditions across the six canonical regions")
	var scene: PackedScene = load("res://scenes/gameplay/expedition_prototype.tscn")
	assert(scene != null, "Missing interactive expedition scene")
	var viewer: Node2D = scene.instantiate()
	root.add_child(viewer)
	await process_frame
	assert(viewer.expedition.ready)
	assert(viewer.show_decorations)
	assert(not viewer.reveal_hidden_for_developer and not viewer.show_route_audit)
	assert(viewer.expedition.visible_sites().size() > 0)
	assert(viewer.party_status.text.contains("THREE TRAVELLERS"))
	assert(viewer.journal.text.contains("Three travellers gather"))
	viewer._unhandled_input(_key(KEY_H))
	viewer._unhandled_input(_key(KEY_A))
	viewer._unhandled_input(_key(KEY_E))
	assert(not viewer.show_encounter_demo)
	assert(not viewer._encounter_preview_available())
	for occupant in viewer.region.get("encounter_demo_v1", {}).get("occupants", []):
		assert(not viewer.select_encounter_demo_at(Vector2(float(occupant.position[0]), float(occupant.position[1]))))
	assert(not viewer.reveal_hidden_for_developer)
	assert(not viewer.show_route_audit)
	viewer._unhandled_input(_key(KEY_V))
	assert(not viewer.show_decorations)
	viewer._unhandled_input(_key(KEY_V))
	assert(viewer.show_decorations)
	var start_hours: int = viewer.expedition.hours
	viewer._unhandled_input(_key(KEY_S))
	assert(viewer.expedition.hours > start_hours and viewer.expedition.supplies == 11)
	viewer._unhandled_input(_key(KEY_4))
	assert(viewer.expedition.ready and viewer.expedition.hours == 0,
		"Region switch retained previous party state")
	assert(not viewer.load_region("res://tools/regiongen/.tmp/missing-expedition.json"))
	assert(viewer.region.is_empty())
	print("PASS: GAME-55 six Azgaar expeditions, visible-site travel, choices, scout, return, hidden privacy, source-water exclusion and Godot UI")
	quit(0)
