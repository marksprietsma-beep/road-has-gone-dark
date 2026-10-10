extends SceneTree
class AlternateLibrary extends GameWorldLibrary:
 var profile_path := ""
 func profiles_directory(_entry: Dictionary) -> String: return profile_path
class DamagingStore extends GamePlaythroughStore:
 var descriptor_path := ""
 var damage := true
 func load_save(slot: String, world: GameWorldTemplate) -> Dictionary:
  if damage:
   damage = false
   var d := WorldOriginLore.read_json(descriptor_path)
   d.enrichment_sha = "0".repeat(64)
   var f := FileAccess.open(descriptor_path,FileAccess.WRITE)
   f.store_string(JSON.stringify(d))
   f.close()
  return super.load_save(slot,world)
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
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var path := OS.get_environment("GAME80_TEST_ROOT").path_join("postwrite/profiles-v2")
 DirAccess.make_dir_recursive_absolute(path)
 for name in ["descriptor.json","enrichment.json","public.json"]:
  check(DirAccess.copy_absolute(ProjectSettings.globalize_path("res://data/world_enrichment/presets-profiles-v2/game-11-determinism/" + name),path.path_join(name)) == OK,"copy isolated profile bytes")
 var original := FileAccess.get_file_as_bytes(path.path_join("descriptor.json"))
 var ui = load("res://scenes/ui/new_game_origin.tscn").instantiate()
 root.add_child(ui)
 var library := AlternateLibrary.new()
 library.profile_path = path
 ui.library = library
 ui.origin_profile_cache.clear()
 var store := DamagingStore.new()
 store.save_root = path.get_base_dir().path_join("saves")
 store.descriptor_path = path.path_join("descriptor.json")
 ui.store = store
 for n in 5: ui.advance()
 check(ui.page == 3 and ui.saved_slot.is_empty() and not success_claim(ui),"profile reload failure prevents success handoff and false claim")
 var slot: String = ui.pending_enrichment_slot
 check(not slot.is_empty() and FileAccess.file_exists(store.save_root.path_join(slot + ".json")),"written campaign retained")
 ui.advance()
 check(ui.pending_enrichment_slot == slot and DirAccess.get_files_at(store.save_root).size() == 1,"same-slot retry, no duplicate")
 ui.go_back()
 check(ui.page == 3,"pending written campaign cannot be abandoned")
 var f := FileAccess.open(store.descriptor_path,FileAccess.WRITE)
 f.store_buffer(original)
 f.close()
 ui.advance()
 check(ui.page == 4 and ui.saved_slot == slot and success_claim(ui),"exact restore completes one validated campaign")
 check(store.load_save(slot,ui.worlds[0]).ok and DirAccess.get_files_at(store.save_root).size() == 1,"both pins reload, exactly one save")
 print("GAME-80 profile post-write: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
