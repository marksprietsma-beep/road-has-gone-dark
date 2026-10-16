extends "res://tests/character_wave_four/cohort_driver.gd"
## Focused new mechanics; inherited helpers construct lawful histories, never production XP.
var channel_battle := {}
func run() -> void:
 base=OS.get_environment("GAME112W5_TEST_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v15.json")
 check(loaded.ok,"v15 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME112W5_RESTART")=="1":
  var saved: Dictionary=WorldOriginLore.read_json(base.path_join("saved.json"))
  for id in saved.records:
   var derived := kernel.derive_character(saved.records[id])
   check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"exact cold character "+id)
  var engine := TacticalAuras.new(saved.records.duskblade)
  check(engine.validate(saved.channel_battle).is_empty(),"actual channel battle reload valid")
  var next := {"actor_id":engine.current(saved.channel_battle).id,"revision":saved.channel_battle.revision,"kind":"end"}
  var replay := engine.command(saved.channel_battle,next)
  check(replay.ok and replay.battle.state_hash==saved.after_end_hash,"cold channel battle next action/RNG exact")
  var shaman: Dictionary=saved.records.retrieval_spent
  var alternate: Dictionary=shaman.duplicate(true);alternate.choices.prepared_abilities=["spirit-shaman-spirit-rebuke-1"]
  check(not RulesWaveFive.commit_retrieval(shaman,alternate,source).ok,"cold retrieval permit remains spent")
  finish();return
 for cls in ["duskblade","spirit-shaman"]:
  fixtures[cls]=build(cls,20)
  check(not fixtures[cls].is_empty(),"complete new1–20 track "+cls)
 if failures:finish();return
 fixtures.fighter=build("fighter",20)
 test_attack_observer();test_channel_delivery();test_retrieval();test_spell_cohort();test_new_paths();test_wave_five_feats();test_supporting_content()
 finish()
func select(record: Dictionary,id: String) -> Dictionary:
 var result: Dictionary=record.duplicate(true)
 result.choices.prepared_abilities=[id];result.choices.spell_preparations={}
 result.runtime.resources=kernel._replay(result).context.capacities.duplicate()
 return result
func attack_seed(roll: int,weapon_roll: int=0,conceal: bool=false) -> Dictionary:
 for n in 50000:
  var rng := RulesRng.initial("wave-five-hit-"+str(n))
  var first := RulesRng.roll("1d100"if conceal else"1d20",rng)
  if conceal:
   if first.total<=50:return rng
  elif first.total==roll:
   if weapon_roll==0 or RulesRng.roll("1d6",first.rng).total==weapon_roll:return rng
 check(false,"deterministic test seed found");return RulesRng.initial("missing")
