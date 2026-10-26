extends "res://tests/nature_repertoires/journey_driver.gd"
## Three deliberate martial builds through ordinary opportunities and sole writer.
func configure() -> void:configs=[["fighter","human",""],["fighter","human",""],["barbarian","human",""]]
func goals_for(index: int) -> Dictionary:
 return {"nodes":[{"op":"skill","id":"perception"if index==1 else"athletics","min":3}],"feats":["point-blank-shot","weapon-focus","veteran-weapon-training","greater-weapon-focus"]if index==1 else ["weapon-focus","dodge","veteran-weapon-training"]if index==0 else["toughness","iron-will","dodge"]}
func creation_attributes(index: int,_goals: Dictionary) -> Dictionary:
 return {"STR":14,"DEX":15,"CON":13,"INT":12,"WIS":10,"CHA":8}if index==1 else{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var out: Dictionary=planner.advance(record,cls,goals_for(index))
 if not out.ok:return out
 var choice: Dictionary=out.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 for key in choice.specialisations:
  if cls=="fighter" and str(key).begins_with("fighter-choice-"):choice.specialisations[key]="bow"if index==1 else"blade"
  if cls=="barbarian" and str(key).begins_with("barbarian-choice-"):choice.specialisations[key]="reckless"if key=="barbarian-choice-1"else"resilient"
 if (record.advancement_history.size()+1)%4==0:choice.attribute_increase="DEX"if index==1 else"STR"
 return kernel.preview_advancement(record,choice)
func spell_selection(_record: Dictionary) -> Dictionary:return {"spells":[],"preparations":{}}
func prepare(_index: int) -> void:pass
func promote(index: int) -> void:configure();super.promote(index)
func create_party() -> void:
 configure()
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"real source-backed hometown")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id));slot=born.state.playthrough_id
 check(service.store.save_new(slot,born.state,entry.world).ok,"fresh campaign through original save owner")
 action_builder("builder_open");check(RulesRecords.registry(state).rules_ref()==source.rules_ref(),"normal New Game uses latest exact pin")
 for i in 3:
  var cls: String=configs[i][0];var id: String=state.party_ids[i]
  var record := kernel.create(id,creation_attributes(i,goals_for(i)),"heritage-human")
  var step := planned(record,cls,i);check(step.ok,"real legal first level "+cls+JSON.stringify(step.get("errors",[])))
  if not step.ok:return
  record=step.candidate;record.equipment=["bow","leathers"]if i==1 else["shortblade","mail","shield"]if i==0 else["shortblade","leathers"]
  var identity := {"name":["Arin","Lysa","Doran"][i],"people_id":"human","role_id":"expert","origin_burg":int(home.burg_id),"occupation_id":CharacterBuilderRecords.backgrounds(entry.world,int(home.burg_id))[0].id}
  action_builder("builder_save",i+1,{"identity":identity,"build":CharacterBuilderRecords.definition(record)})
 action_builder("builder_ready")
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,"actual three saved martial identities")
 if resumed.ok:state=resumed.state
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==0,"fresh party has no injected XP")
func test_known_authority() -> void:
 configure()
 for i in 3:
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id];var d := kernel.derive_character(r)
  check(d.ok and d.snapshot.class_levels.get(configs[i][0],0)==8,"eight actual earned class levels "+id)
  var first: String="fighter-choice-1"if i<2 else"barbarian-choice-1"
  check(r.advancement_history[0].specialisations[first]==("blade"if i==0 else"bow"if i==1 else"reckless"),"deliberate starting specialisation persisted "+id)
  if i==1:check(r.equipment.has("bow") and d.snapshot.feats.has("point-blank-shot"),"earned ranged equipment and actual feat choice")
  var next := planned(r,str(configs[i][0]),i);check(next.ok,"next permanent class level is legal")
  if next.ok:
   var choice: Dictionary=next.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   check(not CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"selector cannot create missing level9 XP")
func test_real_combat() -> void:
 # The connected worker enters and commits a real fight. This ordinary travel
 # boundary demonstrates home recovery without awarding a second objective.
 var xp: int=CharacterBuilderRecords.xp(state,state.party_ids[0])
 if cycle().results.size()==4:action("cycle_seek")
 var index := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):index=i;break
 check(index>=0,"real unresolved site permits ordinary return/home rest")
 if index>=0:travel(index);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==xp and xp==490,"home recovery never grants XP")
func checkpoint() -> void:
 super.checkpoint()
 var proof := WorldOriginLore.read_json(base.path_join("proof.json"));proof.builds={}
 for i in state.party_ids.size():
  var id: String=state.party_ids[i];var r: Dictionary=state.mechanics.records[id]
  proof.builds[id]={"role":["blade","bow","rage"][i],"equipment":r.equipment,"history":r.advancement_history,"xp":CharacterBuilderRecords.xp(state,id)}
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 if int(proof.earned_xp)%100==0 or int(proof.earned_xp)==490:print("MARTIAL_EARNED_XP ",proof.earned_xp," failures ",failures)
