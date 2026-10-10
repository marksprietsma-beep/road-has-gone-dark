class_name ExpeditionService
extends PartyService
## Reuses GAME-81 lock, exact-byte journal, guarded world lifecycle and reload.
var packet := {}
var packet_digest := ""
var cache_root := "user://expedition-content"
func prepare(entry: Dictionary) -> Dictionary:
 var w: GameWorldTemplate = entry.world
 var home: int = int(entry.get("home",-1))
 if home<0: return fail("Missing hometown")
 var cache := ProjectSettings.globalize_path(cache_root).path_join(w.source_sha256)
 var key := str(home)
 var path := cache.path_join(key+".json")
 if FileAccess.file_exists(path):
  packet = WorldOriginLore.read_json(path)
  if FileAccess.get_sha256(path)!=FileAccess.get_file_as_string(path+".sha"): return fail("Local content cache failed validation; campaign preserved.")
 else:
  var ready := library.helper_status()
  if not ready.ok: return ready
  if DirAccess.make_dir_recursive_absolute(cache)!=OK: return fail("Cannot prepare local content cache")
  var temp := cache.path_join("job-"+Crypto.new().generate_random_bytes(12).hex_encode())
  if DirAccess.make_dir_absolute(temp)!=OK: return fail("Cannot prepare local generation")
  var source := ProjectSettings.globalize_path(entry.path)
  if str(entry.path).begins_with("res://"):
   source = temp.path_join("world.json")
   if not _copy_input(entry.path,source): return fail("Cannot read packed canonical world")
  var output := temp.path_join("result.json")
  var helper := library.helper_location()
  var log: Array = []
  var code := OS.execute(helper.path_join("node.exe" if OS.get_name()=="Windows" else "node"),[helper.path_join("tools/expedition/entry.mjs"),"--world",source,"--home",str(home),"--cache",cache,"--output",output],log,true,false)
  packet = WorldOriginLore.read_json(output)
  for f in [output,temp.path_join("world.json")]:
   if FileAccess.file_exists(f): DirAccess.remove_absolute(f)
  DirAccess.remove_absolute(temp)
  if code!=0 or not packet.get("ok",false): return fail("Local region generation failed; campaign preserved. "+str(log).left(200))
  var file := FileAccess.open(path,FileAccess.WRITE)
  if file==null: return fail("Cannot cache local region")
  file.store_string(JSON.stringify(packet,"",false,true))
  file.close()
  file = FileAccess.open(path+".sha",FileAccess.WRITE)
  if file==null: return fail("Cannot verify local region cache")
  file.store_string(FileAccess.get_sha256(path))
  file.close()
 packet_digest=FileAccess.get_sha256(path)
 if not packet.get("content") is Dictionary or not packet.get("leads") is Array or not packet.get("svg") is String: return fail("Malformed local content cache; campaign preserved.")
 var c: Dictionary = packet.content
 if not c.get("sites") is Array or c.sites.size()!=8 or not c.get("sha") is String or c.sha.length()!=64 or not c.get("home_position") is Array or c.home_position.size()!=2: return fail("Malformed local site set; campaign preserved.")
 var cell: int = int(w.get_record("burg",home).get("cell",-1))
 for i in c.sites.size():
  var s: Variant = c.sites[i]
  if not s is Dictionary or s.get("id")!=ExpeditionRecords.site_id(w,cell,i) or not s.get("name") is String or not s.get("description") is String or not s.get("history_description") is String or not s.get("position") is Array or s.position.size()!=2 or not s.get("facts") is Dictionary or not s.facts.get("conditions") is Array: return fail("Invalid local site record; campaign preserved.")
  for n in s.position:
   if not (n is int or n is float) or n<0 or n>1000: return fail("Invalid local position; campaign preserved.")
 if packet.get("content",{}).get("world_id")!=w.world_id or packet.content.get("home_id")!=home or packet.content.get("version")!=ExpeditionRecords.VERSION: return fail("Mismatched local content")
 return {"ok":true}
