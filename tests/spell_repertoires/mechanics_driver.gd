extends "res://tests/character_wave_five/mechanics_driver.gd"
## Upper-tier legal development histories, explicitly not earned level20 campaigns.
var saved_records := {}
var saved_battle := {}
var traces := {}
func run() -> void:
 base=OS.get_environment("GAME130_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v17.json")
 check(loaded.ok,"v17 exact schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:complete();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME130_RESTART")=="1":
  var saved := WorldOriginLore.read_json(base.path_join("saved.json"))
  for id in saved.records:
   var record: Dictionary=saved.records[id];var s := kernel.derive_character(record)
   check(s.ok and s.snapshot.snapshot_hash==saved.hashes[id],"exact snapshot process restart "+id)
   check(RulesJson.digest(record)==saved.record_hashes[id],"full history/preparation/resources/statuses/equipment exact restart "+id)
  var engine := TacticalAuras.new(saved.battle.units.a.record)
  check(engine.validate(saved.battle).is_empty(),"cold tactical battle exact validation")
  var after := engine.command(saved.battle,{"actor_id":"a","revision":saved.battle.revision,"kind":"end"})
  check(after.ok and after.battle.state_hash==saved.after_end_hash,"cold next command log/RNG/state identical")
  complete(true);return
 fixtures.fighter=build("fighter",20)
 fixtures.save_target=build("fighter",7)
 for cls in ["wizard","cleric"]:
  fixtures[cls]=build(cls,20)
  check(not fixtures[cls].is_empty(),"lawful full class progression "+cls)
 if failures:complete();return
 for id in source.ids("abilities"):
  var spell := source.definition("abilities",id)
  if spell.get("provenance",{}).get("revision")!="game130-upper-tier-repertoires":continue
  test_spell(spell)
 test_control();test_suppression();test_dispel();test_support();test_recovery();test_prism();test_hybrid();test_spellbook()
 var hashes := {};var record_hashes := {}
 for id in saved_records:
  var s := kernel.derive_character(saved_records[id]);check(s.ok,"persist lawful advanced fixture "+id)
  if s.ok:hashes[id]=s.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(saved_records[id])
 var engine := TacticalAuras.new(saved_battle.units.a.record)
 var after := engine.command(saved_battle,{"actor_id":"a","revision":saved_battle.revision,"kind":"end"})
 check(after.ok,"persist real follow-up command")
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":saved_records,"hashes":hashes,"record_hashes":record_hashes,"battle":saved_battle,"after_end_hash":after.get("battle",{}).get("state_hash","")})))
 FileAccess.open(base.path_join("traces.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(traces),"  "))
 complete()
func complete(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false,"new_spells":10,"source":"RulesCharacter/RulesEffects/TacticalAuras"}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME130 ",JSON.stringify(proof))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
func prepared(record: Dictionary,id: String,copies := 1) -> Dictionary:
 var r: Dictionary=record.duplicate(true);r.choices.prepared_abilities=[id];r.choices.spell_preparations={id:copies}
 r.runtime.resources=kernel._replay(r).get("context",{}).get("capacities",{}).duplicate()
 return r
func cast(actor: Dictionary,target: Dictionary,id: String,seed_value := "game130") -> Dictionary:
 return RulesEffects.new(source).use_ability(actor,target,id,{"move":1,"main":1,"reaction":1},RulesRng.initial(seed_value))
func save_seed(spell: Dictionary,success: bool,target: Dictionary) -> String:
 var snapshot: Dictionary=kernel.derive_character(target).snapshot
 var first: Dictionary=spell.effects.filter(func(e: Dictionary):return e.op=="save")[0]
 var actor: Dictionary=prepared(fixtures[spell.casting_class],spell.id)
 var context: Dictionary=kernel.derive_character(actor).context
 var dc: int=RulesExpressions.evaluate_formula(first.dc,context).value
 for n in 200:
  var seed_value := "game130-save-"+str(n)
  if RulesRng.saving_throw(snapshot.stats[first.save],dc,RulesRng.initial(seed_value)).success==success:return seed_value
 check(false,"test witnesses both numerical save outcomes "+spell.id);return "missing"
func test_spell(spell: Dictionary) -> void:
 var actor := prepared(fixtures[spell.casting_class],spell.id)
 var target: Dictionary=fixtures.save_target.duplicate(true);target.runtime.hp=maxi(1,int(kernel.derive_character(target).snapshot.stats.HP)-30)
 var before := RulesJson.digest([actor,target]);var outcome := cast(actor,target,spell.id)
 check(outcome.ok,"selected spell executes "+spell.id+JSON.stringify(outcome.get("errors",[])))
 if not outcome.ok:return
 check(before==RulesJson.digest([actor,target]),"pure input record/RNG invariant "+spell.id)
 check(RulesJson.digest(outcome)==RulesJson.digest(cast(JSON.parse_string(JSON.stringify(actor)),JSON.parse_string(JSON.stringify(target)),spell.id)),"exact deterministic cast replay "+spell.id)
 check(outcome.budget.main==0 and outcome.budget.move==1,"one main action only "+spell.id)
 for pool in spell.cost.resources:check(int(outcome.actor.runtime.resources[pool])==int(actor.runtime.resources[pool])-1,"one matching slot/copy spent "+pool)
 check(not cast(outcome.actor,target,spell.id).ok,"prepared-copy exhaustion rejected "+spell.id)
 var empty_slot: Dictionary=actor.duplicate(true)
 empty_slot.runtime.resources[spell.casting_class+"-slots-"+str(spell.spell_tier)]=0
 check(not cast(empty_slot,target,spell.id).ok,"shared tier-slot exhaustion cannot be bypassed by prepared copies "+spell.id)
 check(not RulesEffects.new(source).use_ability(actor,target,spell.id,{"move":1,"main":0,"reaction":1},RulesRng.initial("no-action")).ok,"spent main action rejects cast "+spell.id)
 var unselected: Dictionary=actor.duplicate(true);unselected.choices.prepared_abilities=[];unselected.choices.spell_preparations={};unselected.runtime.resources=kernel._replay(unselected).context.capacities.duplicate()
 check(not cast(unselected,target,spell.id).ok,"unprepared spell rejected "+spell.id)
 var effects := RulesEffects.new(source)
 var rest := effects.refresh_resources(outcome.actor.runtime,kernel.derive_character(outcome.actor).snapshot.resource_capacities,"eligible_rest")
 var rested: Dictionary=outcome.actor.duplicate(true);rested.runtime=rest.runtime
 check(cast(rested,target,spell.id).ok,"eligible rest recovers both slot and prepared copy "+spell.id)
 var encounter_refresh := effects.refresh_resources(outcome.actor.runtime,kernel.derive_character(outcome.actor).snapshot.resource_capacities,"encounter")
 check(encounter_refresh.runtime.resources==outcome.actor.runtime.resources,"encounter cannot refill daily spells "+spell.id)
 var battle := encounter(actor);var engine := TacticalAuras.new(actor)
 var target_id: String="bandit-blade" if spell.targeting.kind=="creature" else "b"
 battle.units.b.position=[2,2];battle.units.c.position=[1,2]
 battle=engine.seal(battle)
 var command := {"actor_id":"a","revision":battle.revision,"kind":spell.id,"target_id":target_id}
 var tactical := engine.command(battle,command)
 check(tactical.ok,"actual legal tactical command "+spell.id+str(tactical.get("error","")))
 if tactical.ok:
  check(engine.validate(tactical.battle).is_empty(),"valid postcast tactical state "+spell.id)
  traces[spell.id]={"events":outcome.events,"log":tactical.battle.log,"after_hash":tactical.battle.state_hash,"development_fixture":true}
  saved_records[spell.id]=tactical.battle.units.a.record
 check(not engine.eligible(battle,battle.units.a,battle.units["bandit-blade" if target_id=="b" else "b"],spell.id),"wrong-team target rejected "+spell.id)
 battle.units[target_id].position=[7,5];battle=engine.seal(battle)
 check(not engine.command(battle,command).ok,"range/LOS cannot bypass tactical authority "+spell.id)
 if spell.effects.any(func(e: Dictionary):return e.op=="save"):
  for success in [false,true]:
   var result := cast(actor,target,spell.id,save_seed(spell,success,target))
   check(result.ok and result.events.any(func(e: Dictionary):return e.type=="save_resolved" and e.success==success),"real successful/failed saving throw "+spell.id+str(success))
   if result.ok:check(int(result.actor.runtime.resources[spell.casting_class+"-slots-"+str(spell.spell_tier)])==int(actor.runtime.resources[spell.casting_class+"-slots-"+str(spell.spell_tier)])-1,"save never refunds slot")
func test_control() -> void:
 var actor := prepared(fixtures.wizard,"wizard-gravitic-snare");var spell := source.definition("abilities","wizard-gravitic-snare")
 var target: Dictionary=fixtures.save_target.duplicate(true)
 var applied := cast(actor,target,spell.id,save_seed(spell,false,target));check(applied.ok,"control hit")
 if not applied.ok:return
 var engine := TacticalAuras.new(actor);var battle := encounter(actor)
 battle.units["bandit-blade"].record=applied.target;battle=engine.seal(battle)
 check(engine.paths(battle,battle.units["bandit-blade"]).is_empty(),"immobilisation actually removes movement destinations")
 var once := RulesEffects.new(source).expire_statuses(applied.target.runtime,"target_activation_end")
 check(once.runtime.statuses.any(func(s: Dictionary):return s.id=="gravitic-snare"),"two-activation control persists first boundary")
 var twice := RulesEffects.new(source).expire_statuses(once.runtime,"target_activation_end")
 check(not twice.runtime.statuses.any(func(s: Dictionary):return s.id=="gravitic-snare"),"control expires precisely second boundary")
func test_suppression() -> void:
 var actor := prepared(fixtures.wizard,"wizard-dissonant-seal")
 var target := prepared(build("cleric",7),"cleric-freedom-path");target.character_id="silenced-cleric"
 var spell := source.definition("abilities","wizard-dissonant-seal")
 var suppressed := cast(actor,target,spell.id,save_seed(spell,false,target))
 check(suppressed.ok,"real suppression save failure")
 if not suppressed.ok:return
 check(not cast(suppressed.target,suppressed.target,"cleric-freedom-path").ok,"suppressed spell rejected by GAME32 effect authority")
 var guarding := cast(suppressed.target,fixtures.save_target,"attack")
 check(guarding.ok,"suppression permits nonspell action "+JSON.stringify(guarding.get("errors",[])))
 var engine := TacticalAuras.new(target);var battle := encounter(suppressed.target)
 check(not engine.eligible(battle,battle.units.a,battle.units.a,"cleric-freedom-path"),"tactical target highlighting respects suppression")
 saved_records.suppressed=suppressed.target
func test_dispel() -> void:
 var effects := RulesEffects.new(source);var target: Dictionary=fixtures.save_target.duplicate(true)
 var actor := prepared(fixtures.wizard,"wizard-unravel-enchantment")
 target.runtime.statuses=[{"id":"haste","source":"test","remaining":3,"expiry":"global_round_start"},{"id":"weakened","source":"test","remaining":3,"expiry":"global_round_start"}]
 var spell := source.definition("abilities","wizard-unravel-enchantment")
 var removed := cast(actor,target,spell.id,save_seed(spell,false,target))
 check(removed.ok and not removed.target.runtime.statuses.any(func(s: Dictionary):return s.id=="haste") and removed.target.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened"),"dispel strips listed boons but never cleanses hostile afflictions")
 var resisted := cast(actor,target,spell.id,save_seed(spell,true,target))
 check(resisted.ok and resisted.target.runtime.statuses==target.runtime.statuses,"Will save preserves boons")
func test_support() -> void:
 var target: Dictionary=fixtures.fighter.duplicate(true)
 target.runtime.statuses=[{"id":"gravitic-snare","source":"test","remaining":2,"expiry":"target_activation_end"}]
 var liberated := cast(prepared(fixtures.cleric,"cleric-freedom-path"),target,"cleric-freedom-path")
 check(liberated.ok and not kernel.derive_character(liberated.target).snapshot.capabilities.immobile,"freedom removes actual immobilisation")
 if liberated.ok:
  var snare := source.definition("abilities","wizard-gravitic-snare")
  var immune := cast(prepared(fixtures.wizard,snare.id),liberated.target,snare.id,save_seed(snare,false,liberated.target))
  check(immune.ok and immune.events.any(func(e: Dictionary):return e.type=="status_resisted") and not kernel.derive_character(immune.target).snapshot.capabilities.immobile,"freedom prevents actual reapplication")
 target.runtime.statuses=[{"id":"dissonant-seal","source":"test","remaining":2,"expiry":"target_activation_end"},{"id":"weakened","source":"test","remaining":3,"expiry":"global_round_start"}];target.runtime.hp=5
 var renewal := cast(prepared(fixtures.cleric,"cleric-purifying-renewal"),target,"cleric-purifying-renewal")
 check(renewal.ok and renewal.target.runtime.hp>5 and renewal.target.runtime.statuses.is_empty(),"renewal heals and cleanses without resource restoration")
 var actor := prepared(fixtures.cleric,"cleric-elemental-covenant");var battle := encounter(actor);var engine := TacticalAuras.new(actor)
 battle.units.b.position=[2,2];battle.units.c.position=[3,2];battle=engine.seal(battle)
 var applied := engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":"cleric-elemental-covenant","target_id":"b"})
 check(applied.ok,"area elemental covenant command")
 if applied.ok:
  for id in ["b","c"]:check(engine.characters.derive_character(applied.battle.units[id].record).snapshot.capabilities.resistances.fire==8,"same-team area applied once "+id)
  check(not engine.characters.derive_character(applied.battle.units["bandit-blade"].record).snapshot.capabilities.resistances.has("fire"),"enemy excluded from allied area")
 actor=prepared(fixtures.cleric,"cleric-battle-litany");battle=encounter(actor);engine=TacticalAuras.new(actor)
 battle.units.b.position=[1,2];battle=engine.seal(battle)
 var before: int=engine.stats(battle.units.a).damage
 applied=engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":"cleric-battle-litany","target_id":"b"})
 check(applied.ok and engine.stats(applied.battle.units.a).damage==before+2,"maintained litany projects real allied weapon damage")
 if applied.ok:
  applied.battle.units.a.position=[7,5];var moved := engine.seal(applied.battle)
  check(engine.stats(moved.units.a).damage==before,"leaving aura removes support immediately")
func test_recovery() -> void:
 var actor := prepared(fixtures.cleric,"cleric-return-to-breath");var engine := TacticalAuras.new(actor);var battle := encounter(actor)
 battle.units.b.record.runtime.hp=0;battle.units.b.position=[1,2];battle=engine.seal(battle)
 var order_before: Array=battle.order.duplicate();var rng_before: Dictionary=battle.rng.duplicate()
 var command := {"actor_id":"a","revision":battle.revision,"kind":"cleric-return-to-breath","target_id":"b"}
 var recovered := engine.command(battle,command)
 check(recovered.ok,"downed ally recovery command legal")
 if not recovered.ok:return
 check(engine.alive(recovered.battle.units.b) and recovered.battle.units.b.record.runtime.hp>0,"downed ally actually recovers health")
 check(recovered.battle.order==order_before and recovered.battle.cursor==battle.cursor and recovered.battle.budget.main==0 and recovered.battle.rng==rng_before,"recovery grants no extra turn or RNG")
 battle.units.c.position=battle.units.b.position;check(not engine.eligible(battle,battle.units.a,battle.units.b,command.kind),"occupied downed tile cannot revive into collision")
 battle.units.c.position=[3,2];battle.units.b.entity={"active":false};check(not engine.eligible(battle,battle.units.a,battle.units.b,command.kind),"expired creature cannot be restored")
 saved_battle=recovered.battle;saved_records.recovered=recovered.battle.units.b.record
func test_prism() -> void:
 var spell := source.definition("abilities","wizard-prismatic-volley");var actor := prepared(fixtures.wizard,spell.id);var target: Dictionary=fixtures.fighter.duplicate(true)
 target.runtime.statuses=[{"id":"elemental-covenant","source":"test","remaining":3,"expiry":"global_round_start"}]
 var result := cast(actor,target,spell.id)
 check(result.ok,"split-element packet resolves")
 if result.ok:
  check(result.events.filter(func(e: Dictionary):return e.type=="save_resolved").size()==2,"independent Reflex and Fortitude saves")
  check(result.events.filter(func(e: Dictionary):return e.type=="damage_resisted").size()==2,"each element uses actual resistance")
func test_hybrid() -> void:
 var planner: Node=load("res://tests/character_completeness/prestige_driver.gd").new();planner.source=source;planner.kernel=kernel
 var goals: Dictionary=planner.requirements("mystic-theurge",0)
 var record := kernel.create("hybrid",{"STR":8,"DEX":10,"CON":13,"INT":15,"WIS":14,"CHA":12},"heritage-human")
 for cls in ["wizard","wizard","wizard","cleric","cleric","cleric","mystic-theurge","mystic-theurge","mystic-theurge","mystic-theurge","mystic-theurge","wizard","wizard","wizard","wizard","wizard","cleric","cleric","cleric","cleric"]:
  var next: Dictionary=planner.advance(record,cls,goals);check(next.ok,"lawful hybrid advancement "+cls+JSON.stringify(next.get("errors",[])))
  if not next.ok:planner.free();return
  var deliberate: Dictionary=next.candidate.advancement_history.back().duplicate(true);deliberate.erase("level")
  if (record.advancement_history.size()+1)%4==0:
   deliberate.attribute_increase="INT" if record.advancement_history.size()+1<=8 else "WIS"
   var context: Dictionary=kernel._replay(record).context
   var wanted_points: int=maxi(1,int(source.definition("classes",cls).skill_points)+int(floor(float(int(context.attributes.INT)+(1 if deliberate.attribute_increase=="INT" else 0)-10)/2.0)))
   var spent := 0
   for n in deliberate.skill_allocations.values():spent+=int(n)
   for skill in deliberate.skill_allocations.keys().duplicate():
    if spent<=wanted_points:break
    var trim: int=mini(int(deliberate.skill_allocations[skill]),spent-wanted_points)
    deliberate.skill_allocations[skill]-=trim;spent-=trim
    if deliberate.skill_allocations[skill]==0:deliberate.skill_allocations.erase(skill)
   next=kernel.preview_advancement(record,deliberate)
   check(next.ok,"deliberate dual-casting attribute advancement "+JSON.stringify(next.get("errors",[])))
   if not next.ok:planner.free();return
  record=next.candidate
 record.runtime.hp=kernel.derive_character(record).snapshot.stats.HP
 var snapshot: Dictionary=kernel.derive_character(record).snapshot
 check(snapshot.casting_levels.wizard==13 and snapshot.casting_levels.cleric==12,"hybrid progresses both independent casting tracks")
 for id in ["wizard-dissonant-seal","cleric-purifying-renewal"]:
  var chosen := prepared(record,id)
  # A lawful INT/WIS build must meet each individual requirement; no blended casting attribute.
  var valid := kernel.derive_character(chosen)
  if valid.ok:
   var result := cast(chosen,fixtures.fighter,id);check(result.ok,"hybrid actual chosen upper-tier spell "+id+JSON.stringify(result.get("errors",[])))
   if result.ok:saved_records["hybrid:"+id]=result.actor
  else:check(false,"hybrid must reach permanent required ability score "+id+JSON.stringify(valid.errors))
 planner.free()
func test_spellbook() -> void:
 for cls in ["wizard","cleric"]:
  var low := build(cls,7)
  var high: Dictionary=fixtures[cls]
  var spell: String=cls+"-"+("dissonant-seal" if cls=="wizard" else "return-to-breath")
  check(not kernel.derive_character(low).snapshot.abilities.has(spell),"level7 cannot prepare tier7 "+cls)
  check(not kernel.derive_character(prepared(low,spell)).ok,"forged high-tier preparation rejected "+cls)
  var poor := kernel.create("poor:"+cls,{"STR":15,"DEX":14,"CON":13,"INT":10,"WIS":12,"CHA":8},"heritage-human")
  for n in 13:
   var next := kernel.preview_advancement(poor,kernel.suggested_choice(poor,cls).choice)
   check(next.ok,"lawful low-casting-attribute history "+cls)
   if not next.ok:break
   poor=next.candidate
  check(not cast(prepared(poor,spell),fixtures.fighter,spell).ok,"actual attribute requirement enforced "+cls)
  var ui := SpellbookEditor.new();ui.setup(high)
  check(ui.controls.has(spell),"actual production spellbook exposes new spell "+cls)
  if ui.controls.has(spell):
   ui.controls[spell].value=1
   check(ui.selection().has(spell) and ui.preparations().get(spell)==1,"visible production preparation control selectable "+cls)
  ui.free()
