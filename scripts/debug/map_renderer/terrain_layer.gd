class_name TerrainMapLayer
extends MapLayer
var texture: Texture2D
func set_package(package: Dictionary) -> void:
	texture = package.get("texture")
	queue_redraw()
func _draw() -> void:
	if texture: draw_texture_rect(texture, Rect2(Vector2.ZERO, Vector2(model.size)), false)
