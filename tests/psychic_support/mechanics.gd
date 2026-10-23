extends "res://tests/psychic_support/helpers.gd"
## Legal development histories, real existing authority. Earned XP is tested separately.
const POWERS := {"psychic-warrior-power-1":"power-kinetic-bolt","psychic-warrior-power-2":"power-force-screen","psychic-warrior-power-4":"power-body-renewal","psychic-warrior-power-6":"power-mind-lock","psychic-warrior-power-8":"power-energy-surge"}
const MIND := {"divine-mind-mantle":"energy","divine-mind-mantle-4":"body","divine-mind-mantle-8":"mind","divine-mind-mantle-12":"unity","divine-mind-doctrine":"assault","divine-mind-doctrine-5":"bulwark","divine-mind-doctrine-10":"stride","divine-mind-power-1":"power-kinetic-bolt","divine-mind-power-2":"power-crystal-shard","divine-mind-power-3":"power-electric-lance","divine-mind-power-4":"power-force-screen","divine-mind-power-8":"power-thought-thrust","divine-mind-power-12":"power-concord"}
func run() -> void:
 base=OS.get_environment("GAME127_ROOT");DirAccess.make_dir_recursive_absolute(base)
 check(source.load_pack("res://data/rules/trhgd-character-v26.json").ok,"immutable26 validates")
 kernel=RulesCharacter.new(source)
 if failures:finish_parity();return
 if OS.get_environment("GAME127_RESTART")=="1":cold();return
 records.foe=build("foe",route("fighter",20),PSI)
 for cls in ["psychic-warrior","divine-mind"]:
  for at in [1,4,8,15,20]:
   var r := build(cls+str(at),route(cls,at),WISDOM,POWERS if cls=="psychic-warrior" else MIND,"WIS")
   if r.is_empty():finish_parity();return
   records[cls+str(at)]=r
   var snap: Dictionary=kernel.derive_character(r).snapshot
   check(snap.level==at and snap.manifesting_level==at,"actual permanent progression "+cls+str(at))
   check(snap.resource_capacities["psychic-points"]==2+at,"existing bounded shared PP progression "+cls+str(at))
   levels[cls+str(at)]={"history":at,"known":snap.known_powers,"points":snap.resource_capacities["psychic-points"]}
 for n in 6:
  var r := cognition("heritage-human",n)
  if r.is_empty():finish_parity();return
  records["cognition"+str(n)]=r
  var snap: Dictionary=kernel.derive_character(r).snapshot
  check(snap.level==8+n and snap.manifesting_level==8+n,"ordered five-level prestige manifesting "+str(n))
  check(snap.resource_capacities["psychic-points"]==10+2*n,"prestige adds its own PP contribution, no competing pool")
  levels["cognition"+str(n)]={"history":8+n,"prestige_levels":n,"known":snap.known_powers,"points":snap.resource_capacities["psychic-points"]}
 if not failures:test_warrior();test_mind();test_cognition();test_multiclass();test_forms();test_guards()
 if failures:finish_parity();return
 var hashes := {};var record_hashes := {};var next := {};var after := {}
 for id in records:
  records[id]=RulesJson.string_keys(records[id]);var derived := kernel.derive_character(records[id])
  check(derived.ok,"saved fixture validates "+id+JSON.stringify(derived.get("errors",[])))
  if derived.ok:hashes[id]=derived.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  check(engine.validate(battles[id]).is_empty(),"saved battle validates "+id+engine.validate(battles[id]))
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var result := engine.command(battles[id],next[id]);check(result.ok,"predict cold next command "+id)
  if result.ok:after[id]=result.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 finish_parity()
func has(r: Dictionary,id: String) -> bool:return r.runtime.statuses.any(func(s: Dictionary):return s.id==id)
func next_activation(engine: TacticalAuras,b: Dictionary) -> Dictionary:
 var current_id: String=engine.current(b).id
 for n in b.order.size()+1:
  var result := engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"})
  check(result.ok,"ordinary end-turn advances activation")
  if not result.ok:return b
  b=result.battle
  if engine.current(b).id==current_id:return b
 check(false,"activation returns within one turn-order cycle");return b
