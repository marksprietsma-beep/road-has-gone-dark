extends Node2D

## GAME-54 public-only local preview. Never loads .tmp/developer or writes saves.
const CASES := [
 "unified-game-11-determinism-shore",
 "unified-game-11-determinism-river",
 "unified-game-11-determinism-highland",
 "unified-atlas-showcase-shore",
 "unified-atlas-showcase-river",
 "unified-atlas-showcase-highland"
]
const PUBLIC_FOLDER := "res://tools/regiongen/.tmp/public/"
var player_map: Dictionary = {}
var image_texture: ImageTexture
var selected_site_id: String = ""
@onready var view: Camera2D = $Camera2D
@onready var info: Label = $HUD/Help

func _ready() -> void:
 fit_map()
 load_case(PUBLIC_FOLDER + CASES[0] + ".json")

func fit_map() -> void:
 view.position = Vector2(500, 500)
 var size: Vector2 = get_viewport_rect().size
 var zoom_value: float = clampf(minf(size.x / 1100.0, (size.y - 115.0) / 1100.0), .14, 2.2)
 view.zoom = Vector2(zoom_value, zoom_value)

func _base_info() -> String:
 if player_map.is_empty():
  return "GAME-54 | No public map loaded"
 return "GAME-54 | Public exploration preview | 1-6: region  F: fit  Click: inspect known place\nVisible %d | Rumours %d | Original km unknown | No hidden/audit access" % [
  (player_map.get("known_sites", []) as Array).size(),
  (player_map.get("rumours", []) as Array).size()]

func load_case(path: String) -> bool:
 selected_site_id = ""
 player_map.clear()
 image_texture = null
 queue_redraw()
 if not path.begins_with(PUBLIC_FOLDER) or path.contains("..") or path.contains("developer"):
  info.text = "Refusing non-public map"
  return false
 if not FileAccess.file_exists(path):
  info.text = "Public preview missing (generate six GAME-54 maps first)"
  return false
 var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary:
  info.text = "Malformed public map JSON"
  return false
 var json: Dictionary = data
 if int(json.get("schema_version", -1)) != 1 or \
    str(json.get("role", "")) != "PLAYER_PREVIEW_NOT_GAME_SAVE" or \
    str(json.get("km_scale", "")) != "UNCALIBRATED_SOURCE_UNITS" or \
    str(json.get("migration", "")) != "NOT_AUTOMATIC" or \
    str(json.get("original_world_sha256", "")).length() != 64:
  info.text = "Unsupported or unsafe public map"
  return false
 var places: Array = json.get("known_sites", [])
 var rumours: Array = json.get("rumours", [])
 for place in places:
  if not place is Dictionary or not str(place.get("knowledge", "")) in ["visited", "discovered"]:
   info.text = "Refusing unknown site in player preview"
   return false
  var pos: Variant = place.get("position", [])
  if not pos is Array or pos.size() != 2:
   return false
 for rumour in rumours:
  if not rumour is Dictionary or rumour.has("id") or rumour.has("label") or rumour.has("position"):
   info.text = "Rumour contains hidden site data"
   return false
 var svg_path: String = path.trim_suffix(".json") + ".svg"
 if not FileAccess.file_exists(svg_path):
  info.text = "Public map SVG missing"
  return false
 var raster := Image.new()
 var err: Error = raster.load_svg_from_buffer(FileAccess.get_file_as_bytes(svg_path))
 if err != OK:
  info.text = "SVG rendering failed"
  return false
 image_texture = ImageTexture.create_from_image(raster)
 player_map = json
 info.text = _base_info()
 queue_redraw()
 return true

func _point(raw: Variant) -> Vector2:
 if raw is Array and raw.size() == 2:
  return Vector2(float(raw[0]), float(raw[1]))
 return Vector2(-10000, -10000)

func select_site_at(where: Vector2) -> bool:
 selected_site_id = ""
 if player_map.is_empty():
  return false
 var best_dist: float = 23.0
 var selected: Dictionary = {}
 for entry in player_map.get("known_sites", []):
  if not entry is Dictionary:
   continue
  var p: Vector2 = _point(entry.get("position", []))
  var distance: float = p.distance_to(where)
  if distance <= best_dist:
   best_dist = distance
   selected = entry
 if selected.is_empty():
  info.text = _base_info()
  queue_redraw()
  return false
 selected_site_id = str(selected.get("id", ""))
 info.text = _base_info() + "\n%s | %s | %s | Access/safety unverified" % [
  str(selected.get("label", "")),str(selected.get("kind", "")),str(selected.get("knowledge", ""))]
 queue_redraw()
 return true

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_F:
   fit_map()
   return
  if event.keycode >= KEY_1 and event.keycode <= KEY_6:
   load_case(PUBLIC_FOLDER + CASES[event.keycode - KEY_1] + ".json")
   return
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  select_site_at(get_global_mouse_position())

func _draw() -> void:
 if image_texture != null:
  draw_texture(image_texture, Vector2.ZERO)
 if selected_site_id.is_empty() or player_map.is_empty():
  return
 for entry in player_map.get("known_sites", []):
  if entry is Dictionary and str(entry.get("id", "")) == selected_site_id:
   draw_arc(_point(entry.get("position", [])), 24, 0, TAU, 40, Color("#ca623d"), 3.0, true)
   break
