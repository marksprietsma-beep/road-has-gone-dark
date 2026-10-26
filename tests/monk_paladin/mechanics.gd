extends "res://tests/monk_paladin/probe.gd"
## Lawful development fixtures, separate from the mandatory earned campaign.
var contracts := {}
var outcomes := {"hits":0,"misses":0,"criticals":0}
func run() -> void:
 base=OS.get_environment("MONK_PALADIN_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v31.json").ok,"current31 exact registry")
 kernel=RulesCharacter.new(source)
 if OS.get_environment("MONK_PALADIN_RESTART")=="1":cold();finish_current(true);return
 fixtures.fighter=build("fighter",20)
 for cls in ["monk","paladin"]:
  for style in (["iron","wind"] if cls=="monk" else ["mercy","justice"]):
   for at in [1,6,15,20]:
    var r := make(cls,at,options(cls,style));check(not r.is_empty(),"lawful early/mid/late history "+cls+style+str(at))
    if not r.is_empty():records[cls+"-"+style+str(at)]=r
 if failures:finish_current();return
 test_flurry();test_overrides();test_stances();test_smite();test_grace_healing();test_shelter();test_casting();test_high();test_resources()
 records.warblade8=build("warblade",8)
 test_counter_defeat() # Existing real Monk flurry/counter defeat regression.
 contracts.reaction_competition=true
 persist_current();finish_current()
func options(cls: String,style: String) -> Dictionary:
 return {cls+"-choice-1":style,cls+"-choice-6":style,cls+"-choice-15":style}
func prepare(record: Dictionary) -> Dictionary:
 var r := record.duplicate(true);var d := kernel.derive_character(r);check(d.ok,"preparation begins from legal history")
 if not d.ok:return {}
 var copies := RulesCoreContent.starting_preparations(d.snapshot,source)
 r.choices.prepared_abilities=copies.keys();r.choices.prepared_abilities.sort();r.choices.spell_preparations=copies
 d=kernel.derive_character(r);check(d.ok,"per-class prepared choices and copies legal "+JSON.stringify(d.get("errors",[])))
 if d.ok:r.runtime.resources=d.snapshot.resource_capacities.duplicate(true)
 return RulesJson.string_keys(r)
func test_flurry() -> void:
 for at in [1,6,20]:
  var r: Dictionary=records["monk-wind"+str(at)];var engine := TacticalAuras.new(r)
  for die in [1,19,20]:
   var b := encounter(r);b.rng=attack_seed(die);b=engine.seal(b)
   var manual: Dictionary=b.duplicate(true)
   engine.weapon_attack(manual,manual.units.a,manual.units["bandit-blade"],false,"flurry")
   if engine.alive(manual.units["bandit-blade"]):engine.weapon_attack(manual,manual.units.a,manual.units["bandit-blade"],false,"flurry")
   var before := RulesJson.digest(b);var used := execute(engine,b,"flurry","bandit-blade")
   check(used.ok,"legal two-strike Flurry "+str(at)+str(die))
   if not used.ok:continue
   check(RulesJson.digest(b)==before,"flurry source immutable")
   check(used.battle.rng==manual.rng and used.battle.units["bandit-blade"].record.runtime==manual.units["bandit-blade"].record.runtime,"exactly two original -2 attack/damage resolutions, no extra RNG")
   check(used.battle.budget.main==0 and used.battle.budget.move==1 and used.battle.units.a.record.runtime.resources==b.units.a.record.runtime.resources,"one main, no invented ki charge, movement preserved")
   check(not execute(engine,used.battle,"flurry","bandit-blade").ok,"no third/fourth strikes from a spent main")
   check(not execute(engine,b,"flurry","b").ok,"cannot Flurry ally")
   battles["flurry"+str(at)+str(die)]=used.battle
  var empty := r.duplicate(true);empty.runtime.resources.ki=0
  check(execute(engine,encounter(empty),"flurry","bandit-blade").ok,"ki exhaustion preserves authentic free main-action Flurry")
  empty.equipment=["shortblade"]
  check(not execute(engine,encounter(empty),"flurry","bandit-blade").ok,"held blade does not become unarmed")
  var armoured := r.duplicate(true);armoured.equipment=["unarmed","mail"]
  check(not kernel.validate_build(armoured).ok,"existing strict armour rejection preserved")
 contracts.flurry=true
