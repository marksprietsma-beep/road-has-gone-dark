extends "res://tests/ranger_steward/probe.gd"
## Legal development histories. Ordinary earned prestige entry is a separate campaign.
var contracts := {}
var outcomes := {"hits":0,"misses":0,"criticals":0}
func run() -> void:
 base=OS.get_environment("RANGER_STEWARD_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v32.json").ok,"current32 exact registry")
 kernel=RulesCharacter.new(source)
 if OS.get_environment("RANGER_STEWARD_RESTART")=="1":cold();finish_current(true);return
 fixtures.fighter=build("fighter",20)
 for style in ["archery","blade"]:
  var r := kernel.create("ranger-probe",{"STR":13,"DEX":15,"CON":12,"INT":10,"WIS":14,"CHA":8},"heritage-human")
  r.equipment=["shortblade","leathers"]if style=="blade"else["bow","leathers"]
  for at in range(1,21):
   r=more(r,"ranger",1,{"ranger-choice-1":style,"ranger-choice-6":style,"ranger-choice-15":style,"ranger-companion":"leopard"})
   check(not r.is_empty(),"every lawful Ranger level and deliberate style "+style+str(at))
   if r.is_empty():break
   if at in [1,4,6,13,15,16,20]:records[style+str(at)]=r.duplicate(true)
 if failures:finish_current();return
 test_aimed();test_styles();test_quarry();test_casting();test_growth();test_steward();test_creatures();test_summons();test_owner_defeat();test_late()
 persist_current();finish_current()
func encounter(record: Dictionary) -> Dictionary:
 var b := super.encounter(record);var engine := TacticalAuras.new(record)
 b.units.b.position=[0,4];b.units.c.position=[0,5];b.units["bandit-bow"].position=[6,4]
 # The old general-purpose helper rebuilds the renamed owner's pet. Preserve
 # the actual supplied HP/effort/statuses; only alias fixture actor identity.
 if not record.runtime.companions.is_empty():
  var original: Dictionary=record.runtime.companions.values()[0];var pid: String=RulesEntities.identity("a")
  var pet_record: Dictionary=original.record.duplicate(true);pet_record.character_id=pid
  b.units.a.record.runtime.companions={pid:{"definition_id":original.definition_id,"record":pet_record.duplicate(true)}}
  if int(pet_record.runtime.hp)==0:b.units.erase(pid);b.order.erase(pid)
  else:b.units[pid].record=pet_record
 b.cursor=b.order.find("a")
 for pet in b.units.values():
  if pet.has("entity"):pet.position=[1,0]
 b=engine.seal(b);check(engine.validate(b).is_empty(),"valid nonoverlapping development battlefield: "+engine.validate(b))
 return b
func prepare(record: Dictionary,spells: Array) -> Dictionary:
 var r := record.duplicate(true);r.choices.prepared_abilities=spells.duplicate();r.choices.spell_preparations={}
 for id in spells:
  if source.definition("abilities",id).tags.has("prepared"):r.choices.spell_preparations[id]=1
 var d := kernel.derive_character(r);check(d.ok,"legal deliberate spell selection "+JSON.stringify(d.get("errors",[])))
 if d.ok:r.runtime.resources=d.snapshot.resource_capacities.duplicate(true)
 return RulesJson.string_keys(r)
