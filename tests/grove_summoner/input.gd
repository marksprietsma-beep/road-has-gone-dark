extends "res://tests/hybrid_acceptance/input.gd"
signal completed
var no_quit := false
var failed_checks := []
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;failed_checks.append(label);print("ASSERTION_FAILED ",label)
func run() -> void:
 var folder := OS.get_environment("GROVE_SUMMONER_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(folder.path_join("saved.json")))
 var source := RulesRecords.registry(saved.records["bonded-wizard-prefix"]);var kernel := RulesCharacter.new(source)
 var helper: Node=load("res://tests/grove_summoner/mechanics.gd").new();helper.source=source;helper.kernel=kernel;helper.fixtures.fighter=helper.build("fighter",12)
 for cls in ["spirit-shaman","druid","wizard"]:
  var r: Dictionary=helper.build(cls,1);var before := RulesJson.digest(r)
  var editor := BuildEditor.new();add_child(editor);editor.setup(r,false)
  check(editor.class_options().has(cls) and not editor.class_options().has("grove-warden") and not editor.class_options().has("bonded-summoner"),"actual creator has legal base classes and no starting prestige")
  editor.class_filter.text=source.definition("classes",cls).name;editor.class_filter.text_changed.emit(editor.class_filter.text)
  check(find(editor.class_picker,cls)>=0,"actual searchable creator keeps selected class visible")
  editor.class_filter.text="";editor.class_filter.text_changed.emit("")
  check(editor.class_picker.item_count==kernel.starting_classes().size(),"clearing search restores exact base roster")
  editor.class_loadout();editor.suggest_spell_selections()
  if cls=="druid":
   var picker: OptionButton=editor.career_pickers["druid-companion"];var index := find(picker,"leopard");check(index>=0,"existing companion choice visible")
   if index>=0:picker.select(index);picker.item_selected.emit(index)
  var created: Dictionary=CharacterBuilderRecords.create(r.character_id,editor.definition(),r)
  check(created.ok,"real production creator controls commit legal base identity "+cls+JSON.stringify(created.get("errors",[])))
  if created.ok and cls=="druid":check(created.candidate.runtime.companions.values()[0].definition_id=="leopard","actual selected owned creature persists")
  check(RulesJson.digest(r)==before,"UI exploration never changes existing identity or pin");editor.queue_free()
 for spec in [["grove-druid-prefix","grove-warden","grove-casting","druid"],["bonded-wizard-prefix","bonded-summoner","bonded-casting","wizard"]]:
  var r: Dictionary=saved.records[spec[0]];var before := RulesJson.digest(r);var editor := BuildEditor.new();add_child(editor);editor.setup(r,true)
  var index := find(editor.class_picker,spec[1]);check(index>=0 and not editor.class_picker.is_item_disabled(index),"qualified prestige is an enabled optional advancement")
  if index>=0:
   editor.class_picker.select(index);editor.class_picker.item_selected.emit(index)
   check(editor.career_pickers.has(spec[2]),"persistent existing-caster selector visible")
   if editor.career_pickers.has(spec[2]):
    var picker: OptionButton=editor.career_pickers[spec[2]];var chosen := find(picker,spec[3]);check(chosen>=0 and not picker.is_item_disabled(chosen),"actual existing parent enabled")
    if chosen>=0:picker.select(chosen);picker.item_selected.emit(chosen)
    var out: Dictionary=kernel.preview_advancement(r,editor.choice());check(out.ok and out.candidate.advancement_history.back().specialisations[spec[2]]==spec[3],"actual advancement controls persist deliberately chosen parent")
    if spec[1]=="bonded-summoner":
     var absent := find(picker,"sorcerer");check(absent>=0 and picker.is_item_disabled(absent),"unowned parent has visible permanent restriction")
     var forged: Dictionary=editor.choice();forged.specialisations[spec[2]]="sorcerer"
     check(not kernel.preview_advancement(r,forged).ok,"backend independently rejects forged unowned parent")
   index=find(editor.class_picker,spec[3]);editor.class_picker.select(index);editor.class_picker.item_selected.emit(index)
   check(kernel.preview_advancement(r,editor.choice()).ok,"actual UI can decline prestige and continue its parent")
  check(before==RulesJson.digest(r),"parent/decline previews do not commit levels or generate XP");editor.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for spec in [["grove-druid1","grove-protection-1","a"],["grove-druid3","grove-protection-3","a:companion"],["bonded-wizard5","bonded-summoner-technique-5","a"]]:
  var r: Dictionary=saved.records[spec[0]];var b: Dictionary=helper.encounter(r);var aid: String=spec[1];var target: String=spec[2]
  if target=="a:companion":b.units[target].record.runtime.hp=1
  ui.engine=TacticalAuras.new(r);b=ui.engine.seal(b);show(ui,b,aid);ui.sent={};var tile: Array=b.units[target].position
  check(ui.action_buttons.has(aid) and not ui.action_buttons[aid].disabled and ui.tiles[str(tile)].target_tile,"real affordable class action and correct target hitbox "+aid)
  ui.choose_tile(tile);check(ui.sent.get("kind")==aid and ui.sent.get("target")==target,"real tile dispatch names the authoritative actor/target action")
  check(ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":aid,"target_id":target}).ok,"actual UI intent executes through original combat")
  for reason in ["main","reserve"]:
   var empty: Dictionary=b.duplicate(true)
   if reason=="main":empty.budget.main=0
   else:
    for pool in source.definition("abilities",aid).cost.resources:empty.units.a.record.runtime.resources[pool]=0
   empty=ui.engine.seal(empty);show(ui,empty,aid);ui.sent={};ui.choose_tile(tile)
   check(ui.action_buttons[aid].disabled and not ui.tiles[str(tile)].target_tile and ui.sent.is_empty(),"unavailable costs disable button/targets/dispatch "+aid+reason)
 for spec in [["grove_form","grove-protection-1"],["bonded_form","bonded-summoner-technique-5"]]:
  var r: Dictionary=saved.records[spec[0]];var b: Dictionary=helper.encounter(r);ui.engine=TacticalAuras.new(r);show(ui,b,spec[1]);ui.sent={};ui.choose_tile(b.units.a.position)
  check((not ui.action_buttons.has(spec[1]) or ui.action_buttons[spec[1]].disabled) and not ui.tiles[str(b.units.a.position)].target_tile and ui.sent.is_empty(),"body suppression has no misleading available action or target")
 var b: Dictionary=saved.battles["bonded-summoner-call-leopard"]
 ui.engine=TacticalAuras.new(b.units.a.record);var creature: String=ui.engine.current(b).id;b=helper.turn(ui.engine,b,creature)
 show(ui,b,"leopard-special");ui.sent={};var target: Array=b.units["bandit-blade"].position
 check(ui.action_buttons.has("leopard-special") and not ui.action_buttons["leopard-special"].disabled and ui.tiles[str(target)].target_tile,"actual summoned actor turn exposes its own finite special")
 ui.choose_tile(target);check(ui.sent.get("kind")=="leopard-special"and ui.sent.get("target")=="bandit-blade","owned summon control dispatches its actual target")
 check(helper.failures==0,"all UI development fixtures and transitions are legal");helper.free();ui.queue_free()
 FileAccess.open(folder.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"failed_checks":failed_checks,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false}))
 print("GROVE_SUMMONER_INPUT ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
