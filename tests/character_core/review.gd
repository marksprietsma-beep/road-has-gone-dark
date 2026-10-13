extends "res://tests/character_builder/review.gd"
var cohorts := [["fighter","rogue","wizard"],["barbarian","bard","cleric"],["monk","paladin","ranger"],["sorcerer","druid","fighter"],["cleric","ranger","rogue"],["druid","bard","monk"]]
var core_actions: Array=[]
func review_content(index: int) -> void:
 print("GAME118 fresh creator ",index)
 check(ui.state.character_builder.rules_ref.pack_id==RulesRecords.NEW_PACK,"fresh New Game defaults to current supported rules without opt-in")
 check(not ui.content_button.is_visible_in_tree(),"no hidden content-button journey")
 check(ui.class_choice.item_count==11 and ui.people_picker.item_count==9,"familiar race and class decisions offered on first open")
 check(not ui.role_picker.is_visible_in_tree(),"narrative guidance subordinate")
 check(ui.preview_recipes.size()==3,"three actual persistent LPC adventurers")
 if index==0:
  for size in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
   tree.root.size=size;await frames();await shot('first-open-%dx%d'%[size.x,size.y])
   check(ui.finish_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"first-open footer accessible")
  tree.root.size=Vector2i(1280,720);await frames()
  if visual:
   await click(ui.class_choice);await shot('first-open-core-class-options');await key(KEY_ESCAPE)
func review_build(index: int,member: int) -> void:
 var cls: String=cohorts[index][member]
 print("GAME118 actual character ",cls)
 var races: Array=["dwarf","half-elf","elf","human","gnome","halfling","half-orc","goblin","orc"]
 var race: String=races[(index*3+member)%races.size()]
 ui.pick(ui.people_picker,race);ui.people_picker.item_selected.emit(ui.people_picker.selected)
 ui.pick(ui.class_choice,cls);ui.class_choice.item_selected.emit(ui.class_choice.selected)
 check(ui.editor.preview.ok,"familiar "+race+" "+cls+" has a real legal build: "+CharacterBuilderRecords.reason(ui.editor.preview))
 check(ui.editor.preview.candidate.advancement_history[0].class_id==cls,"actual mechanical class independent of narrative role")
 ui.name_edit.text=cls.capitalize()+" of the Road";ui.name_edit.text_changed.emit(ui.name_edit.text)
 check(ui.roster.rows[member].get_child(0).get_child(1).get_child(1).text.begins_with(cls.capitalize()),"pending party card shows the selected real class")
 check(ui.biography.text.contains(ui.name_edit.text) and ui.statistics.text.contains(ui.name_edit.text),"pending biography and sheet agree with edited name")
 if index==0:
  ui.detail_tabs.current_tab=0;await frames();await shot(cls+'-ancestry-traits')
  ui.detail_tabs.current_tab=1;await frames();await shot(cls+'-class-build')
  ui.detail_tabs.current_tab=2;await frames();await shot(cls+'-mechanical-sheet')
