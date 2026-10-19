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
 test_fencing();test_talents();test_rider_levels();test_hit_boundaries();test_openings();test_scout_movement();test_knight_protection();test_prestige();test_pin_isolation()
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
 var caps: Dictionary=kernel.derive_character(spent).snapshot.resource_capacities
 var refreshed := RulesEffects.new(source).refresh_resources(spent.runtime,caps,"eligible_rest")
 check(refreshed.ok and refreshed.runtime.resources["swashbuckler-resolve"]==caps["swashbuckler-resolve"],"eligible rest restores fencing resource")
 var encounter_refresh := RulesEffects.new(source).refresh_resources(spent.runtime,caps,"encounter")
 check(encounter_refresh.ok and encounter_refresh.runtime.resources["swashbuckler-resolve"]==0,"no daily recovery at mere encounter boundary")
 var light: Dictionary=kernel.derive_character(r).snapshot
 var staff: Dictionary=r.duplicate(true);staff.equipment=["staff","leathers"]
 var heavy: Dictionary=r.duplicate(true);heavy.equipment=["shortblade","mail"]
 check(light.typed_modifiers.melee_attack.any(func(m: Dictionary):return m.source.contains("swashbuckler-finesse")),"sheet shows actual conditional finesse")
 check(not kernel.derive_character(staff).snapshot.typed_modifiers.melee_attack.any(func(m: Dictionary):return m.source.contains("swashbuckler-finesse")),"staff loses finesse on numerical sheet")
 # Multiclass to gain armour proficiency; otherwise the build rejection alone
 # would not demonstrate the actual fencing restriction.
 var choice := kernel.suggested_choice(r,"fighter","steady-study")
 var advanced := kernel.preview_advancement(r,choice.choice)
 check(advanced.ok,"legal fencing/Fighter multiclass")
 if advanced.ok:
  heavy=advanced.candidate;heavy.equipment=["shortblade","mail"]
  var d := kernel.derive_character(heavy)
  check(d.ok and not d.snapshot.typed_modifiers.melee_attack.any(func(m: Dictionary):return m.source.contains("swashbuckler-finesse")),"proficient medium armour suppresses numerical finesse")
  check(not execute(TacticalAuras.new(heavy),encounter(heavy),"swashbuckler-technique-4","bandit-blade").ok,"proficient medium-armoured character cannot fence")
  records.armoured_multiclass=heavy
 var manifested: Dictionary=r.duplicate(true)
 manifested.runtime.statuses.append({"id":"soulknife-manifested","source":"explicit-weapon-override-development-fixture","remaining":3,"expiry":"global_round_start"})
 check(not RulesMartial.fencing_equipment(manifested,source),"active virtual weapon overrides held fencing blade")
 var projected := kernel.derive_character(manifested)
 check(projected.ok and not projected.snapshot.typed_modifiers.melee_attack.any(func(m: Dictionary):return m.source.contains("swashbuckler-finesse")),"active non-fencing weapon suppresses numerical finesse too")
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
 b=encounter(r);b.units["bandit-blade"].position=[2,2];b=engine.seal(b)
 var moved := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":"move","destination":[0,1]})
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
 var guarded: Dictionary=challenge.battle.duplicate(true)
 var target: Dictionary=fixtures.fighter.duplicate(true);target.character_id="b";target.equipment=["shortblade"]
 guarded.units.b.record=target;guarded.units.b.position=[1,2];guarded.units["bandit-blade"].position=[2,2];guarded.units.c.position=[0,0]
 var attacker := build("fighter",1);attacker.character_id="bandit-blade";attacker.equipment=["shortblade"]
 guarded.units["bandit-blade"].record=attacker
 for accuracy in [1,19]:
  var copy: Dictionary=guarded.duplicate(true);copy.rng=attack_seed(accuracy,6)
  engine.weapon_attack(copy,copy.units["bandit-blade"],copy.units.b,false)
  check(copy.units.a.reaction==(1 if accuracy==1 else 0),"guard reaction spent only on actual hit "+str(accuracy))
  if accuracy==19:
   var control: Dictionary=guarded.duplicate(true);control.units.a.reaction=0;control.rng=attack_seed(accuracy,6)
   engine.weapon_attack(control,control.units["bandit-blade"],control.units.b,false)
   check(copy.units.b.record.runtime.hp==control.units.b.record.runtime.hp+4,"adjacent guard actually prevents four damage")
   copy.rng=attack_seed(19);control.rng=attack_seed(19)
   var hp1: int=copy.units.b.record.runtime.hp;var hp2: int=control.units.b.record.runtime.hp
   engine.weapon_attack(copy,copy.units["bandit-blade"],copy.units.b,false);engine.weapon_attack(control,control.units["bandit-blade"],control.units.b,false)
   check(hp1-int(copy.units.b.record.runtime.hp)==hp2-int(control.units.b.record.runtime.hp),"spent shared reaction cannot protect twice")
