class_name OpportunityRecords
extends RefCounted
## Explicit V2 ledger. Noncombat facts never masquerade as battle victories.
static func create(base: Dictionary,state: Dictionary) -> Dictionary:
 var s := SandboxRecords.create(base,state)
 s.version=OpportunityGenerator.VERSION;s["actions"]=[];s["information"]={}
 return s
static func history(action: Dictionary,site: Dictionary) -> Dictionary:
 return {"encounter_id":site.board.id if not action.battle_hash.is_empty() else "","site_id":site.id,"outcome":action.outcome,"summary":action.text,"contributor_id":action.participant,"choice_id":action.choice_id}
static func delta(actions: Array,id: String,cycling: bool=false) -> Dictionary:
 var information: Array=[];var choices: Array=[];var contributors: Array=[];var last := {}
 for action in actions:
  if action.site_id!=id:continue
  last=action;choices.append(action.choice_id)
  if not action.information.is_empty():information.append(action.information)
  if not action.participant.is_empty() and action.participant not in contributors:contributors.append(action.participant)
 if last.is_empty():return {}
 return {"sandbox_version":OpportunityCycles.VERSION if cycling else OpportunityGenerator.VERSION,"outcome":last.outcome,"objective_completed":last.complete and (last.outcome in OpportunityCycles.rules().rewarded_outcomes if cycling else last.outcome not in ["withdrawn","defeat"]),"threat_defeated":last.outcome=="victory","battle_hash":last.battle_hash,"information":information,"choices":choices,"contributors":contributors,"sequence":last.sequence}
