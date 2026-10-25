extends Node
signal completed
var no_quit := false
var failures := 0
var checks := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME133_ROOT")
 var saved := RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 var battle: Dictionary=saved.battle.duplicate(true)
 ui.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
 ui.engine=TacticalAuras.new(battle.units.a.record);battle=ui.engine.seal(battle)
 ui.state.first_adventure.battle=battle;ui.mode="druid-packward-canopy";ui.sent={};ui.refresh()
 var blocked_position: Array=battle.units[RulesEntities.identity("a")].position
 var exhausted_hash := RulesJson.digest(battle)
 check(int(battle.budget.main)==0,"original saved cast has already spent its main action")
 check(ui.action_buttons["druid-packward-canopy"].disabled and not ui.tiles[str(blocked_position)].target_tile,"spent spell has no misleading action or target")
 ui.choose_tile(blocked_position)
 check(ui.sent.is_empty() and RulesJson.digest(battle)==exhausted_hash,"unavailable spell click preserves exact battle/log/RNG and emits no intent")
 # A separate lawful development encounter after the existing eligible-rest
 # boundary supplies a genuinely affordable positive targeting case.
 var source := RulesRecords.registry(battle.units.a.record)
 var derived := RulesCharacter.new(source).derive_character(battle.units.a.record)
 check(derived.ok,"original historical caster remains valid")
 var rested := RulesEffects.new(source).refresh_resources(battle.units.a.record.runtime,derived.snapshot.resource_capacities,"eligible_rest")
 check(rested.ok,"actual eligible-rest policy restores daily slots and prepared copies")
 if not rested.ok:
  ui.queue_free();get_tree().quit(1);return
 battle.units.a.record.runtime=rested.runtime;battle.cursor=battle.order.find("a");battle.budget={"main":1,"move":1};battle=ui.engine.seal(battle)
 check(ui.engine.validate(battle).is_empty(),"fresh historical encounter is authoritative and valid")
 ui.state.first_adventure.battle=battle;ui.mode="druid-packward-canopy";ui.sent={};ui.refresh()
 var pet_id := RulesEntities.identity("a");var p: Array=battle.units[pet_id].position
 check(ui.tiles.has(str(p)) and ui.tiles[str(p)].target_tile,"actual pet tile highlighted")
 ui.choose_tile(p)
 check(ui.sent.get("kind")=="druid-packward-canopy" and ui.sent.get("target")==pet_id,"production click selects companion identity")
 check(ui.engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":"druid-packward-canopy","target_id":pet_id}).ok,"positive UI spell intent is genuinely executable")
 check(ui.action_buttons.has("druid-packward-canopy"),"real combat action exposes new spell")
 var spellbook := SpellbookEditor.new();var record: Dictionary=saved.records["sorcerer-crystal-reservoir"]
 spellbook.setup(record)
 check(spellbook.controls["sorcerer-crystal-reservoir"].button_pressed and spellbook.controls["sorcerer-crystal-reservoir"].disabled,"known spontaneous choice is visible and locked")
 check(not spellbook.controls["sorcerer-slipstream-veil"].disabled,"unknown legal spontaneous option can be learned")
 spellbook.free()
 var granted := RulesEffects.new(RulesRecords.registry(record)).use_ability(record,record,"sorcerer-crystal-reservoir",{"main":1,"move":1,"reaction":1},RulesRng.initial("visible-buffer"))
 check(granted.ok,"real spell supplies displayed buffer")
 if granted.ok:
  for id in battle.units.keys().duplicate():
   if battle.units[id].has("entity"):battle.units.erase(id);battle.order.erase(id)
  battle.units.a.record=granted.actor;battle.cursor=battle.order.find("a")
  ui.engine=TacticalAuras.new(granted.actor);battle=ui.engine.seal(battle)
  check(ui.engine.current(battle).id=="a","buffer fixture explicitly selects the displaying actor")
  check(ui.engine.validate(battle).is_empty(),"buffer UI fixture remains an authoritative valid battle")
  ui.state.first_adventure.battle=battle;ui.mode="attack";ui.refresh()
  check("18 temporary HP"in ui.detail.text,"active character sees actual finite HP buffer")
  check("18 temporary HP"in ui.tiles[str(battle.units.a.position)].tooltip_text,"hover targeting exposes real buffer")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Production combat click/highlights and persistent known-spell controls."}))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
