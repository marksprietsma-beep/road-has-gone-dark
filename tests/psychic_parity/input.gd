extends Node
var checks := 0
var failures := 0
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(message)
func _ready() -> void:call_deferred("run")
func choose(control: OptionButton,identity: String) -> bool:
 for index in control.item_count:
  if str(control.get_item_metadata(index))==identity:
   check(not control.is_item_disabled(index),"actual option is selectable "+identity)
   control.select(index);control.item_selected.emit(index);return true
 var rows: Array=[]
 for index in control.item_count:rows.append({"metadata":control.get_item_metadata(index),"text":control.get_item_text(index),"disabled":control.is_item_disabled(index)})
 check(false,"actual option exists "+identity+"; available="+JSON.stringify(rows));return false
func run() -> void:
 var base := OS.get_environment("GAME152_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for cls in ["psion","wilder"]:
  var original: Dictionary=saved.records[cls+"1"];var before := RulesJson.digest(original)
  var editor := BuildEditor.new();add_child(editor);editor.setup(original,false);editor.class_loadout();editor.refresh_preview()
  check(editor.class_id==cls and editor.preview.ok,"actual class-one creator is valid "+cls)
  check(not editor.class_options().has("cerebremancer"),"prestige absent from actual creation selector")
  var picker: OptionButton=editor.career_pickers[cls+"-power-1"]
  check(picker.item_count>1,"blank actual power search shows available alternatives on first open")
  editor.power_query="Thought";editor.refresh_power_options()
  check(picker.item_count>1,"actual power search retains selection and matching alternatives")
  editor.power_query="";editor.refresh_power_options()
  check(picker.item_count==editor.source.definition("classes",cls).career_choices.filter(func(g: Dictionary):return g.id==cls+"-power-1")[0].options.size(),"clearing actual power search restores the complete class list")
  for i in picker.item_count:
   var id: String=str(picker.get_item_metadata(i));var tier: int=int(editor.source.definition("psychic_powers",id).tier)
   if tier>1:check(picker.is_item_disabled(i),"actual higher-tier power is locked at birth "+id)
  if cls=="psion":
   choose(editor.career_pickers["psion-second-power"],"power-force-screen")
   choose(editor.career_pickers["psion-power-1"],"power-thought-thrust")
   choose(editor.career_pickers["psion-discipline"],"ward")
   check(editor.preview.ok and not editor.kernel.derive_character(editor.preview.candidate).snapshot.features.has("psion-discipline-assault"),"actual Ward choice changes mechanical candidate")
  else:
   choose(editor.career_pickers["wilder-power-1"],"power-thought-fog")
   check(editor.preview.ok and editor.kernel.derive_character(editor.preview.candidate).snapshot.known_powers.has("power-thought-fog"),"actual Wilder power choice changes repertoire")
  check(RulesJson.digest(original)==before,"creator staging never mutates original saved identity/resources")
  editor.queue_free()
 var advance := BuildEditor.new();add_child(advance);advance.setup(saved.records.precursor,true)
 var before := RulesJson.digest(saved.records.precursor)
 choose(advance.class_picker,"cerebremancer")
 check(advance.preview.ok and advance.preview.candidate.advancement_history.back().class_id=="cerebremancer","actual eligible prestige is an explicit selectable advancement")
 check(RulesJson.digest(saved.records.precursor)==before,"eligibility/preview never assigns prestige")
 advance.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 var b: Dictionary=saved.battles["ready-psion8"].duplicate(true)
 ui.engine=TacticalAuras.new(b.units.a.record);ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode="attack";ui.refresh()
 before=RulesJson.digest(b)
 var powers: OptionButton=ui.find_child("PsychicPowerSelector",true,false)
 check(powers!=null,"actual in-combat known-power selector exists")
 if powers!=null:choose(powers,"power-kinetic-bolt")
 var augment: OptionButton=ui.find_child("PsychicAugmentationSelector",true,false)
 check(augment!=null,"actual deliberate augmentation selector exists")
 if augment!=null:choose(augment,"power-kinetic-bolt-aug2")
 var id := "power-kinetic-bolt-aug2"
 check(ui.action_buttons.has(id) and not ui.action_buttons[id].disabled,"actual affordable augmented action is discoverable")
 if ui.action_buttons.has(id):
  ui.action_buttons[id].pressed.emit()
  var position: Array=b.units["bandit-blade"].position
  check(ui.tiles[str(position)].target_tile,"actual target tile matches tactical hitbox")
  ui.tiles[str(position)].pressed.emit()
  check(ui.sent.get("kind")==id and ui.sent.get("target")=="bandit-blade","actual button/tile intent contains selected variant and correct enemy")
  var used: Dictionary=ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":ui.sent.get("kind",""),"target_id":ui.sent.get("target","")})
  check(used.ok and int(used.battle.units.a.record.runtime.resources["psychic-points"])==int(b.units.a.record.runtime.resources["psychic-points"])-3,"actual GUI intent executes with exactly three points")
 check(RulesJson.digest(b)==before,"selector/target feedback consumes no RNG/state/resources")
 var empty: Dictionary=b.duplicate(true);empty.units.a.record.runtime.resources["psychic-points"]=0;empty=ui.engine.seal(empty)
 ui.state.first_adventure.battle=empty;ui.refresh()
 check(ui.action_buttons.has(id) and ui.action_buttons[id].disabled,"actual exhausted manifestation button is disabled")
 ui.state.first_adventure.battle=b;ui.selected_power="power-force-screen";ui.selected_augmentation=0;ui.refresh()
 check(ui.action_buttons.has("power-force-screen") and not ui.action_buttons["power-force-screen"].disabled,"legal affordable self-manifestation stays enabled")
 var control_helper: Node=load("res://tests/upper_prepared/mechanics.gd").new();control_helper.source=ui.engine.registry;control_helper.kernel=RulesCharacter.new(control_helper.source)
 var caster: Dictionary=control_helper.prepare_upper(control_helper.build("wizard",20),"wizard-stillness-lattice")
 var target: Dictionary=b.units.a.record.duplicate(true)
 target.runtime.modifiers.append({"stat":"will","type":"untyped","value":-100,"source":"forced-save-development-fixture"})
 var controlled: Dictionary=RulesEffects.new(control_helper.source).use_ability(caster,target,"wizard-stillness-lattice",{"main":1,"move":1,"reaction":1},RulesRng.initial("game152-real-suppression"))
 check(control_helper.failures==0 and controlled.ok,"real legal Wizard cast suppresses an otherwise valid psychic character")
 control_helper.free()
 if controlled.ok:
  var control_snapshot: Dictionary=ui.engine.characters.derive_character(controlled.target).snapshot
  check(control_snapshot.tags.has("main_action_suppressed"),"real Stillness cast applied main suppression; events="+JSON.stringify(controlled.events)+"; statuses="+JSON.stringify(controlled.target.runtime.statuses))
  var blocked: Dictionary=b.duplicate(true);blocked.units.a.record=controlled.target;ui.engine=TacticalAuras.new(controlled.target);blocked=ui.engine.seal(blocked)
  check(ui.engine.validate(blocked).is_empty(),"temporary main suppression preserves a valid tactical fixture")
  var digest := RulesJson.digest(blocked)
  ui.state.first_adventure.battle=blocked;ui.refresh()
  var display_diagnostic := {"pin":ui.engine.registry.rules_ref(),"parity":RulesPsychic.parity_enabled(ui.engine.registry),"display_matches_battle":RulesJson.digest(ui.battle())==digest,"selected_power":ui.selected_power,"buttons":ui.action_buttons.keys(),"actor":ui.engine.current(blocked).id,"tags":ui.engine.characters.derive_character(ui.engine.current(blocked).record).snapshot.tags,"statuses":ui.engine.current(blocked).record.runtime.statuses,"display_tags":ui.engine.characters.derive_character(ui.engine.current(ui.battle()).record).snapshot.tags,"has_button":ui.action_buttons.has("power-force-screen")}
  if ui.action_buttons.has("power-force-screen"):display_diagnostic.disabled=ui.action_buttons["power-force-screen"].disabled;display_diagnostic.ready_disabled=ui.action_buttons["power-force-screen"].get_meta("ready_disabled")
  check(ui.action_buttons.has("power-force-screen") and ui.action_buttons["power-force-screen"].disabled,"actual self-power button respects main suppression despite affordable points; "+JSON.stringify(display_diagnostic))
  check(not ui.engine.command(blocked,{"actor_id":"a","revision":blocked.revision,"kind":"power-force-screen","target_id":"a"}).ok,"authoritative command rejects a temporarily suppressed self manifestation")
  check(RulesJson.digest(blocked)==digest,"suppressed self manifestation consumes no points/main/RNG")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Real production Godot creator/power/discipline/prestige and battle selector/augmentation/buttons/target tiles. Signal-based controls, not OS/human input acceptance."}))
 get_tree().quit(1 if failures else 0)
