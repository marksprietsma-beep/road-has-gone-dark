extends "res://tests/psychic_parity/mechanics.gd"
## Lawful standard-array development fixtures. Earned campaign acceptance is separate.
const WISDOM := {"STR":8,"DEX":13,"CON":14,"INT":12,"WIS":15,"CHA":10}
const ARDENT := {"ardent-mantle":"energy","ardent-second-mantle":"body","ardent-mantle-4":"mind","ardent-mantle-8":"insight","ardent-mantle-12":"unity","ardent-power-1":"power-kinetic-bolt","ardent-second-power":"power-force-screen","ardent-power-2":"power-body-renewal","ardent-power-4":"power-mind-lock","ardent-power-6":"power-energy-surge","ardent-power-8":"power-vital-exchange","ardent-power-10":"power-iron-carapace","ardent-power-12":"power-purifying-concord","ardent-power-14":"power-void-detonation","ardent-power-16":"power-severing-tempest","ardent-power-18":"power-perfect-unity"}
func run() -> void:
 base=OS.get_environment("GAME127_ROOT");DirAccess.make_dir_recursive_absolute(base)
 check(source.load_pack("res://data/rules/trhgd-character-v25.json").ok,"immutable25 validates")
 kernel=RulesCharacter.new(source)
 if failures:finish_identity();return
 if OS.get_environment("GAME127_RESTART")=="1":identity_cold();return
 records.foe=build("foe",route("fighter",20),PSI)
 for cls in ["ardent","lurk","erudite"]:
  for at in [1,4,8,15,20]:
   var r := build(cls+str(at),route(cls,at),WISDOM if cls=="ardent" else PSI,ARDENT if cls=="ardent" else {},"WIS" if cls=="ardent" else "INT")
   records[cls+str(at)]=r
   if r.is_empty():finish_identity();return
   var snap: Dictionary=kernel.derive_character(r).snapshot
   check(snap.level==at and snap.manifesting_level==at,"lawful permanent history and shared cap "+cls+str(at))
   check(snap.known_powers.size()==snap.power_origins.size(),"every permanent power has an owning class "+cls+str(at))
   levels[cls+str(at)]={"history":at,"known":snap.known_powers,"points":snap.resource_capacities["psychic-points"],"distinct_limit":snap.distinct_power_limit}
 if not failures:test_mantles();test_ambush();test_distinct()
 if failures:finish_identity();return
 var hashes := {};var record_hashes := {};var next := {};var after := {}
 for id in records:
  records[id]=RulesJson.string_keys(records[id]);var derived := RulesCharacter.new(RulesRecords.registry(records[id])).derive_character(records[id])
  check(derived.ok,"all persisted identity states validate "+id)
  if derived.ok:hashes[id]=derived.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  check(engine.validate(battles[id]).is_empty(),"saved battle valid "+id)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var result := engine.command(battles[id],next[id]);check(result.ok,"next command prediction "+id)
  if result.ok:after[id]=result.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 finish_identity()
