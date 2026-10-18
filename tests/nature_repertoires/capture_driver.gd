extends "res://tests/character_completeness/journey_driver.gd"
## Actual production scenes/components. Upper-tier screen overrides are render-only,
## explicitly labelled development fixtures; no campaign, XP or save is rewritten.
var capture_folder := ""
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0")
 capture_folder=OS.get_environment("GAME133_ROOT").get_base_dir().path_join("captures");DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];var proof := WorldOriginLore.read_json(base.path_join("proof.json"));slot=proof.slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"original earned campaign reload for real Godot evidence")
 if not loaded.ok:finish_capture();return
 state=loaded.state
 var before := RulesJson.digest(state)
 var saved := WorldOriginLore.read_json(OS.get_environment("GAME133_ROOT").path_join("saved.json"))
 var earned: Dictionary=state.duplicate(true)
 for i in [0,1]:
  var ui := await open_sheet()
  ui._select_member(i);ui.detail_tabs.current_tab=4;ui.spellbook.repertoire_search.text="tier 4";ui.spellbook.repertoire_search.text_changed.emit("tier 4")
  check(ui.spellbook.controls.has("sorcerer-crystal-reservoir" if i==0 else "druid-bramble-tether"),"earned production spellbook includes newly unlocked tier4")
  await photograph_scene("earned-"+("sorcerer" if i==0 else "druid")+"-tier4",false)
  ui.detail_tabs.current_tab=3
  if i==0:await photograph_scene("earned-advancement-no-free-xp",false)
 for cls in ["sorcerer","druid"]:
  var key: String="sorcerer-starfall-rupture" if cls=="sorcerer" else "druid-winters-verdict"
  var ui := await open_sheet()
  var index: int=0 if cls=="sorcerer" else 1
  var id: String=earned.party_ids[index]
  var fixture := render_identity(saved.records[key],id)
  ui.state=earned.duplicate(true);ui.state.mechanics.records[id]=fixture;ui.selected=index+1;ui.refresh()
  ui.title.text="DEVELOPMENT FIXTURE · "+cls.capitalize()+"20 · not earned XP"
  for tier in [6,7]:
   ui.detail_tabs.current_tab=4;ui.spellbook.repertoire_search.text="tier "+str(tier);ui.spellbook.repertoire_search.text_changed.emit("tier "+str(tier))
   await photograph_scene("fixture-"+cls+"-tier"+str(tier),true)
  ui.detail_tabs.current_tab=2
  await photograph_scene("fixture-"+cls+"-sheet",true,Vector2i(2560,1440))
 var ui := await open_sheet()
 var id: String=earned.party_ids[0];var hybrid := render_identity(saved.records["hybrid:sorcerer-starfall-rupture"],id)
 ui.state=earned.duplicate(true);ui.state.mechanics.records[id]=hybrid;ui.selected=1;ui.refresh();ui.detail_tabs.current_tab=4;ui.spellbook.repertoire_search.text="tier 6";ui.spellbook.repertoire_search.text_changed.emit("tier 6")
 ui.title.text="DEVELOPMENT FIXTURE · Sorcerer / Druid / Mystic Theurge · not earned XP"
 await photograph_scene("fixture-hybrid-independent-tracks",true)
 # Display the exact saved post-canopy battle through the real combat scene.
 PartyService.handoff={}
 get_tree().change_scene_to_file("res://scenes/combat/first_adventure.tscn")
 while get_tree().current_scene==null or not get_tree().current_scene is Control or not "engine" in get_tree().current_scene:await get_tree().process_frame
 var combat: Control=get_tree().current_scene
 combat.set_process(false)
 var battle: Dictionary=saved.battle.duplicate(true)
 combat.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
 for i in 3:
  var m: Dictionary=earned.party.members[i].duplicate(true);m.character_id=["a","b","c"][i];combat.state.party.members.append(m)
 combat.engine=TacticalAuras.new(battle.units.a.record);combat.message="DEVELOPMENT FIXTURE · actual Packward canopy resolved · slot/action spent"
 combat.mode="druid-packward-canopy";combat.refresh()
 await photograph_scene("fixture-packward-combat",true)
 await photograph_scene("fixture-packward-combat-small",true,Vector2i(640,360))
 var connected := OS.get_environment("GAME133_CONNECTED_ROOT")
 if connected.is_empty():connected=OS.get_environment("GAME133_ROOT").get_base_dir().path_join("connected")
 var active_state := WorldOriginLore.read_json(connected.path_join("active-state.json"))
 check(not active_state.is_empty(),"real committed earned mid-battle evidence exists")
 if not active_state.is_empty():
  PartyService.handoff={};get_tree().change_scene_to_file("res://scenes/combat/first_adventure.tscn")
  while get_tree().current_scene==null or not "engine" in get_tree().current_scene:await get_tree().process_frame
  combat=get_tree().current_scene;combat.set_process(false);combat.state=active_state;combat.engine=TacticalAuras.new(active_state)
  combat.message="EARNED · Sorcerer / Druid level8 · both new tier4 spells committed · 490XP"
  combat.mode="druid-bramble-tether";combat.refresh()
  await photograph_scene("earned-midbattle-spells-saved",false)
  var scroll: ScrollContainer=combat.log_label.get_parent().get_parent()
  scroll.ensure_control_visible(combat.log_label)
  await photograph_scene("earned-midbattle-spell-log",false,Vector2i(2560,1440))
 check(RulesJson.digest(state)==before,"visual fixture overrides never alter original earned campaign")
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok and RulesJson.digest(resumed.state)==before,"screenshots write no gameplay, XP or campaign save")
 finish_capture()
