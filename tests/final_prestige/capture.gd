extends "res://tests/martial_careers/capture.gd"
## Original Godot scenes and original pixels; earned and development labels separate.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("FINAL_PRESTIGE_CAPTURE_ROOT");DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded: Dictionary=service.operate(entry,slot,"resume");check(loaded.ok,"actual earned campaign loads for original Windows renders")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before: String=RulesJson.digest(state);var xp: int=proof.earned_xp
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(OS.get_environment("FINAL_PRESTIGE_ROOT").path_join("saved.json")))
 var born: Dictionary=service.store.create_playthrough(entry.world,int(state.origin.state_id),int(state.origin.home_burg_id),int(state.origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"fresh creator uses sole writer without injected XP")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  await photograph_scene("ordinary-first-open-creator",false);screenshots.back().earned_xp=0
  select_option(creator.class_choice,"wizard");creator.detail_tabs.current_tab=1;show_tab(creator.editor.sections,"Spells")
  await photograph_scene("ordinary-wizard-preparation",false,Vector2i(2560,1440));screenshots.back().earned_xp=0
  select_option(creator.class_choice,"rogue");creator.detail_tabs.current_tab=1;show_tab(creator.editor.sections,"Specialisation")
  await photograph_scene("ordinary-rogue-choices",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for index in 3:
  var sheet: CharacterScreen=await open_sheet();sheet._select_member(index);sheet.detail_tabs.current_tab=2
  var record: Dictionary=state.mechanics.records[state.party_ids[index]]
  sheet.title.text="EARNED · %dXP · total%d · %s"%[xp,record.advancement_history.size(),["Wizard / Fighter / Eldritch Knight","Rogue / Shadowdancer","Dwarf Fighter / Dwarven Defender"][index]]
  await photograph_scene("earned-"+["wizard-knight","rogue-shadow","dwarf-defender"][index]+"-sheet",false,Vector2i(2560,1440));screenshots.back().earned_xp=xp
  sheet.detail_tabs.current_tab=4;await photograph_scene("earned-"+str(index)+"-spell-choices",false);screenshots.back().earned_xp=xp
 var root: String=service.store.save_root;var original_slot: String=slot
 for index in 3:
  var info: Dictionary=proof.earned_entries[state.party_ids[index]];var entered: Dictionary=WorldOriginLore.read_json(base.path_join("earned-entry-"+str(index)+".json"))
  check(RulesJson.digest(entered)==info.state_hash,"genuine funded pre-entry snapshot")
  var fork:=GamePlaythroughStore.new();fork.save_root=base.path_join("capture-entry-"+str(index));check(fork.save_new(slot,entered,entry.world).ok,"pre-entry display uses original writer")
  service.store.save_root=fork.save_root;service.library.save_root=fork.save_root
  var sheet: CharacterScreen=await open_sheet();sheet._select_member(index);sheet.detail_tabs.current_tab=3;select_option(sheet.advance_editor.class_picker,info.path)
  show_tab(sheet.advance_editor.sections,"Specialisation"if info.path=="eldritch-knight"else"Progression")
  check(not sheet.advancement_button.disabled,"funded prestige is deliberately selectable in production")
  sheet.title.text="EARNED · %dXP · optional %s preview · not automatic"%[int(info.earned_xp),str(info.path)]
  await photograph_scene("earned-entry-"+str(index)+"-prestige",false,Vector2i(2560,1440));screenshots.back().earned_xp=info.earned_xp
  select_option(sheet.advance_editor.class_picker,info.parent);check(not sheet.advancement_button.disabled,"funded alternative can decline prestige")
  await photograph_scene("earned-entry-"+str(index)+"-decline-preview",false);screenshots.back().earned_xp=info.earned_xp
  check(RulesJson.digest(fork.load_save(slot,entry.world).state)==info.state_hash,"UI previews change neither XP nor history")
  service.store.save_root=base.path_join("declined-"+str(index));service.library.save_root=service.store.save_root
  sheet=await open_sheet();sheet._select_member(index);sheet.detail_tabs.current_tab=2;sheet.title.text="EARNED · %dXP · actually committed %s decline"%[int(info.earned_xp),str(info.parent)]
  await photograph_scene("earned-entry-"+str(index)+"-decline-committed",false,Vector2i(2560,1440));screenshots.back().earned_xp=info.earned_xp
 service.store.save_root=root;service.library.save_root=root;slot=original_slot
 for key in ["wizard5-total20","shadow10-total20","defender10-total20"]:
  var sheet: CharacterScreen=await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[key],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · total20 · "+key+" · not earned20"
  await photograph_scene("fixture-"+key+"-sheet",true,Vector2i(2560,1440))
 for key in ["knight_counter","knight_shield","shadow-action1","shadow-action4","shadow-action7","shadow-action10","defender-stance1","defender-stance4","defender-stance7","defender-stance10","defender_counter","eldritch-channel-wizard-enfeeble-hit"]:
  var combat: Control=await open_combat();var battle: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  for index in 3:
   var member: Dictionary=state.party.members[index].duplicate(true);member.character_id=["a","b","c"][index];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(battle.units.a.record);combat.mode="attack";combat.message="DEVELOPMENT FIXTURE · "+key+" · actual paid effects; total20 is not earned; humanoid LPC fallback";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  if key=="defender-stance10":await photograph_scene("fixture-redoubt-small",true,Vector2i(640,360))
 var active: Dictionary=WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat: Control=await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · %dXP · real selected channel, paid shroud and anchored defence; exact saved campaign"%xp;combat.refresh()
 await photograph_scene("earned-connected-final-prestige",false,Vector2i(2560,1440));screenshots.back().earned_xp=xp
 await photograph_scene("earned-connected-final-prestige",false);screenshots.back().earned_xp=xp
 var resumed: Dictionary=service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"original renders never mutate earned identity, rules pin, XP, choices or save")
 finish_capture()