func test_prestige() -> void:
 var planner: Node=load("res://tests/character_completeness/prestige_driver.gd").new();planner.source=source;planner.kernel=kernel
 for pair in [["swashbuckler","duelist"],["rogue","arcane-trickster"]]:
  var path: String=pair[1]
  check(not kernel.starting_classes().has(path),"prestige absent from creation "+path)
  var empty := kernel.create("forged",{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8},"heritage-human")
  var forged: Dictionary=kernel.suggested_choice(empty,"fighter").choice;forged.class_id=path
  check(not kernel.preview_advancement(empty,forged).ok,"authoritative forged first prestige rejected "+path)
  var route: Dictionary=planner.search_route(pair[0],path,5,0)
  check(route.get("complete",false),"legitimate permanent prerequisites/full development route "+str(pair)+JSON.stringify(route.get("blocker",{})))
  if not route.get("complete",false):continue
  var r: Dictionary=planner.records[pair[0]+":"+path]
  records[path]=r
  if path=="arcane-trickster":
   var d: Dictionary=kernel.derive_character(r).snapshot
   check(d.abilities.has("precision") and RulesMartial.precision_damage(r,source)==2*int(ceil(float(int(d.class_levels.rogue)+int(d.class_levels[path]))/2.0)),"prestige contributes to real shared precision consumer")
   var engine := TacticalAuras.new(r);var b := encounter(r)
   b.units.b.position=[2,2];b.units.c.position=[0,0];b.rng=attack_seed(19);b=engine.seal(b)
   var hit := execute(engine,b,"attack","bandit-blade")
   check(hit.ok and hit.battle.log.any(func(v: String):return v.contains("Precision +"+str(RulesMartial.precision_damage(r,source)))),"actual Trickster weapon hit uses combined precision scaling")
   if hit.ok:battles.trickster=hit.battle
   b=encounter(r);var power := execute(engine,b,"arcane-trickster-power-1","bandit-blade")
   check(power.ok and power.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp,"actual ranged legerdemain has executable save/damage effect")

  else:
   r=r.duplicate(true);r.equipment=["shortblade","leathers"]
   var engine := TacticalAuras.new(r);var b := encounter(r)
   b.units["bandit-blade"].record.runtime.modifiers.append({"stat":"defence","value":100,"type":"untyped","source":"explicit-Duelist-miss-development-fixture"})
   b.rng=attack_seed(1);b=engine.seal(b)
   var missed := execute(engine,b,"duelist-power-1","bandit-blade")
   check(missed.ok and not missed.battle.units.a.record.runtime.statuses.any(func(v: Dictionary):return v.id=="duelist-power-1-stance"),"Duelist parry stance requires confirmed hit")
 check(planner.failures==0,"prestige planner retains exact production validations")
 planner.free()
func test_pin_isolation() -> void:
 var old := RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v19.json").ok,"historical v19 load")
 check(not RulesMartial.mobile_enabled(old),"v19 cannot enter changed combat semantics")
 check(old.definition("abilities","swashbuckler-technique-4").name=="Disarming flourish 4","historical advertised content preserved")
 check(RulesRecords.new_character_registry().rules_ref()==source.rules_ref(),"new campaigns use exact v20")

