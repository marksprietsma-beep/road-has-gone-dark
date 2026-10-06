extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME81_TEST_ROOT")
 var service := PartyService.new()
 service.library.library_root = base.path_join("library")
 service.store.save_root = base.path_join("saves")
 service.library.save_root = service.store.save_root
 var phase := OS.get_environment("GAME81_PHASE")
 if phase == "create":
  for i in 5:
   if service.library.discover().any(func(e: Dictionary): return e.world.seed=="game81-party-world-%d"%i): continue
   var stage := service.library.create_staging()
   check(stage.ok,"owned library staging")
   check(DirAccess.copy_absolute(base.path_join("generated/game81-party-world-%d/world.json"%i),stage.directory.path_join("world.json"))==OK,"actual fresh source bytes")
   var imported := service.library.import_generated(stage.directory)
   check(imported.ok,str(imported.get("error")))
  var entries := service.library.discover()
  check(entries.size()==7,"both presets and five fresh worlds")
  for entry in entries:
   var w: GameWorldTemplate = entry.world
   var profiles := OriginProfiles.new()
   check(profiles.load_world(w),profiles.error)
   var h: Dictionary = profiles.projection.hometowns.values()[0]
   var original := service.store.create_playthrough(w,int(h.state_id),int(h.burg_id),int(h.province_id))
   var state: Dictionary = original.state
   var old := WorldOriginLore.new()
   check(old.load_world(w,w.enrichment_directory),old.error)
   state.origin_enrichment = old.descriptor
   state.origin_profiles = profiles.descriptor
   var origin_sha := FileAccess.get_sha256((w.enrichment_directory if not w.enrichment_directory.is_empty() else WorldOriginLore.directory(w)).path_join("enrichment.json"))
   var profile_sha := FileAccess.get_sha256(OriginProfiles.directory(w).path_join("enrichment.json"))
   var slot: String = state.playthrough_id
   check(service.store.save_new(slot,state,w).ok,"one origin campaign")
   var result := service.operate(entry,slot,"generate")
   check(result.ok,str(result.get("error")))
   if not result.ok: continue
   for n in 3:
    var sibling: Dictionary = result.state.party.members[(n+1)%3].duplicate(true)
    result = service.operate(entry,slot,"edit",n+1,{"name":"Named Adventurer %d"%(n+1),"regenerate":true})
    check(result.ok,"edit each existing member")
    if result.ok:
     check(result.state.party.members[n].background_variant==1,"one persisted variant")
     check(result.state.party.members[n].name=="Named Adventurer %d"%(n+1),"edited name persisted")
     check(result.state.party.members[(n+1)%3]==sibling,"sibling unchanged")
   result = service.operate(entry,slot,"ready")
   check(result.ok and result.state.onboarding_stage=="party_ready","ready only after validated save")
   var path := ProjectSettings.globalize_path(service.store._slot_path(slot))
   var proof := FileAccess.open(path+".expected",FileAccess.WRITE)
   proof.store_string(FileAccess.get_sha256(path))
   proof.close()
   check(origin_sha==FileAccess.get_sha256((w.enrichment_directory if not w.enrichment_directory.is_empty() else WorldOriginLore.directory(w)).path_join("enrichment.json")) and profile_sha==FileAccess.get_sha256(OriginProfiles.directory(w).path_join("enrichment.json")),"V1/V2 bytes untouched")
 else:
  var entries := service.library.discover()
  var count := 0
  for name in DirAccess.get_files_at(service.store.save_root):
   if not name.ends_with(".json"): continue
   count += 1
   var raw := WorldOriginLore.read_json(service.store.save_root.path_join(name))
   var matching: Array = entries.filter(func(e: Dictionary): return e.id==raw.world_ref.id)
   check(matching.size()==1,"exact world after process restart")
   if matching.size()!=1: continue
   var entry: Dictionary = matching[0]
   var slot := name.trim_suffix(".json")
   var loaded := service.operate(entry,slot,"generate")
   check(loaded.ok,"restart resumes same campaign without reroll")
   var path := ProjectSettings.globalize_path(service.store._slot_path(slot))
   check(FileAccess.get_sha256(path)==FileAccess.get_file_as_string(path+".expected"),"restart retains exact all-three edited facts and names")
   var legacy := raw.duplicate(true)
   legacy.erase("party")
   legacy.erase("onboarding_stage")
   check(service.store._validate(legacy,entry.world).is_empty(),"legacy skeleton save remains valid with frozen pins")
   if not entry.preset:
    var package: String = WorldPeoples.directory(entry.world).path_join("enrichment.json")
    var bytes := FileAccess.get_file_as_bytes(package)
    var file := FileAccess.open(package,FileAccess.WRITE)
    file.store_string("{}")
    file.close()
    check(not service.operate(entry,slot,"edit",1,{"name":"Must Not Save"}).ok,"corrupt people package refused")
    check(FileAccess.get_sha256(path)==FileAccess.get_file_as_string(path+".expected"),"corruption preserves campaign and origin")
    check(FileAccess.get_file_as_string(package)=="{}","corrupt package never silently regenerated")
    file = FileAccess.open(package,FileAccess.WRITE)
    file.store_buffer(bytes)
    file.close()
    check(service.store.load_save(slot,entry.world).ok,"exact restoration permits same campaign reload")
   check(not service.library.delete_world(entry).ok,"used world remains protected")
  check(count==7,"seven campaigns only, no extra playthroughs")
 print("GAME-81 lifecycle ",phase,": ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
