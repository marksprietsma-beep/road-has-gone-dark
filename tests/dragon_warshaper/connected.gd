extends "res://tests/class_signatures/connected_driver.gd"
## Real earned campaign, original commands/writer and owned creature combat.
var owned_actions := {}
var setup_actions := {}
func full_careers() -> bool:return OS.get_environment("DRAGON_WARSHAPER_EARNED_FULL")=="1"
func earned_source_xp() -> int:return 2280 if full_careers()else 480
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"dragon-disciple-technique-7"if full_careers()else"dragon-disciple-technique-1",state.party_ids[1]:"warshaper-technique-3"if full_careers()else"warshaper-technique-1",state.party_ids[2]:"dragon-disciple-technique-4"if full_careers()else"guard"}
func requires_manifestation() -> bool:return false
func signature_setup(battle: Dictionary,actor: Dictionary) -> Dictionary:
 var engine:=TacticalAuras.new(state);var owner: String=state.party_ids[1]
 if actor.id==state.party_ids[0]and (not owned_actions.has_all(["summon","companion"])or not performed.has(owner)or not performed.has(state.party_ids[2])):return {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
 if actor.id==owner and not setup_actions.has("summon")and battle.budget.main==1:
  if battle.budget.move==1:
   var move: Dictionary=engine.enemy_command(battle)
   if move.kind=="move":return move
  var command: Dictionary={"actor_id":owner,"revision":battle.revision,"kind":"druid-summon-sentinel","target_id":owner};var expected: Dictionary=engine.command(battle,command)
  check(expected.ok,"actual prepared Druid Sentinel can coexist with earned Warshaper and Wolf")
  if expected.ok:setup_actions.summon={"command":command,"before_hash":battle.state_hash,"after_hash":expected.battle.state_hash};return command
 if actor.id==owner and performed.has(owner)and battle.budget.main==1 and RulesEntities.form(actor.record,source).is_empty()and owned_actions.has_all(["summon","companion"]):
  var command: Dictionary={"actor_id":owner,"revision":battle.revision,"kind":wanted_actions()[owner],"target_id":owner};var expected: Dictionary=engine.command(battle,command)
  if expected.ok:return command
 if actor.has("entity")and not owned_actions.has(actor.entity.kind):
  var proposed: Dictionary=engine.enemy_command(battle)
  if proposed.kind in ["attack","move"]:
   var expected: Dictionary=engine.command(battle,proposed);check(expected.ok,"real owned actor action "+actor.entity.kind)
   if expected.ok and proposed.kind=="attack"and expected.battle.units[proposed.target_id].record.runtime.hp<battle.units[proposed.target_id].record.runtime.hp:
    owned_actions[actor.entity.kind]={"actor_id":actor.id,"owner_id":actor.entity.owner_id,"kind":"attack","definition_id":actor.entity.definition_id,"command":proposed,"before_hp":battle.units[proposed.target_id].record.runtime.hp,"after_hp":expected.battle.units[proposed.target_id].record.runtime.hp}
   return proposed
 return {}
func finish_connected(restart := false) -> void:
 if restart:
  var proof: Dictionary=WorldOriginLore.read_json(connected_folder.path_join("proof.json"));check(proof.owned_actions.has_all(["summon","companion"]),"real Wolf and temporary Sentinel attacks survive independent continuation")
  var owner: Dictionary=state.mechanics.records[state.party_ids[1]];var pet: String=RulesEntities.identity(owner.character_id)
  check(owner.runtime.companions.size()==1 and owner.runtime.companions[pet].definition_id=="wolf","same owned Wolf remains after resolution/home")
  var recovered: Dictionary=kernel.derive_character(owner.runtime.companions[pet].record)
  check(recovered.ok and owner.runtime.companions[pet].record.runtime.hp==recovered.snapshot.stats.HP,"eligible home rest restores the persistent creature")
  check(RulesEntities.form(owner,source).is_empty(),"actual return restores original Ogre body and equipment")
 else:
  var battle: Dictionary=AdventureService.active_battle(state);var owner: String=state.party_ids[1]
  check(owned_actions.has_all(["summon","companion"])and setup_actions.has("summon"),"actual owned creatures both attack; no fabricated summon command or XP")
  check(not RulesEntities.form(battle.units[owner].record,source).is_empty(),"saved active campaign contains the real paid Warshaper form")
  if FileAccess.file_exists(connected_folder.path_join("proof.json")):
   var proof: Dictionary=WorldOriginLore.read_json(connected_folder.path_join("proof.json"));proof.owned_actions=owned_actions;proof.setup_actions=setup_actions;proof.checks=checks;proof.failures=failures
   FileAccess.open(connected_folder.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 super.finish_connected(restart)
