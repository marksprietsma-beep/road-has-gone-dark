extends "res://tests/nature_repertoires/journey_driver.gd"
## Ordinary opportunities and original campaign writer; no XP grants or edited histories.
var earned_entries := {}
var retrieval_proof := {}
func configure() -> void:configs=[["spirit-shaman","human","grove-warden"],["wizard","human","bonded-summoner"],["druid","human","grove-warden"]]
func journey_xp() -> int:return 810
func journey_level() -> int:return 10
func journey_cycles() -> int:return 24
func create_party() -> void:configure();super.create_party()
func goals_for(index: int) -> Dictionary:
 configure();return planner.requirements(configs[index][2],0)
func creation_attributes(index: int,_goals: Dictionary) -> Dictionary:
 return {"STR":8,"DEX":12,"CON":13,"INT":15,"WIS":14,"CHA":10}if index==1 else{"STR":10,"DEX":12,"CON":13,"INT":14,"WIS":15,"CHA":8}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var out: Dictionary=planner.advance(record,cls,goals_for(index))
 if not out.ok:return out
 var choice: Dictionary=out.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 for group in choice.specialisations:
  if group=="grove-casting":choice.specialisations[group]="druid"if index==2 else"spirit-shaman"
  if group=="bonded-casting":choice.specialisations[group]="wizard"
  if group=="druid-companion":choice.specialisations[group]="leopard"
 if (record.advancement_history.size()+1)%4==0:choice.attribute_increase="INT"if index==1 else"WIS"
 return kernel.preview_advancement(record,choice)
func spell_selection(record: Dictionary) -> Dictionary:
 # Reuse the already-verified selection helper; only choices go to the real
 # builder operation. Its fixture recovery never writes runtime into a campaign.
 var helper: Node=load("res://tests/dual_prestige_acceptance/base.gd").new();helper.source=source;helper.kernel=kernel
 var selected: Dictionary=helper.learn(record);check(helper.failures==0 and not selected.is_empty(),"existing legal known/prepared/retrieved selection policy")
 helper.free()
 if selected.is_empty():return {"spells":[],"preparations":{}}
 return {"spells":selected.choices.prepared_abilities,"preparations":selected.choices.spell_preparations}
func promote(index: int) -> void:
 if failures:return
 configure();var id: String=state.party_ids[index];var r: Dictionary=state.mechanics.records[id];var next: int=r.advancement_history.size()+1
 if next>10 or CharacterBuilderRecords.xp(state,id)<CharacterBuilderRecords.threshold(next,state):return
 var cls: String="spirit-shaman"if index==0 else"wizard"if index==1 else"spirit-shaman"if next==2 else"druid"
 var path: String=configs[index][2]
 if kernel.available_advancement(r).classes[path].ok:
  var before := RulesJson.digest(state);var alternatives := {}
  for selected in [cls,path]:
   var preview: Dictionary=planned(r,selected,index);check(preview.ok,"earned legal prestige or decline "+selected)
   if preview.ok:
    var choice: Dictionary=preview.candidate.advancement_history.back().duplicate(true);choice.erase("level")
    var funded: Dictionary=CharacterBuilderRecords.preview_advancement(state,id,choice)
    check(funded.ok,"actual XP funds deliberately selected alternative "+selected)
    alternatives[selected]=funded.ok
  check(RulesJson.digest(state)==before,"eligibility and selection previews neither advance nor grant XP")
  if not kernel.derive_character(r).snapshot.class_levels.has(path):
   earned_entries[id]={"member_index":index,"character_id":id,"path":path,"parent":cls,"earned_xp":CharacterBuilderRecords.xp(state,id),"required_xp":CharacterBuilderRecords.threshold(next,state),"original_history":r.advancement_history,"alternatives":alternatives,"state_hash":before}
   FileAccess.open(base.path_join("earned-entry-"+str(index)+".json"),FileAccess.WRITE).store_string(JSON.stringify(state))
   var decline: Dictionary=planned(r,cls,index);var declined_choice: Dictionary=decline.candidate.advancement_history.back().duplicate(true);declined_choice.erase("level")
   var reviewed: Dictionary=CharacterBuilderRecords.preview_advancement(state,id,declined_choice)
   var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("declined-"+str(index));check(fork.save_new(slot,state,entry.world).ok,"earned decline fork uses sole save authority")
   var builder := CharacterBuilderService.new();builder.store=fork;builder.library=service.library
   var declined: Dictionary=builder.operate(entry,slot,"builder_advance",index+1,{"before_hash":before,"character_id":id,"choice":declined_choice,"candidate_hash":reviewed.candidate_hash})
   check(declined.ok,"qualified player really commits decline through production advancement")
   if declined.ok:
    var actual: Dictionary=fork.load_save(slot,entry.world)
    check(actual.ok and not actual.state.mechanics.records[id].advancement_history.any(func(step: Dictionary):return step.class_id==path) and CharacterBuilderRecords.xp(actual.state,id)==earned_entries[id].earned_xp,"committed decline advances base class with the same legitimately earned XP")
    earned_entries[id].decline_committed=true;earned_entries[id].decline_hash=RulesJson.digest(actual.state)
   check(RulesJson.digest(state)==before,"separate decline never edits the primary choice or grants XP")
  cls=path
 var proposal: Dictionary=planned(r,cls,index);check(proposal.ok,"actual funded progression "+cls+str(next)+JSON.stringify(proposal.get("errors",[])))
 if not proposal.ok:return
 var choice: Dictionary=proposal.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 var preview: Dictionary=CharacterBuilderRecords.preview_advancement(state,id,choice)
 check(preview.ok,"single XP authority accepts explicit level choice")
 if preview.ok:action_builder("builder_advance",index+1,{"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
 prepare(index)
func test_known_authority() -> void:
 for i in 3:
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id];var d: Dictionary=kernel.derive_character(r)
  check(d.ok and r.advancement_history.size()==10 and CharacterBuilderRecords.xp(state,id)==810,"actual ten levels from810 earnedXP")
  if i==1:check(d.snapshot.class_levels.wizard==5 and d.snapshot.class_levels["bonded-summoner"]==5 and d.snapshot.casting_levels.wizard==10,"all five Bonded levels genuinely earned with actual Wizard advancement")
  else:check(d.snapshot.class_levels["grove-warden"]==3,"all three Grove levels genuinely earned")
  if i==0:check(d.snapshot.class_levels["spirit-shaman"]==7 and d.snapshot.casting_levels["spirit-shaman"]==10,"selected Spirit Shaman progression/retrieval remains real")
  if i==2:
   check(d.snapshot.class_levels.druid==6 and d.snapshot.class_levels["spirit-shaman"]==1 and d.snapshot.casting_levels.druid==9,"deliberate lawful bridge advances only the selected Druid")
   check(r.runtime.companions.values()[0].definition_id=="leopard","actual persistent chosen companion, not a permanent summon")
  check(earned_entries.has(id),"actual funded pre-entry choice/decline state retained")
  if earned_entries.has(id):
   check(earned_entries[id].earned_xp==earned_entries[id].required_xp and earned_entries[id].required_xp==(250 if i==1 else 360),"correct distinct earliest earned entry threshold")
  var cls: String="wizard"if i==1 else"druid"if i==2 else"spirit-shaman"
  var next: Dictionary=planned(r,cls,i);check(next.ok,"unfunded next permanent level is mechanically legal")
  if next.ok:
   var choice: Dictionary=next.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   check(not CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"selector cannot create unfunded level11 XP")
func home_without_rewards() -> void:
 var xp: int=CharacterBuilderRecords.xp(state,state.party_ids[0])
 if cycle().results.size()==4:action("cycle_seek")
 var index := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):index=i;break
 check(index>=0,"unresolved source-backed trip for eligible home recovery")
 if index>=0:travel(index);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==xp and xp==810,"home recovery never grants XP")
