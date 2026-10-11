extends SceneTree
## Focused original atlas renders for phone comparison; never a gameplay projection.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(1280,720)
 var base:=OS.get_environment("GAME98_TEST_ROOT")
 var specs: Array=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("contexts.json")))
 var atlas: Variant=null;var previous: String=""
 for index in specs.size():
  var spec: Dictionary=specs[index]
  var world:=GameWorldTemplate.new();assert(world.load_fixture(spec.world))
  if previous!=str(spec.world):
   if atlas!=null:atlas.queue_free();await process_frame
   atlas=load("res://scenes/debug/map_renderer/fantasy_map_layers.tscn").instantiate();root.add_child(atlas)
   atlas.display_fixture(world._raw,str(spec.world).replace(".json",".relief.svg"),str(spec.world).replace(".json",".vegetation.svg"))
   previous=str(spec.world)
  var home:=world.get_record("burg",int(spec.home_id));var point:=Vector2(home.x,home.y)
  atlas.set_zoom(3.0);atlas.scale=Vector2(3,3);atlas.position=root.get_visible_rect().size/2-point*3
  atlas.select_at(point)
  for i in 12:await process_frame
  await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png(base.path_join("region-%02d-atlas-detail.png"%index))==OK)
 atlas.queue_free();await process_frame;await process_frame
 print("Six focused source-atlas Godot captures saved");quit()
