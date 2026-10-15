extends "res://tests/character_catalogue/fresh_driver.gd"
## Ordinary level-one adventure rewards, plus separate explicitly labelled fixtures.
var actions_used: Array=[]
func run() -> void:
 base=OS.get_environment("GAME112W3_TEST_ROOT").path_join("journey")
 DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 if OS.get_environment("GAME112W3_RESTART")=="1":
  var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
  var resumed := service.operate(entry,slot,"resume");check(resumed.ok,"separate process production campaign restart")
  if resumed.ok:
   state=resumed.state;check(RulesJson.digest(state)==proof.state_sha,"exact earned characters/resources/history reload")
  for fixture in proof.development_saves:
   var store := GamePlaythroughStore.new();store.save_root=fixture.save_root
   var loaded := store.load_save(slot,entry.world);check(loaded.ok,"original writer reloads labelled advanced fixture")
   if loaded.ok:
    for id in loaded.state.party_ids:check(RulesCharacter.new(RulesRecords.registry(loaded.state)).derive_character(loaded.state.mechanics.records[id]).snapshot.snapshot_hash==fixture.snapshots[id],"exact advanced persistent powers/creatures")
  await capture("wave-three-earned-reload","sheet",2);finish();return
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"source-backed origin")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"ordinary campaign creation")
 slot=born.state.playthrough_id;action_builder("builder_open")
 check(state.character_builder.rules_ref.pack_id==RulesRecords.NEW_PACK,"fresh default exact latest pin; no content opt-in")
 await creator("first-open-catalogue",1,"","")
 var source := RulesRecords.registry(state);var kernel := RulesCharacter.new(source)
 for i in 3:
  var cls: String=class_roster()[i];var ancestry: String=ancestry_roster()[i];var id: String=state.party_ids[i]
  var attributes := {};var priority: Array=source.definition("classes",cls).attribute_priority
  for n in 6:attributes[priority[n]]=source.rule("standard_array")[n]
  var record := kernel.create(id,attributes,"heritage-"+ancestry)
  var step := kernel.preview_advancement(record,kernel.suggested_choice(record,cls,"toughness").choice)
  check(step.ok,"actual initial class "+cls+JSON.stringify(step.get("errors",[])))
  if not step.ok:finish();return
  record=step.candidate;record.equipment=source.definition("classes",cls).recommended_equipment
  var identity := {"name":["Iria","Selen","Vale"][i],"people_id":ancestry,"role_id":"adept","origin_burg":int(home.burg_id),"occupation_id":CharacterBuilderRecords.backgrounds(entry.world,int(home.burg_id))[0].id}
  await creator("wave-three-create-"+cls,i+1,ancestry,cls)
  action_builder("builder_save",i+1,{"identity":identity,"build":CharacterBuilderRecords.definition(record)})
 action_builder("builder_ready")
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,"hometown/local region ready");state=resumed.get("state",state)
 var initial := state.duplicate(true)
 check(CharacterBuilderRecords.xp(state,state.party_ids[0])==0,"ordinary campaign has no injected XP")
 await capture("wave-three-starting-sheet","sheet",2)
 action("cycle_seek")
 for i in 4:
  travel(i)
  var site := SandboxRecords.site(cycle(),cycle().active.site_id)
  if OpportunityGenerator.template(site.activity_id).family=="contested" and actions_used.is_empty():await fight_psychic()
  else:action("cycle_activity",{"choice":"negotiate" if OpportunityGenerator.template(site.activity_id).family=="contested" else "careful"})
  action("cycle_return")
 for id in state.party_ids:
  var record: Dictionary=state.mechanics.records[id]
  var proposed := kernel.suggested_choice(record,record.advancement_history[0].class_id)
  var preview := CharacterBuilderRecords.preview_advancement(state,id,proposed.choice)
  check(preview.ok,"advancement through genuinely earned rewards")
  if preview.ok:action_builder("builder_advance",1,{"character_id":id,"choice":proposed.choice,"candidate_hash":preview.candidate_hash})
 await capture("wave-three-earned-advancement","sheet",2)
 var earned := state.duplicate(true);var development_saves: Array=[]
 # Same ancestry and level, different actual powers; original writer owns each fixture.
 for cls in ["psion-offence","psion-control","ardent","lurk","druid"]:
  var fixture := initial.duplicate(true);var id: String=fixture.party_ids[0]
  var track: String="psion" if str(cls).begins_with("psion-") else str(cls)
  var attributes := {};var priority: Array=source.definition("classes",track).get("attribute_priority",["WIS","CON","DEX","INT","STR","CHA"])
  for n in 6:attributes[priority[n]]=source.rule("standard_array")[n]
  var record := kernel.create(id,attributes,initial.mechanics.records[id].ancestry_ref)
  for n in (8 if track=="druid" else 12):
   var choice: Dictionary=kernel.suggested_choice(record,track).choice
   if n==0 and cls=="psion-control":choice.specialisations["psion-power-1"]="power-thought-fog";choice.specialisations["psion-second-power"]="power-keen-mind"
   if n==0 and track=="druid":choice.specialisations["druid-companion"]="leopard"
   var advanced := kernel.preview_advancement(record,choice);check(advanced.ok,"labelled development history "+cls+str(n))
   if not advanced.ok:finish();return
   record=advanced.candidate
  record.equipment=source.definition("classes",track).recommended_equipment
  record.runtime.hp=int(kernel.derive_character(record).snapshot.stats.HP)
  fixture.mechanics.records[id]=record;fixture.character_builder.initial_levels[id]=record.advancement_history.size()
  var root_path := base.path_join("development-"+cls);var store := GamePlaythroughStore.new();store.save_root=root_path
  var saved_fixture := store.save_new(slot,fixture,entry.world)
  check(saved_fixture.ok,"writer-owned advanced fixture "+cls+" "+JSON.stringify(saved_fixture.get("error","")))
  var snapshots := {}
  for member in fixture.party_ids:snapshots[member]=kernel.derive_character(fixture.mechanics.records[member]).snapshot.snapshot_hash
  development_saves.append({"save_root":root_path,"snapshots":snapshots})
  if DisplayServer.get_name()!="headless":await advanced_capture(fixture,root_path,cls)
 state=earned
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"slot":slot,"state_sha":RulesJson.digest(state),"rules_ref":source.rules_ref(),"earned_xp":CharacterBuilderRecords.xp(state,state.party_ids[0]),"actions_used":actions_used,"development_saves":development_saves,"screenshots":screenshots}))
 finish()
