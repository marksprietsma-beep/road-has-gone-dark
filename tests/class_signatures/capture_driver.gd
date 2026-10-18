extends "res://tests/nature_repertoires/capture_driver.gd"
## All images come from actual Windows Godot viewport pixels, never compositing.
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0")
 capture_folder=OS.get_environment("GAME129_ROOT").get_base_dir().path_join("captures");DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];slot=WorldOriginLore.read_json(base.path_join("proof.json")).slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"original earned martial campaign reload")
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved := WorldOriginLore.read_json(OS.get_environment("GAME129_ROOT").path_join("saved.json"))
 for i in 3:
  var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  await photograph_scene("earned-"+["soulknife","warblade","swordsage"][i]+"-sheet",false)
 for cls in ["soulknife","warblade","crusader","swordsage"]:
  var sheet := await open_sheet();var id: String=state.party_ids[0]
  var fixture := render_identity(saved.records[cls+"20"],id)
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=fixture;sheet.selected=1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · "+cls.capitalize()+"20 · not earned XP"
  await photograph_scene("fixture-"+cls+"-level20-sheet",true,Vector2i(2560,1440))
 for key in ["soulknife","riposte","swordsage","echo"]:
  var combat := await open_combat()
  var b: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(b.units.a.record);combat.message="DEVELOPMENT FIXTURE · actual resolved "+key+" · resources/reactions spent";combat.mode="attack";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  if key=="riposte":await photograph_scene("fixture-riposte-small",true,Vector2i(640,360))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active)
 combat.message="EARNED · three level8 careers · 490XP · class actions saved";combat.refresh()
 await photograph_scene("earned-saved-class-signatures",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume")
 check(resumed.ok and RulesJson.digest(resumed.state)==before,"captures never rewrite earned campaign/history/XP")
 finish_capture()
func open_combat() -> Control:
 PartyService.handoff={};get_tree().change_scene_to_file("res://scenes/combat/first_adventure.tscn")
 while get_tree().current_scene==null or not "engine" in get_tree().current_scene:await get_tree().process_frame
 var combat: Control=get_tree().current_scene;combat.set_process(false);return combat
func photograph_scene(name: String,fixture: bool,resolution := Vector2i(1280,720)) -> void:
 get_tree().root.size=resolution
 for frame in 5:await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var image := get_tree().root.get_texture().get_image()
 var file := name+"-%dx%d.png"%[image.get_width(),image.get_height()]
 check(image.save_png(capture_folder.path_join(file))==OK,"actual Godot image "+name)
 screenshots.append({"file":file,"width":image.get_width(),"height":image.get_height(),"requested_width":resolution.x,"requested_height":resolution.y,"sha256":FileAccess.get_sha256(capture_folder.path_join(file)),"development_fixture":fixture,"earned_xp":false if fixture else 490})
