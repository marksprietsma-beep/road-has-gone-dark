extends "res://tests/adventure_cycles/earned_driver.gd"
## Native production saves plus clearly labelled advanced development fixtures.
var used_actions: Array=[]
func run() -> void:
 base=OS.get_environment("GAME112_TEST_ROOT").path_join("fresh")
 DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 if OS.get_environment("GAME112_RESTART")=="1":
  var proof: Dictionary=WorldOriginLore.read_json(base.path_join("new-party-proof.json"));slot=proof.slot
  var resumed:=service.operate(entry,slot,"resume");check(resumed.ok,"new native campaign reload")
  state=resumed.get("state",{})
  check(RulesJson.digest(state)==proof.state_sha,"new ancestry/class campaign exact fresh-process reload")
  for fixture in proof.development_saves:
   var store:=GamePlaythroughStore.new();store.save_root=fixture.save_root
   var loaded:=store.load_save(slot,entry.world)
   check(loaded.ok,"development advanced character load")
   if loaded.ok:
    for id in loaded.state.party_ids:check(RulesCharacter.new(RulesRecords.registry(loaded.state)).derive_character(loaded.state.mechanics.records[id]).snapshot.snapshot_hash==fixture.snapshots[id],"advanced history/resources preserve exact pin")
  await capture("catalogue-party-reloaded","sheet",2)
  finish();return
 var profiles:=OriginProfiles.new();check(profiles.load_world(entry.world),"real world profiles")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born:=service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"source-backed fresh campaign")
 slot=born.state.playthrough_id;action_builder("builder_open")
 check(state.character_builder.rules_ref.pack_id==RulesRecords.NEW_PACK,"normal first open uses latest content")
 await creator("first-open-catalogue",1,"","")
 if failures>0:finish();return
 var source:=RulesRecords.registry(state);var kernel:=RulesCharacter.new(source)
 for i in 3:
  var cls: String=["psion","warlock","warblade"][i];var ancestry: String=["tiefling","aasimar","steelbound"][i];var id: String=state.party_ids[i]
  var attributes: Dictionary={}
  var priority: Array=source.definition("classes",cls).attribute_priority
  for n in priority.size():attributes[priority[n]]=source.rule("standard_array")[n]
  var record:=kernel.create(id,attributes,"heritage-"+ancestry)
  var proposal:=kernel.preview_advancement(record,kernel.suggested_choice(record,cls,"toughness").choice)
  check(proposal.ok,"new authentic starting class "+cls)
  if not proposal.ok:finish();return
  record=proposal.candidate
  record.equipment=source.definition("classes",cls).recommended_equipment.filter(func(item: String):return not source.definition("equipment",item).kind in source.definition("ancestries",record.ancestry_ref).get("capabilities",{}).get("blocked_equipment",[]))
  var jobs:=CharacterBuilderRecords.backgrounds(entry.world,int(home.burg_id))
  var identity:={"name":["Vessa","Alar","Orin"][i],"people_id":ancestry,"role_id":["adept","adept","vanguard"][i],"origin_burg":int(home.burg_id),"occupation_id":jobs[0].id}
  await creator("create-"+cls+"-"+ancestry,i+1,ancestry,cls)
  if failures>0:finish();return
  action_builder("builder_save",i+1,{"identity":identity,"build":CharacterBuilderRecords.definition(record)})
 action_builder("builder_ready")
 var resumed:=service.operate(entry,slot,"resume");check(resumed.ok,"native hometown transition");state=resumed.get("state",state)
 var development_base:=state.duplicate(true)
 await capture("new-class-mechanical-sheet","sheet",2)
 action("cycle_seek")
 for i in 4:
  travel(i)
  var site:=SandboxRecords.site(cycle(),cycle().active.site_id)
  if OpportunityGenerator.template(site.activity_id).family=="contested" and used_actions.is_empty():await fight_new()
  else:action("cycle_activity",{"choice":"negotiate" if OpportunityGenerator.template(site.activity_id).family=="contested" else "careful"})
  action("cycle_return")
 var development_saves: Array=[]
 for path in ["wizard","psion","shadowdancer"]:
  var fixture:=development_base.duplicate(true);var id: String=fixture.party_ids[0];var ancestry: String=fixture.mechanics.records[id].ancestry_ref
  var record:=kernel.create(id,{"INT":15,"WIS":14,"DEX":13,"STR":12,"CON":10,"CHA":8},ancestry)
  var levels:=20 if path=="wizard" else 12 if path=="psion" else 15
  for n in levels:
   var cls: String=path if path!="shadowdancer" or n>=5 else "rogue"
   var result:=kernel.preview_advancement(record,kernel.suggested_choice(record,cls,"dodge" if path=="shadowdancer" and n==0 else "steady-study").choice)
   check(result.ok,"labelled development history "+path)
   if not result.ok:break
   record=result.candidate
  record.equipment=["staff"] if path in ["wizard","psion"] else ["shortblade"]
  record.runtime.hp=kernel.derive_character(record).snapshot.stats.HP;record.runtime.resources=kernel.derive_character(record).snapshot.resource_capacities.duplicate()
  if path=="wizard":
   record.choices.prepared_abilities=["wizard-tier9-tempest"];record.choices.spell_preparations={"wizard-tier9-tempest":1};RulesCoreContent.refill_prepared(record,source)
  fixture.mechanics.records[id]=record;fixture.character_builder.advancements=[]
  var snapshots:={}
  for character in fixture.party_ids:
   fixture.character_builder.initial_levels[character]=fixture.mechanics.records[character].advancement_history.size()
   snapshots[character]=kernel.derive_character(fixture.mechanics.records[character]).snapshot.snapshot_hash
  var fixture_root:=base.path_join("development-"+path);var store:=GamePlaythroughStore.new();store.save_root=fixture_root
  var saved:=store.save_new(slot,fixture,entry.world);check(saved.ok,"original writer saves labelled advanced fixture "+path+str(saved.get("error","")))
  development_saves.append({"save_root":fixture_root,"snapshots":snapshots,"path":path,"development_fixture":true,"ordinary_xp_granted":false})
  if DisplayServer.get_name()!="headless":await advanced_capture(fixture,fixture_root,path)
 check(used_actions.size()>0,"actual saved encounter executes a new class ability")
 FileAccess.open(base.path_join("new-party-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"slot":slot,"state_sha":RulesJson.digest(state),"rules_ref":source.rules_ref(),"earned_xp":CharacterBuilderRecords.xp(state,state.party_ids[0]),"used_actions":used_actions,"development_saves":development_saves,"screenshots":screenshots}," "))
 finish()
func finish() -> void:
 FileAccess.open(base.path_join("screenshots.json"),FileAccess.WRITE).store_string(JSON.stringify(screenshots," "))
 print("GAME112 FRESH NATIVE ",checks," / ",failures)
 get_tree().quit(1 if failures else 0)
func creator(name: String,member: int,people: String,cls: String) -> void:
 if DisplayServer.get_name()=="headless":return
 get_tree().root.gui_embed_subwindows=true
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
 var deadline:=Time.get_ticks_msec()+60000
 while get_tree().current_scene==null or get_tree().current_scene.scene_file_path!="res://scenes/ui/party_creation.tscn":await get_tree().process_frame
 var ui: Control=get_tree().current_scene
 while (ui.thread!=null or ui.state.is_empty()) and Time.get_ticks_msec()<deadline:await get_tree().process_frame
 check(not ui.state.is_empty(),"actual creator loaded")
 if ui.state.is_empty():return
 for frame in 3:await get_tree().process_frame
 ui._select_member(member-1)
 if not people.is_empty():
  ui.pick(ui.people_picker,people);ui.people_picker.item_selected.emit(ui.people_picker.selected)
  ui.editor.set_class(cls);ui._identity_changed()
 for frame in 5:await get_tree().process_frame
 check(ui.editor.preview.ok,"visible new race/class preview "+people+" "+cls)
 ui.detail_tabs.current_tab=2 if not people.is_empty() else 0
 await screenshot(name,false)
 if name=="first-open-catalogue":
  ui.class_choice.get_popup().popup(Rect2i(Vector2i(ui.class_choice.get_global_rect().position),Vector2i(ui.class_choice.size)))
  for frame in 4:await get_tree().process_frame
  await screenshot("available-core-and-alternative-classes",false)
  ui.class_choice.get_popup().hide()
  ui.people_picker.get_popup().popup(Rect2i(Vector2i(ui.people_picker.get_global_rect().position),Vector2i(ui.people_picker.size)))
  for frame in 4:await get_tree().process_frame
  await screenshot("available-ancestry-families",false)
  ui.people_picker.get_popup().hide()
 get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
 for frame in 3:await get_tree().process_frame
func screenshot(name: String,development: bool) -> void:
 for resolution in [Vector2i(1280,720),Vector2i(640,360),Vector2i(2560,1440)]:
  get_tree().root.size=resolution
  for frame in 5:await get_tree().process_frame
  if name.contains("-history"):
   var history_scroll: ScrollContainer=get_tree().current_scene.detail_tabs.get_child(2)
   history_scroll.scroll_vertical=int(history_scroll.get_v_scroll_bar().max_value)
  if name=="development-tier9-spells":
   var spells_scroll: ScrollContainer=get_tree().current_scene.detail_tabs.get_child(4)
   spells_scroll.ensure_control_visible(get_tree().current_scene.spellbook.controls["wizard-tier9-tempest"])
  for frame in 4:await get_tree().process_frame
  await RenderingServer.frame_post_draw
  DirAccess.make_dir_recursive_absolute(base.path_join("screenshots"))
  var file:=name+"-%dx%d.png"%[resolution.x,resolution.y]
  check(get_tree().root.get_texture().get_image().save_png(base.path_join("screenshots/"+file))==OK,"actual Godot screenshot")
  screenshots.append({"file":file,"sha256":FileAccess.get_sha256(base.path_join("screenshots/"+file)),"development_fixture":development})
func advanced_capture(fixture: Dictionary,fixture_root: String,path: String) -> void:
 CharacterScreen.handoff={"entry":entry,"slot":slot,"save_root":fixture_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 get_tree().change_scene_to_file("res://scenes/ui/character_sheet.tscn")
 while get_tree().current_scene==null or get_tree().current_scene.scene_file_path!="res://scenes/ui/character_sheet.tscn":await get_tree().process_frame
 var ui: Control=get_tree().current_scene
 while ui.thread!=null or ui.state.is_empty():await get_tree().process_frame
 ui.title.text="DEVELOPMENT FIXTURE · "+path+" · XP not granted";ui.detail_tabs.current_tab=2
 await screenshot("development-"+path+"-sheet",true)
 var scroll: ScrollContainer=ui.detail_tabs.get_child(2);scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value)
 await screenshot("development-"+path+"-history",true)
 if path=="wizard":
  ui.detail_tabs.current_tab=4
  for frame in 4:await get_tree().process_frame
  var spells_scroll: ScrollContainer=ui.detail_tabs.get_child(4)
  var spell_control: Control=ui.spellbook.controls["wizard-tier9-tempest"]
  spells_scroll.scroll_vertical=int(spell_control.get_global_rect().position.y-ui.spellbook.get_global_rect().position.y)-100
  await screenshot("development-tier9-spells",true)
 get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
 for frame in 3:await get_tree().process_frame
func fight_new() -> void:
 action("cycle_fight");engine.configure(state)
 await capture("new-classes-combat","combat")
 for n in 250:
  var battle:=AdventureService.active_battle(state)
  if failures>0 or battle.status!="active":break
  var actor:=engine.current(battle);var command:=engine.enemy_command(battle)
  if actor.team=="party" and int(battle.budget.main)>0:
   var cls: String=actor.record.advancement_history[0].class_id;var ability:=cls+"-technique-1"
   var targets: Array=battle.units.values().filter(func(target: Dictionary):return target.team=="enemy" and engine.eligible(battle,actor,target,ability))
   if not targets.is_empty() and engine.effects.validate_ability_cost(ability,actor.record.runtime,{"main":int(battle.budget.main),"move":int(battle.budget.move),"reaction":int(actor.reaction)}).ok:
    command={"actor_id":actor.id,"revision":battle.revision,"kind":ability,"target_id":targets[0].id}
    if not used_actions.has(ability):used_actions.append(ability)
  var result:=engine.command(battle,command);check(result.ok,"new class pure command")
  if not result.ok:break
  action("cycle_command",{"command":command})
  check(AdventureService.active_battle(state).state_hash==result.battle.state_hash,"new class command persists exact authority")
 check(AdventureService.active_battle(state).status!="active","new class battle completes")
 await capture("new-class-combat-results","combat")

func capture(name: String,screen: String,tab: int=0) -> void:
 if DisplayServer.get_name()=="headless":return
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 CharacterScreen.handoff=PartyService.handoff.duplicate()
 var path: String="res://scenes/ui/character_sheet.tscn" if screen=="sheet" else "res://scenes/combat/first_adventure.tscn" if screen=="combat" else "res://scenes/gameplay/expedition.tscn"
 get_tree().change_scene_to_file(path)
 while get_tree().current_scene==null or get_tree().current_scene.scene_file_path!=path:await get_tree().process_frame
 var ui: Control=get_tree().current_scene
 var deadline:=Time.get_ticks_msec()+60000
 while (ui.thread!=null or ui.state.is_empty()) and Time.get_ticks_msec()<deadline:await get_tree().process_frame
 check(not ui.state.is_empty() and ui.thread==null,"production scene ready "+name)
 if ui.state.is_empty():return
 ui.set_process(false)
 if screen=="sheet":ui.detail_tabs.current_tab=tab
 await screenshot(name,false)
 get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
 for frame in 3:await get_tree().process_frame
