class_name PoliticalMapLayer
extends MapLayer

var texture: Texture2D

func set_package(package: Dictionary) -> void:
	texture = package.get("political_texture")
	queue_redraw()

func _draw() -> void:
	if not model or not texture: return
	var zoom_alpha := 1.0 if zoom_band == 0 else (0.9 if zoom_band == 1 else 0.55)
	draw_texture_rect(texture, Rect2(Vector2.ZERO, Vector2(model.size)), false, Color(1.0, 1.0, 1.0, zoom_alpha))
