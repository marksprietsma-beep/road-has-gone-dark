extends SceneTree

## Runs the real F6 scene. Captures are the actual Godot root viewport.
var checks: Array[String] = []
var captures: Array[String] = []
var flow: Node
var started: int
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, name: String) -> void:
	if not ok:
		push_error("FAIL: " + name)
		quit(1)
		assert(ok,name)
	checks.append(name)
func settle() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	var image := root.get_texture().get_image()
	check(image != null and image.get_width() == 1440, "actual rendered viewport " + name)
	check(image.save_png("res://research/game70/evidence/"+name+".png") == OK,"saved " + name)
	captures.append(name+".png")
func click_map(point: Vector2) -> void:
	var screen: Vector2 = flow.viewport.get_canvas_transform()*point
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = screen
	flow.viewport.push_input(press,true)
	await process_frame
	press = press.duplicate()
	press.pressed = false
	flow.viewport.push_input(press,true)
	await process_frame
func _run() -> void:
	started = Time.get_ticks_msec()
	flow = load("res://scenes/debug/world_region_town_flow.tscn").instantiate()
	root.add_child(flow)
	await settle()
	check(flow.world_stem == "game-11-determinism" and flow.level == "world","F6 starts canonical world")
	check(not flow.switch_world("invented-world"),"unknown world fails safely")
	check(not flow.select_world_burg(999999),"unknown burg fails safely")
	check(not flow.open_region(),"no selected burg cannot open region")
	check(flow.resolve_burg(760).get("name","") != "Batan" and flow._case_for_burg(760).is_empty(),"same numeric burg ID never substitutes cross-world town")
	for slug in ["albanes","batan","thilranlena"]:
		check(flow.bookmark(slug),slug+" real bookmark")
		await settle()
		var c: Dictionary
		for candidate in flow.journeys:
			if candidate.slug == slug: c = candidate
		check(flow.world_stem == c.world and int(flow.selected_burg.i) == int(c.burgId) and int(flow.selected_burg.cell) == int(c.cellId),slug+" exact canonical identity")
		check(flow.world_map.selection.selected_cell == int(c.cellId),slug+" source parent cell selected")
		# Real atlas hit/signal path, not just the bookmark helper.
		await click_map(Vector2(c.worldPosition[0],c.worldPosition[1]))
		check(int(flow.selected_burg.i) == int(c.burgId),slug+" actual world map click signal")
		await capture(slug+"-world")
		var world_position: Vector2 = flow.camera.position
		var world_zoom: Vector2 = flow.camera.zoom
		flow.action.pressed.emit()
		await settle()
		check(flow.level == "region",slug+" Open Region UI button")
		check(int(flow.region_map.region.source_context.parent_cell.source_id) == int(c.cellId) and flow.region_map.region.id == c.regionId,slug+" exact generated cell identity")
		check(flow.region_map.region.export_scope == "PUBLIC_KNOWN_ONLY",slug+" region public export")
		check(flow.region_map.region.source_context.parent_source_world_sha256 == c.fixtureSha256,slug+" no cross-world region")
		check(int(flow.region_map.selected_source_id) == int(c.burgId),slug+" local burg highlighted")
		await click_map(Vector2(c.localPosition[0],c.localPosition[1]))
		check(int(flow.region_burg.i) == int(c.burgId),slug+" actual regional burg click")
		await capture(slug+"-region")
		# Exercise camera context away from the default fit view.
		flow.camera.position += Vector2(8,-5)
		flow.camera.zoom *= 1.04
		var region_position: Vector2 = flow.camera.position
		var region_zoom: Vector2 = flow.camera.zoom
		check(not flow.select_region_burg(999999),slug+" absent regional burg fails safely")
		check(not flow.open_town(),slug+" invalid regional selection cannot open town")
		check(flow.select_region_burg(c.burgId),slug+" restore source regional selection")
		flow.action.pressed.emit()
		await settle()
		check(flow.level == "town",slug+" Inspect Settlement UI button")
		check(flow.town_map.model.audience == "public" and flow.town_map.model.settlement.worldIdentity == c.fixtureSha256 and int(flow.town_map.model.settlement.burgId) == int(c.burgId),slug+" matching original public town model")
		check(flow.town_map.model.buildings.size() == {"batan":77,"albanes":463,"thilranlena":537}[slug],slug+" original roof count")
		for e in flow.town_map.model.establishments: check(e.knowledge != "unknown",slug+" known facility "+e.type)
		await capture(slug+"-town")
		var type: String = {"batan":"inn","albanes":"guildhall","thilranlena":"warehouse"}[slug]
		var chosen: Dictionary = {}
		for e in flow.town_map.model.establishments:
			if e.type == type: chosen = e; break
		check(not chosen.is_empty(),slug+" real target facility")
		check(flow.town_map.select_facility(chosen.id),slug+" index selection")
		flow.town_focus.pressed.emit()
		await settle()
		flow.town_map.selected_id = ""
		flow.selected_facility = {}
		await click_map(Vector2(chosen.position[0],chosen.position[1]))
		check(flow.selected_facility.get("id","") == chosen.id,slug+" real facility map input")
		var building: Dictionary = {}
		for b in flow.town_map.model.buildings:
			if b.id == chosen.buildingId: building = b
		check(flow.town_map.selected_polygon() == building.polygon,slug+" exact canonical highlight polygon")
		if slug == "albanes": check(chosen.provenance.providerBuildingId == "b93","guildhall b93")
		if slug == "thilranlena": check(chosen.provenance.providerBuildingId == "b223","warehouse b223")
		check(flow.inspection.text.contains(type) and flow.notice.text.contains("NOT fitted"),slug+" inspection and geography limitation visible")
		await capture(slug+"-facility")
		var town_position: Vector2 = flow.camera.position
		var town_zoom: Vector2 = flow.camera.zoom
		flow.back.pressed.emit()
		await settle()
		check(flow.level == "region" and flow.camera.position == region_position and flow.camera.zoom == region_zoom and int(flow.region_map.selected_source_id) == int(c.burgId),slug+" Back restores region camera and selection")
		await capture(slug+"-return-region")
		flow.back.pressed.emit()
		await settle()
		check(flow.level == "world" and flow.world_stem == c.world and int(flow.selected_burg.i) == int(c.burgId) and flow.camera.position == world_position and flow.camera.zoom == world_zoom,slug+" Back restores world camera and identity")
		await capture(slug+"-return-world")
		# Repeat same journey, preserving cached town camera and fixed identities.
		check(flow.open_region() and flow.open_town(),slug+" repeat complete journey")
		check(flow.camera.position == town_position and flow.camera.zoom == town_zoom and flow.town_map.selected_id == chosen.id,slug+" repeated town camera and facility selection restored")
		check(not flow.town_map.select_facility("unknown-facility"),slug+" unknown facility rejected")
		flow.go_back()
		flow.go_back()
		await settle()
		check(flow.level == "world" and int(flow.selected_burg.i) == int(c.burgId),slug+" repeat return deterministic")
	# A real unsupported town is inspectable but never substituted.
	var unsupported_id := -1
	for b in flow.world_data.settlements:
		if b is Dictionary and int(b.get("i",0)) > 0 and not b.get("hidden",false) and not b.get("removed",false) and flow._case_for_burg(int(b.i)).is_empty(): unsupported_id = int(b.i); break
	check(flow.select_world_burg(unsupported_id),"real unsupported burg inspectable")
	check(flow.action.disabled and not flow.open_region() and flow.level == "world","unsupported burg has no random region/town fallback")
	var report := {"engine":Engine.get_version_info().string,"rendering":"Compatibility / Xvfb / Mesa llvmpipe","checks":checks,"captures":captures,"loadMsec":flow.load_msec,"elapsedMsec":Time.get_ticks_msec()-started,"viewport":[1440,960]}
	var out := FileAccess.open("res://research/game70/evidence/godot-results.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"\t")+"\n")
	out.close()
	print("PASS ",checks.size()," Godot assertions; ",captures.size()," actual Godot PNGs; all three repeated journeys")
	quit(0)
