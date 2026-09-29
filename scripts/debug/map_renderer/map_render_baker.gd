class_name MapRenderBaker
extends RefCounted

## Deterministically bakes the costly nearest-cell terrain package once per fixture.

const PIXEL_SCALE := 2
const BUCKET_SIZE := 18.0
const SEARCH_RADIUS := 2
const WATER_DEEP := Color("#172c35")
const WATER_SHALLOW := Color("#38575a")
const COAST_INK := Color("#332d25")
const PARCHMENT := Color("#b7a276")

const BIOME_PALETTE := {
	"Hot desert": Color("#a98c5e"),
	"Cold desert": Color("#95866a"),
	"Savanna": Color("#8b8355"),
	"Grassland": Color("#78805a"),
	"Tropical seasonal forest": Color("#52664c"),
	"Temperate deciduous forest": Color("#495d47"),
	"Tropical rainforest": Color("#3d5544"),
	"Temperate rainforest": Color("#405246"),
	"Taiga": Color("#485247"),
	"Tundra": Color("#817964"),
	"Glacier": Color("#a9aa9d"),
	"Wetland": Color("#526456"),
}

func bake(model: MapRenderModel) -> Dictionary:
	var baked_size := Vector2i(maxi(1, model.size.x / PIXEL_SCALE), maxi(1, model.size.y / PIXEL_SCALE))
	var image := Image.create(baked_size.x, baked_size.y, false, Image.FORMAT_RGBA8)
	var ids := PackedInt32Array()
	ids.resize(baked_size.x * baked_size.y)
	var buckets := _make_buckets(model)
	for y in baked_size.y:
		for x in baked_size.x:
			var map_point := Vector2(x * PIXEL_SCALE + 1, y * PIXEL_SCALE + 1)
			var cell_id := _nearest_cell(model, buckets, map_point)
			ids[y * baked_size.x + x] = cell_id
			image.set_pixel(x, y, _terrain_color(model, cell_id, x, y))
	_ink_coastline(image, ids, model, baked_size)
	return {"texture": ImageTexture.create_from_image(image), "cell_ids": ids, "baked_size": baked_size, "pixel_scale": PIXEL_SCALE}

func _ink_coastline(image: Image, ids: PackedInt32Array, model: MapRenderModel, size: Vector2i) -> void:
	# A restrained double shoreline keeps continents legible at every zoom level.
	for y in size.y:
		for x in size.x:
			var index := y * size.x + x
			var land := _is_land(model, ids[index])
			var edge := false
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var other := Vector2i(x, y) + offset
				if other.x >= 0 and other.y >= 0 and other.x < size.x and other.y < size.y:
					edge = edge or land != _is_land(model, ids[other.y * size.x + other.x])
			if edge:
				image.set_pixel(x, y, image.get_pixel(x, y).lerp(COAST_INK, 0.72 if land else 0.48))

func _is_land(model: MapRenderModel, cell_id: int) -> bool:
	return model.valid_cell(cell_id) and cell_id < model.heights.size() and float(model.heights[cell_id]) >= model.LAND_HEIGHT

func _make_buckets(model: MapRenderModel) -> Dictionary:
	var buckets := {}
	for cell_id in model.points.size():
		var p := model.point(cell_id)
		var key := Vector2i(floori(p.x / BUCKET_SIZE), floori(p.y / BUCKET_SIZE))
		if not buckets.has(key): buckets[key] = []
		buckets[key].append(cell_id)
	return buckets

func _nearest_cell(model: MapRenderModel, buckets: Dictionary, p: Vector2) -> int:
	var origin := Vector2i(floori(p.x / BUCKET_SIZE), floori(p.y / BUCKET_SIZE))
	var winner := -1
	var best := INF
	for by in range(origin.y - SEARCH_RADIUS, origin.y + SEARCH_RADIUS + 1):
		for bx in range(origin.x - SEARCH_RADIUS, origin.x + SEARCH_RADIUS + 1):
			for cell_id in buckets.get(Vector2i(bx, by), []):
				var distance := p.distance_squared_to(model.point(cell_id))
				if distance < best:
					best = distance
					winner = cell_id
	return winner

func _terrain_color(model: MapRenderModel, cell_id: int, x: int, y: int) -> Color:
	if not model.valid_cell(cell_id): return WATER_DEEP
	var height := float(model.heights[cell_id])
	if height < model.LAND_HEIGHT:
		return WATER_DEEP.lerp(WATER_SHALLOW, clampf(height / model.LAND_HEIGHT, 0.0, 1.0))
	var biome_id := int(model.biomes[cell_id]) if cell_id < model.biomes.size() else 0
	var record: Dictionary = model.biome_records.get(biome_id, {})
	var base: Color = BIOME_PALETTE.get(str(record.get("name", "")), Color("#77775c"))
	base = base.lerp(PARCHMENT, clampf((height - 20.0) / 150.0, 0.0, 0.34))
	# Stable sparse relief/noise marks; no runtime randomness.
	var noise := posmod(cell_id * 31 + x * 17 + y * 13, 29)
	if noise < 3: base = base.lightened(0.035)
	elif noise > 26: base = base.darkened(0.055)
	if height > 42.0 and noise < 5: base = base.darkened(0.09)
	return base
