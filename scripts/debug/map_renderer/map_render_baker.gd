class_name MapRenderBaker
extends RefCounted

## Deterministically bakes the costly nearest-cell terrain package once per fixture.

const PIXEL_SCALE := 2
const BUCKET_SIZE := 18.0
const SEARCH_RADIUS := 2
const WATER_DEEP := Color("#17282e")
const WATER_SHALLOW := Color("#354b4c")
const PARCHMENT := Color("#a79570")
const POLITICAL_PARCHMENT := Color("#9b8767")
const POLITICAL_ALPHA := 0.19
const BORDER_INK := Color("#302722", 0.64)

# The source biome colours are deliberately not used directly. They are useful
# data, but their saturated categorical palette reads like a GIS overlay.
const BIOME_INKS := {
	"hot desert": Color("#aa9367"),
	"cold desert": Color("#948769"),
	"savanna": Color("#91845d"),
	"grassland": Color("#878462"),
	"tropical seasonal forest": Color("#6f7858"),
	"temperate deciduous forest": Color("#697257"),
	"tropical rainforest": Color("#59694f"),
	"temperate rainforest": Color("#596653"),
	"taiga": Color("#626b58"),
	"tundra": Color("#858272"),
	"glacier": Color("#aaa58f"),
	"wetland": Color("#687565"),
}

func bake(model: MapRenderModel) -> Dictionary:
	var baked_size := Vector2i(maxi(1, model.size.x / PIXEL_SCALE), maxi(1, model.size.y / PIXEL_SCALE))
	var image := Image.create(baked_size.x, baked_size.y, false, Image.FORMAT_RGBA8)
	var ids := PackedInt32Array()
	ids.resize(baked_size.x * baked_size.y)
	var buckets := _make_buckets(model)
	var terrain_colors := _smoothed_terrain_colors(model)
	for y in baked_size.y:
		for x in baked_size.x:
			var map_point := Vector2(x * PIXEL_SCALE + 1, y * PIXEL_SCALE + 1)
			var cell_id := _nearest_cell(model, buckets, map_point)
			ids[y * baked_size.x + x] = cell_id
			image.set_pixel(x, y, _terrain_color(model, terrain_colors, cell_id, x, y))
	_ink_coastline(image, ids, baked_size, model)
	var political_images := _bake_political_images(model, ids, baked_size)
	return {
		"texture": ImageTexture.create_from_image(image),
		"political_texture": ImageTexture.create_from_image(political_images["wash"]),
		"border_texture": ImageTexture.create_from_image(political_images["borders"]),
		"cell_ids": ids,
		"baked_size": baked_size,
		"pixel_scale": PIXEL_SCALE,
	}

func _ink_coastline(image: Image, ids: PackedInt32Array, baked_size: Vector2i, model: MapRenderModel) -> void:
	var coast_ink := Color("#292c27", 0.88)
	for y in range(1, baked_size.y - 1):
		for x in range(1, baked_size.x - 1):
			var cell_id := ids[y * baked_size.x + x]
			if not _is_land(model, cell_id): continue
			var neighbor_ids: Array[Vector2i] = [Vector2i(x - 1, y), Vector2i(x + 1, y), Vector2i(x, y - 1), Vector2i(x, y + 1)]
			for other: Vector2i in neighbor_ids:
				if not _is_land(model, ids[other.y * baked_size.x + other.x]):
					image.set_pixel(x, y, image.get_pixel(x, y).lerp(coast_ink, 0.72))
					break

func _bake_political_images(model: MapRenderModel, ids: PackedInt32Array, baked_size: Vector2i) -> Dictionary:
	var wash := Image.create(baked_size.x, baked_size.y, false, Image.FORMAT_RGBA8)
	var borders := Image.create(baked_size.x, baked_size.y, false, Image.FORMAT_RGBA8)
	wash.fill(Color(0.0, 0.0, 0.0, 0.0))
	borders.fill(Color(0.0, 0.0, 0.0, 0.0))
	for y in baked_size.y:
		for x in baked_size.x:
			var index := y * baked_size.x + x
			var state_id := _land_state(model, ids[index])
			if state_id <= 0: continue
			var record: Dictionary = model.state_records.get(state_id, {})
			var state_color := Color(str(record.get("color", "#8f765c")))
			state_color = state_color.lerp(POLITICAL_PARCHMENT, 0.50)
			state_color.a = POLITICAL_ALPHA
			wash.set_pixel(x, y, state_color)
			if _is_state_edge(model, ids, baked_size, x, y, state_id):
				borders.set_pixel(x, y, BORDER_INK)
	return {"wash": wash, "borders": borders}

