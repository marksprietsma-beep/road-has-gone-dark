extends SceneTree
var failures := 0
func check(ok: bool, why: String) -> void:
 if not ok:
  failures += 1
  push_error(why)
func frames() -> void:
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var service := PartyService.new()
 service.store.save_root = "user://game81-visual-smoke-" + Crypto.new().generate_random_bytes(8).hex_encode()
 var entry: Dictionary = service.library.discover()[0]
 var w: GameWorldTemplate = entry.world
 var reader := OriginProfiles.new()
 check(reader.load_world(w), reader.error)
 var h: Dictionary = reader.projection.hometowns.values()[0]
 var created := service.store.create_playthrough(w, int(h.state_id), int(h.burg_id), int(h.province_id))
 var state: Dictionary = created.state
 state.origin_profiles = reader.descriptor
 var old := WorldOriginLore.new()
 check(old.load_world(w), old.error)
 state.origin_enrichment = old.descriptor
 check(service.store.save_new(state.playthrough_id,state,w).ok,"origin saved")
 PartyService.handoff = {"entry":entry,"slot":state.playthrough_id,"save_root":service.store.save_root}
 change_scene_to_file("res://scenes/ui/party_creation.tscn")
 await frames()
 var ui = current_scene
 var deadline := Time.get_ticks_msec() + 90000
 while ui.thread != null and Time.get_ticks_msec() < deadline: await process_frame
 check(not ui.state.is_empty(),"generated party is visible")
 var output := "res://docs/implementation/game81/screenshots"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 for dimensions in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size = dimensions
  await frames()
  check(ui.finish_button.get_global_rect().end.y <= root.get_visible_rect().size.y,"footer fits viewport")
  check(root.get_texture().get_image().save_png(output.path_join("initial-%dx%d.png"%[dimensions.x,dimensions.y]))==OK,"actual frame")
 print("GAME-81 visual smoke failures: ",failures)
 quit(1 if failures else 0)
