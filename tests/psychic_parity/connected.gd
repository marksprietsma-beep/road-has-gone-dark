extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"power-kinetic-bolt-aug2",state.party_ids[1]:"wilder-surge",state.party_ids[2]:"wizard-arcane-bolt"}
func requires_manifestation() -> bool:return false
func candidate_targets(battle: Dictionary,actor: Dictionary,ability: String) -> Array:
 return battle.units.values().filter(func(t: Dictionary):return t.team!=actor.team)
