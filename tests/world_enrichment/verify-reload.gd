extends SceneTree
class AlternateLibrary extends GameWorldLibrary:
 var lore_path := ""
 func enrichment_directory(_entry: Dictionary) -> String:
  return lore_path
class FailingLoreStore extends GamePlaythroughStore:
 var descriptor_path := ""
 var damage := true
 func load_save(slot: String, world: GameWorldTemplate) -> Dictionary:
  if damage:
   damage = false
   var d := WorldOriginLore.read_json(descriptor_path)
   d.enrichment_sha = "0".repeat(64)
   var f := FileAccess.open(descriptor_path, FileAccess.WRITE)
   f.store_string(JSON.stringify(d))
   f.close()
  return super.load_save(slot, world)
var checks := 0
var failures := 0
func check(value: bool, why: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(why)
func success_claim(node: Node) -> bool:
 if node is Label and node.text.contains("Your origin has been saved"): return true
 for child in node.get_children():
  if success_claim(child): return true
 return false
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var directory := "user://game79-postwrite-" + Crypto.new().generate_random_bytes(8).hex_encode()
 var lore_path := directory.path_join("origin-v1")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(lore_path))
 for name in ["descriptor.json", "enrichment.json", "public.json"]:
  DirAccess.copy_absolute(ProjectSettings.globalize_path("res://data/world_enrichment/presets/game-11-determinism/" + name), ProjectSettings.globalize_path(lore_path.path_join(name)))
 var original := FileAccess.get_file_as_bytes(lore_path.path_join("descriptor.json"))
 var ui = load("res://scenes/ui/new_game_origin.tscn").instantiate()
 root.add_child(ui)
 # Keep this origin regression at its persistence boundary; GAME-81
 # capture-flow exercises the real default party scene routing.
 ui.party_creation_requested.disconnect(ui._open_party)
 var library := AlternateLibrary.new()
 library.lore_path = lore_path
 ui.library = library
 ui.origin_lore_cache.clear()
 var store := FailingLoreStore.new()
 store.save_root = directory.path_join("saves")
 store.descriptor_path = lore_path.path_join("descriptor.json")
 ui.store = store
 ui.advance()
 ui.advance()
 check(ui.page == 1 and ui.area_view == "region", "state advances to explicit region choice")
 ui.advance()
 ui.advance()
 ui.advance()
 check(ui.page == 3 and ui.saved_slot.is_empty(), "post-write lore failure never reaches handoff")
 check(not success_claim(ui), "failed lore validation never claims saved success")
 check(not ui.pending_enrichment_slot.is_empty(), "exact written slot retained for retry")
 var slot: String = ui.pending_enrichment_slot
 check(FileAccess.file_exists(store.save_root.path_join(slot + ".json")), "invalid enrichment never deletes a written campaign")
 ui.advance()
 check(ui.page == 3 and ui.pending_enrichment_slot == slot, "retry revalidates the same slot")
 check(DirAccess.get_files_at(store.save_root).size() == 1 and not success_claim(ui), "failed retry creates no duplicate or false claim")
 var f := FileAccess.open(store.descriptor_path, FileAccess.WRITE)
 f.store_buffer(original)
 f.close()
 ui.advance()
 check(ui.page == 4 and ui.saved_slot == slot and success_claim(ui), "exact restoration validates retained slot and allows handoff")
 check(DirAccess.get_files_at(store.save_root).size() == 1 and store.load_save(slot, ui.worlds[0]).ok, "one reloadable campaign remains")
 ui.advance()
 ui.advance()
 check(DirAccess.get_files_at(store.save_root).size() == 1, "review never duplicates retained campaign")
 for name in DirAccess.get_files_at(store.save_root): DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_root.path_join(name)))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_root))
 for name in DirAccess.get_files_at(lore_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(lore_path.path_join(name)))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(lore_path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
 print("GAME-79 post-write lore regression: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