func test_overrides() -> void:
 var hybrid := more(make("monk",1),"soulknife",1)
 var manifested := use(hybrid,hybrid,"soulknife-manifest");check(manifested.ok,"owned paid hybrid manifestation")
 if manifested.ok:
  var engine := TacticalAuras.new(manifested.actor);var b := encounter(manifested.actor);var before := RulesJson.digest(b)
  check(engine.active_weapon(b.units.a)=="mind-blade","effective manifestation shown")
  check(not engine.eligible(b,b.units.a,b.units["bandit-blade"],"flurry") and not execute(engine,b,"flurry","bandit-blade").ok,"manifested Flurry rejected by targets and command")
  check(not use(manifested.actor,manifested.actor,"flurry").ok,"generic effects requirements independently reject non-unarmed source")
  check(RulesJson.digest(b)==before and execute(engine,b,"attack","bandit-blade").ok,"invalid Flurry spends no state/RNG; ordinary manifested attack remains legal")
  records.manifested=manifested.actor
 var druid := more(make("monk",1),"druid",5)
 var shaped := use(druid,druid,"wild-shape");check(shaped.ok,"owned natural transformation")
 if shaped.ok:
  var engine := TacticalAuras.new(shaped.actor);var b := encounter(shaped.actor)
  check(engine.active_weapon(b.units.a)!="unarmed" and not execute(engine,b,"flurry","bandit-blade").ok,"natural form cannot borrow unarmed Flurry")
  check(execute(engine,b,"attack","bandit-blade").ok,"natural basic attack remains legal")
  records.shaped=shaped.actor
 contracts.weapon_overrides=true
func test_stances() -> void:
 for at in [1,6,20]:
  for style in ["iron","wind"]:
   var r: Dictionary=records["monk-"+style+str(at)];var id: String= "monk-"+style+"-"+str(6 if at>=6 else 1)
   var used := use(r,r,id);check(used.ok,"paid chosen stance "+id+str(at))
   if not used.ok:continue
   var before := stats_of(r);var after := stats_of(used.actor)
   check(used.budget.main==0 and used.actor.runtime.resources.ki==r.runtime.resources.ki-1,"stance really spends main/ki")
   if style=="wind":check(after.reflex==before.reflex+2 and after.stride==before.stride+2,"Wind insight actually adds beyond Evasion and permanent speed")
   else:check(after.defence>before.defence and after.fortitude>=before.fortitude,"Iron defensive alternative actually changes stats")
   if at>=6:check(used.actor.runtime.temporary_hp==at,"mastery grants nonstacking class-level buffer")
   var engine := TacticalAuras.new(r);var b := encounter(r);var paid := execute(engine,b,id)
   check(paid.ok,"real stance tactical command")
   if paid.ok:
    check(engine.reachable(paid.battle,paid.battle.units.a).size()>=engine.reachable(b,b.units.a).size(),"paid stance preserves real movement options")
    battles[style+str(at)]=paid.battle
   var expired: Dictionary=used.actor.duplicate(true)
   for n in 3:expired.runtime=RulesEffects.new(source).expire_statuses(expired.runtime,"global_round_start").runtime
   check(not expired.runtime.statuses.any(func(s: Dictionary):return s.id==id+"-status"),"three global expiry boundaries remove stance")
   check(expired.runtime.resources.ki==r.runtime.resources.ki-1,"expiry never refunds ki")
   records[style+"-active"+str(at)]=used.actor
 contracts.stances=true
