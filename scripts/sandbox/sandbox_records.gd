class_name SandboxRecords
extends RefCounted
## Optional namespace; old expedition/adventure schemas and saves stay intact.
static func create(base: Dictionary,state: Dictionary) -> Dictionary:
 var knowledge := {};var characters := {}
 for i in base.sites.size():knowledge[base.sites[i].id]="rumoured" if i==1 else "discovered"
 for id in state.party_ids:characters[id]={"xp":0,"history":[]}
 return {"version":SandboxGenerator.VERSION,"revision":1,"base":base.duplicate(true),"base_sha":RulesJson.digest(base),"knowledge":knowledge,"encounters":{},"results":{},"active":{},"characters":characters}
static func site(s: Dictionary,id: String) -> Dictionary:
 for row in s.base.sites:
  if row.id==id:return row
 return {}
static func battle(state: Dictionary) -> Dictionary:
 var s: Dictionary=state.get("sandbox",{});var id: String=s.get("active",{}).get("site_id","")
 return s.get("encounters",{}).get(id,{})
static func validate(state: Dictionary,world: GameWorldTemplate) -> String:
 if not state.has("sandbox"):return ""
 var s: Variant=RulesJson.normalize(state.sandbox)
 if not s is Dictionary or s.size()!=9 or s.get("version")!=SandboxGenerator.VERSION or not RulesJson.integer(s.get("revision"),1,RulesJson.LIMIT) or not s.get("base") is Dictionary or not s.get("base_sha") is String or not s.get("knowledge") is Dictionary or not s.get("encounters") is Dictionary or not s.get("results") is Dictionary or not s.get("active") is Dictionary or not s.get("characters") is Dictionary:return "sandbox.schema: Invalid record"
 if not state.has("expedition") or not state.has("mechanics") or state.party.status!="ready":return "sandbox.context: Existing party/expedition/rules required"
 var base: Dictionary=s.base
 if not base.has_all(["version","seed","world_ref","home_id","cell_id","content_sha","home_position","sites"]) or base.size()!=8 or base.version!=s.version or RulesJson.digest(base)!=s.base_sha or base.world_ref!=RulesJson.normalize(state.world_ref) or base.home_id!=state.origin.home_burg_id or base.cell_id!=world.get_record("burg",int(base.home_id)).cell or base.content_sha!=state.expedition.content_sha or not base.sites is Array or base.sites.size()!=4 or not base.home_position is Array or base.home_position.size()!=2:return "sandbox.pin: Generated content or geographic anchor mismatch"
 var seed := RulesJson.digest([SandboxGenerator.VERSION,FileAccess.get_sha256(SandboxGenerator.SOURCE),world.source_sha256,int(base.home_id),int(base.cell_id),base.content_sha])
 if base.seed!=seed:return "sandbox.seed: Unsupported source/generation version"
 var ids := {};var slots := {}
 for row in base.sites:
  if not row is Dictionary or not row.has_all(["id","opportunity_id","name","kind","position","world_position","description","reward","context","provenance","board"]) or row.size()!=11 or not row.context is Dictionary or not row.provenance is Dictionary:return "sandbox.site: Malformed generated site"
  var slot: Variant=row.context.get("placement_slot")
  if not RulesJson.integer(slot,0,7) or slots.has(str(slot)):return "sandbox.site: Invalid source placement slot"
  slots[str(slot)]=true
  var expected := "sandbox-site:"+RulesJson.digest([s.version,world.world_id,int(base.home_id),int(base.cell_id),int(slot)])
  if row.id!=expected or ids.has(expected) or row.opportunity_id!="opportunity:"+RulesJson.digest([s.version,expected]) or row.provenance.get("seed")!=RulesJson.digest([seed,expected]) or row.context.get("placement_ref")!=ExpeditionRecords.site_id(world,int(base.cell_id),int(slot)) or row.context.get("home_id")!=base.home_id or row.context.get("cell_id")!=base.cell_id:return "sandbox.site: Unstable source/site identity"
  ids[expected]=true
  if not row.position is Array or row.position.size()!=2 or not row.world_position is Array or row.world_position.size()!=2 or not row.name is String or not row.description is String or row.description.length()>450 or not row.board is Dictionary or not SandboxGenerator.valid_board(row.board) or row.board.generation.seed!=row.provenance.seed or row.board.generation.site_id!=row.id or row.board.generation.kind!=row.kind:return "sandbox.map: Invalid generated map/description"
  for coordinate in row.position:
   if not coordinate is float and not coordinate is int or coordinate<0 or coordinate>1000:return "sandbox.position: Invalid local coordinates"
 if s.knowledge.size()!=ids.size() or s.characters.size()!=state.party_ids.size():return "sandbox.roster: Missing site/character state"
 for id in s.knowledge:
  if not ids.has(id) or not s.knowledge[id] in ["rumoured","discovered","visited","resolved"]:return "sandbox.knowledge: Unknown site/state"
 for id in s.encounters:
  if not ids.has(id) or not s.encounters[id] is Dictionary:return "sandbox.encounter: Unknown encounter"
  var b: Dictionary=s.encounters[id];var why := TacticalCombat.new().validate(b)
  if not why.is_empty() or b.site_id!=id or b.board!=site(s,id).board:return "sandbox.encounter: "+why
  var members: Array=b.units.values().filter(func(u: Dictionary):return u.team=="party").map(func(u: Dictionary):return u.id)
  if members.size()!=3 or not state.party_ids.all(func(p: String):return members.has(p)):return "sandbox.encounter: Party identities changed"
  if b.status=="active" and (s.active.get("site_id")!=id or s.active.get("phase")!="combat"):return "sandbox.encounter: Active fight lost its expedition"
  if b.status!="active" and not s.results.has(id):return "sandbox.result: Terminal fight requires atomic result"
 var ordered: Array=[]
 for id in s.results:
  if not ids.has(id) or not s.encounters.has(id) or not s.results[id] is Dictionary:return "sandbox.result: Unknown result"
  var r: Dictionary=s.results[id];var b: Dictionary=s.encounters[id]
  if r.size()!=6 or r.get("site_id")!=id or not r.get("outcome") in ["victory","defeat"] or r.outcome!=b.status or r.get("battle_hash")!=b.state_hash or r.get("xp_each")!=(10 if b.status=="victory" else 0) or not r.get("text") is String or not RulesJson.integer(r.get("sequence"),1,state.expedition.log.size()) or s.knowledge[id]!="resolved":return "sandbox.result: Corrupt outcome/reward"
  var event: Dictionary=state.expedition.log[int(r.sequence)-1]
  if event.text!=r.text or event.type!=("record" if b.status=="victory" else "leave") or state.world_deltas.get(id,{}).get("sandbox_outcome")!=r.outcome or state.world_deltas.get(id,{}).get("battle_hash")!=b.state_hash or state.world_deltas.get(id,{}).get("encounter_id")!=b.board.id:return "sandbox.result: Missing world consequence"
  ordered.append(r)
 ordered.sort_custom(func(a: Dictionary,b: Dictionary):return a.sequence<b.sequence)
 for id in s.knowledge:
  if s.knowledge[id]=="resolved" and not s.results.has(id):return "sandbox.result: Premature resolution"
 for id in state.party_ids:
  var c: Variant=s.characters.get(id)
  if not c is Dictionary or c.size()!=2 or not c.get("history") is Array:return "sandbox.history: Missing character record"
  var history: Array=[];var xp := 0
  for r in ordered:
   xp+=int(r.xp_each);history.append({"encounter_id":site(s,r.site_id).board.id,"site_id":r.site_id,"outcome":r.outcome,"summary":r.text})
  if c.get("xp")!=xp or c.history!=history:return "sandbox.history: Duplicated or missing progression"
 if not s.active.is_empty():
  if s.active.size()!=3 or not ids.has(s.active.get("site_id")) or not s.active.get("phase") in ["map","site","combat","result"] or not RulesJson.integer(s.active.get("supplies"),0,4):return "sandbox.active: Invalid journey"
  if s.active.phase=="combat" and (not s.encounters.has(s.active.site_id) or s.encounters[s.active.site_id].status!="active"):return "sandbox.active: Missing saved active encounter"
  if s.active.phase=="result" and not s.results.has(s.active.site_id):return "sandbox.active: Missing result"
  if s.active.phase in ["site","combat"] and s.knowledge[s.active.site_id] not in ["visited","resolved"]:return "sandbox.active: Missing visit"
 return ""
static func projection(s: Dictionary) -> Dictionary:
 var sites: Array=[];var leads: Array=[]
 for row in s.base.sites:
  var known: bool=s.knowledge[row.id]!="rumoured"
  if known:sites.append({"id":row.id,"name":row.name,"kind":row.kind,"position":row.position,"description":row.description,"knowledge":s.knowledge[row.id]})
  leads.append({"id":row.id,"site":row.id if known else "","title":row.name if known else "Rumour of an occupied work-yard","knowledge":s.knowledge[row.id],"status":"resolved" if s.results.has(row.id) else "available","goal":"Approach and assess the armed occupants","clue":row.description if known else "A local report describes armed occupants somewhere outside the town. Scout to establish their position."})
 return {"sites":sites,"leads":leads,"home_position":s.base.home_position}