func encounter(record: Dictionary) -> Dictionary:
 var caster: Dictionary=record.duplicate(true);caster.character_id="a"
 if caster.equipment.is_empty():caster.equipment=source.definition("classes",caster.advancement_history[0].class_id).recommended_equipment.duplicate()
 caster.runtime.companions={};RulesEntities.synchronize(caster,source)
 var records := {"a":caster}
 for id in ["b","c"]:
  records[id]=build("fighter",1);records[id].character_id=id;records[id].equipment=["shortblade"]
 var state := {"world_ref":{},"origin":{},"party_ids":["a","b","c"],"party":{"members":[{"name":"Duskblade"},{"name":"Ally"},{"name":"Ally"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":records}}
 var engine := TacticalAuras.new(state);var battle := engine.create(state,"wave-five-channel")
 var target: Dictionary=fixtures.fighter.duplicate(true);target.character_id="bandit-blade";target.equipment=["shortblade"]
 battle.units["bandit-blade"].record=target;battle.units["bandit-blade"].position=[2,1];battle.units.a.position=[1,1]
 battle.cursor=battle.order.find("a");return engine.seal(battle)
func order(battle: Dictionary,kind: String) -> Dictionary:
 return {"actor_id":"a","revision":battle.revision,"kind":kind,"target_id":"bandit-blade"}
func test_attack_observer() -> void:
 var rng := RulesRng.initial("scoped-observation");var before := RulesJson.digest(rng);var critical: Dictionary=source.rule("critical")
 var expected := RulesRng.attack_roll(4,13,critical,rng)
 var observed := RulesAttackTrace.capture(func():
  var thread := Thread.new()
  check(thread.start(func():return RulesRng.attack_roll(4,13,critical,rng))==OK,"parallel observer fixture started")
  thread.wait_to_finish()
  check(RulesRng.attack_roll(4,13,critical,rng)==expected,"observer leaves exact authority return unchanged"))
 check(observed==[expected.event],"only this thread's authoritative result captured")
 check(RulesJson.digest(rng)==before,"observer never mutates or consumes source RNG")
 var empty := RulesAttackTrace.capture(func():pass)
 check(empty.is_empty(),"scope removed after prior observation")
func test_channel_delivery() -> void:
 var caster := select(build("duskblade",3),"duskblade-searing-grasp")
 var engine := TacticalAuras.new(caster)
 for hit in [true,false]:
  var battle := encounter(caster);battle.rng=attack_seed(19 if hit else 1);battle=engine.seal(battle)
  var before := RulesJson.digest(battle)
  var control := engine.command(battle,order(battle,"attack"))
  var cast := engine.command(battle,order(battle,"channel-duskblade-searing-grasp"))
  check(control.ok and cast.ok,"channel hit/miss commands accepted "+str(hit))
  if not cast.ok or not control.ok:continue
  check(RulesJson.digest(battle)==before,"channel input untouched")
  check(cast.battle.budget.main==0 and cast.battle.budget.move==1,"exact one main action, movement retained")
  check(int(cast.battle.units.a.record.runtime.resources["duskblade-slots-1"])==int(battle.units.a.record.runtime.resources["duskblade-slots-1"])-1,"slot paid exactly once even on miss")
  if hit:
   var original := RulesEffects.new(source).use_ability(control.battle.units.a.record,control.battle.units["bandit-blade"].record,"duskblade-searing-grasp",{"main":1,"move":1,"reaction":1},control.battle.rng)
   check(original.ok,"independent original spell authority")
   check(cast.battle.units["bandit-blade"].record.runtime==original.target.runtime and cast.battle.rng==original.rng,"one authoritative weapon hit then one original spell; no duplicate damage/RNG")
   channel_battle=cast.battle
  else:
   check(cast.battle.units["bandit-blade"].record==control.battle.units["bandit-blade"].record and cast.battle.rng==control.battle.rng,"miss has no spell effect or spell RNG")
  var replay := engine.command(JSON.parse_string(JSON.stringify(battle)),order(battle,"channel-duskblade-searing-grasp"))
  check(replay.ok and replay.battle.state_hash==cast.battle.state_hash,"exact JSON channel replay")
  check(engine.validate(cast.battle).is_empty(),"channel battle validates")
 var invalids := ["unknown","empty-slots","spent-action","bow","friendly","range","blocked","form","forged-weapon"]
 for reason in invalids:
  var battle := encounter(caster);var input := order(battle,"channel-duskblade-searing-grasp")
  match reason:
   "unknown":battle.units.a.record.choices.prepared_abilities=[]
   "empty-slots":battle.units.a.record.runtime.resources["duskblade-slots-1"]=0
   "spent-action":battle.budget.main=0
   "bow":battle.units.a.weapon="bow";battle.units.a.record.equipment=["bow","mail"]
   "friendly":input.target_id="b"
   "range":battle.units["bandit-blade"].position=[6,1]
   "blocked":
    battle.units.a.position=[2,1];battle.units["bandit-blade"].position=[4,1]
    # Build the larger body lawfully: changing ancestry after allocating skills
    # can invalidate the saved INT-dependent advancement budget.
    var large := select(build("duskblade",3,"heritage-ogre"),"duskblade-searing-grasp")
    large.character_id="a";large.equipment=caster.equipment.duplicate()
    battle.units.a.record=large
   "form":battle.units.a.record.runtime.statuses=[{"id":"leopard-form","source":"fixture","remaining":3,"expiry":"global_round_start"}]
   "forged-weapon":battle.units.a.weapon="boar-tusks"
  battle=engine.seal(battle);var before := RulesJson.digest(battle)
  check(not engine.command(battle,input).ok,"illegal channel rejected "+reason)
  check(RulesJson.digest(battle)==before,"invalid command preserves original "+reason)
 var concealed := encounter(caster);concealed.units["bandit-blade"].record.runtime.statuses=[{"id":"perfect-shadow","source":"fixture","remaining":2,"expiry":"global_round_start"}];concealed.rng=attack_seed(1,0,true);concealed=engine.seal(concealed)
 var miss := engine.command(concealed,order(concealed,"channel-duskblade-searing-grasp"))
 check(miss.ok and miss.battle.units["bandit-blade"].record.runtime.hp==concealed.units["bandit-blade"].record.runtime.hp,"concealment prevents delivery")
 if miss.ok:check(miss.battle.rng==RulesRng.roll("1d100",concealed.rng).rng,"concealment miss consumes no attack/spell roll")
 var resisted := encounter(caster);resisted.units["bandit-blade"].record.runtime.statuses=[{"id":"iron-carapace","source":"fixture","remaining":3,"expiry":"global_round_start"}];resisted.rng=attack_seed(19,1);resisted=engine.seal(resisted)
 var strike := engine.command(resisted,order(resisted,"attack"));var channel := engine.command(resisted,order(resisted,"channel-duskblade-searing-grasp"))
 check(strike.ok and channel.ok,"fully resisted weapon fixture accepted")
 if strike.ok and channel.ok:
  check(strike.battle.units["bandit-blade"].record.runtime.hp==resisted.units["bandit-blade"].record.runtime.hp,"weapon loses zero HP against actual resistance")
  check(channel.battle.units["bandit-blade"].record.runtime.hp<strike.battle.units["bandit-blade"].record.runtime.hp,"authoritative hit delivers magic despite zero physical HP loss")
func test_retrieval() -> void:
 var shaman := select(build("spirit-shaman",1),"spirit-shaman-spirit-rebuke-1")
 var id: String="spirit-shaman-spirit-refuge-1"
 var alternate: Dictionary=shaman.duplicate(true);alternate.choices.prepared_abilities=[id]
 check(RulesWaveFive.commit_retrieval(shaman,alternate,source).ok,"permitted bounded retrieval change")
 check(alternate.runtime.resources["spirit-retrieval"]==0 and alternate.runtime.resources["spirit-shaman-slots-1"]==shaman.runtime.resources["spirit-shaman-slots-1"],"selection spends permit, never refills slots")
 var again: Dictionary=alternate.duplicate(true);again.choices.prepared_abilities=shaman.choices.prepared_abilities.duplicate()
 check(not RulesWaveFive.commit_retrieval(alternate,again,source).ok,"second selection before rest rejected")
 var effect := RulesEffects.new(source);var capacity: Dictionary=kernel.derive_character(alternate).snapshot.resource_capacities
 check(effect.refresh_resources(alternate.runtime,capacity,"encounter").runtime.resources["spirit-retrieval"]==0,"encounter cannot refresh retrieval")
 var rested: Dictionary=alternate.duplicate(true);rested.runtime=effect.refresh_resources(rested.runtime,capacity,"eligible_rest").runtime
 check(RulesWaveFive.commit_retrieval(rested,again,source).ok,"eligible rest refreshes one retrieval")
 fixtures.retrieval_spent=alternate
 var draft := CharacterBuilderRecords.definition(shaman)
 shaman.equipment=["staff","leathers"];draft=CharacterBuilderRecords.definition(shaman)
 var created := CharacterBuilderRecords.create("new-spirit",draft,{"rules_ref":source.rules_ref()})
 check(created.ok,"real starting payload Spirit Shaman "+JSON.stringify(created.get("errors",[])))
 if created.ok:check(created.candidate.runtime.resources["spirit-retrieval"]==0,"creation consumes initial choice permit")
 var overflow: Dictionary=shaman.duplicate(true);overflow.choices.prepared_abilities=["spirit-shaman-spirit-rebuke-1","spirit-shaman-spirit-refuge-1","spirit-shaman-listening-ward"]
 check(not kernel.validate_build(overflow).ok,"retrieval pool is bounded")
 check(not use(alternate,build("fighter",1),"spirit-shaman-spirit-rebuke-1").ok,"different retrieved build cannot cast old offensive option")
 check(use(alternate,build("fighter",1),id).ok,"different retrieved build has real support option")
func test_spell_cohort() -> void:
 var unique := {};var shapes := {}
 for cls in ["duskblade","spirit-shaman"]:
  for id in kernel.derive_character(fixtures[cls]).snapshot.abilities:
   var a := source.definition("abilities",id)
   if a.get("casting_class")!=cls or a.has("channel_spell"):continue
   var caster := select(fixtures[cls],id);var target := build("fighter",1);target.runtime.hp=1
   if a.targeting.kind=="self":target=caster
   var cast := use_at_save(caster,target,id,1)
   check(cast.ok,"every new spell executes "+id+JSON.stringify(cast.get("errors",[])))
   if not cast.ok:continue
   check(cast.budget.main==0 and int(cast.actor.runtime.resources[cls+"-slots-"+str(a.spell_tier)])==int(caster.runtime.resources[cls+"-slots-"+str(a.spell_tier)])-1,"actual action and tier slot "+id)
   check(cast.events.any(func(e: Dictionary):return e.type=="summon_intent") if a.effects.any(func(e: Dictionary):return e.op=="summon") else effect_state(cast.target)!=effect_state(target),"actual effect or typed summon intent "+id)
   check(RulesJson.digest(cast)==RulesJson.digest(use_at_save(caster,target,id,1)),"spell deterministic "+id)
   var dry: Dictionary=caster.duplicate(true);dry.runtime.resources[cls+"-slots-"+str(a.spell_tier)]=0
   check(not use(dry,target,id).ok,"exhaustion enforced "+id)
   unique[a.name]=true;shapes[RulesJson.digest(a.effects)]=true
 check(unique.size()==32 and shapes.size()>=27,"thirty-two original spell identities with actual effect diversity")
func advanced_base(cls: String,count: int) -> Dictionary:
 var r := build(cls,1,"heritage-human","arcane-strike"if cls=="duskblade"else"spirit-reserve")
 for n in range(1,count):
  var step := kernel.suggested_choice(r,cls)
  var must: Array=["spellcraft"]if cls=="duskblade"else["nature","insight"]
  var allocation: Dictionary=step.choice.skill_allocations
  var ranks: Dictionary=kernel.derive_character(r).context.skills
  for skill in must:
   if int(ranks[skill])>=n+1 or allocation.has(skill):continue
   for donor in allocation.keys():
    if must.has(donor):continue
    allocation[donor]-=1
    if allocation[donor]==0:allocation.erase(donor)
    allocation[skill]=1;break
  var next := kernel.preview_advancement(r,step.choice);check(next.ok,"durable prerequisite history "+cls+str(n))
  if not next.ok:return {}
  r=next.candidate
 return r
func test_new_paths() -> void:
 for spec in [["abjurant-champion","duskblade",5],["grove-warden","spirit-shaman",3]]:
  var path: String=spec[0];var r := advanced_base(spec[1],6)
  check(not kernel.starting_classes().has(path),"prestige not a starting class "+path)
  var blank := kernel.create("forged",r.base_attributes,"heritage-human")
  var forged: Dictionary=kernel.suggested_choice(blank,spec[1]).choice.duplicate(true);forged.class_id=path
  var rejected := kernel.preview_advancement(blank,forged)
  check(not rejected.ok and rejected.errors[0].code=="advancement.prestige_start","forged prestige start rejected by authority "+path)
  var options := kernel.available_advancement(r);check(options.ok and options.classes[path].ok,"complete permanent entry "+path+JSON.stringify(options))
  check(not kernel.derive_character(r).snapshot.class_levels.has(path),"eligibility never auto-assigns "+path)
  check(kernel.preview_advancement(r,kernel.suggested_choice(r,spec[1]).choice).ok,"qualified character may decline "+path)
  var early := build(spec[1],1)
  check(not kernel.available_advancement(early).classes[path].ok,"ineligible path rejected "+path)
  for n in int(spec[2]):
   var choice := kernel.suggested_choice(r,path)
   check(choice.ok,"explicit prestige choices "+path+str(n))
   if not choice.ok:break
   var next := kernel.preview_advancement(r,choice.choice);check(next.ok,"genuine prestige progression "+path+str(n)+JSON.stringify(next.get("errors",[])))
   if not next.ok:break
   r=next.candidate
  fixtures[path]=r
  check(kernel.derive_character(r).snapshot.class_levels.get(path)==spec[2],"intended prestige cap reached "+path)
  check(not kernel.available_advancement(r).classes[path].ok,"own class cap enforced "+path)
  check(kernel.derive_character(r).snapshot.casting_levels[spec[1]]==6+int(spec[2]),"hybrid casting advances exact selected caster "+path)
func test_wave_five_feats() -> void:
 for spec in [["channel-training","duskblade",2,"steady-study"],["arcane-endurance","duskblade",2,"arcane-strike"],["spirit-reserve","spirit-shaman",2,"steady-study"],["ancestral-listener","spirit-shaman",2,"steady-study"],["retrieved-capacity","spirit-shaman",2,"steady-study"],["runic-veteran","duskblade",6,"steady-study"],["watchful-channel","duskblade",3,"steady-study"],["spirit-temper","spirit-shaman",2,"spirit-reserve"]]:
  var id: String=spec[0];var r := build(spec[1],spec[2],"heritage-human",spec[3])
  if id=="watchful-channel":
   # Preserve a lawful previous-level choice, rather than granting a runtime prerequisite.
   r.advancement_history[2].feat_id="channel-training"
  var suggestion := kernel.suggested_choice(r,spec[1],id)
  check(suggestion.ok and suggestion.choice.feat_id==id,"feat is a legal explicit advancement choice "+id)
  if not suggestion.ok:continue
  var gained := kernel.preview_advancement(r,suggestion.choice)
  var alternate: Dictionary=suggestion.choice.duplicate(true);alternate.feat_id="steady-study"
  var baseline := kernel.preview_advancement(r,alternate)
  check(gained.ok and baseline.ok,"positive feat and lawful control "+id+JSON.stringify(gained.get("errors",[])))
  if not gained.ok or not baseline.ok:continue
  check(gained.snapshot.feats.has(id),"persistent feat history "+id)
  var a: Dictionary=gained.snapshot;var b: Dictionary=baseline.snapshot
  match id:
   "channel-training":check(int(a.stats.save_dc)>int(b.stats.save_dc),"real spell DC training")
   "arcane-endurance":check(int(a.stats.HP)==int(b.stats.HP)+4 and int(a.stats.fortitude)>int(b.stats.fortitude),"real HP and Fortitude")
   "spirit-reserve":check(int(a.resource_capacities["spirit-favour"])==int(b.resource_capacities["spirit-favour"])+2,"two real guide uses")
   "ancestral-listener":check(int(a.stats.will)>int(b.stats.will),"real Will training")
   "retrieved-capacity":check(int(a.resource_capacities["spirit-shaman-slots-1"])==int(b.resource_capacities["spirit-shaman-slots-1"])+1,"one real tier1 slot")
   "runic-veteran":check(int(a.capabilities.resistances.get("force",0))>int(b.capabilities.resistances.get("force",0)),"actual force resistance")
   "watchful-channel":check(int(a.stats.initiative)>int(b.stats.initiative),"actual initiative training")
   "spirit-temper":check(int(a.capabilities.resistances.get("psychic",0))>int(b.capabilities.resistances.get("psychic",0)),"actual psychic resistance")
  var unqualified := build("fighter",2)
  var bad: Dictionary=kernel.suggested_choice(unqualified,"fighter").choice;bad.feat_id=id
  check(not kernel.preview_advancement(unqualified,bad).ok,"missing feat/class prerequisite rejected "+id)
  check(kernel.validate_build(JSON.parse_string(JSON.stringify(gained.candidate))).ok,"feat exact JSON history "+id)
func test_supporting_content() -> void:
 fixtures.psion=build("psion",20);fixtures.druid=build("druid",20)
 test_supporting_powers();test_supporting_bodies();test_supporting_creatures();test_supporting_heritages();test_psychic_feat_chain()
func test_supporting_powers() -> void:
 var tested := 0
 for pid in source.ids("psychic_powers"):
  var power := source.definition("psychic_powers",pid)
  if power.provenance.get("revision")!="game112-wave-five":continue
  var master: Dictionary=fixtures.psion.duplicate(true)
  var groups := RulesCareer.groups(source,"psion",20)
  var group: Dictionary=groups.filter(func(g: Dictionary):return g.options.any(func(o: Dictionary):return o.features.has(power.feature_id)))[0]
  master.advancement_history.back().specialisations[group.id]=pid
  check(kernel.validate_build(master).ok,"deliberately selected persistent new power "+pid)
  for aid in power.variants:
   var a := source.definition("abilities",aid);var target := build("fighter",1);target.runtime.hp=1
   master.runtime.hp=maxi(1,int(master.runtime.hp)-10)
   var cast := use_at_save(master,target,aid,1)
   check(cast.ok,"every augmentation executes "+aid+JSON.stringify(cast.get("errors",[])))
   if not cast.ok:continue
   check(cast.budget.main==0 and int(master.runtime.resources["psychic-points"])-int(cast.actor.runtime.resources["psychic-points"])==int(a.cost.resources["psychic-points"]),"actual augmentation/main cost "+aid)
   check(effect_state(cast.target)!=effect_state(target) or effect_state(cast.actor)!=effect_state(master),"actual power outcome "+aid)
   check(RulesJson.digest(cast)==RulesJson.digest(use_at_save(master,target,aid,1)),"power replay "+aid)
   var dry: Dictionary=master.duplicate(true);dry.runtime.resources["psychic-points"]=0
   check(not use(dry,target,aid).ok,"point exhaustion "+aid)
  # One real tactical execution per identity complements every costed kernel variant.
  var aid: String=power.variants[0];var a := source.definition("abilities",aid)
  var battle := encounter(master);var engine := TacticalAuras.new(master)
  var target_id: String="b"if a.targeting.kind=="ally"else"bandit-blade"
  if target_id=="bandit-blade":
   var target := build("fighter",1);target.character_id=target_id;target.equipment=["shortblade"];battle.units[target_id].record=target
  battle.units[target_id].record.runtime.hp=1
  battle.rng=save_seeds[1];battle=engine.seal(battle)
  var input := {"actor_id":"a","revision":battle.revision,"kind":aid,"target_id":target_id}
  var cast := engine.command(battle,input)
  check(cast.ok,"power executes in actual tactical authority "+pid+str(cast.get("error","")))
  if cast.ok:
   check(cast.battle.budget.main==0 and engine.validate(cast.battle).is_empty(),"legal costed power battle "+pid)
   var replay := engine.command(JSON.parse_string(JSON.stringify(battle)),input)
   check(replay.ok and replay.battle.state_hash==cast.battle.state_hash,"actual tactical power replay "+pid)
  tested+=1;fixtures[pid]=master
 check(tested==10,"ten selectable new power identities tested")
func test_supporting_bodies() -> void:
 var original: Dictionary=fixtures.druid.duplicate(true);original.equipment=["staff","leathers"];original.runtime.hp-=5
 var before: Dictionary=kernel.derive_character(original).snapshot
 for id in ["moon-stag","iron-tortoise","briar-cat"]:
  var cast := use(original,original,"wild-shape-"+id)
  check(cast.ok,"new functional form "+id+JSON.stringify(cast.get("errors",[])))
  if not cast.ok:continue
  var current: Dictionary=cast.actor;var transformed := kernel.derive_character(current)
  check(transformed.ok and current.character_id==original.character_id and current.runtime.hp==original.runtime.hp,"identity and original health remain authoritative "+id)
  check(transformed.snapshot.attributes.STR!=before.attributes.STR or transformed.snapshot.attributes.DEX!=before.attributes.DEX,"physical attributes change "+id)
  check(not transformed.snapshot.abilities.any(func(aid: String):return source.definition("abilities",aid).tags.has("spell")),"form suppresses casting "+id)
  check(TacticalAuras.new(current).active_weapon({"record":current,"weapon":"staff"})==RulesEntities.form(current,source).weapon_id,"actual natural weapon "+id)
  var revert := use(current,current,"revert-form")
  check(revert.ok and RulesEntities.form(revert.actor,source).is_empty() and revert.actor.equipment==original.equipment,"reversion restores equipment "+id)
  if revert.ok:check(kernel.derive_character(revert.actor).snapshot.attributes==before.attributes,"reversion restores physical attributes "+id)
  var expiry: Dictionary=current.duplicate(true)
  for n in 3:expiry.runtime=RulesEffects.new(source).expire_statuses(expiry.runtime,"global_round_start").runtime
  check(RulesEntities.form(expiry,source).is_empty() and expiry.runtime.hp==original.runtime.hp,"exact three-round expiry "+id)
  fixtures["active-"+id]=current
func test_supporting_creatures() -> void:
 for id in ["ancestor-sentinel","briar-beast"]:
  var creature := RulesEntities.creature_record("owner:summon:"+id,id,6,source)
  check(not creature.is_empty() and kernel.validate_build(creature).ok,"authored owned creature "+id)
  if creature.is_empty():continue
  var target := build("fighter",1);target.runtime.hp=1
  var cast := use_at_save(creature,target,id+"-special",1)
  check(cast.ok and cast.budget.main==0 and int(cast.actor.runtime.resources["creature-effort"])==int(creature.runtime.resources["creature-effort"])-1,"distinct costed creature action "+id)
  if cast.ok:check(effect_state(cast.target)!=effect_state(target),"real creature support/control "+id)
  for cls in ["spirit-shaman","druid","wizard"]:
   var master := build(cls,20);var aid: String=cls+"-call-"+id;master=prep(master,aid)
   var battle := encounter(master);var engine := TacticalAuras.new(master)
   var input := {"actor_id":"a","revision":battle.revision,"kind":aid,"target_id":"a"}
   var summoned := engine.command(battle,input)
   check(summoned.ok,"real tactical summon "+aid+str(summoned.get("error","")))
   if not summoned.ok:continue
   var owned: Array=summoned.battle.units.values().filter(func(u: Dictionary):return u.get("entity",{}).get("kind")=="summon" and u.entity.owner_id=="a")
   check(owned.size()==1 and summoned.battle.order.has(owned[0].id) and owned[0].entity.definition_id==id,"exact one owned actor with real turn "+aid)
   check(engine.validate(summoned.battle).is_empty(),"summon battle validates "+aid)
   var replay := engine.command(JSON.parse_string(JSON.stringify(battle)),input)
   check(replay.ok and replay.battle.state_hash==summoned.battle.state_hash,"summon deterministic replay "+aid)
   fixtures["summoner-"+cls+"-"+id]=master
  for cls in ["druid","ranger"]:
   var record := kernel.create("owner",build(cls,1).base_attributes,"heritage-human")
   for n in 6:
    var choice := kernel.suggested_choice(record,cls)
    for group in RulesCareer.groups(source,cls,n+1):
     if group.options.any(func(o: Dictionary):return o.id==id):choice.choice.specialisations[group.id]=id
    var next := kernel.preview_advancement(record,choice.choice);check(next.ok,"real companion selection/growth "+cls+id+str(n))
    if not next.ok:break
    record=next.candidate
   var pets: Dictionary=record.runtime.companions
   check(pets.size()==1 and pets.values()[0].definition_id==id,"one permanent chosen companion "+cls+id)
   check(kernel.validate_build(JSON.parse_string(JSON.stringify(record))).ok,"companion exact JSON and ownership "+cls+id)
   fixtures["owner-"+cls+"-"+id]=record
func test_supporting_heritages() -> void:
 for people in ["catfolk","riverborn","wildborn","ratfolk"]:
  var record := build("fighter",3,"heritage-"+people)
  check(not record.is_empty(),"inherited playable creation/progression "+people)
  if record.is_empty():continue
  var snapshot: Dictionary=kernel.derive_character(record).snapshot
  var ancestry := source.definition("ancestries",record.ancestry_ref)
  for attr in ancestry.attribute_adjustments:check(int(snapshot.attributes[attr])==int(record.base_attributes[attr])+int(ancestry.attribute_adjustments[attr]),"actual inherited attribute "+people+attr)
  check(ancestry.visual_profile.art_status=="neutral_humanoid_fallback","honest anatomy artwork "+people)
  if people in ["catfolk","riverborn"]:
   var battle := encounter(record);var engine := TacticalAuras.new(record)
   battle.rng=attack_seed(19);battle=engine.seal(battle)
   var used := engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":people+"-natural-strike","target_id":"bandit-blade"})
   check(used.ok and used.battle.budget.main==0,"real inherited natural strike "+people)
   if used.ok:check(int(used.battle.units["bandit-blade"].record.runtime.hp)<int(battle.units["bandit-blade"].record.runtime.hp),"real inherited natural damage "+people)
  if people=="wildborn":
   var used := use(record,record,"wildborn-shelter")
   check(used.ok and used.budget.main==0 and int(used.actor.runtime.resources["wildborn-gift"])==int(record.runtime.resources["wildborn-gift"])-1,"actual finite inherited gift")
   if used.ok:check(kernel.derive_character(used.actor).snapshot.capabilities.resistances.get("physical")==2,"actual inherited protection")
  fixtures[people]=record
 for spec in [["catfolk","catfolk-ambush"],["riverborn","riverborn-fangs"],["wildborn","wildborn-resilience"],["ratfolk","ratfolk-footwork"]]:
  var r := build("fighter",2,"heritage-"+spec[0]);var choice := kernel.suggested_choice(r,"fighter",spec[1]);var gained := kernel.preview_advancement(r,choice.choice)
  check(gained.ok and gained.snapshot.feats.has(spec[1]),"ancestry feat deliberately selected "+spec[1])
  if not gained.ok:continue
  match spec[0]:
   "catfolk":check(int(gained.snapshot.capabilities.moving_damage)==1,"actual moving damage")
   "riverborn":check(gained.snapshot.capabilities.weapon_damage.get("riverborn-natural")=="1d8","actual inherited bite dice")
   "wildborn":check(int(gained.snapshot.capabilities.resistances.get("physical",0))==2,"actual inherited physical resistance")
   "ratfolk":check(int(gained.snapshot.stats.stride)>int(kernel.derive_character(r).snapshot.stats.stride),"actual inherited footwork")
  var illegal := build("fighter",2)
  var forged: Dictionary=kernel.suggested_choice(illegal,"fighter").choice;forged.feat_id=spec[1]
  check(not kernel.preview_advancement(illegal,forged).ok,"ancestry feat restriction enforced "+spec[1])
 for heritage in ["heritage-catfolk-swiftstrider","heritage-riverborn-rime"]:
  var record := build("fighter",1,heritage)
  check(not record.is_empty() and kernel.validate_build(record).ok,"real heritage tradeoffs "+heritage);fixtures[heritage]=record
 for spec in [["druid","ancestral-bond"],["druid","briar-form-training"]]:
  var record := build(spec[0],5 if spec[1]=="ancestral-bond"else 6)
  if spec[1]=="ancestral-bond":record=kernel.preview_advancement(record,kernel.suggested_choice(record,"spirit-shaman").choice).candidate
  var suggestion := kernel.suggested_choice(record,spec[0],spec[1]);var gained := kernel.preview_advancement(record,suggestion.choice)
  check(gained.ok and gained.snapshot.feats.has(spec[1]),"supporting feat with durable prerequisite "+spec[1])
  if gained.ok:
   if spec[1]=="briar-form-training":check(gained.snapshot.capabilities.weapon_damage.get("leopard-claws")=="1d8","real natural-form dice")
   else:check(gained.candidate.runtime.companions.values()[0].record.advancement_history.size()>kernel.preview_advancement(record,kernel.suggested_choice(record,spec[0],"steady-study").choice).candidate.runtime.companions.values()[0].record.advancement_history.size(),"real companion growth")
func test_psychic_feat_chain() -> void:
 var record := build("psion",1,"heritage-human","psychic-discipline")
 for n in range(2,14):
  var id: String="resonant-discipline"if n==7 else"harmonic-focus"if n==13 else"steady-study"
  var suggestion := kernel.suggested_choice(record,"psion",id)
  if n in [4,10]:
   var power: String="power-kinetic-shatter"if n==4 else"power-harmonic-shelter"
   for group in RulesCareer.groups(source,"psion",n):
    if group.options.any(func(o: Dictionary):return o.id==power):suggestion.choice.specialisations[group.id]=power
  var gained := kernel.preview_advancement(record,suggestion.choice)
  check(gained.ok,"permanent psychic feat/power chain "+str(n)+JSON.stringify(gained.get("errors",[])))
  if not gained.ok:break
  if n in [7,13]:
   var alternate: Dictionary=suggestion.choice.duplicate(true);alternate.feat_id="steady-study"
   var baseline := kernel.preview_advancement(record,alternate)
   check(baseline.ok and gained.snapshot.feats.has(id),"new learned-power feat explicitly chosen "+id)
   if baseline.ok:check(int(gained.snapshot.resource_capacities["psychic-points"])==int(baseline.snapshot.resource_capacities["psychic-points"])+2,"actual psychic reserve bonus "+id)
   if n==7:check(gained.snapshot.capabilities.resistances.get("force")==3,"real resonant force resistance")
   if n==13 and baseline.ok:check(int(gained.snapshot.stats.reflex)>int(baseline.snapshot.stats.reflex),"real harmonic Reflex bonus")
  record=gained.candidate
 fixtures["psychic-feat-chain"]=record
 for id in ["resonant-discipline","harmonic-focus"]:
  var early := build("psion",2,"heritage-human","psychic-discipline")
  var bad: Dictionary=kernel.suggested_choice(early,"psion").choice;bad.feat_id=id
  check(not kernel.preview_advancement(early,bad).ok,"permanent learned-power prerequisite required "+id)
func finish() -> void:
 if not base.is_empty():
  DirAccess.make_dir_recursive_absolute(base)
  if OS.get_environment("GAME112W5_RESTART")!="1" and not fixtures.is_empty():
   var hashes := {}
   for id in fixtures:
    var result := kernel.derive_character(fixtures[id]);check(result.ok,"saved fixture derived "+id)
    if result.ok:hashes[id]=result.snapshot.snapshot_hash
   var after := {}
   if not channel_battle.is_empty():after=TacticalAuras.new(fixtures.duskblade).command(channel_battle,{"actor_id":"a","revision":channel_battle.revision,"kind":"end"})
   check(after.get("ok",false),"persisted channel follow-up")
   FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify({"records":fixtures,"hashes":hashes,"channel_battle":channel_battle,"after_end_hash":after.get("battle",{}).get("state_hash","")}))
  FileAccess.open(base.path_join("restart-proof.json"if OS.get_environment("GAME112W5_RESTART")=="1"else"mechanics-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true}))
 print("WAVE5 ",checks," checks ",failures," failures")
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
