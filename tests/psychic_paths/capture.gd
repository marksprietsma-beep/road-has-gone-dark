extends "res://tests/class_signatures/capture_driver.gd"
## Unmodified Windows viewport pixels, with earned and development labels.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("GAME127_PATH_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof := WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"real earned810XP campaign for captures")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state);var primary_root: String=service.store.save_root
 var saved := WorldOriginLore.read_json(OS.get_environment("GAME127_PATH_ROOT").path_join("saved.json"))
 var origin: Dictionary=state.origin
 var born := service.store.create_playthrough(entry.world,int(origin.state_id),int(origin.home_burg_id),int(origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"ordinary creator uses the original campaign writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":primary_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  select_option(creator.class_choice,"psion")
  check(not creator.editor.class_options().has("metamind") and not creator.editor.class_options().has("pyrokineticist"),"real creator displays base classes, never prestige")
  creator.detail_tabs.current_tab=1
  for i in creator.editor.sections.get_tab_count():
   if creator.editor.sections.get_tab_title(i)=="Powers":creator.editor.sections.current_tab=i
  await photograph_scene("ordinary-psion-creator",false);screenshots.back().earned_xp=0
  await photograph_scene("ordinary-psion-small",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for cls in ["metamind","pyrokineticist"]:
  var row: Dictionary=proof.earned_entries[cls];service.store.save_root=row.save_root
  var sheet := await open_sheet();sheet._select_member(int(row.member));sheet.detail_tabs.current_tab=3
  select_option(sheet.advance_editor.class_picker,cls)
  check(sheet.advance_editor.preview.ok,"actual funded earned prestige preview "+cls)
  sheet.title.text="EARNED · "+cls+" entry · "+str(row.earned_xp)+"XP · total"+str(int(row.next_level)-1)+" → "+str(row.next_level)
  await photograph_scene("earned-"+cls+"-entry",false);screenshots.back().earned_xp=row.earned_xp
  await photograph_scene("earned-"+cls+"-entry-large",false,Vector2i(2560,1440));screenshots.back().earned_xp=row.earned_xp
  var fork := GamePlaythroughStore.new();fork.save_root=row.save_root;var retained := fork.load_save(slot,entry.world)
  check(retained.ok and RulesJson.digest(retained.state)==row.state_hash,"entry preview never commits a free level or rewrites earned history")
 service.store.save_root=primary_root
 for i in 2:
  var cls: String=["metamind","pyrokineticist"][i];var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  sheet.title.text="EARNED · "+cls+" career · total10 / 810XP"
  await photograph_scene("earned-"+cls+"-sheet",false,Vector2i(2560,1440))
  sheet=await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[cls+"-total20"],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · "+cls+"10 / total20 · not earned XP"
  await photograph_scene("fixture-"+cls+"-advanced-sheet",true,Vector2i(2560,1440))
 for key in ["ready-metamind10","metamind10","pyrokineticist1","pyrokineticist10"]:
  var combat := await open_combat();var battle: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(battle.units.a.record);combat.mode="metamind-reclaim" if "metamind" in key else "attack";combat.message="DEVELOPMENT FIXTURE · "+key+" · actual saved resources/effects";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  await photograph_scene("fixture-"+key+"-large",true,Vector2i(2560,1440))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · actual saved reclamation, fire and ally protection · total10 / 810XP";combat.refresh()
 await photograph_scene("earned-saved-path-combat",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"captures preserve primary earned save/history/XP")
 finish_capture()

func select_option(picker: OptionButton,id: String) -> void:
 for i in picker.item_count:
  if picker.get_item_metadata(i)==id:picker.select(i);picker.item_selected.emit(i);return
 check(false,"actual option not found "+id)

func photograph_scene(name: String,fixture: bool,resolution := Vector2i(1280,720)) -> void:
 get_tree().root.size=resolution;get_tree().root.warp_mouse(Vector2(2,2))
 for frame in 5:await get_tree().process_frame
 var scene: Node=get_tree().current_scene
 if scene!=null and "action_buttons" in scene and "metamind" in name and scene.action_buttons.has("metamind-reclaim"):
  var container: Node=scene.action_buttons["metamind-reclaim"].get_parent()
  while container!=null and not container is ScrollContainer:container=container.get_parent()
  if container is ScrollContainer:container.ensure_control_visible(scene.action_buttons["metamind-reclaim"])
 await super.photograph_scene(name,fixture,resolution)
 if not fixture:screenshots.back().earned_xp=810
