extends SceneTree

## Rendered (non-headless, virtual display) acceptance evidence. Does not
## alter a campaign, save world data, or invent location geography.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: PackedScene = load("res://scenes/gameplay/expedition_prototype.tscn")
	if scene == null:
		push_error("Gameplay expedition scene missing")
		quit(1)
		return
	var viewer: Node2D = scene.instantiate()
	root.add_child(viewer)
	await process_frame
	await process_frame
	if not viewer.expedition.ready:
		push_error("Expedition did not initialise")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	if picture == null or picture.get_width() < 320:
		push_error("Real renderer has no viewport content")
		quit(1)
		return
	var folder: String = ProjectSettings.globalize_path("res://tools/regiongen/.tmp")
	DirAccess.make_dir_recursive_absolute(folder)
	var path: String = folder.path_join("expedition-prototype.png")
	if picture.save_png(path) != OK:
		push_error("Cannot save actual Godot viewport")
		quit(1)
		return
	print("PASS: GAME-55 rendered expedition screenshot %dx%d" % [picture.get_width(), picture.get_height()])
	quit(0)
