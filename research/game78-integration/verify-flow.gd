extends SceneTree
const SCENE := preload("res://scenes/ui/new_game_origin.tscn")
var checks := 0
var failures := 0
var out := "res://research/game78-integration/evidence"
var ui: Control
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func frames() -> void:
 for i in 6: await process_frame
 await RenderingServer.frame_post_draw
func click(control: Control) -> void:
 await frames()
 for down in [true,false]:
  var event := InputEventMouseButton.new()
  event.position = control.get_global_rect().get_center()
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = down
  root.push_input(event,true)
 await frames()
func capture(name: String) -> void:
 await frames()
 check(ui.facts.text == ui._origin_context().hometown_summary(ui.burg_id).summary,"GAME-75 factual context unchanged")
 check(ui.facts.get_global_rect().end.y <= ui.next_button.get_global_rect().position.y,"Factual panel fits")
 if is_instance_valid(ui.local_memory):
  check(ui.local_memory.get_global_rect().end.y <= ui.next_button.get_global_rect().position.y,"Lore fits above footer")
  check(not ui.local_memory.text.contains("secret") and not ui.local_memory.text.contains("rumour"),"Public-only lore")
 check(ui.next_button.get_global_rect().end.y <= root.get_visible_rect().size.y,"Footer remains inside logical viewport: " + name)
 check(root.get_texture().get_image().save_png(out.path_join(name+".png"))==OK,"Screenshot saved")
func origin(world_index: int, burg_id: int) -> void:
 ui.choose_world(world_index)
 var town: Dictionary = ui.worlds[world_index].get_record("burg",burg_id)
 var cell: Dictionary = ui.worlds[world_index].get_record("cell",int(town.cell))
 ui.state_id = int(cell.state)
 ui.province_id = int(cell.province)
 ui.burg_id = burg_id
 ui.page = 3
 ui.show_page()
func saved_files() -> PackedStringArray:
 if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ui.store.save_root)):
  return PackedStringArray()
 return DirAccess.get_files_at(ui.store.save_root)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 ui=SCENE.instantiate()
 root.add_child(ui)
 await frames()
 ui.store.save_root="user://game78-integration-proof-%d" % Time.get_ticks_usec()
 check(saved_files().is_empty(),"No preconfirmation save")
 for size in [Vector2i(640,360),Vector2i(1280,720)]:
  root.size=size
  for id in [771,25]:
   origin(0,id)
   check(is_instance_valid(ui.local_memory),"Real preset town has lore")
   await capture("confirm-%d-%dx%d" % [id,size.x,size.y])
 origin(0,645)
 check(not is_instance_valid(ui.local_memory),"Unlisted town receives no invented/substituted lore")
 await capture("missing-lore-1280x720")
 origin(1,760)
 check(is_instance_valid(ui.local_memory),"Actual Atlas immutable identity")
 await capture("atlas-origin-1280x720")
 origin(0,771)
 check(saved_files().is_empty(),"Preview/cancel route created no save")
 await click(ui.back_button)
 check(ui.page==2 and not is_instance_valid(ui.local_memory),"Back clears lore and preserves choice")
 await click(ui.next_button)
 check(ui.page==3 and is_instance_valid(ui.local_memory),"Return restores correct lore")
 await click(ui.next_button)
 check(ui.page==4 and not ui.saved_slot.is_empty(),"Real mouse confirmation saves only after reload validation")
 check(saved_files().size()==1,"Exactly one playthrough")
 check(ui.store.load_save(ui.saved_slot,ui.worlds[0]).ok,"Saved origin reloads")
 await capture("origin-established-1280x720")
 await click(ui.next_button)
 check(ui.page==3,"Review origin returns without another save")
 await click(ui.next_button)
 check(ui.page==4 and saved_files().size()==1,"Reconfirmation returns to same saved handoff")
 var slot: String = ui.saved_slot
 DirAccess.remove_absolute(ui.store._slot_path(slot))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(ui.store.save_root))
 print("GAME-78 integration real input/render: %d checks, %d failures" % [checks,failures])
 ui.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