func assert_cast(b: Dictionary,id: String,target := "bandit-blade") -> Dictionary:
 var engine := TacticalAuras.new(b.units.a.record);var before := RulesJson.digest(b)
 var result := command(engine,b,id,target);check(result.ok,"actual legal tactical command "+id+str(result.get("error","")))
 check(RulesJson.digest(b)==before,"command input immutable "+id)
 if not result.ok:return {}
 var replay := command(engine,RulesJson.normalize(JSON.parse_string(JSON.stringify(b))),id,target)
 check(replay.ok and replay.battle.state_hash==result.battle.state_hash,"exact logs/HP/RNG deterministic replay "+id)
 check(result.battle.budget.main==0,"actual main action spent "+id)
 for pool in source.definition("abilities",id).cost.resources:
  check(int(result.battle.units.a.record.runtime.resources[pool])==int(b.units.a.record.runtime.resources[pool])-int(source.definition("abilities",id).cost.resources[pool]),"exact authored reserve cost "+id+":"+pool)
 check(not command(engine,result.battle,id,target).ok,"cannot reuse spent main action "+id)
 return result.battle
func test_warrior() -> void:
 for at in [1,4,8,15,20]:
  var r: Dictionary=records["psychic-warrior"+str(at)];var engine := TacticalAuras.new(r);var b := encounter(r)
  var milestone: int=1 if at<4 else 4 if at<8 else 8 if at<12 else 12
  var id := "psychic-warrior-technique-"+str(milestone)
  for hit in [false,true]:
   var branch: Dictionary=b.duplicate(true)
   var controlled: Dictionary=branch.units.a.record if hit else branch.units["bandit-blade"].record
   controlled.runtime.modifiers.append({"stat":"melee_attack" if hit else "defence","type":"untyped","value":100,"source":"forced-hit-miss-development-fixture"})
   branch=engine.seal(branch)
   check(int(engine.stats(branch.units["bandit-blade"]).defence)>=0 and int(engine.stats(branch.units["bandit-blade"]).defence)<=1000,"controlled contest stays inside frozen defence bounds")
   var out := assert_cast(branch,id)
   if out.is_empty():continue
   check(has(out.units.a.record,id+"-augmentation") and out.units.a.record.runtime.temporary_hp==at,"actor augmentation applies before separate weapon roll, including misses")
   check((out.units["bandit-blade"].record.runtime.hp<branch.units["bandit-blade"].record.runtime.hp)==hit,"physical weapon roll independently hits or misses")
   check(engine.stats(out.units.a).defence>engine.stats(b.units.a).defence,"physical augmentation actually changes defence")
   battles["warrior-"+str(at)+("-hit" if hit else "-miss")]=out
  if at>=15:
   id="psychic-warrior-master-20" if at==20 else "psychic-warrior-master-13"
   var out := assert_cast(b,id)
   if not out.is_empty():
    check(has(out.units.a.record,id+"-stance"),"late stance actually applied")
    check(kernel.derive_character(out.units.a.record).snapshot.capabilities.resistances.physical==2,"late stance actual physical resistance")
    var runtime: Dictionary=out.units.a.record.runtime
    var expired := RulesEffects.new(source).expire_statuses(runtime,"global_round_start")
    check(expired.ok and not expired.runtime.statuses.any(func(s: Dictionary):return s.id==id+"-stance"),"late stance expires at authored boundary")
  battles["ready-warrior"+str(at)]=b
 var r: Dictionary=records["psychic-warrior8"];var b := encounter(r)
 var support := assert_cast(b,"power-force-screen","b")
 if not support.is_empty():check(support.units.b.record.runtime.temporary_hp>0 and support.units["bandit-blade"].record.runtime.hp==b.units["bandit-blade"].record.runtime.hp,"selected support differs from physical strike")
 var augmented := assert_cast(b,"power-kinetic-bolt-aug2")
 if not augmented.is_empty():battles.augmented_warrior=augmented
 var empty: Dictionary=r.duplicate(true);empty.runtime.resources["psychic-points"]=0
 check(not use(empty,records.foe,"psychic-warrior-technique-8").ok and not use(empty,records.foe,"power-kinetic-bolt").ok,"strikes and chosen powers share finite PP, cannot substitute an obsolete class pool")
 check(not use(records["psychic-warrior1"],records.foe,"power-kinetic-bolt-aug2").ok,"manifesting cap rejects over-augmentation")
 var rested := RulesEffects.new(source).refresh_resources(empty.runtime,kernel.derive_character(empty).snapshot.resource_capacities,"eligible_rest")
 check(rested.ok and int(rested.runtime.resources["psychic-points"])==10,"eligible rest restores exact shared capacity")
 traces.warrior={"levels":[1,4,8,15,20],"strike_and_support":true,"hit_miss":true,"resource_exhaustion":true}
