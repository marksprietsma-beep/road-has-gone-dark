extends "res://tests/class_signatures/capture_driver.gd"
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0")
 capture_folder=OS.get_environment("GAME146_ROOT").get_base_dir().path_join("captures");DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];slot=WorldOriginLore.read_json(base.path_join("proof.json")).slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual earned Scout/Rogue/Knight campaign reload")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved := WorldOriginLore.read_json(OS.get_environment("GAME146_ROOT").path_join("saved.json"))
 for i in 3:
  var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  await photograph_scene("earned-"+["scout","rogue","knight"][i]+"-sheet",false)
 for key in ["scout20","rogue20","swashbuckler20","knight20","duelist","arcane-trickster"]:
  var sheet := await open_sheet();var id: String=state.party_ids[0]
  var fixture := render_identity(saved.records[key],id)
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=fixture;sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · "+key+" · not earned XP"
  await photograph_scene("fixture-"+key+"-sheet",true,Vector2i(2560,1440))
 for key in ["flourish-true","flourish-false","precision-true","scout","knight"]:
  var combat := await open_combat();var b: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(b.units.a.record);combat.message="DEVELOPMENT FIXTURE · resolved "+key+" · actual resource/hit log";combat.mode="attack";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  if key=="flourish-true":await photograph_scene("fixture-fencing-small",true,Vector2i(640,360))
 var resumed := service.operate(entry,slot,"resume")
 check(resumed.ok and RulesJson.digest(resumed.state)==before,"captures never rewrite earned campaign/history/XP")
 finish_capture()
