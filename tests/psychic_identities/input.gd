extends "res://tests/psychic_parity/input.gd"
func run() -> void:
 var base := OS.get_environment("GAME127_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for cls in ["ardent","lurk","erudite"]:
  var original: Dictionary=saved.records[cls+"1"];var before := RulesJson.digest(original)
  var editor := BuildEditor.new();add_child(editor);editor.setup(original,false);editor.class_loadout();editor.refresh_preview()
  check(editor.class_id==cls and editor.preview.ok,"actual production creator valid on first open "+cls)
  check(editor.class_options().has(cls) and not editor.class_options().has("cerebremancer"),"base choice remains central; no prestige at birth")
  var powers: OptionButton=editor.career_pickers[cls+"-power-1"]
  check(powers.item_count>1,"actual blank search offers choices "+cls)
  for i in powers.item_count:
   if int(editor.source.definition("psychic_powers",str(powers.get_item_metadata(i))).tier)>1:check(powers.is_item_disabled(i),"higher power unavailable at birth")
  if cls=="ardent":
   choose(editor.career_pickers["ardent-mantle"],"energy");choose(editor.career_pickers["ardent-second-mantle"],"body")
   choose(editor.career_pickers["ardent-power-1"],"power-kinetic-bolt");choose(editor.career_pickers["ardent-second-power"],"power-force-screen")
   check(editor.preview.ok,"actual mantle and different power choices create valid Ardent")
   for i in powers.item_count:
    if powers.get_item_metadata(i)=="power-thought-thrust":check(powers.is_item_disabled(i),"actual control explains out-of-mantle restriction")
   choose(editor.career_pickers["ardent-second-mantle"],"mind")
   choose(editor.career_pickers["ardent-second-power"],"power-thought-thrust")
   check(editor.preview.ok,"actual mantle change changes legal power choices")
  check(RulesJson.digest(original)==before,"creator preview preserves saved identity and RNG")
  editor.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 for at in [1,8,20]:
  var b: Dictionary=saved.battles["spent-erudite"+str(at)].duplicate(true);var engine := TacticalAuras.new(b.units.a.record)
  var snapshot: Dictionary=engine.characters.derive_character(b.units.a.record).snapshot
  var blocked: String=snapshot.known_powers.filter(func(id: String):return not snapshot.manifested_powers.has(id))[0]
  var repeated: String=snapshot.manifested_powers[0];var digest := RulesJson.digest(b)
  ui.engine=engine;ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.selected_power=blocked;ui.selected_augmentation=0;ui.mode="attack";ui.refresh()
  check(ui.action_buttons.has(blocked) and ui.action_buttons[blocked].disabled,"actual exhausted Erudite button disabled "+str(at))
  check("Distinct powers" in ui.action_buttons[blocked].tooltip_text,"actual disabled action explains distinct allowance")
  ui.selected_power=repeated;ui.refresh()
  check(ui.action_buttons.has(repeated) and not ui.action_buttons[repeated].disabled,"actual repeated power still available "+str(at))
  if at>=8:
   var augment: OptionButton=ui.find_child("PsychicAugmentationSelector",true,false)
   var variants: Array=engine.registry.definition("psychic_powers",repeated).variants
   choose(augment,str(variants[1]))
   check(ui.action_buttons.has(str(variants[1])) and not ui.action_buttons[str(variants[1])].disabled,"actual augmentation shares used identity")
  check(RulesJson.digest(b)==digest,"selecting blocked, repeated and augmented powers changes no combat state")
 var b: Dictionary=saved.battles["veiled-lurk8"].duplicate(true);ui.engine=TacticalAuras.new(b.units.a.record)
 ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode="lurk-psychic-ambush";ui.refresh()
 check(ui.action_buttons.has("lurk-psychic-ambush") and not ui.action_buttons["lurk-psychic-ambush"].disabled,"actual veiled melee ambush offered")
 var position: Array=b.units["bandit-blade"].position
 check(ui.tiles[str(position)].target_tile,"adjacent enemy tile highlights correct hitbox")
 ui.tiles[str(position)].pressed.emit()
 check(ui.sent.get("kind")=="lurk-psychic-ambush" and ui.sent.get("target")=="bandit-blade","actual button and tile target correct identity")
 check(ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":ui.sent.get("kind",""),"target_id":ui.sent.get("target","")}).ok,"actual production intent accepted by authority")
 b=saved.battles["bow-lurk"].duplicate(true);ui.engine=TacticalAuras.new(b.units.a.record);ui.state.first_adventure.battle=b;ui.refresh()
 check(ui.action_buttons["lurk-psychic-ambush"].disabled and not ui.tiles[str(position)].target_tile,"actual bow ambush action and targeting unavailable")
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual production Godot creator and combat controls/signals, mantle options, powers, augmentation, disabled reasons and tile targeting. Human and OS input review remains separate."}))
 get_tree().quit(1 if failures else 0)
