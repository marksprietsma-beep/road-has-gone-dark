class_name OpportunityCycles
extends RefCounted
## Optional versioned ledger. Legacy sandbox and character pins remain intact.
const VERSION := "contextual-cycles-v1"
const SOURCE := "res://data/sandbox/cycles-v1.json"
static var _base_cache := {}
static var _profile_cache := {}
static func rules() -> Dictionary:return WorldOriginLore.read_json(SOURCE)
static func current(state: Dictionary) -> Dictionary:
 var cycles: Array=state.get("adventure_cycles",{}).get("cycles",[])
 return cycles.back().record if not cycles.is_empty() else {}
static func xp(state: Dictionary,id: String) -> int:
 var total := 0
 for cycle in state.get("adventure_cycles",{}).get("cycles",[]):total+=int(cycle.record.characters.get(id,{}).get("xp",0))
 return total
static func history(state: Dictionary,id: String) -> Array:
 var rows: Array=[]
 for cycle in state.get("adventure_cycles",{}).get("cycles",[]):rows.append_array(cycle.record.characters.get(id,{}).get("history",[]))
 return rows
static func remember(facts: Dictionary,site: Dictionary,result: Dictionary) -> void:
 var place: String=str(site.context.placement_ref)
 var previous: Dictionary=facts.get(place,{})
 var fact := {"event_id":site.id,"outcome":result.outcome,"threat_event_id":previous.get("threat_event_id",""),"threat_outcome":previous.get("threat_outcome","")}
 var activity := OpportunityGenerator.template(str(site.get("activity_id","")))
 if activity.is_empty() or activity.get("family")=="contested":
  fact.threat_event_id=site.id;fact.threat_outcome=result.outcome
 facts[place]=fact
static func memories(state: Dictionary,count: int=-1) -> Dictionary:
 var facts := {}
 var legacy: Dictionary=state.get("sandbox",{})
 for site in legacy.get("base",{}).get("sites",[]):
  if legacy.get("results",{}).has(site.id):remember(facts,site,legacy.results[site.id])
 var cycles: Array=state.get("adventure_cycles",{}).get("cycles",[])
 for cycle in cycles.slice(0,cycles.size() if count<0 else count):
  for site in cycle.record.base.sites:
   if cycle.record.results.has(site.id):remember(facts,site,cycle.record.results[site.id])
 return RulesJson.string_keys(facts)
static func context(state: Dictionary) -> Dictionary:
 var profiles := {};var levels := 0
 for id in state.party_ids:
  profiles[id]=state.mechanics.records[id].duplicate(true)
  levels+=profiles[id].advancement_history.size()
 return RulesJson.string_keys({"ordinal":state.get("adventure_cycles",{}).get("cycles",[]).size()+1,"memories":memories(state),"profiles":profiles,"threat_level":mini(maxi(1,int(ceil(float(levels)/state.party_ids.size()))),int(rules().enemy_level_cap))})
