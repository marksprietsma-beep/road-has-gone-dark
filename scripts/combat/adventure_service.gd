class_name AdventureService
extends ExpeditionService
## Existing party lock/journal is the only writer, including individual turns.
func _operate_locked(entry: Dictionary,slot: String,operation: String,member: int,changes: Dictionary) -> Dictionary:
 var world: GameWorldTemplate=entry.world
 var loaded := recover(slot,world)
 if not loaded.ok: return loaded
 var state: Dictionary=loaded.state
 var adventure: Dictionary=state.get("first_adventure",{})
 var battle: Dictionary=RulesJson.normalize(adventure.get("battle",{}))
 if not operation in ["prepare_adventure","begin_battle","battle_command","resolve_battle"]:
  if operation!="resume" and not battle.is_empty() and adventure.result.is_empty(): return fail("Finish or withdraw from the saved encounter first.")
  var result := super._operate_locked(entry,slot,operation,member,changes)
  if result.get("ok",false) and result.state.has("first_adventure"):
   result.state.first_adventure.battle=RulesJson.normalize(result.state.first_adventure.battle)
  return result
 if not state.has("expedition") or state.party.status!="ready": return fail("Enter the hometown with your existing party first.")
 if changes.get("revision")!=state.expedition.revision: return fail("The expedition changed. Resume before continuing.")
 var input := entry.duplicate();input.home=state.origin.home_burg_id
 var prepared := prepare(input)
 if not prepared.ok: return prepared
 if state.expedition.content_sha!=packet.content.sha or state.expedition.packet_sha!=packet_digest: return fail("Local content version changed; campaign preserved.")
 var candidate := state.duplicate(true)
 if operation=="prepare_adventure":
  if not adventure.is_empty(): return loaded
  var preview := RulesRecords.preview_preparation(candidate)
  if not preview.ok: return preview
  candidate=preview.candidate
  candidate.first_adventure=AdventureRecords.create(candidate)
 elif operation=="begin_battle":
  if adventure.is_empty(): return fail("Meet your party at the hometown first.")
  if not battle.is_empty() or not adventure.result.is_empty(): return fail("The first encounter is already saved.")
  var active: Dictionary=state.expedition.active
  if active.get("phase")!="site" or int(active.supplies)<1 or state.expedition.outcomes.has(active.get("site_id")): return fail("Visit an unresolved local site with provisions first.")
  candidate.first_adventure.battle=TacticalCombat.new().create(state,active.site_id,CombatBattlefields.DEFAULT)
  if candidate.first_adventure.battle.is_empty():return fail("The authored battlefield is unavailable. Campaign preserved.")
  candidate.first_adventure.revision+=1
 elif operation=="battle_command":
  if battle.is_empty() or not adventure.result.is_empty(): return fail("No active encounter.")
  var command_input = changes.get("command",{})
  if not command_input is Dictionary: return fail("Invalid battle command.")
  if TacticalCombat.new().current(battle).team=="enemy" and RulesJson.digest(command_input)!=RulesJson.digest(TacticalCombat.new().enemy_command(battle)): return fail("Enemy orders are deterministic.")
  var applied := TacticalCombat.new().command(battle,command_input)
  if not applied.ok: return applied
  candidate.first_adventure.battle=applied.battle
  candidate.first_adventure.revision+=1
  # Result and final action share one save: interruption cannot lose rewards.
  if applied.battle.status!="active": resolve(candidate)
 elif operation=="resolve_battle":
  if not adventure.result.is_empty(): return loaded
  if battle.is_empty() or battle.status=="active": return fail("Encounter is not finished.")
  resolve(candidate)
 var committed := commit(slot,candidate,world)
 if committed.get("ok",false): committed.state.first_adventure.battle=RulesJson.normalize(committed.state.first_adventure.battle)
 return committed

func resolve(candidate: Dictionary) -> void:
 var a: Dictionary=candidate.first_adventure
 var b: Dictionary=a.battle
 var victory: bool=b.status=="victory"
 var site_id: String=b.site_id
 var site: Dictionary=packet.content.sites.filter(func(s: Dictionary):return s.id==site_id)[0]
 var text: String=("The party drove raiders away from the approach to "+site.name+". The local account is recorded; each adventurer earns 10 journey XP.") if victory else ("Raiders forced the party to withdraw from "+site.name+". The account remains unresolved. Fallen companions were helped back with 1 HP.")
 a.result={"outcome":b.status,"site_id":site_id,"battle_hash":b.state_hash,"xp_each":10 if victory else 0,"text":text}
 for id in candidate.party_ids:
  var life: Dictionary=a.characters[id]
  life.xp+=a.result.xp_each;life.hook.status="experienced"
  life.history.append({"encounter_id":"first-road-v1","site_id":site_id,"outcome":b.status,"summary":text})
  var record: Dictionary=candidate.mechanics.records[id]
  record.runtime=b.units[id].record.runtime.duplicate(true)
  # V0 rescue, not death/injuries. Transient combat conditions never leak home.
  record.runtime.hp=maxi(1,int(record.runtime.hp))
  record.runtime.statuses.clear();record.revision+=1
 candidate.mechanics.revision+=1
 for kind in ["injury","relationship","reputation","personal_quest"]:
  a.consequence_hooks.append({"kind":kind,"status":"pending_future_system","source":"first-road-v1","site_id":site_id,"character_ids":candidate.party_ids.duplicate(),"outcome":b.status})
 var e: Dictionary=candidate.expedition
 var approach := "record" if victory else "leave"
 e.outcomes[site_id]={"approach":approach,"sequence":e.revision+1,"text":text}
 if victory:
  e.knowledge[site_id]="investigated";e.active.supplies-=1
 candidate.world_deltas[site_id]={"first_adventure":b.status,"investigated":victory,"approach":approach}
 e.active.phase="result"
 _event(candidate,approach,text,2 if victory else 0)
