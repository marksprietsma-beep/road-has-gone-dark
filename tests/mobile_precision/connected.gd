extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"scout-technique-1",state.party_ids[1]:"rogue-debilitating-1",state.party_ids[2]:"knight-technique-1"}
func requires_manifestation() -> bool:return false