func test_smite() -> void:
 for at in [1,6,20]:
  var r: Dictionary=records["paladin-justice"+str(at)];var engine := TacticalAuras.new(r)
  for die in [1,19,20]:
   var b := encounter(r);b.rng=attack_seed(die);b=engine.seal(b)
   var snap: Dictionary=kernel.derive_character(r).snapshot
   var expected := RulesRng.attack_roll(int(engine.stats(b.units.a).melee_attack)+maxi(0,int(floor(float(int(snap.attributes.CHA)-10)/2.0))),int(engine.stats(b.units["bandit-blade"]).defence),source.rule("critical"),b.rng)
   outcomes["hits"if expected.hit else"misses"]+=1
   if int(expected.critical_bonus)>0:outcomes.criticals+=1
   var manual: Dictionary=b.duplicate(true);engine.weapon_attack(manual,manual.units.a,manual.units["bandit-blade"],false,"smite")
   var used := execute(engine,b,"smite","bandit-blade");check(used.ok,"actual paid melee Smite "+str(at)+str(die))
   if not used.ok:continue
   check(used.battle.rng==manual.rng and used.battle.units["bandit-blade"].record.runtime.hp==manual.units["bandit-blade"].record.runtime.hp,"original Charisma accuracy / Paladin-level damage authority")
   check(used.battle.units.a.record.runtime.resources["smite-uses"]==r.runtime.resources["smite-uses"]-1 and used.battle.budget.main==0,"hit/miss both spend one main and Smite use")
   check(used.battle.units.a.record.runtime.resources["lay-hands"]==r.runtime.resources["lay-hands"],"Smite cannot borrow healing pool")
   check(not execute(engine,b,"smite","b").ok,"Smite refuses allies")
   battles["smite"+str(at)+str(die)]=used.battle
  var ranged := r.duplicate(true);ranged.equipment=["bow","mail"]
  var b := encounter(ranged);var hash := RulesJson.digest(b)
  check(not execute(engine,b,"smite","bandit-blade").ok and not use(ranged,ranged,"smite").ok,"bow Smite rejected by combat and generic requirements")
  check(hash==RulesJson.digest(b) and execute(engine,b,"attack","bandit-blade").ok,"ordinary bow attack retained; rejected Smite changes nothing")
 contracts.smite=true
func test_grace_healing() -> void:
 var r: Dictionary=records["paladin-mercy6"];var d := kernel.derive_character(r)
 var charisma: int=maxi(0,int(floor(float(int(d.snapshot.attributes.CHA)-10)/2.0)))
 check(charisma>0 and d.snapshot.tags.has("divine_grace"),"earned class feature and real casting attribute")
 var no_grace := make("paladin",1);var level_two := make("paladin",2)
 check(stats_of(level_two).fortitude-stats_of(no_grace).fortitude==1+2,"level2 adds scheduled Fortitude and actual +2 Charisma grace")
 var engine := TacticalAuras.new(r);var b := encounter(r)
 b.units.b.position=[1,2];b.units.b.record.runtime.hp=maxi(1,int(b.units.b.record.runtime.hp)-4);b=engine.seal(b)
 var hp: int=b.units.b.record.runtime.hp
 var healed := execute(engine,b,"lay-on-hands","b");check(healed.ok,"real adjacent ally healing")
 if healed.ok:
  check(healed.battle.units.b.record.runtime.hp>hp and healed.battle.units.b.record.runtime.hp<=engine.stats(healed.battle.units.b).HP,"healing respects target maximum")
  check(healed.battle.units.a.record.runtime.resources["lay-hands"]==r.runtime.resources["lay-hands"]-1 and healed.battle.budget.main==0,"real touch cost/main")
  battles.healing=healed.battle
 check(not execute(engine,b,"lay-on-hands","bandit-blade").ok,"touch healing rejects hostile target")
 var far: Dictionary=b.duplicate(true);far.units.b.position=[7,5];far=engine.seal(far)
 check(not execute(engine,far,"lay-on-hands","b").ok,"touch healing does not acquire Mercy range")
 var mercy := execute(engine,b,"paladin-mercy-6","b");check(mercy.ok,"selected Mercy alternative is executable")
 var justice: Dictionary=records["paladin-justice6"]
 check(not use(justice,justice,"paladin-mercy-6").ok,"unselected oath cannot be borrowed")
 contracts.grace_healing=true
