class_name GamePlaythroughStore
extends RefCounted

## Save service owns only mutable campaign state. Canonical Azgaar JSON is
## referenced by content SHA, never copied into a save or modified in place.
const SAVE_VERSION := 1
var save_root := "user://game_world_saves"
var error := ""

func _fail(message: String) -> Dictionary:
	error = message
	return {"ok": false, "error": message}

func _slot_path(slot: String) -> String:
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9_-]{1,64}$")
	if pattern.search(slot) == null:
		return ""
	return save_root.path_join(slot + ".json")

func create_playthrough(world: GameWorldTemplate, state_id: int, burg_id: int, province_id: int = -1) -> Dictionary:
	error = ""
	if not world.validate_origin(state_id, burg_id, province_id):
		return _fail("Starting hometown is not an eligible real small settlement in the selected region")
	var burg := world.get_record("burg", burg_id)
	var home_province := int(world.get_record("cell", int(burg.get("cell", -1))).get("province", 0))
	var characters: Array[Dictionary] = []
	var campaign_id := Crypto.new().generate_random_bytes(16).hex_encode()
	for n in range(3):
		characters.append({
			"id": campaign_id + ":adventurer:" + str(n + 1),
			"name": "Adventurer %d" % (n + 1),
			"build_version": 0, "build": {}, "conditions": [],
			"assignment": "travelling", "rules_pack": "pf1e-derived:planned"
		})
	return {
		"ok": true,
		"state": {
			"save_version": SAVE_VERSION,
			"playthrough_id": campaign_id,
			"world_ref": world.source_metadata(),
			"origin": {
				"state_id": state_id,
				"province_id": home_province,
				"home_burg_id": burg_id,
				"home_id": world.entity_id("burg", burg_id)
			},
			"characters": characters,
			"party_ids": characters.map(func(c: Dictionary) -> String: return str(c["id"])),
			"player_knowledge": {
				"known_burg_ids": [world.entity_id("burg", burg_id)],
				"rumoured_poi_ids": [],
				"discovered_poi_ids": [],
				"visited_poi_ids": []
			},
			"world_deltas": {},
			"game_clock": {"tick": 0, "time_unit": "unassigned"}
		}
	}

func save_new(slot: String, state: Dictionary, world: GameWorldTemplate) -> Dictionary:
	return _write(slot, state, world, false)

func save_existing(slot: String, state: Dictionary, world: GameWorldTemplate) -> Dictionary:
	return _write(slot, state, world, true)

func _write(slot: String, state: Dictionary, world: GameWorldTemplate, replace_existing: bool) -> Dictionary:
	error = ""
	var path := _slot_path(slot)
	if path.is_empty():
		return _fail("Unsafe save slot name")
	var validated := _validate(state, world)
	if not validated.is_empty():
		return _fail(validated)
	var real_root := ProjectSettings.globalize_path(save_root)
	if DirAccess.make_dir_recursive_absolute(real_root) != OK:
		return _fail("Cannot create save directory")
	var full := ProjectSettings.globalize_path(path)
	var temp := full + ".tmp"
	var backup := full + ".bak"
	if FileAccess.file_exists(full) and not replace_existing:
		return _fail("Save already exists and was not overwritten")
	if replace_existing and not FileAccess.file_exists(full):
		return _fail("Save to update was not found")
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return _fail("Cannot create temporary save file")
	file.store_string(JSON.stringify(state, "  "))
	file.flush()
	file.close()
	# Back up the old save before replacement: works on Windows too, where
	# filesystem rename cannot always overwrite an existing destination.
	var backed_up := false
	if replace_existing:
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(full, backup) != OK:
			DirAccess.remove_absolute(temp)
			return _fail("Cannot back up previous save")
		backed_up = true
	if DirAccess.rename_absolute(temp, full) != OK:
		if backed_up:
			DirAccess.rename_absolute(backup, full)
		DirAccess.remove_absolute(temp)
		return _fail("Could not commit save file")
	if backed_up:
		DirAccess.remove_absolute(backup)
	return {"ok": true, "slot": slot}

func load_save(slot: String, world: GameWorldTemplate) -> Dictionary:
	error = ""
	var path := _slot_path(slot)
	if path.is_empty():
		return _fail("Unsafe save slot name")
	var full := ProjectSettings.globalize_path(path)
	# Recover an interrupted update when only its older backup remains.
	if not FileAccess.file_exists(full) and FileAccess.file_exists(full + ".bak"):
		if DirAccess.rename_absolute(full + ".bak", full) != OK:
			return _fail("Failed to recover interrupted save update")
	var file := FileAccess.open(full, FileAccess.READ)
	if file == null:
		return _fail("Save file not found")
	var parser := JSON.new()
	var parse_status := parser.parse(file.get_as_text())
	file.close()
	if parse_status != OK or not parser.data is Dictionary:
		return _fail("Save JSON is corrupt")
	var state: Dictionary = parser.data
	var why := _validate(state, world)
	if not why.is_empty():
		return _fail(why)
	return {"ok": true, "state": state}

func _validate(state: Dictionary, world: GameWorldTemplate) -> String:
	if int(state.get("save_version", -1)) != SAVE_VERSION:
		return "Unsupported save schema version"
	if not world.validate_save_reference(state.get("world_ref", {})):
		return "Missing or mismatched world template/version/fingerprint"
	if str(state.get("playthrough_id", "")).is_empty():
		return "Missing playthrough ID"
	var origin: Dictionary = state.get("origin", {})
	var sid := int(origin.get("state_id", -1))
	var bid := int(origin.get("home_burg_id", -1))
	if not world.validate_origin(sid, bid):
		return "Origin does not correspond to an eligible source hometown"
	if str(origin.get("home_id", "")) != world.entity_id("burg", bid):
		return "Source hometown stable ID mismatch"
	var party: Array = state.get("party_ids", [])
	var characters: Array = state.get("characters", [])
	if characters.size() != 3 or party.size() != 3:
		return "First-version playthrough requires three character records"
	var member_ids: Dictionary = {}
	for member in characters:
		if not member is Dictionary or str(member.get("id", "")).is_empty():
			return "Invalid character record"
		var id := str(member["id"])
		if member_ids.has(id):
			return "Duplicate character ID"
		member_ids[id] = true
	for member_id in party:
		if not member_ids.has(str(member_id)):
			return "Party refers to an unknown character"
	var knowledge: Dictionary = state.get("player_knowledge", {})
	for field in ["known_burg_ids", "rumoured_poi_ids", "discovered_poi_ids", "visited_poi_ids"]:
		if not knowledge.get(field, null) is Array:
			return "Invalid player knowledge structure"
	for field in ["rumoured_poi_ids", "discovered_poi_ids", "visited_poi_ids"]:
		for pid in knowledge[field]:
			if not pid is String or not str(pid).begins_with("poi:"):
				return "Invalid player-known POI reference"
			var index_text := str(pid).trim_prefix("poi:")
			if not index_text.is_valid_int() or world.get_record("poi", int(index_text)).is_empty():
				return "Player knowledge references a nonexistent POI"
	if not state.get("world_deltas", null) is Dictionary or not state.get("game_clock", null) is Dictionary:
		return "Missing mutable game state"
	return ""
