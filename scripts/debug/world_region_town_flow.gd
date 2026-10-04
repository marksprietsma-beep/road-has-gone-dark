extends Control

## Standalone F6 research proof. No save writes or production entry point.
const ROOT := "res://research/game70/"
const WORLDS := ["game-11-determinism", "atlas-showcase"]
const RegionAdapter := preload("res://scripts/debug/game70/region_adapter.gd")
const TownLayer := preload("res://scripts/debug/game70/town_layer.gd")
const MapCanvas := preload("res://scripts/debug/game70/map_canvas.gd")
var level := "world"
var world_stem := ""
var world_data: Dictionary = {}
var selected_burg: Dictionary = {}
var region_burg: Dictionary = {}
var active_case: Dictionary = {}
var journeys: Array = []
var frames: Dictionary = {}
var context_cache: Dictionary = {}
var world_cache: Dictionary = {}
var selected_facility: Dictionary = {}
var camera: Camera2D
var world_map: WorldFixtureRenderer
var region_map: Node2D
var town_map: Node2D
var viewport: SubViewport
var canvas: Node2D
var breadcrumb: Label
var status: Label
var inspection: Label
var notice: Label
var action: Button
var back: Button
var town_focus: Button
var world_choice: OptionButton
var entries: VBoxContainer
var dragging := false
var last_error := ""
var load_msec: Dictionary = {}

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1440, 960)
	get_window().size = Vector2i(1440, 960)
	journeys = read_json(ROOT + "journeys.json").get("cases", [])
	for f in JSON.parse_string(FileAccess.get_file_as_string("res://research/game69/art/frames.json")):
		frames[f.slug] = f.frame
	_build_ui()
	switch_world(WORLDS[0])

func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _button(text: String, fn: Callable, box: Container) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(fn)
	box.add_child(b)
	return b

func _label(box: Container, font_size: int = 15) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	box.add_child(l)
	return l

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#211d17")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+k, 12)
	add_child(margin)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	breadcrumb = _label(layout, 21)
	var toolbar := HBoxContainer.new()
	layout.add_child(toolbar)
	world_choice = OptionButton.new()
	for w in WORLDS: world_choice.add_item(w)
	world_choice.item_selected.connect(func(index: int) -> void: switch_world(WORLDS[index]))
	toolbar.add_child(world_choice)
	for c in journeys:
		_button("Bookmark: " + c.name, func() -> void: bookmark(c.slug), toolbar)
	back = _button("Back", go_back, toolbar)
	_button("Fit map (F)", fit_map, toolbar)
	town_focus = _button("Focus selected premises", focus_facility, toolbar)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(holder)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1080, 760)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(viewport)
	canvas = MapCanvas.new()
	canvas.controller = self
	viewport.add_child(canvas)
	camera = Camera2D.new()
	canvas.add_child(camera)
	world_map = load("res://scenes/debug/map_renderer/fantasy_map_layers.tscn").instantiate()
	canvas.add_child(world_map)
	world_map.settlement_selected.connect(_world_selected)
	region_map = load("res://scenes/debug/local_region_v1.tscn").instantiate()
	region_map.set_script(RegionAdapter)
	canvas.add_child(region_map)
	region_map.camera = camera
	region_map.hide()
	town_map = TownLayer.new()
	town_map.camera = camera
	canvas.add_child(town_map)
	town_map.facility_selected.connect(_facility_selected)
	town_map.hide()
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 304
	body.add_child(panel)
	status = _label(panel)
	inspection = _label(panel, 14)
	action = _button("Open Region", _primary_action, panel)
	var heading := _label(panel, 14)
	heading.text = "Public source records / facility index"
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	notice = _label(layout, 13)

func _clear_entries() -> void:
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()

func _key() -> String:
	if level == "world": return "world:" + world_stem
	if level == "region": return "region:" + str(region_map.region.get("id", ""))
	return "town:" + str(town_map.model.get("settlement", {}).get("id", ""))

func _remember() -> void:
	if world_stem.is_empty(): return
	context_cache[_key()] = {"position":camera.position,"zoom":camera.zoom,"facilityId":selected_facility.get("id","") if level == "town" else ""}

func _restore_or_fit() -> void:
	if context_cache.has(_key()):
		camera.position = context_cache[_key()].position
		camera.zoom = context_cache[_key()].zoom
		if level == "town" and not str(context_cache[_key()].get("facilityId","")).is_empty():
			town_map.select_facility(context_cache[_key()].facilityId)
	else:
		fit_map()
	world_map.set_zoom(camera.zoom.x)
	camera.force_update_scroll()