func test_shelter() -> void:
 var r := make("paladin",7);var engine := TacticalAuras.new(r);var b := encounter(r)
 b.units.b.position=[1,2];b.units.c.position=[7,5];b=engine.seal(b)
 var inside := engine.stats(b.units.b);var outside := engine.stats(b.units.c)
 var used := execute(engine,b,"oath-shelter");check(used.ok,"real party shelter main action")
 if not used.ok:return
 check(engine.stats(used.battle.units.b).defence==inside.defence+2 and engine.stats(used.battle.units.b).will==inside.will+3,"nearby ally gains real defence and Will")
 check(engine.stats(used.battle.units.c)==outside,"distant ally receives no aura")
 check(not used.battle.units["bandit-blade"].record.runtime.statuses.any(func(s: Dictionary):return s.id=="oath-shelter"),"enemy excluded from shelter")
 check(used.battle.units.a.record.runtime.resources["smite-uses"]==r.runtime.resources["smite-uses"]-1,"shelter competes with Smite pool")
 battles.shelter=used.battle;contracts.party_shelter=true
func test_casting() -> void:
 for at in [6,20]:
  var r := prepare(records["paladin-mercy"+str(at)]);var id: String= "paladin-radiance" if at==6 else "paladin-tier6-tempest"
  check(r.choices.prepared_abilities.has(id),"real prepared offensive option "+id)
  var engine := TacticalAuras.new(r);var b := encounter(r)
  var used := execute(engine,b,id,"bandit-blade");check(used.ok,"prepared divine spell executes "+id)
  if not used.ok:continue
  for pool in source.definition("abilities",id).cost.resources:check(used.battle.units.a.record.runtime.resources[pool]==r.runtime.resources[pool]-1,"own tier slot and prepared copy spent "+pool)
  check(used.battle.units.a.record.runtime.resources["lay-hands"]==r.runtime.resources["lay-hands"] and used.battle.units.a.record.runtime.resources["smite-uses"]==r.runtime.resources["smite-uses"],"casting independent from oath/touch resources")
  var absent := r.duplicate(true);absent.choices.prepared_abilities.erase(id);absent.choices.spell_preparations.erase(id)
  for pool in source.definition("abilities",id).cost.resources:
   if source.definition("resources",pool).has("prepared_ability"):absent.runtime.resources[pool]=0
  check(not execute(engine,encounter(absent),id,"bandit-blade").ok,"unprepared divine spell denied")
  records["prepared"+str(at)]=used.battle.units.a.record;battles["spell"+str(at)]=used.battle
 var hybrid := prepare(more(make("paladin",6),"sorcerer",4))
 check(kernel.derive_character(hybrid).ok,"prepared divine/spontaneous arcane multiclass remains legal")
 records.dual_caster=hybrid;contracts.divine_casting=true
