extends "res://tests/character_wave_five/mechanics_driver.gd"
## Pinned27 diagnostic witnesses, not acceptance/promotion of either career.
const Capture = preload("res://tests/nature_repertoires/capture_driver.gd")
var evidence := {}
func run() -> void:
 base=OS.get_environment("HYBRID_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v27.json").ok,"pinned27 diagnostic source")
 kernel=RulesCharacter.new(source)
 test_historical_projection()
 fixtures.fighter=build("fighter",20)
 var sorcerer := archmage("sorcerer")
 var wizard := archmage("wizard")
 if not sorcerer.is_empty() and not wizard.is_empty():
  for spec in [["sorcerer",sorcerer],["wizard",wizard]]:
   var r: Dictionary=spec[1];var d := kernel.derive_character(r)
   var cast := use_at_save(r,fixtures.fighter,"high-arcana-force-1",1)
   check(cast.ok,"actual high arcana executes for selected "+str(spec[0])+JSON.stringify(cast.get("errors",[])))
   var dc := RulesExpressions.evaluate_formula(source.definition("abilities","high-arcana-force-1").effects[0].dc,d.context)
   evidence[str(spec[0])+"_force"]={"attributes":d.snapshot.attributes,"dc":dc,"events":cast.get("events",[]),"history":r.advancement_history}
  var d := kernel.derive_character(sorcerer)
  check(int(d.snapshot.attributes.CHA)>int(d.snapshot.attributes.INT),"legal Sorcerer path has distinct primary attribute")
  var druid := prep(build("druid",20),"druid-wildheart-mantle")
  var transformed := use(druid,sorcerer,"druid-wildheart-mantle")
  check(transformed.ok,"real v27 Druid spell transforms the actual Archmage")
  if transformed.ok:
   var cast := use_at_save(transformed.target,fixtures.fighter,"high-arcana-force-1",1)
   evidence.transformed_high_arcana={"accepted":cast.ok,"form":RulesEntities.form(transformed.target,source),"errors":cast.get("errors",[])}
   check(cast.ok,"reproduced27: untyped high arcana still executes through casting-suppressed body")
 var caster := select(build("duskblade",3),"duskblade-searing-grasp");caster.equipment=["bow","mail"]
 var b := encounter(caster);var engine := TacticalAuras.new(caster)
 check(engine.validate(b).is_empty(),"legal bow-equipped Duskblade diagnostic battle")
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 ui.engine=engine;ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode="channel-duskblade-searing-grasp";ui.refresh()
 var wrapper: String="channel-duskblade-searing-grasp"
 check(ui.action_buttons.has(wrapper),"actual selected channel appears in production controls")
 var rejected := engine.command(b,order(b,wrapper))
 if ui.action_buttons.has(wrapper):
  evidence.channel_bow_ui={"button_enabled":not ui.action_buttons[wrapper].disabled,"target_eligible":engine.eligible(b,b.units.a,b.units["bandit-blade"],wrapper),"command_accepted":rejected.ok}
  check(ui.action_buttons[wrapper].disabled and not rejected.ok,"corrected production UI disables bow channel; pinned27 command semantics still reject")
 var melee := select(build("duskblade",3),"duskblade-searing-grasp")
 var ready := encounter(melee);ui.engine=TacticalAuras.new(melee)
 var spent := ui.engine.command(ready,order(ready,wrapper))
 check(spent.ok,"real channel consumes the main action for targeting diagnostic")
 if spent.ok:
  ui.state.first_adventure.battle=spent.battle;ui.mode=wrapper;ui.refresh()
  var stale: bool=ui.tiles[str(spent.battle.units["bandit-blade"].position)].target_tile
  evidence.spent_channel_highlight={"main":spent.battle.budget.main,"button_disabled":ui.action_buttons[wrapper].disabled,"target_highlighted":stale}
  check(stale and ui.action_buttons[wrapper].disabled,"reproduced presentation mismatch: unavailable channel still highlights target after actual action")
 ui.queue_free()
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"scope":"Pinned27 baseline defects and historical display repair only; no career readiness promotion.","evidence":evidence}),"  "))
 print("HYBRID_PROBE ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
func archmage(cls: String) -> Dictionary:
 var r := career_fixture(cls,13,["spell-focus","greater-spell-focus"])
 if r.is_empty():return {}
 if cls=="sorcerer":r=prep(r,"sorcerer-tier7-tempest")
 var offered := kernel.available_advancement(r)
 check(offered.get("classes",{}).get("archmage",{}).get("ok",false),"actual permanent Archmage qualification "+cls+JSON.stringify(offered))
 var choice := kernel.suggested_choice(r,"archmage")
 if not choice.ok:check(false,"qualified Archmage suggestion "+cls);return {}
 choice.choice.specialisations["archmage-casting"]=cls
 var advanced := kernel.preview_advancement(r,choice.choice)
 check(advanced.ok,"manual legal prestige choice "+cls+JSON.stringify(advanced.get("errors",[])))
 return advanced.candidate if advanced.ok else {}
func test_historical_projection() -> void:
 var file := "res://tests/hybrid_acceptance/historical-render-fixtures.json"
 var archived: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(file));var capture := Capture.new()
 capture.state={"mechanics":{"rules_ref":source.rules_ref()}}
 var rows := {}
 for key in archived.records:
  var original: Dictionary=archived.records[key];var before := RulesJson.digest(original)
  var historical := RulesCharacter.new(RulesRecords.registry(original)).derive_character(original)
  check(historical.ok and historical.snapshot.snapshot_hash==archived.hashes[key] and before==archived.record_hashes[key],"actual archived18 exact original hashes "+key)
  var rendered := capture.render_identity(original,"render:"+key)
  check(not rendered.is_empty(),"actual production capture helper projects "+key)
  if rendered.is_empty():continue
  var d := kernel.derive_character(rendered)
  check(d.ok and RulesJson.digest(original)==before,"valid current projection leaves original pin/history/resources unchanged "+key)
  var added: Array=[]
  for pool in rendered.runtime.resources:
   if original.runtime.resources.has(pool):check(rendered.runtime.resources[pool]==original.runtime.resources[pool],"no existing resource refilled "+pool)
   else:
    added.append(pool)
    check(rendered.runtime.resources[pool]==0 and d.snapshot.resource_capacities[pool]==0 and source.definition("resources",pool).has("prepared_ability"),"only empty, unselected new prepared pools "+pool)
  rows[key]={"added_zero_pools":added,"original_hash":before,"projected_hash":RulesJson.digest(rendered),"projected_snapshot":d.snapshot.snapshot_hash}
 check(capture.failures==0,"capture helper retains every validation assertion")
 evidence.historical_projection=rows;capture.free()
