class_name OriginLore
extends RefCounted

## Research adapter consumes ONLY the precomputed public projection. The caller
## pins this file's digest to the enrichment version it intends to show.
## It never reads a full sidecar containing hidden facts or changes a save.
var error := ""
var _entries: Dictionary = {}
const KEYS := ["schema_version", "world_id", "burg_id", "enrichment_sha", "content_pack_version", "record_id", "label", "text"]

func load_projection(path: String, expected_file_sha: String) -> bool:
	_entries.clear()
	error = ""
	if expected_file_sha.length() != 64 or FileAccess.get_sha256(path) != expected_file_sha:
		return _fail("Public projection digest mismatch")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("schema_version") != 1 or not parsed.get("entries") is Array:
		return _fail("Unsupported public projection")
	var pending: Dictionary = {}
	for row in parsed.entries:
		if not row is Dictionary or row.size() != KEYS.size():
			return _fail("Unexpected public fields")
		for key in KEYS:
			if not row.has(key):
				return _fail("Missing public field")
		if row.schema_version != 1 or not row.world_id is String or not row.world_id.begins_with("azgaar:1.153.1:"):
			return _fail("World identity mismatch")
		if not row.burg_id is float and not row.burg_id is int:
			return _fail("Invalid burg identity")
		if float(row.burg_id) != floor(float(row.burg_id)) or int(row.burg_id) < 1:
			return _fail("Invalid burg identity")
		if not row.text is String or row.text.is_empty() or row.text.length() > 900:
			return _fail("Invalid public text")
		if not row.enrichment_sha is String or row.enrichment_sha.length() != 64 or row.label != "Local memory":
			return _fail("Invalid public version")
		var key := "%s/burg:%d" % [row.world_id, int(row.burg_id)]
		if pending.has(key):
			return _fail("Duplicate origin record")
		pending[key] = row.duplicate(true)
	_entries = pending
	return true

func get_public(world_id: String, burg_id: int) -> Dictionary:
	return _entries.get("%s/burg:%d" % [world_id, burg_id], {}).duplicate(true)

func _fail(message: String) -> bool:
	error = message
	_entries.clear()
	return false
