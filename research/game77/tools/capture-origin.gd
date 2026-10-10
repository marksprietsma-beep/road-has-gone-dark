extends SceneTree
const World = preload("res://scripts/game_world/game_world_template.gd")
const Adapter = preload("res://research/game77/src/origin_lore.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world := World.new()
	if not world.load_fixture("res://tests/worldgen/fixtures/game-11-determinism.json"):
		push_error(world.error); quit(1); return
	var adapter := Adapter.new()
	var path := "res://research/game77/evidence/public-origins.json"
	if not adapter.load_projection(path, FileAccess.get_sha256(path)):
		push_error(adapter.error); quit(1); return
	var row: Dictionary = adapter.get_public(world.world_id, 771)
	var base := ColorRect.new()
	base.color = Color("100f0c")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(base)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 40)
	for side in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 28)
	base.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	for text in ["GAME-77 • PUBLIC ORIGIN LORE PROOF", "MAURA", "Source-backed hometown • Kausalo / Tusmukmia", "LOCAL MEMORY — GENERATED WORLD HISTORY", row.text, "Research proof only. No character creation or gameplay."]:
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color("d5bd88"))
		label.add_theme_font_size_override("font_size", 16 if text != "MAURA" else 24)
		column.add_child(label)
	var out := "res://research/game77/evidence/screenshots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for size in [Vector2i(640,360), Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = size
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.save_png(out + "/public-origin-%dx%d.png" % [size.x,size.y]) != OK:
			push_error("Screenshot failed"); quit(1); return
	print("PASS: 3 actual Godot 4.6.3 public-origin renders")
	quit(0)
