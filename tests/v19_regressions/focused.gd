extends "res://tests/class_signatures/mechanics_driver.gd"
## Focused historical reproductions. These are development fixtures, not earned XP.
func run() -> void:
 base=OS.get_environment("GAME144_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v19.json").ok,"load unchanged v19")
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME144_RESTART")=="1":
  var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
  for name in saved.records:
   var record: Dictionary=saved.records[name]
   check(RulesCharacter.new(RulesRecords.registry(record)).derive_character(record).ok,"cold original/exact nested pin validates "+name)
   check(RulesJson.digest(record)==saved.hashes[name],"cold complete owner/companion/history/resources exact "+name)
  var engine := TacticalAuras.new(saved.battle.units.a.record)
  check(engine.validate(saved.battle).is_empty(),"cold actual authority battle validates")
  var next := engine.command(saved.battle,saved.command)
  check(next.ok and next.battle.state_hash==saved.next_hash,"cold next command/log/resources/RNG exact")
  finish_repair(true);return
 fixtures.fighter=build("fighter",20)
 var battle := encounter(build("warblade",1))
 battle.rng=attack_seed(20)
 var engine := TacticalAuras.new(battle.units.a.record);battle=engine.seal(battle)
 var before := RulesJson.digest(battle)
 var command := order(battle,"warblade-technique-1")
 var stale := TacticalCombat.new(battle.units.a.record).command(battle,command)
 var correct := engine.command(battle,command)
 check(stale.ok and correct.ok,"same lawful command accepted by both historical and production adapters")
 if not stale.ok or not correct.ok:finish_repair();return
 var fields: Array=[]
 for key in correct.battle:
  if RulesJson.canonical(correct.battle[key])!=RulesJson.canonical(stale.battle[key]):fields.append(key)
 check(not fields.is_empty(),"reproduce stale catalogue predictor without weakening exact state equality")
 var replay := TacticalAuras.new(battle.units.a.record).command(battle,command)
 check(replay.ok and replay.battle.state_hash==correct.battle.state_hash,"production predictor equals independently constructed campaign adapter")
 check(RulesJson.digest(battle)==before,"predictions never mutate source battle")
 var archived: Dictionary=RulesJson.normalize(WorldOriginLore.read_json("res://tests/v19_regressions/fixtures/druid-v18-render.json")).record
 var original_hash := RulesJson.digest(archived)
 var owner: String=archived.character_id
 var pet_id := RulesEntities.identity(owner)
 check(archived.runtime.companions.has(pet_id),"actual archived fixture has original deterministic companion ID")
 check(RulesCharacter.new(RulesRecords.registry(archived)).derive_character(archived).ok,"actual original v18 owner/companion is valid")
 var broken: Dictionary=archived.duplicate(true);broken.rules_ref=source.rules_ref()
 var old_result := kernel.derive_character(broken)
 check(not old_result.ok and old_result.errors.any(func(e: Dictionary):return e.code=="companion.build"),"reproduce mixed v19 owner/v18 companion pin failure, not an identity failure")
 var renderer: Node=load("res://tests/nature_repertoires/capture_driver.gd").new()
 renderer.state={"rules_ref":source.rules_ref()}
 var rendered: Dictionary=renderer.render_identity(archived,owner)
 check(renderer.failures==0 and not rendered.is_empty(),"actual render helper accepts original saved fixture")
 renderer.free()
 check(rendered.character_id==owner and rendered.runtime.companions.keys()==archived.runtime.companions.keys() and rendered.runtime.companions[pet_id].record.character_id==pet_id,"repair uses existing IDs; no replacement owner or creature fabricated")
 var expected: Dictionary=archived.duplicate(true);expected.rules_ref=source.rules_ref();expected.runtime.companions[pet_id].record.rules_ref=source.rules_ref()
 check(rendered==expected,"only owner and nested render pins change; creature history/state/resources unchanged")
 check(kernel.derive_character(rendered).ok,"exact shared owner/companion pin validates")
 check(RulesJson.digest(archived)==original_hash,"original saved v18 fixture remains byte-for-byte unchanged")
 var forged: Dictionary=rendered.duplicate(true);forged.runtime.companions[pet_id].record.character_id="forged-creature"
 check(not kernel.derive_character(forged).ok,"wrong companion identity still rejected")
 forged=rendered.duplicate(true);forged.runtime.companions[pet_id].record.rules_ref=archived.rules_ref
 check(not kernel.derive_character(forged).ok,"mixed nested content pins still rejected")
 var saved_records := RulesJson.string_keys({"original":archived,"rendered":rendered})
 var hashes := {}
 for name in saved_records:hashes[name]=RulesJson.digest(saved_records[name])
 var next_command := {"actor_id":engine.current(correct.battle).id,"revision":correct.battle.revision,"kind":"end"}
 var next := engine.command(correct.battle,next_command);check(next.ok,"predict valid next command before restart")
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":saved_records,"hashes":hashes,"battle":correct.battle,"command":next_command,"next_hash":next.get("battle",{}).get("state_hash","")})))
 FileAccess.open(base.path_join("reproduction.json"),FileAccess.WRITE).store_string(JSON.stringify({"command":command,"stale_hash":stale.battle.state_hash,"production_hash":correct.battle.state_hash,"different_fields":fields,"mixed_pin_errors":old_result.errors,"original_owner":owner,"original_companion":pet_id,"original_rules_ref":archived.rules_ref,"render_rules_ref":rendered.rules_ref},"  "))
 finish_repair()
func finish_repair(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME144 ",JSON.stringify(proof));get_tree().quit(1 if failures else 0)