static func validate(state: Dictionary,world: GameWorldTemplate,scope: Dictionary={}) -> String:
 var cycling := not scope.is_empty()
 var prefix := "cycle_" if cycling else ""
 var version := OpportunityCycles.VERSION if cycling else OpportunityGenerator.VERSION
 var s: Dictionary=RulesJson.normalize(state.sandbox)
 if s.size()!=11 or not s.has_all(["version","revision","base","base_sha","knowledge","encounters","results","active","characters","actions","information"]) or s.version!=version or not RulesJson.integer(s.revision,1,RulesJson.LIMIT):return "opportunity.schema: Invalid V2 record"
 for key in ["base","knowledge","encounters","results","active","characters","information"]:
  if not s[key] is Dictionary:return "opportunity.schema: Invalid dictionary"
 if not s.actions is Array or not state.has_all(["party","expedition","mechanics"]) or state.party.status!="ready":return "opportunity.context: Saved ready party/rules required"
 var base: Dictionary=s.base
 if base.size()!=9 or not base.has_all(["version","seed","world_ref","home_id","cell_id","content_sha","home_position","sites","rules_sha"]):return "opportunity.pin: Invalid base schema"
 if base.version!=s.version:return "opportunity.pin: Wrong version"
 if RulesJson.digest(base)!=s.base_sha:return "opportunity.pin: Base hash changed"
 if base.world_ref!=RulesJson.normalize(state.world_ref):return "opportunity.pin: World reference mismatch"
 if base.home_id!=state.origin.home_burg_id or base.cell_id!=world.get_record("burg",int(base.home_id)).cell:return "opportunity.pin: Hometown/cell mismatch"
 if base.content_sha!=state.expedition.content_sha:return "opportunity.pin: Local content mismatch"
 var ids := {}
 if not cycling:
  if base.rules_sha!=FileAccess.get_sha256(OpportunityGenerator.SOURCE):return "opportunity.pin: Manifest mismatch"
  if base.seed!=OpportunityGenerator.seed_for(world,int(base.home_id),base.content_sha):return "opportunity.pin: Seed mismatch"
  if not base.sites is Array or base.sites.size()!=4:return "opportunity.pin: Invalid opportunity count"
  if not base.home_position is Array or base.home_position.size()!=2:return "opportunity.position: Invalid home"
  var slots := {};var used: Array=[]
  var families: Array=["recovery","investigation","contested",""]
  families.sort_custom(func(a: String,b: String):return RulesJson.digest([base.seed,a])<RulesJson.digest([base.seed,b]))
  for i in base.sites.size():
   var site: Variant=base.sites[i]
   if not site is Dictionary or site.size()!=12 or not site.has_all(["id","opportunity_id","name","kind","position","world_position","description","reward","context","provenance","board","activity_id"]) or not site.context is Dictionary or not site.provenance is Dictionary:return "opportunity.site: Invalid record"
   var slot: Variant=site.context.get("placement_slot")
   if not RulesJson.integer(slot,0,7) or slots.has(str(slot)):return "opportunity.site: Invalid placement slot"
   var old_seed := RulesJson.digest([SandboxGenerator.VERSION,FileAccess.get_sha256(SandboxGenerator.SOURCE),world.source_sha256,int(base.home_id),int(base.cell_id),base.content_sha])
   if int(slot)!=(i+SandboxGenerator.pick(old_seed,"placement-offset",8))%8:return "opportunity.site: Source placement selection changed"
   slots[str(slot)]=true
   for coordinates in [site.position,site.world_position]:
    if not coordinates is Array or coordinates.size()!=2:return "opportunity.position: Invalid coordinates"
    for n in coordinates:
     if not (n is float or n is int) or not is_finite(float(n)):return "opportunity.position: Nonfinite coordinates"
   for n in site.position:
    if n<0 or n>1000:return "opportunity.position: Out of local bounds"
   var home_cell := world.get_record("cell",int(base.cell_id))
   var biome := str(world.get_record("biome",int(home_cell.biome)).get("name","Unclassified land"))
   var environment := "forest" if ("forest" in biome.to_lower() or biome.to_lower()=="taiga") else "dry" if "desert" in biome.to_lower() or "savanna" in biome.to_lower() else "upland" if int(home_cell.get("heights",20))>=60 else "grass"
   var route := SandboxGenerator.nearest_route(world,site.world_position,int(base.cell_id))
   var activity := OpportunityGenerator.select(base.seed+":"+str(i),environment,float(route.distance)<=2.0,families[i],used)
   if activity.is_empty() or site.activity_id!=activity.id:return "opportunity.pool: Weighted selection changed"
   used.append(activity.id)
   var id := "sandbox-site:"+RulesJson.digest([s.version,world.world_id,int(base.home_id),int(base.cell_id),int(slot)])
   var local_seed := RulesJson.digest([base.seed,id])
   if site.id!=id or ids.has(id) or site.opportunity_id!="opportunity:"+RulesJson.digest([s.version,id]) or site.context.get("home_id")!=base.home_id or site.context.get("cell_id")!=base.cell_id or site.context.get("biome")!=biome or site.context.get("environment")!=environment or site.context.get("route_ref")!=(int(route.id) if activity.requires_route else -1) or site.context.get("placement_ref")!=ExpeditionRecords.site_id(world,int(base.cell_id),int(slot)):return "opportunity.identity: Invalid source identity"
   var recipe := {"version":SandboxGenerator.VERSION,"rules_sha":FileAccess.get_sha256(SandboxGenerator.SOURCE),"seed":local_seed,"site_id":id,"kind":activity.kind,"environment":environment,"composition":SandboxGenerator.pick(local_seed,"opponents",SandboxGenerator.rules().compositions.size())}
   if site.board!=SandboxGenerator.battlefield(recipe) or site.name!=activity.name or site.kind!=activity.kind or site.description!=activity.description or site.provenance!={"version":s.version,"seed":local_seed,"world_sha":world.source_sha256,"content_sha":base.content_sha,"rules_sha":base.rules_sha,"authorship":"TRHGD generated local fiction"}:return "opportunity.recipe: Content/board/provenance changed"
   ids[id]=true
 else:
  for site in base.sites:ids[site.id]=true
 if s.knowledge.size()!=4 or s.characters.size()!=state.party_ids.size():return "opportunity.roster: Missing site/party"
 for id in s.knowledge:
  if not ids.has(id) or s.knowledge[id] not in ["rumoured","discovered","visited","resolved"]:return "opportunity.knowledge: Invalid state"
 for id in s.encounters:
  if not ids.has(id) or not s.encounters[id] is Dictionary:return "opportunity.encounter: Invalid reference"
  var b: Dictionary=s.encounters[id]
  var error := TacticalCombat.new().validate(b)
  if not error.is_empty() or b.site_id!=id or b.board!=SandboxRecords.site(s,id).board:return "opportunity.encounter: "+error
  var members: Array=b.units.values().filter(func(u: Dictionary):return u.team=="party" and not u.has("entity")).map(func(u: Dictionary):return u.id)
  if members.size()!=3 or not state.party_ids.all(func(p: String):return p in members):return "opportunity.encounter: Persistent party changed"
  if b.status=="active" and (s.active.get("phase")!="combat" or s.active.get("site_id")!=id):return "opportunity.encounter: Detached active fight"
  if b.status!="active" and not s.results.has(id):return "opportunity.encounter: Missing atomic result"
 var sequence := 0;var results := {};var information := {};var changes := {};var xp := 0;var histories: Array=[]
 for action in s.actions:
  if not action is Dictionary or action.size()!=18 or not action.has_all(["site_id","choice_id","participant","profession","provisions_spent","provisions_gained","supplies_before","supplies_after","turns","event","sequence","outcome","information","discovered_site","text","battle_hash","xp_each","complete"]) or not ids.has(action.site_id) or not RulesJson.integer(action.sequence,sequence+1,state.expedition.log.size()):return "opportunity.ledger: Invalid ordered action"
  sequence=int(action.sequence)
  for key in ["site_id","choice_id","participant","profession","event","outcome","information","discovered_site","text","battle_hash"]:
   if not action[key] is String:return "opportunity.ledger: Invalid text field"
  for key in ["provisions_spent","provisions_gained","supplies_before","supplies_after"]:
   if not RulesJson.integer(action[key],0,4):return "opportunity.ledger: Invalid provisions"
  if not RulesJson.integer(action.turns,0,2) or not RulesJson.integer(action.xp_each,0,10) or not action.complete is bool:return "opportunity.ledger: Invalid reward/clock/completion"
  var site := SandboxRecords.site(s,action.site_id)
  var expected := {}
  if action.choice_id=="combat_result":
   if not s.encounters.has(site.id) or s.encounters[site.id].status=="active":return "opportunity.result: Unsaved terminal combat"
   var b: Dictionary=s.encounters[site.id]
   expected={"participant":"","profession":"","provisions":0,"gain":0,"outcome":b.status,"information":"Armed occupants defeated." if b.status=="victory" else "The armed group forced a withdrawal and remains in place.","reveal":false,"complete":true,"event":"record" if b.status=="victory" else "leave"}
   if action.battle_hash!=b.state_hash or action.xp_each!=(OpportunityCycles.reward(expected) if cycling else (10 if b.status=="victory" else 0)):return "opportunity.reward: Invalid combat authority"
  else:
   var choices := (OpportunityCycles.choices(state,site) if cycling else OpportunityGenerator.choices(state,site)).filter(func(o: Dictionary):return o.id==action.choice_id)
   if choices.is_empty():return "opportunity.choice: Unsupported choice/participant"
   expected=choices[0]
   if expected.id=="fight" or action.battle_hash!="" or action.xp_each!=(OpportunityCycles.reward(expected) if cycling else 0):return "opportunity.reward: Noncombat battle reward"
  if action.participant!=expected.participant or action.profession!=expected.profession or action.provisions_spent!=expected.provisions or action.provisions_gained!=mini(int(expected.gain),4-int(action.supplies_before)+int(expected.provisions)) or not RulesJson.integer(action.supplies_before,int(expected.provisions),4) or action.supplies_after!=action.supplies_before-action.provisions_spent+action.provisions_gained or action.outcome!=expected.outcome or action.information!=expected.information or action.complete!=expected.complete or action.event!=expected.event or action.turns!=ExpeditionRecords.EVENT_COSTS.get(action.event):return "opportunity.cost: Invalid cost/information/participant"
  if not action.discovered_site is String or not action.text is String or action.text!=OpportunityAdventure.summary(site,expected,action.provisions_gained,action.xp_each):return "opportunity.text: Invalid consequence"
  if not action.discovered_site.is_empty():
   if not expected.reveal or not ids.has(action.discovered_site) or action.discovered_site==site.id or s.knowledge[action.discovered_site]=="rumoured":return "opportunity.discovery: Invalid discovered information"
  var event: Dictionary=state.expedition.log[sequence-1]
  if event.type!=prefix+str(action.event) or event.text!=action.text:return "opportunity.event: Missing cost event"
  if results.has(site.id):return "opportunity.result: Action after resolution"
  if not information.has(site.id):information[site.id]=[]
  information[site.id].append({"sequence":sequence,"text":action.information,"discovered_site":action.discovered_site})
  changes[site.id]=delta(s.actions,site.id,cycling)
  if action.complete:
   var result: Dictionary=action.duplicate(true);result["version"]="activity-result-cycles-v1" if cycling else "activity-result-v2";results[site.id]=result
  xp+=int(action.xp_each);histories.append(history(action,site))
 if s.results!=results or s.information!=information:return "opportunity.result: Duplicated/missing outcome or information"
 for id in changes:
  if RulesJson.normalize(state.world_deltas.get(id))!=changes[id]:return "opportunity.world: Missing world memory"
 for id in s.knowledge:
  if (s.knowledge[id]=="resolved")!=results.has(id):return "opportunity.knowledge: Resolution mismatch"
 for id in state.party_ids:
  if s.characters.get(id)!={"xp":xp,"history":histories}:return "opportunity.history: Duplicated/missing XP or contribution"
 # Reconstruct provisions from the authoritative expedition event stream.
 var supplies := 0;var away := false;var active_id := ""
 for event in state.expedition.log:
  if cycling and (event.sequence<int(scope.start) or event.sequence>int(scope.end)):continue
  var event_type: String=str(event.type).trim_prefix(prefix) if cycling else str(event.type)
  if event_type in ["recover","quick","inspect","negotiate"] and not s.actions.any(func(action: Dictionary):return action.sequence==event.sequence):return "opportunity.event: Unbound V2 cost event"
  if event_type=="depart" and event.text==OpportunityAdventure.DEPART:
   if away:return "opportunity.journey: Departed twice"
   away=true;supplies=4
  elif away:
   if event_type in ["scout","travel"]:supplies-=1
   for action in s.actions:
    if action.sequence==event.sequence:
     if supplies!=action.supplies_before:return "opportunity.supplies: Unfunded or duplicated action"
     supplies=int(action.supplies_after);active_id=action.site_id
   if event_type=="return":away=false;active_id=""
   if supplies<0 or supplies>4:return "opportunity.supplies: Invalid journey balance"
 if away!=(not s.active.is_empty()):return "opportunity.active: Lost journey"
 if not s.active.is_empty():
  var a: Dictionary=s.active
  if a.size()!=3 or not ids.has(a.get("site_id")) or a.get("phase") not in ["map","site","combat","result"] or a.get("supplies")!=supplies or (not active_id.is_empty() and a.site_id!=active_id):return "opportunity.active: Invalid saved journey"
  if a.phase in ["site","combat"] and s.knowledge[a.site_id]!="visited":return "opportunity.active: Missing visit"
  if a.phase=="combat" and (not s.encounters.has(a.site_id) or s.encounters[a.site_id].status!="active"):return "opportunity.active: Missing battle"
  if a.phase=="result" and not s.results.has(a.site_id):return "opportunity.active: Missing result"
 return ""
static func projection(s: Dictionary) -> Dictionary:
 var projected := SandboxRecords.project_v1(s)
 for lead in projected.leads:
  var site := SandboxRecords.site(s,lead.id)
  lead.goal="Choose an approach; combat rewards and noncombat outcomes are distinct."
  lead.clue=site.description if not lead.site.is_empty() else "A local report needs investigation. Scout before its position or kind can be shown."
  if lead.site.is_empty():lead.title="Unlocated local report"
 return projected
