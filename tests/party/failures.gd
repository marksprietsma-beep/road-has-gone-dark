extends SceneTree
class FaultStore extends GamePlaythroughStore:
 var fail_write := false
 var fail_reload := false
 var pending := false
 func save_existing(slot: String, state: Dictionary, world: GameWorldTemplate) -> Dictionary:
  if fail_write: return _fail("Injected write failure")
  var result := super.save_existing(slot,state,world)
  if result.ok and fail_reload: pending = true
  return result
 func load_save(slot: String, world: GameWorldTemplate) -> Dictionary:
  if pending:
   pending = false
   return _fail("Injected post-write validation failure")
  return super.load_save(slot,world)
class FaultGenerator extends PartyService:
 func _helper(_entry: Dictionary, _request: Dictionary) -> Dictionary:
  return fail("Injected generator failure")
var failures := 0
var checks := 0
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(why)
func put(path: String, text: String) -> void:
 var file := FileAccess.open(path,FileAccess.WRITE)
 file.store_string(text)
 file.close()
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var service := PartyService.new()
 service.store = FaultStore.new()
 service.store.save_root = "user://game81-failures-" + Crypto.new().generate_random_bytes(8).hex_encode()
 var entry: Dictionary = service.library.discover()[0]
 var world: GameWorldTemplate = entry.world
 var reader := OriginProfiles.new()
 check(reader.load_world(world),reader.error)
 var home: Dictionary = reader.projection.hometowns.values()[0]
 var made := service.store.create_playthrough(world,int(home.state_id),int(home.burg_id),int(home.province_id))
 var state: Dictionary = made.state
 state.origin_profiles = reader.descriptor
 var legacy := WorldOriginLore.new()
 check(legacy.load_world(world),legacy.error)
 state.origin_enrichment = legacy.descriptor
 var slot: String = state.playthrough_id
 check(service.store.save_new(slot,state,world).ok,"origin written once")
 var path := ProjectSettings.globalize_path(service.store._slot_path(slot))
 var original := FileAccess.get_file_as_string(path)
 var bad := FaultGenerator.new()
 bad.store = service.store
 check(not bad.operate(entry,slot,"generate").ok,"generator failure is controlled")
 check(FileAccess.get_file_as_string(path)==original,"failed generation retains exact origin")
 service.store.fail_write = true
 check(not service.operate(entry,slot,"generate").ok,"write failure never reports success")
 check(FileAccess.get_file_as_string(path)==original,"write failure keeps old bytes")
 service.store.fail_write = false
 service.store.fail_reload = true
 check(not service.operate(entry,slot,"generate").ok,"post-write reload failure never reports success")
 check(FileAccess.get_file_as_string(path)==original,"failed reload restores exact origin")
 check(not service.store.load_save(slot,world).state.has("party"),"no false party handoff/state")
 check(not FileAccess.file_exists(service._journal(slot)),"successful rollback leaves no journal")
 service.store.fail_reload = false
 var generated := service.operate(entry,slot,"generate")
 check(generated.ok,str(generated.get("error")))
 if not generated.ok:
  quit(1)
  return
 var valid: Dictionary = generated.state
 var raw := FileAccess.get_file_as_string(path)
 for mutation in ["character","background","people","role","incomplete","secret","occupation"]:
  var invalid := valid.duplicate(true)
  match mutation:
   "character": invalid.party.members[0].character_id = "bad"
   "background": invalid.party.members[0].background_id = invalid.party.members[0].background_id.left(-1) + "x"
   "people": invalid.party.members[0].people_id = "bad"
   "role": invalid.party.members[0].role_id = "bad"
   "incomplete": invalid.party.members.pop_back()
   "secret": invalid.party.members[0].generated_facts.background.local_knowledge.hidden_pois.append("private")
   "occupation": invalid.party.members[0].generated_facts.occupation_id = "bad"
  check(not service.commit(slot,invalid,world).ok,"invalid " + mutation + " rejected")
  check(FileAccess.get_file_as_string(path)==raw,"invalid " + mutation + " preserves bytes")
 var journals := {"before":raw,"after_sha":raw.sha256_text()}
 put(service._journal(slot),JSON.stringify(journals))
 check(service.recover(slot,world).ok,"restart validates completed same-slot transaction")
 check(not FileAccess.file_exists(service._journal(slot)),"completed transaction journal cleaned")
 # A crash after Game-7 moved its backup but before publication.
 put(service._journal(slot),JSON.stringify({"before":raw,"after_sha":"pending"}))
 check(DirAccess.rename_absolute(path,path+".bak")==OK,"simulate interrupted existing-slot rename")
 check(service.recover(slot,world).ok,"restart recovers Game-7 backup without new campaign")
 check(FileAccess.get_file_as_string(path)==raw,"interrupted write recovered exact bytes")
 var edited := service.operate(entry,slot,"edit",2,{"regenerate":true})
 check(edited.ok,"deterministic retry succeeds")
 if edited.ok:
  check(edited.state.party.members[1].background_variant==1,"retry advances single stored variant once")
  check(edited.state.party.members[0]==valid.party.members[0],"retry does not reroll sibling")
 check(DirAccess.get_files_at(service.store.save_root).size()==1,"one campaign, no orphan/duplicate/recovery files")
 print("GAME-81 failure checks: ",checks,"; failures: ",failures)
 quit(1 if failures else 0)
