extends "res://tests/psychic_parity/connected.gd"
func earned_source_xp() -> int:return 810
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"metamind-reclaim",state.party_ids[1]:"pyrokineticist-technique-4",state.party_ids[2]:"power-force-screen-aug2"}
func signature_setup(battle: Dictionary,actor: Dictionary) -> Dictionary:
 if actor.id!=state.party_ids[0] or performed.has(actor.id) or int(battle.budget.main)==0:return {}
 var caps: Dictionary=RulesCharacter.new(source).derive_character(actor.record).snapshot.resource_capacities
 if int(actor.record.runtime.resources["psychic-points"])<int(caps["psychic-points"]):return {}
 # Spend3 real points on ally protection first; later reclaim must restore
 # actual missing points while consuming a finite reserve/main action.
 return {"actor_id":actor.id,"revision":battle.revision,"kind":"power-force-screen-aug2","target_id":actor.id}
