extends "res://tests/nature_repertoires/journey_driver.gd"
## Original source-backed opportunities and campaign writer, no XP grants.
func configure() -> void:configs=[["monk","human",""],["paladin","human",""],["paladin","human",""]]
func goals_for(index: int) -> Dictionary:
 return {"nodes":[{"op":"skill","id":"acrobatics"if index==0 else"persuasion","min":3}],"feats":["dodge","lightning-reflexes","toughness"]if index==0 else["toughness","great-fortitude","iron-will"]if index==1 else["weapon-focus","toughness","iron-will"]}
func creation_attributes(index: int,_goals: Dictionary) -> Dictionary:
 return {"STR":14,"DEX":13,"CON":12,"INT":10,"WIS":15,"CHA":8}if index==0 else{"STR":14,"DEX":12,"CON":13,"INT":10,"WIS":8,"CHA":15}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var out: Dictionary=planner.advance(record,cls,goals_for(index))
 if not out.ok:return out
 var choice: Dictionary=out.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 for key in choice.specialisations:
  if str(key).begins_with(cls+"-choice-"):choice.specialisations[key]="wind"if index==0 else"mercy"if index==1 else"justice"
 if (record.advancement_history.size()+1)%4==0:choice.attribute_increase="WIS"if index==0 else"CHA"
 return kernel.preview_advancement(record,choice)
func promote(index: int) -> void:configure();super.promote(index)
func create_party() -> void:configure();super.create_party()
func test_known_authority() -> void:
 configure()
 for i in 3:
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id];var d := kernel.derive_character(r)
  check(d.ok and d.snapshot.class_levels.get(configs[i][0],0)==8,"eight genuinely earned career levels "+id)
  var key: String=str(configs[i][0])+"-choice-1"
  check(r.advancement_history[0].specialisations[key]==["wind","mercy","justice"][i],"deliberate starting discipline/oath persists")
  if i>0:check(not r.choices.spell_preparations.is_empty(),"earned Paladin actually prepares divine spells")
  var next := planned(r,str(configs[i][0]),i);check(next.ok,"next permanent level legal")
  if next.ok:
   var choice: Dictionary=next.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   check(not CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"selector cannot invent unfunded ninth-level XP")
func test_real_combat() -> void:
 # A separate connected worker enters, saves, cold-resolves and returns from
 # the earned campaign. This primary campaign boundary grants no duplicate XP.
 var xp: int=CharacterBuilderRecords.xp(state,state.party_ids[0])
 if cycle().results.size()==4:action("cycle_seek")
 var index := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):index=i;break
 check(index>=0,"unresolved ordinary opportunity permits travel and home rest")
 if index>=0:travel(index);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==xp and xp==490,"home recovery awards no XP")
func checkpoint() -> void:
 super.checkpoint()
 var proof := WorldOriginLore.read_json(base.path_join("proof.json"));proof.builds={}
 for i in state.party_ids.size():
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id]
  proof.builds[id]={"role":["wind","mercy","justice"][i],"equipment":r.equipment,"history":r.advancement_history,"xp":CharacterBuilderRecords.xp(state,id)}
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 if int(proof.earned_xp)%100==0 or int(proof.earned_xp)==490:print("MONK_PALADIN_EARNED ",proof.earned_xp," failures ",failures)
