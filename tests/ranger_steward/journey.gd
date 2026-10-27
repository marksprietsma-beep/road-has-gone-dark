extends "res://tests/nature_repertoires/journey_driver.gd"
## Same ordinary source-backed opportunities and sole campaign writer; no XP grants.
var earned_entry := {}
func action_builder(operation: String,member: int=1,extra: Dictionary={}) -> void:
 var chosen := extra.duplicate(true)
 if operation=="builder_save" and member==2:chosen.build.equipment=["shortblade","leathers"]
 super.action_builder(operation,member,chosen)
func configure() -> void:configs=[["ranger","human",""],["ranger","human",""],["ranger","human","beast-steward"]]
func goals_for(index: int) -> Dictionary:
 if index==2:return planner.requirements("beast-steward",0)
 return {"nodes":[{"op":"skill","id":"perception","min":3}],"feats":["weapon-focus","toughness","great-fortitude"]}
func creation_attributes(_index: int,_goals: Dictionary) -> Dictionary:
 return {"STR":13,"DEX":15,"CON":12,"INT":10,"WIS":14,"CHA":8}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var out: Dictionary=planner.advance(record,cls,goals_for(index))
 if not out.ok:return out
 var choice: Dictionary=out.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 for key in choice.specialisations:
  if str(key).begins_with("ranger-choice-"):choice.specialisations[key]="blade"if index==1 else"archery"
  if key=="ranger-companion":choice.specialisations[key]=["wolf","leopard","stag"][index]
  if key=="beast-steward-training":choice.specialisations[key]="swift"
 if (record.advancement_history.size()+1)%4==0:choice.attribute_increase="WIS"
 return kernel.preview_advancement(record,choice)
func promote(index: int) -> void:
 configure()
 if index==2:
  var id: String=state.party_ids[index];var r: Dictionary=state.mechanics.records[id]
  if r.advancement_history.size()==5 and CharacterBuilderRecords.xp(state,id)>=CharacterBuilderRecords.threshold(6,state) and kernel.available_advancement(r).classes["beast-steward"].ok:
   var before := RulesJson.digest(state);var alternatives := {}
   for cls in ["ranger","beast-steward"]:
    var next := planned(r,cls,index);check(next.ok,"earned deliberate prestige entry/decline alternative "+cls)
    if next.ok:
     var choice: Dictionary=next.candidate.advancement_history.back().duplicate(true);choice.erase("level")
     var preview := CharacterBuilderRecords.preview_advancement(state,id,choice);check(preview.ok,"genuine earned XP funds alternative "+cls)
     alternatives[cls]=preview.ok
   check(RulesJson.digest(state)==before and not kernel.derive_character(r).snapshot.class_levels.has("beast-steward"),"funded eligibility and preview never auto-advance")
   earned_entry={"character_id":id,"earned_xp":CharacterBuilderRecords.xp(state,id),"required_xp":CharacterBuilderRecords.threshold(6,state),"alternatives":alternatives,"state_hash":before,"original_history":r.advancement_history}
   FileAccess.open(base.path_join("earned-qualified-steward.json"),FileAccess.WRITE).store_string(JSON.stringify(state))
 super.promote(index)
func create_party() -> void:configure();super.create_party()
func test_known_authority() -> void:
 configure()
 for i in 3:
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id];var d := kernel.derive_character(r)
  check(d.ok and r.advancement_history.size()==8,"eight genuinely earned character levels "+id)
  check(d.snapshot.class_levels.get("ranger",0)==(5 if i==2 else 8),"actual base-class history uses funded optional prestige choices")
  if i==2:check(d.snapshot.class_levels.get("beast-steward",0)==3 and r.advancement_history[5].class_id=="beast-steward","explicit earned prestige entry at6 and advancement to3")
  else:check(not d.snapshot.class_levels.has("beast-steward"),"other Ranger alternatives remain ordinary Rangers")
  check(r.advancement_history[0].specialisations["ranger-choice-1"]==("blade"if i==1 else"archery"),"persistent deliberate combat style")
  check(r.equipment==(["shortblade","leathers"]if i==1 else["bow","leathers"]),"deliberately selected actual blade/ranged equipment persists")
  var pid: String=RulesEntities.identity(id)
  check(r.runtime.companions.size()==1 and r.runtime.companions.has(pid) and r.runtime.companions[pid].definition_id==["wolf","leopard","stag"][i],"same owned selected creature through earned progression")
  check(not r.choices.spell_preparations.is_empty(),"earned Ranger actually prepares nature spells")
  var cls: String="beast-steward"if i==2 else"ranger";var next := planned(r,cls,i);check(next.ok,"next permanent level legal")
  if next.ok:
   var choice: Dictionary=next.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   check(not CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"class selector cannot invent unfunded ninth-level XP")
func test_real_combat() -> void:
 var xp: int=CharacterBuilderRecords.xp(state,state.party_ids[0])
 if cycle().results.size()==4:action("cycle_seek")
 var index := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):index=i;break
 check(index>=0,"unresolved ordinary opportunity permits home recovery")
 if index>=0:travel(index);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==xp and xp==490,"return/rest awards no XP")
func checkpoint() -> void:
 super.checkpoint()
 var proof := WorldOriginLore.read_json(base.path_join("proof.json"));proof.builds={};proof.earned_entry=earned_entry
 for i in state.party_ids.size():
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id]
  proof.builds[id]={"role":["archery","blade","steward"][i],"equipment":r.equipment,"history":r.advancement_history,"companions":r.runtime.companions,"xp":CharacterBuilderRecords.xp(state,id)}
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 if int(proof.earned_xp)%100==0 or int(proof.earned_xp)==490:print("RANGER_STEWARD_EARNED ",proof.earned_xp," failures ",failures)
