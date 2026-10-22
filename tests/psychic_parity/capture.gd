extends "res://tests/class_signatures/capture_driver.gd"
## Original Windows Godot viewport pixels. Fixtures do not rewrite earned saves.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0")
 capture_folder=OS.get_environment("GAME152_CAPTURE_ROOT")
 if capture_folder.is_empty():capture_folder=OS.get_environment("GAME152_ROOT").get_base_dir().path_join("captures")
 DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];slot=WorldOriginLore.read_json(base.path_join("proof.json")).slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual earned psychic campaign reload for original renders")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(OS.get_environment("GAME152_ROOT").path_join("saved.json")))
 # Separate ordinary New Game save through the original writer, not a forged ready flag.
 var origin: Dictionary=state.origin
 var born := service.store.create_playthrough(entry.world,int(origin.state_id),int(origin.home_burg_id),int(origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"independent ordinary creator save through original writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  for cls in ["psion","wilder"]:
   for i in creator.class_choice.item_count:
    if creator.class_choice.get_item_metadata(i)==cls:creator.class_choice.select(i);creator.class_choice.item_selected.emit(i);break
   check(creator.editor.class_id==cls,"actual first-open creator selects "+cls)
   creator.detail_tabs.current_tab=1
   for i in creator.editor.sections.get_tab_count():
    if creator.editor.sections.get_tab_title(i)=="Powers":creator.editor.sections.current_tab=i
   await photograph_scene("ordinary-creator-"+cls+"-powers",false)
   screenshots.back().earned_xp=0
   if cls=="psion":
    await photograph_scene("ordinary-creator-psion-small",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for i in 3:
  var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  sheet.title.text="EARNED · "+["Psion8","Wilder8","Psion3 / Wizard3 / Cerebremancer2"][i]+" · 490XP before connected battle"
  await photograph_scene("earned-"+["psion","wilder","cerebremancer"][i]+"-sheet",false,Vector2i(2560,1440))
  sheet.detail_tabs.current_tab=3
  await photograph_scene("earned-"+["psion","wilder","cerebremancer"][i]+"-advancement-no-free-XP",false)
 for key in ["psion20","wilder20","hybrid"]:
  var sheet := await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[key],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · "+key+" · not earned XP"
  await photograph_scene("fixture-"+key+"-history-resources",true,Vector2i(2560,1440))
 for key in ["ready-psion8","psion8","wilder8"]:
  var combat := await open_combat();var battle: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(battle.units.a.record);combat.mode="attack";combat.message="DEVELOPMENT FIXTURE · "+key+" · real saved costs/effects";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  await photograph_scene("fixture-"+key+"-combat-large",true,Vector2i(2560,1440))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · actual saved augmented ward / Wilder surge / Wizard ward · separate pools";combat.refresh()
 await photograph_scene("earned-saved-psychic-arcane-combat",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume")
 check(resumed.ok and RulesJson.digest(resumed.state)==before,"original renders change no earned identity/history/XP/save")
 finish_capture()