static func generate(world: GameWorldTemplate,home: int,pool: Array,content_sha: String,home_position: Array,c: Dictionary) -> Dictionary:
 c=RulesJson.string_keys(c)
 var cache_key := RulesJson.digest([world.world_ref,home,pool,content_sha,home_position,c,FileAccess.get_sha256(SOURCE)])
 if _base_cache.has(cache_key):return _base_cache[cache_key].duplicate(true)
 var cell: Dictionary=world.get_record("cell",int(world.get_record("burg",home).cell))
 var biome: String=str(world.get_record("biome",int(cell.biome)).get("name","Unclassified land"))
 var environment := "forest" if "forest" in biome.to_lower() or biome.to_lower()=="taiga" else "dry" if "desert" in biome.to_lower() or "savanna" in biome.to_lower() else "upland" if int(cell.get("heights",20))>=60 else "grass"
 var seed := RulesJson.digest([VERSION,FileAccess.get_sha256(SOURCE),world.source_sha256,home,int(world.get_record("burg",home).cell),content_sha,c])
 var sites: Array=[];var used: Array=[];var policy := rules()
 for i in 4:
  var slot := (i+SandboxGenerator.pick(seed,"placement-offset",8))%8
  var placement: Dictionary=pool[slot];var previous: Dictionary=c.memories.get(placement.id,{})
  var route := SandboxGenerator.nearest_route(world,placement.world_position,int(world.get_record("burg",home).cell))
  var family: String=["recovery","investigation","contested",""][i]
  # A failed/peaceful prior occupation is remembered rather than respawned as
  # a newly defeated threat. A local assistance/evidence report stays possible.
  if family=="contested" and previous.get("threat_outcome") in ["defeat","peaceful_access","withdrawn","failed_check"]:family="investigation"
  var activity := OpportunityGenerator.select(seed+":"+str(i),environment,float(route.distance)<=2.0,family,used)
  if activity.is_empty():activity=OpportunityGenerator.select(seed+":"+str(i),environment,false,"",used)
  if activity.is_empty():return {}
  if activity.family=="contested" and previous.get("threat_outcome") in ["defeat","peaceful_access","withdrawn","failed_check"]:
   activity=OpportunityGenerator.select(seed+":"+str(i),environment,false,"recovery",used)
   if activity.is_empty():activity=OpportunityGenerator.select(seed+":"+str(i),environment,false,"investigation",used)
  if activity.is_empty():return {}
  used.append(activity.id)
  var id := "cycle-site:"+RulesJson.digest([VERSION,world.world_id,home,c.ordinal,slot,seed])
  var local_seed := RulesJson.digest([seed,id])
  var recipe := {"version":SandboxGenerator.VERSION,"rules_sha":FileAccess.get_sha256(SandboxGenerator.SOURCE),"seed":local_seed,"site_id":id,"kind":activity.kind,"environment":environment,"composition":SandboxGenerator.pick(local_seed,"opponents",SandboxGenerator.rules().compositions.size())}
  var board := SandboxGenerator.battlefield(recipe)
  if board.is_empty():return {}
  var titles: Array=policy.titles[activity.family]
  var name: String=str(titles[SandboxGenerator.pick(local_seed,"report",titles.size())])+" · "+str(world.get_record("burg",home).name)+" #"+str(c.ordinal)
  var past := " Earlier report here: "+str(previous.outcome).replace("_"," ")+"; its saved outcome remains." if not previous.is_empty() else " This location has no resolved party report yet."
  var description: String=str(activity.description)+past+(" Prior armed group: "+str(previous.threat_outcome).replace("_"," ")+"." if not str(previous.get("threat_outcome","")).is_empty() else "")+" New report "+str(c.ordinal)+" from the hometown; this is a distinct generated objective."
  sites.append({"id":id,"opportunity_id":"opportunity:"+RulesJson.digest([VERSION,id]),"name":name,"kind":activity.kind,"position":placement.position.duplicate(),"world_position":placement.world_position.duplicate(),"description":description,"reward":"10 journey XP each for full objective completion; no duplicate combat award.","activity_id":activity.id,"context":{"home_id":home,"cell_id":int(world.get_record("burg",home).cell),"region_id":int(cell.get("province",0)),"biome":biome,"environment":environment,"placement_ref":placement.id,"placement_slot":slot,"route_ref":int(route.id) if activity.requires_route else -1},"provenance":{"version":VERSION,"seed":local_seed,"world_sha":world.source_sha256,"content_sha":content_sha,"rules_sha":FileAccess.get_sha256(SOURCE),"authorship":"TRHGD generated local fiction"},"board":board})
 var result := {"version":VERSION,"seed":seed,"world_ref":world.world_ref.duplicate(true),"home_id":home,"cell_id":int(world.get_record("burg",home).cell),"content_sha":content_sha,"rules_sha":FileAccess.get_sha256(SOURCE),"home_position":home_position.duplicate(),"sites":sites}
 result=RulesJson.string_keys(result)
 _base_cache[cache_key]=result.duplicate(true)
 return result
static func reward(choice: Dictionary) -> int:
 return int(rules().objective_xp) if choice.complete and choice.outcome in rules().rewarded_outcomes else 0