func test_mantles() -> void:
 var birth := kernel.create("mantle-forgery",WISDOM,"heritage-human")
 var choice: Dictionary=kernel.suggested_choice(birth,"ardent").choice
 choice.specialisations["ardent-mantle"]="energy";choice.specialisations["ardent-second-mantle"]="body"
 choice.specialisations["ardent-power-1"]="power-thought-thrust";choice.specialisations["ardent-second-power"]="power-force-screen"
 check(not kernel.preview_advancement(birth,choice).ok,"mind power cannot use energy/body mantles")
 birth.runtime.granted_features.append("ardent-mantle-mind")
 check(not kernel.preview_advancement(birth,choice).ok,"temporary granted mantle cannot qualify permanent learning")
 birth.runtime.granted_features=[];choice.specialisations["ardent-second-mantle"]="mind"
 check(kernel.preview_advancement(birth,choice).ok==false,"force screen still needs body or unity; mantle edits revalidate every power")
 choice.specialisations["ardent-second-power"]="power-kinetic-bolt"
 check(kernel.preview_advancement(birth,choice).ok,"real energy/mind selections unlock different offensive powers")
 choice.specialisations["ardent-second-mantle"]="energy"
 check(not kernel.preview_advancement(birth,choice).ok,"duplicate starting mantles rejected")
 # Every pair of authored mantles and every starting power uses the same durable predicate.
 var mapping := {"energy":"power-kinetic-bolt","body":"power-force-screen","mind":"power-thought-thrust","insight":"power-burst-step","unity":"power-fellowship"}
 for first in mapping:
  for second in mapping:
   if first==second:continue
   var original := kernel.create("mantle-"+first+"-"+second,WISDOM,"heritage-human")
   var selected: Dictionary=kernel.suggested_choice(original,"ardent").choice
   selected.specialisations["ardent-mantle"]=first;selected.specialisations["ardent-second-mantle"]=second
   selected.specialisations["ardent-power-1"]=mapping[first];selected.specialisations["ardent-second-power"]=mapping[second]
   check(kernel.preview_advancement(original,selected).ok,"every distinct mantle pair is attainable "+first+"/"+second)
   var context: Dictionary=kernel._replay(original).context
   for power in source.ids("psychic_powers"):
    var row := source.definition("psychic_powers",power)
    if int(row.tier)!=1 or not row.class_ids.has("ardent"):continue
    var allowed: bool=row.mantle_tags.has("mantle_"+first)or row.mantle_tags.has("mantle_"+second)
    check(RulesPsychic.eligibility(power,"ardent",1,context,source,selected.specialisations).ok==allowed,"exact mantle union eligibility "+first+"/"+second+":"+power)
 var mixed := build("mixed",["ardent","psion","psion","psion"],{"STR":8,"DEX":13,"CON":14,"INT":12,"WIS":15,"CHA":10}, {"ardent-mantle":"energy","ardent-second-mantle":"body","ardent-power-1":"power-kinetic-bolt","ardent-second-power":"power-force-screen","psion-power-1":"power-thought-thrust","psion-second-power":"power-burst-step"},"WIS")
 if mixed.is_empty():return
 var snap: Dictionary=kernel.derive_character(mixed).snapshot
 check(snap.power_origins["power-kinetic-bolt"].attribute=="WIS" and snap.power_origins["power-thought-thrust"].attribute=="INT","multiclass origins remain separate; Psion learning is not mantle restricted")
 records.mixed=mixed
 for at in [1,8,20]:
  var r: Dictionary=records["ardent"+str(at)];var engine := TacticalAuras.new(r);var b := encounter(r)
  battles["ready-ardent"+str(at)]=b
  var attack := command(engine,b,"power-kinetic-bolt")
  var ward := command(engine,b,"power-force-screen","b")
  check(attack.ok and ward.ok,"Ardent actually chooses attack or ally defence "+str(at))
  if attack.ok and ward.ok:
   check(attack.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp and ward.battle.units.b.record.runtime.temporary_hp>0,"Ardent choices have distinct effects")
   check(attack.battle.budget.main==0 and int(attack.battle.units.a.record.runtime.resources["psychic-points"])==int(b.units.a.record.runtime.resources["psychic-points"])-1,"Ardent expenditure exact")
   battles["ardent"+str(at)]=ward.battle
 var no_points: Dictionary=records.ardent1.duplicate(true);no_points.runtime.resources["psychic-points"]=0
 check(not use(no_points,records.foe,"power-kinetic-bolt").ok,"Ardent exhaustion rejects")
 var refreshed := RulesEffects.new(source).refresh_resources(no_points.runtime,kernel.derive_character(no_points).snapshot.resource_capacities,"eligible_rest")
 check(refreshed.ok and int(refreshed.runtime.resources["psychic-points"])>0,"Ardent eligible rest recovers")
 var late := command(TacticalAuras.new(records.ardent20),encounter(records.ardent20),"power-perfect-unity","b")
 check(late.ok and late.battle.units.b.record.runtime.temporary_hp==27,"Ardent tier9 supported identity executes, not a table-only level20")
