extends SceneTree
const Adapter = preload("res://research/game77/src/origin_lore.gd")
const World = preload("res://scripts/game_world/game_world_template.gd")
const PATH := "res://research/game77/evidence/public-origins.json"
var checks := 0
func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		quit(1)
func _initialize() -> void:
	var world := World.new()
	expect(world.load_fixture("res://tests/worldgen/fixtures/game-11-determinism.json"), "GameWorld load")
	var adapter := Adapter.new()
	expect(adapter.load_projection(PATH, FileAccess.get_sha256(PATH)), "Pinned public projection")
	var row: Dictionary = adapter.get_public(world.world_id, 771)
	expect(not row.is_empty(), "Actual Maura identity")
	expect(row.label == "Local memory", "Generated lore distinguished from source facts")
	expect(not row.text.contains("tally") and not row.has("secret") and not row.has("rumours"), "No private fields")
	expect(adapter.get_public(world.world_id, 99999).is_empty(), "No invented town")
	expect(adapter.get_public("other-world", 771).is_empty(), "No cross-world substitution")
	row.text = "changed copy"
	expect(adapter.get_public(world.world_id, 771).text != row.text, "Copy isolation")
	expect(not adapter.load_projection(PATH, "0".repeat(64)), "Reject altered projection")
	expect(adapter.get_public(world.world_id, 771).is_empty(), "Failed load clears stale rows")
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	original.entries[0].secret = "HIDDEN_POI_SENTINEL"
	var tmp := "user://game77-negative-projection.json"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	file.store_string(JSON.stringify(original)); file.close()
	expect(not adapter.load_projection(tmp, FileAccess.get_sha256(tmp)), "Reject unexpected secret field even with matching digest")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	print("PASS: GAME-77 origin adapter %d checks" % checks)
	quit(0)
