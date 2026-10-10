extends "res://tests/sandbox/lifecycle.gd"
## Runs unchanged source main to create a blocked campaign, then repaired source
## in independent processes against exactly the same library/save directories.
func run() -> void:
 base=OS.get_environment("GAME99_CAMPAIGN_ROOT")
 DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 var phase := OS.get_environment("GAME99_CAMPAIGN_PHASE")
 if phase=="blocked":
  var stage := service.library.create_staging();check(stage.ok,"old library staging")
  var source := OS.get_environment("GAME99_WORLD")
  check(DirAccess.copy_absolute(source,str(stage.directory).path_join("world.json"))==OK,"original immutable source bytes")
  var imported := service.library.import_generated(stage.directory);check(imported.ok,str(imported.get("error","")));entry=imported.entry
  var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),profiles.error)
  var home: Dictionary=profiles.projection.hometowns.values()[0]
  var created := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id));check(created.ok,"original origin")
  slot=created.state.playthrough_id;check(service.store.save_new(slot,created.state,entry.world).ok,"original save writer")
  var party := PartyService.new();party.store=service.store;party.library=service.library
  check(party.operate(entry,slot,"generate").ok,"old persistent identities")
  for i in 3:check(party.operate(entry,slot,"edit",i+1,{"role_id":["vanguard","scout","adept"][i]}).ok,"old build")
  check(party.operate(entry,slot,"ready").ok,"old party ready")
  var bytes := FileAccess.get_file_as_string(service.store._slot_path(slot))
  var failed := service.operate(entry,slot,"resume")
  check(not failed.ok and str(failed.get("error","")).contains("9109"),"old helper reproduces exact geography failure")
  check(FileAccess.get_file_as_string(service.store._slot_path(slot))==bytes,"old failure preserves exact save")
  var loaded := service.store.load_save(slot,entry.world);check(loaded.ok,"blocked save validates")
  state=loaded.state
  FileAccess.open(base.path_join("old-save.json"),FileAccess.WRITE).store_string(bytes)
  FileAccess.open(base.path_join("checkpoint.json"),FileAccess.WRITE).store_string(JSON.stringify({"slot":slot,"world_sha":entry.world.source_sha256,"world_id":entry.world.world_id,"home":state.origin.home_burg_id,"party_ids":state.party_ids}))
 else:
  var checkpoint: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("checkpoint.json")));slot=checkpoint.slot
  var matches := service.library.discover().filter(func(e: Dictionary):return e.id==checkpoint.world_id);check(matches.size()==1,"same old world-library entry")
  entry=matches[0];check(entry.world.source_sha256==checkpoint.world_sha,"same canonical fingerprint")
  var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("old-save.json")))
  if phase=="recover":
   check(FileAccess.get_file_as_string(service.store._slot_path(slot))==FileAccess.get_file_as_string(base.path_join("old-save.json")),"install did not rewrite save")
   var loaded := service.operate(entry,slot,"resume");check(loaded.ok,str(loaded.get("error","")));state=loaded.state
   for field in ["origin","party","party_ids","characters","world_ref","world_deltas","known_sites"]:
    if old.has(field):check(RulesJson.digest(state[field])==RulesJson.digest(old[field]),"old campaign preserves "+field)
   check(state.origin.home_burg_id==checkpoint.home,"same selected hometown")
   var bytes := FileAccess.get_file_as_string(service.store._slot_path(slot))
   check(service.operate(entry,slot,"resume").ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==bytes,"recovery retry idempotent")
   action("sandbox_begin");travel(0);action("sandbox_fight")
   action("sandbox_command",{"command":command(AdventureService.active_battle(state))})
   FileAccess.open(base.path_join("battle-checkpoint.json"),FileAccess.WRITE).store_string(JSON.stringify({"hash":AdventureService.active_battle(state).state_hash,"rng":AdventureService.active_battle(state).rng,"base_sha":state.sandbox.base_sha}))
  else:
   var battle_checkpoint: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("battle-checkpoint.json")))
   var loaded := service.operate(entry,slot,"resume");check(loaded.ok,str(loaded.get("error","")));state=loaded.state
   check(AdventureService.active_battle(state).state_hash==battle_checkpoint.hash and RulesJson.digest(AdventureService.active_battle(state).rng)==RulesJson.digest(battle_checkpoint.rng),"repaired campaign resumes exact tactical state")
   fight_to_result();action("sandbox_return")
   check(state.sandbox.base_sha==battle_checkpoint.base_sha and state.sandbox.results.size()==1,"same saved opportunities and one result")
   check(state.party_ids==checkpoint.party_ids and RulesJson.digest(state.party)==RulesJson.digest(old.party),"original people/builds survive battle and home return")
   var bytes := FileAccess.get_file_as_string(service.store._slot_path(slot));check(service.operate(entry,slot,"resume").ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==bytes,"resume cannot duplicate rewards/history")
 var proof := {"phase":phase,"checks":checks,"failures":failures,"world_sha":entry.world.source_sha256,"slot":slot,"party_ids":state.party_ids,"home":state.origin.home_burg_id,"save_sha":FileAccess.get_sha256(service.store._slot_path(slot))}
 FileAccess.open(base.path_join("proof-"+phase+".json"),FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print("GAME99 CAMPAIGN ",phase," ",checks," checks / ",failures," failures");quit(1 if failures else 0)
