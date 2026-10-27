extends "res://tests/class_signatures/connected_driver.gd"
## Original writer and actual earned party; held owner waits for owned attacks.
var owned_actions := {}
func earned_source_xp() -> int:return 810
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"grove-protection-1",state.party_ids[1]:"bonded-summoner-technique-5",state.party_ids[2]:"grove-protection-2"}
func requires_manifestation() -> bool:return false
func candidate_targets(battle: Dictionary,actor: Dictionary,ability: String) -> Array:
 if ability=="grove-protection-2":
  if not owned_actions.has("summon") or not owned_actions.has("companion"):return []
  return battle.units.values().filter(func(u: Dictionary):return u.get("entity",{}).get("kind")=="companion" and u.entity.owner_id==actor.id)
 return battle.units.values()
func signature_setup(battle: Dictionary,actor: Dictionary) -> Dictionary:
 if actor.id==state.party_ids[2] and (not owned_actions.has("summon") or not owned_actions.has("companion")):return {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
 if actor.has("entity") and not owned_actions.has(actor.entity.kind):
  var engine := TacticalAuras.new(state);var proposed: Dictionary=engine.enemy_command(battle)
  if proposed.kind in ["attack","move"]:
   var result: Dictionary=engine.command(battle,proposed);check(result.ok,"real earned owned actor command "+actor.entity.kind)
   if proposed.kind=="attack"and result.ok and result.battle.units[proposed.target_id].record.runtime.hp<battle.units[proposed.target_id].record.runtime.hp:
    owned_actions[actor.entity.kind]={"actor_id":actor.id,"owner_id":actor.entity.owner_id,"definition_id":actor.entity.definition_id,"kind":"attack","before_hp":battle.units[proposed.target_id].record.runtime.hp,"after_hp":result.battle.units[proposed.target_id].record.runtime.hp,"command":proposed,"before_hash":battle.state_hash,"after_hash":result.battle.state_hash}
   return proposed
 return {}
func finish_connected(restart := false) -> void:
 if restart:
  var proof: Dictionary=WorldOriginLore.read_json(connected_folder.path_join("proof.json"));check(proof.owned_actions.has_all(["summon","companion"]),"real owned summon and permanent companion attacks preserved across independent restart")
  var id: String=state.party_ids[2];var owner: Dictionary=state.mechanics.records[id];var pid: String=RulesEntities.identity(id)
  check(owner.runtime.companions.size()==1 and owner.runtime.companions[pid].definition_id=="leopard","same permanent companion survives resolution/home")
  var d: Dictionary=kernel.derive_character(owner.runtime.companions[pid].record)
  check(d.ok and owner.runtime.companions[pid].record.runtime.hp==d.snapshot.stats.HP,"eligible home recovery restores actual persistent creature")
  check(state.mechanics.records[state.party_ids[1]].runtime.companions.is_empty(),"temporary summon never becomes a campaign animal companion")
 else:
  check(owned_actions.has_all(["summon","companion"]),"actual earned temporary and permanent creatures both land attacks before checkpoint")
  if FileAccess.file_exists(connected_folder.path_join("proof.json")):
   var proof: Dictionary=WorldOriginLore.read_json(connected_folder.path_join("proof.json"));proof.owned_actions=owned_actions;proof.checks=checks;proof.failures=failures
   FileAccess.open(connected_folder.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 super.finish_connected(restart)
