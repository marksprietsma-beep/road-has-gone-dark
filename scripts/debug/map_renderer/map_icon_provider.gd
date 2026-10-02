class_name MapIconProvider
extends RefCounted

## Shared, data-driven source for the development atlas comparison. The renderer
## asks for semantic roles; it never needs to know asset paths or atlas cells.
const ROLES: Array[String] = [
	"capital", "city", "town", "village", "hamlet", "fort",
	"monastery", "trading", "ruins", "cave", "lighthouse", "mine",
]
## Minimum candidate score is 7/10 (period aesthetic + POI coverage).
## Rejected source assets remain in the repo for traceability, but are not selectable.
const FAMILIES: Array[String] = [
	"Procedural", "Game-icons", "Mercator", "de Fer", "Müller", "Janssonius",
	"Super Rough RPG/HEX", "Vischer", "Ogilby", "Hogenburg",
]
const FAMILY_DIRECTORIES := {
	"Game-icons": "game-icons", "Mercator": "mercator", "de Fer": "de-fer",
	"Müller": "muller", "Janssonius": "janssonius", "Super Rough RPG/HEX": "super-rough",
	"Vischer": "vischer", "Ogilby": "ogilby", "Hogenburg": "hogenburg",
}
const ROOT := "res://assets/map_icons/trials/"

## Only present actual installed samples; never offer nonfunctional trial options.
static func available_families() -> Array[String]:
	var present: Array[String] = ["Procedural"]
	for name in FAMILIES:
		if name == "Procedural":
			continue
		var folder: String = ROOT + str(FAMILY_DIRECTORIES.get(name, "")) + "/"
		var has_capital := FileAccess.file_exists(folder + "capital.svg") or FileAccess.file_exists(folder + "capital.png")
		var has_town := FileAccess.file_exists(folder + "town.svg") or FileAccess.file_exists(folder + "town.png")
		if has_capital and has_town:
			present.append(name)
	return present

var family := "Procedural"
var errors: Array[String] = []
var _cache: Dictionary = {}
var _role_manifests: Dictionary = {}

func set_family(value: String) -> void:
	family = value if value in FAMILIES else "Procedural"

## Missing source roles fall back to baseline markers and read N/A in the legend.
## A declared role whose file fails to load still produces an error and red X.
func is_declared_absent(role: String) -> bool:
	if family == "Procedural" or family == "Game-icons":
		return false
	if not _role_manifests.has(family):
		var path := ROOT + str(FAMILY_DIRECTORIES.get(family, "")) + "/mapping.json"
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		_role_manifests[family] = parsed if parsed is Dictionary else {}
	var manifest: Dictionary = _role_manifests[family]
	return role in manifest.get("absent_roles", [])

func texture_for(role: String) -> Texture2D:
	if family == "Procedural" or role not in ROLES or is_declared_absent(role):
		return null
	var key := "%s/%s" % [family, role]
	if _cache.has(key):
		return _cache[key]
	var texture: Texture2D = _standalone_texture(role)
	_cache[key] = texture
	return texture

func _standalone_texture(role: String) -> Texture2D:
	var stem := ROOT + str(FAMILY_DIRECTORIES.get(family, "")) + "/" + role
	var png_path := stem + ".png"
	if FileAccess.file_exists(png_path):
		var png_image := _load_png(png_path)
		return ImageTexture.create_from_image(png_image) if png_image else null
	var svg_path := stem + ".svg"
	if FileAccess.file_exists(svg_path):
		var svg_image := _load_svg(svg_path)
		return ImageTexture.create_from_image(svg_image) if svg_image else null
	_report_error("Unmapped icon role %s for family %s" % [role, family])
	return null

func _load_png(path: String) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_report_error("Cannot open PNG: %s" % path)
		return null
	var image := Image.new()
	var error := image.load_png_from_buffer(file.get_buffer(file.get_length()))
	if error != OK:
		_report_error("Godot PNG decode failed (%s): %s" % [error_string(error), path])
		return null
	return image

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
