class_name ReliefMapLayer
extends MapLayer

const ReliefRules := preload("res://scripts/debug/map_renderer/relief_presentation.gd")
const SYMBOL_ROOT := "res://assets/map/relief/"
const RIDGE_INK := Color("#40382f", 0.30)
const RIDGE_SHADOW := Color("#786d59", 0.18)

var _textures := {}

func _ready() -> void:
	for kind in ["mount", "mountSnow", "hill"]:
		for variant in range(1, 4):
			var key := "%s_%d" % [kind, variant]
			_textures[key] = load(SYMBOL_ROOT + key + ".svg")

func _draw() -> void:
	if not model:
		return
	_draw_ridges(ReliefRules.ridge_segments(model.relief))
	# Fitted view intentionally has no individual stamps: ridge structure alone
	# carries the mountain geography without turning clusters into black knots.
	for icon in ReliefRules.visible_icons(model.relief, zoom_band):
		_draw_icon(icon)

func _draw_ridges(segments: Array) -> void:
	for segment in segments:
		var start: Vector2 = segment[0]
		var finish: Vector2 = segment[1]
		var direction := finish - start
		if direction.length_squared() < 1.0:
			continue
		var normal := direction.normalized().orthogonal()
		draw_line(start, finish, RIDGE_INK, 0.85, true)
		# Two quiet, broken-looking flank strokes imply mass without per-icon piles.
		for side in [-1.0, 1.0]:
			var offset := normal * 2.2 * side
			draw_line(start.lerp(finish, 0.16) + offset, start.lerp(finish, 0.72) + offset, RIDGE_SHADOW, 0.65, true)

func _draw_icon(icon: Dictionary) -> void:
	var kind := str(icon.get("kind", "mount"))
	var variant := clampi(int(icon.get("variant", 1)), 1, 3)
	var texture: Texture2D = _textures.get("%s_%d" % [kind, variant])
	if not texture:
		return
	var size := clampf(float(icon.get("size", 12.0)), 8.0, 26.0)
	if kind == "hill":
		size *= 0.72
	var ratio := float(texture.get_height()) / float(texture.get_width())
	var dimensions := Vector2(size, size * ratio)
	var anchor := Vector2(float(icon.get("x", 0.0)), float(icon.get("y", 0.0)))
	draw_texture_rect(texture, Rect2(anchor - Vector2(dimensions.x * 0.5, dimensions.y), dimensions), false)