func test_aimed() -> void:
 for at in [1,6,20]:
  var r: Dictionary=records["archery"+str(at)];var engine := TacticalAuras.new(r)
  for die in [1,19,20]:
   var b := encounter(r);b.rng=attack_seed(die);b=engine.seal(b)
   var captured := {}
   var trace := RulesAttackTrace.capture(func():captured.result=execute(engine,b,"aimed-shot","bandit-blade"))
   var used: Dictionary=captured.result;check(used.ok,"actual ranged Aimed Shot "+str(at)+str(die))
   if not used.ok:continue
   check(used.battle.budget=={"main":0,"move":0} and used.battle.units.a.record.runtime.resources==b.units.a.record.runtime.resources,"Aimed Shot pays main+move without invented resolve cost")
   check(not execute(engine,used.battle,"aimed-shot","bandit-blade").ok,"no second shot after spent actions")
   var lines: Array=used.battle.log.slice(b.log.size());var lost: int=int(b.units["bandit-blade"].record.runtime.hp)-int(used.battle.units["bandit-blade"].record.runtime.hp)
   check(trace.size()==1,"exactly one authoritative attack result per Aimed Shot")
   if trace.size()==1:
    if trace[0].hit:check(lost>0 and lines.any(func(line: String):return line.contains(" hits ")),"authoritative hit actually damages target")
    else:check(lost==0 and lines.any(func(line: String):return line.ends_with("miss.")),"authoritative miss deals no damage and is logged")
    check(trace[0].critical==lines.any(func(line: String):return line.contains("(critical)")),"actual critical agrees with authoritative outcome")
    if trace[0].critical:outcomes.criticals+=1
    elif trace[0].hit:outcomes.hits+=1
    else:outcomes.misses+=1
   var replay := execute(engine,JSON.parse_string(JSON.stringify(b)),"aimed-shot","bandit-blade")
   check(replay.ok and replay.battle.state_hash==used.battle.state_hash,"exact attack/HP/cost/log/RNG replay with observer removed")
   battles["aimed"+str(at)+str(die)]=used.battle
  for reason in ["melee","unarmed","natural","manifested","friendly","range","blocked","spent-move","spent-main"]:
   var b := encounter(r);var target := "bandit-blade"
   if reason=="melee":b.units.a.record.equipment=["shortblade","leathers"];b.units.a.weapon="shortblade"
   elif reason=="unarmed":b.units.a.record.equipment=["unarmed"];b.units.a.weapon="unarmed"
   elif reason=="natural":b.units.a.record.runtime.statuses.append({"id":"leopard-form","source":"development-fixture","remaining":3,"expiry":"global_round_start"})
   elif reason=="manifested":
    var hybrid := more(make(1),"soulknife",1);var m := use(hybrid,hybrid,"soulknife-manifest");check(m.ok,"real legal manifestation for negative ranged test")
    if not m.ok:continue
    b=encounter(m.actor)
   elif reason=="friendly":target="b"
   elif reason=="range":b.units.a.position=[0,0];b.units["bandit-blade"].position=[7,5]
   elif reason=="blocked":b.units["bandit-blade"].position=[4,1]
   elif reason=="spent-move":b.budget.move=0
   else:b.budget.main=0
   b=engine.seal(b);var before := RulesJson.digest(b)
   check(not execute(engine,b,"aimed-shot",target).ok,"invalid Aimed Shot rejected "+reason)
   check(before==RulesJson.digest(b),"denial preserves exact state/log/RNG "+reason)
 contracts.ranged_actions=true
func test_styles() -> void:
 for style in ["archery","blade"]:
  for at in [1,6,20]:
   var r: Dictionary=records[style+str(at)];r=r.duplicate(true);r.equipment=["bow","leathers"]if style=="archery"else["shortblade","leathers"]
   var aid: String="ranger-"+style+"-"+str(6 if at>=6 else 1);var cast := use(r,r,aid);check(cast.ok,"paid selected combat style "+aid+str(at))
   if not cast.ok:continue
   check(cast.budget.main==0 and cast.actor.runtime.resources["tracker-resolve"]==r.runtime.resources["tracker-resolve"]-1,"one main and finite tracker resolve")
   if at>=6:check(cast.actor.runtime.temporary_hp==at,"advanced style gives existing nonstacking class-level buffer")
   var engine := TacticalAuras.new(r)
   for weapon in ["bow","shortblade"]:
    var plain := r.duplicate(true);plain.equipment=[weapon,"leathers"]
    var active: Dictionary=cast.actor.duplicate(true);active.equipment=plain.equipment.duplicate()
    var before := stats_of(plain);var after := stats_of(active)
    if style=="archery":
     check(after.damage==before.damage+(2 if weapon=="bow"else 0),"Archery damage matches actual weapon context "+weapon)
     if weapon=="shortblade":
      var b := encounter(plain);b.rng=attack_seed(19);b=engine.seal(b);var x := execute(engine,b,"attack","bandit-blade")
      var y := b.duplicate(true);y.units.a.record.runtime.statuses=active.runtime.statuses.duplicate(true);y=engine.seal(y);var z := execute(engine,y,"attack","bandit-blade")
      check(x.ok and z.ok and x.battle.units["bandit-blade"].record.runtime==z.battle.units["bandit-blade"].record.runtime and x.battle.rng==z.battle.rng,"Archery cannot add hidden melee or reaction damage")
    else:check(after.melee_attack>=before.melee_attack and after.defence>=before.defence,"Blade alternative changes real attack/defence under normal typed stacking")
   if style=="archery":
    var b := encounter(r);b.cursor=b.order.find("bandit-blade");b.rng=attack_seed(19);b=engine.seal(b)
    var styled := b.duplicate(true);styled.units.a.record.runtime.statuses=cast.actor.runtime.statuses.duplicate(true);styled=engine.seal(styled)
    var command := {"actor_id":"bandit-blade","revision":b.revision,"kind":"move","destination":[2,2]}
    var plain_reaction := engine.command(b,command);var style_reaction := engine.command(styled,command)
    check(plain_reaction.ok and style_reaction.ok,"real hostile movement provokes held-bow fallback melee reaction")
    if plain_reaction.ok and style_reaction.ok:
     check(style_reaction.battle.units.a.reaction==0 and style_reaction.battle.units["bandit-blade"].record.runtime==plain_reaction.battle.units["bandit-blade"].record.runtime and style_reaction.battle.rng==plain_reaction.battle.rng,"Archery damage cannot leak into actual bow departure-reaction fallback")
     battles["archery-reaction"+str(at)]=style_reaction.battle
   var expired: Dictionary=cast.actor.duplicate(true)
   for n in 3:expired.runtime=RulesEffects.new(source).expire_statuses(expired.runtime,"global_round_start").runtime
   check(not expired.runtime.statuses.any(func(s: Dictionary):return s.id==aid+"-status"),"style expires at three global boundaries")
   check(expired.runtime.resources["tracker-resolve"]==r.runtime.resources["tracker-resolve"]-1,"expiry never refunds resolve")
   var capacity: Dictionary=kernel.derive_character(r).snapshot.resource_capacities;var spent := r.duplicate(true)
   for n in int(spent.runtime.resources["tracker-resolve"]):
    var out := use(spent,spent,aid);check(out.ok,"finite legal style expenditure")
    if out.ok:spent=out.actor
   check(spent.runtime.resources["tracker-resolve"]==0 and not use(spent,spent,aid).ok,"exhaustion independently rejects style")
   check(RulesEffects.new(source).refresh_resources(spent.runtime,capacity,"encounter").runtime.resources["tracker-resolve"]==0,"encounter cannot refund daily resolve")
   check(RulesEffects.new(source).refresh_resources(spent.runtime,capacity,"eligible_rest").runtime.resources["tracker-resolve"]==capacity["tracker-resolve"],"eligible rest recovers resolve")
   records[style+"-active"+str(at)]=cast.actor;records[style+"-spent"+str(at)]=spent
 contracts.style_limits=true
