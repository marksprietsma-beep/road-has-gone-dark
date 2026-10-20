extends "res://tests/class_signatures/capture_driver.gd"
func run() -> void:
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0")
 capture_folder=OS.get_environment("GAME150_ROOT").get_base_dir().path_join("captures");DirAccess.make_dir_recursive_absolute(capture_folder)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0];slot=WorldOriginLore.read_json(base.path_join("proof.json")).slot
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"actual earned prepared-caster campaign reload: "+str(loaded.get("error",loaded.get("errors",[]))))
 if not loaded.ok:finish_capture();return
 state=loaded.state;var before := RulesJson.digest(state)
 var saved := WorldOriginLore.read_json(OS.get_environment("GAME150_ROOT").path_join("saved.json"))
 for i in [0,1]:
  var cls: String="wizard" if i==0 else "cleric"
  var sheet := await open_sheet();sheet._select_member(i);sheet.detail_tabs.current_tab=2
  await photograph_scene("earned-"+cls+"-sheet",false)
  sheet=await open_sheet();var id: String=state.party_ids[i]
  sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[cls+"20"],id);sheet.selected=i+1;sheet.refresh();sheet.detail_tabs.current_tab=2
  sheet.title.text="DEVELOPMENT FIXTURE · "+cls+"20 · not earned XP"
  await photograph_scene("fixture-"+cls+"20-sheet",true,Vector2i(2560,1440))
  var record: Dictionary=saved.records["wizard-unweaving-tide" if cls=="wizard" else "cleric-concord-release"].duplicate(true)
  var second: String="wizard-stillness-lattice" if cls=="wizard" else "cleric-renewing-benediction"
  record.choices.prepared_abilities.append(second);record.choices.spell_preparations[second]=1
  sheet=await open_sheet();sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(record,id);sheet.selected=i+1;sheet.refresh();sheet.detail_tabs.current_tab=4
  sheet.title.text="DEVELOPMENT FIXTURE · selected upper spells · spent pools retained"
  sheet.spellbook.repertoire_search.text="tier 8"
  sheet.spellbook.repertoire_search.text_changed.emit("tier 8")
  check(sheet.spellbook.controls[record.choices.prepared_abilities[0]].get_parent().visible,"actual tier8 search exposes selected upper spell")
  await photograph_scene("fixture-"+cls+"-tier8-preparation",true)
  sheet.spellbook.repertoire_search.text="tier 9"
  sheet.spellbook.repertoire_search.text_changed.emit("tier 9")
  check(sheet.spellbook.controls[second].get_parent().visible,"actual tier9 search exposes selected upper spell")
  await photograph_scene("fixture-"+cls+"-tier9-preparation",true,Vector2i(2560,1440))
  sheet=await open_sheet();sheet.state=state.duplicate(true);sheet.state.mechanics.records[id]=render_identity(saved.records[cls+"5"],id);sheet.selected=i+1;sheet.refresh();sheet.detail_tabs.current_tab=3
  sheet.title.text="DEVELOPMENT FIXTURE · deliberate advanced "+cls+" choice"
  sheet.advance_editor.sections.current_tab=4
  get_tree().root.size=Vector2i(1280,720)
  for frame in 5:await get_tree().process_frame
  var picker: OptionButton=sheet.advance_editor.career_pickers[cls+"-choice-6"]
  var scroll: ScrollContainer=sheet.detail_tabs.get_current_tab_control();scroll.ensure_control_visible(picker)
  for frame in 3:await get_tree().process_frame
  picker.show_popup()
  await photograph_scene("fixture-"+cls+"-permanent-choice",true)
 for key in ["unweaving_area","wizard-stillness-lattice","controlled_player","cleric-concord-release","cleric-renewing-benediction","renewal"]:
  var combat := await open_combat();var b: Dictionary=saved.battles[key].duplicate(true)
  combat.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}}
  for i in 3:
   var member: Dictionary=state.party.members[i].duplicate(true);member.character_id=["a","b","c"][i];combat.state.party.members.append(member)
  combat.engine=TacticalAuras.new(b.units.a.record);combat.message="DEVELOPMENT FIXTURE · "+key+" · actual resolved effects/resources";combat.mode="attack";combat.refresh()
  await photograph_scene("fixture-"+key+"-combat",true)
  var spell: String="wizard-unweaving-tide" if key=="unweaving_area" else key
  var side: ScrollContainer=combat.log_label.get_parent().get_parent()
  if combat.action_buttons.has(spell):
   side.ensure_control_visible(combat.action_buttons[spell])
   await photograph_scene("fixture-"+key+"-spell-control",true,Vector2i(2560,1440))
  if key in ["wizard-stillness-lattice","renewal"]:
   side.ensure_control_visible(combat.log_label)
   await photograph_scene("fixture-"+key+"-effect-log",true,Vector2i(2560,1440))
  if key=="controlled_player":
   await photograph_scene("fixture-control-large",true,Vector2i(2560,1440))
   await photograph_scene("fixture-control-small",true,Vector2i(640,360))
 var active := WorldOriginLore.read_json(OS.get_environment("GAME129_CONNECTED_ROOT").path_join("active-state.json"))
 var combat := await open_combat();combat.state=active;combat.engine=TacticalAuras.new(active);combat.message="EARNED · level8/490XP · actual allied wards saved";combat.refresh()
 await photograph_scene("earned-saved-prepared-careers",false,Vector2i(2560,1440))
 var resumed := service.operate(entry,slot,"resume")
 check(resumed.ok and RulesJson.digest(resumed.state)==before,"captures never rewrite actual earned XP/history/identity")
 finish_capture()
