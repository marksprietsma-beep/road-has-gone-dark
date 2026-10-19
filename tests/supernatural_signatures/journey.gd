extends "res://tests/nature_repertoires/journey_driver.gd"
func create_party() -> void:
 configs=[["warlock","human",""],["binder","human",""],["dragonfire-adept","human",""]]
 super.create_party()
func goals_for(index: int) -> Dictionary:
 var nodes: Array=[{"op":"skill","id":"arcana","min":3}]
 if index==1:nodes.append({"op":"feature","id":"binder-sentinel-pact"})
 return {"nodes":nodes,"feats":[]}
func test_known_authority() -> void:
 for id in state.party_ids:check(kernel.validate_build(state.mechanics.records[id]).ok,"earned supernatural identity valid")
 var bound := kernel.derive_character(state.mechanics.records[state.party_ids[1]]).snapshot
 check(bound.abilities.has("binder-sentinel") and not bound.abilities.has("binder-embers"),"deliberate permanent Sentinel covenant selected through ordinary creator")
func test_real_combat() -> void:
 # The connected phase enters and cold-resolves an actual saved campaign battle.
 for id in state.party_ids:
  check(CharacterBuilderRecords.xp(state,id)==490,"normal objectives fund490 XP")
  check(state.mechanics.records[id].advancement_history.size()==8,"earned level8, not20")
