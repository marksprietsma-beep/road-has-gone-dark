extends SceneTree

func _initialize() -> void:
 call_deferred("_verify")

func _verify() -> void:
 var scene: PackedScene = load("res://scenes/debug/source_authority_preview.tscn")
 assert(scene != null, "GAME-49 source authority scene is missing")
 var viewer: Node2D = scene.instantiate()
 root.add_child(viewer)
 await process_frame
 assert(not viewer.model.is_empty(), "Source authority example not loaded")
 assert(viewer.show_original and viewer.show_approximate)
 assert(viewer.show_inferred and viewer.show_unknown)
 var kinds := [
  "authority-game-11-determinism-shore",
  "authority-game-11-determinism-river",
  "authority-game-11-determinism-highland",
  "authority-atlas-showcase-shore",
  "authority-atlas-showcase-river",
  "authority-atlas-showcase-highland"
 ]
 for name in kinds:
  assert(viewer.load_case("res://tools/regiongen/.tmp/%s.json" % name))
  await process_frame
  var model: Dictionary = viewer.model
  assert(int(model["schema_version"]) == 1)
  assert(model["assumption"]["status"] == "HYPOTHETICAL_NOT_CANON")
  assert(model["flags"]["reliable_fine_road_geometry"] == false)
  assert(model["flags"]["travel_safety_known"] == false)
  assert(model["unknown"]["safe_or_patrolled_routes"] == "NOT_VERIFIED")
  assert(model["inferred_fine_detail"]["trust"] == "NOT_GENERATED")
  # The optional visual-only fine grid is separate from macro SourceAuthority.
  assert(not viewer.fine_field.is_empty(), "GAME-51 inference proof missing")
  assert(int(viewer.fine_field.get("schema_version", -1)) == 1)
  assert(str(viewer.fine_field.get("source_world_sha256", "")) == str(model["identity"]["source_world_sha256"]))
  assert(str(viewer.fine_field.get("source_context_id", "")) == str(model["identity"]["source_context_id"]))
  assert(str(viewer.fine_field.get("truth", "")) == "INFERRED_VISUAL_FIELD_NOT_TRAVERSAL")
  assert(str(viewer.fine_field.get("claims", {}).get("walkable", "")) == "UNKNOWN")
  assert(viewer.fine_field.get("vertices", []).size() == 1089)
  assert(viewer.show_inferred, "Illustrative field should show under I by default")
  assert(not model["source_macro"]["towns"].is_empty())
 for key in [KEY_S,KEY_A,KEY_I,KEY_U]:
  var event := InputEventKey.new()
  event.keycode = key
  event.pressed = true
  viewer._unhandled_input(event)
 assert(not viewer.show_original and not viewer.show_approximate)
 assert(not viewer.show_inferred and not viewer.show_unknown)
 assert(not viewer.load_case("res://tools/regiongen/.tmp/missing-authority.json"))
 assert(viewer.model.is_empty(), "Bad input left stale original source data")
 assert(viewer.fine_field.is_empty(), "Bad input left stale inferred data")
 print("PASS: GAME-49 Godot six v2 source authority windows with separate inferred grid, exact/approx/inferred/unknown toggles, missing-file fail closed")
 quit(0)
