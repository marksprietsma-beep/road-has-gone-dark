class_name CycleAdventure
extends RefCounted
static var _validated_cycles := {}
static func current(state: Dictionary) -> Dictionary:return OpportunityCycles.current(state)
static func ready_for_leads(state: Dictionary) -> bool:
 if AdventureService.away(state):return false
 var s: Dictionary=current(state) if state.has("adventure_cycles") else state.get("sandbox",{})
 return s.is_empty() or s.results.size()==s.base.sites.size()
static func transition(service: AdventureService,entry: Dictionary,state: Dictionary,operation: String,changes: Dictionary) -> Dictionary:
 if changes.get("revision")!=state.expedition.revision:return service.fail("The journey changed. Resume before continuing.")
 if operation=="cycle_seek":return seek(service,entry,state)
 if not state.has("adventure_cycles"):return service.fail("Seek new leads at home first.")
 var input := entry.duplicate();input.home=state.origin.home_burg_id
 var source := service.prepare(input)
 if not source.ok:return source
 if not source_matches(state,service.packet):return service.fail("Saved report geography does not match the original region. Campaign preserved.")
 var shadow := state.duplicate(true)
 shadow.sandbox=current(state).duplicate(true)
 var result := OpportunityAdventure.transition(service,entry,shadow,operation.replace("cycle_","sandbox_"),changes,true)
 if not result.get("ok",false):return result
 result.candidate.adventure_cycles.cycles.back().record=result.candidate.sandbox
 if state.has("sandbox"):result.candidate.sandbox=state.sandbox.duplicate(true)
 else:result.candidate.erase("sandbox")
 return result
static func seek(service: AdventureService,entry: Dictionary,state: Dictionary) -> Dictionary:
 if state.party.status!="ready" or not ready_for_leads(state):return service.fail("Return home and resolve the current reports before seeking another set. Unfinished reports stay saved.")
 var input := entry.duplicate();input.home=state.origin.home_burg_id
 var prepared := service.prepare(input)
 if not prepared.ok:return prepared
 if state.expedition.content_sha!=service.packet.content.sha or state.expedition.packet_sha!=service.packet_digest:return service.fail("Original local source changed; campaign preserved.")
 var preparation := RulesRecords.preview_preparation(state)
 if not preparation.ok:return preparation
 var candidate: Dictionary=preparation.candidate
 if candidate.has("adventure_cycles") and not source_matches(candidate,service.packet):return service.fail("Original report geography changed; campaign preserved.")
 if not candidate.has("adventure_cycles"):
  candidate.adventure_cycles={"version":OpportunityCycles.VERSION,"policy_sha":FileAccess.get_sha256(OpportunityCycles.SOURCE),"pool":RulesJson.string_keys(JSON.parse_string(JSON.stringify(service.packet.content.sites))),"home_position":RulesJson.string_keys(JSON.parse_string(JSON.stringify(service.packet.content.home_position))),"cycles":[]}
 var ledger: Dictionary=candidate.adventure_cycles
 if not ledger.cycles.is_empty():ledger.cycles.back().end_sequence=int(candidate.expedition.revision)
 var c := OpportunityCycles.context(candidate)
 var base := OpportunityCycles.generate(entry.world,int(candidate.origin.home_burg_id),ledger.pool,candidate.expedition.content_sha,ledger.home_position,c)
 if base.is_empty():return service.fail("No valid contextual reports could be prepared; existing history preserved.")
 var record := OpportunityRecords.create(base,candidate);record.version=OpportunityCycles.VERSION
 ledger.cycles.append({"context":c,"record":record,"start_sequence":int(candidate.expedition.revision)+1,"end_sequence":0})
 service._event(candidate,"cycle_seek","New reports from the hometown are recorded. Full objective completion earns 10 journey XP each; inspections, travel and rest do not.",1)
 return {"ok":true,"candidate":candidate}
static func source_matches(state: Dictionary,packet: Dictionary) -> bool:
 if not state.has("adventure_cycles"):return true
 return RulesJson.string_keys(state.adventure_cycles.pool)==RulesJson.string_keys(JSON.parse_string(JSON.stringify(packet.content.sites))) and RulesJson.string_keys(state.adventure_cycles.home_position)==RulesJson.string_keys(JSON.parse_string(JSON.stringify(packet.content.home_position)))