func test_quarry() -> void:
 var r := make(1);var archers := r.duplicate(true)
 archers.advancement_history[0].specialisations["ranger-quarry-choice"]="archers"
 check(kernel.validate_build(archers).ok,"deliberate permanent alternate quarry is legal")
 for target in ["bandit-blade","bandit-bow"]:
  var engine := TacticalAuras.new(r);var b := encounter(r);b.units[target].position=[2,1]if target=="bandit-blade"else[2,2];b.rng=attack_seed(19);b=engine.seal(b)
  var x := execute(engine,b,"attack",target);var other := b.duplicate(true);other.units.a.record.advancement_history[0].specialisations["ranger-quarry-choice"]="archers";other=engine.seal(other);var y := execute(engine,other,"attack",target)
  check(x.ok and y.ok,"both actual permanent quarry attacks execute")
  if x.ok and y.ok:check(y.battle.units[target].record.runtime.hp==x.battle.units[target].record.runtime.hp+(2 if target=="bandit-blade"else 0),"raider versus archer actual target-dependent damage "+target)
  check(RulesCareer.quarry_matches(kernel.derive_character(archers).snapshot,b.units[target],source)==(target=="bandit-bow"),"quarry classification uses hostile ranged loadout")
  battles["quarry-"+target]=y.battle if y.ok else b
 records.archer_quarry=archers;contracts.quarry=true