func test_real_combat() -> void:
 # Connected tactical commands and independent cold resolution are a separate
 # phase using a fork of this exact earned save, not a rebuilt fixture.
 home_without_rewards()
 var id: String=state.party_ids[0];var r: Dictionary=state.mechanics.records[id];var d: Dictionary=kernel.derive_character(r)
 var pool: String=source.definition("classes","spirit-shaman").retrieval_resource
 var candidates: Array=d.snapshot.abilities.filter(func(aid: String):var a: Dictionary=source.definition("abilities",aid);return a.get("casting_class")=="spirit-shaman" and a.tags.has("spell") and RulesCoreContent.spell_eligible(d.snapshot,a) and not r.choices.prepared_abilities.has(aid))
 check(not candidates.is_empty() and r.runtime.resources[pool]==1,"earned prestige parent has real eligible home retrieval choice")
 if candidates.is_empty():return
 var selected: Array=r.choices.prepared_abilities.duplicate();selected.remove_at(0);selected.append(candidates[0])
 var old_slots: Dictionary=r.runtime.resources.duplicate(true)
 action_builder("builder_spells",1,{"character_id":id,"spells":selected,"preparations":r.choices.spell_preparations})
 check(state.mechanics.records[id].choices.prepared_abilities==selected and state.mechanics.records[id].runtime.resources[pool]==0,"real production operation commits one rest-based retrieval and consumes its permit")
 for resource in old_slots:
  if resource!=pool:check(state.mechanics.records[id].runtime.resources[resource]==old_slots[resource],"retrieval does not refill casting slots or Grove Favour")
 var raw := FileAccess.get_file_as_string(service.store._slot_path(slot));var builder := CharacterBuilderService.new();builder.store=service.store;builder.library=service.library
 var denied: Dictionary=builder.operate(entry,slot,"builder_spells",1,{"before_hash":RulesJson.digest(state),"character_id":id,"spells":r.choices.prepared_abilities,"preparations":r.choices.spell_preparations})
 check(not denied.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==raw,"second retrieval denied with exact saved bytes intact")
 retrieval_proof={"character_id":id,"before":r.choices.prepared_abilities,"after":selected,"spent":state.mechanics.records[id].runtime.resources[pool],"second_change_rejected":not denied.ok}
 home_without_rewards();check(state.mechanics.records[id].runtime.resources[pool]==1 and state.mechanics.records[id].choices.prepared_abilities==selected,"eligible home rest restores retrieval permit without forgetting the selected set")
 retrieval_proof.recovered=state.mechanics.records[id].runtime.resources[pool]
func checkpoint() -> void:
 super.checkpoint()
 var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));proof.earned_entries=earned_entries;proof.retrieval=retrieval_proof;proof.builds={}
 for i in state.party_ids.size():
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id]
  proof.builds[id]={"role":["grove-shaman","bonded-wizard","grove-druid"][i],"history":r.advancement_history,"choices":r.choices,"companions":r.runtime.companions,"xp":CharacterBuilderRecords.xp(state,id)}
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 if int(proof.earned_xp)%100==0 or int(proof.earned_xp)==810:print("GROVE_SUMMONER_EARNED ",proof.earned_xp," failures ",failures)

func finish_journey(restart := false) -> void:
 if restart:
  var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"))
  for info in proof.earned_entries.values():
   var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("declined-"+str(int(info.member_index)))
   var actual: Dictionary=fork.load_save(slot,entry.world)
   check(actual.ok and info.decline_committed and RulesJson.digest(actual.state)==info.decline_hash,"actual XP-funded decline survives an independent cold process")
 super.finish_journey(restart)