func test_ambush() -> void:
 for at in [1,8,20]:
  var r: Dictionary=records["lurk"+str(at)];var engine := TacticalAuras.new(r);var b := encounter(r)
  check(not command(engine,b,"lurk-psychic-ambush").ok,"ambush needs prior veil "+str(at))
  var veiled := command(engine,b,"lurk-veil","a");check(veiled.ok,"veil activation "+str(at))
  if not veiled.ok:continue
  b=veiled.battle
  check(not command(engine,b,"lurk-psychic-ambush").ok,"veil and ambush cannot share a main action")
  for turn in b.order.size():
   var ended := engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"})
   check(ended.ok,"authoritative end-turn reaches next Lurk activation")
   if not ended.ok:return
   b=ended.battle
   if engine.current(b).id=="a":break
  check(engine.current(b).id=="a" and int(b.budget.main)==1,"normal next activation restores only action tokens")
  check(kernel.derive_character(b.units.a.record).snapshot.capabilities.concealment==25,"veil provides concealment, not invisibility")
  battles["veiled-lurk"+str(at)]=b
  var distant: Dictionary=b.duplicate(true);distant.units["bandit-blade"].position=[2,2];distant=engine.seal(distant)
  check(engine.validate(distant).is_empty() and not command(engine,distant,"lurk-psychic-ambush").ok,"melee ambush remains adjacent on valid free tiles")
  for attack_bonus in [-100,100]:
   var attempt: Dictionary=b.duplicate(true);attempt.units.a.record.runtime.modifiers.append({"stat":"melee_attack","type":"untyped","value":attack_bonus,"source":"forced-hit-miss-development-fixture"});attempt=engine.seal(attempt)
   var used := command(engine,attempt,"lurk-psychic-ambush");check(used.ok,"costed adjacent ambush resolves "+str(attack_bonus))
   if not used.ok:continue
   check(used.battle.units["bandit-blade"].record.runtime.hp<attempt.units["bandit-blade"].record.runtime.hp,"authored direct psychic component applies independently of weapon roll")
   if attack_bonus<0:check(int(attempt.units["bandit-blade"].record.runtime.hp)-int(used.battle.units["bandit-blade"].record.runtime.hp)==2+at/2,"miss retains exactly the authored class-scaled psychic component")
   else:check(int(attempt.units["bandit-blade"].record.runtime.hp)-int(used.battle.units["bandit-blade"].record.runtime.hp)>2+at/2,"weapon hit adds separate actual weapon damage")
   check(used.battle.units["bandit-blade"].record.runtime.statuses.any(func(st: Dictionary):return st.id=="off-balance"),"authored ambush debuff is visible after hit or miss")
   check(not kernel.derive_character(used.battle.units.a.record).snapshot.tags.has("psychic_ambush_ready"),"ambush consumes veil on hit or miss")
   check(int(used.battle.units.a.record.runtime.resources["psychic-points"])==int(attempt.units.a.record.runtime.resources["psychic-points"])-1 and int(used.battle.units.a.record.runtime.resources["lurk-focus"])==int(attempt.units.a.record.runtime.resources["lurk-focus"])-1,"ambush spends one focus and PP even on miss")
   check(used.battle.log.any(func(line: String):return "miss." in line) if attack_bonus<0 else used.battle.log.any(func(line: String):return " damage" in line),"actual weapon roll is separately visible")
   check(command(engine,attempt,"lurk-psychic-ambush").battle.state_hash==used.battle.state_hash,"ambush exact RNG replay")
   battles["lurk"+str(at)+str(attack_bonus)]=used.battle
  var exhausted: Dictionary=r.duplicate(true)
  var focus: int=exhausted.runtime.resources["lurk-focus"]
  for n in focus:
   var spent := use(exhausted,exhausted,"lurk-veil");check(spent.ok,"each veil spends one actual focus")
   if spent.ok:exhausted=spent.actor
  check(not use(exhausted,exhausted,"lurk-veil").ok and not use(exhausted,records.foe,"lurk-psychic-ambush").ok,"Lurk exhausted focus blocks veil and ambush")
  var rest := RulesEffects.new(source).refresh_resources(exhausted.runtime,kernel.derive_character(exhausted).snapshot.resource_capacities,"eligible_rest")
  check(rest.ok and int(rest.runtime.resources["lurk-focus"])==focus,"eligible rest restores actual Lurk focus")
  records["exhausted-lurk"+str(at)]=exhausted
 var ogre := kernel.create("ogre-lurk",PSI,"heritage-ogre")
 for n in 4:
  var suggestion := kernel.suggested_choice(ogre,"lurk");check(suggestion.ok,"legal large Lurk suggestion")
  if not suggestion.ok:return
  var advanced := kernel.preview_advancement(ogre,suggestion.choice);check(advanced.ok,"legal large Lurk advancement")
  if not advanced.ok:return
  ogre=advanced.candidate
 ogre.runtime.hp=int(kernel.derive_character(ogre).snapshot.stats.HP);ogre.runtime.resources=kernel._replay(ogre).context.capacities.duplicate()
 var armed := use(ogre,ogre,"lurk-veil");check(armed.ok,"large Lurk actual veil")
 if armed.ok:
  var engine := TacticalAuras.new(ogre);var b := encounter(armed.actor)
  b.units["bandit-blade"].position=[2,2];b=engine.seal(b)
  check(engine.validate(b).is_empty(),"large Lurk negative fixture is completely legal")
  check(engine.eligible(b,b.units.a,b.units["bandit-blade"],"attack"),"ordinary weapon attack retains legitimate ancestry reach")
  check(not engine.eligible(b,b.units.a,b.units["bandit-blade"],"lurk-psychic-ambush") and not command(engine,b,"lurk-psychic-ambush").ok,"bounded ambush does not inherit ordinary weapon reach")
  battles["reach-lurk"]=b
 var bow_lurk := build("bow-lurk",["fighter"]+route("lurk",8),PSI,{},"INT")
 if not bow_lurk.is_empty():
  bow_lurk.equipment=["bow"];var veiled_bow := use(bow_lurk,bow_lurk,"lurk-veil")
  check(veiled_bow.ok,"lawful fighter bridge grants bow proficiency and retains Lurk veil")
  if veiled_bow.ok:
   var b := encounter(veiled_bow.actor);b.units.a.record.equipment=["bow"];b.units.a.weapon="bow";var engine := TacticalAuras.new(bow_lurk);b=engine.seal(b)
   check(engine.validate(b).is_empty() and not command(engine,b,"lurk-psychic-ambush").ok,"legal active bow cannot perform a melee ambush")
   battles["bow-lurk"]=b
 var expired: Dictionary=records.lurk8.duplicate(true)
 var veil := use(expired,expired,"lurk-veil")
 if veil.ok:
  for i in 2:veil.actor.runtime=RulesEffects.new(source).expire_statuses(veil.actor.runtime,"global_round_start").runtime
  check(not kernel.derive_character(veil.actor).snapshot.tags.has("psychic_ambush_ready"),"veil expires after two global round boundaries")
  records.expired_lurk=veil.actor
