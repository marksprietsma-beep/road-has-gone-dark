extends "res://tests/hybrid_acceptance/capture.gd"
## Original Godot pixels; saved earned people and labelled development views.
func show_tab(tabs: TabContainer,title: String) -> void:
 for n in tabs.get_tab_count():
  if tabs.get_tab_title(n)==title:tabs.current_tab=n;return
 check(false,"production tab exists "+title)
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("MARTIAL_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof := WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual earned490XP/8 campaign resumes for original renders")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(OS.get_environment("MARTIAL_ROOT").path_join("saved.json")))
 var born := service.store.create_playthrough(entry.world,int(state.origin.state_id),int(state.origin.home_burg_id),int(state.origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"separate fresh ordinary creator through original writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  await photograph_scene("ordinary-first-open-creator",false);screenshots.back().earned_xp=0
  select_option(creator.class_choice,"fighter");creator.detail_tabs.current_tab=1
  select_option(creator.editor.career_pickers["fighter-choice-1"],"bow")
  for id in creator.editor.equipment_pickers:
   var enabled: bool=id in ["bow","leathers"]
   if creator.editor.equipment_pickers[id].button_pressed!=enabled:creator.editor.equipment_pickers[id].button_pressed=enabled
  show_tab(creator.editor.sections,"Specialisation")
  await photograph_scene("ordinary-fighter-bow-specialisation",false,Vector2i(2560,1440));screenshots.back().earned_xp=0
  show_tab(creator.editor.sections,"Equipment")
  await photograph_scene("ordinary-fighter-equipment",false);screenshots.back().earned_xp=0
  select_option(creator.class_choice,"barbarian");select_option(creator.editor.career_pickers["barbarian-choice-1"],"resilient");show_tab(creator.editor.sections,"Specialisation")
  await photograph_scene("ordinary-barbarian-rage-choice",false);screenshots.back().earned_xp=0
  await photograph_scene("ordinary-barbarian-small",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for i in 3:
  var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  sheet.title.text="EARNED · 490XP · class8 · "+["Fighter blade","Fighter bow","Barbarian"][i]
  await photograph_scene("earned-"+["fighter-blade","fighter-bow","barbarian"][i]+"-sheet",false,Vector2i(2560,1440))
  if i==1:
   sheet.detail_tabs.current_tab=3;show_tab(sheet.advance_editor.sections,"Feats")
   check(sheet.advancement_button.disabled,"earned8 cannot commit an unfunded ninth level")
   await photograph_scene("earned-feat-prerequisites-no-free-xp",false)
 for key in ["blade20","bow20","barbarian-resilient20","barbarian-reckless20"]:
  var sheet := await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[key],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · class20 · "+key+" · not earned XP"
  await photograph_scene("fixture-"+key+"-sheet",true,Vector2i(2560,1440))
 for key in ["blade","bow","rage"]:
  var combat := await open_combat();var battle: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(battle.units.a.record);combat.mode="attack";combat.message="DEVELOPMENT FIXTURE · "+key+" · actual paid actions, not earned levels";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  if key=="bow":await photograph_scene("fixture-bow-small",true,Vector2i(640,360))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · 490XP/8 · both Fighter disciplines and Resilient rage paid and saved";combat.refresh()
 await photograph_scene("earned-connected-martial-actions",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"captures preserve original earned campaign XP, identities, resources and saves")
 finish_capture()
