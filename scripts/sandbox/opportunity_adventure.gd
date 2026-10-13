class_name OpportunityAdventure
extends RefCounted
const DEPART := "The party sets out to assess a V2 local opportunity."
static func summary(site: Dictionary,choice: Dictionary,gained: int,xp: int) -> String:
 var contributor: String=" Contribution: "+(str(choice.profession).trim_prefix("skill:").capitalize() if str(choice.profession).begins_with("skill:") else str(choice.profession).replace("-"," "))+"." if not choice.participant.is_empty() else ""
 return str(site.name)+": "+str(choice.outcome).replace("_"," ")+". "+str(choice.information)+" Cost: %d turn(s), %d provision(s); recovered %d. Journey XP each: %d."%[ExpeditionRecords.EVENT_COSTS[choice.event],choice.provisions,gained,xp]+contributor
static func apply(service: AdventureService,candidate: Dictionary,site: Dictionary,choice: Dictionary,battle_hash: String="",xp: int=0,cycling: bool=false) -> void:
 var s: Dictionary=candidate.sandbox;var a: Dictionary=s.active
 var before := int(a.supplies);var gained := mini(int(choice.gain),4-before+int(choice.provisions))
 a.supplies=before-int(choice.provisions)+gained
 var discovered := ""
 if choice.reveal:
  for other in s.base.sites:
   if other.id!=site.id and s.knowledge[other.id]=="rumoured":
    s.knowledge[other.id]="discovered";discovered=other.id;break
 if cycling:xp=OpportunityCycles.reward(choice)
 var text := summary(site,choice,gained,xp)
 var action := {"site_id":site.id,"choice_id":choice.id,"participant":choice.participant,"profession":choice.profession,"provisions_spent":choice.provisions,"provisions_gained":gained,"supplies_before":before,"supplies_after":a.supplies,"turns":ExpeditionRecords.EVENT_COSTS[choice.event],"event":choice.event,"sequence":candidate.expedition.revision+1,"outcome":choice.outcome,"information":choice.information,"discovered_site":discovered,"text":text,"battle_hash":battle_hash,"xp_each":xp,"complete":choice.complete}
 s.actions.append(action)
 if not s.information.has(site.id):s.information[site.id]=[]
 s.information[site.id].append({"sequence":action.sequence,"text":choice.information,"discovered_site":discovered})
 if choice.complete:
  var result := action.duplicate(true);result["version"]="activity-result-cycles-v1" if cycling else "activity-result-v2"
  s.results[site.id]=result;s.knowledge[site.id]="resolved";a.phase="result"
 for id in candidate.party_ids:
  s.characters[id].xp+=xp;s.characters[id].history.append(OpportunityRecords.history(action,site))
 candidate.world_deltas[site.id]=OpportunityRecords.delta(s.actions,site.id,cycling)
 service._event(candidate,("cycle_" if cycling else "")+str(choice.event),text,int(action.turns))
static func resolve(service: AdventureService,candidate: Dictionary,site: Dictionary,cycling: bool=false) -> void:
 var b: Dictionary=candidate.sandbox.encounters[site.id];var victory: bool=b.status=="victory"
 var choice := {"id":"combat_result","participant":"","profession":"","provisions":0,"gain":0,"outcome":b.status,"information":"Armed occupants defeated." if victory else "The armed group forced a withdrawal and remains in place.","reveal":false,"complete":true,"event":"record" if victory else "leave"}
 for id in candidate.party_ids:
  var record: Dictionary=candidate.mechanics.records[id]
  record.runtime=b.units[id].record.runtime.duplicate(true);record.runtime.hp=maxi(1,int(record.runtime.hp));record.runtime.statuses=[];record.revision+=1
 candidate.mechanics.revision+=1
 apply(service,candidate,site,choice,b.state_hash,10 if victory else 0,cycling)
