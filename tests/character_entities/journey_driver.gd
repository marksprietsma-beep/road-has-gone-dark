extends "res://tests/character_catalogue/fresh_driver.gd"
## Genuine level1 campaign/earned advancement and separate labelled shape fixtures.
var demonstration_actions: Array=[]
func run() -> void:
 base=OS.get_environment("GAME112W2_TEST_ROOT").path_join("journey")
 DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 if OS.get_environment("GAME112W2_RESTART")=="1":
  var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
  var resumed := service.operate(entry,slot,"resume");check(resumed.ok,"fresh process actual campaign reload")
  if resumed.ok:
   state=resumed.state
   check(RulesJson.digest(state)==proof.state_sha,"exact campaign/companion/earned-XP restart")
  var fixture_service := AdventureService.new();fixture_service.store.save_root=base.path_join("shape-fixture")
  fixture_service.library=service.library;fixture_service.cache_root=service.cache_root
  var fixture := fixture_service.operate(entry,slot,"resume")
  check(fixture.ok,"separate process active Wild Shape campaign reload")
  if fixture.ok:check(AdventureService.active_battle(fixture.state).state_hash==proof.fixture_battle_hash,"active companion/summon/form battle retained exactly by original writer")
  await capture("wave-two-reloaded-party","sheet",2)
  finish_wave();return
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"canonical world profiles")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"normal campaign birth")
 slot=born.state.playthrough_id;action_builder("builder_open")
 check(state.character_builder.rules_ref.pack_id=="trhgd-character-v12","normal journey defaults to v12")
 await creator("wave-two-first-open",1,"","")
 var source := RulesRecords.registry(state);var kernel := RulesCharacter.new(source)
 for i in 3:
  var cls: String=["druid","wizard","wilder"][i];var ancestry: String=["shifter","changeling","minotaur"][i]
  var attributes: Dictionary={};var priority: Array=source.definition("classes",cls).get("attribute_priority",["WIS","CON","DEX","INT","STR","CHA"] if cls=="druid" else ["INT","DEX","CON","WIS","STR","CHA"])
  for n in 6:attributes[priority[n]]=source.rule("standard_array")[n]
  var id: String=state.party_ids[i];var record := kernel.create(id,attributes,"heritage-"+ancestry)
  var proposed := kernel.preview_advancement(record,kernel.suggested_choice(record,cls,"toughness").choice)
  check(proposed.ok,"new authentic starting build "+cls)
  if not proposed.ok:finish_wave();return
  record=proposed.candidate;record.equipment=["staff"]
  if cls=="wizard":
   record.choices.prepared_abilities=["wizard-summon-sentinel"];record.choices.spell_preparations={"wizard-summon-sentinel":1}
  var identity := {"name":["Fen","Lyra","Bran"][i],"people_id":ancestry,"role_id":"adept","origin_burg":int(home.burg_id),"occupation_id":CharacterBuilderRecords.backgrounds(entry.world,int(home.burg_id))[0].id}
  await creator("wave-two-create-"+cls,i+1,ancestry,cls)
  action_builder("builder_save",i+1,{"identity":identity,"build":CharacterBuilderRecords.definition(record)})
 action_builder("builder_ready")
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,"native hometown transition");state=resumed.get("state",state)
 var initial_state := state.duplicate(true)
 await capture("wave-two-companion-sheet","sheet",2)
 action("cycle_seek")
 for i in 4:
  travel(i)
  if failures>0:finish_wave();return
  var site := SandboxRecords.site(cycle(),cycle().active.site_id)
  if OpportunityGenerator.template(site.activity_id).family=="contested" and demonstration_actions.is_empty():await demonstrate_battle(false)
  else:action("cycle_activity",{"choice":"negotiate" if OpportunityGenerator.template(site.activity_id).family=="contested" else "careful"})
  action("cycle_return")
 check(demonstration_actions.any(func(id: String):return id.contains(":companion")),"persistent companion actually acts in saved combat")
 check(demonstration_actions.has("wizard-summon-sentinel") and demonstration_actions.any(func(id: String):return id.contains(":summon:")),"prepared summon enters and acts in saved combat")
 check(demonstration_actions.has("wilder-surge"),"distinct psychic surge acts in saved combat")
 for id in state.party_ids:
  var record: Dictionary=state.mechanics.records[id]
  var choice := kernel.suggested_choice(record,record.advancement_history[0].class_id)
  var preview := CharacterBuilderRecords.preview_advancement(state,id,choice.choice)
  check(preview.ok,"actual earned advancement")
  if preview.ok:action_builder("builder_advance",1,{"character_id":id,"choice":choice.choice,"candidate_hash":preview.candidate_hash})
 await capture("wave-two-earned-level2","sheet",2)
 var earned_state := state.duplicate(true);var ordinary_root: String=service.store.save_root
 # Development fixture at class5, writer-owned separate directory; no XP grant.
 var fixture := initial_state.duplicate(true);var druid_id: String=fixture.party_ids[0]
 var advanced: Dictionary=fixture.mechanics.records[druid_id]
 for n in 4:
  var result := kernel.preview_advancement(advanced,kernel.suggested_choice(advanced,"druid").choice)
  check(result.ok,"labelled Druid5 development history")
  if not result.ok:finish_wave();return
  advanced=result.candidate
 advanced.runtime.hp=int(kernel.derive_character(advanced).snapshot.stats.HP)
 fixture.mechanics.records[druid_id]=advanced;fixture.character_builder.initial_levels[druid_id]=5
 service.store.save_root=base.path_join("shape-fixture")
 check(service.store.save_new(slot,fixture,entry.world).ok,"existing writer saves labelled shape fixture")
 state=fixture
 action("cycle_seek")
 for i in 4:
  var site: Dictionary=cycle().base.sites[i]
  if OpportunityGenerator.template(site.activity_id).family!="contested":continue
  travel(i);await demonstrate_battle(true);break
 var fixture_hash: String=AdventureService.active_battle(state).state_hash
 service.store.save_root=ordinary_root;state=earned_state
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"slot":slot,"state_sha":RulesJson.digest(state),"rules_ref":source.rules_ref(),"earned_xp":CharacterBuilderRecords.xp(state,state.party_ids[0]),"demonstration_actions":demonstration_actions,"fixture_battle_hash":fixture_hash,"fixture_is_earned":false,"screenshots":screenshots}," "))
 finish_wave()
