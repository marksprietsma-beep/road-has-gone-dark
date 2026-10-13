extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize() -> void:
 check(CharacterBuilderRecords.xp({},"hero")==0,"missing optional progression stays zero")
 check(CharacterBuilderRecords.xp({"sandbox":{"characters":{"hero":{"xp":20.0}}},"first_adventure":{"characters":{"hero":{"xp":10}}}},"hero")==30,"real integer JSON XP totals preserved")
 for value in [[],"bad",false,1,null]:
  check(CharacterBuilderRecords.xp({"sandbox":value},"hero")==0,"malformed namespace cannot fund advancement")
  check(CharacterBuilderRecords.xp({"sandbox":{"characters":value}},"hero")==0,"malformed roster cannot throw or fund advancement")
  check(CharacterBuilderRecords.xp({"sandbox":{"characters":{"hero":value}}},"hero")==0,"malformed character cannot throw or fund advancement")
 for value in ["20",true,[],{},-1,0.5,INF]:
  check(CharacterBuilderRecords.xp({"sandbox":{"characters":{"hero":{"xp":value}}}},"hero")==0,"XP must be a bounded nonnegative integer")
 var base := OS.get_environment("GAME103_TEST_ROOT")
 var service := CharacterBuilderService.new();service.store.save_root=base.path_join("legacy/saves");service.library.library_root=base.path_join("legacy/library")
 var metadata := WorldOriginLore.read_json(base.path_join("legacy.json"))
 var entry: Dictionary=service.library.discover().filter(func(e: Dictionary):return e.world.source_sha256==metadata.world_sha)[0]
 var loaded := service.store.load_save(metadata.slot,entry.world);check(loaded.ok,"genuine earned legacy advancement remains readable")
 var broken: Dictionary=loaded.state.duplicate(true);broken.sandbox.characters=[]
 check(not service.store._validate(broken,entry.world).is_empty(),"malformed advanced save returns validation failure without script error")
 FileAccess.open(base.path_join("xp-shape-results.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
 print("GAME103 XP shape ",checks," / ",failures);quit(1 if failures else 0)