func switch_world(stem: String) -> bool:
	if stem not in WORLDS: return _fail("Unknown source world; selection unchanged")
	_remember()
	var started := Time.get_ticks_msec()
	var path: String = "res://tests/worldgen/fixtures/%s.json" % stem
	var data := read_json(path)
	if data.is_empty(): return _fail("Canonical fixture unavailable")
	world_stem = stem
	world_data = data
	selected_burg = {}
	region_burg = {}
	active_case = {}
	selected_facility = {}
	level = "world"
	world_choice.select(WORLDS.find(stem))
	world_map.display_fixture(data, path.trim_suffix(".json") + ".relief.svg", ROOT + "world-art/" + stem + ".vegetation.svg")
	load_msec["world:"+stem] = Time.get_ticks_msec()-started
	_show_level()
	_restore_or_fit()
	_rebuild_world_index()
	_refresh()
	return true

func resolve_burg(id: int) -> Dictionary:
	for b in world_data.get("settlements", []):
		if b is Dictionary and int(b.get("i", -1)) == id and id > 0 and not b.get("removed", false) and not b.get("hidden", false):
			return b
	return {}

func _case_for_burg(id: int) -> Dictionary:
	for c in journeys:
		if c.world == world_stem and int(c.burgId) == id: return c
	return {}

func select_world_burg(id: int, centre: bool = false) -> bool:
	if level != "world": return _fail("Burg selection requires the world view")
	var b := resolve_burg(id)
	if b.is_empty():
		selected_burg = {}
		_refresh()
		return _fail("Unknown or unavailable burg ID %d in %s" % [id, world_stem])
	selected_burg = b
	world_map.selection.select_cell(int(b.cell))
	if centre:
		camera.position = Vector2(b.x,b.y)
		camera.zoom = Vector2(2.6,2.6)
		world_map.set_zoom(camera.zoom.x)
		camera.force_update_scroll()
	_refresh()
	return true

func bookmark(slug: String) -> bool:
	for c in journeys:
		if c.slug == slug:
			if level != "world" or world_stem != c.world:
				if not switch_world(c.world): return false
			return select_world_burg(c.burgId, true)
	return _fail("Unknown bookmark")

func _world_selected(b: Dictionary, _details: String) -> void:
	if level == "world" and not b.is_empty(): select_world_burg(int(b.i))

func _rebuild_world_index() -> void:
	_clear_entries()
	# A source index permits selection of small/decluttered real burgs too.
	for b in world_data.get("settlements", []):
		if not b is Dictionary or int(b.get("i",0)) <= 0 or b.get("removed",false) or b.get("hidden",false): continue
		_button("%s · #%d" % [MapWorldText.plain(b.name,35),int(b.i)], func() -> void: select_world_burg(int(b.i),true), entries)

func open_region() -> bool:
	if level != "world" or selected_burg.is_empty(): return _fail("Select a real source burg first")
	var c := _case_for_burg(int(selected_burg.i))
	if c.is_empty(): return _fail("Region not prepared for this burg; no substitute region is opened")
	var data := read_json(ROOT+"regions/"+c.regionFile)
	var ctx: Dictionary = data.get("source_context",{})
	if int(ctx.get("parent_cell",{}).get("source_id",-1)) != int(selected_burg.cell) or ctx.get("parent_source_world_sha256","") != c.fixtureSha256 or FileAccess.get_sha256("res://tests/worldgen/fixtures/%s.json" % world_stem) != c.fixtureSha256:
		return _fail("Region/source world identity mismatch")
	_remember()
	var started := Time.get_ticks_msec()
	if not region_map.load_region(ROOT+"regions/"+c.regionFile): return _fail("Invalid prepared GAME-62 region")
	active_case = c
	region_burg = selected_burg
	region_map.selected_source_id = int(selected_burg.i)
	level = "region"
	load_msec["region:"+c.slug] = Time.get_ticks_msec()-started
	_show_level()
	_restore_or_fit()
	_clear_entries()
	for b in region_map.region.source_context.source_burgs:
		var suffix := " · town available" if not _case_for_burg(int(b.source_id)).is_empty() and int(b.source_cell_id) == int(c.cellId) else " · town unavailable"
		_button(str(b.name)+suffix, func() -> void: select_region_burg(int(b.source_id)), entries)
	_refresh()
	return true

