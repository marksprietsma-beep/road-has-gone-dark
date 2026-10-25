extends "res://tests/dual_prestige_acceptance/base.gd"
## All high-level routes are lawful development fixtures, not earned XP.
const SORCERER_ARRAY := {"STR":8,"DEX":12,"CON":10,"INT":13,"WIS":14,"CHA":15}
func run() -> void:
 base=OS.get_environment("DUAL_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v29.json")
 check(loaded.ok,"immutable29 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_dual();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("DUAL_RESTART")=="1":cold_dual();return
 fixtures.fighter=build("fighter",20)
 fixtures.miss_defender=warded_defender()
 test_entry();test_dual_progression();test_champion_progression()
 if failures:finish_dual();return
 test_independent_casts();test_restoration_choices();test_martial_outcomes();test_dual_forms();test_resources()
 var payload := {"records":{},"hashes":{},"record_hashes":{},"battles":battles,"next":{}}
 for key in saved_records:
  var r: Dictionary=RulesJson.string_keys(saved_records[key]);var d := kernel.derive_character(r)
  check(d.ok,"persist complete legal state "+key)
  if not d.ok:continue
  payload.records[key]=r;payload.hashes[key]=d.snapshot.snapshot_hash;payload.record_hashes[key]=RulesJson.digest(r)
 for key in battles:
  var engine := TacticalAuras.new(battles[key].units.a.record)
  check(engine.validate(battles[key]).is_empty(),"saved tactical authority valid "+key)
  var command := {"actor_id":engine.current(battles[key]).id,"revision":battles[key].revision,"kind":"end"}
  var out := engine.command(battles[key],command);check(out.ok,"predict saved continuation "+key)
  if out.ok:payload.next[key]={"command":command,"hash":out.battle.state_hash}
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(payload)))
 finish_dual()
func test_entry() -> void:
 var aggregate := route(["wizard","sorcerer","sorcerer","cleric","cleric","cleric"],DUAL_ARRAY)
 if not aggregate.is_empty():check(not kernel.available_advancement(aggregate).classes["mystic-theurge"].ok,"aggregate levels never replace genuine tier2 arcane access")
 var prefix := repeated("wizard",3)+repeated("cleric",3)
 var eligible := route(prefix)
 if eligible.is_empty():return
 var before := RulesJson.digest(eligible)
 check(kernel.available_advancement(eligible).classes["mystic-theurge"].ok,"actual independent tier2 arcane/divine entry")
 check(not kernel.derive_character(eligible).snapshot.class_levels.has("mystic-theurge") and RulesJson.digest(eligible)==before,"qualification never assigns prestige or mutates history")
 check(kernel.preview_advancement(eligible,kernel.suggested_choice(eligible,"wizard").choice).ok,"qualified character may explicitly decline prestige")
 var first := kernel.create("forged-prestige",WIZARD_ARRAY,"heritage-human")
 for path in ["mystic-theurge","abjurant-champion"]:
  check(not kernel.starting_classes().has(path),"prestige never a starting class "+path)
  var choice: Dictionary=kernel.suggested_choice(first,"wizard").choice;choice.class_id=path
  var rejected := kernel.preview_advancement(first,choice)
  check(not rejected.ok and rejected.errors[0].code=="advancement.prestige_start","forged prestige first-history entry rejected "+path)
 var junior := route(prefix+["sorcerer","mystic-theurge"],DUAL_ARRAY,"mystic-theurge",{"mystic-theurge-arcane":"sorcerer"})
 if not junior.is_empty():
  var d := kernel.derive_character(junior)
  check(d.snapshot.casting_levels.wizard==3 and d.snapshot.casting_levels.sorcerer==2 and int(d.snapshot.resource_capacities.get("sorcerer-slots-2",0))==0,"lawful junior parent gains its own levels only; no borrowed Wizard tier2 pool")
  saved_records.junior_parent=junior
 for spec in [["beguiler",6,"cleric",3],["wizard",3,"spirit-shaman",3],["duskblade",5,"druid",3]]:
  var r := route(repeated(spec[0],spec[1])+repeated(spec[2],spec[3]),WIZARD_ARRAY)
  if r.is_empty():continue
  var offered := kernel.available_advancement(r);check(offered.classes["mystic-theurge"].ok,"genuine supported parent pair "+str(spec))
  var choice := kernel.suggested_choice(r,"mystic-theurge")
  choice.choice.specialisations["mystic-theurge-arcane"]=spec[0];choice.choice.specialisations["mystic-theurge-divine"]=spec[2]
  var out := kernel.preview_advancement(r,choice.choice)
  check(out.ok,"deliberate real parent pair advances "+str(spec)+JSON.stringify(out.get("errors",[])))
  if out.ok:
   var snap: Dictionary=out.snapshot
   check(int(snap.casting_levels[spec[0]])==int(spec[1])+1 and int(snap.casting_levels[spec[2]])==int(spec[3])+1,"each selected actual caster advances exactly once")
   saved_records["parents:"+spec[0]+":"+spec[2]]=out.candidate
  for wrong in ["psion","cleric"]:
   var forged: Dictionary=choice.choice.duplicate(true);forged.specialisations["mystic-theurge-arcane"]=wrong
   check(not kernel.preview_advancement(r,forged).ok,"psychic/divine class cannot be forged as arcane parent "+wrong)
 contracts.permanent_entry=true
