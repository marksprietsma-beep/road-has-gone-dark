extends "res://tests/class_signatures/capture_driver.gd"
## Untouched viewport PNGs, rendered by native Windows Godot. No compositor.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("GAME127_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];slot=WorldOriginLore.read_json(base.path_join("proof.json")).slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual earned campaign reload for captures")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(OS.get_environment("GAME127_ROOT").path_join("saved.json")))
 var origin: Dictionary=state.origin
 var born := service.store.create_playthrough(entry.world,int(origin.state_id),int(origin.home_burg_id),int(origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"separate ordinary creator through original writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  for cls in ["psychic-warrior","divine-mind"]:
   for i in creator.class_choice.item_count:
    if creator.class_choice.get_item_metadata(i)==cls:creator.class_choice.select(i);creator.class_choice.item_selected.emit(i);break
   check(creator.editor.class_id==cls,"actual first-open creator selects "+cls)
   creator.detail_tabs.current_tab=1
   for i in creator.editor.sections.get_tab_count():
    if creator.editor.sections.get_tab_title(i)=="Powers":creator.editor.sections.current_tab=i
   await photograph_scene("ordinary-creator-"+cls+"-powers",false);screenshots.back().earned_xp=0
   await photograph_scene("ordinary-creator-"+cls+"-small",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for i in 3:
  var cls: String=["psychic-warrior","divine-mind","cognition-adept"][i];var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  sheet.title.text="EARNED · "+cls+" career, total8 · 490XP before connected encounter"
  await photograph_scene("earned-"+cls+"-sheet",false,Vector2i(2560,1440))
  sheet.detail_tabs.current_tab=3
  await photograph_scene("earned-"+cls+"-advancement",false)
  sheet=await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[cls+"20" if i<2 else "cognition5"],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · "+cls+("20" if i<2 else " five prestige levels / total13")+" · not earned XP"
  await photograph_scene("fixture-"+cls+"-advanced-sheet",true,Vector2i(2560,1440))
 for key in ["augmented_warrior","bulwark8","cognition-strike5","reach-cognition","transformed"]:
  var combat := await open_combat();var battle: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(battle.units.a.record);combat.mode="cognition-strike-1" if "cognition" in key else "attack";combat.message="DEVELOPMENT FIXTURE · "+key+" · actual saved effects and resources"
  combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  await photograph_scene("fixture-"+key+"-large",true,Vector2i(2560,1440))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · real saved warrior strike / divine aura / earned cognition strike · actual costs";combat.refresh()
 await photograph_scene("earned-saved-cohort-combat",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume")
 check(resumed.ok and RulesJson.digest(resumed.state)==before,"captures preserve earned characters, XP and save bytes")
 finish_capture()

func photograph_scene(name: String,fixture: bool,resolution := Vector2i(1280,720)) -> void:
 # Move the real pointer off the battlefield before rendering; no pixel edits.
 get_tree().root.size=resolution
 get_tree().root.warp_mouse(Vector2(2,2))
 for frame in 5:await get_tree().process_frame
 var scene: Node=get_tree().current_scene
 if "cognition" in name and scene!=null and "action_buttons" in scene:
  var action_id := "cognition-strike-5" if "cognition-strike5" in name else "cognition-strike-1"
  if scene.action_buttons.has(action_id):
   var container: Node=scene.action_buttons[action_id].get_parent()
   while container!=null and not container is ScrollContainer:container=container.get_parent()
   if container is ScrollContainer:container.ensure_control_visible(scene.action_buttons[action_id])
 await super.photograph_scene(name,fixture,resolution)
