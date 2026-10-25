extends "res://tests/martial_careers/mechanics.gd"
## Extra real authority interactions. Authored fixtures, no campaign XP claim.
func run() -> void:
 base=OS.get_environment("MARTIAL_ROOT").path_join("extended");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v30.json").ok,"extended30 registry");kernel=RulesCharacter.new(source)
 if OS.get_environment("MARTIAL_RESTART")=="1":cold();return
 fixtures.fighter=variant("fighter",20)
 fixtures.fighter.character_id="external-target"
 test_guard();test_power_strike();test_higher_features();test_exact_rage_expiry();test_reaction_weapon();test_rage_combat()
 persist();finish_martial()
func enemy_activation(engine: TacticalAuras,b: Dictionary,id: String) -> Dictionary:
 # A controlled authored starting activation, as in the existing encounter
 # helpers. Initiative-generation acceptance belongs to the frozen oracle.
 var result := b.duplicate(true);result.cursor=result.order.find(id);result.budget={"main":1,"move":1}
 return engine.seal(result)
func test_guard() -> void:
 var defender := variant("fighter",20);defender.equipment=["shortblade","mail","shield"]
 var light := defender.duplicate(true);light.equipment=["shortblade","leathers"]
 check(stats_of(defender).defence>stats_of(light).defence,"actual armour/shield defence trade-off")
 var engine := TacticalAuras.new(defender);var b := encounter(defender)
 var ally := variant("fighter",20);ally.character_id="b";ally.equipment=["shortblade"]
 var enemy := variant("fighter",1);enemy.character_id="bandit-blade";enemy.equipment=["shortblade"]
 b.units.b.record=ally;b.units.b.position=[1,2];b.units.c.position=[0,4]
 b.units["bandit-blade"].record=enemy;b.units["bandit-blade"].position=[2,2];b=engine.seal(b)
 check(engine.validate(b).is_empty(),"guard encounter geometry remains authoritative")
 var guarded := execute(engine,b,"guard");check(guarded.ok,"actual guard spends main action")
 if not guarded.ok:return
 check(guarded.battle.budget.main==0 and guarded.battle.units.a.reaction==1,"guard does not manufacture another main or reaction")
 for die in [1,19]:
  var active := enemy_activation(engine,guarded.battle,"bandit-blade");active.rng=attack_seed(die,6 if die==19 else 0);active=engine.seal(active)
  var spent := active.duplicate(true);spent.units.a.reaction=0;spent=engine.seal(spent)
  var command := {"actor_id":"bandit-blade","revision":active.revision,"kind":"attack","target_id":"b"}
  var used := engine.command(active,command);var control := engine.command(spent,command)
  check(used.ok and control.ok,"actual guarded hit/miss command "+str(die))
  if not used.ok or not control.ok:continue
  if die==1:check(used.battle.units.a.reaction==1 and used.battle.units.b.record.runtime.hp==active.units.b.record.runtime.hp,"a genuine miss spends no protective reaction")
  else:
   check(used.battle.units.a.reaction==0 and used.battle.units.b.record.runtime.hp-control.battle.units.b.record.runtime.hp==4,"protection reduces actual allied damage by four and consumes shared reaction")
   battles.protection=used.battle
  check(used.battle.rng==control.battle.rng,"protection adds no extra random resolution")
 records.armoured=defender;contracts.guard_reactions=true
