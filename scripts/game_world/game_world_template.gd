class_name GameWorldTemplate
extends RefCounted

## Canonical, read-only-in-practice adapter: never change the upstream fixture.
## Only deep copies are returned. Saves contain a reference, not this 5 MB JSON.
const SCHEMA_VERSION := 1
const AZGAAR_VERSION := "1.153.1"
const GROUP_KEYS := {
	"cell": "cells", "state": "states", "province": "provinces",
	"burg": "settlements", "culture": "cultures", "religion": "religions",
	"biome": "biomes", "river": "rivers", "route": "routes", "poi": "markers"
}
var error := ""
var world_id := ""
var seed := ""
var source_sha256 := ""
var world_ref: Dictionary = {}
var _raw: Dictionary = {}
# Override only for isolated tests/custom library roots; not persisted as a path.
var enrichment_directory := ""
var profiles_directory := ""

func load_fixture(path: String) -> bool:
	error = ""
	world_id = ""
	world_ref = {}
	_raw = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("Fixture unavailable: %s" % path)
	var parser := JSON.new()
	var status := parser.parse(file.get_as_text())
	file.close()
	if status != OK or not parser.data is Dictionary:
		return _fail("Invalid world JSON: %s (line %d)" % [parser.get_error_message(), parser.get_error_line()])
	var source: Dictionary = parser.data
	if int(source.get("schemaVersion", -1)) != SCHEMA_VERSION:
		return _fail("Unsupported Azgaar schema version")
	var generator: Dictionary = source.get("generator", {})
	if str(generator.get("provider", "")) != "azgaar" or str(generator.get("version", "")) != AZGAAR_VERSION:
		return _fail("Unrecognised or mismatched Azgaar generator")
	var map_data: Dictionary = source.get("map", {})
	if int(map_data.get("width", 0)) < 1 or int(map_data.get("height", 0)) < 1:
		return _fail("Missing map dimensions")
	var cells: Dictionary = source.get("cells", {})
	var ids: Array = cells.get("ids", [])
	if ids.is_empty() or cells.get("state", []).size() != ids.size() or cells.get("province", []).size() != ids.size():
		return _fail("Missing or inconsistent cell identity arrays")
	for group in ["states", "provinces", "settlements", "cultures", "religions", "biomes", "rivers", "routes", "markers"]:
		if not source.get(group, null) is Array:
			return _fail("Missing entity list: %s" % group)
	var seen: Dictionary = {}
	for i in ids.size():
		var n := int(ids[i])
		if seen.has(n) or n < 0:
			return _fail("Duplicate/invalid cell ID")
		seen[n] = true
	seed = str(source.get("seed", ""))
	if seed.is_empty():
		return _fail("Source seed is missing")
	source_sha256 = FileAccess.get_sha256(path)
	if source_sha256.length() != 64:
		return _fail("Cannot fingerprint fixture")
	world_id = "azgaar:%s:%s:%s" % [AZGAAR_VERSION, seed, source_sha256]
	world_ref = {
		"id": world_id, "seed": seed, "schema_version": SCHEMA_VERSION,
		"generator": generator.duplicate(true), "sha256": source_sha256
	}
	_raw = source
	return true

func _fail(message: String) -> bool:
	error = message
	return false

## IDs use *source numeric keys*, never change when someone renames a burg.
## The world reference is validated separately in the save header.
func entity_id(kind: String, source_id: int) -> String:
	if not GROUP_KEYS.has(kind) or source_id < 0:
		return ""
	if kind == "cell":
		if get_record("cell", source_id).is_empty():
			return ""
	else:
		if get_record(kind, source_id).is_empty():
			return ""
	return "%s:%d" % [kind, source_id]

