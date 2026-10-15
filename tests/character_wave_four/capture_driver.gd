extends "res://tests/character_psychic/capture_driver.gd"
## Real production creator, unchanged existing canonical world; no XP fixture grants.
func run() -> void:
 base=OS.get_environment("GAME112W4_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(base)
 var source_root := OS.get_environment("GAME112W4_WORLD_ROOT")
 service.library.library_root=source_root.path_join("library");entry=service.library.discover()[0]
 service.cache_root=base.path_join("cache");service.store.save_root=base.path_join("saves");service.library.save_root=service.store.save_root
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"existing world profiles")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id));slot=born.state.playthrough_id
 check(service.store.save_new(slot,born.state,entry.world).ok,"normal writer new campaign")
 action_builder("builder_open")
 var ui := await open_screen("res://scenes/ui/party_creation.tscn")
 if ui==null:finish();return
 check(ui.editor.source.rules_ref().pack_id=="trhgd-character-v14","creator exact v14 default")
 check(not ui.editor.equipment_pickers.has("frost-fangs")and not ui.editor.equipment_pickers.has("bulwark-slam"),"actual starting equipment UI excludes creature attacks")
 await screenshot("v14-first-open",false)
 ui.detail_tabs.current_tab=1
 for index in ui.editor.sections.get_tab_count():
  if ui.editor.sections.get_tab_title(index)=="Equipment":ui.editor.sections.current_tab=index
 await screenshot("v14-starting-equipment",false)
 for cls in ["erudite","divine-mind","marshal","beguiler","dragonfire-adept"]:
  ui.editor.set_class(cls);ui._identity_changed();ui.detail_tabs.current_tab=1
  check(ui.editor.preview.ok,"new creator legal default "+cls+JSON.stringify(ui.editor.preview.get("errors",[])))
  for tab in ["Specialisation","Spells","Progression","Powers"]:
   if tab=="Powers" and not ui.editor.source.definition("classes",cls).has("psychic_profile"):continue
   if tab=="Spells" and ui.editor.source.definition("classes",cls).spell_mode.is_empty():continue
   if tab=="Progression" and cls not in ["beguiler","dragonfire-adept"]:continue
   var found := false
   for index in ui.editor.sections.get_tab_count():
    if ui.editor.sections.get_tab_title(index)==tab:ui.editor.sections.current_tab=index;found=true
   if found:
    if tab=="Specialisation" and not ui.editor.career_pickers.is_empty():
     var control: Control=ui.editor.career_pickers.values()[0]
     control.grab_focus()
     ui.detail_tabs.get_child(1).ensure_control_visible(control)
     for frame in 4:await get_tree().process_frame
    await screenshot(cls+"-"+tab.to_lower(),false)
 for people in ["air-genasi","earth-genasi","fire-genasi","water-genasi"]:
  ui.pick(ui.people_picker,people);ui.people_picker.item_selected.emit(ui.people_picker.selected)
  ui.editor.suggest_allocation() # An inherited INT change changes the explicit skill-rank budget.
  ui.detail_tabs.current_tab=2
  check(ui.editor.preview.ok,"actual inherited creator preview "+people+JSON.stringify(ui.editor.preview.get("errors",[])))
  await screenshot(people+"-traits",false)
 await close_screen()
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source_commit":OS.get_environment("GAME112W4_SOURCE_SHA"),"screenshots":screenshots,"development_fixture":false}))
 finish()