func test_casting() -> void:
 for spec in [[4,"ranger-vine-snare"],[6,"ranger-storm-bolt"],[13,"ranger-tier5-tempest"],[16,"ranger-tier6-tempest"]]:
  var r := prepare(records["archery"+str(spec[0])],[spec[1]]);var aid: String=spec[1];var engine := TacticalAuras.new(r)
  for die in [1,20]:
   var b := encounter(r);b.rng=attack_seed(die);b=engine.seal(b)
   var out := execute(engine,b,aid,"bandit-blade");check(out.ok,"actual prepared nature magic "+aid+str(die))
   if not out.ok:continue
   check(out.battle.log.any(func(line: String):return line.contains("resisted"if die==20 else"failed")),"actual successful/failed Reflex outcome is recorded "+aid+str(die))
   if aid=="ranger-vine-snare":check(out.battle.units["bandit-blade"].record.runtime.statuses.any(func(s: Dictionary):return s.id=="entangled")== (die==1),"Reflex success genuinely negates nature control")
   else:check(out.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp,"nature damage executes after failed or successful half save")
   for pool in source.definition("abilities",aid).cost.resources:check(out.battle.units.a.record.runtime.resources[pool]==r.runtime.resources[pool]-1,"nature slot and exact prepared copy both spent "+pool)
   check(not execute(engine,out.battle,aid,"bandit-blade").ok,"spell and weapon actions compete for the same main")
   battles[aid+str(die)]=out.battle
  var spent := r.duplicate(true);var ability := source.definition("abilities",aid)
  for pool in ability.cost.resources:
   var empty := r.duplicate(true);empty.runtime.resources[pool]=0;check(not use(empty,fixtures.fighter,aid).ok,"no borrowing an empty nature slot/copy "+pool)
  var used := use(spent,fixtures.fighter,aid);check(used.ok,"copy exhaustion witness")
  if used.ok:
   check(not use(used.actor,fixtures.fighter,aid).ok,"single prepared copy is exhausted even if shared slots remain")
   var capacities: Dictionary=kernel.derive_character(r).snapshot.resource_capacities
   var rest := RulesEffects.new(source).refresh_resources(used.actor.runtime,capacities,"eligible_rest");check(rest.ok,"nature rest succeeds")
   for pool in ability.cost.resources:check(rest.runtime.resources[pool]==capacities[pool],"eligible rest restores exact copies and slots")
   records[aid+"-spent"]=used.actor
  records[aid]=r
 var hybrid_base := kernel.create("ranger-wizard",{"STR":10,"DEX":15,"CON":12,"INT":13,"WIS":14,"CHA":8},"heritage-human")
 var hybrid := prepare(more(more(hybrid_base,"ranger",4),"wizard",1),["ranger-thorn-dart","wizard-arcane-bolt"])
 if not hybrid.is_empty():
  var out := use(hybrid,fixtures.fighter,"ranger-thorn-dart");check(out.ok,"real arcane/nature multiclass casts its nature spell")
  if out.ok:
   for pool in hybrid.runtime.resources:
    if str(pool).begins_with("wizard-"):check(out.actor.runtime.resources[pool]==hybrid.runtime.resources[pool],"nature casting preserves unrelated wizard resource "+pool)
   records.hybrid=out.actor
  var arcane := use(hybrid,fixtures.fighter,"wizard-arcane-bolt");check(arcane.ok,"dual nature/arcane build genuinely casts from both traditions")
  if arcane.ok:
   for pool in hybrid.runtime.resources:
    if str(pool).begins_with("ranger-"):check(arcane.actor.runtime.resources[pool]==hybrid.runtime.resources[pool],"arcane casting preserves unrelated nature resource "+pool)
 var healer := prepare(records.archery4,["ranger-nature-cure"]);var engine := TacticalAuras.new(healer);var b := encounter(healer);var pid: String="a:companion"
 b.units[pid].record.runtime.hp=int(engine.stats(b.units[pid]).HP)-1;b=engine.seal(b)
 var healed := execute(engine,b,"ranger-nature-cure",pid);check(healed.ok,"prepared nature recovery reaches actual owned companion")
 if healed.ok:check(healed.battle.units[pid].record.runtime.hp==int(engine.stats(b.units[pid]).HP),"nature recovery caps at real pet maximum and captures ownership")
 var downed := b.duplicate(true);downed.units[pid].record.runtime.hp=0;downed=engine.seal(downed)
 check(not execute(engine,downed,"ranger-nature-cure",pid).ok,"ordinary nature cure cannot revive a defeated pet in battle")
 if healed.ok:battles.nature_healing=healed.battle
 records.nature_healer=healer;contracts.nature_casting=true
func test_growth() -> void:
 for hp in [0,1]:
  var r := make(4,"archery","leopard");var id: String=RulesEntities.identity(r.character_id);var pet: Dictionary=r.runtime.companions[id].record
  pet.runtime.hp=hp;pet.runtime.resources["creature-effort"]=0
  var old_max: int=kernel.derive_character(pet).snapshot.stats.HP
  var out := kernel.preview_advancement(r,kernel.suggested_choice(r,"ranger").choice);check(out.ok,"legal growth of injured or defeated permanent pet")
  if not out.ok:continue
  var grown: Dictionary=out.candidate.runtime.companions[id].record;var new_max: int=kernel.derive_character(grown).snapshot.stats.HP
  check(grown.character_id==pet.character_id and out.candidate.runtime.companions[id].definition_id=="leopard","growth retains same permanent identity/definition")
  check(grown.runtime.hp==(0 if hp==0 else maxi(0,new_max-old_max+hp)),"growth preserves downed state or living damage deficit")
  check(grown.runtime.resources["creature-effort"]==0,"growth never refunds spent pet effort")
  var rested: Dictionary=out.candidate.duplicate(true);RulesEntities.recover_companions(rested,source)
  check(rested.runtime.companions[id].record.runtime.hp==new_max and rested.runtime.companions[id].record.runtime.resources["creature-effort"]>0,"only eligible recovery restores pet health/effort")
  var entry := encounter(out.candidate);var pid: String=RulesEntities.identity("a")
  check(entry.units.a.record.runtime.companions[pid].record.runtime.hp==grown.runtime.hp,"next actual encounter retains supplied pet health")
  check(entry.units.has(pid)==(hp>0),"downed pet is not silently respawned by encounter creation")
  if hp>0:check(entry.units[pid].record.runtime.resources["creature-effort"]==0,"next encounter never restores spent pet effort")
  records["grown-"+str(hp)]=out.candidate
 contracts.persistent_growth=true
