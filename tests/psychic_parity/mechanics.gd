extends "res://tests/psychic_parity/baseline.gd"
## Legal standard-array development histories; ordinary earned play is separate.
var records := {}
var battles := {}
var base := ""
var levels := {}
const PSI := {"STR":8,"DEX":13,"CON":14,"INT":15,"WIS":12,"CHA":10}
const WILD := {"STR":8,"DEX":13,"CON":14,"INT":12,"WIS":10,"CHA":15}
func run() -> void:
 base=OS.get_environment("GAME152_ROOT");DirAccess.make_dir_recursive_absolute(base)
 check(source.load_pack("res://data/rules/trhgd-character-v24.json").ok,"immutable24 schema")
 if failures:finish();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME152_RESTART")=="1":cold();return
 records.foe=build("foe",route("fighter",20),PSI)
 for cls in ["psion","wilder"]:
  for at in [1,3,8,15,20]:
   var options := {cls+"-power-1":"power-kinetic-bolt",cls+"-power-2":"power-force-screen",cls+"-power-4":"power-mind-lock",cls+"-power-6":"power-energy-surge",cls+"-power-8":"power-vital-exchange",cls+"-power-10":"power-iron-carapace",cls+"-power-12":"power-purifying-concord",cls+"-power-14":"power-void-detonation",cls+"-power-16":"power-severing-tempest",cls+"-power-18":"power-perfect-unity"}
   if cls=="psion":options["psion-second-power"]="power-thought-thrust"
   var r := build(cls+str(at),route(cls,at),PSI if cls=="psion" else WILD,options)
   records[cls+str(at)]=r
   if r.is_empty():finish();return
   var snapshot: Dictionary=kernel.derive_character(r).snapshot
   check(int(snapshot.manifesting_level)==at,"actual shared manifesting cap "+cls+str(at))
   check(snapshot.power_origins.size()==snapshot.known_powers.size(),"every selected power has a durable owning class")
   levels[cls+str(at)]={"history":r.advancement_history.size(),"known":snapshot.known_powers,"points":snapshot.resource_capacities["psychic-points"],"origins":snapshot.power_origins}
 test_damage();test_costs();test_origins();test_hybrid();test_tactical();test_guards()
 if failures:finish();return
 var hashes := {};var record_hashes := {};var next := {};var after := {}
 for id in records:
  records[id]=RulesJson.string_keys(records[id]);var registry := RulesRecords.registry(records[id]);var derived := RulesCharacter.new(registry).derive_character(records[id])
  check(derived.ok,"saved fixture validates "+id)
  if derived.ok:hashes[id]=derived.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  check(engine.validate(battles[id]).is_empty(),"actual tactical state validates "+id)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var result := engine.command(battles[id],next[id]);check(result.ok,"predict independent cold command "+id)
  if result.ok:after[id]=result.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 FileAccess.open(base.path_join("traces.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(traces),"  "))
 finish()
func route(cls: String,count: int) -> Array:
 var result: Array=[]
 for n in count:result.append(cls)
 return result
func spell(r: Dictionary,id: String) -> Dictionary:
 var selected: Dictionary=r.duplicate(true);selected.choices.prepared_abilities=[id];selected.choices.spell_preparations={}
 check(kernel.validate_build(selected).ok,"lawful spontaneous known spell "+id)
 return selected
func test_damage() -> void:
 var assault: Dictionary=records.psion3
 var ward := build("ward",route("psion",3),PSI,{"psion-discipline":"ward","psion-power-1":"power-kinetic-bolt","psion-second-power":"power-thought-thrust","psion-power-2":"power-force-screen"})
 var ah := lost(use(assault,records.foe,"power-kinetic-bolt"),records.foe)
 var wh := lost(use(ward,records.foe,"power-kinetic-bolt"),records.foe)
 check(ah==5 and wh==3,"Assault adds two psychic damage; Ward stays defensive")
 var surge := use(records.wilder3,records.foe,"wilder-surge");check(surge.ok,"existing surge executes")
 if not surge.ok:return
 check(int(records.wilder3.runtime.resources["psychic-points"])-int(surge.actor.runtime.resources["psychic-points"])==4 and surge.budget.main==0,"surge retains four-point/main price")
 var status: Dictionary=surge.actor.runtime.statuses.filter(func(s: Dictionary):return s.id=="weakened")[0]
 check(status.remaining==3 and status.expiry=="global_round_start","original Weakened duration retained")
 var weak := lost(use(surge.actor,records.foe,"power-kinetic-bolt"),records.foe)
 check(weak==1,"existing fatigue now affects subsequent psychic damage")
 var healed := use(records.psion3,records.psion3,"power-force-screen");var warded := use(ward,ward,"power-force-screen")
 check(healed.ok and warded.ok and healed.actor.runtime.temporary_hp==warded.actor.runtime.temporary_hp,"damage bonus never increases barriers")
 var runtime: Dictionary=surge.actor.runtime
 for n in 3:
  var expired := RulesEffects.new(source).expire_statuses(runtime,"global_round_start");check(expired.ok,"ordinary Weakened boundary");runtime=expired.runtime
 var recovered: Dictionary=surge.actor.duplicate(true);recovered.runtime=runtime
 check(lost(use(recovered,records.foe,"power-kinetic-bolt"),records.foe)==3,"ordinary expiry restores normal psychic damage")
 records.weakened=surge.actor;records.ward=ward;traces.damage={"assault":ah,"ward":wh,"weakened":weak}
func test_costs() -> void:
 var early: Dictionary=records.psion1;var mid: Dictionary=records.psion3
 var before := RulesJson.digest(early)
 check(not use(early,records.foe,"power-kinetic-bolt-aug2").ok and RulesJson.digest(early)==before,"augmentation above manifesting cap rejects atomically")
 var used := use(mid,records.foe,"power-kinetic-bolt-aug2");check(used.ok,"deliberate legal augmentation")
 if not used.ok:return
 check(int(mid.runtime.resources["psychic-points"])-int(used.actor.runtime.resources["psychic-points"])==3 and used.budget.main==0,"exact augmentation cost/main token")
 check(lost(used,records.foe)>lost(use(mid,records.foe,"power-kinetic-bolt"),records.foe),"extra points change actual damage")
 check(not RulesEffects.new(source).use_ability(used.actor,records.foe,"power-kinetic-bolt",used.budget,used.rng).ok,"another power cannot reuse the same main action")
 var depleted: Dictionary=mid.duplicate(true);depleted.runtime.resources["psychic-points"]=1;before=RulesJson.digest(depleted)
 check(not use(depleted,records.foe,"power-kinetic-bolt-aug2").ok and RulesJson.digest(depleted)==before,"insufficient points reject without refill or mutation")
 var times := int(depleted.runtime.resources["psychic-points"])
 for n in times:
  var action := use(depleted,depleted,"power-force-screen");check(action.ok,"finite support power consumes reserve")
  if action.ok:depleted=action.actor
 check(int(depleted.runtime.resources["psychic-points"])==0 and not use(depleted,depleted,"power-force-screen").ok,"real zero-point exhaustion")
 var rested := RulesEffects.new(source).refresh_resources(depleted.runtime,kernel.derive_character(depleted).snapshot.resource_capacities,"eligible_rest");check(rested.ok,"eligible rest boundary")
 depleted.runtime=rested.runtime
 check(int(depleted.runtime.resources["psychic-points"])==int(kernel.derive_character(depleted).snapshot.resource_capacities["psychic-points"]),"rest restores exactly psychic capacity")
 records.spent=used.actor
func test_origins() -> void:
 var mixed := build("mixed",["psion","wilder","wilder","wilder"],{"STR":8,"DEX":12,"CON":14,"INT":15,"WIS":10,"CHA":13},{"psion-power-1":"power-kinetic-bolt","psion-second-power":"power-force-screen","wilder-power-1":"power-thought-thrust"},"INT")
 if mixed.is_empty():return
 var result := use(mixed,records.foe,"power-thought-thrust");check(result.ok,"mixed-origin manifestation")
 if not result.ok:return
 var saved: Dictionary=result.events.filter(func(e: Dictionary):return e.type=="save_resolved")[0]
 var origin: Dictionary=kernel.derive_character(mixed).snapshot.power_origins["power-thought-thrust"]
 check(origin.class_id=="wilder" and origin.attribute=="CHA" and saved.dc==12,"known power uses owning Wilder CHA, not higher Psion INT")
 var opposite := build("opposite",["wilder","psion","psion","psion"],{"STR":8,"DEX":12,"CON":14,"INT":13,"WIS":10,"CHA":15},{"wilder-power-1":"power-force-screen","psion-power-1":"power-thought-thrust","psion-second-power":"power-kinetic-bolt"},"CHA")
 var other := use(opposite,records.foe,"power-thought-thrust");check(other.ok,"reverse mixed-origin manifestation")
 if other.ok:check(other.events.filter(func(e: Dictionary):return e.type=="save_resolved")[0].dc==12,"Psion-known power cannot borrow higher Wilder CHA")
 var context: Dictionary=kernel.derive_character(mixed).context.duplicate(true);context.attributes.CHA=8
 check(not RulesPsychic.casting_access(source.definition("abilities","power-thought-thrust"),context,source).ok,"owning attribute requirement is independently enforced")
 check(not RulesEffects.new(source).use_ability(mixed,records.foe,"power-thought-thrust",{"main":1,"move":1,"reaction":1},RulesRng.initial("forged"),{"manifesting_modifier":100}).ok,"event context cannot forge manifesting attribute")
 records.mixed=mixed;records.opposite=opposite;traces.origins={"power":"power-thought-thrust","actual_dc":saved.dc,"origin":origin}
func test_hybrid() -> void:
 var attrs := {"STR":8,"DEX":12,"CON":13,"INT":14,"WIS":10,"CHA":15}
 var route6 := ["psion","psion","psion","sorcerer","sorcerer","sorcerer"]
 var precursor := build("precursor",route6,attrs,{},"INT",{3:"psychic-discipline"},["sorcerer-arcane-bolt"])
 if precursor.is_empty():return
 var hash_before := RulesJson.digest(precursor)
 check(kernel.available_advancement(precursor).classes.cerebremancer.ok and precursor.advancement_history.size()==6,"permanent legal hybrid qualifies without automatic entry")
 var declined := kernel.preview_advancement(precursor,kernel.suggested_choice(precursor,"psion").choice)
 check(declined.ok and declined.candidate.advancement_history[-1].class_id=="psion" and RulesJson.digest(precursor)==hash_before,"qualification may be deliberately declined")
 var hybrid := build("hybrid",route6+route("cerebremancer",5),attrs,{"cerebremancer-casting":"sorcerer"},"INT",{3:"psychic-discipline"},["sorcerer-arcane-bolt"])
 if hybrid.is_empty():return
 var snapshot: Dictionary=kernel.derive_character(hybrid).snapshot
 check(snapshot.casting_levels.sorcerer==8 and snapshot.manifesting_level==8 and snapshot.class_levels.cerebremancer==5,"all five prestige levels advance both existing tracks")
 check(snapshot.power_origins.values().all(func(o: Dictionary):return o.attribute=="INT"),"Psion and Cerebremancer selected psychic powers retain INT")
 var arcane := use(hybrid,records.foe,"sorcerer-arcane-bolt");check(arcane.ok,"independently known arcane spell executes")
 if not arcane.ok:return
 check(arcane.actor.runtime.resources["psychic-points"]==hybrid.runtime.resources["psychic-points"] and int(arcane.actor.runtime.resources["sorcerer-slots-1"])==int(hybrid.runtime.resources["sorcerer-slots-1"])-1,"arcane slot spends no psychic points")
 var psychic := use(arcane.actor,records.foe,"power-kinetic-bolt");check(psychic.ok,"hybrid later psychic action executes")
 if psychic.ok:
  check(psychic.actor.runtime.resources["sorcerer-slots-1"]==arcane.actor.runtime.resources["sorcerer-slots-1"] and int(psychic.actor.runtime.resources["psychic-points"])==int(arcane.actor.runtime.resources["psychic-points"])-1,"psychic expenditure neither converts nor refills arcane slots")
  records.hybrid_spent=psychic.actor
 var empty: Dictionary=hybrid.duplicate(true);empty.runtime.resources["sorcerer-slots-1"]=0
 check(not use(empty,records.foe,"sorcerer-arcane-bolt").ok and use(empty,records.foe,"power-kinetic-bolt").ok,"points cannot substitute for exhausted arcane slots")
 empty=hybrid.duplicate(true);empty.runtime.resources["psychic-points"]=0
 check(not use(empty,records.foe,"power-kinetic-bolt").ok and use(empty,records.foe,"sorcerer-arcane-bolt").ok,"arcane slots cannot substitute for exhausted points")
 var unknown: Dictionary=hybrid.duplicate(true);unknown.choices.prepared_abilities=[]
 check(not use(unknown,records.foe,"sorcerer-arcane-bolt").ok,"hybrid still obeys spontaneous known spells")
 check(not kernel.validate_build(unknown).ok,"removing permanent qualifying arcane repertoire invalidates hybrid history")
 var hollow := build("hollow",route6,{"STR":10,"DEX":14,"CON":13,"INT":15,"WIS":12,"CHA":8},{},"INT",{3:"psychic-discipline"})
 check(not hollow.is_empty() and not kernel.available_advancement(hollow).classes.cerebremancer.ok,"nominal arcane levels without a usable spell no longer qualify")
 var temporary: Dictionary=hollow.duplicate(true);temporary.runtime.modifiers.append({"stat":"save_dc","type":"untyped","value":100,"source":"temporary-development-fixture"})
 check(not kernel.available_advancement(temporary).classes.cerebremancer.ok,"temporary bonuses cannot satisfy permanent arcane entry")
 records.hybrid=hybrid;records.precursor=precursor;records.hollow=hollow
 traces.hybrid={"history":hybrid.advancement_history,"casting_levels":snapshot.casting_levels,"manifesting_level":snapshot.manifesting_level,"resources":hybrid.runtime.resources}
func encounter(record: Dictionary) -> Dictionary:
 var caster: Dictionary=record.duplicate(true);caster.character_id="a";caster.equipment=source.definition("classes",caster.advancement_history[0].class_id).recommended_equipment.duplicate()
 var party := {"a":caster}
 for id in ["b","c"]:party[id]=build(id,["fighter"],PSI);party[id].equipment=["shortblade"]
 var state := {"world_ref":{},"origin":{},"party_ids":["a","b","c"],"party":{"members":[{"name":"Psychic"},{"name":"Ally"},{"name":"Ally"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":party}}
 var engine := TacticalAuras.new(state);var b := engine.create(state,"game152-parity")
 var target: Dictionary=records.foe.duplicate(true);target.character_id="bandit-blade";target.equipment=["shortblade"]
 b.units["bandit-blade"].record=target;b.units["bandit-blade"].position=[2,1];b.units.a.position=[1,1];b.cursor=b.order.find("a")
 return engine.seal(b)
func command(engine: TacticalAuras,b: Dictionary,id: String,target := "bandit-blade") -> Dictionary:
 return engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":id,"target_id":target})
func test_tactical() -> void:
 for cls in ["psion","wilder"]:
  for at in [1,8,20]:
   var r: Dictionary=records[cls+str(at)];var engine := TacticalAuras.new(r);var b := encounter(r)
   var id := "power-kinetic-bolt" if at==1 else "power-kinetic-bolt-aug2"
   var before := RulesJson.digest(b);var result := command(engine,b,id)
   check(result.ok,"actual tactical psychic target/cost "+cls+str(at))
   if not result.ok:continue
   check(RulesJson.digest(b)==before and engine.validate(result.battle).is_empty(),"tactical command preserves input and valid state")
   var replay := command(engine,RulesJson.normalize(JSON.parse_string(JSON.stringify(b))),id)
   check(replay.ok and replay.battle.state_hash==result.battle.state_hash,"exact tactical HP/log/RNG replay "+cls+str(at))
   check(result.battle.budget.main==0 and result.battle.budget.move==1,"psychic attack spends one main, retains movement")
   battles[cls+str(at)]=result.battle
   var invalid := command(engine,b,id,"b");check(not invalid.ok,"offensive powers cannot target allies")
   var distant: Dictionary=b.duplicate(true);distant.units["bandit-blade"].position=[7,5];distant=engine.seal(distant)
   check(not command(engine,distant,id).ok,"range still belongs to tactical authority")
 var hybrid: Dictionary=records.hybrid;var engine := TacticalAuras.new(hybrid);var b := encounter(hybrid)
 var first := command(engine,b,"sorcerer-arcane-bolt");check(first.ok,"hybrid actual arcane command")
 if first.ok:
  check(not command(engine,first.battle,"power-kinetic-bolt").ok,"arcane and psychic compete for same main action")
  battles.hybrid=first.battle
 var failed: Dictionary=records.foe.duplicate(true);var saved: Dictionary=records.foe.duplicate(true)
 failed.runtime.modifiers.append({"stat":"will","type":"untyped","value":-100,"source":"forced-save-development-fixture"})
 saved.runtime.modifiers.append({"stat":"will","type":"untyped","value":100,"source":"forced-save-development-fixture"})
 var miss := use(records.psion3,saved,"power-thought-thrust");var hit := use(records.psion3,failed,"power-thought-thrust")
 check(miss.ok and hit.ok and lost(miss,saved)==0 and lost(hit,failed)>0,"actual successful and failed enemy saves change psychic results")
 if miss.ok:check(int(miss.actor.runtime.resources["psychic-points"])==int(records.psion3.runtime.resources["psychic-points"])-1,"successful save still consumes actual point/main")
func test_guards() -> void:
 var malformed := source.source_data();malformed.features.filter(func(f: Dictionary):return f.id=="psion-discipline-assault")[0].capabilities.ability_damage.psychic=31
 check(not RulesRegistry.new().load_data(malformed).ok,"unbounded ability-tag damage capability rejects")
 malformed=source.source_data();malformed.features.filter(func(f: Dictionary):return f.id=="psion-discipline-assault")[0].capabilities.ability_damage.psychic="2"
 check(not RulesRegistry.new().load_data(malformed).ok,"untyped ability damage rejects")
 var birth := kernel.create("forged",PSI,"heritage-human");var choice: Dictionary=kernel.suggested_choice(birth,"psion").choice;choice.class_id="cerebremancer"
 check(not kernel.preview_advancement(birth,choice).ok,"prestige is never a starting class")
 var old := RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v23.json").ok,"historical23 source still loads")
 malformed=old.source_data();malformed.features.filter(func(f: Dictionary):return f.id=="psion-discipline-assault")[0].capabilities={"ability_damage":{"psychic":2}}
 check(not RulesRegistry.new().load_data(malformed).ok,"new capability cannot be inserted into a historical schema")
func cold() -> void:
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for id in saved.records:
  var r: Dictionary=saved.records[id];var registry := RulesRecords.registry(r);var derived := RulesCharacter.new(registry).derive_character(r)
  check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"exact cold derived choice/origin/resources "+id)
  check(RulesJson.digest(r)==saved.record_hashes[id],"exact cold character record "+id)
 for id in saved.battles:
  var engine := TacticalAuras.new(saved.battles[id].units.a.record)
  check(engine.validate(saved.battles[id]).is_empty(),"cold tactical state valid "+id)
  var next := engine.command(saved.battles[id],saved.next[id]);check(next.ok and next.battle.state_hash==saved.after[id],"cold exact next HP/status/log/RNG "+id)
 finish(true)
func finish(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"classes":["psion","wilder","cerebremancer"],"levels":levels,"traces":traces,"development_fixtures":true,"campaign_xp_injected":false}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof)))
 print("GAME152 ",checks," checks; ",failures," failures");get_tree().quit(1 if failures else 0)
