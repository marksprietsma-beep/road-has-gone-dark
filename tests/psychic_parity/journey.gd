extends "res://tests/nature_repertoires/journey_driver.gd"
## Existing opportunity cycle, original XP authority and one campaign writer.
func create_party() -> void:
 configs=[["psion","human",""],["wilder","human",""],["psion","human","cerebremancer"]]
 super.create_party()
func goals_for(index: int) -> Dictionary:
 return {"nodes":[{"op":"skill","id":"arcana","min":4},{"op":"skill","id":"spellcraft","min":3}],"feats":["psychic-discipline"] if index==2 else []}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var proposed := planner.advance(record,cls,goals_for(index))
 if not proposed.ok:return proposed
 var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 var options := {"psion-discipline":"assault" if index==0 else "ward","psion-power-1":"power-kinetic-bolt","psion-second-power":"power-force-screen","psion-power-2":"power-thought-thrust","psion-power-4":"power-mind-lock","psion-power-6":"power-energy-surge","psion-power-8":"power-vital-exchange","wilder-power-1":"power-kinetic-bolt","wilder-power-2":"power-force-screen","wilder-power-4":"power-mind-lock","wilder-power-6":"power-energy-surge","wilder-power-8":"power-vital-exchange","cerebremancer-casting":"wizard","cerebremancer-power-1":"power-electric-lance"}
 for group in options:
  if choice.specialisations.has(group):choice.specialisations[group]=options[group]
 return kernel.preview_advancement(record,choice)
func spell_selection(record: Dictionary) -> Dictionary:
 var snapshot: Dictionary=kernel.derive_character(record).snapshot
 var copies := RulesCoreContent.starting_preparations(snapshot,source)
 return {"spells":copies.keys(),"preparations":copies}
func promote(index: int) -> void:
 if failures:return
 var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
 var next: int=record.advancement_history.size()+1
 if next>8 or CharacterBuilderRecords.xp(state,id)<CharacterBuilderRecords.threshold(next,state):return
 var cls: String="wilder" if index==1 else "psion"
 if index==2 and next in [4,5,6]:cls="wizard"
 if index==2 and next>=7:
  var eligible: Dictionary=kernel.available_advancement(record).classes.cerebremancer
  check(eligible.ok,"actually earned hybrid meets complete permanent prerequisites "+JSON.stringify(eligible.get("errors",[])))
  if not eligible.ok:return
  var before := RulesJson.digest(record)
  check(planned(record,"psion",index).ok and RulesJson.digest(record)==before,"actually qualified character can decline prestige without automatic assignment")
  cls="cerebremancer"
 var proposed := planned(record,cls,index)
 check(proposed.ok,"legal earned class/power choice "+cls+str(next)+JSON.stringify(proposed.get("errors",[])))
 if not proposed.ok:return
 var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 var preview := CharacterBuilderRecords.preview_advancement(state,id,choice)
 check(preview.ok,"earned XP pays for deliberate advancement "+cls+str(next)+str(preview.get("error",preview.get("errors",[]))))
 if preview.ok:action_builder("builder_advance",index+1,{"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
 prepare(index)
func test_known_authority() -> void:
 for index in 3:
  var id: String=state.party_ids[index];var r: Dictionary=state.mechanics.records[id];var before := FileAccess.get_file_as_string(service.store._slot_path(slot))
  var cls: String="wilder" if index==1 else "cerebremancer" if index==2 else "psion"
  var proposed := kernel.suggested_choice(r,cls)
  check(proposed.ok,"next level is mechanically available, distinct from XP funding")
  if proposed.ok:check(not CharacterBuilderRecords.preview_advancement(state,id,proposed.choice).ok,"490 earned XP cannot pay for level9")
  check(FileAccess.get_file_as_string(service.store._slot_path(slot))==before,"failed funding preview changes neither save nor XP")
 var hybrid: Dictionary=state.mechanics.records[state.party_ids[2]]
 check(kernel.derive_character(hybrid).snapshot.class_levels.cerebremancer==2,"ordinary opportunities fund actual optional prestige levels")
func test_real_combat() -> void:
 # Actual saved campaign commands/cold/rest are the connected phase, not fixtures.
 if cycle().results.size()==4:action("cycle_seek")
 var unfinished := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):unfinished=i;break
 check(unfinished>=0,"real unresolved opportunity allows normal return/rest")
 if unfinished<0:return
 travel(unfinished);action("cycle_return")
 for id in state.party_ids:
  check(CharacterBuilderRecords.xp(state,id)==490 and state.mechanics.records[id].advancement_history.size()==8,"actual level8/490XP earned career, never20")
  check(kernel.validate_build(state.mechanics.records[id]).ok,"earned psychic and hybrid history remains valid")
