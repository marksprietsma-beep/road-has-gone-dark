extends "res://tests/nature_repertoires/journey_driver.gd"
func create_party() -> void:
 configs=[["wizard","human",""],["cleric","human",""],["fighter","human",""]]
 super.create_party()
func goals_for(index: int) -> Dictionary:
 var nodes: Array=[{"op":"skill","id":"spellcraft" if index<2 else "athletics","min":3}]
 if index==0:nodes.append({"op":"feature","id":"wizard-abjuration-1-feature"})
 if index==1:nodes.append({"op":"feature","id":"cleric-war-1-feature"})
 return {"nodes":nodes,"feats":[]}
func spell_selection(record: Dictionary) -> Dictionary:
 var snapshot: Dictionary=kernel.derive_character(record).snapshot
 var copies := RulesCoreContent.starting_preparations(snapshot,source)
 for wanted in ["wizard-gravitic-snare","cleric-freedom-path"]:
  if not snapshot.abilities.has(wanted):continue
  var cls: String=source.definition("abilities",wanted).casting_class
  for id in copies.keys().duplicate():
   var row := source.definition("abilities",id)
   if row.get("casting_class")==cls and int(row.spell_tier)==4:copies.erase(id)
  copies[wanted]=1
 return {"spells":copies.keys(),"preparations":copies}
func test_known_authority() -> void:
 for index in [0,1]:
  var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
  var cls: String="wizard" if index==0 else "cleric"
  var wanted: String="wizard-gravitic-snare" if index==0 else "cleric-freedom-path"
  # Explicit isolated backend fixture: actual effect cost and trusted runtime
  # transition, never a claim that production offers casting while at home.
  var spent := RulesEffects.new(source).use_ability(record,state.mechanics.records[state.party_ids[2]],wanted,{"main":1,"move":1,"reaction":1},RulesRng.initial("prepared-no-refill"))
  check(spent.ok,"real spell cost for isolated no-refill fixture "+cls)
  if not spent.ok:return
  var transition := RulesRecords.preview_runtime(state,id,spent.actor.runtime)
  check(transition.ok,"fixture uses existing trusted runtime transition")
  if not transition.ok:return
  var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("preparation-"+cls)
  check(fork.save_new(slot,transition.candidate,entry.world).ok,"fixture uses sole campaign save owner")
  var writer := CharacterBuilderService.new();writer.store=fork;writer.library=service.library
  var snapshot: Dictionary=kernel.derive_character(record).snapshot
  var alternatives: Array=snapshot.abilities.filter(func(aid: String):return source.definition("abilities",aid).get("casting_class")==cls and int(source.definition("abilities",aid).get("spell_tier",0))==4 and aid!=wanted and RulesCoreContent.spell_eligible(snapshot,source.definition("abilities",aid)))
  check(not alternatives.is_empty(),"earned caster has a real different tier4 preparation")
  if alternatives.is_empty():return
  var copies: Dictionary=record.choices.spell_preparations.duplicate();copies.erase(wanted);copies[alternatives[0]]=1
  var before: Dictionary=transition.candidate.mechanics.records[id].runtime.resources.duplicate(true)
  var result := writer.operate(entry,slot,"builder_spells",index+1,{"before_hash":RulesJson.digest(transition.candidate),"character_id":id,"spells":copies.keys(),"preparations":copies})
  check(result.ok,"actual preparation save accepts changed legal repertoire "+JSON.stringify(result.get("errors",[])))
  if not result.ok:return
  var current_record: Dictionary=result.state.mechanics.records[id]
  var capacities: Dictionary=kernel.derive_character(current_record).snapshot.resource_capacities
  for pool in before:
   var expected: int=int(capacities[pool]) if source.definition("resources",pool).has("prepared_ability") else int(before[pool])
   check(int(current_record.runtime.resources[pool])==expected,"home preparation follows exact copy-allocation versus shared-slot policy "+pool)
  check(CharacterBuilderRecords.xp(result.state,id)==490,"preparation grants no XP")
  var raw := FileAccess.get_file_as_string(fork._slot_path(slot))
  copies[alternatives[0]]=int(snapshot.resource_capacities[cls+"-slots-4"])+1
  var rejected := writer.operate(entry,slot,"builder_spells",index+1,{"before_hash":RulesJson.digest(result.state),"character_id":id,"spells":copies.keys(),"preparations":copies})
  check(not rejected.ok and RulesJson.canonical(rejected).contains("spell.preparation_budget") and FileAccess.get_file_as_string(fork._slot_path(slot))==raw,"production rejects over-budget copies and retains exact saved bytes")
func test_real_combat() -> void:
 # Refresh through a real unresolved expedition return. The separate connected
 # phase uses actual campaign battle commands, not a bare tactical simulation.
 if cycle().results.size()==4:action("cycle_seek")
 var unfinished := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):unfinished=i;break
 check(unfinished>=0,"real unresolved opportunity permits eligible return/rest")
 if unfinished<0:return
 travel(unfinished);action("cycle_return")
 for id in state.party_ids:
  check(CharacterBuilderRecords.xp(state,id)==490 and state.mechanics.records[id].advancement_history.size()==8,"actual490XP/level8 earned career, not20")
  check(kernel.validate_build(state.mechanics.records[id]).ok,"actual earned history validates")

