extends "res://tests/psychic_parity/journey.gd"
## Actual opportunities and original campaign XP; no free levels or alternate writer.
func create_party() -> void:
 configs=[["psychic-warrior","human",""],["divine-mind","human",""],["psychic-warrior","human","cognition-adept"]]
 # The parent's party factory invokes this method dynamically; use the original
 # nature journey implementation to retain this cohort's configurations.
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"source-backed origin")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id));slot=born.state.playthrough_id
 check(service.store.save_new(slot,born.state,entry.world).ok,"fresh ordinary pinned campaign")
 action_builder("builder_open")
 check(RulesRecords.registry(state).rules_ref()==source.rules_ref(),"fresh campaign default exact current pin")
 for i in 3:
  var cls: String=configs[i][0];var id: String=state.party_ids[i]
  var attribute_goals: Array=goals_for(i).nodes.duplicate(true)
  attribute_goals.push_front({"op":"attribute","id":source.definition("classes",cls).psychic_profile.attribute,"min":11})
  var attrs: Dictionary=planner.attributes_for(cls,attribute_goals)
  var initial := kernel.create(id,attrs,"heritage-human")
  var proposed := planned(initial,cls,i);check(proposed.ok,"ordinary lawful creation "+cls+" index="+str(i)+" attributes="+JSON.stringify(attrs)+" validation="+JSON.stringify(proposed))
  if not proposed.ok:return
  var record: Dictionary=proposed.candidate;record.equipment=source.definition("classes",cls).recommended_equipment.duplicate()
  var identity := {"name":["Kerin","Mara","Tovan"][i],"people_id":"human","role_id":"expert","origin_burg":int(home.burg_id),"occupation_id":CharacterBuilderRecords.backgrounds(entry.world,int(home.burg_id))[0].id}
  action_builder("builder_save",i+1,{"identity":identity,"build":CharacterBuilderRecords.definition(record)})
 action_builder("builder_ready")
 for i in 3:prepare(i)
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,"ready real cohort");state=resumed.get("state",state)
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==0,"starts with zero injected XP")
func goals_for(index: int) -> Dictionary:
 return planner.requirements("cognition-adept",0) if index==2 else {"nodes":[{"op":"skill","id":"arcana","min":3}],"feats":[]}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var proposed: Dictionary=planner.advance(record,cls,goals_for(index))
 if not proposed.ok:return proposed
 var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 var options := {"psychic-warrior-power-1":"power-kinetic-bolt","psychic-warrior-power-2":"power-force-screen","divine-mind-mantle":"energy","divine-mind-mantle-4":"body","divine-mind-power-1":"power-kinetic-bolt","divine-mind-power-2":"power-crystal-shard","divine-mind-power-3":"power-electric-lance","divine-mind-power-4":"power-force-screen","divine-mind-doctrine":"assault","divine-mind-doctrine-5":"bulwark"}
 for group in options:
  if choice.specialisations.has(group):choice.specialisations[group]=options[group]
 return kernel.preview_advancement(record,choice)
func promote(index: int) -> void:
 if failures:return
 var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id];var next: int=record.advancement_history.size()+1
 if next>8 or CharacterBuilderRecords.xp(state,id)<CharacterBuilderRecords.threshold(next,state):return
 var cls: String=configs[index][0]
 if index==2 and kernel.available_advancement(record).classes["cognition-adept"].ok:
  check(planned(record,"psychic-warrior",index).ok,"eligible earned character can decline prestige")
  cls="cognition-adept"
 var proposed := planned(record,cls,index);check(proposed.ok,"legitimate earned choice "+cls+str(next)+JSON.stringify(proposed.get("errors",[])))
 if not proposed.ok:return
 var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 var preview := CharacterBuilderRecords.preview_advancement(state,id,choice);check(preview.ok,"real XP funds deliberate level "+str(next))
 if preview.ok:action_builder("builder_advance",index+1,{"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
 prepare(index)
func test_known_authority() -> void:
 for index in 3:
  var id: String=state.party_ids[index];var r: Dictionary=state.mechanics.records[id]
  var proposed := kernel.suggested_choice(r,str(r.advancement_history.back().class_id))
  check(proposed.ok and not CharacterBuilderRecords.preview_advancement(state,id,proposed.choice).ok,"490 actual XP cannot buy level9")
 check(kernel.derive_character(state.mechanics.records[state.party_ids[2]]).snapshot.class_levels.get("cognition-adept",0)>0,"ordinary adventure XP funds optional cognition prestige, no fixture grants")
