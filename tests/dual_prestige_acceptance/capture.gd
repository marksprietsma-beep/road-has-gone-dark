extends "res://tests/hybrid_acceptance/capture.gd"
## Original Godot pixels; real earned saves and explicitly labelled fixture views.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("DUAL_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof := WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual640XP/9 campaign resumes for screenshots")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(OS.get_environment("DUAL_ROOT").path_join("saved.json")))
 var born := service.store.create_playthrough(entry.world,int(state.origin.state_id),int(state.origin.home_burg_id),int(state.origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"ordinary new campaign through sole writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  select_option(creator.class_choice,"wizard");creator.detail_tabs.current_tab=1
  await photograph_scene("ordinary-base-classes-only",false);screenshots.back().earned_xp=0
 for i in 3:
  var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  var r: Dictionary=state.mechanics.records[state.party_ids[i]];var d := CharacterBuilderRecords.kernel(state).derive_character(r)
  sheet.title.text="EARNED · 640XP · total9 · "+str(d.snapshot.class_levels)
  await photograph_scene("earned-"+["wizard-theurge","sorcerer-theurge","duskblade-champion"][i]+"-sheet",false,Vector2i(2560,1440))
  if i<2:
   sheet.detail_tabs.current_tab=4
   await photograph_scene("earned-"+["prepared-dual-traditions","spontaneous-and-divine"][i],false)
 var original_root: String=service.store.save_root
 for cls in ["wizard","sorcerer","duskblade"]:
  var witness: Dictionary=proof.earned_entry_witnesses[cls]
  var earned := WorldOriginLore.read_json(base.path_join(witness.file));check(RulesJson.digest(earned)==witness.state_hash,"unchanged actual pre-entry witness "+cls)
  var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("capture-entry-"+cls)
  check(fork.save_new(slot,earned,entry.world).ok,"real funded pre-entry screenshot fork")
  service.store.save_root=fork.save_root;service.library.save_root=fork.save_root
  var sheet := await open_sheet();sheet._select_member(0 if cls=="wizard" else (1 if cls=="sorcerer" else 2));sheet.detail_tabs.current_tab=3
  select_option(sheet.advance_editor.class_picker,witness.path)
  var parent: String="abjurant-casting" if cls=="duskblade" else "mystic-theurge-arcane"
  select_option(sheet.advance_editor.career_pickers[parent],cls)
  if cls!="duskblade":select_option(sheet.advance_editor.career_pickers["mystic-theurge-divine"],"cleric")
  check(not sheet.advancement_button.disabled,"actual earned XP funds optional manual prestige "+cls)
  sheet.title.text="EARNED · "+str(witness.earned_xp)+"XP · optional "+str(witness.path)+" preview, not assigned"
  sheet.advance_editor.sections.current_tab=4
  await photograph_scene("earned-"+cls+"-optional-entry",false,Vector2i(2560,1440));screenshots.back().earned_xp=witness.earned_xp
  if cls=="wizard":
   sheet.advance_editor.sections.current_tab=3
   await photograph_scene("earned-permanent-prestige-prerequisites",false,Vector2i(2560,1440));screenshots.back().earned_xp=witness.earned_xp
  select_option(sheet.advance_editor.class_picker,cls)
  check(not sheet.advancement_button.disabled,"qualified character may instead continue base class "+cls)
  check(RulesJson.digest(fork.load_save(slot,entry.world).state)==witness.state_hash,"selection and decline preview never spend XP or assign prestige")
 service.store.save_root=original_root;service.library.save_root=original_root
 for key in ["theurge20","champion20"]:
  var sheet := await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[key],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · total20 · "+key+" · not earned XP"
  await photograph_scene("fixture-"+key+"-sheet",true,Vector2i(2560,1440))
 for key in ["theurge:large","theurge:release","theurge:refuge","retaliation:5:1","retaliation:5:19","retaliation:5:20"]:
  var combat := await open_combat();var b: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(b.units.a.record);combat.mode="attack";combat.message="DEVELOPMENT FIXTURE · actual resolved "+key+" · action/resource spent";combat.refresh()
  await photograph_scene("fixture-"+key.replace(":","-")+"-combat",true)
  if key=="theurge:refuge":await photograph_scene("fixture-refuge-small",true,Vector2i(640,360))
 for variant in ["a","b"]:
  var active := WorldOriginLore.read_json(OS.get_environment("DUAL_CONNECTED_BASE").path_join("connected-"+variant).path_join("active-state.json"))
  var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · 640XP/9 before isolated fork · actual arcane, divine and Champion actions committed";combat.refresh()
  await photograph_scene("earned-connected-"+variant,false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"captures preserve actual campaign XP/history/resources/save")
 finish_capture()
