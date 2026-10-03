class_name ExpeditionSession
extends RefCounted

## GAME-55: isolated, session-only exploratory loop.
## The displayed direct line is NEVER an established road or walkable path.
## We refuse journeys crossing original macro sea/lakes, but successful
## journeys are abstract story turns, not verified fine-terrain traversal.
const MAX_SUPPLIES := 12
const MAX_DANGER := 8

var source_region: Dictionary = {}
var known: Dictionary = {}
var home: Vector2 = Vector2.ZERO
var position: Vector2 = Vector2.ZERO
var current_id: String = ""
var chosen_id: String = ""
var supplies: int = MAX_SUPPLIES
var danger: int = 0
var hours: int = 0
var clues: int = 0
var journeys: int = 0
var notes: Array[String] = []
var error: String = ""
var ready: bool = false

func _fail(reason: String) -> bool:
	error = reason
	return false

func begin(region: Dictionary) -> bool:
	ready = false
	source_region = {}
	known.clear()
	chosen_id = ""
	error = ""
	notes.clear()
	supplies = MAX_SUPPLIES
	danger = 0
	hours = 0
	clues = 0
	journeys = 0
	var ctx: Dictionary = region.get("source_context", {})
	var sites: Dictionary = region.get("local_sites_v2", {})
	var art: Dictionary = region.get("inferred_fine_v1", {})
	if int(sites.get("schema_version", -1)) != 2 or \
			str(sites.get("source_context_id", "")) != str(ctx.get("id", "")) or \
			str(sites.get("source_world_sha256", "")) != str(ctx.get("parent_source_world_sha256", "")):
		return _fail("Contextual site/source identity mismatch")
	if str(ctx.get("constraints", {}).get("shorelines", "")) != "original_source_features":
		return _fail("Original coastline constraints are missing")
	if art.is_empty() or \
			str(art.get("source_context_id", "")) != str(ctx.get("id", "")) or \
			str(art.get("truth", "")) != "INFERRED_VISUAL_FIELD_NOT_TRAVERSAL":
		return _fail("Inferred scenery must be separate and source-matched")
	var places: Array = sites.get("sites", [])
	if places.is_empty() or str(places[0].get("kind", "")) != "hometown":
		return _fail("No original source hometown")
	var origin: Dictionary = places[0]
	var origin_point: Array = origin.get("position", [])
	var original_home: Array = ctx.get("space", {}).get("home_local", [])
	if origin_point.size() != 2 or origin_point != original_home:
		return _fail("Starting party would be moved off the canonical burg")
	source_region = region
	home = Vector2(float(origin_point[0]), float(origin_point[1]))
	position = home
	current_id = str(origin.get("id", ""))
	for item in places:
		var id: String = str(item.get("id", ""))
		if id.is_empty() or known.has(id):
			return _fail("Missing or repeated site identity")
		var state: String = str(item.get("knowledge", "hidden"))
		if not ["discovered", "visited", "rumoured", "hidden"].has(state):
			return _fail("Unknown knowledge state")
		known[id] = state
	if not is_dry(home):
		return _fail("Hometown not on original macro dry land")
	ready = true
	_log("Three travellers gather at %s. Supplies: %d." % [str(origin.get("label", "the town")), supplies])
	_log("Road protection, crossings and exact walking terrain remain unknown.")
	return true

func _log(message: String) -> void:
	notes.push_front(message)
	if notes.size() > 5:
		notes.resize(5)

func _point(item: Dictionary) -> Vector2:
	var p: Array = item.get("position", [])
	if p.size() != 2:
		return Vector2(-1, -1)
	return Vector2(float(p[0]), float(p[1]))

func _place(id: String) -> Dictionary:
	for item in source_region.get("local_sites_v2", {}).get("sites", []):
		if str(item.get("id", "")) == id:
			return item
	return {}

func _polygon(raw: Variant) -> PackedVector2Array:
	var result := PackedVector2Array()
	if raw is Array:
		for p in raw:
			if p is Array and p.size() >= 2:
				result.append(Vector2(float(p[0]), float(p[1])))
	return result

func is_dry(p: Vector2) -> bool:
	var land := false
	var features: Array = source_region.get("source_context", {}).get("source_features", [])
	for value in features:
		if str(value.get("classification", "")) != "land_boundary":
			continue
		if Geometry2D.is_point_in_polygon(p, _polygon(value.get("local_polygon", []))):
			land = true
	if not land:
		return false
	for value in features:
		if str(value.get("classification", "")) != "freshwater_lake":
			continue
		if Geometry2D.is_point_in_polygon(p, _polygon(value.get("local_polygon", []))):
			return false
	return true

