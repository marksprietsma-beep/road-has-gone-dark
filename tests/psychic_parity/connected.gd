extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"power-force-screen-aug2",state.party_ids[1]:"wilder-surge",state.party_ids[2]:"wizard-mage-armour"}
func requires_manifestation() -> bool:return false
func candidate_targets(battle: Dictionary,actor: Dictionary,ability: String) -> Array:
 var row := RulesRecords.registry(state).definition("abilities",ability)
 if row.targeting.kind=="self":return [actor]
 return battle.units.values().filter(func(t: Dictionary):return t.team==actor.team if row.targeting.kind=="ally" else t.team!=actor.team)
