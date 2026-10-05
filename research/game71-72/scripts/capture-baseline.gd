extends SceneTree
var flow: Node
var records: Array = []
var report_path := "baseline.json"
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	assert(root.get_texture().get_image().save_png("res://research/game71-72/evidence/before-"+name+".png") == OK)
	records.append({"name":name,"window":root.size,"content":root.content_scale_size,"mapViewport":flow.viewport.size,"hostSize":flow.viewport.get_parent().size,"hostScreenScale":flow.viewport.get_parent().get_screen_transform().get_scale(),"stretch":root.get_stretch_transform(),"camera":flow.camera.position,"zoom":flow.camera.zoom,"markers":flow.town_map.rendered_markers.map(func(e: Dictionary) -> String:return e.id) if flow.level == "town" else []})
func dense_burg() -> Dictionary:
	var best: Dictionary = {}
	var count := -1
	for b in flow.world_data.settlements:
		if not b is Dictionary or int(b.get("i",0)) < 1 or b.get("hidden",false) or b.get("removed",false): continue
		var n := 0
		for other in flow.world_data.settlements:
			if other is Dictionary and int(other.get("i",0)) > 0 and Vector2(b.x,b.y).distance_to(Vector2(other.x,other.y)) < 50: n += 1
		if n > count: count = n; best = b
	return best
func run() -> void:
	flow = load("res://scenes/debug/world_region_town_flow.tscn").instantiate()
	root.add_child(flow)
	await settle()
	for stem in ["game-11-determinism","atlas-showcase"]:
		if flow.world_stem != stem: assert(flow.switch_world(stem))
		flow.fit_map()
		await capture(stem+"-fit")
		flow.camera.zoom = Vector2(1.2,1.2)
		flow.world_map.set_zoom(1.2)
		await capture(stem+"-medium")
		var dense := dense_burg()
		assert(flow.select_world_burg(dense.i,true))
		flow.camera.zoom = Vector2(3.8,3.8)
		flow.world_map.set_zoom(3.8)
		await capture(stem+"-dense")
		assert(flow.bookmark("albanes" if stem == "game-11-determinism" else "batan"))
		await capture(stem+"-selected")
		root.size = Vector2i(2880,1920)
		await capture(stem+"-selected-2x")
		root.size = Vector2i(1800,1200)
		await capture(stem+"-selected-125")
		root.size = Vector2i(1440,960)
	for slug in ["albanes","batan","thilranlena"]:
		assert(flow.bookmark(slug) and flow.open_region() and flow.open_town())
		flow.fit_map()
		flow.town_map.selected_id = ""
		flow.selected_facility = {}
		flow._refresh()
		await capture(slug+"-none")
		var types: Array = ["guildhall","tavern","mill"] if slug == "albanes" else (["inn","well","manor"] if slug == "batan" else ["warehouse","tavern","pier"])
		for type in types:
			for e in flow.town_map.model.establishments:
				if e.type == type:
					assert(flow.town_map.select_facility(e.id))
					break
			await capture(slug+"-"+type)
		flow.go_back()
		flow.go_back()
	var file := FileAccess.open("res://research/game71-72/evidence/"+report_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"records":records},"\t")+"\n")
	file.close()
	print("PASS baseline: ",records.size()," actual Godot captures and viewport/marker measurements")
	quit()