func _operate_locked(entry: Dictionary, slot: String, operation: String, _member: int, changes: Dictionary) -> Dictionary:
 var world: GameWorldTemplate = entry.world
 var loaded := recover(slot,world)
 if not loaded.ok: return loaded
 var state: Dictionary = loaded.state
 if state.get("party",{}).get("status")!="ready": return fail("Finish party setup first")
 var input := entry.duplicate()
 input.home = state.origin.home_burg_id
 var prepared := prepare(input)
 if not prepared.ok: return prepared
 var content: Dictionary = packet.content
 if state.has("expedition") and (state.expedition.content_sha!=content.sha or state.expedition.packet_sha!=packet_digest): return fail("Campaign local content version does not match")
 if operation=="resume" and state.has("expedition"): return loaded
 var candidate := state.duplicate(true)
 if not candidate.has("expedition"):
  if operation!="resume": return fail("Begin from the hometown first")
  var knowledge := {}
  for s in content.sites: knowledge[s.id]="unknown"
  for l in packet.leads: knowledge[l.site_id]=l.knowledge
  candidate.expedition={"version":ExpeditionRecords.VERSION,"content_sha":content.sha,"packet_sha":packet_digest,"cell_id":content.cell_id,"knowledge":knowledge,"leads":packet.leads.duplicate(true),"active":{},"revision":0,"log":[],"outcomes":{}}
  if candidate.game_clock.get("time_unit")!="unassigned" or candidate.game_clock.get("tick")!=0: return fail("This campaign uses another clock. It was preserved without conversion.")
  candidate.game_clock={"tick":0,"time_unit":"expedition-turn"}
  _event(candidate,"begin","Local accounts are ready. Your party gathers at home.",0)
  return commit(slot,candidate,world)
 var e: Dictionary = candidate.expedition
 if changes.get("revision",-1)!=e.revision: return fail("This action is already recorded or the campaign changed. Resume to continue.")
 var lead_id := str(changes.get("lead",""))
 var matches: Array = e.leads.filter(func(l: Dictionary): return l.id==lead_id)
 var lead: Dictionary = matches[0] if not matches.is_empty() else {}
 var active: Dictionary = e.active
 if operation=="accept":
  if not active.is_empty() or lead.is_empty() or not lead.status in ["available","withdrawn"]: return fail("Lead cannot be accepted now")
  lead.status="accepted"
  _event(candidate,"accept","Accepted a local account for investigation.",0)
 elif operation=="depart":
  if not active.is_empty() or lead.is_empty() or lead.status!="accepted": return fail("Choose an accepted lead first")
  e.active={"lead_id":lead.id,"phase":"map","site_id":"","party_ids":candidate.party_ids.duplicate(),"supplies":4}
  _event(candidate,"depart","All three adventurers depart together.",1)
 elif operation=="return":
  if active.is_empty(): return fail("Party is already home")
  var l: Dictionary = e.leads.filter(func(x: Dictionary): return x.id==active.lead_id)[0]
  l.status="completed" if e.outcomes.has(l.site_id) and e.outcomes[l.site_id].approach!="leave" else "withdrawn"
  e.active={}
  _event(candidate,"return","Returned home. Local knowledge and the expedition record are preserved.",1)
 else:
  if active.is_empty(): return fail("No active expedition")
  lead=e.leads.filter(func(x: Dictionary): return x.id==active.lead_id)[0]
  var site: Dictionary = content.sites.filter(func(s: Dictionary): return s.id==lead.site_id)[0]
  if operation=="scout":
   if active.phase!="map" or e.knowledge[site.id]!="rumoured" or active.supplies<1: return fail("This rumour cannot be scouted now")
   e.knowledge[site.id]="discovered"
   active.supplies-=1
   _event(candidate,"scout","Located "+site.name+". Its position is now recorded on your map.",2)
  elif operation=="travel":
   if active.phase!="map" or not e.knowledge[site.id] in ["discovered","visited","investigated"] or active.supplies<1: return fail("Travel requires a known location and provisions")
   active.phase="site"
   active.site_id=site.id
   active.supplies-=1
   if e.knowledge[site.id]!="investigated": e.knowledge[site.id]="visited"
   _event(candidate,"travel","Arrived at "+site.name+". The local journey is recorded.",1)
  elif operation in ["survey","record","secure","study","craft","leave"]:
   if active.phase!="site" or e.outcomes.has(site.id) and e.outcomes[site.id].approach!="leave": return fail("This site's choice is already recorded")
   var options := choices(candidate,site)
   if not options.any(func(o: Dictionary): return o.id==operation): return fail("This approach is not available to your party")
   if operation!="leave" and active.supplies<1: return fail("Return home to prepare another expedition")
   var texts := {"survey":"The perimeter is recorded. Your notes now distinguish the surrounding work.","record":"You compare the remaining work with the local account and record its former use: "+str(site.facts.purpose).replace("-"," ")+".","secure":"You mark the unstable sections to avoid. The approach is recorded without forcing entry.","study":"Your adept copies the surviving marks. Their arrangement can now be compared with other local work.","craft":"A former craft worker records the joins and repairs, separating later work from the original structure.","leave":"You leave the remains undisturbed. The concern stays unresolved."}
   e.outcomes[site.id]={"approach":operation,"sequence":e.revision+1,"text":texts[operation]}
   if operation!="leave":
    e.knowledge[site.id]="investigated"
    active.supplies-=1
    if not candidate.world_deltas.has(site.id): candidate.world_deltas[site.id]={}
    candidate.world_deltas[site.id].merge({"investigated":true,"approach":operation},true)
   if operation=="survey":
    var secondary: Dictionary = content.sites[3]
    if e.knowledge[secondary.id]=="unknown":
     e.outcomes[site.id].text="The perimeter is recorded. You note a second patch of old work for later investigation."
     e.knowledge[secondary.id]="rumoured"
     e.leads.append({"id":"lead:"+ExpeditionRecords.canonical([content.sha,int(candidate.origin.home_burg_id),secondary.id]).sha256_text(),"site_id":secondary.id,"status":"available","goal":"Follow up the newly recorded account","issuer":"your party","origin":"generated-local"})
   active.phase="result"
   _event(candidate,operation,e.outcomes[site.id].text,0 if operation=="leave" else 2)
  else: return fail("Unknown expedition action")
 return commit(slot,candidate,world)
