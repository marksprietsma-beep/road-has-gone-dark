class_name LandmarkMapLayer
extends MapLayer

## Exact upstream types retain original Game-icons role aliases from GAME-28.
const EXISTING_ROLE_ALIASES := {
	"ruins": "ruins",
	"caves": "cave",
	"lighthouses": "lighthouse",
	"mines": "mine",
}
const MEDIUM_ZOOM_TYPES := ["volcanoes", "ruins", "battlefields", "lighthouses"]
## Prioritise permanent story hooks and dangers over routine waypoints.
## Stable original marker ID breaks ties: density/pan/scroll order cannot
## unpredictably decide which landmark wins a collision.
const IMPORTANT_TYPES := [
	"volcanoes", "ruins", "battlefields", "lighthouses", "dungeons",
	"portals", "rifts", "necropolises", "sacred-mountains",
]
const DANGER_TYPES := [
	"sea-monsters", "lake-monsters", "hill-monsters", "brigands",
	"pirates", "disturbed-burials", "caves", "waterfalls", "mines",
]
const GRID_SIZE := 32.0
const MIN_ICON_SPACE_SCREEN := 23.0

var icon_provider: MapIconProvider
var declutter_enabled := true
var display_zoom := 1.0
var _warned_unknown_types: Dictionary = {}
## Only markers actually drawn may be clicked. A marker deliberately hidden
## by the source, zoom band or the collision filter is not an inspectable icon.
var displayed_markers: Array[Dictionary] = []

func marker_near(position: Vector2, radius: float) -> Dictionary:
	if not visible or not is_inside_tree():
		return {}
	var nearest: Dictionary = {}
	var min_dist_sq := radius * radius
	for marker in displayed_markers:
		var at := Vector2(float(marker.get("x", 0)), float(marker.get("y", 0)))
		var distance := position.distance_squared_to(at)
		if distance <= min_dist_sq:
			min_dist_sq = distance
			nearest = marker
	return nearest

func set_icon_provider(value: MapIconProvider) -> void:
	icon_provider = value
	queue_redraw()

func set_display_zoom(value: float) -> void:
	if is_equal_approx(display_zoom, value):
		return
	display_zoom = value
	queue_redraw()

func set_declutter_enabled(enabled: bool) -> void:
	if declutter_enabled == enabled:
		return
	declutter_enabled = enabled
	queue_redraw()

func _draw() -> void:
	displayed_markers.clear()
	if not model or not icon_provider or zoom_band == 0:
		return

	var candidates: Array[Dictionary] = []
	var sequence := 0
	for marker in model.fixture.get("markers", []):
		if not marker is Dictionary or bool(marker.get("hidden", false)):
			continue
		var kind := str(marker.get("type", ""))
		if zoom_band == 1 and kind not in MEDIUM_ZOOM_TYPES:
			continue
		var known := kind in MapIconProvider.MARKER_TYPES
		var role := str(EXISTING_ROLE_ALIASES.get(kind, kind)) if known else "unidentified"
		if not known and not _warned_unknown_types.has(kind):
			_warned_unknown_types[kind] = true
			push_warning("Unknown Azgaar marker type '%s'; using neutral authored pin" % kind)
		candidates.append({
			"marker": marker, "role": role,
			"priority": _priority(kind), "sequence": sequence
		})
		sequence += 1

	if declutter_enabled:
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if a["priority"] != b["priority"]:
				return int(a["priority"]) > int(b["priority"])
			return int(a["sequence"]) < int(b["sequence"])
		)

	var occupied: Dictionary = {}
	if declutter_enabled:
		_reserve_civilization(occupied)

	# Compare overlap in screen pixels, converted to map units. This means a
	# large UI viewport or zoom does not introduce fake new world locations.
	var diameter := maxf(7.0, MIN_ICON_SPACE_SCREEN / maxf(display_zoom, 0.25))
	for entry in candidates:
		var marker: Dictionary = entry["marker"]
		var p := Vector2(float(marker.get("x", 0.0)), float(marker.get("y", 0.0)))
		if declutter_enabled:
			var bounds := Rect2(p - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter)
			if _overlaps(occupied, bounds):
				continue
			_stamp(occupied, bounds)
		_draw_icon(p, str(entry["role"]))
		displayed_markers.append(marker)

func _priority(kind: String) -> int:
	if kind in IMPORTANT_TYPES:
		return 3
	if kind in DANGER_TYPES:
		return 2
	return 1

func _reserve_civilization(occupied: Dictionary) -> void:
	var settlements_node := get_parent().get_node_or_null("Settlements")
	if settlements_node and settlements_node.visible:
		for settlement in model.fixture.get("settlements", []):
			if not settlement is Dictionary or not settlements_node.should_display(settlement): continue
			var p := Vector2(float(settlement.get("x", 0.0)), float(settlement.get("y", 0.0)))
			var icon_size: float = settlements_node.icon_size(settlement)
			var gap := maxf(icon_size + 4.0, 16.0 / maxf(display_zoom, 0.25))
			_stamp(occupied, Rect2(p - Vector2.ONE * gap * 0.5, Vector2.ONE * gap))

	# Labels now avoid actual drawn icons; no duplicate label estimates or cyclic claims.

## Small spatial hash avoids scanning all settlements and landmarks for
## every marker, even in the deliberately crowded 8x stress fixture.
func _buckets(bounds: Rect2) -> Array[Vector2i]:
	var first := Vector2i(floori(bounds.position.x / GRID_SIZE), floori(bounds.position.y / GRID_SIZE))
	var last := Vector2i(floori(bounds.end.x / GRID_SIZE), floori(bounds.end.y / GRID_SIZE))
	var result: Array[Vector2i] = []
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			result.append(Vector2i(x, y))
	return result

func _overlaps(occupied: Dictionary, bounds: Rect2) -> bool:
	for cell in _buckets(bounds):
		if not occupied.has(cell):
			continue
		for other: Rect2 in occupied[cell]:
			if other.intersects(bounds):
				return true
	return false

func _stamp(occupied: Dictionary, bounds: Rect2) -> void:
	for cell in _buckets(bounds):
		if not occupied.has(cell):
			occupied[cell] = []
		occupied[cell].append(bounds)

func _draw_icon(p: Vector2, role: String) -> void:
	var texture := icon_provider.texture_for(role)
	if texture:
		var source := texture.get_size()
		var size := source * (7.0 / maxf(source.x, source.y))
		draw_texture_rect(texture, Rect2(p - size * 0.5, size), false)
	else:
		# A missing expected asset must still be visible as a real error.
		draw_line(p + Vector2(-2, -2), p + Vector2(2, 2), Color("#a8493f"), 1.0)
		draw_line(p + Vector2(2, -2), p + Vector2(-2, 2), Color("#a8493f"), 1.0)
