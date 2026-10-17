extends "res://tests/character_completeness/journey_driver.gd"
## Production adventure/save/XP services, no free XP or high-level substitutions.
func create_party() -> void:
 configs=[["wizard","human",""],["cleric","human",""],["fighter","human",""]]
 planner.free();planner=load("res://tests/spell_repertoires/caster_planner.gd").new();planner.source=source;planner.kernel=kernel
 super.create_party()
func spell_selection(record: Dictionary) -> Dictionary:
 var selected := super.spell_selection(record)
 var snapshot: Dictionary=kernel.derive_character(record).snapshot
 for aid in ["wizard-gravitic-snare","cleric-freedom-path"]:
  if not snapshot.abilities.has(aid):continue
  var pool: String=str(source.definition("abilities",aid).casting_class)+"-slots-4"
  for id in selected.spells.duplicate():
   if source.definition("abilities",id).cost.resources.has(pool):selected.spells.erase(id);selected.preparations.erase(id)
  selected.spells.append(aid);selected.preparations[aid]=1
 return selected
func test_real_combat() -> void:
 # The final home-return preceded the earned level7 choice. Newly unlocked
 # slots start empty; take a genuine new expedition and return/rest, never
 # grant resources from the selector or fixture code.
 var xp_before: int=CharacterBuilderRecords.xp(state,state.party_ids[0])
 if cycle().results.size()==4:action("cycle_seek")
 travel(0);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==xp_before,"home-return rest grants resources but never XP")
 var tactical := TacticalAuras.new(state);var battle := tactical.create(state,"game130-earned-casters")
 var wanted := {state.party_ids[0]:"wizard-gravitic-snare",state.party_ids[1]:"cleric-freedom-path",state.party_ids[2]:"attack"}
 for n in 200:
  if battle.status!="active":break
  var actor := tactical.current(battle);var command := tactical.enemy_command(battle)
  if actor.team=="party" and int(battle.budget.main)>0 and not combat_actions.has(actor.id):
   var aid: String=wanted[actor.id]
   for target in battle.units.values():
    if tactical.eligible(battle,actor,target,aid):
     var proposed := {"actor_id":actor.id,"revision":battle.revision,"kind":aid,"target_id":target.id}
     if tactical.command(battle,proposed).ok:command=proposed;break
  var result := tactical.command(battle,command)
  check(result.ok,"earned character production tactical action "+str(command.kind))
  if not result.ok:return
  check(result.battle.state_hash==tactical.command(battle,command).battle.state_hash,"earned new spell deterministic replay")
  if actor.team=="party" and command.kind==wanted[actor.id]:combat_actions[actor.id]=str(command.kind)
  battle=result.battle
  if combat_actions.size()==3:break
 check(combat_actions.size()==3,"earned Wizard/Cleric cast new tier4 spells and martial ally acts")
 FileAccess.open(base.path_join("combat.json"),FileAccess.WRITE).store_string(JSON.stringify(battle))
