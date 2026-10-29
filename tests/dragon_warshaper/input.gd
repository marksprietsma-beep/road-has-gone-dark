extends "res://tests/grove_summoner/input.gd"
## Production creator/advancement callbacks plus actual mouse events on combat.
var footer_observations := []
func run() -> void:
 var folder: String=OS.get_environment("DRAGON_WARSHAPER_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(folder.path_join("saved.json")))
 var source: RulesRegistry=RulesRecords.registry(saved.records["wizard-prefix"]);var kernel:=RulesCharacter.new(source)
 var helper: Node=load("res://tests/dragon_warshaper/mechanics.gd").new();helper.source=source;helper.kernel=kernel;helper.fixtures.fighter=helper.build("fighter",12)
 for cls in ["wizard","sorcerer","druid"]:
  var record: Dictionary=helper.build(cls,1);var before: String=RulesJson.digest(record)
  var editor:=BuildEditor.new();add_child(editor);editor.setup(record,false)
  check(editor.class_options().has(cls) and not editor.class_options().has("dragon-disciple") and not editor.class_options().has("warshaper"),"real new creator offers base classes only")
  editor.class_filter.text=source.definition("classes",cls).name;editor.class_filter.text_changed.emit(editor.class_filter.text)
  check(find(editor.class_picker,cls)>=0,"actual existing class search retains chosen class")
  editor.class_loadout();editor.suggest_spell_selections()
  var out: Dictionary=CharacterBuilderRecords.create(record.character_id,editor.definition(),record)
  check(out.ok,"production creator definition commits legally "+cls+JSON.stringify(out.get("errors",[])))
  check(RulesJson.digest(record)==before,"creator exploration never mutates persistent identity")
  editor.queue_free()
 for spec in [["wizard-prefix","dragon-disciple","wizard"],["beguiler-prefix","dragon-disciple","beguiler"],["druid-prefix","warshaper","druid"]]:
  var record: Dictionary=saved.records[spec[0]];var before: String=RulesJson.digest(record)
  var editor:=BuildEditor.new();add_child(editor);editor.setup(record,true)
  var index: int=find(editor.class_picker,spec[1]);check(index>=0 and not editor.class_picker.is_item_disabled(index),"qualified prestige appears only as optional advancement")
  if index>=0:
   editor.class_picker.select(index);editor.class_picker.item_selected.emit(index)
   if spec[1]=="dragon-disciple":
    check(editor.career_pickers.has("dragon-disciple-casting"),"actual existing-parent selection visible")
    if editor.career_pickers.has("dragon-disciple-casting"):
     var picker: OptionButton=editor.career_pickers["dragon-disciple-casting"];var selected: int=find(picker,spec[2])
     check(selected>=0 and not picker.is_item_disabled(selected),"real eligible parent is available, including Beguiler")
     if selected>=0:picker.select(selected);picker.item_selected.emit(selected)
   check(kernel.preview_advancement(record,editor.choice()).ok,"actual production prestige controls produce an accepted permanent choice")
   index=find(editor.class_picker,spec[2]);editor.class_picker.select(index);editor.class_picker.item_selected.emit(index)
   check(kernel.preview_advancement(record,editor.choice()).ok,"actual UI can decline prestige for its parent")
  check(RulesJson.digest(record)==before,"eligibility and deliberate previews create no level or XP")
  editor.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for spec in [["wizard10","dragon-disciple-technique-1","bandit-blade"],["wizard10","dragon-disciple-technique-4","a"],["wizard10","dragon-disciple-technique-7","bandit-blade"],["wizard10","dragon-disciple-technique-10","bandit-blade"],["druid5","warshaper-technique-1","a"],["druid5","warshaper-technique-3","a"],["druid5","warshaper-technique-5","a"]]:
  var record: Dictionary=saved.records[spec[0]];var battle: Dictionary=helper.encounter(record);var aid: String=spec[1];var target: String=spec[2]
  ui.engine=TacticalAuras.new(record);show(ui,battle,aid);ui.sent={};var tile: Array=battle.units[target].position
  check(ui.action_buttons.has(aid)and not ui.action_buttons[aid].disabled and ui.tiles[str(tile)].target_tile,"actual affordable action and legal highlight "+aid)
  ui.choose_tile(tile);check(ui.sent.get("kind")==aid and ui.sent.get("target")==target,"production tile callback preserves exact class-action intent")
  check(ui.engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":aid,"target_id":target}).ok,"real control intent executes through original authority")
  for reason in ["main","reserve"]:
   var empty: Dictionary=battle.duplicate(true)
   if reason=="main":empty.budget.main=0
   else:
    for pool in source.definition("abilities",aid).cost.resources:empty.units.a.record.runtime.resources[pool]=0
   empty=ui.engine.seal(empty);show(ui,empty,aid);ui.sent={};ui.choose_tile(tile)
   check(ui.action_buttons[aid].disabled and not ui.tiles[str(tile)].target_tile and ui.sent.is_empty(),"unavailable action has no enabled button, highlight or emitted command "+aid+reason)
 var transformed: Dictionary=saved.records.dragon_form;var blocked: Dictionary=helper.encounter(transformed);ui.engine=TacticalAuras.new(transformed);show(ui,blocked,"dragon-disciple-technique-1");ui.sent={};ui.choose_tile(blocked.units["bandit-blade"].position)
 check((not ui.action_buttons.has("dragon-disciple-technique-1")or ui.action_buttons["dragon-disciple-technique-1"].disabled)and ui.sent.is_empty(),"actual altered-body UI suppresses supernatural breath")
 ui.queue_free();await frames()
 for dimensions in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440),Vector2i.ZERO]:
  if dimensions==Vector2i.ZERO:get_window().mode=Window.MODE_FULLSCREEN
  else:get_window().mode=Window.MODE_WINDOWED;get_window().size=dimensions
  await frames()
  var control: Control=load("res://tests/sentinel_turn/ui_probe.gd").new();PartyService.handoff={};add_child(control);control.set_process(false)
  var record: Dictionary=saved.records.druid5;var battle: Dictionary=helper.encounter(record)
  control.engine=TacticalAuras.new(record);display_control(control,battle,"move");await frames()
  await click(control.tiles[str([1,2])]);check(control.last_result.get("ok",false)and control.battle().commands.back().kind=="move","genuine tile mouse input spends actual movement before shaping")
  await click(control.action_buttons["warshaper-technique-5"]);await frames()
  check(control.last_result.get("ok",false)and control.battle().budget=={"main":0,"move":0}and not RulesEntities.form(control.battle().units.a.record,source).is_empty(),"genuine frame button creates actual exhausted transformed actor")
  check(not control.end_button.disabled and get_viewport().get_visible_rect().encloses(control.end_button.get_global_rect()),"fixed End remains wholly on-screen and enabled after transformation0/0")
  var expected: Dictionary=control.engine.command(control.battle(),{"actor_id":"a","revision":control.battle().revision,"kind":"end"})
  footer_observations.append({"fullscreen":get_window().mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN],"requested":[dimensions.x,dimensions.y],"end":str(control.end_button.get_global_rect()),"viewport":str(get_viewport().get_visible_rect()),"form":RulesEntities.form(control.battle().units.a.record,source),"before_hash":control.battle().state_hash})
  await RenderingServer.frame_post_draw
  var pixels: Image=get_viewport().get_texture().get_image();var file: String="morphic-footer-%s-%dx%d.png"%["fullscreen"if dimensions==Vector2i.ZERO else str(dimensions.x),pixels.get_width(),pixels.get_height()]
  pixels.save_png(folder.path_join(file));footer_observations.back().file=file;footer_observations.back().sha256=FileAccess.get_sha256(folder.path_join(file));footer_observations.back().width=pixels.get_width();footer_observations.back().height=pixels.get_height()
  await click(control.end_button,true);check(control.last_result.get("ok",false)and control.battle().state_hash==expected.battle.state_hash,"genuine fixed End click advances the transformed actor through exact original authority")
  control.queue_free();await frames()
 check(helper.failures==0,"all original fixture helpers remain legal");helper.free()
 FileAccess.open(folder.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"failed_checks":failed_checks,"rules_ref":source.rules_ref(),"footer_observations":footer_observations,"development_fixtures":true,"earned_xp":false,"scope":"Creator/advancement control callbacks, original action/target controls, and genuine mouse move/frame/End. UI intent harness; sole campaign writer and cold tested separately."}))
 print("DRAGON_WARSHAPER_INPUT ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
func display_control(ui: Control,battle: Dictionary,mode: String) -> void:
 ui.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
 for id in ["a","b","c"]:ui.state.party.members.append({"character_id":id,"name":battle.units[id].name})
 ui.mode=mode;ui.message="DEVELOPMENT control fixture · original mouse/turn authority · no campaign write";ui.refresh()
func frames(n := 4) -> void:
 for i in n:await get_tree().process_frame
func click(control: Control,whole := false) -> void:
 var parent: Node=control.get_parent()
 while parent!=null:
  if parent is ScrollContainer:(parent as ScrollContainer).ensure_control_visible(control)
  parent=parent.get_parent()
 await frames()
 var rectangle: Rect2=control.get_global_rect().intersection(get_viewport().get_visible_rect());parent=control.get_parent()
 while parent!=null:
  if parent is Control and (parent as Control).clip_contents:rectangle=rectangle.intersection((parent as Control).get_global_rect())
  parent=parent.get_parent()
 check(control.is_visible_in_tree()and not control.get("disabled")and rectangle.size.x>1 and rectangle.size.y>1,"genuine mouse control has an enabled visible hitbox")
 if whole:check(get_viewport().get_visible_rect().encloses(control.get_global_rect()),"entire essential footer action is on-screen")
 if rectangle.size.x<=1 or rectangle.size.y<=1:return
 var motion:=InputEventMouseMotion.new();motion.position=rectangle.get_center();get_viewport().push_input(motion,true);await frames(1)
 for down in [true,false]:
  var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=rectangle.get_center();get_viewport().push_input(event,true);await frames(1)
 await frames()
