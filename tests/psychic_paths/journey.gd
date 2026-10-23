extends "res://tests/nature_repertoires/journey_driver.gd"
## Original opportunity/XP/campaign authorities; only acceptance target is larger.
var earned_entries := {}
func journey_xp() -> int:return 810
func journey_level() -> int:return 10
func journey_cycles() -> int:return 24
func create_party() -> void:
 configs=[["psion","human","metamind"],["psion","human","pyrokineticist"],["psion","human",""]]
 super.create_party()
func goals_for(index: int) -> Dictionary:
 return planner.requirements("metamind" if index==0 else "pyrokineticist",0) if index<2 else {"nodes":[{"op":"skill","id":"arcana","min":4}],"feats":[]}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var proposal: Dictionary=planner.advance(record,cls,goals_for(index))
 if not proposal.ok:return proposal
 var choice: Dictionary=proposal.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 var options := {"psion-power-1":"power-kinetic-bolt","psion-second-power":"power-force-screen","psion-power-2":"power-thought-thrust","psion-power-4":"power-body-renewal","metamind-discipline-1":"reserve","metamind-power-1":"power-mind-lock"}
 for group in options:
  if choice.specialisations.has(group):choice.specialisations[group]=options[group]
 return kernel.preview_advancement(record,choice)
func spell_selection(_record: Dictionary) -> Dictionary:return {"spells":[],"preparations":{}}
func promote(index: int) -> void:
 if index<2 and failures==0:
  var path: String=configs[index][2];var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
  var next: int=record.advancement_history.size()+1
  if not earned_entries.has(path) and CharacterBuilderRecords.xp(state,id)>=CharacterBuilderRecords.threshold(next,state) and kernel.available_advancement(record).classes[path].ok:
   var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("entry-"+path).path_join("saves")
   check(fork.save_new(slot,state,entry.world).ok,"preserve actual funded entry through original writer "+path)
   earned_entries[path]={"member":index,"character_id":id,"save_root":fork.save_root,"state_hash":RulesJson.digest(state),"earned_xp":CharacterBuilderRecords.xp(state,id),"next_level":next,"fixture":false}
 super.promote(index)
func checkpoint() -> void:
 super.checkpoint()
 var proof := WorldOriginLore.read_json(base.path_join("proof.json"));proof.earned_entries=earned_entries
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
func finish_journey(restart := false) -> void:
 if restart:
  var proof := WorldOriginLore.read_json(base.path_join("proof.json"))
  for path in proof.earned_entries:
   var row: Dictionary=proof.earned_entries[path];var fork := GamePlaythroughStore.new();fork.save_root=row.save_root
   var loaded := fork.load_save(slot,entry.world)
   check(loaded.ok and RulesJson.digest(loaded.state)==row.state_hash,"exact cold funded pre-entry campaign "+path)
 super.finish_journey(restart)
func test_known_authority() -> void:
 for i in 3:
  var id: String=state.party_ids[i];var record: Dictionary=state.mechanics.records[id]
  var cls: String="metamind" if i==0 else "pyrokineticist" if i==1 else "psion"
  var proposal := kernel.suggested_choice(record,cls)
  check(proposal.ok and not CharacterBuilderRecords.preview_advancement(state,id,proposal.choice).ok,"810 genuine XP cannot fund level11 at1000")
  check(CharacterBuilderRecords.xp(state,id)==810 and record.advancement_history.size()==10,"actual total10/810XP, not a level20 development fixture")
 check(kernel.derive_character(state.mechanics.records[state.party_ids[0]]).snapshot.class_levels.metamind==2,"ordinary XP funds Metamind entry9 and second path level10")
 check(kernel.derive_character(state.mechanics.records[state.party_ids[1]]).snapshot.class_levels.pyrokineticist==5,"ordinary XP funds five optional Pyrokineticist levels")
func test_real_combat() -> void:
 # The connected phase owns actual combat; this journey ends with an eligible
 # original home return/rest without granting any extra XP.
 if cycle().results.size()==4:action("cycle_seek")
 var index := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):index=i;break
 check(index>=0,"unresolved real opportunity provides eligible return/rest")
 if index<0:return
 travel(index);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==810,"return/rest never grants XP")