func demonstrate_battle(shape: bool) -> void:
 action("cycle_fight");engine.configure(state)
 await capture("wave-two-shape-fixture-start" if shape else "wave-two-owned-creatures","combat")
 var shaped := false;var reverted := false
 for n in 250:
  var battle := AdventureService.active_battle(state)
  if failures>0 or battle.status!="active":break
  var actor := engine.current(battle);var command := engine.enemy_command(battle)
  if actor.team=="party" and int(battle.budget.main)>0:
   if shape and actor.id!=state.party_ids[0]:
    command={"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
   elif actor.has("entity"):
    if not demonstration_actions.has(actor.id):demonstration_actions.append(actor.id)
   elif shape and actor.id==state.party_ids[0] and not shaped:
    command={"actor_id":actor.id,"revision":battle.revision,"kind":"wild-shape","target_id":actor.id};shaped=true
   elif shape and actor.id==state.party_ids[0] and shaped and not reverted and demonstration_actions.has("bear-attack"):
    command={"actor_id":actor.id,"revision":battle.revision,"kind":"revert-form","target_id":actor.id};reverted=true
   elif actor.id==state.party_ids[1] and not demonstration_actions.has("wizard-summon-sentinel"):
    command={"actor_id":actor.id,"revision":battle.revision,"kind":"wizard-summon-sentinel","target_id":actor.id}
   elif actor.id==state.party_ids[2] and not demonstration_actions.has("wilder-surge"):
    var targets: Array=battle.units.values().filter(func(t: Dictionary):return t.team=="enemy" and engine.eligible(battle,actor,t,"wilder-surge"))
    if not targets.is_empty():command={"actor_id":actor.id,"revision":battle.revision,"kind":"wilder-surge","target_id":targets[0].id}
  var pure := engine.command(battle,command);check(pure.ok,"saved owned/form command "+str(command.kind)+str(pure.get("error","")))
  if not pure.ok:break
  action("cycle_command",{"command":command})
  check(AdventureService.active_battle(state).state_hash==pure.battle.state_hash,"same authority and save journal")
  if not demonstration_actions.has(command.kind):demonstration_actions.append(command.kind)
  if shape and command.kind=="attack" and actor.id==state.party_ids[0] and not RulesEntities.form(actor.record,engine.registry).is_empty():demonstration_actions.append("bear-attack")
  if shape and command.kind=="wild-shape":
   var active_store := GamePlaythroughStore.new();active_store.save_root=base.path_join("active-shape-fixture")
   check(active_store.save_new(slot,state,entry.world).ok,"same writer preserves active transformed campaign for restart")
  if command.kind in ["wild-shape","wizard-summon-sentinel","revert-form","wilder-surge"]:await capture("wave-two-"+str(command.kind)+( "-fixture" if shape else ""),"combat")
  if shape and reverted:break # Retain active battle for a real process-restart proof.
 if shape:check(shaped and reverted and demonstration_actions.has("bear-attack"),"Druid transforms, attacks with changed anatomy and reverts")
 else:check(AdventureService.active_battle(state).status!="active","actual new-party encounter resolves")
func screenshot(name: String,development: bool) -> void:
 var fixture: bool=development or name.contains("fixture") or service.store.save_root.ends_with("shape-fixture")
 if fixture and get_tree().current_scene!=null and get_tree().current_scene.get("title") is Label:
  var heading: Label=get_tree().current_scene.title
  if not heading.text.begins_with("DEVELOPMENT FIXTURE"):heading.text="DEVELOPMENT FIXTURE · XP not granted · "+heading.text
 await super.screenshot(name,fixture)
func finish_wave() -> void:
 FileAccess.open(base.path_join("screenshots.json"),FileAccess.WRITE).store_string(JSON.stringify(screenshots," "))
 print("WAVE TWO JOURNEY ",checks," / ",failures)
 get_tree().quit(1 if failures else 0)
