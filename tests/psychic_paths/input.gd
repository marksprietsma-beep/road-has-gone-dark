extends "res://tests/psychic_parity/input.gd"
func run() -> void:
 var base := OS.get_environment("GAME127_PATH_ROOT");var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var creator := BuildEditor.new();add_child(creator);creator.setup(saved.records.psion1,false);creator.class_loadout();creator.refresh_preview()
 check(creator.preview.ok and creator.class_id=="psion","actual ordinary psychic base creation remains legal")
 for cls in ["metamind","pyrokineticist"]:check(not creator.class_options().has(cls),"prestige excluded from actual starting choices "+cls)
 creator.queue_free()
 for cls in ["metamind","pyrokineticist"]:
  var original: Dictionary=saved.records[cls+"0"];var before := RulesJson.digest(original)
  var advance := BuildEditor.new();add_child(advance);advance.setup(original,true)
  choose(advance.class_picker,cls)
  check(advance.preview.ok and advance.preview.candidate.advancement_history.back().class_id==cls,"actual eligible prestige manually previewed "+cls)
  check(RulesJson.digest(original)==before,"actual advancement preview never auto-assigns or mutates history")
  if cls=="metamind":
   choose(advance.career_pickers["metamind-discipline-1"],"resilience")
   check(advance.preview.ok and advance.kernel.derive_character(advance.preview.candidate).snapshot.capabilities.resistances.psychic==2,"actual persistent resilience option")
   var amount: int=int(advance.kernel.derive_character(advance.preview.candidate).snapshot.resource_capacities["psychic-points"])
   choose(advance.career_pickers["metamind-discipline-1"],"reserve")
   check(advance.preview.ok and int(advance.kernel.derive_character(advance.preview.candidate).snapshot.resource_capacities["psychic-points"])==amount+2,"actual reserve alternative changes finite capacity")
  advance.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for cls in ["metamind","pyrokineticist"]:
  var b: Dictionary=saved.battles["ready-"+cls+"1"].duplicate(true);var before := RulesJson.digest(b)
  ui.engine=TacticalAuras.new(b.units.a.record);ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode="attack";ui.refresh()
  var action := "metamind-reclaim" if cls=="metamind" else "pyrokineticist-technique-1"
  check(ui.action_buttons.has(action) and not ui.action_buttons[action].disabled,"actual affordable path action is available "+cls)
  ui.action_buttons[action].pressed.emit()
  var target := "a" if cls=="metamind" else "bandit-blade"
  if cls=="pyrokineticist":
   var position: Array=b.units[target].position
   check(ui.tiles[str(position)].target_tile,"actual fire targeting hitbox")
   ui.tiles[str(position)].pressed.emit()
  check(ui.sent.get("kind")==action and ui.sent.get("target")==target,"actual path button dispatches correct intent "+cls)
  var used: Dictionary=ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":ui.sent.get("kind",""),"target_id":ui.sent.get("target","")})
  check(used.ok,"actual path UI intent executes through existing tactical authority")
  check(RulesJson.digest(b)==before,"UI selection changes neither saved state nor RNG")
  var empty: Dictionary=b.duplicate(true);empty.units.a.record.runtime.resources["metamind-reserve" if cls=="metamind" else "psychic-points"]=0
  empty=ui.engine.seal(empty);ui.state.first_adventure.battle=empty;ui.refresh()
  check(ui.action_buttons[action].disabled,"actual exhausted path action is disabled "+cls)
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual Godot base creator, optional prestige/discipline advancement and tactical self/fire target controls. High-level input fixtures are separate from earned progression."}))
 get_tree().quit(1 if failures else 0)
