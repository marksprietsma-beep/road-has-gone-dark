extends SceneTree

## No developer records or gameplay saves are ever loaded by this viewer.
func _initialize() -> void:
 call_deferred("_check")

func _check() -> void:
 var scene: PackedScene = load("res://scenes/debug/unified_public_preview.tscn")
 assert(scene != null, "GAME-54 public-only Godot scene missing")
 var viewer: Node2D = scene.instantiate()
 root.add_child(viewer)
 await process_frame
 assert(not viewer.player_map.is_empty(), "First player-preview JSON missing")
 assert(viewer.image_texture != null, "Inferred scene SVG was not rendered")
 var visited := 0
 for label in viewer.CASES:
  assert(viewer.load_case(viewer.PUBLIC_FOLDER + label + ".json"))
  await process_frame
  var data: Dictionary = viewer.player_map
  assert(data.get("role", "") == "PLAYER_PREVIEW_NOT_GAME_SAVE")
  assert(data.get("migration", "") == "NOT_AUTOMATIC")
  assert(data.get("fine_walkable", "") == "UNKNOWN")
  assert(data.get("route_safety", "") == "UNKNOWN")
  assert(viewer.image_texture != null)
  for rumour in data.get("rumours", []):
   assert(not rumour.has("label") and not rumour.has("id") and not rumour.has("position"))
  var places: Array = data.get("known_sites", [])
  assert(places.size() >= 1, "Missing original hometown")
  for p in places:
   assert(str(p.get("knowledge", "")) in ["discovered", "visited"])
   var pos: Vector2 = Vector2(float(p["position"][0]),float(p["position"][1]))
   assert(viewer.select_site_at(pos), "Known place not selectable")
   assert(viewer.selected_site_id == str(p["id"]))
   assert(viewer.info.text.contains(str(p["label"])))
   visited += 1
  assert(not viewer.load_case(viewer.PUBLIC_FOLDER + "missing.json"))
  assert(viewer.player_map.is_empty(), "Unsafe stale player data survived missing file")
  assert(viewer.image_texture == null, "Unsafe stale rendered map survived missing file")
 assert(visited >= 4)
 # Do not allow a player scene to navigate into developer-only unfiltered data.
 assert(not viewer.load_case("res://tools/regiongen/.tmp/developer/unified-game-11-determinism-shore.json"))
 assert(viewer.player_map.is_empty())
 assert(not viewer.load_case(viewer.PUBLIC_FOLDER + "../developer/unified-game-11-determinism-shore.json"))
 assert(viewer.player_map.is_empty())
 var first := InputEventKey.new()
 first.keycode=KEY_1
 first.pressed=true
 viewer._unhandled_input(first)
 assert(not viewer.player_map.is_empty())
 var fit := InputEventKey.new()
 fit.keycode=KEY_F
 fit.pressed=true
 viewer._unhandled_input(fit)
 assert(viewer.view.zoom.x > 0.0)
 print("PASS: GAME-54 Godot six public-only source/site/terrain maps, safe click inspection, no hidden/audit traversal")
 quit(0)
