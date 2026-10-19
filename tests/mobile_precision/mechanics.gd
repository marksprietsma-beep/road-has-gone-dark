extends "res://tests/class_signatures/mechanics_driver.gd"
## Lawful high-level fixtures; no campaign XP injected. Actual native Windows only.
func run() -> void:
 base=OS.get_environment("GAME146_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v20.json")
 check(loaded.ok,"v20 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_mobile();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME146_RESTART")=="1":
  var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
  for id in saved.records:
   check(kernel.derive_character(saved.records[id]).snapshot.snapshot_hash==saved.hashes[id],"cold exact character "+id)
  for id in saved.battles:
   var engine := TacticalAuras.new(saved.battles[id].units.a.record)
   check(engine.validate(saved.battles[id]).is_empty(),"cold valid battle "+id)
   var next := engine.command(saved.battles[id],saved.next[id])
   check(next.ok and next.battle.state_hash==saved.after[id],"cold exact next command/log/RNG "+id)
  finish_mobile(true);return
 fixtures.fighter=build("fighter",20)
 for cls in ["scout","rogue","swashbuckler","knight"]:
  for at in [1,8,20]:
   var r := build(cls,at);check(not r.is_empty(),"lawful career "+cls+str(at))
   if not r.is_empty():records[cls+str(at)]=r
 if failures:finish_mobile();return
 test_fencing();test_openings();test_scout_movement();test_knight_protection();test_pin_isolation()
 var hashes := {};var after := {};var next := {}
 for id in records:
  records[id]=RulesJson.string_keys(records[id]);var d := kernel.derive_character(records[id])
  check(d.ok,"saved lawful record "+id)
  if d.ok:hashes[id]=d.snapshot.snapshot_hash
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var result := engine.command(battles[id],next[id]);check(result.ok,"next command prediction "+id)
  if result.ok:after[id]=result.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"battles":battles,"next":next,"after":after})))
 finish_mobile()
