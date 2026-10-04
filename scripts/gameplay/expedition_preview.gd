extends "res://scripts/debug/contextual_region_preview.gd"

## GAME-55 opt-in playable slice. No campaign/save/schema writes.
## Journey duration is abstract; source dry-land only excludes obvious water,
## never certifies real trails, bridges, patrols or pathfinding.
var expedition: ExpeditionSession = ExpeditionSession.new()
@onready var party_status: Label = $HUD/PartyStatus
@onready var journal: Label = $HUD/Journal

func _ready() -> void:
	super._ready()
	call_deferred("_refresh")

func fit_map() -> void:
	# Compact 640×360 logical layout: source map left; journal panel right.
	camera.position = Vector2(1000.0, 500.0)
	camera.zoom = Vector2(0.33, 0.33)

func _base_info() -> String:
	return "THE ROAD HAS GONE DARK\nClick a known site: select\nT: Journey   S: Scout\nC: Cautious   B: Bold\nR: Return   V: Terrain\n1–6: Regions   F: Fit   Esc: Exit"

func load_region(path: String) -> bool:
	if not super.load_region(path):
		return false
	if not expedition.begin(region):
		info.text = "Expedition data invalid: " + expedition.error
		region.clear()
		queue_redraw()
		return false
	# The hidden-site debug switch is disabled in this gameplay view.
	reveal_hidden_for_developer = false
	show_route_audit = false
	selected_local_id = ""
	_refresh()
	queue_redraw()
	return true

func _site_is_visible(site: Dictionary) -> bool:
	return expedition.site_is_visible(site)

func _encounter_preview_available() -> bool:
	# Prototype occupants are not campaign enemies, even if debug data exists.
	return false

func _route_preview_available() -> bool:
	return false

func select_local_site_at(point: Vector2) -> bool:
	if not super.select_local_site_at(point):
		return false
	if not expedition.select_site(selected_local_id):
		selected_local_id = ""
		_refresh()
		return false
	_refresh()
	return true

func _action(action: String) -> void:
	var okay: bool = false
	match action:
		"journey":
			okay = expedition.travel_to_selected()
		"scout":
			okay = expedition.scout()
		"careful", "bold":
			okay = expedition.investigate(action)
		"return":
			okay = expedition.rest_at_home()
	if not okay:
		expedition._log(expedition.error)
	selected_local_id = expedition.chosen_id
	info.text = _base_info()
	_refresh()
	queue_redraw()

func _refresh() -> void:
	if not is_node_ready() or expedition == null or not expedition.ready:
		return
	var position_name: String = "Hometown"
	var place: Dictionary = expedition._place(expedition.current_id)
	if not place.is_empty():
		position_name = str(place.get("label", "Hometown"))
	var chosen: String = "none"
	if not expedition.chosen_id.is_empty():
		var choice: Dictionary = expedition._place(expedition.chosen_id)
		if expedition.site_is_visible(choice):
			chosen = str(choice.get("label", "none"))
	party_status.text = "THREE TRAVELLERS\nSupplies %d/%d  Danger %d/%d\nClues %d   Hours %d\nAt: %s\nTarget: %s" % [
		expedition.supplies, expedition.MAX_SUPPLIES,
		expedition.danger, expedition.MAX_DANGER,
		expedition.clues, expedition.hours, position_name, chosen]
	journal.text = "RECENT EVENTS\n" + "\n".join(expedition.notes.slice(0, 4))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_T:
				_action("journey")
				return
			KEY_S:
				_action("scout")
				return
			KEY_C:
				_action("careful")
				return
			KEY_B:
				_action("bold")
				return
			KEY_R:
				_action("return")
				return
			KEY_H, KEY_A, KEY_E, KEY_P, KEY_BRACKETLEFT, KEY_BRACKETRIGHT, KEY_0:
				# No god-mode debug reveal in an actual party view.
				return
			KEY_ESCAPE:
				# This is an isolated F6 prototype; do not mutate main menu.
				get_tree().quit()
				return
	super._unhandled_input(event)
	_refresh()

func _draw() -> void:
	super._draw()
	if not expedition.ready:
		return
	var p: Vector2 = expedition.position
	# Party glyph: three travellers. Markers are illustrative only and
	# are not a collision mesh or verified walkable travel coordinates.
	draw_circle(p, 15.0, Color("#e8d4a7", .8))
	draw_arc(p, 15.0, 0.0, TAU, 36, Color("#402c22"), 2.0)
	for offset in [Vector2(-6, 2), Vector2(6, 2), Vector2(0, -5)]:
		draw_circle(p + offset, 3.8, Color("#3d3930"))