func _event(candidate: Dictionary, type: String, text: String, cost: int) -> void:
 var e: Dictionary = candidate.expedition
 e.revision+=1
 candidate.game_clock.tick+=cost
 e.log.append({"sequence":e.revision,"type":type,"text":text,"tick":candidate.game_clock.tick})
static func choices(state: Dictionary, site: Dictionary) -> Array:
 var options: Array = [{"id":"survey","label":"Survey the perimeter","effect":"Record the site and look for further leads"},{"id":"record","label":"Examine the surviving work","effect":"Learn its former use"}]
 var special := {}
 for m in state.party.members:
  var marked: bool = site.get("has_marks",str(site.get("facts",{}).get("conditions",[])).contains("walls-chalked"))
  var damaged: bool = site.get("unstable",str(site.get("facts",{}).get("conditions",[])).contains("walls-cracked"))
  if m.role_id=="adept" and marked: special={"id":"study","label":m.name+": study the markings","effect":"Record the surviving marks"}
  elif m.role_id=="vanguard" and damaged and special.is_empty(): special={"id":"secure","label":m.name+": secure the approach","effect":"Record sections to avoid"}
  elif m.role_id=="expert" and special.is_empty(): special={"id":"craft","label":m.name+": examine the construction","effect":"Distinguish original work from repairs"}
  elif m.role_id=="scout" and special.is_empty(): options[0].label=m.name+": survey quietly"
  var occupation := str(m.generated_facts.get("occupation_id",""))
  if special.is_empty() and ("mason" in occupation or "wood" in occupation or "carpenter" in occupation): special={"id":"craft","label":m.name+": examine the workmanship","effect":"Recognise joins and repairs"}
 if not special.is_empty(): options.append(special)
 options.append({"id":"leave","label":"Leave it undisturbed","effect":"Withdraw with the lead unresolved"})
 return options