func steward(level := 5,training := "swift",pet := "leopard") -> Dictionary:
 var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new();planner.source=source;planner.kernel=kernel
 var goals: Dictionary=planner.requirements("beast-steward",0);var r := kernel.create("steward-probe",{"STR":13,"DEX":15,"CON":12,"INT":10,"WIS":14,"CHA":8},"heritage-human")
 for n in 5:
  var out: Dictionary=planner.advance(r,"ranger",goals);check(out.ok,"permanent prestige prerequisite history "+str(n)+JSON.stringify(out.get("errors",[])))
  if not out.ok:planner.free();return {}
  var choice: Dictionary=out.candidate.advancement_history.back().duplicate(true);choice.erase("level")
  if choice.specialisations.has("ranger-companion"):choice.specialisations["ranger-companion"]=pet
  out=kernel.preview_advancement(r,choice);check(out.ok,"selected permanent creature retained")
  if not out.ok:planner.free();return {}
  r=out.candidate
 planner.free()
 return more(r,"beast-steward",level,{"beast-steward-training":training})
func test_steward() -> void:
 var prefix := steward(0);check(kernel.available_advancement(prefix).classes["beast-steward"].ok,"durable class/feat/ranks/bond enable earned prestige option")
 records.steward_prefix=prefix
 var before := RulesJson.digest(prefix);var decline := more(prefix,"ranger",1)
 check(not decline.is_empty() and RulesJson.digest(prefix)==before and not kernel.derive_character(decline).snapshot.class_levels.has("beast-steward"),"qualification is optional; lawful decline never auto-assigns prestige")
 check(not kernel.starting_classes().has("beast-steward"),"prestige never appears as starting class")
 var fresh := kernel.create("forged-start",prefix.base_attributes,prefix.ancestry_ref);var proposal := kernel.suggested_choice(fresh,"ranger")
 proposal.choice.class_id="beast-steward";check(not kernel.preview_advancement(fresh,proposal.choice).ok,"forged prestige-first payload rejected authoritatively")
 for reason in ["feat","ranks","bond"]:
  var bad := make(5)if reason=="feat"else build("wizard",5)if reason=="bond"else make(4)
  bad.runtime.granted_features=["beast-stewardship-feature","ranger-wolf-bond"]
  check(not kernel.available_advancement(bad).classes["beast-steward"].ok,"temporary grants cannot replace permanent prestige prerequisites "+reason)
 for training in ["swift","enduring"]:
  for level in [1,3,5]:
   var r := steward(level,training);check(not r.is_empty(),"all supported steward levels and training alternatives "+training+str(level))
   if r.is_empty():continue
   var pet: Dictionary=r.runtime.companions.values()[0].record
   check(pet.advancement_history.size()==2+level+(1 if training=="swift"else 0),"Ranger5 pet growth includes actual prestige and optional swift increment")
   records["steward-"+training+str(level)]=r
   if level==5:check(not kernel.available_advancement(r).classes["beast-steward"].ok,"prestige stops at its authored five-level cap")
   for aid in ["steward-rally"]+(["steward-drive-3"]if level>=3 else[])+(["steward-drive-5"]if level==5 else[]):
    var b := encounter(r);var engine := TacticalAuras.new(r);var pid: String=RulesEntities.identity("a")
    b.units[pid].record.runtime.hp=1;b=engine.seal(b)
    var out := execute(engine,b,aid,pid);check(out.ok,"actual owner command affects persistent pet "+aid)
    if not out.ok:continue
    check(out.battle.budget.main==0 and out.battle.units.a.record.runtime.resources["beast-steward-commands"]==b.units.a.record.runtime.resources["beast-steward-commands"]-1,"command spends owner main and exactly one finite charge")
    check(out.battle.units.a.record.runtime.companions[pid].record==out.battle.units[pid].record,"sole ownership record captures real commanded actor")
    if aid=="steward-rally":check(out.battle.units[pid].record.runtime.hp==mini(int(engine.stats(b.units[pid]).HP),4+level),"real capped rally heals target by3+prestige level")
    else:
     check(out.battle.units[pid].record.runtime.temporary_hp==(6 if aid.ends_with("3")else 10)+level,"drive3/5 give distinct scaled nonstacking buffers")
     check(engine.stats(out.battle.units[pid]).melee_attack>engine.stats(b.units[pid]).melee_attack and engine.stats(out.battle.units[pid]).will>engine.stats(b.units[pid]).will,"Pack Drive actually improves companion attack and Will")
    var negative := b.duplicate(true);negative.units.a.record.runtime.resources["beast-steward-commands"]=0;negative=engine.seal(negative)
    check(not execute(engine,negative,aid,pid).ok,"empty command pool denied independently")
    check(not execute(engine,b,aid,"bandit-blade").ok,"cannot command hostile creature")
    for position in [[7,5],[4,1]]:
     var invalid := b.duplicate(true);invalid.units[pid].position=position;invalid=engine.seal(invalid);var unchanged := RulesJson.digest(invalid)
     check(not execute(engine,invalid,aid,pid).ok and RulesJson.digest(invalid)==unchanged,"companion command obeys range/line of sight without resource or RNG loss")
    battles[training+aid+str(level)]=out.battle
 for training in ["swift","enduring"]:
  var high := more(records["steward-"+training+"5"],"ranger",10,{"ranger-choice-6":"archery","ranger-choice-15":"archery"})
  check(not high.is_empty() and high.advancement_history.size()==20,"ordered Ranger15/Steward5 reaches total20 "+training)
  records["steward-"+training+"20"]=high
 var swift: Dictionary=records["steward-swift1"];var enduring: Dictionary=records["steward-enduring1"]
 check(stats_of(swift).initiative>stats_of(enduring).initiative and stats_of(enduring).fortitude>stats_of(swift).fortitude,"Swift and Enduring choices have different actual initiative/save statistics")
 var received := {}
 for training in ["swift","enduring"]:
  var r: Dictionary=records["steward-"+training+"1"];var engine := TacticalAuras.new(r);var b := encounter(r)
  b.cursor=b.order.find("bandit-blade");b.rng=attack_seed(19);b=engine.seal(b)
  var out := execute(engine,b,"attack","a");check(out.ok,"actual incoming attack tests steward training defence")
  if out.ok:received[training]=int(b.units.a.record.runtime.hp)-int(out.battle.units.a.record.runtime.hp);battles["training-defence-"+training]=out.battle
 check(received.has_all(["swift","enduring"]) and received.enduring==received.swift-2,"Enduring resistance prevents exactly2 physical damage from the same attack/RNG")
 var r: Dictionary=records["steward-swift5"].duplicate(true);var cap: Dictionary=kernel.derive_character(r).snapshot.resource_capacities
 for n in int(r.runtime.resources["beast-steward-commands"]):
  var out := use(r,r,"steward-rally");check(out.ok,"finite command expenditure")
  if out.ok:r=out.actor
 check(not use(r,r,"steward-rally").ok,"no unlimited command healing")
 check(RulesEffects.new(source).refresh_resources(r.runtime,cap,"encounter").runtime.resources["beast-steward-commands"]==0,"encounter cannot refresh command pool")
 check(RulesEffects.new(source).refresh_resources(r.runtime,cap,"eligible_rest").runtime.resources["beast-steward-commands"]==cap["beast-steward-commands"],"eligible rest recovers finite command capacity")
 records.steward_spent=r;contracts.prestige=true;contracts.commands=true
