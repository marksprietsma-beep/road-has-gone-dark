extends "res://tests/dragon_warshaper/input.gd"
## Existing creator, advancement and combat controls. DEVELOPMENT fixtures, not earned XP.
func run() -> void:
 var folder: String=OS.get_environment("FINAL_PRESTIGE_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(folder.path_join("saved.json")))
 var source: RulesRegistry=RulesRecords.registry(saved.records["wizard-prefix"]);var kernel:=RulesCharacter.new(source)
 var helper: Node=load("res://tests/final_prestige/mechanics.gd").new();helper.source=source;helper.kernel=kernel;helper.fixtures.fighter=helper.build("fighter",12)
 for cls in ["wizard","rogue","fighter"]:
  var record: Dictionary=helper.build(cls,1);var before: String=RulesJson.digest(record)
  var editor:=BuildEditor.new();add_child(editor);editor.setup(record,false)
  check(editor.class_options().has(cls),"existing base class remains available")
  for path in ["eldritch-knight","shadowdancer","dwarven-defender"]:check(not editor.class_options().has(path),"no prestige in original creation selector "+path)
  editor.class_filter.text=source.definition("classes",cls).name;editor.class_filter.text_changed.emit(editor.class_filter.text)
  check(find(editor.class_picker,cls)>=0,"actual search retains selected base class")
  editor.class_loadout();editor.suggest_spell_selections()
  var out: Dictionary=CharacterBuilderRecords.create(record.character_id,editor.definition(),record)
  check(out.ok,"creator controls produce lawful base character "+cls+JSON.stringify(out.get("errors",[])))
  check(RulesJson.digest(record)==before,"creator preview preserves original identity")
  editor.queue_free()
 for spec in [["wizard-prefix","eldritch-knight","wizard"],["beguiler-prefix","eldritch-knight","beguiler"],["shadow-prefix","shadowdancer","rogue"],["defender-prefix","dwarven-defender","fighter"]]:
  var record: Dictionary=saved.records[spec[0]];var before: String=RulesJson.digest(record)
  var editor:=BuildEditor.new();add_child(editor);editor.setup(record,true)
  var index: int=find(editor.class_picker,spec[1]);check(index>=0 and not editor.class_picker.is_item_disabled(index),"permanent qualification enables optional prestige control")
  if index>=0:
   editor.class_picker.select(index);editor.class_picker.item_selected.emit(index)
   if spec[1]=="eldritch-knight":
    check(editor.career_pickers.has("eldritch-knight-arcane"),"real casting-parent control exists")
    if editor.career_pickers.has("eldritch-knight-arcane"):
     var picker: OptionButton=editor.career_pickers["eldritch-knight-arcane"];var selected: int=find(picker,spec[2])
     check(selected>=0 and not picker.is_item_disabled(selected),"owned actual casting parent is selectable, including Beguiler")
     if selected>=0:picker.select(selected);picker.item_selected.emit(selected)
   check(kernel.preview_advancement(record,editor.choice()).ok,"production prestige selection passes original authority")
   index=find(editor.class_picker,spec[2]);editor.class_picker.select(index);editor.class_picker.item_selected.emit(index)
   check(kernel.preview_advancement(record,editor.choice()).ok,"real control permits declining prestige")
  check(before==RulesJson.digest(record),"eligibility/preview cannot generate class or XP")
  editor.queue_free()
 for spec in [["wizard2","eldritch-channel-3","wizard-enfeeble"],["wizard4","eldritch-channel-5","wizard-arcane-bolt"]]:
  var record: Dictionary=saved.records[spec[0]];var editor:=BuildEditor.new();add_child(editor);editor.setup(record,true)
  var index: int=find(editor.class_picker,"eldritch-knight");editor.class_picker.select(index);editor.class_picker.item_selected.emit(index)
  check(editor.career_pickers.has(spec[1]),"actual scheduled Knight channel choice is visible")
  if editor.career_pickers.has(spec[1]):
   var picker: OptionButton=editor.career_pickers[spec[1]];var selected: int=find(picker,spec[2])
   check(selected>=0 and not picker.is_item_disabled(selected),"actual parent-bound original spell channel is selectable")
   if selected>=0:picker.select(selected);picker.item_selected.emit(selected)
   check(kernel.preview_advancement(record,editor.choice()).ok,"actual original UI commits a legal channel specialisation")
   var wrong: int=find(picker,"sorcerer-arcane-bolt")
   check(wrong<0 or picker.is_item_disabled(wrong),"unowned parent channel cannot be selected")
  editor.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for spec in [["wizard5","eldritch-knight-power-1","bandit-blade"],["wizard5","eldritch-knight-power-3","a"],["wizard5","eldritch-knight-power-5","a"],["eldritch-channel-wizard-enfeeble","eldritch-channel-wizard-enfeeble","bandit-blade"],["shadow10","shadowdancer-technique-1","a"],["shadow10","shadowdancer-technique-4","a"],["shadow10","shadowdancer-technique-7","a"],["shadow10","shadowdancer-technique-10","a"],["defender10","dwarven-defender-technique-1","a"],["defender10","dwarven-defender-technique-4","a"],["defender10","dwarven-defender-technique-7","a"],["defender10","dwarven-defender-technique-10","a"]]:
  var record: Dictionary=saved.records[spec[0]].duplicate(true)
  if str(spec[0]).begins_with("wizard"):record.equipment=["shortblade","mail","shield"]
  var battle: Dictionary=helper.real_field(record);var aid: String=spec[1];var target: String=spec[2]
  ui.engine=TacticalAuras.new(record);show(ui,battle,aid);ui.sent={};var tile: Array=battle.units[target].position
  check(ui.action_buttons.has(aid)and not ui.action_buttons[aid].disabled and ui.tiles[str(tile)].target_tile,"real affordable action/target highlight "+aid)
  ui.choose_tile(tile);check(ui.sent.get("kind")==aid and ui.sent.get("target")==target,"production targeting emits precise authority intent")
  check(ui.engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":aid,"target_id":target}).ok,"original tactical engine accepts control intent")
  if int(source.definition("abilities",aid).cost.main)==0:
   var spent: Dictionary=ui.engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":"guard","target_id":"a"})
   check(spent.ok and spent.battle.budget.main==0 and spent.battle.budget.move==1,"real guard spends main before testing a zero-main choice")
   if spent.ok:
    show(ui,spent.battle,aid);ui.sent={}
    check(not ui.action_buttons[aid].disabled and ui.tiles[str(tile)].target_tile,"zero-main class action remains enabled after main is spent "+aid)
    ui.choose_tile(tile);check(ui.sent.get("kind")==aid,"zero-main control emits its legal remaining-token action")
    check(ui.engine.command(spent.battle,{"actor_id":"a","revision":spent.battle.revision,"kind":aid,"target_id":target}).ok,"original authority accepts remaining move/reaction action")
  for pool in source.definition("abilities",aid).cost.resources:
   var empty: Dictionary=battle.duplicate(true);empty.units.a.record.runtime.resources[pool]=0;empty=ui.engine.seal(empty);show(ui,empty,aid);ui.sent={};ui.choose_tile(tile)
   check(ui.action_buttons[aid].disabled and not ui.tiles[str(tile)].target_tile and ui.sent.is_empty(),"spent matching resource disables button, highlight and command "+aid+pool)
 ui.queue_free();await frames()
 for dimensions in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440),Vector2i.ZERO]:
  if dimensions==Vector2i.ZERO:get_window().mode=Window.MODE_FULLSCREEN
  else:get_window().mode=Window.MODE_WINDOWED;get_window().size=dimensions
  await frames()
  var control: Control=load("res://tests/sentinel_turn/ui_probe.gd").new();PartyService.handoff={};add_child(control);control.set_process(false)
  var record: Dictionary=saved.records.defender10;var battle: Dictionary=helper.real_field(record)
  control.engine=TacticalAuras.new(record);display_control(control,battle,"attack");await frames()
  await click(control.action_buttons["dwarven-defender-technique-10"]);await frames()
  check(control.last_result.get("ok",false)and control.battle().budget=={"main":0,"move":0},"genuine mouse activation spends main/move and anchors Defender")
  check(control.engine.paths(control.battle(),control.battle().units.a).is_empty(),"actual UI battle respects immobility")
  check(not control.end_button.disabled and get_viewport().get_visible_rect().encloses(control.end_button.get_global_rect()),"essential End visible/enabled at exhausted0/0")
  var expected: Dictionary=control.engine.command(control.battle(),{"actor_id":"a","revision":control.battle().revision,"kind":"end"})
  await RenderingServer.frame_post_draw
  var pixels: Image=get_viewport().get_texture().get_image();var file: String="defender-footer-%s-%dx%d.png"%["fullscreen"if dimensions==Vector2i.ZERO else str(dimensions.x),pixels.get_width(),pixels.get_height()]
  pixels.save_png(folder.path_join(file));footer_observations.append({"file":file,"sha256":FileAccess.get_sha256(folder.path_join(file)),"width":pixels.get_width(),"height":pixels.get_height(),"development_fixture":true,"earned_xp":false})
  await click(control.end_button,true);check(control.last_result.get("ok",false)and control.battle().state_hash==expected.battle.state_hash,"genuine End click preserves deterministic turn authority")
  control.queue_free();await frames()
 check(helper.failures==0,"all fixture helpers legal");helper.free()
 FileAccess.open(folder.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"failed_checks":failed_checks,"rules_ref":source.rules_ref(),"screenshots":footer_observations,"development_fixtures":true,"earned_xp":false,"scope":"Original creation/advancement/action/target callbacks; genuine mouse stance and End at three resolutions/fullscreen. Earned campaign persistence verified separately."}))
 print("FINAL_PRESTIGE_INPUT ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