func finish_mobile(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"campaign_xp_injected":false}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME146 ",JSON.stringify(proof));get_tree().quit(1 if failures else 0)
func test_fencing() -> void:
 var r: Dictionary=records.swashbuckler8.duplicate(true);r.equipment=["shortblade","leathers"]
 var engine := TacticalAuras.new(r)
 check(RulesMartial.fencing_equipment(r,source),"light blade fencing legal")
 for hit in [false,true]:
  var b := encounter(r);b.rng=attack_seed(19 if hit else 1);b=engine.seal(b)
  var old := RulesJson.digest(b)
  var result := execute(engine,b,"swashbuckler-technique-4","bandit-blade")
  check(result.ok,"legal flourish hit/miss "+str(hit))
  check(RulesJson.digest(b)==old,"command is pure")
  if not result.ok:continue
  var t: Dictionary=result.battle.units["bandit-blade"].record
  check(t.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened")==hit,"weakening only on confirmed hit "+str(hit))
  check(result.battle.units.a.record.runtime.statuses.any(func(s: Dictionary):return s.id=="swashbuckler-technique-4-fencing")==hit,"self defence only on confirmed hit "+str(hit))
  check(result.battle.budget.main==0 and result.battle.units.a.record.runtime.resources["swashbuckler-resolve"]==r.runtime.resources["swashbuckler-resolve"]-1,"miss still consumes action/resolve")
  battles["flourish-"+str(hit)]=result.battle
 for gear in [["bow","leathers"],["staff","leathers"],["shortblade","mail"],["shortblade","shield"]]:
  var invalid: Dictionary=r.duplicate(true);invalid.equipment=gear
  check(not RulesMartial.fencing_equipment(invalid,source),"reject fencing equipment "+str(gear))
  # Multiclass proficiency is independent of fencing eligibility. Direct effects
  # reject both invalid builds and otherwise proficient, incompatible equipment.
  var result := RulesEffects.new(source).use_ability(invalid,invalid,"swashbuckler-technique-4",{"move":1,"main":1,"reaction":1},RulesRng.initial("bad-fencing"))
  check(not result.ok,"forged direct flourish rejects incompatible equipment "+str(gear))
 var spent: Dictionary=r.duplicate(true);spent.runtime.resources["swashbuckler-resolve"]=0
 check(not execute(engine,encounter(spent),"swashbuckler-technique-4","bandit-blade").ok,"exhausted flourish rejected")
func test_openings() -> void:
 var r: Dictionary=records.rogue8.duplicate(true);r.equipment=["shortblade","leathers"]
 var engine := TacticalAuras.new(r)
 for threat in [false,true]:
  var b := encounter(r);b.units.b.position=[2,2];b.units.b.weapon="shortblade"if threat else"bow";b.units.b.record.equipment=[b.units.b.weapon]
  b.units.c.position=[0,0];b.rng=attack_seed(19);b=engine.seal(b)
  var result := execute(engine,b,"attack","bandit-blade")
  check(result.ok,"precision command accepted")
  if not result.ok:continue
  check(result.battle.units.a.precision_used==threat,"adjacent allied ranged weapon is not a melee threat")
  var twice: Dictionary=result.battle.duplicate(true);twice.budget.main=1;twice.rng=attack_seed(19);twice=engine.seal(twice)
  var again := execute(engine,twice,"attack","bandit-blade")
  check(again.ok,"second development-fixture attack accepted")
  if again.ok:check(again.battle.log.filter(func(s: String):return s.contains("finds an opening")).size()==(1 if threat else 0),"no repeated precision in same activation")
  battles["precision-"+str(threat)]=result.battle
 # Class progression, not temporary stats, determines precision magnitude.
 check(RulesMartial.precision_damage(r,source)==8,"Rogue8 actual precision scaling")
func test_scout_movement() -> void:
 var r: Dictionary=records.scout8.duplicate(true);r.equipment=["bow","leathers"]
 var engine := TacticalAuras.new(r);var b := encounter(r);b.budget.move=0;b.rng=attack_seed(19);b=engine.seal(b)
 var stationary := execute(engine,b,"attack","bandit-blade")
 check(stationary.ok and not stationary.battle.log.any(func(s: String):return s.contains("exploits movement")),"spent movement token is not displacement")
 b=encounter(r);b.units["bandit-blade"].position=[4,1];b=engine.seal(b)
 var moved := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":"move","destination":[1,2]})
 check(moved.ok,"real legal Scout displacement")
 if moved.ok:
  moved.battle.rng=attack_seed(19);moved.battle=engine.seal(moved.battle)
  var hit := execute(engine,moved.battle,"attack","bandit-blade")
  check(hit.ok and hit.battle.log.any(func(s: String):return s.contains("exploits movement")),"real movement enables ranged skirmish")
  if hit.ok:battles.scout=hit.battle
func test_knight_protection() -> void:
 var r: Dictionary=records.knight8.duplicate(true);r.equipment=["shortblade","mail"]
 var engine := TacticalAuras.new(r);var b := encounter(r)
 var challenge := execute(engine,b,"knight-technique-4","bandit-blade")
 check(challenge.ok,"Knight protective challenge uses real resource/action")
 if not challenge.ok:return
 check(challenge.battle.units.a.record.runtime.statuses.any(func(s: Dictionary):return s.id=="guarding"),"challenge arms actual adjacent guard")
 check(not execute(engine,b,"knight-technique-4","b").ok,"challenge cannot target ally")
 battles.knight=challenge.battle
func test_pin_isolation() -> void:
 var old := RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v19.json").ok,"historical v19 load")
 check(not RulesMartial.mobile_enabled(old),"v19 cannot enter changed combat semantics")
 check(old.definition("abilities","swashbuckler-technique-4").name=="Disarming flourish 4","historical advertised content preserved")
 check(RulesRecords.new_character_registry().rules_ref()==source.rules_ref(),"new campaigns use exact v20")
