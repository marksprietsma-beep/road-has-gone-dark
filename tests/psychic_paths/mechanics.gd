extends "res://tests/psychic_parity/mechanics.gd"
## Current immutable rules, lawful fixtures. Earned campaigns are separate.
var planner: Node
func run() -> void:
 base=OS.get_environment("GAME127_PATH_ROOT");DirAccess.make_dir_recursive_absolute(base)
 check(source.load_pack("res://data/rules/trhgd-character-v26.json").ok,"immutable26 source")
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME127_PATH_RESTART")=="1":cold();return
 planner=load("res://tests/character_completeness/prestige_driver.gd").new();planner.source=source;planner.kernel=kernel
 records.foe=build("foe",route("fighter",20),PSI)
 for cls in ["metamind","pyrokineticist"]:
  var starting := 8 if cls=="metamind" else 5
  for at in range(11):
   var r := path_record(cls,at)
   if r.is_empty():finish_parity();return
   records[cls+str(at)]=r
   var snap: Dictionary=kernel.derive_character(r).snapshot
   check(snap.level==starting+at and int(snap.class_levels.get(cls,0))==at,"ordered permanent path levels "+cls+str(at))
   levels[cls+str(at)]={"history":snap.level,"prestige_levels":at,"capacities":snap.resource_capacities,"known":snap.known_powers}
 records.psion1=build("psion1",["psion"],PSI)
 test_entry();test_reserve();test_fire();test_counterplay();test_multiclass();test_tactical_paths()
 if failures:finish_parity();return
 var hashes := {};var record_hashes := {};var next := {};var after := {}
 for id in records:
  records[id]=RulesJson.string_keys(records[id]);var derived := kernel.derive_character(records[id])
  check(derived.ok,"saved fixture valid "+id)
  if derived.ok:hashes[id]=derived.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  check(engine.validate(battles[id]).is_empty(),"sealed path battle valid "+id)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var out := engine.command(battles[id],next[id]);check(out.ok,"next command exists "+id)
  if out.ok:after[id]=out.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 finish_parity()

func path_record(cls: String,count: int,first := "psion",attrs: Dictionary=PSI) -> Dictionary:
 var r := kernel.create(cls+str(count),attrs,"heritage-human")
 var goals: Dictionary=planner.requirements(cls,0)
 var start := 8 if cls=="metamind" else 5
 for index in start+count:
  var chosen: String=first if index<start else cls
  var advanced: Dictionary=planner.advance(r,chosen,goals)
  check(advanced.ok,"lawful prerequisite-directed history "+chosen+str(index)+JSON.stringify(advanced.get("errors",[])))
  if not advanced.ok:return {}
  r=advanced.candidate
 r.equipment=["shortblade"]
 var derived := kernel.derive_character(r);check(derived.ok,"path history validates "+cls+str(count))
 if not derived.ok:return {}
 r.runtime.hp=int(derived.snapshot.stats.HP);r.runtime.resources=derived.snapshot.resource_capacities.duplicate(true)
 return r

func test_entry() -> void:
 for cls in ["metamind","pyrokineticist"]:
  check(not kernel.starting_classes().has(cls),"prestige absent at birth "+cls)
  var born := kernel.create("forged",PSI,"heritage-human");var choice: Dictionary=kernel.suggested_choice(born,"psion").choice;choice.class_id=cls
  check(not kernel.preview_advancement(born,choice).ok,"forged prestige-first rejected "+cls)
  var r: Dictionary=records[cls+"0"];var before := RulesJson.digest(r)
  check(kernel.available_advancement(r).classes[cls].ok,"complete permanent entry recognised "+cls)
  check(planner.advance(r,"psion",planner.requirements(cls,0)).ok,"qualified character can decline prestige "+cls)
  check(RulesJson.digest(r)==before and not kernel.derive_character(r).snapshot.class_levels.has(cls),"eligibility never assigns prestige "+cls)
  var spent: Dictionary=r.duplicate(true);spent.runtime.resources["psychic-points"]=0
  check(kernel.available_advancement(spent).classes[cls].ok,"durable capacity entry does not require unspent points "+cls)
  check(not kernel.available_advancement(records[cls+"10"]).classes[cls].ok,"ten-level path cap enforced "+cls)
 var low := build("low",route("psion",1)+route("fighter",4),PSI)
 low.runtime.granted_features.append("metamind-reserve-1")
 check(not kernel.available_advancement(low).classes.pyrokineticist.ok,"temporary point-capacity bonus cannot satisfy permanent entry")
 check(not kernel.available_advancement(low).classes.metamind.ok,"temporary runtime features do not replace durable Metamind prerequisites")
 records.temporary_entry=low

