class_name ReliefMapLayer
extends MapLayer

const ReliefRules := preload("res://scripts/debug/map_renderer/relief_presentation.gd")
const SYMBOL_ROOT := "res://assets/map/relief/"
const RIDGE_INK_BASE := Color("#40382f")
const RIDGE_SHADOW_BASE := Color("#786d59")

var _textures: Dictionary = {}

func _ready() -> void:
	for kind_value in ["mount", "mountSnow", "hill"]:
		var kind: String = str(kind_value)
		for variant in range(1, 4):
			var key: String = "%s_%d" % [kind, variant]
			_textures[key] = load(SYMBOL_ROOT + key + ".svg")

func _draw() -> void:
	if not model:
		return
	_draw_ridges(ReliefRules.ridge_segments(model.relief))
	for icon in ReliefRules.visible_icons(model.relief, zoom_band):
		if icon is Dictionary:
			_draw_icon(icon)

func _draw_ridges(segments: Array) -> void:
	var ridge_width: float = 3.4 if zoom_band == 0 else (2.0 if zoom_band == 1 else 1.15)
	var ridge_alpha: float = 0.34 if zoom_band == 0 else (0.28 if zoom_band == 1 else 0.22)
	var flank_width: float = 1.15 if zoom_band == 0 else (0.85 if zoom_band == 1 else 0.6)
	var flank_alpha: float = 0.13 if zoom_band == 0 else (0.11 if zoom_band == 1 else 0.08)
	var flank_offset: float = 4.2 if zoom_band == 0 else (3.0 if zoom_band == 1 else 2.2)
	var segment_stride: int = 3 if zoom_band == 0 else (2 if zoom_band == 1 else 1)
	var ridge_ink := Color(RIDGE_INK_BASE.r, RIDGE_INK_BASE.g, RIDGE_INK_BASE.b, ridge_alpha)
	var ridge_shadow := Color(RIDGE_SHADOW_BASE.r, RIDGE_SHADOW_BASE.g, RIDGE_SHADOW_BASE.b, flank_alpha)

	for segment_index in range(segments.size()):
		if segment_index % segment_stride != 0:
			continue
		var segment: Array = segments[segment_index]
		var start: Vector2 = segment[0]
		var finish: Vector2 = segment[1]
		var direction: Vector2 = finish - start
		if direction.length_squared() < 1.0:
			continue
		var normal: Vector2 = direction.normalized().orthogonal()
		draw_line(start, finish, ridge_ink, ridge_width, true)
		for side_value in [-1.0, 1.0]:
			var side: float = float(side_value)
			var offset: Vector2 = normal * flank_offset * side
			draw_line(
				start.lerp(finish, 0.20) + offset,
				start.lerp(finish, 0.72) + offset,
				ridge_shadow,
				flank_width,
				true
			)

func _draw_icon(icon: Dictionary) -> void:
	var kind: String = str(icon.get("kind", "mount"))
	var variant: int = clampi(int(icon.get("variant", 1)), 1, 3)
	var texture: Texture2D = _textures.get("%s_%d" % [kind, variant])
	if not texture:
		return

	var size: float = clampf(float(icon.get("size", 12.0)), 8.0, 26.0)
	if zoom_band == 0:
		size = clampf(size * 1.7, 18.0, 34.0)
	elif zoom_band == 1:
		size *= 1.15
	if kind == "hill":
		size *= 0.72

	var ratio: float = float(texture.get_height()) / float(texture.get_width())
	var dimensions: Vector2 = Vector2(size, size * ratio)
	var anchor: Vector2 = Vector2(float(icon.get("x", 0.0)), float(icon.get("y", 0.0)))
	draw_texture_rect(texture, Rect2(anchor - Vector2(dimensions.x * 0.5, dimensions.y), dimensions), false)