func test_dual_progression() -> void:
 for cls in ["wizard","sorcerer"]:
  var count: int=3 if cls=="wizard" else 4
  var r := route(repeated(cls,count)+repeated("cleric",3),WIZARD_ARRAY if cls=="wizard" else SORCERER_ARRAY)
  if r.is_empty():continue
  for at in 10:
   var proposed := kernel.suggested_choice(r,"mystic-theurge")
   if at==0:proposed.choice.specialisations={"mystic-theurge-arcane":cls,"mystic-theurge-divine":"cleric"}
   var out := kernel.preview_advancement(r,proposed.choice)
   check(out.ok,"actual Theurge level "+str(at+1)+" "+cls+JSON.stringify(out.get("errors",[])))
   if not out.ok:break
   r=learn(out.candidate,out.snapshot)
   if r.is_empty():break
   var d := kernel.derive_character(r)
   check(d.ok and int(d.snapshot.class_levels[cls])==count and int(d.snapshot.class_levels.cleric)==3,"prestige never grants base class history/features "+cls)
   check(int(d.snapshot.casting_levels[cls])==count+at+1 and int(d.snapshot.casting_levels.cleric)==4+at,"both real caster tracks progress independently at every level")
   check(d.snapshot.resource_capacities.has(cls+"-slots-1") and d.snapshot.resource_capacities.has("cleric-slots-1") and d.snapshot.resource_capacities.has("mystic-theurge-uses"),"separate arcane/divine/path pools remain owned")
   saved_records[cls+":theurge"+str(at+1)]=r.duplicate(true)
  if not r.is_empty():check(not kernel.available_advancement(r).classes["mystic-theurge"].ok,"supported Theurge cap10 enforced")
 contracts.dual_casting=true
func test_champion_progression() -> void:
 for variant in ["aegis","retaliation"]:
  var r := route(repeated("duskblade",6),MARTIAL_ARRAY,"abjurant-champion")
  if r.is_empty():continue
  check(kernel.available_advancement(r).classes["abjurant-champion"].ok,"durable martial/arcane/feat/skill entry")
  check(kernel.preview_advancement(r,kernel.suggested_choice(r,"duskblade").choice).ok,"Champion eligibility leaves base advancement available")
  for at in 5:
   var proposed := kernel.suggested_choice(r,"abjurant-champion")
   for key in proposed.choice.specialisations:
    if str(key).begins_with("abjurant-doctrine-"):proposed.choice.specialisations[key]=variant
   if at==0:proposed.choice.specialisations["abjurant-casting"]="duskblade"
   var out := kernel.preview_advancement(r,proposed.choice)
   check(out.ok,"actual Champion level "+str(at+1)+" "+variant+JSON.stringify(out.get("errors",[])))
   if not out.ok:break
   r=learn(out.candidate,out.snapshot)
   if r.is_empty():break
   var d := kernel.derive_character(r)
   check(d.snapshot.casting_levels.duskblade==7+at and d.snapshot.class_levels.duskblade==6,"Champion advances casting without unrelated base powers")
   saved_records["champion:"+variant+str(at+1)]=r.duplicate(true)
  if not r.is_empty():check(not kernel.available_advancement(r).classes["abjurant-champion"].ok,"Champion cap5 preserved")
 contracts.champion_progression=true
