extends "res://tests/psychic_parity/connected.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"power-kinetic-bolt",state.party_ids[1]:"lurk-veil",state.party_ids[2]:"power-kinetic-bolt"}