func fight_psychic() -> void:
 action("cycle_fight");engine.configure(state)
 await capture("wave-three-real-psychic-combat","combat")
 for n in 350:
  var battle := AdventureService.active_battle(state)
  if failures>0 or battle.status!="active":break
  var actor := engine.current(battle);var command := engine.enemy_command(battle)
  if actor.team=="party" and int(battle.budget.main)>0:
   var derived: Dictionary=engine.characters.derive_character(actor.record).snapshot
   for ability_id in ["power-kinetic-bolt","lurk-veil"]:
    if not derived.abilities.has(ability_id) or actions_used.has(ability_id):continue
    var target_id: String=actor.id if ability_id=="lurk-veil" else ""
    if target_id.is_empty():
     for target in battle.units.values():
      if target.team=="enemy" and engine.eligible(battle,actor,target,ability_id):target_id=target.id;break
    if target_id.is_empty() or not engine.effects.validate_ability_cost(ability_id,actor.record.runtime,{"move":int(battle.budget.move),"main":int(battle.budget.main),"reaction":int(actor.reaction)}).ok:continue
    command={"actor_id":actor.id,"revision":battle.revision,"kind":ability_id,"target_id":target_id};actions_used.append(ability_id);break
  action(AdventureService.command_operation(state),{"command":command})
  if failures>0:break
  if command.kind in ["power-kinetic-bolt","lurk-veil"]:await capture("wave-three-"+str(command.kind)+"-used","combat")
 check(AdventureService.active_battle(state).status!="active","ordinary psychic-party combat resolves")
 check(actions_used.has("power-kinetic-bolt"),"selected power functions in actual saved adventure combat")
func finish() -> void:
 FileAccess.open(base.path_join("screenshots.json"),FileAccess.WRITE).store_string(JSON.stringify(screenshots))
 print("WAVE THREE JOURNEY ",checks," / ",failures)
 get_tree().quit(1 if failures else 0)

func class_roster() -> Array:return ["psion","ardent","lurk"]
func ancestry_roster() -> Array:return ["human","elan","xeph"]
