extends "res://tests/opportunities/review.gd"
## Extends the real V2 journey: individual creation, permanent sheets and earned advancement.
func review_creation(index: int) -> void:
 if index!=0:return
 var id: String=ui.state.party_ids[0]
 ui.selected=1;ui.refresh()
 var old_hp: int=ui.editor.preview.snapshot.stats.HP
 var control: OptionButton=ui.editor.attribute_pickers.CON
 ui.editor.select_id(control,"8");control.item_selected.emit(control.selected)
 check(ui.editor.preview.ok and ui.editor.preview.snapshot.stats.HP!=old_hp,"actual standard-array picker changes kernel HP")
 # Restore a survivable but different allocation before the real battle.
 ui.editor.select_id(control,"13");control.item_selected.emit(control.selected)
 check(ui.editor.preview.ok,"custom allocation remains legal")
 ui.name_edit.text="Alric of the Road"
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  tree.root.size=resolution
  for tab in [0,1,2]:
   ui.detail_tabs.current_tab=tab;await frames()
   check(ui.finish_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"creator footer fits "+str(resolution))
   await shot("creator-%s-%dx%d"%[["identity","build","sheet"][tab],resolution.x,resolution.y])
 tree.root.size=Vector2i(1280,720);ui.detail_tabs.current_tab=0;await frames()
 await click(ui.save_button);await wait_job()
 check(ui.state.party.members[0].name=="Alric of the Road" and ui.state.character_builder.drafts[id].base_attributes.CON==13,"player name and allocated scores committed together")
func journey(spec: Dictionary,index: int) -> void:
 await super.journey(spec,index)
 await inspect_sheet("custom-%02d"%index,false)
func existing_campaign() -> void:
 await unprepared_party()
 await super.existing_campaign()
 await inspect_sheet("legacy",true)
func find_button(node: Node,label: String) -> Button:
 if node is Button and node.text==label:return node
 for child in node.get_children():
  var found := find_button(child,label)
  if found!=null:return found
 return null
func inspect_sheet(prefix: String,advance: bool) -> void:
 var before := RulesJson.digest(ui.state)
 var party := RulesJson.digest(ui.state.party)
 var sandbox := RulesJson.digest(ui.state.sandbox)
 await click(find_button(ui,"Characters"));await wait_scene("res://scenes/ui/character_sheet.tscn")
 check(RulesJson.digest(ui.state)==before,"opening permanent sheet never writes gameplay")
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  tree.root.size=resolution;ui.detail_tabs.current_tab=2;await frames()
  check(ui.back_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"sheet footer fits")
  await shot(prefix+"-sheet-%dx%d"%[resolution.x,resolution.y])
 tree.root.size=Vector2i(1280,720);ui.detail_tabs.current_tab=3;await frames()
 if advance:
  var id: String=ui.state.party_ids[0]
  var level: int=ui.state.mechanics.records[id].advancement_history.size()
  ui.advance_editor.select_id(ui.advance_editor.class_picker,"wayfinder")
  ui.advance_editor.class_picker.item_selected.emit(ui.advance_editor.class_picker.selected)
  var choice := CharacterBuilderRecords.kernel().suggested_choice(ui.state.mechanics.records[id],"wayfinder")
  check(choice.ok,"earned legacy multiclass choice available")
  ui.advance_editor.allocation=choice.choice.skill_allocations.duplicate(true);ui.advance_editor.refresh_preview();ui._advance_changed();await frames()
  check(not ui.advancement_button.disabled,"real saved victories enable advancement")
  await shot("earned-multiclass-preview")
  await click(ui.advancement_button);await wait_job()
  check(ui.state.mechanics.records[id].advancement_history.size()==level+1,"actual advancement button commits one earned level")
  check(RulesJson.digest(ui.state.party)==party and RulesJson.digest(ui.state.sandbox)==sandbox,"advancement preserves identities, results, XP and RNG")
  ui.detail_tabs.current_tab=2;await frames();await shot("earned-multiclass-sheet")
 else:check(ui.advancement_button.disabled,"insufficient journey XP visibly prevents free levels")
 await click(ui.back_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 if not advance:check(RulesJson.digest(ui.state)==before,"sheet return preserves exact campaign")

func unprepared_party() -> void:
 var entry: Dictionary=ui.entry
 var origin: Dictionary=ui.state.origin
 var service := CharacterBuilderService.new()
 service.store.save_root=base.path_join("unprepared/saves");service.library.library_root=ui.service.library.library_root
 service.library.save_root=service.store.save_root
 var created := service.store.create_playthrough(entry.world,int(origin.state_id),int(origin.home_burg_id),int(origin.province_id))
 check(created.ok and service.store.save_new(created.state.playthrough_id,created.state,entry.world).ok,"genuine old-format origin")
 var slot: String=created.state.playthrough_id
 check(service.operate(entry,slot,"generate").ok,"original generated party")
 var ready := service.operate(entry,slot,"ready")
 check(ready.ok and not ready.state.has("mechanics") and not ready.state.has("character_builder"),"pre-GAME32 ready save remains supported")
 var path := service.store._slot_path(slot);var bytes := FileAccess.get_file_as_bytes(path)
 var party := RulesJson.digest(ready.state.party)
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root}
 tree.change_scene_to_file("res://scenes/ui/party_creation.tscn");await wait_scene("res://scenes/ui/party_creation.tscn")
 check(ui.ready_view and ui.preview_recipes.size()==3 and FileAccess.get_file_as_bytes(path)==bytes,"old ready identity renders three authentic LPC previews without save changes")
 check(not ui.state.has("mechanics") and not ui.state.has("character_builder") and ui.advancement_button.disabled,"preview never commits suggested builds or grants legacy progression")
 await shot("legacy-unprepared-ready")
 await click(ui.finish_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 check(RulesJson.digest(ui.state.party)==party and ui.state.party_ids==ready.state.party_ids,"existing hometown preparation preserves all old identities")
 proof.unprepared_legacy={"party_sha":party,"preview_bytes_unchanged":true,"persistent_ids":ui.state.party_ids,"hometown_handoff":true}
