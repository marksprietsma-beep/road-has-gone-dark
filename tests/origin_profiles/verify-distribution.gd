extends Node
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(why)
func _ready() -> void:
 var library := GameWorldLibrary.new()
 var base := OS.get_environment("GAME80_DISTRIBUTION_TEST_ROOT")
 library.library_root = base.path_join("library")
 library.save_root = base.path_join("saves")
 check(OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"uses automatically bundled helper, no source override")
 check(library.helper_status().ok,"exported executable locates exact bundled helper")
 for entry in library.discover():
  var profiles := OriginProfiles.new()
  check(profiles.load_world(entry.world),profiles.error)
 var stage := library.create_staging()
 check(stage.ok,"native distribution stages fresh world")
 if stage.ok:
  var generated := library.run_generator(stage.directory,"game80-export-smoke")
  check(generated.ok,str(generated.get("error")))
  if generated.ok:
   var imported := library.import_generated(stage.directory)
   check(imported.ok,str(imported.get("error")))
   if imported.ok:
    var profiles := OriginProfiles.new()
    check(profiles.load_world(imported.entry.world),profiles.error)
    var row: Dictionary = profiles.projection.hometowns[profiles.projection.hometowns.keys()[0]]
    var store := GamePlaythroughStore.new()
    store.save_root = library.save_root
    var created := store.create_playthrough(imported.entry.world,int(row.state_id),int(row.burg_id),int(row.province_id))
    var old := WorldOriginLore.new()
    check(old.load_world(imported.entry.world,imported.entry.world.enrichment_directory),old.error)
    created.state.origin_enrichment = old.descriptor
    created.state.origin_profiles = profiles.descriptor
    check(store.save_new(created.state.playthrough_id,created.state,imported.entry.world).ok,"standalone new campaign persisted")
    check(store.load_save(created.state.playthrough_id,imported.entry.world).ok,"standalone dual-pin reload")
 print("GAME-80 complete native distribution: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
