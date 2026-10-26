extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"monk-wind-6",state.party_ids[1]:"paladin-mercy-6",state.party_ids[2]:"paladin-justice-6"}
func requires_manifestation() -> bool:return false
func candidate_targets(battle: Dictionary,actor: Dictionary,ability: String) -> Array:
 if ability!="paladin-mercy-6":return battle.units.values()
 # Wait for real enemy damage; do not manufacture wounds or count a zero heal.
 return battle.units.values().filter(func(u: Dictionary):return u.team==actor.team and int(u.record.runtime.hp)>0 and int(u.record.runtime.hp)<int(TacticalAuras.new(state).stats(u).HP))
func signature_setup(battle: Dictionary,actor: Dictionary) -> Dictionary:
 if actor.id==state.party_ids[1] and not performed.has(actor.id) and candidate_targets(battle,actor,"paladin-mercy-6").is_empty():
  return {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
 return {}
