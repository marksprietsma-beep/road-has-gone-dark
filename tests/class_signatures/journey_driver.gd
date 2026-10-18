extends "res://tests/nature_repertoires/journey_driver.gd"
## Same ordinary deterministic opportunities/writer; a different real party.
func create_party() -> void:
 configs=[["soulknife","human",""],["warblade","human",""],["swordsage","human",""]]
 super.create_party()
func goals_for(_index: int) -> Dictionary:
 return {"nodes":[{"op":"skill","id":"acrobatics","min":3}],"feats":[]}
func test_known_authority() -> void:
 for id in state.party_ids:
  check(kernel.validate_build(state.mechanics.records[id]).ok,"earned martial identity valid")
  check(not state.mechanics.records[id].advancement_history.any(func(s: Dictionary):return source.definition("classes",s.class_id).class_kind=="prestige"),"qualification does not automatically assign prestige")
func test_real_combat() -> void:
 # The separate connected phase enters, writes and cold-resolves a real battle.
 # Do not substitute a direct unsaved engine match for that campaign witness.
 for i in 3:
  var id: String=state.party_ids[i]
  check(CharacterBuilderRecords.xp(state,id)==490,"all advancement funded by49 real objectives")
  check(state.mechanics.records[id].advancement_history.size()==8,"earned level8 history")
 configs=[["soulknife","human",""],["warblade","human",""],["swordsage","human",""]]
