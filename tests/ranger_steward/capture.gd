extends "res://tests/martial_careers/capture.gd"
## Original production scenes and native pixels. High-level fixtures are labelled.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("RANGER_STEWARD_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof := WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual earned490XP/8 campaign resumes for production renders")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(OS.get_environment("RANGER_STEWARD_ROOT").path_join("saved.json")))
 var born := service.store.create_playthrough(entry.world,int(state.origin.state_id),int(state.origin.home_burg_id),int(state.origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"independent fresh creator through original campaign writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  await photograph_scene("ordinary-first-open-creator",false);screenshots.back().earned_xp=0
  select_option(creator.class_choice,"ranger");creator.detail_tabs.current_tab=1;select_option(creator.editor.career_pickers["ranger-choice-1"],"archery");show_tab(creator.editor.sections,"Specialisation")
  await photograph_scene("ordinary-ranger-archery-style",false,Vector2i(2560,1440));screenshots.back().earned_xp=0
  select_option(creator.editor.career_pickers["ranger-choice-1"],"blade")
  await photograph_scene("ordinary-ranger-blade-style",false);screenshots.back().earned_xp=0
  select_option(creator.editor.career_pickers["ranger-quarry-choice"],"archers")
  await photograph_scene("ordinary-ranger-quarry",false,Vector2i(2560,1440));screenshots.back().earned_xp=0
  show_tab(creator.editor.sections,"Equipment");await photograph_scene("ordinary-ranger-equipment",false);screenshots.back().earned_xp=0
  await photograph_scene("ordinary-ranger-small",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for i in 3:
  var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  sheet.title.text="EARNED · 490XP · total8 · "+["Ranger archery / Wolf","Ranger blade / Leopard","Ranger5 / Beast Steward3 / Stag"][i]
  await photograph_scene("earned-"+["ranger-archery","ranger-blade","beast-steward"][i]+"-sheet",false,Vector2i(2560,1440))
  if i==0:
   sheet.detail_tabs.current_tab=4;await photograph_scene("earned-ranger-nature-preparation",false,Vector2i(2560,1440))
  if i==2:
   sheet.detail_tabs.current_tab=3;show_tab(sheet.advance_editor.sections,"Progression")
   check(sheet.advancement_button.disabled,"earned8 cannot commit an unfunded ninth level")
   await photograph_scene("earned-advancement-no-free-xp",false)
 var earned := WorldOriginLore.read_json(base.path_join("earned-qualified-steward.json"));check(RulesJson.digest(earned)==proof.earned_entry.state_hash,"exact actually earned pre-entry qualification state")
 var original_root: String=service.store.save_root;var original_slot: String=slot
 var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("capture-entry");check(fork.save_new(slot,earned,entry.world).ok,"pre-entry display fork through original writer")
 service.store.save_root=fork.save_root;service.library.save_root=fork.save_root
 var sheet := await open_sheet();sheet._select_member(2);sheet.detail_tabs.current_tab=3;select_option(sheet.advance_editor.class_picker,"beast-steward");show_tab(sheet.advance_editor.sections,"Specialisation")
 check(not sheet.advancement_button.disabled and sheet.advance_editor.career_pickers.has("beast-steward-training"),"actual earned250XP enables optional funded Steward and training controls")
 sheet.title.text="EARNED · Ranger5 · 250XP · optional Beast Steward preview, not committed"
 await photograph_scene("earned-steward-entry-training",false,Vector2i(2560,1440));screenshots.back().earned_xp=250
 select_option(sheet.advance_editor.class_picker,"ranger");check(not sheet.advancement_button.disabled,"actual funded decline remains legal")
 await photograph_scene("earned-steward-decline-alternative",false);screenshots.back().earned_xp=250
 check(RulesJson.digest(fork.load_save(slot,entry.world).state)==RulesJson.digest(earned),"entry/decline capture commits no advancement")
 service.store.save_root=original_root;service.library.save_root=original_root;slot=original_slot
 for key in ["archery20","blade20","steward-swift20","steward-enduring20"]:
  sheet=await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[key],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · total20 · "+key+" · prestige cap5 · not earned XP"
  await photograph_scene("fixture-"+key+"-sheet",true,Vector2i(2560,1440))
 for key in ["aimed2019","swiftsteward-drive-33","pet-attack-leopard","pet-special-stag","summon_and_companion","late20"]:
  var combat := await open_combat();var battle: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(battle.units.a.record);combat.mode="attack";combat.message="DEVELOPMENT FIXTURE · "+key+" · actual owned actors and paid actions; humanoid art fallback";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  if key=="pet-attack-leopard":await photograph_scene("fixture-companion-small",true,Vector2i(640,360))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · 490XP/8 · actual companion attack and owner style/pack commands paid and saved";combat.refresh()
 await photograph_scene("earned-connected-ranger-steward",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"original campaign, identities, companion records, XP and resources unchanged by renders")
 finish_capture()
