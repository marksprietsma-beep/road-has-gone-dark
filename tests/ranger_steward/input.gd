extends "res://tests/hybrid_acceptance/input.gd"
signal completed
var no_quit := false
func run() -> void:
 var folder := OS.get_environment("RANGER_STEWARD_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(folder.path_join("saved.json")))
 var source := RulesRecords.registry(saved.records.archery1);var kernel := RulesCharacter.new(source)
 var helper: Node=load("res://tests/ranger_steward/mechanics.gd").new();helper.source=source;helper.kernel=kernel;helper.fixtures.fighter=helper.build("fighter",20)
 for style in ["archery","blade"]:
  var r: Dictionary=saved.records[style+"1"];var before := RulesJson.digest(r)
  var editor := BuildEditor.new();add_child(editor);editor.setup(r,false)
  check(editor.class_options().has("ranger") and not editor.class_options().has("beast-steward"),"production creator base Ranger with no prestige starting choice")
  editor.class_filter.text="Ranger";editor.class_filter.text_changed.emit(editor.class_filter.text)
  check(find(editor.class_picker,"ranger")>=0,"actual expanding searchable class selector")
  editor.class_filter.text="";editor.class_filter.text_changed.emit("")
  check(editor.class_picker.item_count==kernel.starting_classes().size(),"clear search restores base roster")
  var picker: OptionButton=editor.career_pickers["ranger-choice-1"];var i := find(picker,style);check(i>=0 and not picker.is_item_disabled(i),"selectable real style alternative")
  if i>=0:picker.select(i);picker.item_selected.emit(i)
  picker=editor.career_pickers["ranger-quarry-choice"];i=find(picker,"archers");check(i>=0,"real permanent quarry choice")
  if i>=0:picker.select(i);picker.item_selected.emit(i)
  for gear in editor.equipment_pickers:
   editor.equipment_pickers[gear].button_pressed=gear in (["bow","leathers"]if style=="archery"else["shortblade","leathers"])
  var created := CharacterBuilderRecords.create(r.character_id,editor.definition(),r);check(created.ok,"actual production controls create valid Ranger "+JSON.stringify(created.get("errors",[])))
  if created.ok:check(created.candidate.advancement_history[0].specialisations["ranger-choice-1"]==style and created.candidate.advancement_history[0].specialisations["ranger-quarry-choice"]=="archers","actual selected style and quarry persist")
  check(RulesJson.digest(r)==before,"creation exploration preserves source character and pin");editor.queue_free()
 var prefix: Dictionary=saved.records.steward_prefix;var advance := BuildEditor.new();add_child(advance);advance.setup(prefix,true)
 var index := find(advance.class_picker,"beast-steward");check(index>=0 and not advance.class_picker.is_item_disabled(index),"qualified prestige is an explicit enabled advancement option")
 if index>=0:
  advance.class_picker.select(index);advance.class_picker.item_selected.emit(index)
  check(advance.career_pickers.has("beast-steward-training"),"actual steward training choices appear")
  var chosen := kernel.preview_advancement(prefix,advance.choice());check(chosen.ok and chosen.candidate.advancement_history.back().class_id=="beast-steward","production prestige selector makes legal optional history")
 advance.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for spec in [["archery6","aimed-shot","bandit-blade"],["blade6","ranger-blade-6","a"],["steward-swift3","steward-rally","a:companion"],["steward-swift5","steward-drive-5","a:companion"]]:
  var r: Dictionary=saved.records[spec[0]];var b: Dictionary=helper.encounter(r);var aid: String=spec[1];var target: String=spec[2]
  if target=="a:companion":b.units[target].record.runtime.hp=1
  ui.engine=TacticalAuras.new(r);b=ui.engine.seal(b);show(ui,b,aid);ui.sent={};var tile: Array=b.units[target].position
  check(ui.action_buttons.has(aid) and not ui.action_buttons[aid].disabled and ui.tiles[str(tile)].target_tile,"real affordable action and accurate owner/creature targeting "+aid)
  ui.choose_tile(tile);check(ui.sent.get("kind")==aid and ui.sent.get("target")==target,"actual click sends correct authoritative intent")
  check(ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":aid,"target_id":target}).ok,"UI intent executes via original authority")
  var reasons := ["spent-main"]
  if aid=="aimed-shot":reasons.append_array(["spent-move","wrong-weapon"])
  if not source.definition("abilities",aid).cost.resources.is_empty():reasons.append("empty-resource")
  for reason in reasons:
   var blocked := b.duplicate(true)
   if reason=="spent-main":blocked.budget.main=0
   elif reason=="spent-move":blocked.budget.move=0
   elif reason=="wrong-weapon":blocked.units.a.weapon="shortblade";blocked.units.a.record.equipment=["shortblade","leathers"]
   else:
    for pool in source.definition("abilities",aid).cost.resources:blocked.units.a.record.runtime.resources[pool]=0
   blocked=ui.engine.seal(blocked);var before := RulesJson.digest(blocked);show(ui,blocked,aid);ui.sent={};ui.choose_tile(tile)
   check(ui.action_buttons[aid].disabled and not ui.tiles[str(tile)].target_tile and ui.sent.is_empty(),"unavailable action disabled with no target/intent "+aid+reason)
   check(not ui.engine.command(blocked,{"actor_id":"a","revision":blocked.revision,"kind":aid,"target_id":target}).ok and before==RulesJson.digest(blocked),"rules independently reject invalid intent without state/RNG change")
 var r: Dictionary=saved.records["owner-leopard"];var b: Dictionary=helper.encounter(r);var pid: String="a:companion"
 b.cursor=b.order.find(pid);b.units[pid].position=[1,1];b.units.a.position=[0,1];ui.engine=TacticalAuras.new(r);b=ui.engine.seal(b);show(ui,b,"leopard-special");ui.sent={}
 check(ui.action_buttons.has("leopard-special") and not ui.action_buttons["leopard-special"].disabled,"actual owned-actor turn exposes its distinct action")
 ui.choose_tile(b.units["bandit-blade"].position);check(ui.sent.get("kind")=="leopard-special"and ui.sent.get("target")=="bandit-blade","actual pet tile targets correct enemy")
 check(ui.engine.command(b,{"actor_id":pid,"revision":b.revision,"kind":"leopard-special","target_id":"bandit-blade"}).ok,"pet UI dispatch spends own resources through same engine")
 check(helper.failures==0,"UI fixture histories, companions and boards remain legal");helper.free();ui.queue_free()
 FileAccess.open(folder.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false,"scope":"Actual original creator search/style/quarry, optional prestige training, owner/owned-actor combat controls and target handlers; genuine XP/writer tested separately."}))
 print("RANGER_STEWARD_INPUT ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
