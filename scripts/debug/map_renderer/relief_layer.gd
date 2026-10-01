class_name ReliefMapLayer
extends MapLayer

## Presentation-only cartographic relief. Placement comes from the generated
## provider-neutral model; project-owned art controls its atlas appearance.

const INK := Color("#3f392f")
const RIDGE_LIGHT := Color("#b8a77c")
const VEGETATION_KINDS := {
	"conifer": true, "coniferSnow": true, "deciduous": true,
	"swamp": true, "cactus": true, "deadTree": true
}
const SYMBOLS := {
	"mount": [preload("res://assets/map/relief/mount_1.svg"), preload("res://assets/map/relief/mount_2.svg"), preload("res://assets/map/relief/mount_3.svg")],
	"mountSnow": [preload("res://assets/map/relief/mount_snow_1.svg"), preload("res://assets/map/relief/mount_snow_2.svg"), preload("res://assets/map/relief/mount_snow_3.svg")],
	"hill": [preload("res://assets/map/relief/hill_1.svg"), preload("res://assets/map/relief/hill_2.svg"), preload("res://assets/map/relief/hill_3.svg")],
	"vegetation": [preload("res://assets/map/relief/vegetation_1.svg"), preload("res://assets/map/relief/vegetation_2.svg"), preload("res://assets/map/relief/vegetation_3.svg")]
}

func _draw() -> void:
	if not model:
		return
	_draw_ridge_mass()
	if zoom_band == 0:
		_draw_overview_peaks()
	else:
		_draw_symbols()

func _draw_overview_peaks() -> void:
	# A sparse set of large peaks anchors the connected ridge marks without
	# turning a fitted map into a wall of stamps.
	for item in model.relief:
		if not item is Dictionary or str(item.get("kind", "")) not in ["mount", "mountSnow"]:
			continue
		if int(item.get("order", 0)) % 4 != 0:
			continue
		var kind := str(item.get("kind", "mount"))
		var variants: Array = SYMBOLS[kind]
		var variant := maxi(1, int(item.get("variant", 1)))
		var texture: Texture2D = variants[(variant - 1) % variants.size()]
		var size := maxf(10.0, float(item.get("size", 8.0)) * 1.15)
		var center := Vector2(float(item.get("x", 0)), float(item.get("y", 0))) + Vector2.ONE * float(item.get("size", 8.0)) * 0.5
		draw_texture_rect(texture, Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size), false, Color(1, 1, 1, 0.54))

func _draw_ridge_mass() -> void:
	# Overview receives the strongest continuous cue; it recedes as the actual
	# illustrations become readable. Width is expressed in map coordinates so
	# fit-to-map relief does not vanish into hairlines.
	var alpha := 0.46 if zoom_band == 0 else (0.31 if zoom_band == 1 else 0.20)
	var width := 1.65 if zoom_band == 0 else 1.15
	for stroke in model.slope_hachures:
		if not stroke is Dictionary:
			continue
		var strength := float(stroke.get("strength", 0.5))
		var a := Vector2(float(stroke.get("x1", 0)), float(stroke.get("y1", 0)))
		var b := Vector2(float(stroke.get("x2", 0)), float(stroke.get("y2", 0)))
		draw_line(a, b, Color(INK, alpha * strength), width, true)
		if zoom_band == 0 and strength > 0.6:
			draw_line(a + Vector2(-0.8, 0), b + Vector2(-0.8, 0), Color(RIDGE_LIGHT, 0.16), 0.7, true)

func _draw_symbols() -> void:
	var symbol_alpha := 0.72 if zoom_band == 1 else 0.96
	for item in model.relief:
		if not item is Dictionary:
			continue
		var kind := str(item.get("kind", ""))
		var vegetation := VEGETATION_KINDS.has(kind) or kind not in ["mount", "mountSnow", "hill"]
		# Vegetation remains a quiet texture at medium range and only resolves
		# into individual marks close up.
		if vegetation and zoom_band < 2:
			continue
		var key := "vegetation" if vegetation else kind
		if not SYMBOLS.has(key):
			continue
		var variants: Array = SYMBOLS[key]
		var variant := maxi(1, int(item.get("variant", 1)))
		var texture: Texture2D = variants[(variant - 1) % variants.size()]
		var size := float(item.get("size", 8.0))
		if vegetation:
			size *= 0.68
		var rect := Rect2(Vector2(float(item.get("x", 0)), float(item.get("y", 0))), Vector2(size, size))
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.43 if vegetation else symbol_alpha))
