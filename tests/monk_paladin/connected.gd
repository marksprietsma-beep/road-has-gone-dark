extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"monk-wind-6",state.party_ids[1]:"paladin-mercy-6",state.party_ids[2]:"paladin-justice-6"}
func requires_manifestation() -> bool:return false
func candidate_targets(battle: Dictionary,actor: Dictionary,ability: String) -> Array:
 if ability!="paladin-mercy-6":return battle.units.values()
 # Wait for real enemy damage; do not manufacture wounds or count a zero heal.
 return battle.units.values().filter(func(u: Dictionary):return u.team==actor.team and int(u.record.runtime.hp)>0 and int(u.record.runtime.hp)<int(TacticalAuras.new(state).stats(u).HP))