func test_creatures() -> void:
 for definition in ["wolf","bear","leopard","boar","stag","ancestor-sentinel","briar-beast"]:
  var r := make(8,"archery",definition);var b := encounter(r);var engine := TacticalAuras.new(r);var pid: String=RulesEntities.identity("a")
  check(b.units.has(pid) and b.units[pid].entity.kind=="companion" and b.units[pid].entity.definition_id==definition,"actual selected permanent actor exists "+definition)
  b.units[pid].position=[1,1];b.units.a.position=[0,1];b.cursor=b.order.find(pid);b.rng=attack_seed(19);b=engine.seal(b)
  var attack := execute(engine,b,"attack","bandit-blade");check(attack.ok,"pet has real attack turn "+definition)
  if attack.ok:check(attack.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp and attack.battle.budget.main==0,"actual natural weapon damage and main expenditure "+definition)
  var options: Dictionary=engine.paths(b,b.units[pid]);var dest: Array=[]
  for path in options.values():
   if path.size()>1 and path.back()!=[0,1]:dest=path.back();break
  check(not dest.is_empty(),"pet movement uses existing grid paths "+definition)
  if not dest.is_empty():
   var moved := engine.command(b,{"actor_id":pid,"revision":b.revision,"kind":"move","destination":dest});check(moved.ok and moved.battle.budget.move==0,"pet spends own movement token "+definition)
  var wrong := b.duplicate(true);wrong.budget.main=0;wrong=engine.seal(wrong);check(not execute(engine,wrong,"attack","bandit-blade").ok,"pet cannot attack after spent main "+definition)
  if definition not in ["wolf","bear"]:
   var aid: String=definition+"-special";var target: String="bandit-blade"if source.definition("abilities",aid).targeting.kind=="creature"else pid if source.definition("abilities",aid).targeting.kind=="self"else"a"
   var special_board := b.duplicate(true);special_board.rng=attack_seed(1);special_board=engine.seal(special_board)
   var special := execute(engine,special_board,aid,target);check(special.ok,"distinct selected creature special action "+definition)
   if special.ok:
    check(special.battle.units[pid].record.runtime.resources["creature-effort"]==b.units[pid].record.runtime.resources["creature-effort"]-1,"pet special spends its own effort rather than owner's commands")
    check(special.battle.units[target].record.runtime.temporary_hp!=b.units[target].record.runtime.temporary_hp or special.battle.units[target].record.runtime.statuses!=b.units[target].record.runtime.statuses,"distinct creature power produces actual target buffer/control "+definition)
    var empty := special_board.duplicate(true);empty.units[pid].record.runtime.resources["creature-effort"]=0;empty=engine.seal(empty)
    check(not execute(engine,empty,aid,target).ok,"exhausted pet effort cannot borrow owner resources "+definition)
    if definition=="briar-beast":
     var saved := special_board.duplicate(true);saved.rng=attack_seed(20);saved=engine.seal(saved);var resisted := execute(engine,saved,aid,target)
     check(resisted.ok and resisted.battle.units[target].record.runtime.statuses==saved.units[target].record.runtime.statuses,"successful Reflex negates actual creature root while still spending its effort")
    battles["pet-special-"+definition]=special.battle
  var miss_board := b.duplicate(true);miss_board.rng=attack_seed(1);miss_board=engine.seal(miss_board);var miss := execute(engine,miss_board,"attack","bandit-blade")
  check(miss.ok and miss.battle.units["bandit-blade"].record.runtime.hp==b.units["bandit-blade"].record.runtime.hp and miss.battle.budget.main==0,"natural attack can miss and still spends pet main "+definition)
  var departure := engine.command(b,{"actor_id":pid,"revision":b.revision,"kind":"move","destination":[1,2]})
  check(departure.ok and departure.battle.units["bandit-blade"].reaction==0 and departure.battle.units[pid].record.runtime.hp<b.units[pid].record.runtime.hp,"owned movement provokes the same paid hostile departure reaction "+definition)
  if departure.ok:battles["pet-move-"+definition]=departure.battle
  if attack.ok:battles["pet-attack-"+definition]=attack.battle
  records["owner-"+definition]=r
 contracts.creature_actions=true