func test_mind() -> void:
 for at in [1,4,8,15,20]:
  var r: Dictionary=records["divine-mind"+str(at)];var engine := TacticalAuras.new(r);var b := encounter(r)
  b.units.b.position=[1,4];b.units.c.position=[5,1];b=engine.seal(b)
  var original: Dictionary=engine.stats(b.units.b).duplicate(true)
  var out := assert_cast(b,"divine-mind-aura-assault","a")
  if out.is_empty():continue
  check(engine.stats(out.units.b).melee_attack==original.melee_attack+1+at/5,"actual assault aura on boundary ally scales with owner level")
  check(engine.stats(out.units.c).melee_attack==engine.stats(b.units.c).melee_attack,"outside radius ally receives nothing")
  check(engine.stats(out.units["bandit-blade"]).melee_attack==engine.stats(b.units["bandit-blade"]).melee_attack,"enemy never receives ally aura")
  var digest := RulesJson.digest(out);var rng := RulesJson.digest(out.rng);out=engine.seal(out)
  check(RulesJson.digest(out)==digest and RulesJson.digest(out.rng)==rng,"live aura projection is idempotent and RNG-free")
  var wall: Dictionary=out.duplicate(true);wall.board.blocked.append([1,3]);wall=engine.seal(wall)
  check(engine.stats(wall.units.b).melee_attack==original.melee_attack,"wall blocks aura source to ally")
  var down: Dictionary=out.duplicate(true);down.units.a.record.runtime.hp=0;down=engine.seal(down)
  check(engine.stats(down.units.b).melee_attack==original.melee_attack,"incapacitated source grants no aura")
  var revived: Dictionary=down.duplicate(true);revived.units.a.record.runtime.hp=1;revived=engine.seal(revived)
  check(engine.stats(revived.units.b).melee_attack==engine.stats(out.units.b).melee_attack,"bounded non-upkeep aura resumes from living source; not a bard performance")
  out=next_activation(engine,out)
  check(has(out.units.a.record,"divine-mind-aura-assault") and out.units.a.record.runtime.resources["divine-mind-resolve"]==r.runtime.resources["divine-mind-resolve"]-1,"maintaining aura does not invent per-turn resolve cost")
  var before_pp: int=out.units.a.record.runtime.resources["psychic-points"]
  var power := assert_cast(out,"power-kinetic-bolt")
  if not power.is_empty():
   check(has(power.units.a.record,"divine-mind-aura-assault") and power.units.a.record.runtime.resources["psychic-points"]==before_pp-1,"psychic casting competes for main but keeps maintained aura and separate resolve")
  if at>=8:
   out=next_activation(engine,out)
   var changed := assert_cast(out,"divine-mind-aura-bulwark","a")
   if not changed.is_empty():
    check(has(changed.units.a.record,"divine-mind-aura-bulwark") and not has(changed.units.a.record,"divine-mind-aura-assault"),"switch explicitly replaces previous aura")
    check(engine.stats(changed.units.b).defence==original.defence+1+at/5 and engine.stats(changed.units.b).melee_attack==original.melee_attack,"switch removes old attack support and adds actual defence")
    battles["bulwark"+str(at)]=changed
  if at>=4:
   var milestone: int=2 if at<6 else 6 if at<12 else 12 if at<16 else 16 if at<20 else 20
   var rally := assert_cast(b,"divine-mind-rally-"+str(milestone),"b")
   if not rally.is_empty():
    check(rally.units.b.record.runtime.temporary_hp==at+milestone,"actual higher-level ally rally changes temporary HP")
    check(rally.units.a.record.runtime.resources["psychic-points"]==b.units.a.record.runtime.resources["psychic-points"],"rally uses resolve, never psychic points")
    battles["rally"+str(at)]=rally
  battles["aura"+str(at)]=out
  records["aura-source"+str(at)]=out.units.a.record
 var r: Dictionary=records["divine-mind20"];var engine := TacticalAuras.new(r);var b := encounter(r)
 var stride := assert_cast(b,"divine-mind-aura-stride","a")
 if not stride.is_empty():check(engine.stats(stride.units.b).stride==engine.stats(b.units.b).stride+1,"stride aura changes actual movement stat")
 var empty: Dictionary=records["divine-mind1"].duplicate(true);empty.runtime.resources["divine-mind-resolve"]=0
 check(not use(empty,empty,"divine-mind-aura-assault").ok and use(empty,records.foe,"power-kinetic-bolt").ok,"exhausted resolve cannot borrow PP; powers still legal")
 var restored := RulesEffects.new(source).refresh_resources(empty.runtime,kernel.derive_character(empty).snapshot.resource_capacities,"eligible_rest")
 check(restored.ok and restored.runtime.resources["divine-mind-resolve"]==2,"eligible rest restores resolve separately")
 var initial := kernel.create("mantle",WISDOM,"heritage-human");var suggestion := kernel.suggested_choice(initial,"divine-mind")
 suggestion.choice.specialisations["divine-mind-mantle"]="body";suggestion.choice.specialisations["divine-mind-power-1"]="power-kinetic-bolt"
 check(not kernel.preview_advancement(initial,suggestion.choice).ok,"permanent mantle restricts initial energy power")
 traces.mind={"source_range_los":true,"switch_refresh":true,"incapacitation":true,"resolve_not_upkeep":true,"casting_independent":true}
