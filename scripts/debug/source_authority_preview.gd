extends Node2D
## GAME-49 source authority debug only. No game-state writes or travel logic.
const CASES := [
 "authority-game-11-determinism-shore",
 "authority-game-11-determinism-river",
 "authority-game-11-determinism-highland",
 "authority-atlas-showcase-shore",
 "authority-atlas-showcase-river",
 "authority-atlas-showcase-highland"
]
var model: Dictionary = {}
var fine_field: Dictionary = {}
var show_original: bool = true
var show_approximate: bool = true
var show_inferred: bool = true
var show_unknown: bool = true
@onready var view: Camera2D = $Camera2D
@onready var title_text: Label = $HUD/Help

func _ready() -> void:
 fit_map()
 load_case("res://tools/regiongen/.tmp/" + CASES[0] + ".json")

func fit_map() -> void:
 view.position = Vector2(500, 500)
 var size: Vector2 = get_viewport_rect().size
 var z: float = clampf(minf(size.x / 1100.0, (size.y - 110.0) / 1100.0), .15, 2.0)
 view.zoom = Vector2(z, z)

func load_case(path: String) -> bool:
 model.clear()
 fine_field.clear()
 queue_redraw()
 if not FileAccess.file_exists(path):
  title_text.text = "GAME-49 | Run authority example generator first."
  return false
 var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
 if not decoded is Dictionary:
  title_text.text = "GAME-49 | Malformed authority JSON"
  return false
 if int(decoded.get("schema_version", -1)) != 1:
  title_text.text = "GAME-49 | Unsupported authority schema"
  return false
 var identity: Dictionary = decoded.get("identity", {})
 var source: Dictionary = decoded.get("source_macro", {})
 var derived: Dictionary = decoded.get("derived_approximate", {})
 var unknown: Dictionary = decoded.get("unknown", {})
 if str(identity.get("source_world_sha256", "")).length() != 64 or source.is_empty() or derived.is_empty() or unknown.is_empty():
  title_text.text = "GAME-49 | Missing original source or unknown-field evidence"
  return false
 # Inference is an optional sidecar, never original Azgaar source.
 var inferred_path: String = path.replace("authority-", "fine-")
 if FileAccess.file_exists(inferred_path):
  var inferred_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(inferred_path))
  if not inferred_value is Dictionary:
   title_text.text = "GAME-51 | Malformed optional inferred illustration"
   return false
  var possible: Dictionary = inferred_value
  if int(possible.get("schema_version", -1)) != 1 or \
     str(possible.get("source_context_id", "")) != str(identity.get("source_context_id", "")) or \
     str(possible.get("source_world_sha256", "")) != str(identity.get("source_world_sha256", "")) or \
     str(possible.get("truth", "")) != "INFERRED_VISUAL_FIELD_NOT_TRAVERSAL":
   title_text.text = "GAME-51 | Inferred field does not match original source"
   return false
  fine_field = possible
 model = decoded
 _set_header()
 queue_redraw()
 return true

func _set_header() -> void:
 if model.is_empty():
  return
 var source: Dictionary = model["source_macro"]
 var home_name: String = "Unknown"
 for v in source.get("towns", []):
  if int(v.get("source_burg_id", -1)) == int(model["identity"]["origin_source_burg_id"]):
   home_name = str(v.get("name", "Unknown"))
   break
 var assumption: Dictionary = model.get("assumption", {})
 title_text.text = "GAME-49 | %s | Original/S  Approx/A  Inferred/I  Unknown/U  1-6: world  F: fit\n%s | No fine roads, local bridges or safe traversal inferred | Macro cells: %s" % [
  home_name,str(assumption.get("status", "")),str(assumption.get("source_cell_samples", "?"))]

func _coords(p: Variant) -> Vector2:
 if p is Array and p.size() >= 2:
  return Vector2(float(p[0]), float(p[1]))
 return Vector2.ZERO

