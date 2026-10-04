extends SceneTree

class DrawProbe extends "res://scripts/gameplay/expedition_demo.gd":
	var painted_ids: Array[String] = []
	func _draw_site(site: Dictionary) -> void:
		painted_ids.append(str(site.id))
		super._draw_site(site)

func _initialize() -> void:
	call_deferred("_check")

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func _check() -> void:
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	menu.fade_duration = 0.0
	root.add_child(menu)
	current_scene = menu
	await process_frame
	assert(menu.new_game_button.text == "New Game")
	assert(menu.expedition_demo_button.text == "Expedition Demo")
	menu.expedition_demo_button.pressed.emit()
	for i in range(5):
		await process_frame
	var demo: Node2D = current_scene
	assert(demo != menu and demo.expedition.ready, "Menu button failed to launch bundled demo")
	assert(int(demo.region.source_context.source_home_burg_id) == 554)
	assert(demo.expedition.current_id == "burg:554")
	assert(demo.party_status.text.contains("THREE TRAVELLERS"))
	assert(demo.info.text.contains("session only") and demo.info.text.contains("Main menu"))
	var pristine: Dictionary = demo.region.duplicate(true)
	for code in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_H, KEY_A, KEY_E, KEY_P, KEY_BRACKETRIGHT]:
		demo._unhandled_input(_key(code))
	assert(demo.region == pristine and demo.expedition.hours == 0)
	assert(not demo.reveal_hidden_for_developer and not demo.show_route_audit)
	assert(not demo.show_encounter_demo and not demo.show_route_preview)
	assert(not demo.load_region("res://tools/regiongen/.tmp/missing.json"))
	assert(demo.expedition.ready and demo.region == pristine)
	for site in demo.region.local_sites_v2.sites:
		if str(site.knowledge) in ["hidden", "rumoured"]:
			assert(not demo.select_local_site_at(Vector2(float(site.position[0]), float(site.position[1]))))
	var visited := false
	for site in demo.expedition.visible_sites():
		if str(site.kind) == "hometown":
			continue
		assert(demo.select_local_site_at(Vector2(float(site.position[0]), float(site.position[1]))))
		demo._unhandled_input(_key(KEY_T))
		if demo.expedition.current_id == str(site.id):
			demo._unhandled_input(_key(KEY_C))
			assert(demo.expedition.clues == 1 and demo.expedition.known[site.id] == "visited")
			visited = true
			break
	assert(visited, "Pinned demo has no playable known destination")
	demo._unhandled_input(_key(KEY_R))
	assert(demo.expedition.current_id == "burg:554" and demo.expedition.supplies == 12)
	assert(demo.region == pristine, "Demo wrote session state into pinned source")
	assert(not demo.expedition.corridor_uncontradicted(demo.expedition.home, Vector2(-20, -20)))
	# Exercise the actual canvas draw hook: a prior indentation error silently
	# skipped every non-home marker despite successful data/texture checks.
	var probe: Node2D = load("res://scenes/gameplay/expedition_demo.tscn").instantiate()
	probe.set_script(DrawProbe)
	root.add_child(probe)
	for i in range(3):
		await process_frame
	var expected_ids: Array[String] = []
	for site in probe.expedition.visible_sites():
		if str(site.kind) != "hometown":
			expected_ids.append(str(site.id))
	assert(not probe.painted_ids.is_empty(), "Known site draw hook never ran")
	for id in probe.painted_ids:
		assert(expected_ids.has(id), "Canvas drew an undiscovered site")
	for id in expected_ids:
		assert(probe.painted_ids.has(id), "Known site missing from canvas")
	probe.queue_free()
	demo._unhandled_input(_key(KEY_ESCAPE))
	for i in range(5):
		await process_frame
	assert(current_scene is MainMenu, "Escape failed to return to main menu")
	print("PASS: GAME-56 main-menu launch, bundled data, known marker draw hooks, playable journey/investigation/return, hidden privacy, no debug switching or source mutation, menu return")
	quit(0)