func test_power_strike() -> void:
 var fighter := variant("fighter",8);var engine := TacticalAuras.new(fighter)
 for die in [1,19,20]:
  var b := encounter(fighter)
  # A lawful high-DEX armoured defender makes die1 a genuine numeric miss.
  b.units["bandit-blade"].record.equipment=["shortblade","mail","shield"]
  b.rng=attack_seed(die);b=engine.seal(b)
  var raw := execute(engine,b,"attack","bandit-blade");var power := execute(engine,b,"power-strike","bandit-blade")
  check(raw.ok and power.ok,"real power strike hit/miss/critical "+str(die))
  if not raw.ok or not power.ok:continue
  if die==1:check(raw.battle.units["bandit-blade"].record.runtime.hp==b.units["bandit-blade"].record.runtime.hp and power.battle.units["bandit-blade"].record.runtime.hp==b.units["bandit-blade"].record.runtime.hp,"low numeric attack cannot deal free strike damage")
  else:check(raw.battle.units["bandit-blade"].record.runtime.hp-power.battle.units["bandit-blade"].record.runtime.hp==4,"confirmed power strike adds exactly four damage")
  check(power.battle.budget.main==0 and power.battle.units.a.record.runtime.resources==b.units.a.record.runtime.resources,"ordinary weapon technique pays only its declared main cost")
 var bow := encounter(fighter);bow.units.a.weapon="bow";bow.units.a.record.equipment=["bow","leathers"];bow=engine.seal(bow)
 check(not execute(engine,bow,"power-strike","bandit-blade").ok,"real melee-only power strike rejects ranged equipment")
 contracts.power_strike=true
func test_higher_features() -> void:
 for cls in ["fighter","barbarian"]:
  var r := variant(cls,20,step_options(cls,"blade"if cls=="fighter"else"resilient"));var pool: String="fighter-resolve"if cls=="fighter"else"rage-uses"
  for id in ["second-wind","fighter-career-9","fighter-career-11","fighter-master-13","fighter-master-16","fighter-master-20"]if cls=="fighter"else["rage","barbarian-career-9","barbarian-career-11","barbarian-master-13","barbarian-master-16","barbarian-master-20"]:
   var actor := r.duplicate(true);actor.runtime.hp-=8
   var target: Dictionary=actor if source.definition("abilities",id).targeting.kind=="self"else fixtures.fighter
   var before := RulesJson.digest(actor);var out := use(actor,target,id)
   check(out.ok,"actual advertised higher action "+id+JSON.stringify(out.get("errors",[])))
   if not out.ok:continue
   check(out.budget.main==0 and out.actor.runtime.resources[pool]==actor.runtime.resources[pool]-source.definition("abilities",id).cost.resources[pool],"exact higher-action shared pool/main cost "+id)
   check(RulesJson.digest(actor)==before,"higher power keeps source immutable")
   if id in ["second-wind","fighter-career-9","fighter-career-11"]:check(out.actor.runtime.hp>actor.runtime.hp and out.actor.runtime.hp<=stats_of(actor).HP,"real bounded recovery "+id)
   if id.begins_with("barbarian-master-"):
    var amount: int=3 if id.ends_with("13") else 4 if id.ends_with("16") else 5
    check(kernel.derive_character(out.actor).snapshot.capabilities.resistances.physical==amount and out.actor.runtime.temporary_hp==40,"actual Titan fury resistance and nonstacking buffer "+id)
   records[id]=out.actor
  var paid := r.duplicate(true);var id: String="fighter-master-20"if cls=="fighter"else"barbarian-master-20"
  var target: Dictionary=fixtures.fighter if cls=="fighter"else paid
  for _n in 3:
   var out := use(paid,target,id);check(out.ok,"finite high-level resource expenditure "+cls)
   if out.ok:paid=out.actor;target=fixtures.fighter if cls=="fighter"else paid
  check(paid.runtime.resources[pool]==0 and not use(paid,target,id).ok,"no high-level resource loop "+cls)
  records[cls+"_high_spent"]=paid
 contracts.higher_features=true;contracts.exhaustion=true
func test_exact_rage_expiry() -> void:
 var barbarian := variant("barbarian",1,step_options("barbarian","reckless"));var engine := TacticalAuras.new(barbarian)
 var started := execute(engine,encounter(barbarian),"rage");check(started.ok,"actual early base rage")
 if not started.ok:return
 var b: Dictionary=started.battle
 check(b.units.a.record.runtime.statuses.any(func(s: Dictionary):return s.id=="raging"and s.remaining==3),"rage starts at exactly three global boundaries")
 for remaining in [2,1,0]:
  if b.budget.main==1:b=execute(engine,b,"end").battle
  b=next_activation(engine,b)
  var statuses: Array=b.units.a.record.runtime.statuses.filter(func(s: Dictionary):return s.id=="raging")
  check(statuses.is_empty()if remaining==0 else statuses.size()==1 and statuses[0].remaining==remaining,"exact finite rage expiry "+str(remaining))
 check(b.units.a.record.runtime.resources["rage-uses"]==0,"expiry does not restore spent daily use")
 contracts.exact_rage_duration=true
