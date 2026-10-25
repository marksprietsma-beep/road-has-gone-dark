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
 var base := OS.get_environment("GAME129_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for cls in ["soulknife","warblade","crusader","swordsage"]:
  var battle: Dictionary=saved.battles[cls].duplicate(true)
  battle.cursor=battle.order.find("a");battle.budget={"main":1,"move":1}
  ui.engine=TacticalAuras.new(battle.units.a.record);battle=ui.engine.seal(battle)
  ui.state={"first_adventure":{"battle":battle},"party_ids":["a","b","c"],"party":{"members":[]}}
  ui.mode="attack";ui.refresh()
  check(ui.detail.text.contains("Shared reaction:") and ui.detail.text.contains("Weapon:"),"production resource/weapon/reaction feedback "+cls)
  var action: String={"soulknife":"soulknife-hurl","warblade":"warblade-arm-riposte","crusader":"crusader-recover","swordsage":"swordsage-arm-afterimage"}[cls]
  check(ui.action_buttons.has(action),"production visible signature control "+action)
  check(ui.action_buttons[action].text.contains("Movement") if cls in ["warblade","swordsage"] else ui.action_buttons[action].text.contains("Action"),"visible actual action cost "+cls)
  check(not ui.action_buttons.has("warblade-riposte") and not ui.action_buttons.has("swordsage-afterimage") and not ui.action_buttons.has("crusader-renewal"),"trigger-only effects never manually invokable")
  if cls=="warblade" or cls=="swordsage":
   ui.sent={};ui.action_buttons[action].pressed.emit()
   check(ui.sent.get("kind")==action and ui.sent.get("target")=="a","visible arm action sends existing campaign command")
  if cls=="soulknife":
   check(ui.action_buttons[action].text.contains("range 4"),"hurl displays actual authoritative range rather than generic melee range")
   var strike := "soulknife-technique-8"
   var original_hash := RulesJson.digest(battle)
   var p: Array=battle.units["bandit-blade"].position
   # The saved hit fixture has already spent its entire two-point Focus pool.
   # Resetting main does not restore resources or make that strike affordable.
   check(int(battle.units.a.record.runtime.resources["soulknife-focus"])==0,"original poststrike fixture is genuinely exhausted")
   ui.mode=strike;ui.refresh();ui.sent={}
   check(ui.action_buttons[strike].disabled and not ui.tiles[str(p)].target_tile,"exhausted strike has no misleading button or target")
   ui.choose_tile(p)
   check(ui.sent.is_empty() and not ui.engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":strike,"target_id":"bandit-blade"}).ok,"exhausted click emits no intent and authority rejects it")
   print("SOULKNIFE_EXHAUSTED_CONTROL ",JSON.stringify({"focus":battle.units.a.record.runtime.resources["soulknife-focus"],"main":battle.budget.main,"button_disabled":ui.action_buttons[strike].disabled,"target":ui.tiles[str(p)].target_tile,"intent":ui.sent}))
   check(RulesJson.digest(battle)==original_hash,"unavailable controls preserve exact battle/RNG/log")
   var recovered := ui.engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":"soulknife-recover","target_id":"a"})
   check(recovered.ok,"actual main-action Focus recovery")
   if recovered.ok:
    battle=recovered.battle
    check(battle.budget.main==0 and int(battle.units.a.record.runtime.resources["soulknife-focus"])==2,"recovery restores two Focus without granting another main")
    # Ordinary End commands advance the fixture to the next real activation.
    for turn in battle.order.size()+1:
     var actor: Dictionary=ui.engine.current(battle)
     if actor.id=="a" and int(battle.budget.main)==1:break
     var ended := ui.engine.command(battle,{"actor_id":actor.id,"revision":battle.revision,"kind":"end"})
     check(ended.ok,"ordinary turn advance after recovery")
     if not ended.ok:break
     battle=ended.battle
    check(ui.engine.current(battle).id=="a" and int(battle.budget.main)==1,"next legal Soulknife activation")
    ui.state.first_adventure.battle=battle;ui.mode=strike;ui.sent={};ui.refresh()
    check(not ui.action_buttons[strike].disabled and ui.engine.eligible(battle,ui.engine.current(battle),battle.units["bandit-blade"],strike) and ui.tiles[str(p)].target_tile,"correct affordable melee targeting hitbox")
    ui.choose_tile(p);check(ui.sent.get("kind")==strike and ui.sent.get("target")=="bandit-blade","production target click preserves real enemy identity")
    check(ui.engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":strike,"target_id":"bandit-blade"}).ok,"recovered UI intent is truly executable")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual production combat controls/targeting; authority tested separately."}))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
