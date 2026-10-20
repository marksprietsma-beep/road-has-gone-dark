extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"wizard-abjuration-6",state.party_ids[1]:"cleric-war-6",state.party_ids[2]:"attack"}
func requires_manifestation() -> bool:return false
func candidate_targets(battle: Dictionary,actor: Dictionary,ability: String) -> Array:
 if ability=="attack":return super.candidate_targets(battle,actor,ability)
 var wanted: String=state.party_ids[2] if actor.id==state.party_ids[0] else state.party_ids[0]
 var result: Array=battle.units.values()
 result.sort_custom(func(a: Dictionary,b: Dictionary):return a.id==wanted if (a.id==wanted)!=(b.id==wanted) else str(a.id)<str(b.id))
 return result