func test_reaction_weapon() -> void:
 var archer := variant("fighter",20,step_options("fighter","bow"));archer.equipment=["bow","leathers"]
 var buff := use(archer,archer,"fighter-bow-6");check(buff.ok,"actual paid ranged discipline")
 if not buff.ok:return
 var engine := TacticalAuras.new(archer);var plain := encounter(archer);var enhanced := encounter(buff.actor)
 plain.rng=attack_seed(19);enhanced.rng=plain.rng.duplicate(true)
 # Direct resolver fixture isolates the existing bow reaction's shortblade
 # fallback. Shared reaction payment is independently checked by real guard.
 engine.weapon_attack(plain,plain.units.a,plain.units["bandit-blade"],true)
 engine.weapon_attack(enhanced,enhanced.units.a,enhanced.units["bandit-blade"],true)
 check(plain.units["bandit-blade"].record.runtime.hp==enhanced.units["bandit-blade"].record.runtime.hp and plain.rng==enhanced.rng,"ranged bonus never leaks into the inherited melee reaction fallback")
 check(engine._attack_weapon_context.is_empty(),"reaction context restores after nested resolver")
 contracts.reaction_weapon=true
func test_rage_combat() -> void:
 for level in [1,6,20]:
  var barbarian := variant("barbarian",level,step_options("barbarian","reckless"))
  var raging := use(barbarian,barbarian,"rage");check(raging.ok,"actual base Rage for combat "+str(level))
  if not raging.ok:continue
  var engine := TacticalAuras.new(barbarian)
  var plain := encounter(barbarian);var enhanced := encounter(raging.actor)
  plain.rng=attack_seed(19);enhanced.rng=plain.rng.duplicate(true);plain=engine.seal(plain);enhanced=engine.seal(enhanced)
  var raw := execute(engine,plain,"attack","bandit-blade");var hit := execute(engine,enhanced,"attack","bandit-blade")
  check(raw.ok and hit.ok,"ordinary early/mid/late raging melee attack")
  if raw.ok and hit.ok:
   check(raw.battle.units["bandit-blade"].record.runtime.hp-hit.battle.units["bandit-blade"].record.runtime.hp==2,"paid Rage adds exactly two real weapon damage")
   check(raw.battle.rng==hit.battle.rng,"Rage damage adds no extra random consumption")
  var enemy := variant("fighter",1);enemy.character_id="bandit-blade"
  plain.units["bandit-blade"].record=enemy;enhanced.units["bandit-blade"].record=enemy.duplicate(true)
  var bonus: int=engine.stats(plain.units["bandit-blade"]).melee_attack
  var die: int=int(engine.stats(plain.units.a).defence)-bonus-1
  check(die>=1 and die<=20,"lawful die witnesses actual Rage defensive vulnerability")
  if die<1 or die>20:continue
  plain=enemy_activation(engine,plain,"bandit-blade");enhanced=enemy_activation(engine,enhanced,"bandit-blade")
  plain.rng=attack_seed(die);enhanced.rng=plain.rng.duplicate(true);plain=engine.seal(plain);enhanced=engine.seal(enhanced)
  var command := {"actor_id":"bandit-blade","revision":plain.revision,"kind":"attack","target_id":"a"}
  raw=engine.command(plain,command);hit=engine.command(enhanced,command)
  check(raw.ok and hit.ok,"ordinary enemy attack tests actual defensive counterplay")
  if raw.ok and hit.ok:check(raw.battle.units.a.record.runtime.hp==plain.units.a.record.runtime.hp and hit.battle.units.a.record.runtime.hp<enhanced.units.a.record.runtime.hp,"paid Rage makes a real previously missed attack hit the Barbarian")
 contracts.rage_combat=true
