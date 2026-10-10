extends SceneTree
## Corrupt the actual newly written JSON, then exercise GAME-7's real validator.
class CorruptingStore extends GamePlaythroughStore:
 var corrupt_reloads := 2
 var created_ids: Array[String] = []
 var on_rejected_reload: Callable
 func create_playthrough(world: GameWorldTemplate, state_id: int, burg_id: int, province_id: int = -1) -> Dictionary:
  var result := super.create_playthrough(world, state_id, burg_id, province_id)
  if result.ok: created_ids.append(str(result.state.playthrough_id))
  return result
 func load_save(slot: String, world: GameWorldTemplate) -> Dictionary:
  if corrupt_reloads > 0:
   corrupt_reloads -= 1
   var path := save_root.path_join(slot + ".json")
   var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
   source.origin.home_id = "burg:-1"
   var file := FileAccess.open(path, FileAccess.WRITE)
   file.store_string(JSON.stringify(source))
   file.close()
  var result := super.load_save(slot, world)
  if not result.ok and on_rejected_reload.is_valid(): on_rejected_reload.call()
  return result

class CleanupBlockedOrigin extends "res://scripts/ui/new_game_origin.gd":
 var block_cleanup := false
 func _discard_unvalidated_save() -> bool:
  return false if block_cleanup else super._discard_unvalidated_save()

var checks := 0
var failures := 0
func check(condition: bool, description: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(description)
func has_success_claim(node: Node) -> bool:
 if node is Label and node.text.contains("Your origin has been saved"): return true
 for child in node.get_children():
  if has_success_claim(child): return true
 return false
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var ui = load("res://scenes/ui/new_game_origin.tscn").instantiate()
 root.add_child(ui)
 var store := CorruptingStore.new()
 store.save_root = "user://game74-reload-failure-" + Crypto.new().generate_random_bytes(8).hex_encode()
 ui.store = store
 ui.advance()
 ui.advance()
 check(ui.page == 1 and ui.area_view == "region", "state advances to explicit region choice")
 ui.advance()
 ui.advance()
 var home: int = ui.burg_id
 check(ui.page == 3, "starts at confirmation")
 for attempt in 2:
  ui.advance()
  check(ui.page == 3 and ui.title.text == "Review your origin", "reload failure never enters success")
  check(ui.saved_slot.is_empty() and not has_success_claim(ui), "no validated slot or false saved-state claim")
  check(ui.message.contains("could not be verified"), "confirmation reports validation failure")
  check(store.error == "Source hometown stable ID mismatch", "actual GAME-7 reload validator rejected written state")
  check(DirAccess.get_files_at(store.save_root).is_empty() and ui.unvalidated_save_path.is_empty(), "failed slot removed without orphan or pending state")
  check(store.created_ids.size() == attempt + 1 and ui.burg_id == home, "retry attempts keep origin and create at most one slot")
 ui.advance()
 var verified_slot: String = ui.saved_slot
 check(ui.page == 4 and has_success_claim(ui), "handoff only after successful save and validated reload")
 check(DirAccess.get_files_at(store.save_root).size() == 1, "only validated save remains")
 check(store.load_save(verified_slot, ui.worlds[0]).ok, "final save remains reloadable")
 for failed_slot in store.created_ids.slice(0, 2):
  check(not FileAccess.file_exists(store.save_root.path_join(failed_slot + ".json")), "failed attempt never left an orphan")
 ui.advance()
 ui.advance()
 check(store.created_ids.size() == 3 and DirAccess.get_files_at(store.save_root).size() == 1, "saved review and confirmation cannot duplicate")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_root.path_join(verified_slot + ".json")))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_root))
 # Back/cancel following a failed reload has no written slot to abandon.
 ui.saved_slot = ""
 ui.page = 3
 store.corrupt_reloads = 1
 ui.advance()
 ui.go_back()
 check(ui.page == 2 and not DirAccess.get_files_at(store.save_root).size(), "Back after failure leaves no save")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_root))
 # A failed removal must retain ownership and block duplicate writes or Back.
 var blocked_ui := CleanupBlockedOrigin.new()
 root.add_child(blocked_ui)
 var blocked_store := CorruptingStore.new()
 blocked_store.save_root = store.save_root + "-cleanup"
 blocked_store.corrupt_reloads = 1
 blocked_ui.store = blocked_store
 blocked_ui.advance()
 blocked_ui.advance()
 blocked_ui.advance()
 blocked_ui.advance()
 blocked_store.on_rejected_reload = func(): blocked_ui.block_cleanup = true
 blocked_ui.advance()
 var path: String = blocked_ui.unvalidated_save_path
 check(not path.is_empty() and FileAccess.file_exists(path), "failed immediate cleanup retains owned written slot")
 blocked_ui.advance()
 blocked_ui.go_back()
 check(blocked_ui.page == 3 and blocked_ui.saved_slot.is_empty() and not has_success_claim(blocked_ui), "cleanup failure blocks handoff and Back")
 check(blocked_store.created_ids.size() == 1 and DirAccess.get_files_at(blocked_store.save_root).size() == 1, "blocked cleanup cannot create a duplicate")
 check(blocked_ui.unvalidated_save_path == path, "cleanup failure retains exact owned path")
 blocked_ui.block_cleanup = false
 blocked_ui.advance()
 check(blocked_ui.page == 4 and blocked_store.created_ids.size() == 2, "cleanup recovery permits one validated retry")
 check(not FileAccess.file_exists(path) and DirAccess.get_files_at(blocked_store.save_root).size() == 1, "recovery removes failed slot and leaves only success")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_store.save_root.path_join(blocked_ui.saved_slot + ".json")))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_store.save_root))
 print("GAME-74 post-write reload regression: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
