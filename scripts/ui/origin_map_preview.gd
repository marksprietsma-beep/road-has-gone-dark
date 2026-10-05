extends Control
## Read-only atlas wrapper: no POI or settlement layer enters onboarding.
var model: MapRenderModel
var package: Dictionary = {}
var overlay: Texture2D
var burg := Vector2(-1, -1)

func set_world(source: Dictionary, key: String, fingerprint: String) -> void:
 model = MapRenderModel.new(source)
 package = {}
 var prefix := "res://assets/onboarding/" + key
 if FileAccess.get_file_as_string(prefix + ".sha256") != fingerprint:
  queue_redraw()
  return
 var image := Image.load_from_file(prefix + ".png")
 var ids := FileAccess.get_file_as_bytes(prefix + ".cells").to_int32_array()
 if image == null or ids.size() != image.get_width() * image.get_height():
  queue_redraw()
  return
 package = {"texture": ImageTexture.create_from_image(image), "cell_ids": ids, "baked_size": image.get_size()}
 select_area(-1, -1)

func select_area(state_id: int, province_id: int, home: Dictionary = {}) -> void:
 if package.is_empty(): return
 var dimensions: Vector2i = package.baked_size
 var image := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
 var provinces: Array = model.fixture.cells.province
 for y in dimensions.y:
  for x in dimensions.x:
   var cell: int = package.cell_ids[y * dimensions.x + x]
   if model.valid_cell(cell) and int(model.states[cell]) == state_id and (province_id <= 0 or int(provinces[cell]) == province_id):
    image.set_pixel(x, y, Color(1.0, 0.78, 0.3, 0.48))
 overlay = ImageTexture.create_from_image(image)
 burg = Vector2(float(home.get("x", -1)), float(home.get("y", -1)))
 queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO, size), Color("101414"))
 if package.is_empty(): return
 var scale_factor := minf(size.x / model.size.x, size.y / model.size.y)
 var extent := Vector2(model.size) * scale_factor
 var rect := Rect2((size - extent) / 2, extent)
 draw_texture_rect(package.texture, rect, false)
 draw_texture_rect(overlay, rect, false)
 if burg.x >= 0:
  var point := rect.position + burg * scale_factor
  draw_circle(point, 3, Color("ffe29b"))
  draw_arc(point, 6, 0, TAU, 24, Color("ffe29b"), 1.5)
 draw_rect(rect, Color("8a7045"), false)