func select_region_burg(id: int) -> bool:
	if level != "region": return _fail("Region burg selection requires region view")
	for b in region_map.region.source_context.source_burgs:
		if int(b.source_id) == id:
			region_burg = resolve_burg(id)
			region_map.selected_source_id = id
			region_map.queue_redraw()
			_refresh()
			return not region_burg.is_empty()
	region_burg = {}
	_refresh()
	return _fail("Burg is absent from this regional source context")

func open_town() -> bool:
	if level != "region" or region_burg.is_empty(): return _fail("Select the source burg in its region")
	var c := _case_for_burg(int(region_burg.i))
	if c.is_empty() or int(c.cellId) != int(region_map.region.source_context.parent_cell.source_id): return _fail("Town detail unavailable for this source identity")
	var model := read_json("res://research/game67/samples/%s.public.json" % c.slug)
	if model.get("audience","") != "public" or int(model.get("settlement",{}).get("burgId",-1)) != int(region_burg.i) or model.settlement.get("worldIdentity","") != c.fixtureSha256 or model.settlement.get("worldSeed","") != world_data.seed:
		return _fail("Town belongs to a different burg or source world")
	for e in model.get("establishments",[]):
		if e.get("knowledge", "unknown") == "unknown": return _fail("Invalid public model: hidden facility present")
	_remember()
	var started := Time.get_ticks_msec()
	if not town_map.open_town(c.slug,model,frames[c.slug]): return _fail("Town artwork unavailable")
	active_case = c
	selected_facility = {}
	level = "town"
	load_msec["town:"+c.slug] = Time.get_ticks_msec()-started
	_show_level()
	_restore_or_fit()
	_clear_entries()
	for e in model.establishments:
		_button(str(e.label)+(" · outdoor" if e.locationType == "outdoor" else ""), func() -> void: town_map.select_facility(e.id), entries)
	_refresh()
	return true

func _facility_selected(e: Dictionary) -> void:
	selected_facility = e
	_refresh()

func focus_facility() -> void:
	if level != "town" or selected_facility.is_empty(): return
	camera.position = Vector2(selected_facility.position[0],selected_facility.position[1])
	var span: float = town_map.frame.size.x * .1
	var rings: Array = town_map.selected_polygon()
	if not rings.is_empty():
		var p: Array = rings[0]
		var bounds := Rect2(Vector2(p[0][0],p[0][1]),Vector2.ZERO)
		for point in p: bounds = bounds.expand(Vector2(point[0],point[1]))
		span = maxf(bounds.size.x,bounds.size.y) * 12.0
	camera.zoom = Vector2.ONE * minf(50.0, minf(viewport.size.x,viewport.size.y)/maxf(span,12))
	camera.force_update_scroll()

func go_back() -> void:
	_remember()
	if level == "town":
		level = "region"
		_clear_entries()
		for b in region_map.region.source_context.source_burgs:
			var suffix := " · town available" if not _case_for_burg(int(b.source_id)).is_empty() and int(b.source_cell_id) == int(active_case.cellId) else " · town unavailable"
			_button(str(b.name)+suffix, func() -> void: select_region_burg(int(b.source_id)), entries)
	elif level == "region":
		level = "world"
		_rebuild_world_index()
	else: return
	_show_level()
	_restore_or_fit()
	_refresh()

func _show_level() -> void:
	world_map.visible = level == "world"
	region_map.visible = level == "region"
	town_map.visible = level == "town"
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	RenderingServer.set_default_clear_color(Color("#fff2c8") if level == "town" else Color("#211d17"))

func fit_map() -> void:
	var bounds: Rect2
	if level == "world": bounds = Rect2(Vector2.ZERO,Vector2(world_data.map.width,world_data.map.height))
	elif level == "region": bounds = Rect2(0,0,1000,1000)
	else: bounds = town_map.frame
	camera.position = bounds.get_center()
	var z: float = minf(viewport.size.x / bounds.size.x,viewport.size.y / bounds.size.y)*.91
	camera.zoom = Vector2(z,z)
	world_map.set_zoom(z)
	camera.force_update_scroll()

func _primary_action() -> void:
	if level == "world": open_region()
	elif level == "region": open_town()

