extends "res://tests/nature_repertoires/journey_driver.gd"
## All advancement funded by ordinary opportunity outcomes. No fixture XP.
func create_party() -> void:
 configs=[["swashbuckler","human","duelist"],["rogue","human","arcane-trickster"],["wizard","human",""]]
 super.create_party()
func goals_for(index: int) -> Dictionary:
 var path: String=configs[index][2]
 return planner.requirements(path,0) if not path.is_empty() else {"nodes":[],"feats":[]}
func promote(index: int) -> void:
 if failures:return
 var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
 var next: int=record.advancement_history.size()+1
 if next>8 or CharacterBuilderRecords.xp(state,id)<CharacterBuilderRecords.threshold(next,state):return
 var cfg: Array=configs[index];var cls: String=cfg[0];var path: String=cfg[2]
 if path=="arcane-trickster" and next in [2,3,4]:cls="wizard"
 if not path.is_empty() and kernel.available_advancement(record).classes[path].ok:
  var before := RulesJson.digest(record)
  var decline := planned(record,cls,index)
  check(decline.ok and RulesJson.digest(record)==before,"earned qualified character may decline prestige without auto-assignment "+path)
  cls=path
 var proposal := planned(record,cls,index)
 check(proposal.ok,"lawful XP-funded manual prestige route "+cls+str(next)+JSON.stringify(proposal.get("errors",[])))
 if not proposal.ok:return
 var choice: Dictionary=proposal.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 var preview := CharacterBuilderRecords.preview_advancement(state,id,choice)
 check(preview.ok,"existing XP authority accepts selected career only when funded")
 if preview.ok:action_builder("builder_advance",index+1,{"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
 prepare(index)
func test_known_authority() -> void:
 for i in 3:
  var r: Dictionary=state.mechanics.records[state.party_ids[i]]
  check(kernel.validate_build(r).ok,"earned prestige history validates")
  if i<2:
   var path: String=configs[i][2]
   check(r.advancement_history[0].class_id==configs[i][0] and kernel.derive_character(r).snapshot.class_levels.has(path),"prestige genuinely earned after base career "+path)
func test_real_combat() -> void:
 # Actual campaign combat is separately exercised; do not inject levels here.
 for id in state.party_ids:
  check(CharacterBuilderRecords.xp(state,id)==490 and state.mechanics.records[id].advancement_history.size()==8,"real490XP funds eight ordered levels")