func test_summons() -> void:
 var r := prepare(more(make(4,"archery","leopard"),"druid",1),["druid-summon-sentinel"])
 var engine := TacticalAuras.new(r);var b := encounter(r);var out := execute(engine,b,"druid-summon-sentinel");check(out.ok,"real multiclass temporary summon coexists with single permanent companion")
 if not out.ok:return
 var summons: Array=out.battle.units.values().filter(func(u: Dictionary):return u.get("entity",{}).get("kind")=="summon")
 check(summons.size()==1 and out.battle.units.a.record.runtime.companions.size()==1,"temporary actor never overwrites permanent ownership")
 var sid: String=summons[0].id;var pid: String=RulesEntities.identity("a")
 check(sid!=pid and out.battle.units[sid].entity.remaining==3,"distinct summon identity and bounded duration")
 var again: Dictionary=out.battle.duplicate(true);again.budget.main=1;again.units.a.record.runtime.resources=r.runtime.resources.duplicate(true);again=engine.seal(again)
 var before := RulesJson.digest(again);check(not execute(engine,again,"druid-summon-sentinel").ok and RulesJson.digest(again)==before,"duplicate summon denied without lost state/RNG")
 var active: Dictionary=out.battle.duplicate(true)
 for n in 3:CombatEntities.round_start(engine,active)
 active=engine.seal(active);check(not engine.alive(active.units[sid]) and engine.alive(active.units[pid]),"summon expiry leaves permanent pet active")
 var dismissed: Dictionary=out.battle.duplicate(true);dismissed.budget.main=1;dismissed=engine.seal(dismissed)
 var gone := execute(engine,dismissed,"dismiss",sid);check(gone.ok and not engine.alive(gone.battle.units[sid]) and engine.alive(gone.battle.units[pid]),"costed summon dismissal preserves the owned companion")
 battles.summon_and_companion=out.battle;contracts.summons=true