func corridor_uncontradicted(a: Vector2, b: Vector2) -> bool:
	# This is only a conservative macro WATER EXCLUSION filter.
	# It is *not* fine-resolution navigation or proof of travel access.
	if not ready:
		return false
	var count: int = maxi(1, int(ceilf(a.distance_to(b) / 4.0)))
	for i in range(count + 1):
		if not is_dry(a.lerp(b, float(i) / count)):
			return false
	return true

func visible_sites() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for value in source_region.get("local_sites_v2", {}).get("sites", []):
		var id: String = str(value.get("id", ""))
		if ["discovered", "visited"].has(str(known.get(id, "hidden"))):
			# Copy before sending anything to a HUD, preventing debug-only
			# mutation of the full generation data.
			results.append((value as Dictionary).duplicate(true))
	return results

func site_is_visible(site: Dictionary) -> bool:
	return ["discovered", "visited"].has(str(known.get(str(site.get("id", "")), "hidden")))

func select_site(id: String) -> bool:
	if not ready or not site_is_visible(_place(id)) or _place(id).is_empty():
		return _fail("Location not yet discovered")
	chosen_id = id
	error = ""
	return true

func travel_to_selected() -> bool:
	if not ready:
		return _fail("No expedition loaded")
	if chosen_id.is_empty() or not site_is_visible(_place(chosen_id)):
		return _fail("Select a known location first")
	if chosen_id == current_id:
		return _fail("Already at this place")
	if supplies <= 0 or danger >= MAX_DANGER:
		return _fail("Party exhausted. Return to town or end the expedition.")
	var target: Dictionary = _place(chosen_id)
	var destination: Vector2 = _point(target)
	if not corridor_uncontradicted(position, destination):
		return _fail("Unknown water or coastline crossing: journey withheld")
	var turns: int = maxi(1, int(ceilf(position.distance_to(destination) / 130.0)))
	if turns > supplies:
		return _fail("Insufficient supplies for this abstract journey")
	hours += turns * 3
	supplies -= turns
	journeys += 1
	danger = mini(MAX_DANGER, danger + (1 if turns > 2 else 0))
	position = destination
	current_id = chosen_id
	error = ""
	_log("Reached %s after %d journey turns. Safety unverified." % [str(target.get("label", "site")), turns])
	return true

func scout() -> bool:
	if not ready or supplies < 1 or danger >= MAX_DANGER:
		return _fail("Cannot scout without supplies or while overwhelmed")
	supplies -= 1
	hours += 2
	# A locality-relative discovery. Unknown details stay private until now.
	var next: Dictionary = {}
	var nearest := 300.0
	for site in source_region.get("local_sites_v2", {}).get("sites", []):
		var id: String = str(site.get("id", ""))
		if ["hidden", "rumoured"].has(str(known.get(id, ""))):
			var d: float = position.distance_to(_point(site))
			if d < nearest:
				nearest = d
				next = site
	error = ""
	if next.is_empty():
		_log("Found no new leads nearby.")
		return true
	var id: String = str(next.get("id", ""))
	known[id] = "discovered"
	_log("A new lead emerges: %s." % str(next.get("label", "unknown")))
	return true

func investigate(method: String) -> bool:
	if not ready or not ["careful", "bold"].has(method):
		return _fail("Choose a valid investigation approach")
	var here: Dictionary = _place(current_id)
	if here.is_empty() or str(here.get("kind", "")) == "hometown":
		return _fail("Visit a discovered site before investigating")
	if str(known.get(current_id, "")) == "visited":
		return _fail("This location has already been investigated")
	if supplies <= 0:
		return _fail("Party lacks supplies to investigate")
	supplies -= 1 if method == "careful" else 0
	hours += 2 if method == "careful" else 1
	clues += 1 if method == "careful" else 2
	danger = mini(MAX_DANGER, danger + (0 if method == "careful" else 2))
	known[current_id] = "visited"
	error = ""
	_log(("%s surveyed cautiously." if method == "careful" else "%s explored recklessly; danger increased.") % str(here.get("label", "Location")))
	return true

func rest_at_home() -> bool:
	if not ready or not corridor_uncontradicted(position, home):
		return _fail("No verified dry macro-corridor back; cannot assume a crossing")
	hours += maxi(1, int(ceilf(position.distance_to(home) / 130.0))) * 3
	position = home
	current_id = str(source_region.get("local_sites_v2", {}).get("sites", [])[0].get("id", ""))
	chosen_id = current_id
	supplies = MAX_SUPPLIES
	danger = maxi(0, danger - 3)
	error = ""
	_log("Returned to town and resupplied. No safe road is established.")
	return true
