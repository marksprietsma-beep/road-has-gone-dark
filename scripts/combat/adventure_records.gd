class_name AdventureRecords
extends RefCounted
## Additive V0 records. Existing GAME-81 identities remain the source of truth.
static var _foundation := {}
static func foundation_label(section: String,id: String) -> String:
 if _foundation.is_empty(): _foundation=JSON.parse_string(FileAccess.get_file_as_string("res://data/world_enrichment/trhgd-expanded-v1.json"))
 for row in _foundation.get(section,[]):
  if row is Dictionary and row.get("id")==id: return str(row.get("label",id))
 return id.replace("-"," ").capitalize()
static func identity(state: Dictionary,member: Dictionary) -> Dictionary:
 var background: Dictionary=member.generated_facts.background
 var record: Dictionary=state.get("first_adventure",{}).get("characters",{}).get(member.character_id,{})
 var recommendation := RulesRecords.registry().recommendation(member.role_id)
 var role: String=str(RulesRecords.registry().definition("classes",recommendation["class"]).name)
 return {"name":member.name,"archetype":role,"background":foundation_label("occupations",str(member.generated_facts.occupation_id)),"motivation":foundation_label("motivation",str(background.motivation)),"hook":str(record.get("hook",{}).get("summary","Worries about "+foundation_label("concern",str(background.concern)).to_lower()+"; this journey is a chance to address it.")),"relationship":"Grew up near "+", ".join(state.party.members.filter(func(m: Dictionary):return m.character_id!=member.character_id).map(func(m: Dictionary):return m.name))+".","xp":int(record.get("xp",0)),"history":record.get("history",[])}
static func create(state: Dictionary) -> Dictionary:
 var records := {}
 for m in state.party.members:
  var concern: String=str(m.generated_facts.background.concern)
  records[m.character_id]={"hook":{"id":m.character_id+":first-journey","kind":"background-concern","concern_ref":concern,"background_ref":m.background_id,"home_ref":int(state.origin.home_burg_id),"summary":identity(state,m).hook,"status":"open"},"xp":0,"history":[]}
 return {"version":1,"revision":1,"characters":records,"battle":{},"result":{},"consequence_hooks":[]}
static func validate(state: Dictionary,_world: GameWorldTemplate) -> String:
 if not state.has("first_adventure"): return ""
 var a = RulesJson.normalize(state.first_adventure)
 if not a is Dictionary or a.size()!=6 or a.get("version")!=1 or not RulesJson.integer(a.get("revision"),1,RulesJson.LIMIT) or not a.get("characters") is Dictionary or not a.get("battle") is Dictionary or not a.get("result") is Dictionary or not a.get("consequence_hooks") is Array or not state.has("mechanics") or not state.has("expedition"): return "adventure.schema: Invalid first adventure"
 if a.characters.size()!=state.party_ids.size(): return "adventure.roster: Mismatched characters"
 for m in state.party.members:
  var c = a.characters.get(m.character_id)
  if not c is Dictionary or c.size()!=3 or not c.get("hook") is Dictionary or not RulesJson.integer(c.get("xp"),0,100000) or not c.get("history") is Array: return "adventure.identity: Missing character life record"
  var h: Dictionary=c.hook
  if h.size()!=7 or h.get("id")!=m.character_id+":first-journey" or h.get("kind")!="background-concern" or h.get("concern_ref")!=str(m.generated_facts.background.concern) or h.get("background_ref")!=m.background_id or h.get("home_ref")!=state.origin.home_burg_id or not h.get("summary") is String or not h.get("status") in ["open","experienced"]: return "adventure.hook: Invalid source references"
 if not a.battle.is_empty():
  var error := TacticalCombat.new().validate(a.battle)
  if not error.is_empty(): return "adventure.battle: "+error
  var ids: Array=a.battle.units.values().filter(func(u: Dictionary):return u.team=="party").map(func(u: Dictionary):return u.id)
  for id in state.party_ids:
   if not ids.has(id): return "adventure.battle: Party identity mismatch"
  if a.battle.status=="active" or a.result.is_empty():
   if state.expedition.active.get("phase")!="site" or state.expedition.active.get("site_id")!=a.battle.site_id: return "adventure.context: Active encounter requires its expedition site"
 if not a.result.is_empty():
  if a.result.size()!=5 or not a.result.get("outcome") in ["victory","defeat"] or a.battle.is_empty() or a.battle.status!=a.result.outcome or a.result.get("battle_hash")!=a.battle.state_hash or a.result.get("site_id")!=a.battle.site_id or a.result.get("xp_each")!=(10 if a.result.outcome=="victory" else 0) or not a.result.get("text") is String: return "adventure.result: Invalid consequence"
  if not state.expedition.log.any(func(event: Dictionary):return event.text==a.result.text) or state.world_deltas.get(a.result.site_id,{}).get("first_adventure")!=a.result.outcome: return "adventure.result: Missing world memory"
  for id in state.party_ids:
   if a.characters[id].history.size()!=1 or a.characters[id].history[0]!={"encounter_id":"first-road-v1","site_id":a.result.site_id,"outcome":a.result.outcome,"summary":a.result.text} or a.characters[id].xp!=a.result.xp_each or a.characters[id].hook.status!="experienced": return "adventure.history: Invalid history/progression"
  if a.consequence_hooks.size()!=4: return "adventure.hooks: Missing future hooks"
  for i in 4:
   var expected := {"kind":["injury","relationship","reputation","personal_quest"][i],"status":"pending_future_system","source":"first-road-v1","site_id":a.result.site_id,"character_ids":state.party_ids.duplicate(),"outcome":a.result.outcome}
   if a.consequence_hooks[i]!=expected: return "adventure.hooks: Invalid future hook"
 else:
  if not a.consequence_hooks.is_empty(): return "adventure.hooks: Premature consequence"
  for c in a.characters.values():
   if c.xp!=0 or not c.history.is_empty() or c.hook.status!="open": return "adventure.history: Premature progression"
 return ""
