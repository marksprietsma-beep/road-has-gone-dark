extends Node
class PackageService extends PartyService:
 var jobs: Array[String] = []
 func _copy_input(source: String, target: String) -> bool:
  var directory := target.get_base_dir()
  if directory.get_file() == "peoples": directory = directory.get_base_dir()
  if not jobs.has(directory): jobs.append(directory)
  return super._copy_input(source,target)
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(why)
func _ready() -> void: call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME81_DISTRIBUTION_TEST_ROOT")
 DirAccess.make_dir_recursive_absolute(base)
 var service := PackageService.new()
 service.library.library_root=base.path_join("library")
 service.store.save_root=base.path_join("saves")
 service.library.save_root=service.store.save_root
 check(OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"bundled helper without source override")
 check(service.library.helper_status().ok,"all three production runtime pins found")
 for entry in service.library.discover():
  var people := WorldPeoples.new()
  check(people.load_world(entry.world),people.error)
 # Presets are inside the exported PCK, not loose files. Exercise the same
 # production helper boundary as the editor, including later edits/readiness.
 for entry in service.library.discover():
  var profiles := OriginProfiles.new()
  check(profiles.load_world(entry.world), "packed preset profiles")
  if profiles.projection.is_empty(): continue
  var home: Dictionary = profiles.projection.hometowns.values()[0]
  var created := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
  created.state.origin_profiles = profiles.descriptor
  var lore := WorldOriginLore.new()
  check(lore.load_world(entry.world,entry.world.enrichment_directory), "packed preset origin lore")
  created.state.origin_enrichment = lore.descriptor
  var slot: String = created.state.playthrough_id
  check(service.store.save_new(slot,created.state,entry.world).ok, "persist preset origin")
  var party := service.operate(entry,slot,"generate")
  check(party.ok and party.get("state",{}).get("party",{}).get("members",[]).size()==3,"packed preset generates three members: " + str(party.get("error","")))
  if not party.ok: continue
  var edited := service.operate(entry,slot,"edit",1,{"name":"Preset Name","regenerate":true})
  check(edited.ok and edited.state.party.members[0].name=="Preset Name" and edited.state.party.members[0].background_variant==1,"packed preset edit/reroll")
  var ready := service.operate(entry,slot,"ready")
  var loaded := service.store.load_save(slot,entry.world)
  check(ready.ok and loaded.ok and loaded.state==ready.state and loaded.state.onboarding_stage=="party_ready","packed preset ready/reload")
 check(service.jobs.size()==6 and service.jobs.all(func(path: String): return not DirAccess.dir_exists_absolute(path)),"owned packed-input jobs cleaned up")
 var stage := service.library.create_staging()
 check(stage.ok,"fresh distribution world staging")
 var generated := service.library.run_generator(stage.directory,"game81-complete-package-world")
 check(generated.ok,str(generated.get("error")))
 if generated.ok:
  var imported := service.library.import_generated(stage.directory)
  check(imported.ok,str(imported.get("error")))
  if imported.ok:
   var entry: Dictionary=imported.entry
   var reader := OriginProfiles.new()
   check(reader.load_world(entry.world),reader.error)
   var h: Dictionary=reader.projection.hometowns.values()[0]
   var original := service.store.create_playthrough(entry.world,int(h.state_id),int(h.burg_id),int(h.province_id))
   original.state.origin_profiles=reader.descriptor
   var old := WorldOriginLore.new()
   check(old.load_world(entry.world,entry.world.enrichment_directory),old.error)
   original.state.origin_enrichment=old.descriptor
   var slot: String=original.state.playthrough_id
   check(service.store.save_new(slot,original.state,entry.world).ok,"one persisted origin")
   PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root}
   var ui=load("res://scenes/ui/party_creation.tscn").instantiate()
   get_tree().root.add_child(ui)
   var deadline := Time.get_ticks_msec()+90000
   while ui.thread!=null and Time.get_ticks_msec()<deadline: await get_tree().process_frame
   check(not ui.state.is_empty() and ui.state.party.members.size()==3,"exported production UI/helper prepares three members")
   if not ui.state.is_empty():
    var initial: Dictionary=ui.state.duplicate(true)
    ui.name_edit.text="Offline Name"
    ui._save_changes(true)
    while ui.thread!=null and Time.get_ticks_msec()<deadline: await get_tree().process_frame
    check(ui.state.party.members[0].name=="Offline Name" and ui.state.party.members[0].background_variant==1,"exported UI edit and reroll saved")
    check(ui.state.party.members[1]==initial.party.members[1],"sibling immutable")
    ui._finish()
    while ui.thread!=null and Time.get_ticks_msec()<deadline: await get_tree().process_frame
    check(ui.ready_view and ui.state.onboarding_stage=="party_ready","exported UI ready only after persistence")
    var reloaded := service.store.load_save(slot,entry.world)
    check(reloaded.ok and reloaded.state==ui.state,"save/reload exact across bundled boundary")
    check(DirAccess.get_files_at(service.store.save_root).size()==3,"same campaign, no duplicate")
   ui.queue_free()
   await get_tree().process_frame
 var proof := FileAccess.open(base.path_join("native-result.json"),FileAccess.WRITE)
 proof.store_string(JSON.stringify({"checks":checks,"failures":failures,"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty()})+"\n")
 proof.close()
 print("GAME-81 complete native distribution: ",checks," checks, ",failures," failures")
 get_tree().quit(1 if failures else 0)
