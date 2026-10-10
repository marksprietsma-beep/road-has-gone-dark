extends SceneTree
var checks:=0
var failures:=0
var service:=ExpeditionService.new()
var entries: Array=[]
var base: String
var timings: Array=[]
func check(ok: bool, why: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(why)
func _initialize() -> void: call_deferred("run")
func act(entry: Dictionary, slot: String, state: Dictionary, op: String, lead: String="") -> Dictionary:
 var started:=Time.get_ticks_msec()
 var result:=service.operate(entry,slot,op,1,{"revision":state.expedition.revision,"lead":lead})
 timings.append({"world":entry.world.seed,"operation":op,"milliseconds":Time.get_ticks_msec()-started})
 check(result.ok,op+": "+str(result.get("error","")))
 if not result.ok: return state
 check(service.store.load_save(slot,entry.world).state==result.state,"immediate validated persistence "+op)
 return result.state
func run() -> void:
 base=OS.get_environment("GAME84_TEST_ROOT")
 service.cache_root=base.path_join("cache")
 service.library.library_root=base.path_join("library")
 service.store.save_root=base.path_join("saves")
 service.library.save_root=service.store.save_root
 var phase:=OS.get_environment("GAME84_PHASE")
 if phase=="create":
  if DirAccess.dir_exists_absolute(base.path_join("generated")):
   for name in DirAccess.get_directories_at(base.path_join("generated")):
    if service.library.discover().any(func(e: Dictionary): return e.world.seed==name): continue
    var stage:=service.library.create_staging()
    check(stage.ok,"owned fresh-world staging")
    check(DirAccess.copy_absolute(base.path_join("generated").path_join(name).path_join("world.json"),stage.directory.path_join("world.json"))==OK,"fresh bytes imported")
    var imported:=service.library.import_generated(stage.directory)
    check(imported.ok,str(imported.get("error")))
 entries=service.library.discover()
 check(entries.size()>=2,"two presets available")
 if phase=="create":
  for entry in entries:
   var w: GameWorldTemplate=entry.world
   var h: Dictionary={}
   var profiles:=OriginProfiles.new()
   check(profiles.load_world(w),profiles.error)
   h=profiles.projection.hometowns.values()[0]
   var created:=service.store.create_playthrough(w,int(h.state_id),int(h.burg_id),int(h.province_id))
   check(created.ok,"canonical origin")
   var state: Dictionary=created.state
   var slot: String=state.playthrough_id
   check(service.store.save_new(slot,state,w).ok,"one campaign")
   var party:=PartyService.new()
   party.store=service.store
   party.library=service.library
   var result:=party.operate(entry,slot,"generate")
   check(result.ok,"actual party generation")
   result=party.operate(entry,slot,"ready")
   check(result.ok,"actual party ready")
   result=service.operate(entry,slot,"resume")
   check(result.ok,"missing-only legacy upgrade: "+str(result.get("error")))
   if not result.ok: continue
   state=result.state
   var content: Dictionary=service.packet.content.duplicate(true)
   var e: Dictionary=state.expedition
   var projection:=ExpeditionRecords.projection(content,e)
   check(projection.sites.size()==2,"only two known markers")
   var rumor: Dictionary=e.leads[1]
   var rumoured: Dictionary=content.sites[1]
   check(not JSON.stringify(projection).contains(rumoured.id) and not JSON.stringify(projection).contains(rumoured.name),"undiscovered site identity/name absent from UI")
   check(not JSON.stringify(projection).contains('repair tally'),"no secret truth in public projection")
   var progress:=FileAccess.open(base.path_join(slot+".entry"),FileAccess.WRITE)
   progress.store_string(entry.id)
   progress.close()
   snapshot(slot,state)
   state=act(entry,slot,state,"accept",rumor.id)
   snapshot(slot,state)
   state=act(entry,slot,state,"depart",rumor.id)
   state=act(entry,slot,state,"scout")
   check(state.expedition.knowledge[rumoured.id]=="discovered","rumour discovery persisted")
   snapshot(slot,state)
   state=act(entry,slot,state,"travel")
   snapshot(slot,state)
   var opts:=ExpeditionService.choices(state,rumoured)
   check(opts.size()>=3 and opts.size()<=4 and opts.any(func(o: Dictionary):return o.id=="leave"),"viable generic/no-role withdrawal")
   var before: Dictionary=state.duplicate(true)
   state=act(entry,slot,state,"survey")
   check(state.expedition.leads.size()==4 and state.expedition.knowledge[content.sites[3].id]=="rumoured","real secondary rumour consequence")
   check(state.world_deltas.has(rumoured.id),"mutable consequence separate from world")
   var repeated:=service.operate(entry,slot,"survey",1,{"revision":before.expedition.revision})
   check(not repeated.ok and service.store.load_save(slot,w).state==state,"double click does not double time/provisions/log")
   snapshot(slot,state)
   state=act(entry,slot,state,"return")
   check(state.expedition.leads[1].status=="completed" and state.expedition.active.is_empty(),"completed lead and home location")
   snapshot(slot,state)
   var first_outcome: Dictionary=state.expedition.outcomes.duplicate(true)
   state=act(entry,slot,state,"accept",state.expedition.leads[0].id)
   state=act(entry,slot,state,"depart",state.expedition.leads[0].id)
   state=act(entry,slot,state,"travel")
   state=act(entry,slot,state,"record")
   state=act(entry,slot,state,"return")
   check(state.expedition.outcomes[rumoured.id]==first_outcome[rumoured.id],"second expedition preserves first consequence")
   check(service.packet.content==content,"objective content unchanged by campaign actions")
   var second: Dictionary=service.store.create_playthrough(w,int(h.state_id),int(h.burg_id),int(h.province_id)).state
   var second_slot: String=second.playthrough_id
   check(service.store.save_new(second_slot,second,w).ok,"independent campaign origin")
   result=party.operate(entry,second_slot,"generate")
   result=party.operate(entry,second_slot,"ready")
   result=service.operate(entry,second_slot,"resume")
   check(result.ok and service.packet.content==content,"two campaigns share same objective content")
   check(result.state.expedition.knowledge[rumoured.id]=="rumoured" and result.state.world_deltas.is_empty(),"independent knowledge and world deltas")
   var invalid:=state.duplicate(true)
   invalid.expedition.knowledge["site:wrong-world"]="discovered"
   check(not service.store._validate(invalid,w).is_empty(),"wrong-world site rejected")
   check(not service.library.delete_world(entry).ok,"referenced world deletion stays blocked")
 else:
  for name in DirAccess.get_files_at(base.path_join("snapshots")):
   var state:=WorldOriginLore.read_json(base.path_join("snapshots").path_join(name))
   var match: Array=entries.filter(func(e: Dictionary): return e.id==state.world_ref.id)
   check(match.size()==1,"exact world on restart")
   if match.size()!=1: continue
   var entry: Dictionary=match[0]
   var path:=service.store._slot_path(state.playthrough_id)
   var file:=FileAccess.open(path,FileAccess.WRITE)
   file.store_string(JSON.stringify(state,"  "))
   file.close()
   var result:=service.operate(entry,state.playthrough_id,"resume")
   check(result.ok and result.state==state,"restart at "+name+" preserves exact phase/knowledge/outcomes")
 var measured:=FileAccess.open("res://docs/implementation/game84/transition-timings-"+phase+".json",FileAccess.WRITE)
 measured.store_string(JSON.stringify(timings,"  "))
 measured.close()
 print("GAME-84 lifecycle ",phase,": ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
func snapshot(slot: String, state: Dictionary) -> void:
 var dir:=base.path_join("snapshots")
 DirAccess.make_dir_recursive_absolute(dir)
 var file:=FileAccess.open(dir.path_join(slot+"-%02d.json"%int(state.expedition.revision)),FileAccess.WRITE)
 file.store_string(JSON.stringify(state))
 file.close()