static func validate(state: Dictionary,world: GameWorldTemplate) -> String:
 if not state.has("adventure_cycles"):return ""
 var ledger: Variant=RulesJson.string_keys(state.adventure_cycles)
 if not ledger is Dictionary or ledger.size()!=5 or not ledger.has_all(["version","policy_sha","pool","home_position","cycles"]) or ledger.version!=OpportunityCycles.VERSION or ledger.policy_sha!=FileAccess.get_sha256(OpportunityCycles.SOURCE) or not ledger.pool is Array or ledger.pool.size()!=8 or not ledger.cycles is Array or ledger.cycles.is_empty() or not ledger.home_position is Array or ledger.home_position.size()!=2:return "cycles.schema: Invalid pinned cycle ledger"
 if not state.has_all(["mechanics","expedition","party"]) or state.party.status!="ready":return "cycles.context: Missing ready campaign"
 for n in ledger.home_position:
  if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>1000:return "cycles.placement: Invalid hometown coordinates"
 var cell := int(world.get_record("burg",int(state.origin.home_burg_id)).cell)
 for i in 8:
  var placement: Variant=ledger.pool[i]
  if not placement is Dictionary or placement.get("id")!=ExpeditionRecords.site_id(world,cell,i):return "cycles.placement: Invalid geographic identity"
  for field in ["position","world_position"]:
   if not placement.get(field) is Array or placement[field].size()!=2:return "cycles.placement: Invalid coordinates"
   for n in placement[field]:
    if not (n is int or n is float) or not is_finite(float(n)):return "cycles.placement: Nonfinite coordinates"
  for n in placement.position:
   if n<0 or n>1000:return "cycles.placement: Out of local bounds"
 var histories := {}
 for id in state.party_ids:
  var now: Dictionary=RulesJson.string_keys(state.mechanics.records[id])
  histories[id]=RulesJson.digest([now.advancement_history,now.base_attributes,now.ancestry_ref,now.rules_ref,now.equipment,now.background_ref])
 var previous_end := 0
 for index in ledger.cycles.size():
  var cycle: Variant=ledger.cycles[index]
  if not cycle is Dictionary or cycle.size()!=4 or not cycle.has_all(["context","record","start_sequence","end_sequence"]) or not cycle.context is Dictionary or not cycle.record is Dictionary:return "cycles.schema: Invalid cycle"
  if not RulesJson.integer(cycle.start_sequence,1,state.expedition.revision) or not RulesJson.integer(cycle.end_sequence,0,state.expedition.revision):return "cycles.sequence: Invalid cycle boundary"
  if not cycle.record.get("information") is Dictionary:return "cycles.schema: Invalid information ledger"
  var c: Dictionary=cycle.context
  var end: int=int(cycle.end_sequence) if cycle.end_sequence>0 else int(state.expedition.revision)
  var deltas := {}
  for site_id in cycle.record.get("information",{}):deltas[site_id]=state.world_deltas.get(site_id)
  var validated_key := RulesJson.digest([world.world_ref,state.party_ids,histories,cycle,deltas,state.expedition.log.slice(int(cycle.start_sequence)-1,end)])
  if _validated_cycles.has(validated_key):
   previous_end=int(cycle.end_sequence)
   continue
  if c.size()!=4 or not c.has_all(["ordinal","memories","profiles","threat_level"]) or c.ordinal!=index+1 or not c.memories is Dictionary or c.memories!=RulesJson.string_keys(OpportunityCycles.memories(state,index)) or not c.profiles is Dictionary or c.profiles.size()!=state.party_ids.size():return "cycles.history: Invalid cycle context"
  var levels := 0
  for id in state.party_ids:
   if not c.profiles.get(id) is Dictionary:return "cycles.profile: Missing persistent character"
   var profile: Dictionary=c.profiles[id];var now: Dictionary=RulesJson.string_keys(state.mechanics.records[id])
   if profile.get("character_id")!=id or profile.get("rules_ref")!=now.rules_ref or not profile.get("advancement_history") is Array or profile.advancement_history.size()>now.advancement_history.size() or profile.advancement_history!=now.advancement_history.slice(0,profile.advancement_history.size()) or profile.get("base_attributes")!=now.base_attributes or profile.get("ancestry_ref")!=now.ancestry_ref or profile.get("background_ref")!=now.background_ref or profile.get("equipment")!=now.equipment:return "cycles.profile: Character history changed"
   var key := RulesJson.digest(profile)
   if not OpportunityCycles._profile_cache.has(key):
    var derived := RulesCharacter.new(RulesRecords.registry(profile)).derive_character(profile)
    if not derived.ok:return "cycles.profile: Invalid mechanical character"
    OpportunityCycles._profile_cache[key]=derived.snapshot
   levels+=profile.advancement_history.size()
  if c.threat_level!=mini(maxi(1,int(ceil(float(levels)/state.party_ids.size()))),int(OpportunityCycles.rules().enemy_level_cap)):return "cycles.challenge: Invalid tier"
  if not RulesJson.integer(cycle.start_sequence,previous_end+1,state.expedition.revision) or not RulesJson.integer(cycle.end_sequence,0,state.expedition.revision):return "cycles.sequence: Invalid cycle boundary"
  if state.expedition.log[int(cycle.start_sequence)-1].type!="cycle_seek":return "cycles.sequence: Missing seek event"
  if index<ledger.cycles.size()-1:
   if cycle.end_sequence!=ledger.cycles[index+1].start_sequence-1 or not cycle.record.active.is_empty() or cycle.record.results.size()!=4:return "cycles.sequence: Unfinished archived cycle"
  elif cycle.end_sequence!=0:return "cycles.sequence: Current cycle closed prematurely"
  previous_end=int(cycle.end_sequence)
  var shadow := state.duplicate();shadow.sandbox=cycle.record
  var expected := OpportunityCycles.generate(world,int(state.origin.home_burg_id),ledger.pool,state.expedition.content_sha,ledger.home_position,c)
  if RulesJson.string_keys(cycle.record.get("base"))!=RulesJson.string_keys(expected):return "cycles.recipe: Source/history/recipe changed"
  var scope := {"context":c,"start":int(cycle.start_sequence),"end":int(cycle.end_sequence) if cycle.end_sequence>0 else int(state.expedition.revision)}
  shadow.adventure_cycles=ledger.duplicate();shadow.adventure_cycles.cycles=ledger.cycles.slice(0,index+1)
  var error := OpportunityRecords.validate(shadow,world,scope)
  if not error.is_empty():return error
  _validated_cycles[validated_key]=true
 return ""