func test_distinct() -> void:
 for at in [1,4,8,15,20]:
  var r: Dictionary=records["erudite"+str(at)];var engine := TacticalAuras.new(r);var b := encounter(r)
  var powers: Array=kernel.derive_character(r).snapshot.known_powers
  var limit: int=kernel.derive_character(r).snapshot.distinct_power_limit
  check(limit==1+at/4,"Erudite distinct allowance uses permanent Erudite levels")
  var current: Dictionary=r.duplicate(true)
  for n in limit:
   var power: String=powers[n];var ability: String=source.definition("psychic_powers",power).variants[0]
   # Sufficient reserve from legitimate derived capacities, no replenishment in loop.
   var used := use(current,records.foe if source.definition("abilities",ability).targeting.kind=="creature" else current,ability)
   check(used.ok,"each legal distinct identity executes "+str(at)+":"+power)
   if used.ok:current=used.actor
  check(current.runtime.manifested_powers.size()==limit,"identity count persists exactly")
  var unused: String=powers.filter(func(id: String):return not current.runtime.manifested_powers.has(id))[0]
  var blocked: String=source.definition("psychic_powers",unused).variants[0]
  var repeat: String=source.definition("psychic_powers",current.runtime.manifested_powers[0]).variants[0]
  check(not use(current,records.foe,blocked).ok,"new identity denied at cap with affordable resources")
  check(use(current,records.foe,repeat).ok,"repeated identity allowed at cap")
  if at>=4:
   var augmented: String=source.definition("psychic_powers",current.runtime.manifested_powers[0]).variants[1]
   var augmented_use := use(current,records.foe,augmented)
   check(augmented_use.ok and augmented_use.actor.runtime.manifested_powers==current.runtime.manifested_powers,"augmentation shares the original identity")
  var encounter_refresh := RulesEffects.new(source).refresh_resources(current.runtime,kernel.derive_character(current).snapshot.resource_capacities,"encounter")
  check(encounter_refresh.ok and encounter_refresh.runtime.manifested_powers==current.runtime.manifested_powers,"encounter transition does not reset allowance")
  var rest := RulesEffects.new(source).refresh_resources(current.runtime,kernel.derive_character(current).snapshot.resource_capacities,"eligible_rest")
  check(rest.ok and rest.runtime.manifested_powers.is_empty(),"eligible rest resets only legitimate allowance")
  var rested: Dictionary=current.duplicate(true);rested.runtime=rest.runtime
  check(use(rested,records.foe,blocked).ok,"rest allows a new identity")
  var empty: Dictionary=current.duplicate(true);empty.runtime.resources["psychic-points"]=0
  check(not use(empty,records.foe,repeat).ok,"repetition is not free; exhausted PP rejects")
  records["erudite-spent"+str(at)]=current
  b=encounter(current);battles["spent-erudite"+str(at)]=b
  var repeated_command := command(engine,b,repeat,"bandit-blade" if source.definition("abilities",repeat).targeting.kind=="creature" else "a")
  check(repeated_command.ok and int(repeated_command.battle.budget.main)==0,"a repeated identity still spends a real main action")
  if repeated_command.ok:check(not command(engine,repeated_command.battle,repeat,"bandit-blade" if source.definition("abilities",repeat).targeting.kind=="creature" else "a").ok,"repeat cannot reuse an already spent action token")
  check(not command(engine,b,blocked,"a" if source.definition("abilities",blocked).targeting.kind!="creature" else "bandit-blade").ok,"new encounter still cannot bypass distinct limit")
  traces["erudite"+str(at)]={"limit":limit,"used":current.runtime.manifested_powers,"blocked":blocked,"repeat":repeat,"points":current.runtime.resources["psychic-points"]}
