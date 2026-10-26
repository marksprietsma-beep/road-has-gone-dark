extends "res://tests/class_signatures/connected_driver.gd"
var owned_action := {}
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"ranger-archery-6",state.party_ids[1]:"ranger-blade-6",state.party_ids[2]:"steward-drive-3"}
func requires_manifestation() -> bool:return false
func candidate_targets(battle: Dictionary,actor: Dictionary,ability: String) -> Array:
 if ability!="steward-drive-3":return battle.units.values()
 if owned_action.is_empty():return []
 return battle.units.values().filter(func(u: Dictionary):return u.get("entity",{}).get("kind")=="companion" and u.entity.owner_id==actor.id)
func signature_setup(battle: Dictionary,actor: Dictionary) -> Dictionary:
 if actor.id==state.party_ids[2] and owned_action.is_empty():return {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
 if actor.get("entity",{}).get("kind")=="companion" and actor.entity.owner_id==state.party_ids[2] and owned_action.is_empty():
  var engine := TacticalAuras.new(state);var proposed := engine.enemy_command(battle)
  if proposed.kind in ["move","attack"]:
   var result := engine.command(battle,proposed);check(result.ok,"earned companion uses original move/attack command")
   if proposed.kind=="attack" and result.ok and result.battle.units[proposed.target_id].record.runtime.hp<battle.units[proposed.target_id].record.runtime.hp:
    owned_action={"actor_id":actor.id,"owner_id":actor.entity.owner_id,"definition_id":actor.entity.definition_id,"kind":"attack","target_id":proposed.target_id,"before_hp":battle.units[proposed.target_id].record.runtime.hp,"after_hp":result.battle.units[proposed.target_id].record.runtime.hp,"command":proposed,"before_hash":battle.state_hash,"after_hash":result.battle.state_hash}
   return proposed
 return {}
func finish_connected(restart := false) -> void:
 if restart:
  var proof := WorldOriginLore.read_json(connected_folder.path_join("proof.json"));check(not proof.get("owned_action",{}).is_empty(),"real owned attack was recorded before cold restart")
  for id in state.party_ids:
   var pid: String=RulesEntities.identity(id);var r: Dictionary=state.mechanics.records[id]
   check(r.runtime.companions.size()==1 and r.runtime.companions.has(pid),"same permanent owner/creature identity after combat, home and cold continuation")
   var pet: Dictionary=r.runtime.companions[pid].record;var d := RulesCharacter.new(source).derive_character(pet)
   check(d.ok and pet.runtime.hp==d.snapshot.stats.HP,"eligible home rest recovers actual saved companion")
 else:
  check(not owned_action.is_empty(),"actual earned companion lands a real natural attack before command checkpoint")
  if FileAccess.file_exists(connected_folder.path_join("proof.json")):
   var proof := WorldOriginLore.read_json(connected_folder.path_join("proof.json"));proof.owned_action=owned_action;proof.checks=checks;proof.failures=failures
   FileAccess.open(connected_folder.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 super.finish_connected(restart)
