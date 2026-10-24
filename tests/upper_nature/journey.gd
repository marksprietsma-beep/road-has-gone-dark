extends "res://tests/nature_repertoires/journey_driver.gd"
## Real ordinary Sorcerer/Druid/Fighter careers:490XP/8, never earned20 claims.
func test_real_combat() -> void:
 if cycle().results.size()==4:action("cycle_seek")
 var unfinished := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):unfinished=i;break
 check(unfinished>=0,"ordinary opportunity permits eligible return/rest")
 if unfinished<0:return
 travel(unfinished);action("cycle_return")
 for id in state.party_ids:
  check(CharacterBuilderRecords.xp(state,id)==490 and state.mechanics.records[id].advancement_history.size()==8,"actual490XP/level8, not upper-tier fixture")
  check(kernel.validate_build(state.mechanics.records[id]).ok,"earned current-pin history validates")