func test_high() -> void:
 for cls in ["monk","paladin"]:
  for at in [13,16,20]:
   var r := make(cls,at,options(cls,"wind"if cls=="monk"else"mercy"));var engine := TacticalAuras.new(r)
   var b := encounter(r);b.rng=attack_seed(1);b=engine.seal(b)
   var id: String= cls+"-master-"+str(at);var target: String= "bandit-blade"if cls=="monk"else"b"
   if cls=="paladin":b.units.b.position=[1,2];b.units.b.record.runtime.hp=1;b=engine.seal(b)
   var used := execute(engine,b,id,target);check(used.ok,"actual higher tactical power "+id)
   if not used.ok:continue
   var pool: String= "ki"if cls=="monk"else"lay-hands";var cost: int=int(source.definition("abilities",id).cost.resources[pool])
   check(used.battle.units.a.record.runtime.resources[pool]==r.runtime.resources[pool]-cost and used.battle.budget.main==0,"higher power paid exact finite cost")
   if cls=="monk":check(used.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp,"late palm actual saved force damage")
   else:check(used.battle.units.b.record.runtime.hp>b.units.b.record.runtime.hp,"late Paladin actual party recovery")
   if at>=16:check(used.battle.units.a.record.runtime.temporary_hp==at,"late distinct buffer remains executable")
   battles[cls+str(at)]=used.battle
 contracts.higher_tactical=true
func test_resources() -> void:
 for pair in [["monk-wind6","monk-wind-6","ki"],["paladin-justice6","paladin-justice-6","lay-hands"],["paladin-mercy6","oath-shelter","smite-uses"]]:
  var r: Dictionary=records[pair[0]].duplicate(true);var capacity: Dictionary=kernel.derive_character(r).snapshot.resource_capacities
  var before: int=r.runtime.resources[pair[2]]
  for n in before:
   var used := use(r,r,pair[1]);check(used.ok,"finite resource use "+str(pair[1])+str(n))
   if used.ok:r=used.actor
  check(r.runtime.resources[pair[2]]==0 and not use(r,r,pair[1]).ok,"exhaustion authoritatively rejects further use")
  var no_rest := RulesEffects.new(source).refresh_resources(r.runtime,capacity,"encounter_start")
  check(no_rest.runtime.resources[pair[2]]==0,"encounter transition does not refund daily resource")
  var rested := RulesEffects.new(source).refresh_resources(r.runtime,capacity,"eligible_rest")
  check(rested.ok and rested.runtime.resources[pair[2]]==before,"eligible home rest restores original capacity")
  records[str(pair[0])+"-spent"]=r
 contracts.resources=true
func persist_current() -> void:
 var payload := {"records":{},"hashes":{},"record_hashes":{},"battles":battles,"next":{},"after":{}}
 for key in records:
  var r: Dictionary=RulesJson.string_keys(records[key]);var d := kernel.derive_character(r);check(d.ok,"saved legal full character "+key+JSON.stringify(d.get("errors",[])))
  if not d.ok:continue
  payload.records[key]=r;payload.hashes[key]=d.snapshot.snapshot_hash;payload.record_hashes[key]=RulesJson.digest(r)
 for key in battles:
  var engine := TacticalAuras.new(battles[key].units.a.record);check(engine.validate(battles[key]).is_empty(),"saved tactical validity "+key)
  var command := {"actor_id":engine.current(battles[key]).id,"revision":battles[key].revision,"kind":"end"};var out := engine.command(battles[key],command)
  check(out.ok,"predict next command "+key)
  if out.ok:payload.next[key]=command;payload.after[key]=out.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(payload)))
func cold() -> void:
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for key in saved.records:
  var r: Dictionary=saved.records[key];var d := kernel.derive_character(r)
  check(d.ok and d.snapshot.snapshot_hash==saved.hashes[key],"exact cold attributes/features/choices/resources "+key)
  check(RulesJson.digest(r)==saved.record_hashes[key],"exact cold record/pin "+key)
 for key in saved.battles:
  var engine := TacticalAuras.new(saved.battles[key].units.a.record)
  check(engine.validate(saved.battles[key]).is_empty(),"cold battle valid "+key)
  var out := engine.command(saved.battles[key],saved.next[key])
  check(out.ok and out.battle.state_hash==saved.after[key],"cold next command/log/RNG exact "+key)
func finish_current(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"contracts":contracts,"outcomes":outcomes,"development_fixtures":true,"earned_xp":false}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("MONK_PALADIN ",JSON.stringify(proof))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
