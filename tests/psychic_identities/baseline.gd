extends "res://tests/psychic_parity/mechanics.gd"
## Reproduces v24 defects without changing its immutable rules or saves.
func run() -> void:
 base=OS.get_environment("GAME127_ROOT");DirAccess.make_dir_recursive_absolute(base)
 check(source.load_pack("res://data/rules/trhgd-character-v24.json").ok,"historical24 loads")
 kernel=RulesCharacter.new(source)
 records.foe=build("foe",route("fighter",20),PSI)
 var lurk := kernel.create("lurk",PSI,"heritage-ogre")
 for n in 4:
  var suggestion := kernel.suggested_choice(lurk,"lurk");check(suggestion.ok,"legal inherited-reach advancement")
  if not suggestion.ok:finish_baseline();return
  var step := kernel.preview_advancement(lurk,suggestion.choice);check(step.ok,"legal inherited-reach history")
  if not step.ok:finish_baseline();return
  lurk=step.candidate
 lurk.runtime.hp=int(kernel.derive_character(lurk).snapshot.stats.HP);lurk.runtime.resources=kernel._replay(lurk).context.capacities.duplicate()
 var veiled := use(lurk,lurk,"lurk-veil");check(veiled.ok,"lawful prior veil")
 if not veiled.ok:finish_baseline();return
 var b := encounter(veiled.actor);var engine := TacticalAuras.new(lurk)
 b.units.a.weapon="shortblade";b.units.a.record.equipment=["shortblade"]
 b.units["bandit-blade"].position=[2,2];b=engine.seal(b)
 var diagnoses := {}
 for id in b.units:diagnoses[id]={"record":kernel.validate_build(b.units[id].record),"weapon":b.units[id].weapon,"position":b.units[id].position,"id":b.units[id].record.character_id}
 check(engine.validate(b).is_empty(),"legal inherited-reach fixture: "+engine.validate(b)+JSON.stringify(diagnoses))
 var ranged := command(engine,b,"lurk-psychic-ambush")
 check(ranged.ok,"REPRODUCTION: adjacent ambush incorrectly inherits two-tile ancestry reach")
 var erudite := build("erudite",["erudite"],PSI,{"erudite-power-1":"power-kinetic-bolt","erudite-second-power":"power-force-screen"})
 var first := use(erudite,records.foe,"power-kinetic-bolt");check(first.ok,"first Erudite identity consumes allowance")
 if not first.ok:finish_baseline();return
 b=encounter(first.actor);engine=TacticalAuras.new(erudite)
 check(not command(engine,b,"power-force-screen","a").ok,"authority correctly rejects second identity")
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 ui.engine=engine;ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.selected_power="power-force-screen";ui.mode="attack";ui.refresh()
 check(ui.action_buttons.has("power-force-screen") and not ui.action_buttons["power-force-screen"].disabled,"REPRODUCTION: exhausted distinct identity remains actionable in actual UI")
 traces={"reach_ambush_accepted":ranged.ok,"distinct_backend_rejected":not command(engine,b,"power-force-screen","a").ok,"distinct_button_enabled":ui.action_buttons.has("power-force-screen") and not ui.action_buttons["power-force-screen"].disabled}
 ui.queue_free();finish_baseline()
func finish_baseline() -> void:
 FileAccess.open(base.path_join("baseline-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"traces":traces,"source":"immutable v24; development fixtures, no earned XP"}))
 get_tree().quit(1 if failures else 0)
