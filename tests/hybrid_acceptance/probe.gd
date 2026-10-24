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
 test_late_ward_equivalence()
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
 var spent: Dictionary=ui.engine.command(ready,order(ready,wrapper))
 check(spent.ok,"real channel consumes the main action for targeting diagnostic")
 if spent.ok:
  ui.state.first_adventure.battle=spent.battle;ui.mode=wrapper;ui.refresh()
  var stale: bool=ui.tiles[str(spent.battle.units["bandit-blade"].position)].target_tile
  evidence.spent_channel_highlight={"main":spent.battle.budget.main,"button_disabled":ui.action_buttons[wrapper].disabled,"target_highlighted":stale}
  check(not stale and ui.action_buttons[wrapper].disabled,"corrected presentation: unavailable channel has no target highlight after actual action")
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
func test_late_ward_equivalence() -> void:
 # Pinned27 reproducer: all three advertised ward choices have identical DSL
 # and outcomes, even on a living ally affected by real supported debuffs.
 var r := career_fixture("wizard",13,["spell-focus","greater-spell-focus"])
 for i in 5:
  var suggested := kernel.suggested_choice(r,"archmage")
  for key in suggested.choice.specialisations:
   if str(key).begins_with("high-arcana-"):suggested.choice.specialisations[key]="ward"
  if i==0:suggested.choice.specialisations["archmage-casting"]="wizard"
  var advanced := kernel.preview_advancement(r,suggested.choice);check(advanced.ok,"lawful old five-level Ward path")
  if not advanced.ok:return
  r=advanced.candidate
 r.runtime=RulesEffects.new(source).refresh_resources(r.runtime,kernel.derive_character(r).snapshot.resource_capacities,"eligible_rest").runtime
 var target := build("fighter",7);var attacker := build("duskblade",17)
 attacker.choices.prepared_abilities=["duskblade-binding-edge","duskblade-sapping-touch"]
 attacker.runtime.resources=kernel._replay(attacker).context.capacities.duplicate()
 var tied := use_at_save(attacker,target,"duskblade-binding-edge",1)
 check(tied.ok,"real binding effect creates the Ward counterplay fixture")
 if not tied.ok:return
 var weak := use_at_save(tied.actor,tied.target,"duskblade-sapping-touch",1)
 check(weak.ok,"real weakening effect creates the Ward counterplay fixture")
 if not weak.ok:return
 check(weak.target.runtime.statuses.any(func(v: Dictionary):return v.id=="arcane-tether") and weak.target.runtime.statuses.any(func(v: Dictionary):return v.id=="weakened"),"actual supported debuffs landed; no invented statuses")
 var results := [];var definitions := []
 for i in [1,3,5]:
  var id: String="high-arcana-ward-"+str(i);var out := use(r,weak.target,id)
  check(out.ok,"old Ward choice executes "+id)
  if not out.ok:return
  results.append(out.target.runtime);definitions.append(source.definition("abilities",id).effects)
 check(definitions[0]==definitions[1] and definitions[1]==definitions[2] and results[0]==results[1] and results[1]==results[2],"reproduced27: later Ward choices provide identical effects, not distinct advanced support")
 evidence.duplicate_wards={"actual_outcomes_equal":true,"effect_bodies_equal":true,"target_debuffs":weak.target.runtime.statuses,"powers":["high-arcana-ward-1","high-arcana-ward-3","high-arcana-ward-5"]}
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
