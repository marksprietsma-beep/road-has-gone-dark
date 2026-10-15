extends "res://tests/adventure_cycles/earned_driver.gd"
signal completed
var no_quit := false
## Ordinary opportunities fund manual War Chanter entry. Never writes XP or synthetic history.
func run() -> void:
 base=OS.get_environment("GAME112W4_TEST_ROOT").path_join("earned-cohort");DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 if OS.get_environment("GAME112W4_RESTART")=="1":
  var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
  var loaded := service.operate(entry,slot,"resume")
  check(loaded.ok and RulesJson.digest(loaded.state)==proof.state_hash,"earned prestige exact process restart")
  if loaded.ok:check(loaded.state.mechanics.records[loaded.state.party_ids[0]].advancement_history.back().class_id=="war-chanter","manual earned path persisted")
  var alternate := GamePlaythroughStore.new();alternate.save_root=base.path_join("declined")
  var declined := alternate.load_save(slot,entry.world)
  check(declined.ok and RulesJson.digest(declined.state)==proof.declined_hash,"earned base-class decline exact process restart")
  finish();return
 create_party()
 if failures>0:finish();return
 var id: String=state.party_ids[0]
 check(CharacterBuilderRecords.xp(state,id)==0,"ordinary campaign begins with no injected XP")
 var declined_hash := ""
 for cycle_index in 12:
  action("cycle_seek")
  for i in 4:
   travel(i)
   if failures>0:finish();return
   var site := SandboxRecords.site(cycle(),cycle().active.site_id)
   var before_xp := CharacterBuilderRecords.xp(state,id)
   action("cycle_activity",{"choice":"negotiate"if OpportunityGenerator.template(site.activity_id).family=="contested"else"careful"})
   check(CharacterBuilderRecords.xp(state,id)==before_xp+10,"one actual objective reward")
   reject("cycle_activity",{"choice":"careful"})
   action("cycle_return")
   var record: Dictionary=state.mechanics.records[id]
   var kernel := RulesCharacter.new(RulesRecords.registry(state))
   var next: int=record.advancement_history.size()+1
   if next>7 or CharacterBuilderRecords.xp(state,id)<10*(next-1)*(next-1):continue
   var cls: String="war-chanter"if next==7 else"marshal"
   if next==7:
    var before := RulesJson.digest(state)
    check(kernel.available_advancement(record).classes["war-chanter"].ok,"permanent earned prerequisites qualify optional prestige")
    check(not kernel.derive_character(record).snapshot.class_levels.has("war-chanter"),"qualification never assigns a class")
    var choice: Dictionary=kernel.suggested_choice(record,"marshal").choice
    var preview := CharacterBuilderRecords.preview_advancement(state,id,choice)
    check(preview.ok,"genuinely funded optional base continuation")
    var alternate := GamePlaythroughStore.new();alternate.save_root=base.path_join("declined")
    check(alternate.save_new(slot,state,entry.world).ok,"original writer preserves funded alternate")
    var writer := CharacterBuilderService.new();writer.store=alternate;writer.library=service.library
    var commit := writer.operate(entry,slot,"builder_advance",1,{"before_hash":before,"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
    check(commit.ok,"explicit decline remains a base class")
    if commit.ok:
     declined_hash=RulesJson.digest(commit.state)
     check(commit.state.mechanics.records[id].advancement_history.back().class_id=="marshal"and CharacterBuilderRecords.xp(commit.state,id)==before_xp+10,"decline grants no XP or automatic prestige")
    check(RulesJson.digest(state)==before,"alternate never mutates original campaign")
   var choice := promotion(kernel,record,cls)
   var preview := CharacterBuilderRecords.preview_advancement(state,id,choice)
   check(preview.ok,"earned preview "+cls+str(next)+JSON.stringify(preview.get("errors",[])))
   if not preview.ok:finish();return
   action_builder("builder_advance",1,{"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
   check(CharacterBuilderRecords.xp(state,id)==before_xp+10,"advancement selector grants no XP")
   if failures>0:finish();return
  if state.mechanics.records[id].advancement_history.size()>=7:break
 var record: Dictionary=state.mechanics.records[id]
 check(record.advancement_history.size()==7 and record.advancement_history.back().class_id=="war-chanter","legitimate XP-funded manual prestige")
 var snapshot := RulesCharacter.new(RulesRecords.registry(state)).derive_character(record)
 check(snapshot.ok and snapshot.snapshot.abilities.has("chorus-courage"),"earned chorus becomes an actual ability")
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":RulesRecords.registry(state).rules_ref(),"state_hash":RulesJson.digest(state),"declined_hash":declined_hash,"slot":slot,"earned_xp":CharacterBuilderRecords.xp(state,id),"xp_injected":false,"cycles":state.adventure_cycles.cycles.size(),"history":record.advancement_history}))
 finish()
func create_party() -> void:
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"source-backed origin")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id));slot=born.state.playthrough_id
 check(service.store.save_new(slot,born.state,entry.world).ok,"fresh ordinary save")
 action_builder("builder_open")
 var source := RulesRecords.registry(state);var kernel := RulesCharacter.new(source)
 for i in 3:
  var cls: String=["marshal","beguiler","dragonfire-adept"][i];var id: String=state.party_ids[i]
  var attrs := {};var priority: Array=source.definition("classes",cls).attribute_priority
  for n in 6:attrs[priority[n]]=source.rule("standard_array")[n]
  var record := kernel.create(id,attrs,"heritage-human")
  var chosen := kernel.suggested_choice(record,cls,"commanding-presence"if i==0 else"steady-study")
  if i==0:chosen.choice=promotion(kernel,record,cls,"commanding-presence")
  var step := kernel.preview_advancement(record,chosen.choice)
  check(step.ok,"ordinary initial "+cls+JSON.stringify(step.get("errors",[])))
  if not step.ok:return
  record=step.candidate;record.equipment=source.definition("classes",cls).recommended_equipment
  var identity := {"name":["Arin","Lysa","Doran"][i],"people_id":"human","role_id":"expert","origin_burg":int(home.burg_id),"occupation_id":CharacterBuilderRecords.backgrounds(entry.world,int(home.burg_id))[0].id}
  action_builder("builder_save",i+1,{"identity":identity,"build":CharacterBuilderRecords.definition(record)})
 action_builder("builder_ready")
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,"ready earned party");state=resumed.get("state",state)
func promotion(kernel: RulesCharacter,record: Dictionary,cls: String,feat := "steady-study") -> Dictionary:
 var choice: Dictionary=kernel.suggested_choice(record,cls,feat).choice
 var ranks: Dictionary=kernel.derive_character(record).context.skills
 if cls=="marshal"and int(ranks.performance)<4 and not choice.skill_allocations.has("performance"):
  var first: String=str(choice.skill_allocations.keys()[0]);choice.skill_allocations[first]-=1
  if choice.skill_allocations[first]==0:choice.skill_allocations.erase(first)
  choice.skill_allocations.performance=1
 return choice
func finish() -> void:
 var restart: bool=OS.get_environment("GAME112W4_RESTART")=="1"
 if restart:FileAccess.open(base.path_join("restart-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":RulesRecords.new_character_registry().rules_ref()}))
 FileAccess.open(base.path_join("timings.json"),FileAccess.WRITE).store_string(JSON.stringify(timings))
 print("EARNED COHORT ",checks," / ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
