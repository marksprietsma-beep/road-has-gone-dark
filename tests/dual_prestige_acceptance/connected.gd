extends "res://tests/class_signatures/connected_driver.gd"
func earned_source_xp() -> int:return 640
func requires_manifestation() -> bool:return false
func wanted_actions() -> Dictionary:
 if OS.get_environment("DUAL_CONNECTED_VARIANT")=="b":
  return {state.party_ids[0]:"cleric-bless",state.party_ids[1]:"sorcerer-arcane-bolt",state.party_ids[2]:"abjurant-aegis-3"}
 return {state.party_ids[0]:"wizard-arcane-bolt",state.party_ids[1]:"cleric-bless",state.party_ids[2]:"abjurant-retaliation-1"}
func signature_setup(battle: Dictionary,actor: Dictionary) -> Dictionary:
 # Support before attacking; every wait is an ordinary End command.
 var support: String=state.party_ids[0] if OS.get_environment("DUAL_CONNECTED_VARIANT")=="b" else state.party_ids[1]
 if actor.team=="party" and actor.id!=support and not performed.has(support):return {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
 return {}
func candidate_targets(battle: Dictionary,_actor: Dictionary,ability: String) -> Array:
 var targets: Array=battle.units.values()
 var preferred: String=state.party_ids[2] if ability in ["cleric-bless","abjurant-aegis-3"] else "bandit-blade"
 targets.sort_custom(func(a: Dictionary,b: Dictionary):return a.id==preferred if (a.id==preferred)!=(b.id==preferred) else str(a.id)<str(b.id))
 return targets