func test_owner_defeat() -> void:
 var r := make(8,"archery","leopard");var engine := TacticalAuras.new(r);var b := encounter(r);var pid: String=RulesEntities.identity("a")
 b.units.a.record.runtime.hp=1;b.cursor=b.order.find("bandit-blade");b.rng=attack_seed(19);b=engine.seal(b)
 var out := execute(engine,b,"attack","a");check(out.ok and out.battle.units.a.record.runtime.hp==0,"actual hostile attack defeats owner")
 if not out.ok:return
 var pet_hp: int=out.battle.units[pid].record.runtime.hp;var round: int=out.battle.round
 for n in b.order.size()+1:
  if out.battle.round>round:break
  out=execute(engine,out.battle,"end");check(out.ok,"ordinary turn boundaries after owner defeat")
 check(not engine.alive(out.battle.units[pid]) and out.battle.units[pid].record.runtime.hp==pet_hp,"existing global-round withdrawal deactivates pet without killing or duplicating it")
 check(out.battle.units.a.record.runtime.companions[pid].record==out.battle.units[pid].record,"fallen owner still captures exact living pet record")
 battles.owner_defeat=out.battle;contracts.owner_survival=true
func test_late() -> void:
 for at in [13,16,20]:
  var r: Dictionary=records["archery"+str(at)];var engine := TacticalAuras.new(r);var b := encounter(r);b.rng=attack_seed(19);b=engine.seal(b)
  var id := "ranger-master-"+str(at);var out := execute(engine,b,id,"bandit-blade");check(out.ok,"actual late Ranger technique "+id)
  if out.ok:
   var cost: int=source.definition("abilities",id).cost.resources["tracker-resolve"]
   check(out.battle.units.a.record.runtime.resources["tracker-resolve"]==b.units.a.record.runtime.resources["tracker-resolve"]-cost and out.battle.budget.main==0,"late technique spends actual scaling resolve and main")
   check(out.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp,"late technique delivers real authoritative weapon damage")
   battles["late"+str(at)]=out.battle
 check(stats_of(records.archery20).defence>stats_of(records.blade20).defence and stats_of(records.blade20).save_dc==stats_of(records.archery20).save_dc+2,"original late Archery defence versus Blade nature DC choices have distinct mechanical results")
 var plain := prepare(records.archery20,["ranger-tier6-tempest"]);var blade := prepare(records.blade20,["ranger-tier6-tempest"])
 var engine := TacticalAuras.new(plain);var b := encounter(plain);var dc := 16+int(floor(float(kernel.derive_character(plain).snapshot.attributes.WIS-10)/2.0))+int(stats_of(plain).save_dc)
 var die: int=dc-int(engine.stats(b.units["bandit-blade"]).reflex);check(die>=1 and die<=20,"lawful opposed-save threshold exists")
 if die>=1 and die<=20:
  b.rng=attack_seed(die);b=engine.seal(b);var first := execute(engine,b,"ranger-tier6-tempest","bandit-blade")
  var second_board := encounter(blade);second_board.rng=b.rng.duplicate(true);second_board=engine.seal(second_board);var second := execute(engine,second_board,"ranger-tier6-tempest","bandit-blade")
  check(first.ok and second.ok,"both late style builds execute selected nature magic")
  if first.ok and second.ok:
   check(not first.battle.units["bandit-blade"].record.runtime.statuses.any(func(s: Dictionary):return s.id=="slowed") and second.battle.units["bandit-blade"].record.runtime.statuses.any(func(s: Dictionary):return s.id=="slowed"),"Blade mastery DC changes a real successful save into a failed control outcome with identical RNG")
   check(second.battle.units["bandit-blade"].record.runtime.hp<first.battle.units["bandit-blade"].record.runtime.hp,"late choice changes actual saved damage")
   battles.late_style_save=second.battle
 contracts.late_progression=true
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
 print("RANGER_STEWARD ",JSON.stringify(proof))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
