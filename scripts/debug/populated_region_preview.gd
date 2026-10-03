extends "res://scripts/debug/local_region_preview.gd"

## GAME-40 developer-only populated preview. The underlying source-backed
## regional JSON, not this Node2D renderer, is the immutable data contract.
const POPULATED_CASES := [
	"first", "coast", "river", "mountain", "estuary", "second-world"
]
var reveal_hidden := false
var selected_id := ""
var selected_description := ""

func _ready() -> void:
	camera.position = Vector2(500, 500)
	fit_region()
	load_region("res://tools/regiongen/.tmp/populated-first.json")

func load_region(path: String) -> bool:
	selected_id = ""
	selected_description = ""
	if not super.load_region(path):
		return false
	var layer: Dictionary = region.get("local_sites", {})
	if int(layer.get("schema_version", -1)) != 1 or layer.get("region_id", "") != region.get("id", ""):
		region.clear()
		info.text = "GAME-40 | Missing or mismatched local site layer: generate previews first"
		queue_redraw()
		return false
	_update_description()
	return true

func _visible(site: Dictionary) -> bool:
	if reveal_hidden:
		return true
	return str(site.get("knowledge", "")) in ["discovered", "visited"]

func _update_description() -> void:
	if region.is_empty():
		return
	var area: Dictionary = region.get("region", {})
	var layer: Dictionary = region.get("local_sites", {})
	var all_sites: Array = layer.get("sites", [])
	var shown := 0
	var rumours := 0
	for value in all_sites:
		if not value is Dictionary:
			continue
		if _visible(value):
			shown += 1
		elif str(value.get("knowledge", "")) == "rumoured":
			rumours += 1
	info.text = "FRONTIER REGION | %s | %s km conceptual area | %s visible, %s rumours\n1-6: biome examples   F: fit   ARROWS: pan   WHEEL: zoom   H: %s\n%s" % [
		str(area.get("terrain", "unknown")), str(area.get("side_km", "?")),
		str(shown), str(rumours), "hide developer sites" if reveal_hidden else "developer reveal",
		"CLICK SITE: inspect | Routes and site coordinates are provisional, patrol status unverified"
	]
	if not selected_description.is_empty():
		info.text += "\n" + selected_description

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var choice: int = event.keycode - KEY_1
			reveal_hidden = false
			load_region("res://tools/regiongen/.tmp/populated-%s.json" % POPULATED_CASES[choice])
			fit_region()
			queue_redraw()
			return
		if event.keycode == KEY_H:
			reveal_hidden = not reveal_hidden
			selected_description = ""
			_update_description()
			queue_redraw()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cursor := get_global_mouse_position()
		for value in region.get("local_sites", {}).get("sites", []):
			if not value is Dictionary:
				continue
			var site: Dictionary = value
			if not _visible(site):
				continue
			var coords: Array = site.get("position", [])
			if coords.size() != 2:
				continue
			if cursor.distance_to(Vector2(float(coords[0]), float(coords[1]))) > 21.0:
				continue
			selected_id = str(site.get("id", ""))
			selected_description = "%s [%s] | %s | %s\n%s" % [
				str(site.get("label", "?")), str(site.get("kind", "?")),
				str(site.get("provenance", "?")), str(site.get("knowledge", "?")),
				str(site.get("description", "No inspection detail"))
			]
			_update_description()
			queue_redraw()
			return
	super._unhandled_input(event)

func _draw() -> void:
	super._draw()
	if region.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	var colors := {
		"hometown": Color("#e8c873"),
		"farmstead": Color("#d6b26e"),
		"roadside_inn": Color("#f6d48f"),
		"watchtower": Color("#b5cbd1"),
		"shrine": Color("#d3c4ed"),
		"ruins": Color("#e4a19c"),
		"cave": Color("#b1adc9"),
		"abandoned_camp": Color("#ddd0b5"),
		"ancient_stones": Color("#ddd0b5"),
		"dangerous_woods": Color("#baae7a"),
		"old_mine": Color("#beb5b7")
	}
	for value in region.get("local_sites", {}).get("sites", []):
		if not value is Dictionary:
			continue
		var site: Dictionary = value
		if not _visible(site):
			continue
		var xy: Array = site.get("position", [])
		if xy.size() != 2:
			continue
		var p := Vector2(float(xy[0]), float(xy[1]))
		var kind := str(site.get("kind", ""))
		var chosen_color: Color = colors.get(kind, Color("#e9dcc4"))
		var is_selected := str(site.get("id", "")) == selected_id
		draw_circle(p, 14.0 if is_selected else 11.0, Color("#262c25"))
		draw_arc(p, 14.0 if is_selected else 11.0, 0.0, TAU, 22, chosen_color, 3.0)
		draw_circle(p, 4.5, chosen_color)
		var name := str(site.get("label", "Unknown"))
		var width := clampf(float(name.length()) * 8.2 + 14.0, 75.0, 205.0)
		var px := p.x + 18.0
		if px + width > 985.0:
			px = p.x - width - 17.0
		var rect := Rect2(px, p.y - 13.0, width, 25.0)
		draw_rect(rect, Color("#1c231e", 0.94))
		draw_rect(rect, chosen_color, false, 1.0)
		draw_string(font, Vector2(px + 7.0, p.y + 5.0), name,
				HORIZONTAL_ALIGNMENT_LEFT, width - 12.0, 15, Color("#f8ead4"))