func identity_cold() -> void:
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for id in saved.records:
  var r: Dictionary=saved.records[id];var derived := RulesCharacter.new(RulesRecords.registry(r)).derive_character(r)
  check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"exact cold snapshot "+id)
  check(RulesJson.digest(r)==saved.record_hashes[id],"exact cold raw identity "+id)
 for id in saved.battles:
  var engine := TacticalAuras.new(saved.battles[id].units.a.record)
  check(engine.validate(saved.battles[id]).is_empty(),"cold battle valid "+id)
  var result := engine.command(saved.battles[id],saved.next[id]);check(result.ok and result.battle.state_hash==saved.after[id],"cold next command logs/resources/RNG exact "+id)
 for at in [1,4,8,15,20]:
  var r: Dictionary=saved.records["erudite-spent"+str(at)];var powers: Array=kernel.derive_character(r).snapshot.known_powers
  var unused: String=powers.filter(func(id: String):return not r.runtime.manifested_powers.has(id))[0]
  check(not use(r,saved.records.foe,source.definition("psychic_powers",unused).variants[0]).ok,"cold distinct allowance still enforced")
 finish_identity(true)
func finish_identity(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"classes":["ardent","lurk","erudite"],"levels":levels,"traces":traces,"development_fixtures":true,"campaign_xp_injected":false}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof)))
 print("GAME127 ",checks," checks; ",failures," failures");get_tree().quit(1 if failures else 0)
