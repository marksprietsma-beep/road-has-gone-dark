extends SceneTree
class FaultStore extends GamePlaythroughStore:
 var fail_write := false
 var fail_reload := false
 var pending := false
 var last_candidate := {}
 func save_existing(slot: String, state: Dictionary, world: GameWorldTemplate) -> Dictionary:
  if fail_write: return _fail("Injected write failure")
  last_candidate = state.duplicate(true)
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
class FaultPackedInput extends PartyService:
 var copies := 0
 func _copy_input(source: String, target: String) -> bool:
  copies += 1
  if copies == 2: return false
  return super._copy_input(source,target)
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
func wait_ui(ui: Control) -> void:
 var deadline := Time.get_ticks_msec()+90000
 while ui.thread!=null and Time.get_ticks_msec()<deadline: await process_frame
 check(ui.thread==null,"UI job completed")
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
 var packed := FaultPackedInput.new()
 packed.store = service.store
 var job_root := ProjectSettings.globalize_path("user://party-jobs")
 var jobs_before := DirAccess.get_directories_at(job_root) if DirAccess.dir_exists_absolute(job_root) else PackedStringArray()
 check(not packed.operate(entry,slot,"generate").ok,"partial packed-resource preparation failure is controlled")
 check(FileAccess.get_file_as_string(path)==original,"failed packed inputs preserve exact origin")
 check(DirAccess.get_directories_at(job_root)==jobs_before,"partial packed inputs leave no owned job orphan")
 var bad := FaultGenerator.new()
 bad.store = service.store
 check(not bad.operate(entry,slot,"generate").ok,"generator failure is controlled")
 check(FileAccess.get_file_as_string(path)==original,"failed generation retains exact origin")
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root}
 var preparation=load("res://scenes/ui/party_creation.tscn").instantiate()
 preparation.service=bad
 root.add_child(preparation)
 await wait_ui(preparation)
 check(preparation.state.is_empty() and not preparation.ready_view,"failed generation has no party success state")
 check(preparation.save_button.text=="Retry preparation" and not preparation.save_button.disabled,"failed preparation has explicit retry")
 preparation.service=service
 service.store.fail_reload=true
 preparation._save_changes()
 await wait_ui(preparation)
 check(preparation.state.is_empty() and not preparation.message.contains("Party saved"),"failed preparation reload makes no success claim")
 check(FileAccess.get_file_as_string(path)==original,"failed preparation reload keeps original bytes")
 service.store.fail_reload=false
 preparation._save_changes()
 await wait_ui(preparation)
 check(not preparation.state.is_empty() and preparation.state.playthrough_id==slot,"preparation retry completes same campaign")
 preparation.queue_free()
 await process_frame
 put(path,original) # Restore the owned origin for the service failure cases.
 service.store.fail_write = true
 check(not service.operate(entry,slot,"generate").ok,"write failure never reports success")
 check(FileAccess.get_file_as_string(path)==original,"write failure keeps old bytes")
 service.store.fail_write = false
 service.store.fail_reload = true
 check(not service.operate(entry,slot,"generate").ok,"post-write reload failure never reports success")
 var rejected_candidate: Dictionary = service.store.last_candidate.duplicate(true)
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
 check(valid==rejected_candidate,"retry regenerates identical candidate in same campaign")
 var raw := FileAccess.get_file_as_string(path)
 for mutation in ["character","background","people","role","incomplete","secret","occupation","missing_fact","malformed_character","malformed_party_id","profile_identity","relationship"]:
  var invalid := valid.duplicate(true)
  match mutation:
   "character": invalid.party.members[0].character_id = "bad"
   "background": invalid.party.members[0].background_id = invalid.party.members[0].background_id.left(-1) + "x"
   "people": invalid.party.members[0].people_id = "bad"
   "role": invalid.party.members[0].role_id = "bad"
   "incomplete": invalid.party.members.pop_back()
   "secret": invalid.party.members[0].generated_facts.background.local_knowledge.hidden_pois.append("private")
   "occupation": invalid.party.members[0].generated_facts.occupation_id = "bad"
   "missing_fact":
    invalid.party.members[0].generated_facts.erase("foundation_occupation_id")
    invalid.party.members[0].generated_facts.unsupported="bad"
   "malformed_character": invalid.characters[0]="bad"
   "malformed_party_id": invalid.party_ids[2]=42
   "profile_identity": invalid.party.members[0].generated_facts.origin_identity.posture="invented"
   "relationship": invalid.party.members[0].generated_facts.public_relationship.other_character_ids=[]
  check(not service.commit(slot,invalid,world).ok,"invalid " + mutation + " rejected")
  check(FileAccess.get_file_as_string(path)==raw,"invalid " + mutation + " preserves bytes")
 service.store.fail_reload=true
 check(not service.operate(entry,slot,"ready").ok,"failed ready reload never reports handoff")
 check(service.store.load_save(slot,world).state.onboarding_stage=="party_creation","failed ready keeps draft stage")
 check(FileAccess.get_file_as_string(path)==raw,"failed ready restores draft bytes")
 service.store.fail_reload=false
 # Exercise the actual production presenter, not just the service result.
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root}
 var ui=load("res://scenes/ui/party_creation.tscn").instantiate()
 ui.service=service
 root.add_child(ui)
 await wait_ui(ui)
 service.store.fail_reload=true
 ui._finish()
 await wait_ui(ui)
 check(not ui.ready_view and ui.state.onboarding_stage=="party_creation","UI never hands off after failed reload")
 check(not ui.message.contains("Party saved") and ui.message.contains("restored"),"UI displays error, no false saved claim")
 check(FileAccess.get_file_as_string(path)==raw,"UI failed handoff restores exact draft")
 service.store.fail_reload=false
 ui._finish()
 await wait_ui(ui)
 check(ui.ready_view and ui.state.onboarding_stage=="party_ready","UI deterministic retry validates same campaign")
 ui.queue_free()
 await process_frame
 put(path,raw) # Restore this owned test draft for the crash scenarios below.
 var journals := {"before":raw,"after_sha":raw.sha256_text()}
 put(service._journal(slot),JSON.stringify(journals))
 check(service.recover(slot,world).ok,"restart validates completed same-slot transaction")
 check(not FileAccess.file_exists(service._journal(slot)),"completed transaction journal cleaned")
 # A crash after Game-7 moved its backup but before publication.
 put(service._journal(slot),JSON.stringify({"before":raw,"after_sha":"pending"}))
 check(DirAccess.rename_absolute(path,path+".bak")==OK,"simulate interrupted existing-slot rename")
 check(service.recover(slot,world).ok,"restart recovers Game-7 backup without new campaign")
 check(FileAccess.get_file_as_string(path)==raw,"interrupted write recovered exact bytes")
 # Exact crash in the middle of the party rollback, after moving aside
 # the candidate but before publishing the already-verified previous bytes.
 var candidate := valid.duplicate(true)
 candidate.party.status="ready"
 candidate.onboarding_stage="party_ready"
 var after := JSON.stringify(candidate,"  ")
 put(service._journal(slot),JSON.stringify({"before":raw,"after_sha":after.sha256_text()}))
 put(path+".party-rollback",raw)
 check(DirAccess.rename_absolute(path,path+".party-unverified")==OK,"simulate interrupted rollback")
 put(path+".party-unverified",after)
 check(service.recover(slot,world).ok,"restart finishes exact owned rollback")
 check(FileAccess.get_file_as_string(path)==raw,"rollback crash restores prior draft")
 check(not FileAccess.file_exists(path+".party-rollback") and not FileAccess.file_exists(path+".party-unverified"),"owned rollback files cleaned")
 var edited := service.operate(entry,slot,"edit",2,{"regenerate":true})
 check(edited.ok,"deterministic retry succeeds")
 if edited.ok:
  check(edited.state.party.members[1].background_variant==1,"retry advances single stored variant once")
  check(edited.state.party.members[0]==valid.party.members[0],"retry does not reroll sibling")
 check(DirAccess.get_files_at(service.store.save_root).size()==1,"one campaign, no orphan/duplicate/recovery files")
 print("GAME-81 failure checks: ",checks,"; failures: ",failures)
 quit(1 if failures else 0)
