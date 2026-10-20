extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"bard-rally-1",state.party_ids[1]:"beguiler-unmasking-chime",state.party_ids[2]:"spirit-guide-watcher-1"}
func requires_manifestation() -> bool:return false