func test_reserve() -> void:
 var counts := {}
 for at in [1,4,5,8,10]:
  var r: Dictionary=records["metamind"+str(at)].duplicate(true);var caps: Dictionary=kernel.derive_character(r).snapshot.resource_capacities
  check(int(caps["metamind-reserve"])==1+int(floor(float(at)/4.0)),"finite reserve progression "+str(at))
  var attempts := int(caps["metamind-reserve"])
  for n in attempts:
   r.runtime.resources["psychic-points"]=0
   var out := use(r,r,"metamind-reclaim");check(out.ok,"finite reserve activation "+str(at)+"/"+str(n))
   if not out.ok:return
   check(out.budget.main==0 and int(out.actor.runtime.resources["metamind-reserve"])==attempts-n-1,"one main and one finite charge")
   check(int(out.actor.runtime.resources["psychic-points"])==mini(4+at,int(caps["psychic-points"])),"exact reclamation amount bounded by capacity")
   check(not RulesEffects.new(source).use_ability(out.actor,out.actor,"metamind-reclaim",out.budget,out.rng).ok,"no second reclaim in same main action")
   r=out.actor
  var before := RulesJson.digest(r)
  check(not use(r,r,"metamind-reclaim").ok and RulesJson.digest(r)==before,"exhausted reserve rejects atomically")
  var rested := RulesEffects.new(source).refresh_resources(r.runtime,caps,"eligible_rest");check(rested.ok,"eligible reserve recovery")
  if rested.ok:check(rested.runtime.resources==caps,"eligible rest exactly restores finite capacities")
  var full: Dictionary=records["metamind"+str(at)].duplicate(true);var bounded := use(full,full,"metamind-reclaim")
  check(bounded.ok and bounded.actor.runtime.resources["psychic-points"]==caps["psychic-points"],"reclaim cannot exceed maximum")
  records["reserve-spent"+str(at)]=r;counts[str(at)]={"uses":attempts,"restores":4+at,"cap":caps["psychic-points"]}
 traces.reserve=counts

func test_fire() -> void:
 var outcomes := {}
 for at in [1,4,7,10]:
  var actor: Dictionary=records["pyrokineticist"+str(at)];var ability := "pyrokineticist-technique-"+str(at)
  var failed: Dictionary=records.foe.duplicate(true);failed.runtime.modifiers.append({"stat":"reflex","type":"untyped","value":-100,"source":"controlled-save-development-fixture"})
  var saved: Dictionary=records.foe.duplicate(true);saved.runtime.modifiers.append({"stat":"reflex","type":"untyped","value":100,"source":"controlled-save-development-fixture"})
  var a := use(actor,failed,ability);var b := use(actor,saved,ability)
  check(a.ok and b.ok,"actual fire save branches "+str(at))
  if not a.ok or not b.ok:return
  check(a.target.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened") and not b.target.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened"),"Weakened rider only on failed Reflex")
  check(lost(a,failed)>lost(b,saved),"successful Reflex meaningfully reduces fire damage")
  check(a.budget.main==0 and int(actor.runtime.resources["psychic-points"])-int(a.actor.runtime.resources["psychic-points"])==2,"fire ignition exact shared point/main cost")
  check(int(kernel.derive_character(actor).snapshot.capabilities.resistances.fire)==at,"actual inherited fire resistance at milestone "+str(at))
  var empty: Dictionary=actor.duplicate(true);empty.runtime.resources["psychic-points"]=1
  var before := RulesJson.digest(empty);check(not use(empty,failed,ability).ok and RulesJson.digest(empty)==before,"insufficient fire points reject atomically")
  records["fire-failed"+str(at)]=a.target;records["fire-spent"+str(at)]=a.actor
  outcomes[str(at)]={"failed_damage":lost(a,failed),"saved_damage":lost(b,saved),"events":a.events,"save_events":b.events}
 traces.fire=outcomes