func spell_pair(record: Dictionary,first: String,second: String) -> Dictionary:
 var r := record.duplicate(true)
 for id in [first,second]:
  if not r.choices.prepared_abilities.has(id):r.choices.prepared_abilities.append(id)
  if source.definition("abilities",id).tags.has("prepared"):r.choices.spell_preparations[id]=1
 var replay := kernel._replay(r);check(replay.ok,"legal deliberate two-tradition repertoire "+JSON.stringify(replay.get("errors",[])))
 if not replay.ok:return {}
 RulesCoreContent.refill_prepared(r,source)
 var rested := RulesEffects.new(source).refresh_resources(r.runtime,replay.context.capacities,"eligible_rest")
 check(rested.ok,"home-prepared spell pair rests legally "+JSON.stringify(rested.get("errors",[])))
 if not rested.ok:return {}
 r.runtime=rested.runtime
 return r
func test_independent_casts() -> void:
 for cls in ["wizard","sorcerer"]:
  var r := spell_pair(saved_records[cls+":theurge10"],cls+"-arcane-bolt","cleric-bless")
  if r.is_empty():continue
  var before: Dictionary=r.runtime.resources.duplicate()
  var attack := use(r,fixtures.fighter,cls+"-arcane-bolt");check(attack.ok,"selected arcane spell really damages "+cls)
  if not attack.ok:continue
  check(attack.target.runtime.hp<fixtures.fighter.runtime.hp and attack.actor.runtime.resources[cls+"-slots-1"]==before[cls+"-slots-1"]-1,"actual arcane damage and exactly own slot")
  for pool in before:
   if pool!=cls+"-slots-1" and not source.definition("resources",pool).has("prepared_ability"):check(attack.actor.runtime.resources[pool]==before[pool],"arcane cannot consume unrelated pool "+pool)
  var support := use(attack.actor,fixtures.fighter,"cleric-bless");check(support.ok,"selected divine spell really protects ally "+cls)
  if support.ok:
   check(support.target.runtime.statuses.any(func(s: Dictionary):return s.id=="blessed"),"divine support has real tactical status")
   check(support.actor.runtime.resources[cls+"-slots-1"]==attack.actor.runtime.resources[cls+"-slots-1"] and support.actor.runtime.resources["cleric-slots-1"]==before["cleric-slots-1"]-1,"divine cannot borrow or restore arcane slots")
  for empty in [cls+"-slots-1","cleric-slots-1"]:
   var dry := r.duplicate(true);dry.runtime.resources[empty]=0
   var aid: String=cls+"-arcane-bolt" if empty==cls+"-slots-1" else "cleric-bless"
   check(not use(dry,fixtures.fighter,aid).ok,"other full pools cannot fund exhausted class "+empty)
  saved_records[cls+":independent"]=support.actor if support.ok else attack.actor
 contracts.independent_resources=true
