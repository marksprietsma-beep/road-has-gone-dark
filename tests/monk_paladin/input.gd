extends "res://tests/hybrid_acceptance/input.gd"
signal completed
var no_quit := false
func run() -> void:
 var folder := OS.get_environment("MONK_PALADIN_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(folder.path_join("saved.json")))
 var source := RulesRecords.registry(saved.records["monk-wind1"]);var kernel := RulesCharacter.new(source)
 var helper: Node=load("res://tests/monk_paladin/mechanics.gd").new();helper.source=source;helper.kernel=kernel;helper.fixtures.fighter=helper.build("fighter",20)
 for spec in [["monk","wind","dodge"],["paladin","justice","toughness"]]:
  var r: Dictionary=saved.records[str(spec[0])+"-"+str(spec[1])+"1"];var before := RulesJson.digest(r)
  var editor := BuildEditor.new();add_child(editor);editor.setup(r,false)
  check(editor.class_options().has("monk") and editor.class_options().has("paladin") and not editor.class_options().has("mystic-theurge"),"production creator offers only base careers")
  editor.class_filter.text=str(spec[0]);editor.class_filter.text_changed.emit(editor.class_filter.text)
  check(find(editor.class_picker,spec[0])>=0,"actual searchable class selector")
  editor.class_filter.text="";editor.class_filter.text_changed.emit("")
  check(editor.class_picker.item_count==kernel.starting_classes().size(),"cleared search restores all base classes")
  var key: String=str(spec[0])+"-choice-1";check(editor.career_pickers.has(key),"actual discipline/oath control exists")
  if editor.career_pickers.has(key):
   var picker: OptionButton=editor.career_pickers[key];var i := find(picker,spec[1]);check(i>=0 and not picker.is_item_disabled(i),"real alternative selectable")
   if i>=0:picker.select(i);picker.item_selected.emit(i)
  var feat := find(editor.feat_picker,spec[2]);check(feat>=0 and not editor.feat_picker.is_item_disabled(feat),"actual legal distinct feat choice")
  if feat>=0:editor.feat_picker.select(feat);editor.feat_picker.item_selected.emit(feat)
  var created := CharacterBuilderRecords.create(r.character_id,editor.definition(),r)
  check(created.ok,"real production controls create lawful character "+JSON.stringify(created.get("errors",[])))
  if created.ok:check(created.candidate.advancement_history[0].specialisations[key]==spec[1] and created.candidate.advancement_history[0].feat_id==spec[2],"actual selected class/oath/feat persists")
  check(RulesJson.digest(r)==before,"creator exploration preserves original saved identity and state")
  editor.queue_free()
 var late: Dictionary=helper.make("monk",14,helper.options("monk","wind"))
 var advance := BuildEditor.new();add_child(advance);advance.setup(late,true)
 check(advance.career_pickers.has("monk-choice-15"),"actual late discipline choice visible")
 if advance.career_pickers.has("monk-choice-15"):
  var picker: OptionButton=advance.career_pickers["monk-choice-15"];var wind := find(picker,"wind");var iron := find(picker,"iron")
  check(wind>=0 and not picker.is_item_disabled(wind) and iron>=0 and picker.is_item_disabled(iron),"permanent original discipline gates late alternative with explanation")
  if wind>=0:picker.select(wind);picker.item_selected.emit(wind)
  var chosen := kernel.preview_advancement(late,advance.choice());check(chosen.ok,"real late UI selection is lawful")
  if chosen.ok:check(chosen.snapshot.stats.save_dc==kernel.derive_character(late).snapshot.stats.save_dc+2,"late UI choice yields real palm save DC")
 advance.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for spec in [["monk-wind6","flurry","bandit-blade"],["monk-wind6","monk-wind-6","a"],["paladin-justice6","smite","bandit-blade"],["paladin-mercy6","paladin-mercy-6","b"]]:
  var r: Dictionary=saved.records[spec[0]];var b: Dictionary=helper.encounter(r);var id: String=spec[1];var target: String=spec[2]
  if target=="b":b.units.b.position=[1,2]
  ui.engine=TacticalAuras.new(r);b=ui.engine.seal(b);show(ui,b,id);ui.sent={};var tile: Array=b.units[target].position
  check(ui.action_buttons.has(id) and not ui.action_buttons[id].disabled and ui.tiles[str(tile)].target_tile,"affordable production action and accurate target highlight "+id)
  ui.choose_tile(tile)
  check(ui.sent.get("kind")==id and ui.sent.get("target")==target,"actual tile click sends correct actor/action/target")
  check(ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":id,"target_id":target}).ok,"real UI intent executes through original authority")
  var reasons := ["spent-main"]
  if not source.definition("abilities",id).cost.resources.is_empty():reasons.append("empty-resource")
  if id=="smite":reasons.append("wrong-weapon")
  if id=="flurry":reasons.append("manifested-weapon")
  for reason in reasons:
   var blocked := b.duplicate(true)
   if reason=="spent-main":blocked.budget.main=0
   elif reason=="empty-resource":
    for pool in source.definition("abilities",id).cost.resources:blocked.units.a.record.runtime.resources[pool]=0
   elif reason=="wrong-weapon":blocked.units.a.record.equipment=["bow","mail"];blocked.units.a.weapon="bow"
   else:
    var hybrid: Dictionary=helper.more(helper.make("monk",1),"soulknife",1);var manifested: Dictionary=helper.use(hybrid,hybrid,"soulknife-manifest")
    check(manifested.ok,"UI negative uses a real legal manifestation")
    if not manifested.ok:continue
    blocked=helper.encounter(manifested.actor)
   blocked=ui.engine.seal(blocked);var before := RulesJson.digest(blocked)
   check(ui.engine.validate(blocked).is_empty(),"negative UI fixture remains a legal battle "+reason)
   show(ui,blocked,id);ui.sent={};ui.choose_tile(tile)
   check(ui.action_buttons[id].disabled and not ui.tiles[str(tile)].target_tile and ui.sent.is_empty(),"unavailable action has disabled control, no highlight or intent "+id+reason)
   check(not ui.engine.command(blocked,{"actor_id":"a","revision":blocked.revision,"kind":id,"target_id":target}).ok,"rules authority independently rejects unavailable action")
   check(before==RulesJson.digest(blocked) and before==RulesJson.digest(ui.state.first_adventure.battle),"denial preserves exact HP/resources/log/RNG")
 check(helper.failures==0,"all UI fixture histories and resources legal");helper.free();ui.queue_free()
 FileAccess.open(folder.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false,"scope":"Actual production creator choice/search/feat and combat control/target handlers. Sole campaign writer and earned advancement verified separately."}))
 print("MONK_PALADIN_INPUT ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
