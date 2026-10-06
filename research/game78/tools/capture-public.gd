extends SceneTree
# Genuine Godot rendering of the allowlisted review payload, not a gameplay screen.
var panel: Control
var column: VBoxContainer
func _initialize() -> void:
	call_deferred("run")
func label_for(text: String, size: int) -> Label:
	var item := Label.new()
	item.text = text
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", Color("d5bd88"))
	return item
func run() -> void:
	var rows = JSON.parse_string(FileAccess.get_file_as_string("res://research/game78/evidence/public-review.json"))
	if not rows is Array or rows.size() < 8:
		push_error("Missing public review payload"); quit(1); return
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	panel = ColorRect.new()
	panel.color = Color("100f0c")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)
	var out := "res://research/game78/evidence/screenshots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for page in 4:
		for node in column.get_children():
			column.remove_child(node); node.queue_free()
		column.add_child(label_for("TRHGD • CONTENT RESEARCH / PUBLIC PROJECTION", 24))
		column.add_child(label_for("Actual generated records • no gameplay or mechanical promises", 16))
		for index in [page * 2, page * 2 + 1]:
			var row: Dictionary = rows[index]
			column.add_child(label_for(row.domain.to_upper() + "  /  " + row.logical_id, 22))
			column.add_child(label_for("Canonical " + row.source_kind + " ID %d • cell %d" % [row.burg_or_marker_id, row.cell_id], 16))
			column.add_child(label_for(row.text, 20))
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		if column.size.y > 656:
			push_error("Review page overflow"); quit(1); return
		if root.get_texture().get_image().save_png(out + "/public-page-%d-1280x720.png" % (page + 1)) != OK:
			push_error("Screenshot failed"); quit(1); return
	print("PASS: 4 actual Godot 4.6.3 public-content research renders")
	quit(0)