func test_cognition() -> void:
 var precursor: Dictionary=records.cognition0;var before := RulesJson.digest(precursor)
 check(kernel.available_advancement(precursor).classes["cognition-adept"].ok,"durable BAB/INT/skill/feat/psychic entry")
 check(kernel.preview_advancement(precursor,kernel.suggested_choice(precursor,"psychic-warrior").choice).ok,"eligible character can decline prestige")
 check(RulesJson.digest(precursor)==before,"qualification never grants path or changes identity")
 for n in 5:
  var level: int=n+1;var r: Dictionary=records["cognition"+str(level)];var b := encounter(r);var engine := TacticalAuras.new(r)
  var id := "cognition-strike-"+str(level);var out := assert_cast(b,id)
  if not out.is_empty():
   check(out.units["bandit-blade"].record.runtime.hp<=b.units["bandit-blade"].record.runtime.hp-2*level,"real path psychic effect precedes separate weapon roll")
   battles["cognition-strike"+str(level)]=out
  var distant: Dictionary=b.duplicate(true);distant.units["bandit-blade"].position=[2,2];distant=engine.seal(distant)
  check(not command(engine,distant,id).ok,"ordinary nonadjacent target rejected")
  var augmented: Array=kernel.derive_character(r).snapshot.known_powers.filter(func(power: String):return source.definition("psychic_powers",power).variants.size()>1)
  check(not augmented.is_empty(),"permanent prestige repertoire contains actual augmentable power")
  var power: String=source.definition("psychic_powers",augmented[0]).variants[1]
  var row := source.definition("abilities",power);var selected := assert_cast(b,power,"a" if row.targeting.kind in ["self","ally"] else "bandit-blade")
  if not selected.is_empty():battles["cognition-power"+str(level)]=selected
 var large := cognition("heritage-ogre",5);var b := encounter(large);var engine := TacticalAuras.new(large)
 b.units["bandit-blade"].position=[2,2];b=engine.seal(b)
 check(engine.weapon_range(b.units.a)==2 and command(engine,b,"attack").ok,"ancestry reach still supports normal attack")
 for n in 5:check(not command(engine,b,"cognition-strike-"+str(n+1)).ok,"adjacent prestige strike never inherits reach "+str(n+1))
 battles["reach-cognition"]=b
 var bow: Dictionary=records.cognition1.duplicate(true);bow.equipment=["bow"]
 check(kernel.validate_build(bow).ok,"lawful martial bow proficiency from psychic-warrior history")
 b=encounter(bow);b.units.a.weapon="bow";b.units.a.record.equipment=["bow"];b=engine.seal(b)
 check(not command(engine,b,"cognition-strike-1").ok,"equipped ranged weapon never supplies melee prestige strike")
 battles["bow-cognition"]=b
 check(not kernel.available_advancement(records.cognition5).classes["cognition-adept"].ok,"five prestige levels remain explicit cap")
 var missing: Dictionary=precursor.duplicate(true)
 # Permanent prerequisite deletion must invalidate the historical route, even
 # when a matching feature is offered temporarily.
 for step in missing.advancement_history:
  if step.feat_id=="psychic-discipline":step.feat_id="steady-study"
 missing.runtime.granted_features.append("shared-psychic-access")
 check(not kernel.available_advancement(missing).classes["cognition-adept"].ok,"temporary grants cannot replace permanent prerequisite feat")
 traces.cognition={"optional_entry":true,"levels":5,"adjacent_melee":true,"actual_strikes_and_augmentation":true}