func _poly(raw: Variant) -> PackedVector2Array:
 var p := PackedVector2Array()
 if raw is Array:
  for each in raw:
   if each is Array and each.size() >= 2:
    p.append(_coords(each))
 return p

func _dashes(a: Vector2, b: Vector2, shade: Color, width: float) -> void:
 var distance: float = a.distance_to(b)
 if distance <= .01:
  return
 var dir: Vector2 = (b-a).normalized()
 var t: float = 0.0
 while t < distance:
  draw_line(a+dir*t, a+dir*minf(t+7.0,distance),shade,width,true)
  t += 13.0

func _unhandled_input(event: InputEvent) -> void:
 if not event is InputEventKey:
  return
 var key: InputEventKey = event
 if not key.pressed or key.echo:
  return
 match key.keycode:
  KEY_S: show_original = not show_original
  KEY_A: show_approximate = not show_approximate
  KEY_I: show_inferred = not show_inferred
  KEY_U: show_unknown = not show_unknown
  KEY_F: fit_map()
  _:
   if key.keycode >= KEY_1 and key.keycode <= KEY_6:
    load_case("res://tools/regiongen/.tmp/" + CASES[key.keycode - KEY_1] + ".json")
 queue_redraw()

func _draw_fine_triangle(triangle: Array, cutoff: float, shade: Color) -> void:
 var polygon := PackedVector2Array()
 for i in 3:
  var a: Dictionary = triangle[i]
  var b: Dictionary = triangle[(i + 1) % 3]
  var av: float = float(a.get("value", 0.0))
  var bv: float = float(b.get("value", 0.0))
  var above_a: bool = av >= cutoff
  var above_b: bool = bv >= cutoff
  if above_a:
   polygon.append(a["point"])
  if above_a != above_b:
   var frac: float = (cutoff - av) / (bv - av)
   polygon.append((a["point"] as Vector2).lerp(b["point"], frac))
 # Contour intersections at threshold equality can repeat a vertex or
 # collapse to a zero-area polygon; Godot's triangulator rejects these.
 var clean := PackedVector2Array()
 for v in polygon:
  if clean.is_empty() or clean[clean.size() - 1].distance_to(v) > .05:
   clean.append(v)
 if clean.size() > 2 and clean[0].distance_to(clean[clean.size() - 1]) <= .05:
  clean.resize(clean.size() - 1)
 if clean.size() < 3:
  return
 var area: float = 0.0
 for i in clean.size():
  var a: Vector2 = clean[i]
  var b: Vector2 = clean[(i + 1) % clean.size()]
  area += a.x * b.y - b.x * a.y
 if absf(area) <= 1.0:
  return
 # Threshold clipping can produce a valid-looking 4-point contour with
 # almost-collinear corners; Godot's polygon ear triangulator then rejects
 # the whole shape. Clip of one triangle is convex, so fan-triangulate
 # ourselves and reject each degenerate *individual* triangle.
 for k in range(1, clean.size() - 1):
  var p: Vector2 = clean[0]
  var q: Vector2 = clean[k]
  var r: Vector2 = clean[k + 1]
  var twice_area: float = absf((q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x))
  if twice_area <= .75:
   continue
  draw_colored_polygon(PackedVector2Array([p, q, r]), shade)