func get_record(kind: String, source_id: int) -> Dictionary:
	if _raw.is_empty() or source_id < 0 or not GROUP_KEYS.has(kind):
		return {}
	if kind == "cell":
		var cells: Dictionary = _raw["cells"]
		var index := -1
		var ids: Array = cells.get("ids", [])
		for position in ids.size():
			if int(ids[position]) == source_id:
				index = position
				break
		if index < 0:
			return {}
		var record: Dictionary = {"i": source_id}
		for field in cells:
			if cells[field] is Array and index < cells[field].size():
				record[field] = cells[field][index]
		return record.duplicate(true)
	var items: Array = _raw.get(GROUP_KEYS[kind], [])
	# Azgaar arrays often contain sparse/placeholder records, so always check
	# the explicit upstream 'i' field rather than trusting a list position.
	if source_id < items.size() and items[source_id] is Dictionary:
		var candidate: Dictionary = items[source_id]
		if int(candidate.get("i", -1)) == source_id and not candidate.is_empty():
			return candidate.duplicate(true)
	for item in items:
		if item is Dictionary and int(item.get("i", -1)) == source_id and not item.is_empty():
			return item.duplicate(true)
	return {}

func political_columns() -> Dictionary:
	# Read-only bulk view avoids repeated linear cell lookup in integrity checks.
	var out := {}
	for key in ["ids", "heights", "state", "province"]:
		out[key] = _raw.get("cells", {}).get(key, []).duplicate(true)
	return out

func raw_counts() -> Dictionary:
	var counts := {"cells": _raw.get("cells", {}).get("ids", []).size()}
	for name in ["states", "provinces", "settlements", "rivers", "routes", "markers"]:
		counts[name] = _raw.get(name, []).size()
	return counts

func home_candidates(state_id: int, province_id: int = -1, max_count: int = 30) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if get_record("state", state_id).is_empty() or state_id <= 0:
		return result
	if province_id > 0 and get_record("province", province_id).is_empty():
		return result
	var cells: Dictionary = _raw.get("cells", {})
	var states: Array = cells.get("state", [])
	var provinces: Array = cells.get("province", [])
	for value in _raw.get("settlements", []):
		if not value is Dictionary or value.is_empty():
			continue
		var burg: Dictionary = value
		var id := int(burg.get("i", -1))
		var cell := int(burg.get("cell", -1))
		if id <= 0 or cell < 0 or cell >= states.size() or int(states[cell]) != state_id:
			continue
		if province_id > 0 and (cell >= provinces.size() or int(provinces[cell]) != province_id):
			continue
		var population := float(burg.get("population", 0.0))
		if int(burg.get("capital", 0)) != 0 or population <= 0.0 or population > 5.0:
			continue
		if bool(burg.get("hidden", false)) or bool(burg.get("removed", false)):
			continue
		result.append({
			"id": id, "stable_id": entity_id("burg", id),
			"name": str(burg.get("name", "")),
			"cell_id": cell, "state_id": state_id,
			"province_id": int(provinces[cell]) if cell < provinces.size() else 0,
			"population_azgaar_scale": population,
			"group": str(burg.get("group", "")),
			"walls": bool(burg.get("walls", false)),
			"road_access": "unknown", "outside_protection": "unverified"
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["population_azgaar_scale"] != b["population_azgaar_scale"]:
			return float(a["population_azgaar_scale"]) < float(b["population_azgaar_scale"])
		return int(a["id"]) < int(b["id"])
	)
	if max_count >= 0 and result.size() > max_count:
		result.resize(max_count)
	return result

func validate_origin(state_id: int, home_burg_id: int, province_id: int = -1) -> bool:
	for c in home_candidates(state_id, province_id, -1):
		if int(c["id"]) == home_burg_id:
			return true
	return false

## Important: the objective hidden site list never becomes player knowledge.
func objective_marker_count() -> int:
	return _raw.get("markers", []).size()

func validate_save_reference(reference: Dictionary) -> bool:
	# JSON serialization may change numeric Variant representations. Validate
	# canonical fields explicitly rather than requiring Variant-deep-equality.
	if world_ref.is_empty() or reference.is_empty():
		return false
	var expected: Dictionary = world_ref.get("generator", {})
	var actual: Dictionary = reference.get("generator", {})
	return (
		str(reference.get("id", "")) == world_id
		and str(reference.get("seed", "")) == seed
		and str(reference.get("sha256", "")) == source_sha256
		and int(reference.get("schema_version", -1)) == SCHEMA_VERSION
		and str(actual.get("provider", "")) == str(expected.get("provider", ""))
		and str(actual.get("version", "")) == AZGAAR_VERSION
		and str(actual.get("upstreamCommit", "")) == str(expected.get("upstreamCommit", ""))
	)

func source_metadata() -> Dictionary:
	return world_ref.duplicate(true)
