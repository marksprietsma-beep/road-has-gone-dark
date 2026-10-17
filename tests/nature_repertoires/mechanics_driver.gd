extends "res://tests/spell_repertoires/mechanics_driver.gd"
## Only lawful high-level development fixtures; earned careers live in journey_driver.
func run() -> void:
 base=OS.get_environment("GAME133_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v18.json")
 check(loaded.ok,"v18 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:complete();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME133_RESTART")=="1":
  var saved := RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
  for id in saved.records:
   var s := kernel.derive_character(saved.records[id])
   check(s.ok and s.snapshot.snapshot_hash==saved.hashes[id],"exact cold derived state "+id)
   check(RulesJson.digest(saved.records[id])==saved.record_hashes[id],"exact cold history/known/prepared/creatures/resources/forms "+id)
  var engine := TacticalAuras.new(saved.battle.units.a.record)
  check(engine.validate(saved.battle).is_empty(),"cold battle validates")
  var after := engine.command(saved.battle,{"actor_id":"a","revision":saved.battle.revision,"kind":"end"})
  check(after.ok and after.battle.state_hash==saved.after_end_hash,"cold next command/log/RNG exact")
  complete(true);return
 fixtures.fighter=build("fighter",20);fixtures.save_target=build("fighter",7)
 for cls in ["sorcerer","druid"]:
  fixtures[cls]=build(cls,20)
  check(not fixtures[cls].is_empty(),"legal level20 development fixture "+cls)
 if failures:complete();return
 for id in source.ids("abilities"):
  var spell := source.definition("abilities",id)
  if spell.get("provenance",{}).get("revision")=="game133-sorcerer-druid-repertoires":test_spell(spell)
 test_distinct_effects();test_creatures_and_forms();test_hybrid();test_spellbook();test_area_and_constraints();test_legacy()
 var hashes := {};var record_hashes := {}
 for id in saved_records:
  var d := kernel.derive_character(saved_records[id]);check(d.ok,"persist valid advanced fixture "+id)
  if d.ok:hashes[id]=d.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(saved_records[id])
 var engine := TacticalAuras.new(saved_battle.units.a.record)
 var after := engine.command(saved_battle,{"actor_id":"a","revision":saved_battle.revision,"kind":"end"})
 check(after.ok,"predict next saved command")
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":saved_records,"hashes":hashes,"record_hashes":record_hashes,"battle":saved_battle,"after_end_hash":after.get("battle",{}).get("state_hash","")})))
 FileAccess.open(base.path_join("traces.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(traces),"  "))
 complete()
func complete(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false,"new_spells":10,"source":"RulesCharacter/RulesEffects/TacticalAuras"}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME133 ",JSON.stringify(proof))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
func prepared(record: Dictionary,id: String,copies := 1) -> Dictionary:
 var r: Dictionary=record.duplicate(true);r.choices.prepared_abilities=[id];r.choices.spell_preparations={}
 if source.definition("abilities",id).tags.has("prepared"):r.choices.spell_preparations[id]=copies
 r.runtime.resources=kernel._replay(r).get("context",{}).get("capacities",{}).duplicate()
 return r
func test_spell(spell: Dictionary) -> void:
 var actor := prepared(fixtures[spell.casting_class],spell.id)
 var target: Dictionary=fixtures.save_target.duplicate(true);target.runtime.hp=maxi(1,int(target.runtime.hp)-30)
 # Put a real removable ward on the dispel target; test saves below too.
 if spell.id=="sorcerer-sundering-chord":target.runtime.statuses=[{"id":"haste","source":"fixture","remaining":3,"expiry":"global_round_start"}]
 var seed_value := save_seed(spell,false,target) if spell.effects.any(func(e: Dictionary):return e.op=="save") else "game133"
 var before := RulesJson.digest([actor,target]);var outcome := cast(actor,target,spell.id,seed_value)
 check(outcome.ok,"selected spell executes "+spell.id+JSON.stringify(outcome.get("errors",[])))
 if not outcome.ok:return
 check(before==RulesJson.digest([actor,target]),"source immutable "+spell.id)
 check(RulesJson.digest(outcome)==RulesJson.digest(cast(JSON.parse_string(JSON.stringify(actor)),JSON.parse_string(JSON.stringify(target)),spell.id,seed_value)),"deterministic exact replay "+spell.id)
 check(outcome.budget.main==0 and outcome.budget.move==1,"one main action "+spell.id)
 check(RulesJson.digest(outcome.target.runtime)!=RulesJson.digest(target.runtime),"observable real target change "+spell.id)
 for pool in spell.cost.resources:check(int(outcome.actor.runtime.resources[pool])==int(actor.runtime.resources[pool])-1,"one slot/copy spent "+pool)
 if spell.casting_class=="druid":check(not cast(outcome.actor,target,spell.id).ok,"prepared copy exhausted "+spell.id)
 else:
  check(cast(outcome.actor,target,spell.id).ok,"known spontaneous spell reusable with remaining slot "+spell.id)
  check(outcome.actor.choices==actor.choices,"casting retains permanent knowledge "+spell.id)
 var empty: Dictionary=actor.duplicate(true);empty.runtime.resources[spell.casting_class+"-slots-"+str(spell.spell_tier)]=0
 check(not cast(empty,target,spell.id).ok,"shared slot exhausted "+spell.id)
 check(not RulesEffects.new(source).use_ability(actor,target,spell.id,{"move":1,"main":0,"reaction":1},RulesRng.initial("spent")).ok,"main action exhausted "+spell.id)
 var unknown: Dictionary=actor.duplicate(true);unknown.choices.prepared_abilities=[];unknown.choices.spell_preparations={};unknown.runtime.resources=kernel._replay(unknown).context.capacities.duplicate()
 check(not cast(unknown,target,spell.id).ok,"unknown/unprepared rejected "+spell.id)
 var capacities: Dictionary=kernel.derive_character(outcome.actor).snapshot.resource_capacities
 var restored := RulesEffects.new(source).refresh_resources(outcome.actor.runtime,capacities,"eligible_rest")
 var rested: Dictionary=outcome.actor.duplicate(true);rested.runtime=restored.runtime
 check(cast(rested,target,spell.id).ok,"eligible rest restores slots and prepared copies "+spell.id)
 var encounter_rest := RulesEffects.new(source).refresh_resources(outcome.actor.runtime,capacities,"encounter")
 check(encounter_rest.runtime.resources==outcome.actor.runtime.resources,"encounter grants no daily resources "+spell.id)
 var battle := encounter(actor);var engine := TacticalAuras.new(actor)
 battle.units.b.position=[2,2];battle.units.c.position=[1,2];battle=engine.seal(battle)
 var target_id: String="bandit-blade" if spell.targeting.kind=="creature" else "b"
 var command := {"actor_id":"a","revision":battle.revision,"kind":spell.id,"target_id":target_id}
 var tactical := engine.command(battle,command)
 check(tactical.ok,"real tactical command "+spell.id+str(tactical.get("error","")))
 if tactical.ok:
  check(engine.validate(tactical.battle).is_empty(),"postcast tactical validation "+spell.id)
  traces[spell.id]={"events":outcome.events,"log":tactical.battle.log,"after_hash":tactical.battle.state_hash,"development_fixture":true}
  saved_records[spell.id]=tactical.battle.units.a.record
  if spell.id=="druid-packward-canopy":saved_battle=tactical.battle
 check(not engine.eligible(battle,battle.units.a,battle.units["b" if target_id=="bandit-blade" else "bandit-blade"],spell.id),"wrong team rejected "+spell.id)
 battle.units[target_id].position=[7,5];battle=engine.seal(battle)
 check(not engine.command(battle,command).ok,"range/LOS rejects "+spell.id)
 if spell.effects.any(func(e: Dictionary):return e.op=="save"):
  for success in [false,true]:
   var result := cast(actor,target,spell.id,save_seed(spell,success,target))
   check(result.ok and result.events.any(func(e: Dictionary):return e.type=="save_resolved" and e.success==success),"actual numeric save "+spell.id+str(success))
   if result.ok:check(int(result.actor.runtime.resources[spell.casting_class+"-slots-"+str(spell.spell_tier)])==int(actor.runtime.resources[spell.casting_class+"-slots-"+str(spell.spell_tier)])-1,"resistance never refunds slot")
func test_distinct_effects() -> void:
 var target: Dictionary=fixtures.save_target.duplicate(true)
 var crystal := cast(prepared(fixtures.sorcerer,"sorcerer-crystal-reservoir"),target,"sorcerer-crystal-reservoir")
 check(crystal.ok and crystal.target.runtime.temporary_hp==18,"crystal grants actual nonstacking buffer")
 if crystal.ok:
  var again := cast(crystal.actor,crystal.target,"sorcerer-crystal-reservoir")
  check(again.ok and again.target.runtime.temporary_hp==18,"temporary HP cannot stack")
 var snare := source.definition("abilities","druid-bramble-tether");var rooted := cast(prepared(fixtures.druid,snare.id),target,snare.id,save_seed(snare,false,target))
 if rooted.ok:
  var engine := TacticalAuras.new(fixtures.druid);var b := encounter(fixtures.druid);b.units["bandit-blade"].record=rooted.target;b=engine.seal(b)
  check(engine.paths(b,b.units["bandit-blade"]).is_empty(),"roots remove legal movement")
  var once := RulesEffects.new(source).expire_statuses(rooted.target.runtime,"target_activation_end")
  check(once.runtime.statuses.any(func(s: Dictionary):return s.id=="bramble-tether"),"root survives first activation")
  var twice := RulesEffects.new(source).expire_statuses(once.runtime,"target_activation_end")
  check(twice.runtime.statuses.is_empty(),"root expires second activation")
 var veil := cast(prepared(fixtures.sorcerer,"sorcerer-slipstream-veil"),target,"sorcerer-slipstream-veil")
 check(veil.ok and kernel.derive_character(veil.target).snapshot.capabilities.concealment==50 and kernel.derive_character(veil.target).snapshot.stats.stride==kernel.derive_character(target).snapshot.stats.stride+2,"veil changes movement and weapon counterplay")
 var doubt := source.definition("abilities","sorcerer-crushing-doubt");var shaken := cast(prepared(fixtures.sorcerer,doubt.id),target,doubt.id,save_seed(doubt,false,target))
 check(shaken.ok and kernel.derive_character(shaken.target).snapshot.stats.will==kernel.derive_character(target).snapshot.stats.will-3,"doubt reduces actual later saving throws")
 var dispel := source.definition("abilities","sorcerer-sundering-chord")
 target.runtime.statuses=[{"id":"slipstream-veil","source":"fixture","remaining":2,"expiry":"global_round_start"},{"id":"weakened","source":"fixture","remaining":3,"expiry":"global_round_start"}]
 var stripped := cast(prepared(fixtures.sorcerer,dispel.id),target,dispel.id,save_seed(dispel,false,target))
 check(stripped.ok and not kernel.derive_character(stripped.target).snapshot.capabilities.concealment and stripped.target.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened"),"bounded dispel removes boon, never hostile affliction")
 var resisted := cast(prepared(fixtures.sorcerer,dispel.id),target,dispel.id,save_seed(dispel,true,target))
 check(resisted.ok and resisted.target.runtime.statuses==target.runtime.statuses,"successful Fortitude preserves buffs")
 target=fixtures.save_target.duplicate(true);target.runtime.hp-=20
 var sap := cast(prepared(fixtures.druid,"druid-sap-renewal"),target,"druid-sap-renewal")
 check(sap.ok and sap.target.runtime.hp>target.runtime.hp and sap.target.runtime.temporary_hp==10,"renewal heals wounds and grants separate finite buffer")
 var winter := source.definition("abilities","druid-winters-verdict")
 var frozen := cast(prepared(fixtures.druid,winter.id),target,winter.id,save_seed(winter,false,target))
 var thawed := cast(prepared(fixtures.druid,winter.id),target,winter.id,save_seed(winter,true,target))
 check(frozen.ok and thawed.ok and kernel.derive_character(frozen.target).snapshot.capabilities.immobile and not kernel.derive_character(thawed.target).snapshot.capabilities.immobile,"winter save prevents root but still resolves half damage")
func test_creatures_and_forms() -> void:
 var druid := prepared(fixtures.druid,"druid-packward-canopy")
 var engine := TacticalAuras.new(druid);var battle := encounter(druid)
 var pet_id := RulesEntities.identity("a")
 check(battle.units.has(pet_id),"real persistent Druid companion present")
 if not battle.units.has(pet_id):return
 battle.units[pet_id].position=[0,1];battle=engine.seal(battle)
 var result := engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":"druid-packward-canopy","target_id":pet_id})
 check(result.ok,"canopy targets actual owned companion")
 if result.ok:
  var pet: Dictionary=result.battle.units[pet_id].record
  check(kernel.derive_character(pet).snapshot.capabilities.resistances.get("physical")==5,"companion receives real physical reduction")
  var hit := RulesEffects.new(source).resolve_rules_effect({"op":"damage","amount":{"op":"const","value":10},"damage_type":"physical"},pet.runtime,pet.runtime,{"target_id":pet_id,"target_capabilities":kernel.derive_character(pet).snapshot.capabilities},RulesRng.initial("canopy-hit"))
  check(hit.ok and hit.target.hp==pet.runtime.hp-5,"companion actually takes reduced physical packet "+JSON.stringify(hit.get("errors",[])))
  saved_records.companion_owner=result.battle.units.a.record;saved_battle=result.battle
 # Pre-buff, then use the existing form. It remains spell-suppressed, with original HP.
 druid=prepared(fixtures.druid,"druid-predators-rhythm")
 var buff := cast(druid,druid,"druid-predators-rhythm")
 check(buff.ok,"predator buff self before transformation")
 if not buff.ok:return
 var shape := cast(buff.actor,buff.actor,"wild-shape-leopard")
 # Look up the authored leopard action instead of assuming a renamed alias.
 if not shape.ok:
  for id in kernel.derive_character(buff.actor).snapshot.abilities:
   if source.definition("abilities",id).effects.any(func(e: Dictionary):return e.op=="apply_status" and e.id=="leopard-form"):
    shape=cast(buff.actor,buff.actor,id);break
 check(shape.ok,"existing leopard transformation executes after buff "+JSON.stringify(shape.get("errors",[])))
 if shape.ok:
  var s: Dictionary=kernel.derive_character(shape.actor).snapshot
  check(not s.body_form.is_empty() and s.stats.reach>=2,"natural-form attack gains actual reach")
  check(s.abilities.all(func(id: String):return not source.definition("abilities",id).tags.has("spell")),"form still suppresses spells; no implicit Natural Spell bypass")
  check(shape.actor.runtime.hp==buff.actor.runtime.hp,"transformation retains authoritative health")
  saved_records.buffed_form=shape.actor
func test_hybrid() -> void:
 var planner: Node=load("res://tests/character_completeness/prestige_driver.gd").new();planner.source=source;planner.kernel=kernel
 var goals: Dictionary=planner.requirements("mystic-theurge",0)
 var record := kernel.create("hybrid",{"STR":8,"DEX":10,"CON":12,"INT":13,"WIS":14,"CHA":15},"heritage-human")
 var route: Array=[]
 for pair in [["sorcerer",4],["druid",3],["mystic-theurge",5],["sorcerer",4],["druid",4]]:
  for n in pair[1]:route.append(pair[0])
 for cls in route:
  var next: Dictionary=planner.advance(record,cls,goals)
  check(next.ok,"legal Sorcerer/Druid/Theurge advancement "+cls+JSON.stringify(next.get("errors",[])))
  if not next.ok:planner.free();return
  var deliberate: Dictionary=next.candidate.advancement_history.back().duplicate(true);deliberate.erase("level")
  if (record.advancement_history.size()+1)%4==0:
   deliberate.attribute_increase="CHA" if record.advancement_history.size()+1<=8 else "WIS"
   next=kernel.preview_advancement(record,deliberate)
   check(next.ok,"deliberate CHA/WIS increase "+JSON.stringify(next.get("errors",[])))
   if not next.ok:planner.free();return
  record=next.candidate
 var s: Dictionary=kernel.derive_character(record).snapshot
 check(s.casting_levels.sorcerer==13 and s.casting_levels.druid==12,"hybrid keeps separate effective casting tracks")
 for id in ["sorcerer-starfall-rupture","druid-packward-canopy"]:
  var chosen := prepared(record,id);var result := cast(chosen,fixtures.fighter,id)
  check(result.ok,"hybrid casts using own attribute/slot mode "+id+JSON.stringify(result.get("errors",[])))
  if result.ok:saved_records["hybrid:"+id]=result.actor
 planner.free()
func test_spellbook() -> void:
 for cls in ["sorcerer","druid"]:
  var low := build(cls,1)
  var id: String="sorcerer-starfall-rupture" if cls=="sorcerer" else "druid-winters-verdict"
  check(not kernel.derive_character(prepared(low,id)).ok,"forged high-tier selection rejected "+cls)
  var ui := SpellbookEditor.new();ui.setup(fixtures[cls])
  check(ui.controls.has(id),"real spellbook lists new choice "+cls)
  if cls=="sorcerer":ui.controls[id].button_pressed=true
  else:ui.controls[id].value=1
  check(ui.selection().has(id),"actual checkbox/copy control selects "+cls)
  ui.repertoire_search.text="tier 7";ui.repertoire_search.text_changed.emit("tier 7")
  var visible_spells := 0
  for child in ui.get_children():
   if child.has_meta("spell_search"):
    check(child.visible==("tier 7"in str(child.get_meta("spell_search"))),"spell search visibility "+cls)
    if child.visible:visible_spells+=1
  check(visible_spells>=3,"expanded tier7 discoverable "+cls)
  ui.free()
  var poor := kernel.create("poor:"+cls,{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8},"heritage-human")
  for n in 13:
   var next := kernel.preview_advancement(poor,kernel.suggested_choice(poor,cls).choice)
   check(next.ok,"lawful poor casting score history "+cls)
   if not next.ok:break
   poor=next.candidate
  check(not cast(prepared(poor,id),fixtures.fighter,id).ok,"actual high-tier attribute requirement "+cls)
func test_legacy() -> void:
 var old := RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v17.json").ok,"historical v17 loads exact pin")
 var archived := WorldOriginLore.read_json("res://tests/character_completeness/fixtures/prestige-v15-records.json")
 check(archived.has("records"),"archived pinned source fixtures remain installed")
 check(RulesRecords.new_character_registry().rules_ref()==source.rules_ref(),"fresh New Game defaults to v18")

func test_area_and_constraints() -> void:
 for id in ["sorcerer-starfall-rupture","druid-winters-verdict"]:
  var a := source.definition("abilities",id);var actor := prepared(fixtures[a.casting_class],id)
  var engine := TacticalAuras.new(actor);var b := encounter(actor)
  b.units["bandit-bow"].record=fixtures.save_target.duplicate(true);b.units["bandit-bow"].record.character_id="bandit-bow"
  b.units["bandit-bow"].position=[3,1];b.units.b.position=[2,2];b.units.c.position=[1,2]
  b=engine.seal(b)
  var result := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":id,"target_id":"bandit-blade"})
  check(result.ok,"area spell actual command "+id)
  if result.ok:
   for enemy in ["bandit-blade","bandit-bow"]:check(result.battle.units[enemy].record.runtime.hp<b.units[enemy].record.runtime.hp,"area reaches both living enemies "+id+enemy)
   check(result.battle.units.b.record==b.units.b.record,"enemy area never damages adjacent ally "+id)
   for pool in a.cost.resources:check(result.battle.units.a.record.runtime.resources[pool]==b.units.a.record.runtime.resources[pool]-1,"area pays once, not per target "+id)
   var wall := b.duplicate(true);wall.units["bandit-blade"].position=[3,1];wall.units["bandit-bow"].position=[4,2];wall.board.blocked.append([2,1]);wall=engine.seal(wall)
   check(not engine.eligible(wall,wall.units.a,wall.units["bandit-blade"],id),"actual blocked line of sight rejected "+id)
 var known := prepared(fixtures.sorcerer,"sorcerer-crystal-reservoir")
 known.choices.spell_preparations={"sorcerer-crystal-reservoir":1}
 check(not kernel.validate_build(known).ok,"forged prepared copies cannot turn spontaneous spell into prepared mode")
 var over := prepared(fixtures.druid,"druid-packward-canopy",100)
 check(not kernel.validate_build(over).ok,"preparation count cannot exceed tier-slot capacity")
 var low := build("sorcerer",7)
 check(not kernel.derive_character(low).snapshot.abilities.has("sorcerer-crystal-reservoir"),"Sorcerer7 does not falsely own tier4")
 check(kernel.derive_character(build("druid",7)).snapshot.abilities.has("druid-bramble-tether"),"Druid7 genuinely owns tier4")
 var poor := kernel.create("low-score",{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8},"heritage-human")
 for n in 13:
  var next := kernel.preview_advancement(poor,kernel.suggested_choice(poor,"sorcerer").choice)
  if not next.ok:check(false,"poor-score history valid");return
  poor=next.candidate
 var ui := SpellbookEditor.new();ui.setup(poor)
 check(ui.controls.has("sorcerer-starfall-rupture") and ui.controls["sorcerer-starfall-rupture"].disabled,"actual spontaneous control explains unavailable permanent attribute")
 ui.free()
