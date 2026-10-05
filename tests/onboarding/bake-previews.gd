extends SceneTree
func _initialize() -> void:
 for key in ["game-11-determinism", "atlas-showcase"]:
  var source := WorldFixtureLoader.new().load_fixture("res://tests/worldgen/fixtures/%s.json" % key)
  var package := MapRenderBaker.new().bake(MapRenderModel.new(source))
  var image: Image = package.texture.get_image()
  image.blend_rect(package.political_texture.get_image(), Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
  image.blend_rect(package.border_texture.get_image(), Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
  image.save_png("res://assets/onboarding/%s.png" % key)
  var file := FileAccess.open("res://assets/onboarding/%s.cells" % key, FileAccess.WRITE)
  file.store_buffer(package.cell_ids.to_byte_array())
  file.close()
  file = FileAccess.open("res://assets/onboarding/%s.sha256" % key, FileAccess.WRITE)
  file.store_string(FileAccess.get_sha256("res://tests/worldgen/fixtures/%s.json" % key))
  file.close()
  print("Baked canonical preview: " + key)
 quit()
