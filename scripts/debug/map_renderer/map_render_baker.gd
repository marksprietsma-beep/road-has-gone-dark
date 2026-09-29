class_name MapRenderBaker
extends RefCounted

## Deterministically bakes the costly nearest-cell terrain package once per fixture.

const PIXEL_SCALE := 2
const BUCKET_SIZE := 18.0
const SEARCH_RADIUS := 2
const WATER_DEEP := Color("#18364b")
const WATER_SHALLOW := Color("#39758a")

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
	return {"texture": ImageTexture.create_from_image(image), "cell_ids": ids, "baked_size": baked_size, "pixel_scale": PIXEL_SCALE}

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
	var base := Color(str(record.get("color", "#78965b")))
	base = base.lerp(Color("#d6c89c"), clampf((height - 20.0) / 180.0, 0.0, 0.32))
	# Stable sparse relief/noise marks; no runtime randomness.
	var noise := posmod(cell_id * 31 + x * 17 + y * 13, 29)
	if height > 42.0 and noise < 2:
		base = base.darkened(0.14 if noise == 0 else 0.07)
	return base