func _refresh() -> void:
	breadcrumb.text = "GAME-70 · %s / %s" % [world_stem,level.to_upper()]
	if not selected_burg.is_empty(): breadcrumb.text += " / " + str(selected_burg.name)
	status.text = "World: %s\nSource seed: %s\nLevel: %s\nPUBLIC · navigation proof" % [world_stem,str(world_data.get("seed","")),level]
	back.disabled = level == "world"
	back.text = "Back to region" if level == "town" else "Back to world"
	town_focus.visible = level == "town"
	town_focus.disabled = selected_facility.is_empty()
	action.visible = level != "town"
	if level == "world":
		action.text = "Open Region"
		action.disabled = selected_burg.is_empty() or _case_for_burg(int(selected_burg.get("i",-1))).is_empty()
		inspection.text = "Select a real burg on the atlas or in the source index.\nThe three bookmarks have prepared cell regions." if selected_burg.is_empty() else "%s\nBurg ID: %d · Parent cell: %d\nSource position: %.2f, %.2f\n%s" % [selected_burg.name,int(selected_burg.i),int(selected_burg.cell),float(selected_burg.x),float(selected_burg.y),world_map.describe_settlement(selected_burg)]
		if not selected_burg.is_empty() and action.disabled: inspection.text += "\nRegion/town proof unavailable; no substitution."
		notice.text = "Original Azgaar atlas · click burg / use source index · middle drag / arrows pan · wheel zoom · F fit · Back retains camera and selection."
	elif level == "region":
		var id: int = int(region_burg.get("i",-1))
		var c := _case_for_burg(id)
		action.text = "Inspect Settlement" if not c.is_empty() else "Town detail unavailable"
		action.disabled = c.is_empty() or int(c.get("cellId",-1)) != int(region_map.region.source_context.parent_cell.source_id)
		inspection.text = "Parent cell: %d\nRegion: %s\nSelected burg: %s · #%d\nSource-exact position retained.\n%s" % [int(region_map.region.source_context.parent_cell.source_id),str(region_map.region.id),str(region_burg.get("name","none")),id,"Town detail unavailable" if action.disabled else "Matching public town research available"]
		notice.text = "Accepted GAME-62 V1 · gold boundary: actual parent cell · coastline/roads/burgs source exact · terrain inferred · rivers approximate · distances/crossings unverified."
	else:
		inspection.text = "Town: %s · burg %d · source cell %d\n%d original buildings · %d known facilities\nSelect a marker, roof or facility index." % [active_case.name,int(active_case.burgId),int(active_case.cellId),town_map.model.buildings.size(),town_map.model.establishments.size()]
		if not selected_facility.is_empty():
			var e := selected_facility
			inspection.text += "\n\n%s\nType: %s · %s\nKnowledge: %s\nDistrict: %s\nSource building: %s\nBinding: %s\n%s" % [e.label,e.type,e.locationType,e.knowledge,e.district,str(e.provenance.providerBuildingId) if e.locationType == "building" else "none (outdoor)",e.provenance.binding,e.availability]
		notice.text = "PROVISIONAL: original Settlemaker-local artwork; coast, streets and extent are NOT fitted to this Azgaar region. No physical travel scale or gameplay. Public known facilities only."
	last_error = ""

func _fail(message: String) -> bool:
	last_error = message
	if notice != null: notice.text = message
	return false

func handle_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE: dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var point: Vector2 = viewport.get_canvas_transform().affine_inverse() * event.position
			if level == "world": world_map.select_at(point)
			elif level == "region":
				if region_map.select_burg_at(point): select_region_burg(region_map.selected_source_id)
			else: town_map.inspect_at(point)
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var point: Vector2 = viewport.get_canvas_transform().affine_inverse() * event.position
			var factor: float = 1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1/1.15
			var maximum: float = 50.0 if level == "town" else 4.0
			camera.zoom = Vector2.ONE*clampf(camera.zoom.x*factor,.15,maximum)
			camera.force_update_scroll()
			camera.position += point - viewport.get_canvas_transform().affine_inverse()*event.position
			world_map.set_zoom(camera.zoom.x)
	elif event is InputEventMouseMotion and dragging:
		camera.position -= event.relative/camera.zoom
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F: fit_map()
		elif event.keycode == KEY_ESCAPE: go_back()

func _process(delta: float) -> void:
	if camera == null: return
	var direction := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if direction != Vector2.ZERO: camera.position += direction*500*delta/camera.zoom.x
