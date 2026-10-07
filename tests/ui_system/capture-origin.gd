extends SceneTree
var checks := 0
var failures := 0
var output := ""
var run_id := ""
func _initialize() -> void:
 Engine.max_fps = 60
 call_deferred("run")
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(why)
func settle() -> void:
 for i in 60: await process_frame
 await RenderingServer.frame_post_draw
func click(control: Control) -> void:
 for down in [true, false]:
  var e := InputEventMouseButton.new()
  e.position = control.get_global_rect().get_center()
  e.button_index = MOUSE_BUTTON_LEFT
  e.pressed = down
  root.push_input(e, true)
 await settle()
func shot(name: String) -> void:
 await settle()
 check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, name)
func run() -> void:
 run_id = Crypto.new().generate_random_bytes(8).hex_encode()
 output = "res://docs/implementation/game83/" + OS.get_environment("GAME83_STAGE") + "/origin"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 for dimensions in [Vector2i(640,360), Vector2i(1280,720), Vector2i(2560,1440)]:
  root.size = dimensions
  change_scene_to_file("res://scenes/ui/main_menu.tscn")
  await settle()
  var suffix := "-%dx%d" % [dimensions.x, dimensions.y]
  await shot("main-menu" + suffix)
  await click(current_scene.new_game_button)
  await settle()
  var ui = current_scene
  check(ui.scene_file_path == "res://scenes/ui/new_game_origin.tscn", "mouse New Game opens origin")
  var base := OS.get_environment("GAME84_TEST_ROOT")
  ui.library.library_root = base.path_join("library")
  ui.store.save_root = base.path_join("origin-captures-" + run_id + "-" + str(dimensions.x))
  ui.library.save_root = ui.store.save_root
  ui._reload_library()
  ui.choose_world(0)
  ui.show_page()
  await shot("world" + suffix)
  await click(ui.next_button)
  await shot("state" + suffix)
  await click(ui.next_button)
  await shot("region" + suffix)
  await click(ui.next_button)
  check(ui.candidates.size() > 0, "actual selected region offers hometowns")
  await shot("hometown-choice" + suffix)
  await click(ui.next_button)
  await shot("confirm" + suffix)
  check(not DirAccess.dir_exists_absolute(ui.store.save_root), "preview creates no save")
  await click(ui.next_button)
  var deadline := Time.get_ticks_msec() + 180000
  while (current_scene == ui or current_scene == null) and Time.get_ticks_msec() < deadline: await process_frame
  var party = current_scene
  while party.thread != null and Time.get_ticks_msec() < deadline: await process_frame
  check(party.scene_file_path == "res://scenes/ui/party_creation.tscn" and party.state.party.members.size() == 3, "same origin enters three-member party")
  await shot("party-creation" + suffix)
  party.detail_tabs.current_tab = 1
  await shot("party-background" + suffix)
  party.detail_tabs.current_tab = 0
  await click(party.finish_button)
  while party.thread != null and Time.get_ticks_msec() < deadline: await process_frame
  check(party.ready_view, "actual ready transition")
  await shot("party-ready" + suffix)
 print("GAME-83 origin/party captures: ", checks, " checks, ", failures, " failures")
 quit(1 if failures else 0)