func _draw_fine_field() -> void:
 if fine_field.is_empty():
  return
 var grid: int = int(fine_field.get("grid_steps", 0))
 var samples: Array = fine_field.get("vertices", [])
 if grid <= 0 or samples.size() != (grid + 1) * (grid + 1):
  return
 var step: float = 1000.0 / float(grid)
 # Triangles are only painted if all three sample vertices were classified
 # as land from ORIGINAL source coast/lake polygon geometry.
 var layers: Array = [
  ["h", 48.0, Color("#c9b58c", .66)],
  ["h", 58.0, Color("#b5a17e", .66)],
  ["h", 69.0, Color("#a08e75", .66)],
  ["h", 78.0, Color("#89816c", .66)],
  ["f", .49, Color("#7f946c", .88)],
  ["f", .57, Color("#5e7655", .88)],
  ["f", .65, Color("#455c49", .88)]
 ]
 for layer in layers:
  var key: String = str(layer[0])
  var cutoff: float = float(layer[1])
  var shade: Color = layer[2]
  for j in grid:
   for i in grid:
    var indices := [j * (grid + 1) + i, j * (grid + 1) + i + 1,
     (j + 1) * (grid + 1) + i + 1, (j + 1) * (grid + 1) + i]
    var corners := [Vector2(i * step, j * step), Vector2((i + 1) * step, j * step),
     Vector2((i + 1) * step, (j + 1) * step), Vector2(i * step, (j + 1) * step)]
    for triangle_indices in [[0, 1, 2], [0, 2, 3]]:
     var triangle: Array = []
     var all_land: bool = true
     for corner_index in triangle_indices:
      var entry: Dictionary = samples[indices[corner_index]]
      if not bool(entry.get("land", false)):
       all_land = false
      triangle.append({"point": corners[corner_index],
       "value": float(entry.get(key, 0.0))})
     if all_land:
      _draw_fine_triangle(triangle, cutoff, shade)

func _draw() -> void:
 draw_rect(Rect2(0,0,1000,1000),Color("#8eabb8"))
 if model.is_empty():
  return
 var source: Dictionary = model.get("source_macro", {})
 if show_original:
  for f in source.get("feature_polygons", []):
   if str(f.get("classification","")) != "land_boundary":
    continue
   var p: PackedVector2Array = _poly(f.get("source_polygon",[]))
   if p.size() >= 3:
    draw_colored_polygon(p,Color("#d9c9a2"))
  for f in source.get("feature_polygons", []):
   if str(f.get("classification","")) != "freshwater_lake":
    continue
   var p: PackedVector2Array = _poly(f.get("source_polygon",[]))
   if p.size() >= 3:
    draw_colored_polygon(p,Color("#8eabb8"))
 if show_inferred:
  _draw_fine_field()
 if show_original:
  for line in source.get("routes", []):
   for part in line.get("segments", []):
    var p: PackedVector2Array = _poly(part.get("local_points",[]))
    if p.size() >= 2:
     if str(line.get("classification","")) == "sea_lane":
      _dashes(p[0],p[1],Color("#457e89"),3.0)
     else:
      draw_polyline(p,Color("#775e43"),3.0,true)
  for t in source.get("towns",[]):
   draw_circle(_coords(t.get("local_position",[])),10,Color("#8a3328"))
 if show_approximate:
  for river in model.get("derived_approximate",{}).get("rivers",[]):
   for part in river.get("segments",[]):
    var p: PackedVector2Array = _poly(part.get("local_points",[]))
    if p.size() >= 2:
     _dashes(p[0],p[1],Color("#276b95"),2.0)
 if show_inferred:
  for tree in model.get("inferred_fine_detail",{}).get("trees",[]):
   var pos: Vector2 = Vector2(float(tree.get("x",0)),float(tree.get("y",0)))
   draw_circle(pos,5,Color("#40644b"))
 if show_unknown:
  # A small legend instead of inventing a false traversable micro-map.
  draw_rect(Rect2(12,918,974,66),Color("#ede0bf",.95))
  draw_rect(Rect2(12,918,974,66),Color("#624c3b"),false,1)
  var font: Font = ThemeDB.fallback_font
  draw_string(font,Vector2(24,941),"UNKNOWN: bridges, safe roads, real river meanders, ports, fine dry-land and walkable routes",
   HORIZONTAL_ALIGNMENT_LEFT,955,17,Color("#824432"))
  draw_string(font,Vector2(24,969),"EXACT means macro Azgaar source, not a physically accurate 30 km walking surface.",
   HORIZONTAL_ALIGNMENT_LEFT,955,15,Color("#574838"))
 draw_rect(Rect2(0,0,1000,1000),Color("#463c30"),false,1)
