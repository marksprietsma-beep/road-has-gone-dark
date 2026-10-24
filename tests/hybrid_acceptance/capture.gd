extends "res://tests/class_signatures/capture_driver.gd"
## Real Windows Godot scenes. Pre-entry snapshots were saved at the actual earned XP.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("HYBRID_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof := WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"original1690XP/14 campaign resumes for real captures")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(OS.get_environment("HYBRID_ROOT").path_join("saved.json")))
 var born := service.store.create_playthrough(entry.world,int(state.origin.state_id),int(state.origin.home_burg_id),int(state.origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"fresh ordinary creator original writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  select_option(creator.class_choice,"duskblade");creator.detail_tabs.current_tab=1
  await photograph_scene("ordinary-duskblade-creator",false);screenshots.back().earned_xp=0
  await photograph_scene("ordinary-duskblade-small",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for i in 3:
  var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  var r: Dictionary=state.mechanics.records[state.party_ids[i]];var d := CharacterBuilderRecords.kernel(state).derive_character(r)
  sheet.title.text="EARNED · "+str(r.advancement_history.size())+" total levels · "+str(d.snapshot.class_levels)+" · "+str(proof.earned_xp)+" journey XP"
  await photograph_scene("earned-"+["duskblade","wizard-archmage","sorcerer-archmage"][i]+"-sheet",false,Vector2i(2560,1440))
 var original_slot: String=slot;var original_root: String=service.store.save_root
 for cls in ["wizard","sorcerer"]:
  var earned := WorldOriginLore.read_json(base.path_join("earned-qualified-"+cls+".json"))
  check(RulesJson.digest(earned)==proof.earned_entry_witnesses[cls].state_hash,"actual saved pre-entry witness unchanged "+cls)
  var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("capture-entry-"+cls)
  check(fork.save_new(slot,earned,entry.world).ok,"pre-entry capture fork through sole existing writer")
  service.store.save_root=fork.save_root;service.library.save_root=fork.save_root
  var sheet := await open_sheet();sheet._select_member(1 if cls=="wizard" else 2);sheet.detail_tabs.current_tab=3
  var picker: OptionButton=sheet.advance_editor.class_picker
  select_option(picker,"archmage")
  check(sheet.advance_editor.career_pickers.has("archmage-casting") and sheet.advance_editor.career_pickers.has("high-arcana-1") and not sheet.advancement_button.disabled,"earned1690XP enables explicit optional Archmage and its choices "+cls)
  sheet.title.text="EARNED · "+cls+"13 · 1690XP · optional Archmage preview, not committed"
  await photograph_scene("earned-"+cls+"-prestige-entry",false,Vector2i(2560,1440));screenshots.back().earned_xp=1690
  check(RulesJson.digest(fork.load_save(slot,entry.world).state)==RulesJson.digest(earned),"preview/capture never commits advancement")
 service.store.save_root=original_root;service.library.save_root=original_root;slot=original_slot
 for key in ["duskblade20","sorcerer:force","wizard:ward"]:
  var sheet := await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[key],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · "+key+" · total20 / path5 where applicable · not earned XP"
  await photograph_scene("fixture-"+key.replace(":","-")+"-sheet",true,Vector2i(2560,1440))
  if key=="duskblade20":
   sheet.detail_tabs.current_tab=4;sheet.spellbook.repertoire_search.text="tier 5";sheet.spellbook.repertoire_search.text_changed.emit("tier 5")
   await photograph_scene("fixture-duskblade-tier5-choices",true)
 for key in ["duskblade-searing-grasp:1","duskblade-searing-grasp:19","duskblade-ruinous-touch:20","refraction-counter","sorcerer:liberation","sorcerer:high-arcana-force-5"]:
  var combat := await open_combat();var b: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(b.units.a.record);combat.mode="attack";combat.message="DEVELOPMENT FIXTURE · actual resolved "+key+" · costs and status saved";combat.refresh()
  await photograph_scene("fixture-"+key.replace(":","-")+"-combat",true)
  if key=="sorcerer:liberation":await photograph_scene("fixture-liberation-large",true,Vector2i(2560,1440))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · "+str(proof.earned_xp)+"XP · actual Duskblade / Wizard-Archmage / Sorcerer-Archmage actions saved";combat.refresh()
 await photograph_scene("earned-connected-class-actions",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"all captures preserve original campaign XP/history/resources/save")
 finish_capture()
func select_option(picker: OptionButton,id: String) -> void:
 for n in picker.item_count:
  if picker.get_item_metadata(n)==id:picker.select(n);picker.item_selected.emit(n);return
 check(false,"actual production option missing "+id)
func photograph_scene(name: String,fixture: bool,resolution := Vector2i(1280,720)) -> void:
 await super.photograph_scene(name,fixture,resolution)
 screenshots.back().earned_xp=false if fixture else CharacterBuilderRecords.xp(state,state.party_ids[0])