func test_multiclass() -> void:
 var attrs := {"STR":8,"DEX":14,"CON":12,"INT":13,"WIS":10,"CHA":15}
 var r := path_record("metamind",3,"wilder",attrs)
 if r.is_empty():return
 var snap: Dictionary=kernel.derive_character(r).snapshot
 check(snap.manifesting_level==11,"Metamind progresses existing shared manifesting level")
 for id in snap.known_powers:
  var origin: Dictionary=snap.power_origins[id]
  check(origin.attribute==("INT" if origin.class_id=="metamind" else "CHA"),"powers retain original owning class attributes")
 records.mixed=r;traces.origins=snap.power_origins
 for cls in ["metamind","pyrokineticist"]:
  var advanced: Dictionary=records[cls+"10"].duplicate(true)
  while advanced.advancement_history.size()<20:
   var step: Dictionary=planner.advance(advanced,"psion",planner.requirements(cls,0))
   check(step.ok,"legitimate base continuation after capped path "+cls)
   if not step.ok:return
   advanced=step.candidate
  var final_snapshot: Dictionary=kernel.derive_character(advanced).snapshot
  check(final_snapshot.level==20 and int(final_snapshot.class_levels[cls])==10,"total20 history preserves ten-level prestige cap "+cls)
  advanced.runtime.hp=int(final_snapshot.stats.HP);advanced.runtime.resources=final_snapshot.resource_capacities.duplicate(true)
  records[cls+"-total20"]=advanced
 var erudite := path_record("metamind",1,"erudite")
 if erudite.is_empty():return
 var context: Dictionary=kernel._replay(erudite).context
 var limit := RulesWaveFour.distinct_limit(context,source)
 check(context.known_powers.size()>limit,"Erudite hybrid has a genuine next unmanifested choice")
 erudite.runtime.manifested_powers=context.known_powers.slice(0,limit)
 erudite.runtime.resources["psychic-points"]=0
 var reclaimed := use(erudite,erudite,"metamind-reclaim");check(reclaimed.ok,"Erudite hybrid can spend its finite reserve")
 if reclaimed.ok:
  check(reclaimed.actor.runtime.manifested_powers==erudite.runtime.manifested_powers,"reclamation never resets distinct identities per rest")
  var next: String=source.definition("psychic_powers",context.known_powers[limit]).variants[0]
  check(not use(reclaimed.actor,records.foe,next).ok,"reclaimed points cannot bypass exhausted distinct-power allowance")
  records.erudite_reclaimed=reclaimed.actor

func ancestry_defender(heritage: String) -> Dictionary:
 var r := kernel.create("foe-"+heritage,PSI,heritage)
 for n in 20:
  var step := kernel.preview_advancement(r,kernel.suggested_choice(r,"fighter").choice)
  check(step.ok,"lawful inherited defender "+heritage+str(n))
  if not step.ok:return {}
  r=step.candidate
 r.runtime.hp=int(kernel.derive_character(r).snapshot.stats.HP)
 r.runtime.resources=kernel._replay(r).context.capacities.duplicate(true)
 r.runtime.modifiers.append({"stat":"reflex","type":"untyped","value":-100,"source":"controlled-save-development-fixture"})
 return r

func test_counterplay() -> void:
 var resistant := ancestry_defender("heritage-tiefling-ash")
 var immune := ancestry_defender("heritage-aasimar")
 if resistant.is_empty() or immune.is_empty():return
 var human: Dictionary=records.foe.duplicate(true);human.runtime.modifiers.append({"stat":"reflex","type":"untyped","value":-100,"source":"controlled-save-development-fixture"})
 for at in [1,4,7,10]:
  var actor: Dictionary=records["pyrokineticist"+str(at)];var id := "pyrokineticist-technique-"+str(at)
  var plain := use(actor,human,id);var reduced := use(actor,resistant,id);var guarded := use(actor,immune,id)
  check(plain.ok and reduced.ok and guarded.ok,"actual inherited fire/condition counterplay "+str(at))
  if not plain.ok or not reduced.ok or not guarded.ok:return
  check(lost(reduced,resistant)==maxi(0,lost(plain,human)-8),"actual ash heritage reduces only fire component by8")
  check(reduced.target.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened"),"fire resistance does not fabricate condition immunity")
  check(lost(guarded,immune)==lost(plain,human) and not guarded.target.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened"),"Aasimar condition immunity blocks Weakened, not fire damage")
 records.resistant=resistant;records.condition_immune=immune
 traces.counterplay={"actual_fire_resistance":8,"weakened_immunity":true,"elemental_immunity_claimed":false}

func test_tactical_paths() -> void:
 for cls in ["metamind","pyrokineticist"]:
  for at in [1,4,7,10]:
   var r: Dictionary=records[cls+str(at)].duplicate(true)
   if cls=="metamind":r.runtime.resources["psychic-points"]=0
   var battle := encounter(r);var engine := TacticalAuras.new(r)
   var id := "metamind-reclaim" if cls=="metamind" else "pyrokineticist-technique-"+str(at)
   var out := command(engine,battle,id,"a" if cls=="metamind" else "bandit-blade")
   check(out.ok,"real tactical path action "+cls+str(at))
   if out.ok:battles[cls+str(at)]=out.battle
   battles["ready-"+cls+str(at)]=battle
 traces.tactical={"metamind":true,"pyrokineticist":true}

func finish_parity(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"classes":["metamind","pyrokineticist"],"levels":levels,"traces":traces,"development_fixtures":true,"campaign_xp_injected":false}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof)))
 if is_instance_valid(planner):planner.free()
 print("PSYCHIC_PATHS ",checks," checks; ",failures," failures");get_tree().quit(1 if failures else 0)
