extends "res://tests/martial_careers/capture.gd"
## Original production scenes, real Windows pixels and labelled actual source states.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");capture_folder=OS.get_environment("GROVE_SUMMONER_CAPTURE_ROOT");DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded: Dictionary=service.operate(entry,slot,"resume");check(loaded.ok,"actual earned810XP/10 campaign loads for original Godot renders")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(OS.get_environment("GROVE_SUMMONER_ROOT").path_join("saved.json")))
 var born: Dictionary=service.store.create_playthrough(entry.world,int(state.origin.state_id),int(state.origin.home_burg_id),int(state.origin.get("province_id",0)))
 check(born.ok and service.store.save_new(born.state.playthrough_id,born.state,entry.world).ok,"independent fresh creator uses original writer")
 if born.ok:
  PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
  get_tree().change_scene_to_file("res://scenes/ui/party_creation.tscn")
  while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
  var creator: CharacterScreen=get_tree().current_scene
  while creator.thread!=null:await get_tree().process_frame
  await photograph_scene("ordinary-first-open-creator",false);screenshots.back().earned_xp=0
  select_option(creator.class_choice,"wizard");creator.detail_tabs.current_tab=1;show_tab(creator.editor.sections,"Spells")
  await photograph_scene("ordinary-wizard-spells",false,Vector2i(2560,1440));screenshots.back().earned_xp=0
  select_option(creator.class_choice,"spirit-shaman");creator.detail_tabs.current_tab=1;show_tab(creator.editor.sections,"Spells")
  await photograph_scene("ordinary-spirit-retrieval",false);screenshots.back().earned_xp=0
  select_option(creator.class_choice,"druid");creator.detail_tabs.current_tab=1;select_option(creator.editor.career_pickers["druid-companion"],"leopard");show_tab(creator.editor.sections,"Specialisation")
  await photograph_scene("ordinary-druid-companion",false,Vector2i(2560,1440));screenshots.back().earned_xp=0
  await photograph_scene("ordinary-druid-small",false,Vector2i(640,360));screenshots.back().earned_xp=0
 for i in 3:
  var sheet: CharacterScreen=await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  sheet.title.text="EARNED · 810XP · total10 · "+["Spirit Shaman7 / Grove Warden3","Wizard5 / Bonded Summoner5","Druid6 / Spirit Shaman1 / Grove Warden3 / Leopard"][i]
  await photograph_scene("earned-"+["grove-shaman","bonded-wizard","grove-druid"][i]+"-sheet",false,Vector2i(2560,1440))
  sheet.detail_tabs.current_tab=4;await photograph_scene("earned-"+["shaman-retrieval","bonded-parent-preparation","druid-nature-preparation"][i],false,Vector2i(2560,1440))
  if i==1:
   sheet.detail_tabs.current_tab=3;show_tab(sheet.advance_editor.sections,"Progression");check(sheet.advancement_button.disabled,"810 earnedXP cannot buy an unfunded eleventh level")
   await photograph_scene("earned-no-free-advancement",false)
 var original_root: String=service.store.save_root;var original_slot: String=slot
 for i in 3:
  var info: Dictionary=proof.earned_entries[state.party_ids[i]];var earned: Dictionary=WorldOriginLore.read_json(base.path_join("earned-entry-"+str(i)+".json"))
  check(RulesJson.digest(earned)==info.state_hash,"exact actually earned pre-entry qualification state")
  var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("capture-entry-"+str(i));check(fork.save_new(slot,earned,entry.world).ok,"pre-entry display fork preserves source through original writer")
  service.store.save_root=fork.save_root;service.library.save_root=fork.save_root
  var sheet: CharacterScreen=await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=3;select_option(sheet.advance_editor.class_picker,info.path);show_tab(sheet.advance_editor.sections,"Specialisation")
  check(not sheet.advancement_button.disabled and sheet.advance_editor.career_pickers.has("bonded-casting"if i==1 else"grove-casting"),"actual funded prestige and existing-parent controls")
  sheet.title.text="EARNED · %dXP · optional %s / %s preview, not committed"%[int(info.earned_xp),str(info.path),str(info.parent)]
  await photograph_scene("earned-entry-"+str(i)+"-parent",false,Vector2i(2560,1440));screenshots.back().earned_xp=info.earned_xp
  select_option(sheet.advance_editor.class_picker,info.parent);check(not sheet.advancement_button.disabled,"qualified player can explicitly decline prestige")
  await photograph_scene("earned-entry-"+str(i)+"-decline-preview",false);screenshots.back().earned_xp=info.earned_xp
  check(RulesJson.digest(fork.load_save(slot,entry.world).state)==info.state_hash,"parent and decline renders commit no level or XP")
  service.store.save_root=base.path_join("declined-"+str(i));service.library.save_root=service.store.save_root
  sheet=await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2;sheet.title.text="EARNED · %dXP · actually committed %s decline · same original identity"%[int(info.earned_xp),str(info.path)]
  await photograph_scene("earned-entry-"+str(i)+"-decline-committed",false,Vector2i(2560,1440));screenshots.back().earned_xp=info.earned_xp
 service.store.save_root=original_root;service.library.save_root=original_root;slot=original_slot
 for key in ["grove-shaman3-total20","grove-druid3-total20","bonded-wizard5-total20","bonded-sorcerer5-total20"]:
  var sheet: CharacterScreen=await open_sheet();var id: String=state.party_ids[0]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[key],id);sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · total20 · "+key+" · not earned20"
  await photograph_scene("fixture-"+key+"-sheet",true,Vector2i(2560,1440))
 for key in ["sanctuary_saved_hit","grove-protection-3","active-call5","bonded-summoner-call-renewal-spirit","call-frost-hound","owner_down"]:
  var combat: Control=await open_combat();var battle: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(battle.units.a.record);combat.mode="attack";combat.message="DEVELOPMENT FIXTURE · "+key+" · actual costs/effects/owned actors; humanoid creature art fallback";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  if key=="active-call5":await photograph_scene("fixture-owned-small",true,Vector2i(640,360))
 var active: Dictionary=WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat: Control=await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.mode="attack";combat.message="EARNED · 810XP/10 · real summon and companion attacks; Grove/Bonded actions paid and saved";combat.refresh()
 await photograph_scene("earned-connected-grove-bonded",false,Vector2i(2560,1440))
 await photograph_scene("earned-connected-grove-bonded",false)
 var resumed: Dictionary=service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"renders never alter original identities, class histories, XP, spells, companions or save")
 finish_capture()