static func choices(state: Dictionary,site: Dictionary) -> Array:
 var options := OpportunityGenerator.choices(state,site)
 var trained: Array=[]
 var c: Dictionary=state.adventure_cycles.cycles.back().context
 var activity := OpportunityGenerator.template(site.activity_id)
 for id in state.party_ids:
  var record: Dictionary=c.profiles[id]
  var key := RulesJson.digest(record)
  if not _profile_cache.has(key):_profile_cache[key]=RulesCharacter.new(RulesRecords.registry(record)).derive_character(record).snapshot
  var snapshot: Dictionary=_profile_cache[key]
  var source := RulesRecords.registry(record)
  var approaches: Array=[]
  for skill in rules().skill_map[activity.family]:approaches.append({"skill":skill})
  approaches.append_array(RulesCompleteness.approaches(source,str(site.activity_id)))
  for profile in approaches:
   var skill: String=profile.skill
   if int(snapshot.skills.get(skill,{}).get("ranks",0))<int(profile.get("min_ranks",0)):continue
   if not snapshot.skills.has(skill) or not snapshot.skills[skill].usable:continue
   var bonus: int=int(snapshot.skills[skill].total)
   var dc: int=int(rules().skill_dc_base)+int(c.threat_level)+int(profile.get("dc_adjustment",0))
   var rolled := RulesRng.roll("1d20",RulesRng.initial(RulesJson.digest([VERSION,site.id,id,skill])))
   var success: bool=int(rolled.total)+bonus>=dc
   var choice: Dictionary=activity.choices.filter(func(o: Dictionary):return o.id==("negotiate" if activity.family=="contested" else "careful"))[0].duplicate(true)
   choice.id="skill:"+id+":"+str(skill);choice.participant=id;choice.profession="skill:"+str(skill)
   choice.label=str(state.party.members.filter(func(m: Dictionary):return m.character_id==id)[0].name)+": "+str(skill).capitalize()+" +"+str(bonus)+" vs DC "+str(dc)
   choice.provisions=int(rules().skill_provision_cost[activity.family]);choice.gain=int(choice.gain) if success else 0;choice.reveal=bool(choice.reveal) and success
   choice.outcome=choice.outcome if success else "failed_check";choice.complete=true
   if profile.has("event"):
    for field in ["event","provisions"]:choice[field]=profile[field]
    choice.gain=int(profile.gain) if success else 0;choice.reveal=bool(profile.reveal) and success
    choice.outcome=profile.outcome if success else "failed_check"
    choice.label+=" · "+str(profile.label)
   choice.information="%s check: %d + %d vs DC %d · %s."%[str(skill).capitalize(),int(rolled.total),bonus,dc,"objective completed" if success else "attempt failed; no XP"]
   if profile.has("information"):choice.information+=" "+str(profile.information)
   if profile.has("information"):trained.append(choice)
   else:options.append(choice)
 return trained+options
static func initial_battle(state: Dictionary,site: Dictionary) -> Dictionary:
 var engine := TacticalAuras.new(state);var battle := engine.create_generated(state,site.id,site.board)
 if battle.is_empty():return {}
 var level: int=int(state.adventure_cycles.cycles.back().context.threat_level)
 for enemy in site.board.enemies:
  var record: Dictionary=battle.units[enemy.id].record
  var cls: String=str(engine.registry.recommendation(enemy.role)["class"])
  for n in range(1,level):
   var proposal := engine.characters.suggested_choice(record,cls)
   var advanced := engine.characters.preview_advancement(record,proposal.choice)
   if not advanced.ok:return {}
   record=advanced.candidate
  var snapshot: Dictionary=engine.characters.derive_character(record).snapshot
  record.runtime.hp=int(snapshot.stats.HP)
  for resource in snapshot.resource_capacities:record.runtime.resources[resource]=snapshot.resource_capacities[resource]
  battle.units[enemy.id].record=record
 # Same initiative rule, distinct versioned initial data. Combat/RNG unchanged.
 var ranks := {};var initiatives := {}
 for i in battle.order.size():ranks[battle.order[i]]=i;initiatives[battle.order[i]]=engine.stats(battle.units[battle.order[i]]).initiative
 battle.order.sort_custom(func(a: String,b: String):return initiatives[a]>initiatives[b] if initiatives[a]!=initiatives[b] else ranks[a]<ranks[b])
 return engine.seal(battle)
