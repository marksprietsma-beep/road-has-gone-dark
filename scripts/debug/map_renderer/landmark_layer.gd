class_name LandmarkMapLayer
extends MapLayer

## These four upstream types already have approved singular role art from GAME-28.
## Every other built-in Azgaar marker uses its own verified Game-icons SVG,
## with the same name as the upstream type.
const EXISTING_ROLE_ALIASES := {
	"ruins": "ruins",
	"caves": "cave",
	"lighthouses": "lighthouse",
	"mines": "mine",
}
## Preserve the original medium-zoom macro landmark visibility hierarchy.
const MEDIUM_ZOOM_TYPES := ["volcanoes", "ruins", "battlefields", "lighthouses"]

var icon_provider: MapIconProvider
var _warned_unknown_types: Dictionary = {}

func set_icon_provider(value: MapIconProvider) -> void:
	icon_provider = value
	queue_redraw()

func _draw() -> void:
	if not model or not icon_provider or zoom_band == 0:
		return
	for marker in model.fixture.get("markers", []):
		if not marker is Dictionary:
			continue
		var kind := str(marker.get("type", ""))
		if zoom_band == 1 and kind not in MEDIUM_ZOOM_TYPES:
			continue
		var known := kind in MapIconProvider.MARKER_TYPES
		var role := str(EXISTING_ROLE_ALIASES.get(kind, kind)) if known else "unidentified"
		if not known and not _warned_unknown_types.has(kind):
			_warned_unknown_types[kind] = true
			push_warning("Unknown Azgaar marker type '%s'; using neutral authored pin, not a guessed POI" % kind)
		var texture := icon_provider.texture_for(role)
		var p := Vector2(float(marker.get("x", 0.0)), float(marker.get("y", 0.0)))
		if texture:
			var source := texture.get_size()
			var size := source * (7.0 / maxf(source.x, source.y))
			draw_texture_rect(texture, Rect2(p - size * 0.5, size), false)
		else:
			# A promised source asset genuinely failed. Never disguise it as
			# the old generic dot, crossed line or procedural volcano.
			draw_line(p + Vector2(-2, -2), p + Vector2(2, 2), Color("#a8493f"), 1.0)
			draw_line(p + Vector2(2, -2), p + Vector2(-2, 2), Color("#a8493f"), 1.0)