func _land_state(model: MapRenderModel, cell_id: int) -> int:
	if not model.valid_cell(cell_id): return 0
	if cell_id >= model.states.size() or cell_id >= model.heights.size(): return 0
	if float(model.heights[cell_id]) < model.LAND_HEIGHT: return 0
	return int(model.states[cell_id])

func _is_state_edge(model: MapRenderModel, ids: PackedInt32Array, baked_size: Vector2i, x: int, y: int, state_id: int) -> bool:
	const OFFSETS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
	for offset: Vector2i in OFFSETS:
		var other: Vector2i = Vector2i(x, y) + offset
		if other.x >= baked_size.x or other.y >= baked_size.y: continue
		var other_state := _land_state(model, ids[other.y * baked_size.x + other.x])
		if other_state > 0 and other_state != state_id: return true
	return false

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

func _smoothed_terrain_colors(model: MapRenderModel) -> Array[Color]:
	var colors: Array[Color] = []
	for cell_id in model.points.size():
		colors.append(_base_land_color(model, cell_id))
	# Neighbour averaging turns thousands of categorical cells into broad,
	# cartographic terrain masses while preserving the canonical fixture.
	for _pass_index in 2:
		var next: Array[Color] = colors.duplicate()
		for cell_id in model.points.size():
			if float(model.heights[cell_id]) < model.LAND_HEIGHT: continue
			var total := colors[cell_id] * 2.5
			var weight := 2.5
			if cell_id < model.neighbors.size():
				for raw_neighbor in model.neighbors[cell_id]:
					var neighbor := int(raw_neighbor)
					if model.valid_cell(neighbor) and float(model.heights[neighbor]) >= model.LAND_HEIGHT:
						total += colors[neighbor]
						weight += 1.0
			next[cell_id] = total / weight
		colors = next
	return colors

func _base_land_color(model: MapRenderModel, cell_id: int) -> Color:
	if not model.valid_cell(cell_id) or float(model.heights[cell_id]) < model.LAND_HEIGHT: return WATER_SHALLOW
	var biome_id := int(model.biomes[cell_id]) if cell_id < model.biomes.size() else 0
	var record: Dictionary = model.biome_records.get(biome_id, {})
	var name := str(record.get("name", "grassland")).to_lower()
	return BIOME_INKS.get(name, Color("#817a5f"))

func _terrain_color(model: MapRenderModel, terrain_colors: Array[Color], cell_id: int, x: int, y: int) -> Color:
	if not model.valid_cell(cell_id): return WATER_DEEP
	var height := float(model.heights[cell_id])
	if height < model.LAND_HEIGHT:
		# Keep the sea visually quiet. Using each nearest water cell's raw depth
		# produced large Voronoi-like blotches around coastlines at world zoom.
		# A restrained common ocean tone leaves coastlines and sea lanes readable.
		var water := WATER_DEEP.lerp(WATER_SHALLOW, 0.38)
		return _apply_grain(water, _paper_grain(x, y) * 0.22)
	var base := terrain_colors[cell_id]
	base = base.lerp(PARCHMENT, clampf((height - 28.0) / 190.0, 0.0, 0.18))
	return _apply_grain(base, _paper_grain(x, y))

func _paper_grain(x: int, y: int) -> float:
	# Two large deterministic waves plus faint grain avoid per-cell spotting.
	var broad := sin(float(x) * 0.033) * 0.012 + cos(float(y) * 0.027) * 0.01
	var grain := float(posmod(x * 37 + y * 19 + (x / 17) * 11, 23) - 11) / 2200.0
	return clampf(broad + grain, -0.02, 0.025)

func _apply_grain(color: Color, amount: float) -> Color:
	return color.lightened(amount) if amount >= 0.0 else color.darkened(-amount)
