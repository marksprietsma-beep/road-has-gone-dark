extends SceneTree
var checks := 0
var failures := 0
var service := RulesService.new()
var base: String
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 base=OS.get_environment("GAME32_TEST_ROOT")
 service.store.save_root=base.path_join("saves")
 service.library.library_root=base.path_join("library")
 service.library.save_root=service.store.save_root
 var phase := OS.get_environment("GAME32_PHASE")
 var entry: Dictionary=service.library.discover()[0]
 var world: GameWorldTemplate=entry.world
 if phase=="reload":
  var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("migration.json")))
  var loaded := service.store.load_save(metadata.slot,world)
  check(loaded.ok,"prepared save reloads in a new process")
  if loaded.ok:
   check(RulesJson.digest(loaded.state)==metadata.state_hash,"entire campaign stable after process restart")
   for id in loaded.state.mechanics.records:
    check(RulesCharacter.new(RulesRecords.registry()).derive_character(loaded.state.mechanics.records[id]).snapshot.snapshot_hash==metadata.snapshots[id],"derived snapshot stable across restart")
 else:
  var profiles := OriginProfiles.new()
  check(profiles.load_world(world),profiles.error)
  var hometown: Dictionary=profiles.projection.hometowns.values()[0]
  var created := service.store.create_playthrough(world,int(hometown.state_id),int(hometown.burg_id),int(hometown.province_id))
  check(created.ok,"actual existing origin")
  var slot: String=created.state.playthrough_id
  check(service.store.save_new(slot,created.state,world).ok,"save original origin")
  var generated := service.operate(entry,slot,"generate")
  check(generated.ok,str(generated.get("error")))
  if not generated.ok: finish();return
  var ready := service.operate(entry,slot,"ready")
  check(ready.ok,"existing four narrative characters ready")
  var expedition := ExpeditionService.new()
  expedition.store=service.store;expedition.library=service.library;expedition.cache_root=base.path_join("cache")
  var resumed := expedition.operate(entry,slot,"resume")
  check(resumed.ok,"existing expedition initialization "+str(resumed.get("error")))
  if not resumed.ok: finish();return
  var lead: String=resumed.state.expedition.leads[0].id
  var accepted := expedition.operate(entry,slot,"accept",1,{"revision":resumed.state.expedition.revision,"lead":lead})
  check(accepted.ok,"existing lead accepted")
  var departed := expedition.operate(entry,slot,"depart",1,{"revision":accepted.state.expedition.revision,"lead":lead})
  check(departed.ok,"active expedition before mechanics migration")
  if not departed.ok: finish();return
  var old: Dictionary=departed.state
  var path := service.store._slot_path(slot)
  var original_bytes := FileAccess.get_file_as_string(path)
  check(RulesRecords.preparation_status(old)=="not_prepared" and service.store.load_save(slot,world).ok,"historical save valid without mechanics")
  var preview := RulesRecords.preview_preparation(old)
  check(preview.ok,"explicit migration preview "+str(preview.get("error")))
  if not preview.ok: finish();return
  check(FileAccess.get_file_as_string(path)==original_bytes,"migration preview makes no save write")
  var detached: Dictionary=preview.candidate.duplicate(true);detached.erase("mechanics")
  check(detached==old,"all historical campaign fields remain exactly equal")
  for i in old.characters.size():
   var id: String=old.characters[i].id
   check(preview.candidate.mechanics.records.has(id),"existing stable identity used")
   check(preview.candidate.characters[i]==old.characters[i] and preview.candidate.party.members[i]==old.party.members[i],"names biographies ancestry narrative role slot relationships untouched")
  var committed := service.commit_preview(entry,slot,preview)
  check(committed.ok,"transactional migration commit "+str(committed.get("error")))
  if not committed.ok: finish();return
  var migration_bytes := FileAccess.get_file_as_string(path)
  check(service.commit_preview(entry,slot,RulesRecords.preview_preparation(committed.state)).ok and FileAccess.get_file_as_string(path)==migration_bytes,"idempotent preparation leaves exact bytes")
  check(not service.commit_preview(entry,slot,preview).ok and FileAccess.get_file_as_string(path)==migration_bytes,"stale migration preserves exact bytes")
  var identity: String=old.characters[0].id
  var kernel := RulesCharacter.new(RulesRecords.registry())
  var record: Dictionary=committed.state.mechanics.records[identity]
  var choice := kernel.suggested_choice(record,"wayfinder")
  var advanced := RulesRecords.preview_advancement(committed.state,identity,choice.choice)
  check(advanced.ok,"multiclass campaign preview")
  var corrupt := advanced.duplicate(true);corrupt.candidate_hash="tampered"
  check(not service.commit_preview(entry,slot,corrupt).ok and FileAccess.get_file_as_string(path)==migration_bytes,"tampered preview rejects without write")
  var applied := service.commit_preview(entry,slot,advanced)
  check(applied.ok,"existing recovery/atomic save progression commit")
  if not applied.ok: finish();return
  check(applied.state.expedition==old.expedition and applied.state.party==old.party and applied.state.characters==old.characters,"advancement preserves active expedition and entire narrative party")
  var saved_bytes := FileAccess.get_file_as_string(path)
  for i in 200:
   var invalid: Dictionary=choice.choice.duplicate(true);invalid.class_id="missing"
   check(not RulesRecords.preview_advancement(applied.state,identity,invalid).ok and FileAccess.get_file_as_string(path)==saved_bytes,"200 invalid campaign previews preserve exact bytes")
  check(not service.commit_preview(entry,slot,advanced).ok and FileAccess.get_file_as_string(path)==saved_bytes,"duplicate advance cannot apply twice")
  var bad: Dictionary=applied.state.duplicate(true);bad.mechanics.rules_ref.content_hash="wrong"
  check(not service.store._validate(bad,world).is_empty(),"exact mismatched pack pin rejected")
  bad=applied.state.duplicate(true);bad.mechanics.records.erase(identity)
  check(not service.store._validate(bad,world).is_empty(),"missing mechanics identity rejected")
  bad=applied.state.duplicate(true);bad.mechanics.records[identity].runtime.resources["focus"]=10000
  check(not service.store._validate(bad,world).is_empty(),"unowned/out-of-cap resource rejected")
  var snapshots := {}
  for id in applied.state.mechanics.records: snapshots[id]=kernel.derive_character(applied.state.mechanics.records[id]).snapshot.snapshot_hash
  var file := FileAccess.open(base.path_join("migration.json"),FileAccess.WRITE)
  file.store_string(JSON.stringify({"slot":slot,"state_hash":RulesJson.digest(applied.state),"snapshots":snapshots}));file.close()
 finish()
func finish() -> void:
 var output := OS.get_environment("GAME32_EVIDENCE")
 var file := FileAccess.open(output.path_join("migration-"+OS.get_environment("GAME32_PHASE")+".json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")+"\n");file.close()
 print("GAME-32 migration checks=",checks," failures=",failures)
 quit(1 if failures else 0)