func test_restoration_choices() -> void:
 var r: Dictionary=saved_records["wizard:theurge10"]
 var target := build("fighter",20);target.runtime.hp=1
 for id in ["weakened","arcane-tether","slowed"]:
  var status := source.definition("statuses",id)
  target.runtime.statuses.append({"id":id,"source":"development-condition-fixture","remaining":int(status.duration.amount),"expiry":status.duration.expiry})
 var large := use(r,target,"mystic-theurge-power-5")
 var release := use(r,target,"mystic-theurge-power-7")
 var refuge := use(r,target,"mystic-theurge-power-9")
 check(large.ok and release.ok and refuge.ok,"all distinct late support actions execute")
 if not large.ok or not release.ok or not refuge.ok:return
 check(large.target.runtime.hp>release.target.runtime.hp and large.target.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened"),"large restoration heals more but never cleanses")
 check(not release.target.runtime.statuses.any(func(s: Dictionary):return s.id in ["weakened","arcane-tether"]) and release.target.runtime.statuses.any(func(s: Dictionary):return s.id=="slowed"),"release clears precisely two conditions, not a universal dispel")
 check(refuge.target.runtime.hp==1 and refuge.target.runtime.temporary_hp==14 and refuge.target.runtime.statuses.any(func(s: Dictionary):return s.id=="warded"),"refuge prevents damage without healing or replacing conditions")
 for out in [large,release,refuge]:
  check(out.budget.main==0 and out.actor.runtime.resources["mystic-theurge-uses"]==r.runtime.resources["mystic-theurge-uses"]-1,"one main and one shared finite path use")
  check(out.actor.choices==r.choices,"support never rewrites either casting tradition")
 saved_records.release_spent=release.actor;saved_records.refuge_target=refuge.target
 contracts.distinct_support=true
func test_martial_outcomes() -> void:
 var r: Dictionary=saved_records["champion:retaliation5"]
 var engine := TacticalAuras.new(r)
 for at in [1,3,5]:
  for roll in [1,19,20]:
   var b := encounter(r)
   b.units["bandit-blade"].record=fixtures.miss_defender.duplicate(true);b.units["bandit-blade"].record.character_id="bandit-blade"
   b.rng=attack_seed(roll);b=engine.seal(b)
   check(1+int(engine.stats(b.units.a).melee_attack)<int(engine.stats(b.units["bandit-blade"]).defence),"lawful numeric miss, not an invented natural-one rule")
   var expected := b.duplicate(true);expected.units.a.record.runtime.temporary_hp=4+2*at;expected=engine.seal(expected)
   var plain := engine.command(expected,order(expected,"attack"))
   var out := engine.command(b,order(b,"abjurant-retaliation-"+str(at)))
   check(plain.ok and out.ok,"real paid melee attack "+str(at)+" roll"+str(roll))
   if not plain.ok or not out.ok:continue
   check(out.battle.units["bandit-blade"].record==plain.battle.units["bandit-blade"].record and out.battle.rng==plain.battle.rng,"one ordinary hit/miss/critical, no hidden spell or extra attack")
   check(out.battle.units.a.record.runtime.hp==plain.battle.units.a.record.runtime.hp and out.battle.units.a.record.runtime.temporary_hp==plain.battle.units.a.record.runtime.temporary_hp,"pre-hit buffer and actual counterplay match authority")
   check(out.battle.budget.main==0 and out.battle.units.a.record.runtime.resources["abjurant-resolve"]==b.units.a.record.runtime.resources["abjurant-resolve"]-1,"one action and finite resolve even on miss")
   check(out.battle.units.a.reaction==plain.battle.units.a.reaction,"power grants no extra/shared reaction")
   check(not engine.command(out.battle,order(out.battle,"abjurant-retaliation-"+str(at))).ok,"cannot attack twice with spent main or substitute a reaction")
   battles["retaliation:"+str(at)+":"+str(roll)]=out.battle
 var aegis: Dictionary=saved_records["champion:aegis5"]
 for at in [1,3,5]:
  var out := use(aegis,fixtures.fighter,"abjurant-aegis-"+str(at));check(out.ok,"real finite ally aegis "+str(at))
  if out.ok:check(out.target.runtime.temporary_hp==6+3*at and kernel.derive_character(out.target).snapshot.stats.defence>kernel.derive_character(fixtures.fighter).snapshot.stats.defence,"aegis has real buffer/defence consequences")
 var spent := encounter(r);spent.budget.main=0;spent=engine.seal(spent)
 check(not engine.command(spent,order(spent,"abjurant-retaliation-1")).ok,"ready reaction cannot pay a missing main action")
 contracts.martial_outcomes=true
func test_dual_forms() -> void:
 var druid := prep(build("druid",20),"druid-wildheart-mantle")
 for spec in [["theurge",saved_records["wizard:theurge10"],"mystic-theurge-power-7"],["champion",saved_records["champion:retaliation5"],"abjurant-retaliation-1"]]:
  var form := use(druid,spec[1],"druid-wildheart-mantle");check(form.ok,"actual ally transformation "+spec[0])
  if not form.ok:continue
  var b := encounter(form.target);var engine := TacticalAuras.new(form.target);var before := RulesJson.digest(b)
  var command := order(b,spec[2])
  if spec[0]=="theurge":command.target_id="a"
  check(not engine.command(b,command).ok and RulesJson.digest(b)==before,"suppressed body denies magic without RNG/cost mutation")
  check(engine.command(b,order(b,"attack")).ok,"ordinary natural attack remains available")
  var reverted := use(form.target,form.target,"revert-form");check(reverted.ok,"original reversion action restores body")
  if reverted.ok:
   var restored := encounter(reverted.actor);var restored_engine := TacticalAuras.new(reverted.actor);var resumed := order(restored,spec[2])
   if spec[0]=="theurge":resumed.target_id="a"
   check(restored_engine.command(restored,resumed).ok,"same owned magical technique available after reversion")
   check(reverted.actor.advancement_history==spec[1].advancement_history and reverted.actor.equipment==spec[1].equipment,"form never rewrites identity/history/equipment")
  saved_records[spec[0]+":suppressed"]=form.target
 contracts.body_suppression=true
func test_resources() -> void:
 for spec in [[saved_records["wizard:theurge10"],"mystic-theurge-power-1","mystic-theurge-uses"],[saved_records["champion:aegis5"],"abjurant-aegis-1","abjurant-resolve"]]:
  var r: Dictionary=spec[0].duplicate(true);var before: Dictionary=r.runtime.resources.duplicate();var count: int=int(before[spec[2]])
  for n in count:
   var out := use(r,fixtures.fighter,spec[1]);check(out.ok,"finite class resource use "+str(n))
   if out.ok:r=out.actor
  check(not use(r,fixtures.fighter,spec[1]).ok,"exhausted class pool cannot borrow spell slots")
  for pool in before:
   if pool!=spec[2]:check(r.runtime.resources[pool]==before[pool],"class power never spends other pools "+pool)
  var capacities: Dictionary=kernel.derive_character(r).snapshot.resource_capacities
  for boundary in ["encounter","short_rest","daily","explicit"]:check(RulesEffects.new(source).refresh_resources(r.runtime,capacities,boundary).runtime.resources[spec[2]]==0,"unrelated boundary cannot refill path pool "+boundary)
  var rested := r.duplicate(true);rested.runtime=RulesEffects.new(source).refresh_resources(r.runtime,capacities,"eligible_rest").runtime
  check(use(rested,fixtures.fighter,spec[1]).ok,"eligible home-rest policy restores resource")
  saved_records[spec[2]+":exhausted"]=r
 contracts.recovery=true
func cold_dual() -> void:
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for key in saved.records:
  var d := kernel.derive_character(saved.records[key])
  check(d.ok and d.snapshot.snapshot_hash==saved.hashes[key],"cold exact character snapshot "+key)
  check(RulesJson.digest(saved.records[key])==saved.record_hashes[key],"cold exact history/parents/spells/gear/forms/resources "+key)
 for key in saved.battles:
  var engine := TacticalAuras.new(saved.battles[key].units.a.record)
  check(engine.validate(saved.battles[key]).is_empty(),"cold real tactical state validates "+key)
  var next := engine.command(saved.battles[key],saved.next[key].command)
  check(next.ok and next.battle.state_hash==saved.next[key].hash,"cold next command/log/RNG identical "+key)
 finish_dual(true)
func finish_dual(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"contracts":contracts,"development_fixtures":true,"earned_xp":false,"source":"RulesCharacter/RulesEffects/TacticalAuras"}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof),"  "))
 print("DUAL_PRESTIGE_MECHANICS ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
