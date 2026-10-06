extends SceneTree
## Seeded arrived-state fixtures exercise real production operations and disk
## transactions. This corpus is developer QA, not a simulated screenshot run.
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
 service.store.save_root=base.path_join("saves")
 service.library.library_root=base.path_join("library")
 service.library.save_root=service.store.save_root
 service.cache_root=base.path_join("cache")
 var entries:=service.library.discover()
 var cases: Array=[]
 for entry in entries:
  var matches: Array=[]
  for name in DirAccess.get_files_at(base.path_join("snapshots")):
   var raw:=WorldOriginLore.read_json(base.path_join("snapshots").path_join(name))
   if raw.world_ref.id==entry.id and raw.get("expedition",{}).get("revision")==1:matches.append(raw)
  check(not matches.is_empty(),"independent pristine campaign for "+entry.world.seed)
  if matches.is_empty():continue
  var original: Dictionary=matches[0]
  var slot: String=original.playthrough_id
  var loaded:=service.operate(entry,slot,"resume")
  check(loaded.ok,"source-matched corpus input")
  if not loaded.ok:continue
  var path:=service.store._slot_path(slot)
  var before:=FileAccess.get_file_as_bytes(path)
  var content: Dictionary=service.packet.content.duplicate(true)
  for target in content.sites:
   for provisions in [2,3]:
    for action in ["survey","record","leave"]:
     var fixture:=original.duplicate(true)
     var e: Dictionary=fixture.expedition
     e.leads=[]
     for s in content.sites:
      var id: String="lead:"+ExpeditionRecords.canonical([content.sha,int(fixture.origin.home_burg_id),s.id]).sha256_text()
      e.leads.append({"id":id,"site_id":s.id,"goal":"Record surviving worked stones","issuer":"local workers","status":"accepted" if s.id==target.id else "available"})
      e.knowledge[s.id]="visited" if s.id==target.id else "discovered"
     var lead: Dictionary=e.leads.filter(func(l: Dictionary):return l.site_id==target.id)[0]
     e.active={"lead_id":lead.id,"site_id":target.id,"phase":"site","party_ids":fixture.party_ids.duplicate(),"supplies":provisions}
     service._event(fixture,"depart","Departed for the seeded known-site test.",1)
     service._event(fixture,"travel","Arrived at the seeded known site.",1)
     var seeded:=service.store.save_existing(slot,fixture,entry.world)
     check(seeded.ok,"validated arrived-state fixture")
     var result:=service.operate(entry,slot,action,1,{"revision":fixture.expedition.revision})
     check(result.ok,action+" actual production transaction")
     if not result.ok:continue
     var state: Dictionary=result.state
     check(state.expedition.active.phase=="result","consequence handoff")
     check(state.expedition.active.supplies==provisions-(0 if action=="leave" else 1),"exact provision delta")
     check(state.game_clock.tick==fixture.game_clock.tick+(0 if action=="leave" else 2),"exact clock delta")
     check(state.expedition.knowledge[target.id]==("visited" if action=="leave" else "investigated"),"meaningful knowledge/withdrawal distinction")
     check(state.party_ids==original.party_ids,"same actual adventurers")
     if action=="survey":check(not state.expedition.outcomes[target.id].text.contains("second patch"),"known locations do not falsely become new rumours")
     check(service.store.load_save(slot,entry.world).state==state,"exact reload validation")
     cases.append({"world":entry.world.seed,"site":target.id,"kind":target.kind,"approach":action,"starting_provisions":provisions,"outcome":state.expedition.outcomes[target.id],"knowledge":state.expedition.knowledge[target.id],"provisions":state.expedition.active.supplies,"clock":state.game_clock.tick})
   print("Outcome corpus finished ",entry.world.seed,"; cases ",cases.size())
  var file:=FileAccess.open(path,FileAccess.WRITE)
  file.store_buffer(before);file.close()
  check(service.store.load_save(slot,entry.world).ok,"owned pristine campaign restored after corpus")
 check(cases.size()>=300,"at least 300 actual site-choice/outcome transactions")
 var output:=FileAccess.open("res://docs/implementation/game84/actual-outcome-corpus.json",FileAccess.WRITE)
 output.store_string(JSON.stringify({"developer_seeded_arrival_states":true,"cases":cases.size(),"checks":checks,"failures":failures,"outputs":cases},"  "))
 output.close()
 print("GAME-84 actual outcome corpus: ",cases.size()," sets, ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
