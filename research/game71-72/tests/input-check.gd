extends SceneTree
var flow: Node
var checks: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,name: String) -> void:
	if not ok: push_error("FAIL "+name); quit(1); assert(ok,name)
	checks.append(name)
func settle() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
func click_root(point: Vector2) -> void:
	var p := InputEventMouseButton.new()
	p.button_index=MOUSE_BUTTON_LEFT; p.pressed=true; p.position=root.get_stretch_transform().affine_inverse()*point; p.global_position=p.position
	root.push_input(p,true)
	await process_frame
	p=p.duplicate(); p.pressed=false
	root.push_input(p,true)
	await settle()
func click_map(point: Vector2) -> void:
	var native: Vector2 = flow.viewport.get_canvas_transform()*point
	var local: Vector2 = native*flow.map_surface.size/Vector2(flow.viewport.size)
	await click_root(root.get_stretch_transform()*(flow.map_surface.get_global_transform_with_canvas()*local))
func signature() -> Array:
	return flow.town_map.marker_groups.map(func(g: Dictionary) -> Dictionary:return {"id":g.representative.id,"position":g.representative.position,"members":g.members.map(func(e: Dictionary) -> String:return e.id)})
func run() -> void:
	flow=load("res://scenes/debug/world_region_town_flow.tscn").instantiate();root.add_child(flow);await settle()
	for pixels in [Vector2i(1440,960),Vector2i(1800,1200),Vector2i(2880,1920),Vector2i(1920,1080),Vector2i(3840,2160)]:
		assert(flow.bookmark("albanes"));root.size=pixels;await settle()
		flow.selected_burg={};flow.world_map.set_selected_burg(-1);flow._refresh();await settle()
		await click_map(Vector2(985.83,206.36))
		check(flow.selected_burg.get("i",-1)==7,"actual UI map click at "+str(pixels))
		check(flow.world_map.get_node("Labels").displayed_labels.any(func(l: Dictionary) -> bool:return l.kind=="burg" and l.sourceId==7),"selected capital at "+str(pixels))
		flow.fit_map();await settle()
		check(flow.world_map.get_node("Labels").zoom_band == (0 if flow.camera.zoom.x/flow.pixel_ratio < .7 else (1 if flow.camera.zoom.x/flow.pixel_ratio < 1.65 else 2)),"DPI-independent zoom band "+str(pixels))
		var origin: Vector2 = flow.camera.position
		Input.action_press("ui_right")
		flow._process(.02)
		Input.action_release("ui_right")
		check(flow.camera.position.is_equal_approx(origin+Vector2(10/(flow.camera.zoom.x/flow.pixel_ratio),0)),"logical keyboard pan at "+str(pixels))
		flow.bookmark("albanes");await settle()
		check(root.get_texture().get_image().save_png("res://research/game71-72/evidence/input-world-%dx%d.png"%[pixels.x,pixels.y])==OK,"native window capture "+str(pixels))
	root.size=Vector2i(1440,960);await settle()
	for slug in ["albanes","batan","thilranlena"]:
		check(flow.bookmark(slug) and flow.open_region() and flow.open_town(),slug+" full native entry")
		await settle()
		var original: Array=signature()
		var camera_position: Vector2=flow.camera.position
		var camera_zoom: Vector2=flow.camera.zoom
		# Every index button invokes the real public record, including clustered members.
		for i in flow.town_map.model.establishments.size():
			var e: Dictionary=flow.town_map.model.establishments[i]
			flow.entries.get_child(i).pressed.emit();await settle()
			check(flow.selected_facility.id==e.id,slug+" public index "+e.type)
			check(signature()==original,slug+" selection independent complete cluster layout")
			check(flow.camera.position==camera_position and flow.camera.zoom==camera_zoom,slug+" index preserves camera")
		# Test a real root GUI click on the first visible facility-index button.
		var first: Control=flow.entries.get_child(0)
		await click_root(root.get_stretch_transform()*(first.get_global_transform_with_canvas()*(first.size/2)))
		check(flow.selected_facility.id==flow.town_map.model.establishments[0].id,slug+" actual index GUI click")
		var type: String={"albanes":"guildhall","batan":"inn","thilranlena":"warehouse"}[slug]
		for e in flow.town_map.model.establishments:
			if e.type==type:
				flow.town_map.select_facility(e.id);flow.focus_facility();await settle()
				flow.town_map.selected_id="";flow.selected_facility={};await settle()
				await click_map(Vector2(e.position[0],e.position[1]))
				check(flow.selected_facility.id==e.id,slug+" exact roof/native map hit")
				check(not flow.town_map.selected_polygon().is_empty(),slug+" original source polygon highlight")
				break
		var close: Array=signature();flow.town_map.selected_id="";await settle();check(signature()==close,slug+" close zoom stable")
		var pan := InputEventMouseMotion.new();pan.relative=Vector2(15,9);flow.dragging=true;flow.handle_map_input(pan);flow.dragging=false;await settle()
		var moved: Array=signature();await settle();check(signature()==moved,slug+" deterministic settled pan")
		# Defensive filtering using the actual privileged research record, test-only.
		var secret_model: Dictionary=flow.read_json("res://research/game67/samples/"+slug+".developer.json")
		for e in secret_model.establishments:
			if e.knowledge=="unknown":
				var data: Dictionary=flow.town_map.model.duplicate(true);data.establishments.append(e)
				check(flow.town_map.open_town(slug,data,flow.frames[slug]),slug+" defensive test input")
				await settle();check(not flow.town_map.select_facility(e.id),slug+" unknown cannot select")
				for g in flow.town_map.marker_groups:check(not g.members.any(func(m: Dictionary) -> bool:return m.id==e.id),slug+" hidden absent from groups")
		flow.go_back();flow.go_back();await settle();check(flow.level=="world",slug+" return navigation")
	var f:=FileAccess.open("res://research/game71-72/evidence/input-results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks},"\t")+"\n");f.close()
	print("PASS ",checks.size()," native input, complete index, cluster/privacy/window regressions")
	quit()
