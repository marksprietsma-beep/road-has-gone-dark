extends "res://tests/class_signatures/connected_driver.gd"
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"bard-rally-1",state.party_ids[1]:"beguiler-unmasking-chime",state.party_ids[2]:"spirit-shaman-spirit-refuge-1"}
func requires_manifestation() -> bool:return false

func expected_resolved_pool(saved: Dictionary,battle: Dictionary,id: String,pool: String) -> int:
 if pool!="performance":return super.expected_resolved_pool(saved,battle,id,pool)
 # Mid-battle cold load is still exact. Later legitimate activations must pay
 # continued upkeep; account exactly from the new authoritative command log.
 var amount: int=int(source.definition("statuses","bard-rally-1-status").upkeep.amount)
 var marker: String=str(battle.units[id].name)+" maintains the performance; "+str(source.definition("resources",pool).name)+" -"+str(amount)+"."
 var ticks: int=battle.log.slice(int(saved.battle_log_length)).filter(func(line: String):return line.begins_with(marker)).size()
 return int(saved.resources[id][pool])-ticks*amount
