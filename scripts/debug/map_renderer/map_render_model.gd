class_name MapRenderModel
extends RefCounted

## Read-only renderer-facing projection. It does not alter the canonical fixture.

const LAND_HEIGHT := 20.0
var fixture: Dictionary
var size := Vector2i(1280, 800)
var points: Array
var heights: Array
var biomes: Array
var states: Array
var neighbors: Array
var state_records: Dictionary = {}
var biome_records: Dictionary = {}
var relief: Array
var slope_hachures: Array

func _init(source: Dictionary) -> void:
	fixture = source
	var map: Dictionary = fixture.get("map", {})
	size = Vector2i(int(map.get("width", 1280)), int(map.get("height", 800)))
	var cells: Dictionary = fixture.get("cells", {})
	points = cells.get("points", [])
	heights = cells.get("heights", [])
	biomes = cells.get("biome", [])
	states = cells.get("state", [])
	neighbors = cells.get("neighbors", [])
	var presentation: Dictionary = fixture.get("presentation", {})
	relief = presentation.get("relief", [])
	slope_hachures = presentation.get("slopeHachures", [])
	for record in fixture.get("states", []):
		if record is Dictionary:
			state_records[int(record.get("i", 0))] = record
	for record in fixture.get("biomes", []):
		if record is Dictionary:
			biome_records[int(record.get("i", 0))] = record

func point(cell_id: int) -> Vector2:
	if cell_id < 0 or cell_id >= points.size(): return Vector2.ZERO
	var value: Variant = points[cell_id]
	return Vector2(float(value[0]), float(value[1])) if value is Array and value.size() >= 2 else Vector2.ZERO

func valid_cell(cell_id: int) -> bool:
	return cell_id >= 0 and cell_id < points.size()
