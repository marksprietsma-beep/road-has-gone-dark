extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"sorcerer-draconic-6",state.party_ids[1]:"druid-growth-6",state.party_ids[2]:"attack"}
func requires_manifestation() -> bool:return false
func candidate_targets(battle: Dictionary,_actor: Dictionary,ability: String) -> Array:
 var result: Array=battle.units.values()
 if ability=="druid-growth-6":
  var wanted: String=state.party_ids[2]
  result.sort_custom(func(a: Dictionary,b: Dictionary):return a.id==wanted if (a.id==wanted)!=(b.id==wanted) else str(a.id)<str(b.id))
 return result
