extends "res://tests/character_builder/review.gd"
func review_content(_index: int) -> void:
 check(not ui.content_button.disabled and ui.state.character_builder.confirmed.is_empty(),"content selection available before any confirmation")
 await click(ui.content_button);await wait_job()
 check(ui.state.character_builder.rules_ref.pack_id==RulesRecords.NEW_PACK,"visible selector pins expanded content")
 check(ui.preview_recipes.size()==3,"three genuine current-build art previews remain available")
func review_build(index: int,member: int) -> void:
 if member!=0:return
 var id: String=["blade-dancer","iron-bulwark","road-stalker"][index%3]
 ui.editor.class_filter.text=id.split("-")[0]
 ui.editor.select_id(ui.editor.class_picker,id);ui.editor.class_picker.item_selected.emit(ui.editor.class_picker.selected)
 ui.editor.feat_id="steady-study"
 for item in ui.editor.equipment_pickers:ui.editor.equipment_pickers[item].button_pressed=item==("bow" if id=="road-stalker" else "shortblade")
 for item in ui.editor.preparation_pickers:ui.editor.preparation_pickers[item].button_pressed=false
 ui.editor.suggest_allocation()
 check(ui.editor.preview.ok,"actual expanded martial build is legal: "+CharacterBuilderRecords.reason(ui.editor.preview))
 check(ui.editor.preview.candidate.advancement_history[0].class_id==id,"new class choice is a real kernel record")
 ui.editor.class_filter.text=""
 ui.editor.feat_filter.text="study"
 check(ui.editor.feat_picker.item_count>=1,"search retains a legal selected feat")
 ui.editor.feat_filter.text=""
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  tree.root.size=resolution;ui.detail_tabs.current_tab=1;await frames()
  var ancestor: Node=ui.editor.get_parent()
  while ancestor!=null and not ancestor is ScrollContainer:ancestor=ancestor.get_parent()
  if ancestor is ScrollContainer:ancestor.ensure_control_visible(ui.editor.class_detail)
  await frames()
  check(ui.finish_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"expanded creator footer remains visible")
  await shot("expanded-%s-%dx%d"%[id,resolution.x,resolution.y])
 tree.root.size=Vector2i(1280,720);await frames()
func journey(spec: Dictionary,index: int) -> void:
 await super.journey(spec,index)
 var source := RulesRecords.registry(ui.state)
 check(source.rules_ref().pack_id==RulesRecords.NEW_PACK,"journey remains on expanded pin after combat/home")
 var snapshots := {}
 for id in ui.state.party_ids:
  var result := RulesCharacter.new(source).derive_character(ui.state.mechanics.records[id])
  check(result.ok,"actual saved new-pack character derives after journey")
  snapshots[id]=result.snapshot.snapshot_hash
 journeys.back()["rules_ref"]=source.rules_ref()
 journeys.back()["snapshots"]=snapshots
 journeys.back()["class_id"]=ui.state.mechanics.records[ui.state.party_ids[0]].advancement_history[0].class_id
func restart() -> void:
 await super.restart()
 var saved: Dictionary=WorldOriginLore.read_json(base.path_join("review-proof.json"))
 for journey_data in saved.journeys:
  var store := GamePlaythroughStore.new();store.save_root=journey_data.save_root
  var library := GameWorldLibrary.new();library.library_root=journey_data.library_root
  var matching: Array=library.discover().filter(func(e: Dictionary):return e.world.source_sha256==journey_data.world_sha)
  var result := store.load_save(journey_data.slot,matching[0].world)
  check(result.ok and RulesJson.normalize(result.state.mechanics.rules_ref)==RulesJson.normalize(journey_data.rules_ref),"fresh process retains chosen content pin")
  for id in result.state.party_ids:
   var snapshot: Dictionary=RulesCharacter.new(RulesRecords.registry(result.state)).derive_character(result.state.mechanics.records[id]).snapshot
   var actual: String=snapshot.snapshot_hash
   if actual!=journey_data.snapshots[id]:
    print("REPLAY DIFF ",id," actual=",actual," expected=",journey_data.snapshots[id])
   check(actual==journey_data.snapshots[id],"fresh process reconstructs exact new-pack snapshot")
 var proof_file := base.path_join("restart-proof.json")
 var result: Dictionary=WorldOriginLore.read_json(proof_file);result.checks=checks;result.failures=failures
 FileAccess.open(proof_file,FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")

func finish() -> void:
 print("GAME104 REVIEW FAILED ",checks," / ",failures)
 tree.quit(1)
