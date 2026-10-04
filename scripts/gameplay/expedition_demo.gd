extends "res://scripts/gameplay/expedition_preview.gd"

const DEMO_PATH := "res://assets/demo/kindum-region.json"
const MANIFEST_PATH := "res://assets/demo/manifest.json"
const MENU_PATH := "res://scenes/ui/main_menu.tscn"

func _initial_region_path() -> String:
	return DEMO_PATH

func _base_info() -> String:
	return "EXPEDITION DEMO · KINDUM\nThree travellers; session only.\nClick a known site to select.\nT: Journey   S: Scout\nC: Cautious   B: Bold\nR: Return   X: Hexes   F: Fit\nEsc: Main menu (ends session)"

func load_region(path: String) -> bool:
	if path != DEMO_PATH:
		return false
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not manifest is Dictionary or int(manifest.get("schema_version", -1)) != 1 or \
			str(manifest.get("meaning", "")) != "PINNED_SESSION_ONLY_EXPEDITION_DEMO" or \
			str(manifest.get("path", "")) != DEMO_PATH or \
			FileAccess.get_sha256(DEMO_PATH) != str(manifest.get("region_sha256", "")):
		info.text = "Expedition Demo unavailable: bundled data integrity check failed.\nEsc: Main menu"
		return false
	if not super.load_region(path):
		return false
	var context: Dictionary = region.source_context
	if str(region.id) != str(manifest.get("region_id", "")) or \
			str(context.id) != str(manifest.get("source_context_id", "")) or \
			str(context.parent_source_world_sha256) != str(manifest.get("source_world_sha256", "")) or \
			int(context.source_home_burg_id) != int(manifest.get("source_home_burg_id", -1)):
		region.clear()
		expedition.ready = false
		info.text = "Expedition Demo unavailable: pinned source identity mismatch.\nEsc: Main menu"
		queue_redraw()
		return false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file(MENU_PATH)
			return
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			return
	super._unhandled_input(event)
