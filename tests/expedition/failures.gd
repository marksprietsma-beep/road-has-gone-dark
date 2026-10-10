extends SceneTree
class FaultStore extends GamePlaythroughStore:
 var mode: String=""
 var pending:=false
 func save_existing(slot: String,state: Dictionary,world: GameWorldTemplate) -> Dictionary:
  if mode=="write": return _fail("Deliberate write failure")
  var result:=super.save_existing(slot,state,world)
  if mode=="reload" and result.ok: pending=true
  return result
 func load_save(slot: String,world: GameWorldTemplate) -> Dictionary:
  if pending:
   pending=false
   return _fail("Deliberate immediate reload failure")
  return super.load_save(slot,world)
var checks:=0
var failures:=0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var base:=OS.get_environment("GAME84_TEST_ROOT")
 var service:=ExpeditionService.new()
 var faulty:=FaultStore.new()
 service.store=faulty
 service.store.save_root=base.path_join("saves")
 service.library.library_root=base.path_join("library")
 service.library.save_root=service.store.save_root
 service.cache_root=base.path_join("cache")
 var entries:=service.library.discover()
 var files:=DirAccess.get_files_at(service.store.save_root)
 var names: Array=[]
 for name in files:
  if name.ends_with(".json"): names.append(name)
 check(not names.is_empty(),"owned campaign corpus exists")
 if names.is_empty(): quit(1);return
 var raw:=WorldOriginLore.read_json(service.store.save_root.path_join(names[0]))
 var entry: Dictionary=entries.filter(func(e: Dictionary):return e.id==raw.world_ref.id)[0]
 var slot: String=raw.playthrough_id
 var loaded:=service.operate(entry,slot,"resume")
 check(loaded.ok,"valid ready campaign")
 var state: Dictionary=loaded.state
 var path:=ProjectSettings.globalize_path(service.store._slot_path(slot))
 var before:=FileAccess.get_file_as_string(path)
 var candidate:=state.duplicate(true)
 service._event(candidate,"accept","A test account is recorded.",0)
 for mode in ["write","reload"]:
  faulty.mode=mode
  var failed:=service.commit(slot,candidate,entry.world)
  check(not failed.ok,"forced "+mode+" rejects handoff")
  check(FileAccess.get_file_as_string(path)==before,"exact previous bytes preserved after "+mode)
  check(not FileAccess.file_exists(service._journal(slot)),"no orphan recovery snapshot")
  check(DirAccess.get_files_at(service.store.save_root)==files,"no duplicate/orphan save slot")
 faulty.mode=""
 var retried:=service.commit(slot,candidate,entry.world)
 check(retried.ok and retried.state.expedition.revision==state.expedition.revision+1,"retry applies exactly once")
 check(retried.state.expedition.log.size()==state.expedition.log.size()+1,"no double log/time")
 # An interrupted validated write is accepted once; an invalid exact after-image
 # restores its recorded before-image, never deletes or fabricates a campaign.
 var after:=FileAccess.get_file_as_string(path)
 var file:=FileAccess.open(service._journal(slot),FileAccess.WRITE)
 file.store_string(JSON.stringify({"before":before,"after_sha":after.sha256_text()}))
 file.close()
 check(service.recover(slot,entry.world).ok,"crash after validated write resumes committed state")
 check(FileAccess.get_file_as_string(path)==after,"crash does not repeat consequence")
 file=FileAccess.open(path,FileAccess.WRITE)
 file.store_string("{}")
 file.close()
 file=FileAccess.open(service._journal(slot),FileAccess.WRITE)
 file.store_string(JSON.stringify({"before":after,"after_sha":"{}".sha256_text()}))
 file.close()
 check(service.recover(slot,entry.world).ok and FileAccess.get_file_as_string(path)==after,"unverified crash restores exact prior campaign")
 # Preserve external changes rather than overwriting them during recovery.
 file=FileAccess.open(service._journal(slot),FileAccess.WRITE)
 file.store_string(JSON.stringify({"before":before,"after_sha":"{}".sha256_text()}))
 file.close()
 check(not service.recover(slot,entry.world).ok and FileAccess.get_file_as_string(path)==after,"external changes preserved with recovery evidence")
 DirAccess.remove_absolute(service._journal(slot))
 file=FileAccess.open(path,FileAccess.WRITE)
 file.store_string(before)
 file.close()
 var content: Dictionary=service.packet.content
 for m in state.party.members:
  var saved: String=m.role_id
  for role in ["scout","adept","expert","vanguard"]:
   m.role_id=role
   var choices:=ExpeditionService.choices(state,content.sites[0])
   check(choices.any(func(o: Dictionary):return o.id=="survey") and choices.any(func(o: Dictionary):return o.id=="leave"),"all roles retain generic and withdrawal options")
  m.role_id=saved
 var invalid:=state.duplicate(true)
 invalid.expedition.active={"lead_id":"lead:missing","phase":"site","site_id":content.sites[0].id,"party_ids":state.party_ids,"supplies":4}
 check(not service.store._validate(invalid,entry.world).is_empty(),"unknown lead rejected")
 var malformed:=state.duplicate(true)
 malformed.expedition.outcomes[content.sites[0].id]={"approach":"record","sequence":999}
 check(not service.store._validate(malformed,entry.world).is_empty(),"missing consequence text/sequence rejected before UI")
 malformed=state.duplicate(true)
 malformed.expedition.log[0].tick=100
 check(not service.store._validate(malformed,entry.world).is_empty(),"corrupt event clock rejected")
 malformed=state.duplicate(true)
 malformed.game_clock.tick+=1
 check(not service.store._validate(malformed,entry.world).is_empty(),"campaign and structured log clocks must agree")
 print("GAME-84 failure safety: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