func inspect_sheet(prefix: String,advance: bool) -> void:
 if RulesRecords.registry(ui.state).rules_ref().get("engine_schema")!=3:
  await super.inspect_sheet(prefix,advance);return
 var before := RulesJson.digest(ui.state)
 await click(find_button(ui,"Characters"));await wait_scene("res://scenes/ui/character_sheet.tscn")
 check(RulesJson.digest(ui.state)==before,"opening core sheet does not write gameplay")
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  tree.root.size=resolution;ui.detail_tabs.current_tab=2;await frames();await shot(prefix+"-sheet-%dx%d"%[resolution.x,resolution.y])
  check(ui.back_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"readable core sheet footer fits")
 tree.root.size=Vector2i(1280,720);ui.detail_tabs.current_tab=3;await frames()
 var id: String=ui.state.party_ids[ui.selected-1]
 var next: int=ui.state.mechanics.records[id].advancement_history.size()+1
 var funded: bool=CharacterBuilderRecords.xp(ui.state,id)>=CharacterBuilderRecords.threshold(next,ui.state)
 check(ui.advancement_button.disabled==not funded,"core advancement availability follows actual earned XP and exact pinned policy")
 await click(ui.back_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 check(RulesJson.digest(ui.state)==before,"reading core sheet preserves exact campaign")
func play_fight() -> void:
 var deadline := Time.get_ticks_msec()+240000
 while ui.battle().status=="active" and Time.get_ticks_msec()<deadline:
  if ui.thread==null and not ui.message.is_empty():check(false,"combat action failed: "+ui.message);return
  if ui.thread!=null or ui.is_presenting() or ui.presentation_active or engine.current(ui.battle()).team=="enemy":await tree.process_frame;continue
  var b: Dictionary=ui.battle();engine.configure(ui.state)
  var actor := engine.current(b)
  var mode := "";var target := ""
  if int(b.budget.main)>0:
   var choices: Array=ui.action_buttons.keys().filter(func(id: String):return id!="move" and not ui.action_buttons[id].disabled)
   choices.erase('attack');choices.append('attack')
   if ui.action_buttons.has("second-wind") and not ui.action_buttons["second-wind"].disabled and int(actor.record.runtime.hp)*2<int(engine.stats(actor).HP):
    await click(ui.action_buttons["second-wind"]);await wait_job();continue
   if ui.action_buttons.has("wizard-mage-armour") and not ui.action_buttons["wizard-mage-armour"].disabled and not actor.record.runtime.statuses.any(func(status: Dictionary):return status.id=="warded"):
    await click(ui.action_buttons["wizard-mage-armour"]);await click(ui.tiles[str(actor.position)]);await wait_job();continue
   for id in choices:
    var ability := engine.registry.definition('abilities',id)
    # Exercise damage spells and weapon techniques; do not endlessly repeat non-damaging buffs.
    if id!='attack' and not ability.tags.has('weapon_strike') and not ability.effects.any(func(effect: Dictionary):return effect.op=='damage'):continue
    for enemy_id in b.order:
     if b.units[enemy_id].team!=actor.team and engine.eligible(b,actor,b.units[enemy_id],id):mode=id;target=enemy_id;break
    if not target.is_empty():break
  if not target.is_empty():
   await click(ui.action_buttons[mode]);await click(ui.tiles[str(b.units[target].position)]);await wait_job()
   if mode!='attack' and not core_actions.has(mode):core_actions.append(mode)
  elif int(b.budget.move)>0:
   var command := engine.enemy_command(b)
   if command.kind=='move':await click(ui.action_buttons.move);await click(ui.tiles[str(command.destination)]);await wait_job()
   else:await click(ui.end_button);await wait_job()
  else:await click(ui.end_button);await wait_job()
 check(ui.battle().status=='victory','familiar core party wins through real tactical controls')
 check(core_actions.any(func(id: String):return id.begins_with('wizard-')),'actual selected Wizard spell cast in combat')
 proof.core_actions=core_actions
func journey(spec: Dictionary,index: int) -> void:
 await super.journey(spec,index)
 print("GAME118 completed journey ",index)
 var source := RulesRecords.registry(ui.state)
 check(source.rules_ref().engine_schema==3,'saved journey retains new content pin')
 # Index 0 fights for genuine XP. Advance those actual characters, never fixture XP.
 if index==0:
  await click(find_button(ui,'Characters'));await wait_scene('res://scenes/ui/character_sheet.tscn')
  for member in 3:
   ui.selected=member+1;ui.refresh();ui.detail_tabs.current_tab=3;await frames()
   var id: String=ui.state.party_ids[member]
   check(CharacterBuilderRecords.xp(ui.state,id)>=CharacterBuilderRecords.threshold(2,ui.state),'actual victory funds level two')
   check(not ui.advancement_button.disabled,'earned level available')
   await shot('earned-'+cohorts[0][member]+'-level-preview')
   await click(ui.advancement_button);await wait_job()
   check(ui.state.mechanics.records[id].advancement_history.size()==2,'reviewed level commits once')
   ui.detail_tabs.current_tab=2;await frames();await shot('earned-'+cohorts[0][member]+'-level-sheet')
  await click(ui.back_button);await wait_scene('res://scenes/gameplay/expedition.tscn')
 var snapshots := {}
 for id in ui.state.party_ids:snapshots[id]=RulesCharacter.new(source).derive_character(ui.state.mechanics.records[id]).snapshot.snapshot_hash
 journeys.back()['snapshots']=snapshots;journeys.back()['rules_ref']=source.rules_ref();journeys.back()['classes']=cohorts[index]
func restart() -> void:
 await super.restart()
 var saved: Dictionary=WorldOriginLore.read_json(base.path_join('review-proof.json'))
 for journey_data in saved.journeys:
  var store := GamePlaythroughStore.new();store.save_root=journey_data.save_root
  var library := GameWorldLibrary.new();library.library_root=journey_data.library_root
  var matching: Array=library.discover().filter(func(e: Dictionary):return e.world.source_sha256==journey_data.world_sha)
  var result := store.load_save(journey_data.slot,matching[0].world)
  check(result.ok and RulesJson.normalize(result.state.mechanics.rules_ref)==RulesJson.normalize(journey_data.rules_ref),'fresh process retains original saved rules pin')
  for id in result.state.party_ids:check(RulesCharacter.new(RulesRecords.registry(result.state)).derive_character(result.state.mechanics.records[id]).snapshot.snapshot_hash==journey_data.snapshots[id],'familiar class progression reloads exactly')
 var proof_file := base.path_join('restart-proof.json');var result: Dictionary=WorldOriginLore.read_json(proof_file);result.checks=checks;result.failures=failures
 FileAccess.open(proof_file,FileAccess.WRITE).store_string(JSON.stringify(result,'  ')+'\n')
func finish() -> void:
 print('GAME118 REVIEW FAILED ',checks,' / ',failures);tree.quit(1)
