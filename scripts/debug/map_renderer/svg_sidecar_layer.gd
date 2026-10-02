class_name SvgSidecarMapLayer
extends MapLayer

## Displays the generated Azgaar SVG verbatim. No relief is reconstructed here.
var _texture: Texture2D

func _draw() -> void:
	if _texture:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, Vector2(model.size)), false)

func load_sidecar(path: String) -> void:
	_texture = null
	if not FileAccess.file_exists(path):
		push_warning("SVG sidecar unavailable: %s" % path)
		queue_redraw()
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var image := Image.new()
	var error := image.load_svg_from_string(file.get_as_text(), 4.0)
	if error != OK:
		push_warning("Could not decode SVG sidecar %s (error %d)" % [path, error])
	else:
		_texture = ImageTexture.create_from_image(image)
	queue_redraw()