func open_sheet() -> CharacterScreen:
 CharacterScreen.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 get_tree().change_scene_to_file("res://scenes/ui/character_sheet.tscn")
 while get_tree().current_scene==null or not get_tree().current_scene is CharacterScreen:await get_tree().process_frame
 var ui: CharacterScreen=get_tree().current_scene
 while ui.thread!=null:await get_tree().process_frame
 return ui
func photograph_scene(name: String,fixture: bool,resolution := Vector2i(1280,720)) -> void:
 get_tree().root.size=resolution
 for frame in 5:await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var file := name+"-%dx%d.png"%[resolution.x,resolution.y]
 check(get_tree().root.get_texture().get_image().save_png(capture_folder.path_join(file))==OK,"actual production Godot screenshot "+name)
 screenshots.append({"file":file,"sha256":FileAccess.get_sha256(capture_folder.path_join(file)),"development_fixture":fixture,"earned_xp":false if fixture else 490})
func finish_capture() -> void:
 FileAccess.open(capture_folder.path_join("screenshots.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"screenshots":screenshots,"scope":"Real production Godot screens. Render-only high-level development fixtures explicitly labelled, not earned careers."}))
 get_tree().quit(1 if failures else 0)

func render_identity(record: Dictionary,id: String) -> Dictionary:
 # Render-only fixture: keep persistent companion ownership internally valid.
 # The actual earned campaign and saved mechanics proof are never modified.
 var original := RulesCharacter.new(RulesRecords.registry(record)).derive_character(record)
 check(original.ok,"render source has valid original pinned owner/companion "+JSON.stringify(original.get("errors",[])))
 if not original.ok:return {}
 var r: Dictionary=record.duplicate(true);r.character_id=id;r.rules_ref=RulesRecords.registry(state).rules_ref()
 var pets := {}
 for previous in r.runtime.companions:
  var pet: Dictionary=r.runtime.companions[previous].duplicate(true)
  var pet_id := RulesEntities.identity(id);pet.record.character_id=pet_id
  # The existing render-only owner projection also needs an exact nested pin.
  # Do not recreate the creature, change its history, or touch the saved source.
  pet.record.rules_ref=r.rules_ref.duplicate(true);pets[pet_id]=pet
 r.runtime.companions=pets
 var rendered := RulesCharacter.new(RulesRecords.registry(r)).derive_character(r)
 check(rendered.ok,"render fixture retains valid owner/companion identity "+id+" "+JSON.stringify(rendered.get("errors",[])))
 return r
