extends "res://research/game71-72/scripts/capture-baseline.gd"
var assertions: Array[String] = []
var town_snapshots: Dictionary = {}
func _initialize() -> void:
	report_path = "presentation-results.json"
	super._initialize()
func check(ok: bool, name: String) -> void:
	if not ok: push_error("FAIL "+name); quit(1); assert(ok,name)
	assertions.append(name)
func capture(name: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png("res://research/game71-72/evidence/after-"+name+".png")==OK,"capture "+name)
	var ratio: float = flow.pixel_ratio
	var expected := Vector2i((flow.map_surface.size*root.get_stretch_transform().get_scale()).round())
	check(flow.viewport.size == expected,"native output resolution "+name)
	var snapshot: Dictionary = {"name":name,"window":[root.size.x,root.size.y],"viewport":[flow.viewport.size.x,flow.viewport.size.y],"ratio":ratio,"camera":[flow.camera.position.x,flow.camera.position.y],"logicalZoom":flow.camera.zoom.x/ratio}
	if flow.level == "world":
		var labels: Array = flow.world_map.get_node("Labels").displayed_labels
		check(labels.size()>0,"useful labels "+name)
		var occupied: Array[Rect2] = []
		for l in labels:
			check(float(l.size)/ratio >= 12,"readable measured font "+name)
			for r in occupied: check(not r.intersects(l.rect),"non-overlapping labels "+name)
			occupied.append(l.rect)
			if l.kind == "burg":
				var b: Dictionary = flow.resolve_burg(l.sourceId)
				check(not b.is_empty() and l.anchor==Vector2(b.x,b.y),"real label anchor "+name)
		if "selected" in name:
			check(labels.any(func(l: Dictionary) -> bool:return l.kind=="burg" and l.sourceId==int(flow.selected_burg.i)),"selected burg labelled "+name)
		snapshot.labels = labels.map(func(l: Dictionary) -> Dictionary:return {"kind":l.kind,"id":l.sourceId,"size":l.size,"text":l.text,"rect":[l.rect.position.x,l.rect.position.y,l.rect.size.x,l.rect.size.y]})
	else:
		var groups: Array = flow.town_map.marker_groups
		var known: Array = flow.town_map.model.establishments.map(func(e: Dictionary) -> String:return e.id)
		var marker_snapshot: Array = []
		var covered: Array = []
		for g in groups:
			var ids: Array = g.members.map(func(e: Dictionary) -> String:return e.id)
			marker_snapshot.append({"id":g.representative.id,"position":g.representative.position,"members":ids})
			for e in g.members:
				check(e.knowledge!="unknown" and e.id in known and e.id not in covered,"unique known cluster membership "+name)
				covered.append(e.id)
		var visible: Array = flow.town_map.model.establishments.filter(func(e: Dictionary) -> bool:return flow.viewport.get_visible_rect().grow(-15*ratio).has_point(flow.town_map.get_global_transform_with_canvas()*Vector2(e.position[0],e.position[1])))
		check(covered.size()==visible.size(),"every visible known facility represented "+name)
		var slug: String = flow.active_case.slug
		if town_snapshots.has(slug):
			check(marker_snapshot==town_snapshots[slug].markers,"selection invariant markers and clusters "+name)
			check(snapshot.camera==town_snapshots[slug].camera and snapshot.logicalZoom==town_snapshots[slug].logicalZoom,"exact same camera "+name)
		else: town_snapshots[slug]={"markers":marker_snapshot,"camera":snapshot.camera,"logicalZoom":snapshot.logicalZoom}
		var occupied: Array[Rect2] = []
		for l in flow.town_map.displayed_labels:
			for r in occupied: check(not r.intersects(l.rect),"town labels avoid each other "+name)
			for g in groups: check(not l.rect.intersects(g.rect),"labels never obscure marker hit areas "+name)
			occupied.append(l.rect)
		snapshot.markers=marker_snapshot
	records.append(snapshot)
func run() -> void:
	await super.run()
func _finalize() -> void:
	var f := FileAccess.open("res://research/game71-72/evidence/presentation-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"assertions":assertions,"records":records},"\t")+"\n")
	f.close()
	print("PASS ",assertions.size()," presentation assertions; ",records.size()," actual after captures")
