class_name SandboxAdventure
extends RefCounted
## Transitions return candidates to AdventureService's existing lock/journal/store.
static func transition(service: AdventureService,entry: Dictionary,state: Dictionary,operation: String,changes: Dictionary) -> Dictionary:
 var world: GameWorldTemplate=entry.world
 if state.party.status!="ready" or not state.has("expedition") or not state.expedition.active.is_empty():return service.fail("Return to the hometown with your saved party first.")
 if not state.get("first_adventure",{}).get("battle",{}).is_empty() and state.first_adventure.result.is_empty():return service.fail("Finish or withdraw from the saved Old Road fixture first.")
 if changes.get("revision")!=state.expedition.revision:return service.fail("The journey changed. Resume before continuing.")
 var input := entry.duplicate();input.home=state.origin.home_burg_id
 var ready := service.prepare(input)
 if not ready.ok:return ready
 if state.expedition.content_sha!=service.packet.content.sha or state.expedition.packet_sha!=service.packet_digest:return service.fail("Original region cache changed; campaign preserved.")
 var base := SandboxGenerator.generate(world,int(state.origin.home_burg_id),service.packet.content)
 if base.is_empty():return service.fail("No valid bounded sandbox layout; campaign preserved.")
 var candidate: Dictionary=state.duplicate(true)
 if candidate.has("sandbox") and candidate.sandbox.base_sha!=RulesJson.digest(base):return service.fail("Generated source/version does not match the saved sandbox. Nothing was rerolled.")
 if operation=="sandbox_begin":
  if candidate.has("sandbox"):return {"ok":true,"candidate":candidate}
  var prepared := RulesRecords.preview_preparation(candidate)
  if not prepared.ok:return prepared
  candidate=prepared.candidate;candidate.sandbox=SandboxRecords.create(base,candidate)
  service._event(candidate,"begin","Local opportunities are recorded from this region. No opening quest is required.",0)
  return {"ok":true,"candidate":candidate}
 if not candidate.has("sandbox") or candidate.sandbox.base_sha!=RulesJson.digest(base):return service.fail("Generated source/version does not match the saved sandbox. Nothing was rerolled.")
 var s: Dictionary=candidate.sandbox;var active: Dictionary=s.active
 var selected: String=str(changes.get("lead",active.get("site_id","")))
 if selected.is_empty():selected=str(active.get("site_id",""))
 var site := SandboxRecords.site(s,selected)
 if operation=="sandbox_accept":
  if not active.is_empty() or site.is_empty() or s.results.has(selected):return service.fail("Choose an unresolved opportunity from home.")
  s.active={"site_id":selected,"phase":"map","supplies":4}
  service._event(candidate,"depart","The party sets out to assess a local opportunity.",1)
 elif operation=="sandbox_return":
  if active.is_empty() or active.phase=="combat":return service.fail("Finish or withdraw from the saved fight first.")
  s.active={}
  for id in candidate.party_ids:
   var record: Dictionary=candidate.mechanics.records[id]
   var snapshot: Dictionary=RulesCharacter.new(RulesRecords.registry()).derive_character(record).snapshot
   record.runtime.hp=int(snapshot.stats.HP);record.runtime.statuses=[]
   for resource in snapshot.resource_capacities:record.runtime.resources[resource]=snapshot.resource_capacities[resource]
   record.revision+=1
  candidate.mechanics.revision+=1
  service._event(candidate,"return","Returned home and rested (V0 HP/Focus recovery). Site knowledge, opponents and results remain recorded.",1)
 else:
  if active.is_empty() or site.is_empty() or selected!=active.site_id:return service.fail("No matching active journey.")
  if operation=="sandbox_scout":
   if active.phase!="map" or s.knowledge[selected]!="rumoured" or active.supplies<1:return service.fail("This site cannot be scouted now.")
   s.knowledge[selected]="discovered";active.supplies-=1
   service._event(candidate,"scout","Located "+site.name+". Its source-grounded position stays discovered.",2)
  elif operation=="sandbox_travel":
   if active.phase!="map" or s.knowledge[selected]=="rumoured" or active.supplies<1:return service.fail("Discover the position before travelling.")
   active.phase="site";active.supplies-=1;s.knowledge[selected]="visited"
   service._event(candidate,"travel","Arrived at "+site.name+". The site and encounter are generated local content.",1)
  elif operation=="sandbox_fight":
   if active.phase!="site" or active.supplies<1 or s.results.has(selected) or s.encounters.has(selected):return service.fail("The encounter is already saved or unavailable.")
   var battle := TacticalCombat.new().create_generated(candidate,selected,site.board)
   if battle.is_empty():return service.fail("Generated encounter failed validation; campaign preserved.")
   s.encounters[selected]=battle;active.phase="combat"
  elif operation=="sandbox_command":
   if active.phase!="combat" or not s.encounters.has(selected) or s.results.has(selected):return service.fail("No unresolved saved encounter.")
   var engine := TacticalCombat.new();var b: Dictionary=s.encounters[selected]
   var command: Variant=changes.get("command",{})
   if not command is Dictionary:return service.fail("Invalid combat command.")
   if engine.current(b).team=="enemy" and RulesJson.digest(command)!=RulesJson.digest(engine.enemy_command(b)):return service.fail("Enemy orders remain deterministic.")
   var applied := engine.command(b,command)
   if not applied.ok:return applied
   s.encounters[selected]=applied.battle
   if applied.battle.status!="active":resolve(service,candidate,site)
  else:return service.fail("Unknown sandbox transition.")
 s.revision+=1
 return {"ok":true,"candidate":candidate}
static func resolve(service: AdventureService,candidate: Dictionary,site: Dictionary) -> void:
 var s: Dictionary=candidate.sandbox;var b: Dictionary=s.encounters[site.id]
 var victory: bool=b.status=="victory"
 var text: String="The armed occupants of "+site.name+(" were defeated. The opportunity is complete; each companion gains 10 journey XP." if victory else " drove the party back. This attempt and the surviving opponents stay recorded; no reward or silent respawn.")
 var result := {"site_id":site.id,"outcome":b.status,"battle_hash":b.state_hash,"xp_each":10 if victory else 0,"text":text,"sequence":candidate.expedition.revision+1}
 s.results[site.id]=result;s.knowledge[site.id]="resolved";s.active.phase="result"
 for id in candidate.party_ids:
  s.characters[id].xp+=result.xp_each
  s.characters[id].history.append({"encounter_id":b.board.id,"site_id":site.id,"outcome":b.status,"summary":text})
  var record: Dictionary=candidate.mechanics.records[id]
  record.runtime=b.units[id].record.runtime.duplicate(true);record.runtime.hp=maxi(1,int(record.runtime.hp));record.runtime.statuses=[];record.revision+=1
 candidate.mechanics.revision+=1
 candidate.world_deltas[site.id]={"sandbox_outcome":b.status,"encounter_id":b.board.id,"battle_hash":b.state_hash,"pending_future_hooks":["injury","relationship","reputation","personal_quest"]}
 service._event(candidate,"record" if victory else "leave",text,2 if victory else 0)