func test_multiclass() -> void:
 var options := {"psychic-warrior-power-1":"power-thought-thrust","psion-power-1":"power-kinetic-bolt","psion-second-power":"power-force-screen"}
 var mixed := build("mixed",["psychic-warrior","psion","wizard","wizard","wizard"],{"STR":8,"DEX":12,"CON":14,"INT":15,"WIS":13,"CHA":10},options,"INT",{},["wizard-arcane-bolt"])
 if mixed.is_empty():return
 var snap: Dictionary=kernel.derive_character(mixed).snapshot
 check(snap.power_origins["power-thought-thrust"].attribute=="WIS" and snap.power_origins["power-kinetic-bolt"].attribute=="INT","learned owning classes retain independent casting attributes")
 check(snap.manifesting_level==2 and snap.resource_capacities["psychic-points"]==5,"only psychic class levels contribute to finite shared reserve and manifesting cap")
 var psychic := use(mixed,records.foe,"power-thought-thrust");check(psychic.ok,"mixed psychic action")
 if psychic.ok:
  check(psychic.actor.runtime.resources["wizard-slots-1"]==mixed.runtime.resources["wizard-slots-1"],"psychic action spends no arcane slot")
  records.mixed_spent=psychic.actor
 var arcane := use(mixed,records.foe,"wizard-arcane-bolt");check(arcane.ok,"independently prepared arcane action")
 if arcane.ok:check(arcane.actor.runtime.resources["psychic-points"]==mixed.runtime.resources["psychic-points"],"arcane action spends no psychic reserve")
 records.mixed=mixed
func test_forms() -> void:
 var hybrid := build("a",route("druid",5)+route("psychic-warrior",2),WISDOM,POWERS,"WIS")
 if hybrid.is_empty():return
 var shaped := use(hybrid,hybrid,"wild-shape");check(shaped.ok,"lawful existing Druid/Psychic Warrior transform")
 if not shaped.ok:return
 check(not kernel.derive_character(shaped.actor).snapshot.abilities.has("psychic-warrior-technique-1") and not use(shaped.actor,records.foe,"power-kinetic-bolt").ok,"supported natural forms suppress psychic actions, no advertised transformed manifesting")
 var b := encounter(shaped.actor);var engine := TacticalAuras.new(shaped.actor)
 check(engine.active_weapon(b.units.a)=="bear-claws" and command(engine,b,"attack").ok,"ordinary attack uses actual natural weapon while gear is suppressed")
 records.transformed=shaped.actor;battles.transformed=b
 var reverted := use(shaped.actor,shaped.actor,"revert-form");check(reverted.ok and kernel.derive_character(reverted.actor).snapshot.abilities.has("psychic-warrior-technique-1"),"reversion restores original identity/equipment and psychic abilities")
 var source_hybrid := build("a",route("druid",5)+route("divine-mind",1),WISDOM,{"divine-mind-mantle":"energy","divine-mind-doctrine":"assault","divine-mind-power-1":"power-kinetic-bolt"},"WIS")
 if source_hybrid.is_empty():return
 var active := use(source_hybrid,source_hybrid,"divine-mind-aura-assault");check(active.ok,"hybrid starts genuine aura before shaping")
 if not active.ok:return
 var form := use(active.actor,active.actor,"wild-shape");check(form.ok,"hybrid transforms via actual ability")
 if form.ok:
  b=encounter(form.actor);engine=TacticalAuras.new(form.actor)
  check(not b.units.b.record.runtime.modifiers.any(func(m: Dictionary):return str(m.source).begins_with("aura:")),"transformed aura source grants no ally projection")
  records.aura_transformed=form.actor
func test_guards() -> void:
 var born := kernel.create("forged",PSI,"heritage-human");var choice: Dictionary=kernel.suggested_choice(born,"psychic-warrior").choice;choice.class_id="cognition-adept"
 check(not kernel.preview_advancement(born,choice).ok,"prestige first advancement payload rejected")
 check(not kernel.starting_classes().has("cognition-adept"),"prestige absent from legal starting classes")
 var low: Dictionary=records["psychic-warrior1"].duplicate(true)
 low.runtime.modifiers.append({"stat":"melee_attack","type":"untyped","value":100,"source":"temporary-development-fixture"})
 check(not kernel.available_advancement(low).classes["cognition-adept"].ok,"temporary attack bonuses never satisfy earned permanent entry")
func finish_parity(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"classes":["psychic-warrior","divine-mind","cognition-adept"],"levels":levels,"traces":traces,"development_fixtures":true,"campaign_xp_injected":false}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof)))
 print("PSYCHIC_SUPPORT ",checks," checks; ",failures," failures");get_tree().quit(1 if failures else 0)
