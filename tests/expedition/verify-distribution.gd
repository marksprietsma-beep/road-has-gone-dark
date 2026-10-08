extends Node
var checks:=0
var failures:=0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(why)
func _ready() -> void: call_deferred("run")
func run() -> void:
 var base:=OS.get_environment("GAME84_DISTRIBUTION_TEST_ROOT")
 DirAccess.make_dir_recursive_absolute(base)
 var service:=ExpeditionService.new()
 service.library.library_root=base.path_join("library")
 service.store.save_root=base.path_join("saves")
 service.library.save_root=service.store.save_root
 service.cache_root=base.path_join("cache")
 check(OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"no source helper override")
 check(service.library.helper_status().ok,"four exact runtime pins, one bundled helper")
 var stage:=service.library.create_staging()
 check(stage.ok,"native fresh staging")
 var generated:=service.library.run_generator(stage.directory,"game84-native-package")
 check(generated.ok,str(generated.get("error")))
 if generated.ok:
  var imported:=service.library.import_generated(stage.directory)
  check(imported.ok,str(imported.get("error")))
 var entries:=service.library.discover()
 check(entries.size()==3,"two packed presets and one fresh native world")
 var timings: Array=[]
 for entry in entries:
  var profiles:=OriginProfiles.new()
  check(profiles.load_world(entry.world),"native source profiles")
  if profiles.projection.is_empty(): continue
  var home: Dictionary=profiles.projection.hometowns.values()[0]
  var created:=service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
  check(created.ok,"native origin")
  created.state.origin_profiles=profiles.descriptor
  var old:=WorldOriginLore.new()
  check(old.load_world(entry.world,entry.world.enrichment_directory),"native original lore")
  created.state.origin_enrichment=old.descriptor
  var slot: String=created.state.playthrough_id
  check(service.store.save_new(slot,created.state,entry.world).ok,"native persisted origin")
  var party:=PartyService.new()
  party.store=service.store;party.library=service.library
  var made:=party.operate(entry,slot,"generate")
  check(made.ok,"native actual three adventurers")
  var ready:=party.operate(entry,slot,"ready")
  check(ready.ok,"native ready handoff")
  PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  var ui=load("res://scenes/gameplay/expedition.tscn").instantiate()
  get_tree().root.add_child(ui)
  var deadline:=Time.get_ticks_msec()+180000
  while ui.thread!=null and Time.get_ticks_msec()<deadline: await get_tree().process_frame
  check(not ui.state.is_empty() and ui.message.is_empty(),"native production UI initializes: "+ui.message)
  if ui.state.is_empty():ui.queue_free();continue
  check(ui.map.texture!=null,"native actual GAME-62 SVG loads")
  check(ui.public_view.sites.size()==2,"hidden native sites have no marker")
  var lead: String=ui.state.expedition.leads[1].id
  var start:=Time.get_ticks_msec()
  for action in ["accept","depart","scout","travel","survey","return"]:
   ui.start(action,lead if action in ["accept","depart"] else "")
   while ui.thread!=null and Time.get_ticks_msec()<deadline: await get_tree().process_frame
   check(ui.message.is_empty() and ui.thread==null,"native UI "+action+": "+ui.message)
  check(ui.state.expedition.active.is_empty() and ui.state.expedition.leads[1].status=="completed","native complete hometown return")
  var loaded:=service.operate(entry,slot,"resume")
  check(loaded.ok and loaded.state==ui.state,"native reload retains exact outcomes/party/clock")
  var rules := RulesService.new()
  rules.store=service.store;rules.library=service.library
  var preview := RulesRecords.preview_preparation(loaded.state)
  check(preview.ok,"native bundled rules pack and original party migration")
  if preview.ok:
   var prepared := rules.commit_preview(entry,slot,preview)
   check(prepared.ok,"native atomic mechanical preparation")
   if prepared.ok:
    check(prepared.state.expedition==loaded.state.expedition and prepared.state.party==loaded.state.party,"native mechanics preserve hometown expedition and biography")
    var record: Dictionary=prepared.state.mechanics.records.values()[0]
    var derived := RulesCharacter.new(RulesRecords.registry()).derive_character(record)
    check(derived.ok and derived.snapshot.is_read_only(),"native combat-ready immutable snapshot")
    check(service.store.load_save(slot,entry.world).ok,"native prepared save reload")
  check(not service.library.delete_world(entry).ok,"native used world remains protected")
  timings.append({"world":entry.world.seed,"six_transitions_ms":Time.get_ticks_msec()-start})
  ui.queue_free()
  await get_tree().process_frame
 var proof:=FileAccess.open(base.path_join("native-result.json"),FileAccess.WRITE)
 proof.store_string(JSON.stringify({"checks":checks,"failures":failures,"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"worlds":entries.size(),"timings":timings})+"\n")
 proof.close()
 print("GAME-84 complete native distribution: ",checks," checks, ",failures," failures")
 get_tree().quit(1 if failures else 0)