func test_hit_boundaries() -> void:
 for pair in [["swashbuckler20","swashbuckler-master-20"],["rogue8","attack"]]:
  var r: Dictionary=records[pair[0]].duplicate(true);r.equipment=["shortblade","leathers"]
  var engine := TacticalAuras.new(r)
  var b := encounter(r);b.units.b.position=[2,2];b.units.c.position=[0,0]
  b.units["bandit-blade"].record.runtime.statuses.append({"id":"swordsage-afterimage","source":"concealment-fixture","remaining":1,"expiry":"global_round_start"})
  b.rng=attack_seed(1,0,true);b=engine.seal(b)
  var result := execute(engine,b,pair[1],"bandit-blade")
  check(result.ok,"concealed action remains legal "+pair[0])
  if not result.ok:continue
  check(result.battle.log.any(func(s: String):return s.contains("concealment")),"real concealment blocks attack roll")
  check(result.battle.units["bandit-blade"].record.runtime.hp==b.units["bandit-blade"].record.runtime.hp,"concealed attack deals no damage")
  check(not result.battle.units.a.precision_used,"concealment does not consume opening")
  if pair[1]!="attack":check(not result.battle.units["bandit-blade"].record.runtime.statuses.any(func(v: Dictionary):return v.id=="weakened"),"late flourish hit rider cannot bypass concealment")
 var rogue: Dictionary=records.rogue8.duplicate(true);rogue.equipment=["shortblade","leathers"]
 var engine := TacticalAuras.new(rogue);var b := encounter(rogue);b.units.b.position=[2,2];b.units.c.position=[0,0];b.rng=attack_seed(19)
 engine.weapon_attack(b,b.units.a,b.units["bandit-blade"],true)
 check(not b.units.a.precision_used and not b.log.any(func(s: String):return s.contains("finds an opening")),"reaction attack cannot deliver ordinary activation precision")
 var scout := build_with_feats("scout",8,{1:"dodge",3:"mobility",5:"mobile-skirmisher"})
 check(not scout.is_empty(),"legal mobile-skirmisher prerequisite chain")
 if not scout.is_empty():
  var d: Dictionary=kernel.derive_character(scout).snapshot
  check(d.feats.has("mobile-skirmisher") and d.stats.stride>0,"mobile feat has actual stride consumer, no invented extra damage")
  records.scout_feat=scout

func test_rider_levels() -> void:
 for cls in ["scout","swashbuckler"]:
  for at in [1,8,20]:
   var r: Dictionary=records[cls+str(at)].duplicate(true)
   r.equipment=["bow","leathers"]if cls=="scout"else["shortblade","leathers"]
   var action: String=cls+("-master-20"if at==20 else"-technique-"+str(at))
   var engine := TacticalAuras.new(r)
   for hit in [false,true]:
    var b := encounter(r)
    if not hit:b.units["bandit-blade"].record.runtime.modifiers.append({"stat":"defence","value":100,"type":"untyped","source":"explicit-miss-development-fixture"})
    b.rng=attack_seed(19 if hit else 1);b=engine.seal(b)
    var result := execute(engine,b,action,"bandit-blade")
    check(result.ok,"lawful early/mid/late signature "+action+str(hit))
    if not result.ok:continue
    var status: String="off-balance"if cls=="scout"and at<20 else"weakened"
    check(result.battle.units["bandit-blade"].record.runtime.statuses.any(func(v: Dictionary):return v.id==status)==hit,"actual confirmed-hit rider "+action+str(hit))
    check(result.battle.budget.main==0,"early/mid/late action cost "+action)
    var pool: String=cls+"-resolve"
    check(result.battle.units.a.record.runtime.resources[pool]==int(r.runtime.resources[pool])-int(source.definition("abilities",action).cost.resources[pool]),"early/mid/late exact resource cost "+action)

func test_talents() -> void:
 for option in ["debilitating","escape"]:
  var r := kernel.create("talent-"+option,{"STR":10,"DEX":15,"CON":14,"INT":13,"WIS":12,"CHA":8},"heritage-human")
  var choice: Dictionary=kernel.suggested_choice(r,"rogue").choice;choice.specialisations["rogue-choice-1"]=option
  var next := kernel.preview_advancement(r,choice);check(next.ok,"deliberate Rogue talent "+option)
  if not next.ok:continue
  r=next.candidate;r.equipment=["shortblade","leathers"];r.runtime.hp=kernel.derive_character(r).snapshot.stats.HP;r.runtime.resources=kernel._replay(r).context.capacities.duplicate()
  var action: String="rogue-"+option+"-1";var other: String="rogue-"+("escape"if option=="debilitating"else"debilitating")+"-1"
  check(kernel.derive_character(r).snapshot.abilities.has(action) and not kernel.derive_character(r).snapshot.abilities.has(other),"talent choice changes actual owned actions")
  var engine := TacticalAuras.new(r);var b := encounter(r);var target: String="a"if option=="escape"else"bandit-blade"
  var result := execute(engine,b,action,target);check(result.ok,"actual tactical talent "+option)
  if result.ok:
   check(result.battle.units.a.record.runtime.resources["rogue-talent-uses"]==r.runtime.resources["rogue-talent-uses"]-1,"talent spends actual resource")
   var before: int=engine.stats(b.units[target]).defence;var after: int=engine.stats(result.battle.units[target]).defence
   check(after>before if option=="escape"else after<before,"talent changes real defence "+option)
  records["talent-"+option]=r
