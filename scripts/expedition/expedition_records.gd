class_name ExpeditionRecords
extends RefCounted
const VERSION := "trhgd-expedition-v1"
static func canonical(v: Variant) -> String:
 if v is Dictionary:
  var keys: Array = v.keys()
  keys.sort()
  var pieces: Array[String] = []
  for k in keys: pieces.append(JSON.stringify(k) + ":" + canonical(v[k]))
  return "{" + ",".join(pieces) + "}"
 if v is Array:
  var pieces: Array[String] = []
  for item in v: pieces.append(canonical(item))
  return "[" + ",".join(pieces) + "]"
 return JSON.stringify(v)
static func site_id(world: GameWorldTemplate, cell: int, index: int) -> String:
 return "site:" + canonical([world.world_id,cell,VERSION,index]).sha256_text()
static func validate(state: Dictionary, world: GameWorldTemplate) -> String:
 if not state.has("expedition"): return ""
 var e: Variant = state.expedition
 if not e is Dictionary or e.size()!=10 or e.get("version") != VERSION or not e.get("content_sha") is String or str(e.content_sha).length()!=64 or not e.get("packet_sha") is String or str(e.packet_sha).length()!=64: return "Invalid expedition version/pin"
 if state.get("party",{}).get("status")!="ready": return "Expedition requires the saved ready party"
 var cell := int(world.get_record("burg",int(state.origin.home_burg_id)).cell)
 if e.get("cell_id")!=cell or not e.get("knowledge") is Dictionary or e.knowledge.size()!=8: return "Invalid local-cell knowledge"
 var allowed: Array[String] = []
 for i in 8: allowed.append(site_id(world,cell,i))
 for id in e.knowledge:
  if not id in allowed or not e.knowledge[id] in ["unknown","rumoured","discovered","visited","investigated"]: return "Unknown site/knowledge state"
 if not e.get("leads") is Array or e.leads.size()<3 or e.leads.size()>8: return "Invalid local leads"
 var seen: Array[String] = []
 for l in e.leads:
  if not l is Dictionary or not l.get("site_id") in allowed or not l.get("status") in ["available","accepted","completed","withdrawn"]: return "Invalid lead reference/state"
  var expected := "lead:" + canonical([e.content_sha,int(state.origin.home_burg_id),l.site_id]).sha256_text()
  if l.get("id")!=expected or l.id in seen or not l.get("goal") is String or not l.get("issuer") is String: return "Invalid lead identity"
  seen.append(l.id)
  if e.knowledge[l.site_id]=="unknown": return "Lead leaks unknown site"
 if not e.get("active") is Dictionary or not e.get("log") is Array or not e.get("outcomes") is Dictionary or not e.get("revision") is float and not e.get("revision") is int: return "Invalid expedition state"
 if e.revision<0 or int(e.revision)!=e.revision or e.log.size()!=e.revision: return "Invalid transition revision/log"
 var clock:=0
 var costs: Dictionary={"begin":0,"accept":0,"depart":1,"scout":2,"travel":1,"survey":2,"record":2,"secure":2,"study":2,"craft":2,"leave":0,"return":1}
 for i in e.log.size():
  var event: Variant = e.log[i]
  if not event is Dictionary or event.get("sequence")!=i+1 or not event.get("type") in ["begin","accept","depart","scout","travel","survey","record","secure","study","craft","leave","return"] or not event.get("text") is String or event.text.length()>450 or event.size()!=4: return "Invalid expedition event"
  clock+=int(costs[event.type])
  if event.get("tick")!=clock: return "Invalid expedition event clock"
 if not e.active.is_empty():
  if e.active.size()!=5 or not e.active.get("lead_id") in seen or not e.active.get("phase") in ["map","site","result"] or e.active.get("party_ids")!=state.party_ids or not (e.active.get("supplies") is float or e.active.get("supplies") is int) or int(e.active.get("supplies",-1))!=e.active.get("supplies") or not int(e.active.get("supplies",-1)) in [0,1,2,3,4]: return "Invalid active expedition"
  var lead: Dictionary = e.leads.filter(func(l: Dictionary): return l.id==e.active.lead_id)[0]
  if lead.status!="accepted": return "Active expedition requires accepted lead"
  if e.active.phase!="map" and (e.active.get("site_id")!=lead.site_id or not e.knowledge[lead.site_id] in ["visited","investigated"]): return "Invalid site arrival"
 for id in e.outcomes:
  var result: Variant=e.outcomes[id]
  if not id in allowed or not result is Dictionary or result.size()!=3 or not result.get("approach") in ["survey","record","secure","study","craft","leave"] or not result.get("text") is String or result.text.length()>450 or not (result.get("sequence") is int or result.get("sequence") is float) or result.sequence!=int(result.sequence) or result.sequence<1 or result.sequence>e.revision: return "Invalid site consequence"
  if e.log[int(result.sequence)-1].type!=result.approach or e.log[int(result.sequence)-1].text!=result.text: return "Consequence does not match its recorded event"
  if result.approach!="leave" and e.knowledge[id]!="investigated": return "Consequence requires investigation knowledge"
 if not e.active.is_empty() and e.active.phase=="result" and not e.outcomes.has(e.active.site_id): return "Missing arrived-site consequence"
 if state.game_clock.get("time_unit")!="expedition-turn" or not state.game_clock.get("tick") is float and not state.game_clock.get("tick") is int or state.game_clock.tick<0 or state.game_clock.tick!=int(state.game_clock.tick) or state.game_clock.tick!=clock: return "Invalid expedition clock"
 return ""
static func projection(content: Dictionary, e: Dictionary) -> Dictionary:
 var sites: Array = []
 for s in content.sites:
  if e.knowledge[s.id] in ["discovered","visited","investigated"]:
   sites.append({"id":s.id,"name":s.name,"kind":s.kind,"position":s.position,"description":s.history_description if e.knowledge[s.id]=="investigated" else s.description,"knowledge":e.knowledge[s.id],"has_marks":s.facts.conditions.has("walls-chalked"),"unstable":s.facts.conditions.has("walls-cracked")})
 var leads: Array = []
 for l in e.leads:
  var s: Dictionary = content.sites.filter(func(x: Dictionary): return x.id==l.site_id)[0]
  var known: bool = e.knowledge[s.id]!="rumoured"
  leads.append({"id":l.id,"title":s.name if known else "Rumour of old stonework","goal":l.goal,"issuer":l.issuer,"status":l.status,"knowledge":e.knowledge[s.id],"site":s.id if known else "","clue":s.description if known else "Someone remembers old work somewhere outside the town. Its exact location is not known."})
 return {"sites":sites,"leads":leads,"home_position":content.home_position}
