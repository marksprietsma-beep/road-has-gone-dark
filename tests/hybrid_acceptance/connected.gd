extends "res://tests/class_signatures/connected_driver.gd"
func earned_source_xp() -> int:return 1690
func requires_manifestation() -> bool:return false
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"channel-duskblade-searing-grasp",state.party_ids[1]:"high-arcana-force-1",state.party_ids[2]:"high-arcana-ward-1"}
func signature_setup(battle: Dictionary,actor: Dictionary) -> Dictionary:
 # Let the real support action happen first. No HP, resources, turns or enemies
 # are edited; other adventurers explicitly end their current activation.
 if actor.team=="party" and actor.id!=state.party_ids[2] and not performed.has(state.party_ids[2]):return {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
 return {}
func candidate_targets(battle: Dictionary,_actor: Dictionary,ability: String) -> Array:
 var result: Array=battle.units.values()
 var preferred: String=state.party_ids[0] if ability=="high-arcana-ward-1" else "bandit-blade"
 result.sort_custom(func(a: Dictionary,b: Dictionary):return a.id==preferred if (a.id==preferred)!=(b.id==preferred) else str(a.id)<str(b.id))
 return result