static func transition(service: AdventureService,entry: Dictionary,state: Dictionary,operation: String,changes: Dictionary,cycling: bool=false) -> Dictionary:
 if state.party.status!="ready" or not state.has("expedition") or not state.expedition.active.is_empty():return service.fail("Return to the hometown with your saved party first.")
 if not state.get("first_adventure",{}).get("battle",{}).is_empty() and state.first_adventure.result.is_empty():return service.fail("Finish the saved Old Road encounter first.")
 if changes.get("revision")!=state.expedition.revision:return service.fail("The journey changed. Resume before continuing.")
 var input := entry.duplicate();input.home=state.origin.home_burg_id
 var ready := service.prepare(input)
 if not ready.ok:return ready
 if state.expedition.content_sha!=service.packet.content.sha or state.expedition.packet_sha!=service.packet_digest:return service.fail("Original region cache changed; campaign preserved.")
 var base := OpportunityCycles.generate(entry.world,int(state.origin.home_burg_id),state.adventure_cycles.pool,state.expedition.content_sha,state.adventure_cycles.home_position,state.adventure_cycles.cycles.back().context) if cycling else OpportunityGenerator.generate(entry.world,int(state.origin.home_burg_id),service.packet.content)
 if base.is_empty():return service.fail("No valid bounded V2 opportunities; campaign preserved.")
 var candidate := state.duplicate(true)
 if candidate.has("sandbox") and candidate.sandbox.base_sha!=RulesJson.digest(base):return service.fail("Saved V2 source/version changed. Nothing was rerolled.")
 if operation=="sandbox_begin":
  if candidate.has("sandbox"):return {"ok":true,"candidate":candidate}
  var prepared := RulesRecords.preview_preparation(candidate)
  if not prepared.ok:return prepared
  candidate=prepared.candidate;candidate.sandbox=OpportunityRecords.create(base,candidate)
  service._event(candidate,("cycle_" if cycling else "")+"begin","Recovery, evidence and contested access are recorded as generated local opportunities; choose your own route.",0)
  return {"ok":true,"candidate":candidate}
 if not candidate.has("sandbox"):return service.fail("Prepare local opportunities at home first.")
 var s: Dictionary=candidate.sandbox;var a: Dictionary=s.active
 var selected := str(changes.get("lead",a.get("site_id","")))
 if selected.is_empty():selected=str(a.get("site_id",""))
 var site := SandboxRecords.site(s,selected)
 if operation=="sandbox_accept":
  if not a.is_empty() or site.is_empty() or s.results.has(selected):return service.fail("Choose an unresolved opportunity from home.")
  s.active={"site_id":selected,"phase":"map","supplies":4};service._event(candidate,("cycle_" if cycling else "")+"depart",DEPART,1)
 elif operation=="sandbox_return":
  if a.is_empty() or a.phase=="combat":return service.fail("Finish or withdraw from the saved fight first.")
  s.active={}
  for id in candidate.party_ids:
   var record: Dictionary=candidate.mechanics.records[id]
   var snapshot: Dictionary=RulesCharacter.new(RulesRecords.registry(candidate)).derive_character(record).snapshot
   record.runtime.hp=int(snapshot.stats.HP);record.runtime.statuses=[]
   RulesEntities.recover_companions(record,RulesRecords.registry(state))
   for resource in snapshot.resource_capacities:record.runtime.resources[resource]=snapshot.resource_capacities[resource]
   record.revision+=1
  candidate.mechanics.revision+=1
  service._event(candidate,("cycle_" if cycling else "")+"return","Returned home and rested. Choices, information, provisions spent and world consequences remain recorded.",1)
 else:
  if a.is_empty() or site.is_empty() or selected!=a.site_id:return service.fail("No matching active V2 journey.")
  if operation=="sandbox_scout":
   if a.phase!="map" or s.knowledge[selected]!="rumoured" or a.supplies<1:return service.fail("The report cannot be scouted now.")
   s.knowledge[selected]="discovered";a.supplies-=1
   service._event(candidate,("cycle_" if cycling else "")+"scout","Located "+site.name+". Its generated type and source-owned position are now known.",2)
  elif operation=="sandbox_travel":
   if a.phase!="map" or s.knowledge[selected]=="rumoured" or a.supplies<1:return service.fail("Discover the location and prepare provisions before travelling.")
   a.phase="site";a.supplies-=1;s.knowledge[selected]="visited"
   service._event(candidate,("cycle_" if cycling else "")+"travel","Arrived at "+site.name+". Choose an approach; costs and outcomes are distinct.",1)
  elif operation=="sandbox_activity":
   if a.phase!="site" or s.results.has(selected):return service.fail("This site's outcome is already recorded.")
   var choices := (OpportunityCycles.choices(candidate,site) if cycling else OpportunityGenerator.choices(candidate,site)).filter(func(o: Dictionary):return o.id==changes.get("choice"))
   if choices.is_empty():return service.fail("That choice or companion contribution is unavailable.")
   var choice: Dictionary=choices[0]
   if choice.id=="fight":return service.fail("Use the authoritative combat action.")
   if a.supplies<int(choice.provisions):return service.fail("Not enough provisions for that approach; withdraw or return home.")
   if not choice.complete and s.actions.any(func(action: Dictionary):return action.site_id==selected and action.outcome==choice.outcome):return service.fail("Those occupants were already observed; the information is saved.")
   apply(service,candidate,site,choice,"",0,cycling)
  elif operation=="sandbox_fight":
   if a.phase!="site" or OpportunityGenerator.template(site.activity_id).family!="contested" or a.supplies<1 or s.results.has(selected) or s.encounters.has(selected):return service.fail("No unresolved hostile encounter is available.")
   var battle := OpportunityCycles.initial_battle(candidate,site) if cycling else TacticalCombat.new(candidate).create_generated(candidate,selected,site.board)
   if battle.is_empty():return service.fail("Generated combat failed validation; campaign preserved.")
   s.encounters[selected]=battle;a.phase="combat"
   service._event(candidate,("cycle_" if cycling else "")+"begin","The contested encounter is saved. Combat now owns its actions and RNG.",0)
  elif operation=="sandbox_command":
   if a.phase!="combat" or not s.encounters.has(selected) or s.results.has(selected):return service.fail("No unresolved saved battle.")
   var engine := TacticalCombat.new(candidate);var b: Dictionary=s.encounters[selected]
   var command: Variant=changes.get("command",{})
   if not command is Dictionary:return service.fail("Invalid combat command.")
   if engine.current(b).team=="enemy" and RulesJson.digest(command)!=RulesJson.digest(engine.enemy_command(b)):return service.fail("Enemy orders remain deterministic.")
   var applied := engine.command(b,command)
   if not applied.ok:return applied
   s.encounters[selected]=applied.battle
   if applied.battle.status!="active":resolve(service,candidate,site,cycling)
  else:return service.fail("Unknown V2 opportunity transition.")
 s.revision+=1
 return {"ok":true,"candidate":candidate}
