extends "res://tests/nature_repertoires/journey_driver.gd"
func create_party() -> void:
 configs=[["bard","human",""],["beguiler","human",""],["spirit-shaman","human",""]]
 super.create_party()
func goals_for(index: int) -> Dictionary:
 var nodes: Array=[{"op":"skill","id":"performance"if index==0 else"spellcraft","min":3}]
 if index==0:nodes.append({"op":"feature","id":"bard-rally-1-feature"})
 if index==2:nodes.append({"op":"feature","id":"spirit-guide-watcher-1-access"})
 return {"nodes":nodes,"feats":[]}
func spell_selection(record: Dictionary) -> Dictionary:
 var s: Dictionary=kernel.derive_character(record).snapshot
 var spells: Array=record.choices.prepared_abilities.duplicate()
 if spells.is_empty():
  var suggested := RulesCoreContent.suggested_spells(s,source)
  if not suggested.is_empty():spells.append(suggested[0])
 for id in ["bard-unbinding-refrain","beguiler-unmasking-chime"]:
  if not s.abilities.has(id) or not RulesCoreContent.spell_eligible(s,source.definition("abilities",id)) or spells.has(id):continue
  var cls: String=source.definition("abilities",id).casting_class
  if spells.filter(func(aid: String):return source.definition("abilities",aid).get("casting_class")==cls).size()<RulesCoreContent.selection_limit(cls,int(s.casting_levels[cls]),source):spells.append(id)
 return {"spells":spells,"preparations":{}}
func test_known_authority() -> void:
 for id in state.party_ids:check(kernel.validate_build(state.mechanics.records[id]).ok,"actual earned career validates")
 check(state.mechanics.records[state.party_ids[0]].choices.prepared_abilities.has("bard-unbinding-refrain"),"real level8 Bard learned distinct tier3 relief")
 check(state.mechanics.records[state.party_ids[1]].choices.prepared_abilities.has("beguiler-unmasking-chime"),"real Beguiler learned selected counter-veil")
 var id: String=state.party_ids[2];var r: Dictionary=state.mechanics.records[id]
 var before: Dictionary=r.runtime.resources.duplicate(true);var xp := CharacterBuilderRecords.xp(state,id)
 var writer := CharacterBuilderService.new();writer.store=service.store;writer.library=service.library
 var spells: Array=["spirit-shaman-spirit-refuge-1"]
 var result := writer.operate(entry,slot,"builder_spells",3,{"before_hash":RulesJson.digest(state),"character_id":id,"spells":spells,"preparations":{}})
 check(result.ok,"production writer accepts real home-rest retrieval "+JSON.stringify(result.get("errors",[])))
 if not result.ok:return
 state=result.state
 check(state.mechanics.records[id].runtime.resources["spirit-retrieval"]==0 and before["spirit-retrieval"]==1,"actual earned rest permit consumed once")
 for pool in before:
  if pool!="spirit-retrieval":check(state.mechanics.records[id].runtime.resources[pool]==before[pool],"real retrieval does not restore slots/favour "+pool)
 check(CharacterBuilderRecords.xp(state,id)==xp,"no XP from retrieval")
 var raw := FileAccess.get_file_as_string(service.store._slot_path(slot))
 result=writer.operate(entry,slot,"builder_spells",3,{"before_hash":RulesJson.digest(state),"character_id":id,"spells":["spirit-shaman-spirit-rebuke-1"],"preparations":{}})
 check(not result.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==raw,"second exchange rejects without changing exact saved bytes")
 # Permanent spontaneous choices cannot be exchanged like a Spirit repertoire.
 result=writer.operate(entry,slot,"builder_spells",2,{"before_hash":RulesJson.digest(state),"character_id":state.party_ids[1],"spells":[],"preparations":{}})
 check(not result.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==raw,"actual Beguiler known spells cannot be forgotten")
func test_real_combat() -> void:
 for id in state.party_ids:
  check(CharacterBuilderRecords.xp(state,id)==490 and state.mechanics.records[id].advancement_history.size()==8,"real earned490XP/level8, not20")
