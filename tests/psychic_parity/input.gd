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
 check(false,"actual option exists "+identity);return false
func run() -> void:
 var base := OS.get_environment("GAME152_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for cls in ["psion","wilder"]:
  var original: Dictionary=saved.records[cls+"1"];var before := RulesJson.digest(original)
  var editor := BuildEditor.new();add_child(editor);editor.setup(original,false);editor.class_loadout();editor.refresh_preview()
  check(editor.class_id==cls and editor.preview.ok,"actual class-one creator is valid "+cls)
  check(not editor.class_options().has("cerebremancer"),"prestige absent from actual creation selector")
  var picker: OptionButton=editor.career_pickers[cls+"-power-1"]
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
  var used := ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":ui.sent.get("kind",""),"target_id":ui.sent.get("target","")})
  check(used.ok and int(used.battle.units.a.record.runtime.resources["psychic-points"])==int(b.units.a.record.runtime.resources["psychic-points"])-3,"actual GUI intent executes with exactly three points")
 check(RulesJson.digest(b)==before,"selector/target feedback consumes no RNG/state/resources")
 var empty: Dictionary=b.duplicate(true);empty.units.a.record.runtime.resources["psychic-points"]=0;empty=ui.engine.seal(empty)
 ui.state.first_adventure.battle=empty;ui.refresh()
 check(ui.action_buttons.has(id) and ui.action_buttons[id].disabled,"actual exhausted manifestation button is disabled")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Real production Godot creator/power/discipline/prestige and battle selector/augmentation/buttons/target tiles. Signal-based controls, not OS/human input acceptance."}))
 get_tree().quit(1 if failures else 0)
