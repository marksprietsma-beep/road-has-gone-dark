extends "res://tests/class_signatures/capture_driver.gd"
## Original production Godot renders; fixtures are never mistaken for earned XP.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("UPPER_NATURE_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof := WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"real earned490XP campaign for captures")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved := WorldOriginLore.read_json(OS.get_environment("UPPER_NATURE_ROOT").path_join("saved.json"))
 var origin: Dictionary=state.origin
 var born := service.store.create_playthrough(entry.world,int(origin.state_id),int(origin.home_burg_id),int(origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"fresh creator original writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  select_option(creator.class_choice,"sorcerer");creator.detail_tabs.current_tab=1
  await photograph_scene("ordinary-sorcerer-creator",false);screenshots.back().earned_xp=0
  await photograph_scene("ordinary-sorcerer-small",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for index in 2:
  var cls: String=["sorcerer","druid"][index]
  var sheet := await open_sheet();sheet._select_member(index);sheet.detail_tabs.current_tab=2
  sheet.title.text="EARNED · "+cls+"8 / 490XP · upper tiers are not earned here"
  await photograph_scene("earned-"+cls+"-sheet",false,Vector2i(2560,1440))
  for tier in [8,9]:
   sheet=await open_sheet();var id: String=state.party_ids[index]
   sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[cls+"20"],id);sheet.selected=index+1;sheet.refresh();sheet.detail_tabs.current_tab=4
   sheet.title.text="DEVELOPMENT FIXTURE · "+cls+"20 / tier"+str(tier)+" · not earned XP"
   sheet.spellbook.repertoire_search.text="tier "+str(tier);sheet.spellbook.repertoire_search.text_changed.emit(sheet.spellbook.repertoire_search.text)
   await photograph_scene("fixture-"+cls+"-tier"+str(tier),true)
   await photograph_scene("fixture-"+cls+"-tier"+str(tier)+"-large",true,Vector2i(2560,1440))
  sheet.detail_tabs.current_tab=2
  await photograph_scene("fixture-"+cls+"-sheet",true,Vector2i(2560,1440))
 for key in ["sorcerer-refraction-guard","sorcerer-cascade-well","druid-heartwood-renewal","druid-wildheart-mantle","companion_form","renewing-pet-wolf"]:
  var combat := await open_combat();var b: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(b.units.a.record);combat.mode="attack";combat.message="DEVELOPMENT FIXTURE · "+key+" · actual saved resources/body/status";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  if key in ["sorcerer-refraction-guard","companion_form"]:await photograph_scene("fixture-"+key+"-large",true,Vector2i(2560,1440))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · actual saved bloodline/nature actions · level8 / 490XP";combat.refresh()
 await photograph_scene("earned-connected-class-actions",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"captures preserve actual campaign XP/history/resources")
 finish_capture()

func select_option(picker: OptionButton,id: String) -> void:
 for n in picker.item_count:
  if picker.get_item_metadata(n)==id:picker.select(n);picker.item_selected.emit(n);return
 check(false,"actual creator option missing "+id)
