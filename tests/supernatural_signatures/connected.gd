extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"warlock-invocation-assault",state.party_ids[1]:"binder-sentinel",state.party_ids[2]:"draconic-ward-6"}
func requires_manifestation() -> bool:return false
