extends "res://tests/nature_repertoires/journey_driver.gd"
## Ordinary objectives and the existing builder writer; no fixture XP or respec.
var entry_witnesses := {}
var configured := false
func journey_xp() -> int:return 640
func journey_level() -> int:return 9
func journey_cycles() -> int:return 20
func configure() -> void:
 configs=[["wizard","human","mystic-theurge"],["sorcerer","human","mystic-theurge"],["duskblade","human","abjurant-champion"]]
 if configured:return
 configured=true
 planner.starting_arrays={"wizard":{"STR":8,"DEX":12,"CON":13,"INT":15,"WIS":14,"CHA":10},"sorcerer":{"STR":8,"DEX":12,"CON":10,"INT":13,"WIS":14,"CHA":15},"duskblade":{"STR":10,"DEX":14,"CON":13,"INT":15,"WIS":12,"CHA":8}}
 if OS.get_environment("GAME126_RESUME")=="1":
  var original := WorldOriginLore.read_json(base.path_join("proof.json"))
  entry_witnesses=original.get("earned_entry_witnesses",{}).duplicate(true)
  failed_check=original.get("failed_check",{}).duplicate(true)
func create_party() -> void:
 configure();super.create_party()
func creation_attributes(index: int,goals: Dictionary) -> Dictionary:
 return planner.attributes_for(str(configs[index][0]),goals.nodes)
func prepare(index: int) -> void:
 configure();super.prepare(index)
func spell_selection(record: Dictionary) -> Dictionary:
 # Reuse the already working prepared/known selection policy; this detached
 # planner never joins a SceneTree and cannot run or write another campaign.
 var selector: Node=load("res://tests/hybrid_acceptance/journey.gd").new();selector.source=source;selector.kernel=kernel
 var selection: Dictionary=selector.spell_selection(record);selector.free();return selection
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var out := super.planned(record,cls,index)
 if not out.ok or cls!="abjurant-champion":return out
 var choice: Dictionary=out.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 for key in choice.specialisations:
  if str(key).begins_with("abjurant-doctrine-"):choice.specialisations[key]="retaliation" if int(source.definition("classes",cls).career_choices.filter(func(g: Dictionary):return g.id==key)[0].at)==1 else "aegis"
 return kernel.preview_advancement(record,choice)
func promote(index: int) -> void:
 if failures:return
 configure()
 var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
 var next: int=record.advancement_history.size()+1
 if next>journey_level() or CharacterBuilderRecords.xp(state,id)<CharacterBuilderRecords.threshold(next,state):return
 var cfg: Array=configs[index];var cls: String=cfg[0];var path: String=cfg[2]
 var base_levels: int=6 if index!=1 else 7
 if index<2 and next>int(3 if index==0 else 4) and next<=base_levels:cls="cleric"
 if next>base_levels:
  check(kernel.available_advancement(record).classes[path].ok,"planned genuine permanent prestige entry "+str(cfg[0])+JSON.stringify(kernel.available_advancement(record).classes[path].get("errors",[])))
  if failures:return
  if not entry_witnesses.has(cfg[0]):
   var decline := planned(record,str(cfg[0]),index);check(decline.ok,"earned character may deliberately decline "+path)
   if decline.ok:
    var choice: Dictionary=decline.candidate.advancement_history.back().duplicate(true);choice.erase("level")
    check(CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"actual earned XP funds continuing the base class instead")
   var file: String="earned-qualified-"+str(cfg[0])+".json"
   FileAccess.open(base.path_join(file),FileAccess.WRITE).store_string(JSON.stringify(state))
   entry_witnesses[cfg[0]]={"character_id":id,"state_hash":RulesJson.digest(state),"file":file,"current_level":record.advancement_history.size(),"next_level":next,"earned_xp":CharacterBuilderRecords.xp(state,id),"class_assigned":false,"path":path}
   check(not kernel.derive_character(record).snapshot.class_levels.has(path),"qualification never automatically changes class")
  cls=path
 var proposal := planned(record,cls,index);check(proposal.ok,"lawful earned next level "+cls+str(next)+JSON.stringify(proposal.get("errors",[])))
 if not proposal.ok:return
 var chosen: Dictionary=proposal.candidate.advancement_history.back().duplicate(true);chosen.erase("level")
 var preview := CharacterBuilderRecords.preview_advancement(state,id,chosen);check(preview.ok,"actual cumulative XP funds manual choice")
 if preview.ok:action_builder("builder_advance",index+1,{"character_id":id,"choice":chosen,"candidate_hash":preview.candidate_hash})
 prepare(index)
func checkpoint() -> void:
 super.checkpoint()
 var proof := WorldOriginLore.read_json(base.path_join("proof.json"));proof.earned_entry_witnesses=entry_witnesses
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 if int(proof.earned_xp)%100==0 or int(proof.earned_xp)==journey_xp():print("DUAL_EARNED_XP ",proof.earned_xp," failures ",failures)
func test_known_authority() -> void:
 check(entry_witnesses.size()==3,"all three actual funded entry witnesses preserved")
 for i in 3:
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id];var d := kernel.derive_character(r)
  check(d.ok and d.snapshot.class_levels.get("mystic-theurge" if i<2 else "abjurant-champion",0)==(2 if i==1 else 3),"genuine earned prestige career "+str(i))
  var proposal := planned(r,str(configs[i][2]),i)
  check(proposal.ok,"next permanent career choice remains available")
  if proposal.ok:
   var choice: Dictionary=proposal.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   check(kernel.preview_advancement(r,choice).ok and not CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"permanent qualification cannot fund next level without earned XP")
 var id: String=state.party_ids[1];var builder := CharacterBuilderService.new();builder.store=service.store;builder.library=service.library
 var raw := FileAccess.get_file_as_string(service.store._slot_path(slot))
 var denied := builder.operate(entry,slot,"builder_spells",2,{"before_hash":RulesJson.digest(state),"character_id":id,"spells":[],"preparations":{}})
 check(not denied.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==raw,"real writer preserves permanent spontaneous knowledge and exact saved bytes")
func test_real_combat() -> void:
 # Connected workers use two isolated real-campaign forks; this unresolved
 # trip tests ordinary eligible home recovery without awarding another event.
 if cycle().results.size()==4:action("cycle_seek")
 var unfinished := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):unfinished=i;break
 check(unfinished>=0,"real unresolved opportunity permits return/home recovery")
 if unfinished>=0:travel(unfinished);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==640 and state.mechanics.records[id].advancement_history.size()==9,"earned640XP/9 only, no high-level fixture substitution")
