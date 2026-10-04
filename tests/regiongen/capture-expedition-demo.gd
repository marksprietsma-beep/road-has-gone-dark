extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var demo: Node2D = load("res://scenes/gameplay/expedition_demo.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	await process_frame
	if not demo.expedition.ready:
		push_error("Bundled demo did not initialise")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	if picture == null or picture.get_width() < 320:
		push_error("Real renderer has no viewport content")
		quit(1)
		return
	var path := ProjectSettings.globalize_path("res://build/expedition-demo/Expedition-Demo.png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if picture.save_png(path) != OK:
		push_error("Cannot save actual demo viewport")
		quit(1)
		return
	print("PASS: GAME-56 actual gameplay screenshot")
	quit(0)
