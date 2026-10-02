class_name MapIconProvider
extends RefCounted

## Shared, data-driven source for the development atlas comparison. The renderer
## asks for semantic roles; it never needs to know asset paths or atlas cells.
const ROLES: Array[String] = [
	"capital", "city", "town", "village", "hamlet", "fort",
	"monastery", "trading", "ruins", "cave", "lighthouse", "mine",
]
const FAMILIES: Array[String] = ["Procedural", "Kenney", "Pinhead", "Game-icons", "Osmic", "Lucide"]
const FAMILY_DIRECTORIES := {
	"Pinhead": "pinhead", "Game-icons": "game-icons", "Osmic": "osmic", "Lucide": "lucide",
}
const ROOT := "res://assets/map_icons/trials/"

var family := "Procedural"
var errors: Array[String] = []
var _cache: Dictionary = {}

func set_family(value: String) -> void:
	family = value if value in FAMILIES else "Procedural"

func texture_for(role: String) -> Texture2D:
	if family == "Procedural" or role not in ROLES:
		return null
	var key := "%s/%s" % [family, role]
	if _cache.has(key):
		return _cache[key]
	var texture: Texture2D = _kenney_texture(role) if family == "Kenney" else _standalone_texture(role)
	_cache[key] = texture
	return texture

func _standalone_texture(role: String) -> Texture2D:
	var path := ROOT + str(FAMILY_DIRECTORIES.get(family, "")) + "/" + role + ".svg"
	var image := _load_svg(path)
	return ImageTexture.create_from_image(image) if image else null

func _kenney_texture(role: String) -> Texture2D:
	# The staged SVG has no element IDs or manifest connecting its 91 cells to
	# semantic roles. Do not pretend arbitrary cells are verified role crops.
	_report_error("Kenney role crops are unavailable: source atlas cells are not semantically identified (%s)" % role)
	return null

func _load_svg(path: String) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_report_error("Cannot open SVG: %s" % path)
		return null
	var image := Image.new()
	var error := image.load_svg_from_string(file.get_as_text(), 1.0)
	if error != OK:
		_report_error("Godot SVG parse failed (%s): %s" % [error_string(error), path])
		return null
	return image

func _report_error(message: String) -> void:
	if message not in errors:
		errors.append(message)
	push_error(message)
