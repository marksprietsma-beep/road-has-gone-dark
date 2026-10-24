extends "res://tests/hybrid_acceptance/probe.gd"
## Lawful development fixtures; earned campaign entry is a separate native phase.
var saved_records := {}
var battles := {}
var contracts := {}
func run() -> void:
 base=OS.get_environment("HYBRID_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v28.json")
 check(loaded.ok,"immutable28 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_acceptance();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("HYBRID_RESTART")=="1":cold();return
 fixtures.fighter=build("fighter",20)
 for at in [1,3,5,9,13,17,20]:saved_records["duskblade"+str(at)]=build("duskblade",at)
 for cls in ["wizard","sorcerer"]:
  for variant in ["force","ward"]:
   var r := arch_path(cls,variant)
   if not r.is_empty():saved_records[cls+":"+variant]=r
 if failures:finish_acceptance();return
 fixtures.defender=warded_defender()
 test_channel_cohort();test_multiclass_channels();test_refraction_counter();test_archmage();test_ward_progression();test_beguiler_route();test_permanent_gates();test_forms();test_resource_boundaries()
 var hashes := {};var records := {};var predicted := {}
 for key in saved_records:
  saved_records[key]=RulesJson.string_keys(saved_records[key]);var d := kernel.derive_character(saved_records[key])
  check(d.ok,"all persisted fixtures validate "+key+JSON.stringify(d.get("errors",[])))
  if d.ok:hashes[key]=d.snapshot.snapshot_hash;records[key]=RulesJson.digest(saved_records[key])
 for key in battles:
  var engine := TacticalAuras.new(battles[key].units.a.record)
  check(engine.validate(battles[key]).is_empty(),"saved real tactical state valid "+key)
  var next := {"actor_id":engine.current(battles[key]).id,"revision":battles[key].revision,"kind":"end"}
  var out := engine.command(battles[key],next);check(out.ok,"saved next command predicts "+key)
  if out.ok:predicted[key]={"command":next,"hash":out.battle.state_hash}
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":saved_records,"hashes":hashes,"record_hashes":records,"battles":battles,"predicted":predicted})))
 finish_acceptance()
func arch_path(cls: String,variant: String) -> Dictionary:
 var r := career_fixture(cls,13,["spell-focus","greater-spell-focus"])
 if r.is_empty():return {}
 if cls=="sorcerer":r=prep(r,"sorcerer-tier7-tempest")
 for level in 5:
  var suggested := kernel.suggested_choice(r,"archmage")
  check(suggested.ok,"legal prestige suggestion "+cls+str(level))
  if not suggested.ok:return {}
  for key in suggested.choice.specialisations:
   if str(key).begins_with("high-arcana-"):suggested.choice.specialisations[key]=variant
  if level==0:suggested.choice.specialisations["archmage-casting"]=cls
  if (r.advancement_history.size()+1)%4==0:suggested.choice.attribute_increase=source.definition("classes",cls).casting_attribute
  var out := kernel.preview_advancement(r,suggested.choice)
  check(out.ok,"explicit optional path level "+cls+str(level)+JSON.stringify(out.get("errors",[])))
  if not out.ok:return {}
  r=out.candidate
  saved_records[cls+":"+variant+":path"+str(level+1)]=r.duplicate(true)
  check(kernel.derive_character(r).snapshot.class_levels.archmage==level+1,"ordered actual prestige level, no automatic assignment")
 for i in 2:
  var proposal := kernel.suggested_choice(r,cls)
  if (r.advancement_history.size()+1)%4==0:proposal.choice.attribute_increase=source.definition("classes",cls).casting_attribute
  var out := kernel.preview_advancement(r,proposal.choice);check(out.ok,"lawful total20 continuation "+cls)
  if not out.ok:return {}
  r=out.candidate
 var d := kernel.derive_character(r)
 check(r.advancement_history.size()==20 and d.snapshot.class_levels.archmage==5 and d.snapshot.casting_levels[cls]==20,"five supported path levels; actual20 effective casting "+cls)
 r.runtime=RulesEffects.new(source).refresh_resources(r.runtime,d.snapshot.resource_capacities,"eligible_rest").runtime
 return r
func warded_defender() -> Dictionary:
 # A lawful Fighter17/Duskblade3, not an invented defence bonus. DEX growth,
 # Dodge, mail/shield and its actual self-cast runic ward permit a low-roll miss.
 var r := kernel.create("warded-defender",{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8},"heritage-elf")
 for at in 20:
  var cls: String="fighter" if at<17 else "duskblade"
  var suggested := kernel.suggested_choice(r,cls,"dodge" if at==0 else "steady-study")
  check(suggested.ok,"lawful defensive multiclass suggestion")
  if not suggested.ok:return {}
  if (at+1)%4==0:suggested.choice.attribute_increase="DEX"
  var out := kernel.preview_advancement(r,suggested.choice)
  check(out.ok,"lawful DEX/Dodge defensive history "+JSON.stringify(out.get("errors",[])))
  if not out.ok:return {}
  r=out.candidate
 r.equipment=["shortblade","mail","shield"];r=prep(r,"duskblade-runic-ward");r.runtime.hp=int(kernel.derive_character(r).snapshot.stats.HP)
 var ward := use(r,r,"duskblade-runic-ward");check(ward.ok,"defender's real known self ward spends an actual slot")
 return ward.actor if ward.ok else {}
func test_channel_cohort() -> void:
 var count := 0
 for aid in source.ids("abilities"):
  var row := source.definition("abilities",aid)
  if row.get("casting_class")!="duskblade" or row.has("channel_spell") or row.targeting.kind!="creature":continue
  count+=1
  var at: int=maxi(3,[1,5,9,13,17][int(row.spell_tier)-1])
  var r := select(saved_records["duskblade"+str(at)],aid)
  var engine := TacticalAuras.new(r);var wrapper: String="channel-"+aid
  for roll in [1,19,20]:
   var b := encounter(r);b.units["bandit-blade"].record=fixtures.defender.duplicate(true);b.units["bandit-blade"].record.character_id="bandit-blade"
   b.rng=attack_seed(roll);b=engine.seal(b)
   check(1+int(engine.stats(b.units.a).melee_attack)<int(engine.stats(b.units["bandit-blade"]).defence),"lawful defender permits actual numeric miss; no automatic natural-one rule")
   var before := RulesJson.digest(b);var plain := engine.command(b,order(b,"attack"));var channel := engine.command(b,order(b,wrapper))
   check(plain.ok and channel.ok,"actual supported channel "+aid+" roll"+str(roll)+str(channel.get("error","")))
   if not plain.ok or not channel.ok:continue
   check(RulesJson.digest(b)==before,"channel never mutates input "+aid)
   check(channel.battle.budget.main==0 and channel.battle.budget.move==1,"one main action competes with spells; movement retained")
   var pool: String="duskblade-slots-"+str(row.spell_tier)
   check(channel.battle.units.a.record.runtime.resources[pool]==b.units.a.record.runtime.resources[pool]-1,"exact single slot on hit/miss/critical "+aid)
   if roll==1:check(channel.battle.units["bandit-blade"].record==plain.battle.units["bandit-blade"].record and channel.battle.rng==plain.battle.rng,"numeric miss has no spell effect/RNG "+aid)
   else:
    if roll==20:check("(critical)" in " ".join(plain.battle.log),"actual authoritative critical hit, not a renamed fixture")
    var expected := RulesWaveFive.channel_effects(channel.battle.units.a.record,plain.battle.units["bandit-blade"].record,aid,plain.battle.rng,source)
    check(expected.ok,"independent original hit effect resolves "+aid)
    if expected.ok:check(channel.battle.units["bandit-blade"].record==expected.target and channel.battle.rng==expected.rng,"weapon (including critical) plus exactly one original effect "+aid)
   check(not engine.command(channel.battle,order(channel.battle,aid)).ok,"ordinary cast cannot reuse spent main "+aid)
   check(engine.command(b,order(b,wrapper)).battle.state_hash==channel.battle.state_hash,"identical deterministic wrapper replay "+aid)
   battles[aid+":"+str(roll)]=channel.battle
  var dry := encounter(r);dry.units.a.record.runtime.resources["duskblade-slots-"+str(row.spell_tier)]=0;dry=engine.seal(dry)
  check(not engine.command(dry,order(dry,wrapper)).ok,"no channel with exhausted matching tier "+aid)
  var unknown := encounter(r);unknown.units.a.record.choices.prepared_abilities=[];unknown=engine.seal(unknown)
  check(not engine.command(unknown,order(unknown,wrapper)).ok,"wrapper never bypasses permanent known spell "+aid)
 # Earlier dedicated hit/zero-physical-damage/concealment/invalid gear tests reuse
 # their real authority on28, not earlier-version result claims.
 test_channel_delivery()
 check(count==10,"all ten actual supported single-enemy spells channel; no self/area expansion")
 var first := select(saved_records.duskblade1,"duskblade-searing-grasp")
 check(not kernel.derive_character(first).snapshot.abilities.has("channel-duskblade-searing-grasp"),"channel not granted before class3")
 check(not source.definition("abilities","channel-duskblade-runic-ward").has("id"),"self ward cannot be channelled")
 contracts.channels=count
func test_multiclass_channels() -> void:
 var r: Dictionary=saved_records.duskblade17.duplicate(true)
 for i in 3:
  var proposed := kernel.suggested_choice(r,"wizard")
  if (r.advancement_history.size()+1)%4==0:proposed.choice.attribute_increase="INT"
  var advanced := kernel.preview_advancement(r,proposed.choice);check(advanced.ok,"lawful Duskblade17/Wizard3 ordered history")
  if not advanced.ok:return
  r=advanced.candidate
 r.choices.prepared_abilities=["duskblade-ruinous-touch","wizard-arcane-bolt"];r.choices.spell_preparations={"wizard-arcane-bolt":1}
 var d := kernel.derive_character(r);check(d.ok,"legal independent known/prepared multiclass selections")
 if not d.ok:return
 r.runtime=RulesEffects.new(source).refresh_resources(r.runtime,d.snapshot.resource_capacities,"eligible_rest").runtime
 check(d.snapshot.casting_levels.duskblade==17 and d.snapshot.casting_levels.wizard==3 and not d.snapshot.abilities.has("wizard-tier9-tempest"),"aggregate arcane levels do not grant a different class's upper spells")
 var engine := TacticalAuras.new(r);var b := encounter(r);var before: Dictionary=b.units.a.record.runtime.resources.duplicate()
 var ch := engine.command(b,order(b,"channel-duskblade-ruinous-touch"));check(ch.ok,"late multiclass channel executes")
 if not ch.ok:return
 check(ch.battle.units.a.record.runtime.resources["wizard-slots-1"]==before["wizard-slots-1"] and ch.battle.units.a.record.runtime.resources["wizard-prepared-arcane-bolt"]==1,"channel spends only original Duskblade pool, never Wizard slot/copy")
 check(not engine.command(ch.battle,order(ch.battle,"wizard-arcane-bolt")).ok,"separate class spell still competes for the same main action")
 b=ch.battle
 for n in 10:
  var ended := engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"});check(ended.ok,"actual turn authority advances multiclass fixture")
  if not ended.ok:return
  b=ended.battle
  if engine.current(b).id=="a":break
 var cast := engine.command(b,order(b,"wizard-arcane-bolt"));check(cast.ok,"actual next-activation Wizard spell executes independently")
 if cast.ok:
  check(cast.battle.units.a.record.runtime.resources["wizard-slots-1"]==before["wizard-slots-1"]-1 and cast.battle.units.a.record.runtime.resources["wizard-prepared-arcane-bolt"]==0,"Wizard spell consumes its actual slot and prepared copy")
  check(cast.battle.units.a.record.runtime.resources["duskblade-slots-5"]==ch.battle.units.a.record.runtime.resources["duskblade-slots-5"],"ordinary Wizard spell cannot spend/refill Duskblade resources")
  battles["multiclass-independent"]=cast.battle;saved_records["duskblade:wizard"]=cast.battle.units.a.record
 contracts.multiclass=true
func test_refraction_counter() -> void:
 var target: Dictionary=saved_records["sorcerer:force"].duplicate(true);target.character_id="bandit-blade";target.equipment=["staff"]
 target.choices.prepared_abilities.append("sorcerer-refraction-guard")
 var guard := use(target,target,"sorcerer-refraction-guard");check(guard.ok,"actual existing Sorcerer8 refraction casts under28")
 if not guard.ok:return
 var caster := select(saved_records.duskblade17,"duskblade-ruinous-touch");var b := encounter(caster);var engine := TacticalAuras.new(caster)
 b.units["bandit-blade"].record=guard.actor;b.units["bandit-blade"].weapon="staff";b=engine.seal(b)
 var old_rng := RulesJson.digest(b.rng);var hp: int=int(guard.actor.runtime.hp)
 var out := engine.command(b,order(b,"channel-duskblade-ruinous-touch"));check(out.ok,"real finite-illusion channel counterplay")
 if out.ok:
  check(out.battle.units["bandit-blade"].record.runtime.hp==hp and RulesJson.digest(out.battle.rng)==old_rng,"intercepted weapon delivers no channel damage/save/RNG")
  check(out.battle.units["bandit-blade"].record.runtime.statuses.filter(func(s: Dictionary):return source.definition("statuses",s.id).tags.has("weapon_decoy")).size()==2,"exactly one existing refraction shell consumed")
  check(out.battle.budget.main==0 and out.battle.units.a.record.runtime.resources["duskblade-slots-5"]==b.units.a.record.runtime.resources["duskblade-slots-5"]-1,"countered channel still pays action and original slot")
  battles["refraction-counter"]=out.battle
 contracts.refraction=true
func test_archmage() -> void:
 for cls in ["wizard","sorcerer"]:
  for variant in ["force","ward"]:
   var r: Dictionary=saved_records[cls+":"+variant];var d := kernel.derive_character(r)
   var other: String="ward" if variant=="force" else "force"
   check(not use(r,fixtures.fighter,"high-arcana-"+other+"-1").ok,"unchosen high arcana unavailable "+cls+variant)
   for level in [1,3,5]:
    var aid: String="high-arcana-"+variant+"-"+str(level)
    if variant=="force":
     var dc := RulesExpressions.evaluate_formula(source.definition("abilities",aid).effects[0].dc,d.context)
     var attr: String=source.definition("classes",cls).casting_attribute
     var expected: int=15+int(floor(float(int(d.snapshot.attributes[attr])-10)/2.0))+int(d.snapshot.stats.save_dc)
     check(dc.ok and dc.value==expected,"actual DC follows selected permanent "+cls+" attribute, not maximum/INT fallback")
     for roll in [1,20]:
      var cast := use_at_save(r,fixtures.fighter,aid,roll)
      check(cast.ok,"actual high arcana "+aid+JSON.stringify(cast.get("errors",[])))
      if cast.ok:
       check(cast.actor.runtime.resources["high-arcana"]==r.runtime.resources["high-arcana"]-1 and cast.budget.main==0,"real high arcana use and main action")
       check(cast.events.any(func(e: Dictionary):return e.get("type")=="save_resolved" and int(e.dc)==expected),"actual save event uses selected-caster DC")
       check((cast.target.runtime.hp<fixtures.fighter.runtime.hp)==(roll==1),"real Reflex success/failure counterplay "+aid)
    else:
     var cast := use(r,fixtures.fighter,aid)
     check(cast.ok,"actual selectable ally ward "+aid)
     if cast.ok:
      check(cast.target.runtime.temporary_hp==20 and cast.target.runtime.statuses.any(func(s: Dictionary):return s.id=="draconic-ward"),"path5 ward gives actual buffer and elemental resistance")
      check(cast.actor.runtime.temporary_hp==r.runtime.temporary_hp,"ward goes to target, not caster")
      var repeated := use(cast.actor,cast.target,aid)
      check(repeated.ok and repeated.target.runtime.temporary_hp==20,"ward refresh never stacks temporary HP")
    var b := encounter(r);var engine := TacticalAuras.new(r)
    var target: String="bandit-blade" if variant=="force" else "b"
    var out := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":aid,"target_id":target})
    check(out.ok,"real tactical area/ally command "+cls+aid+str(out.get("error","")))
    if out.ok:battles[cls+":"+aid]=out.battle
 var r: Dictionary=saved_records["sorcerer:force"]
 var absent := RulesExpressions.evaluate_formula({"op":"casting_modifier","id":"mystic-theurge"},kernel.derive_character(r).context)
 check(not absent.ok,"missing permanent selected track rejects; no arbitrary highest-score fallback")
 contracts.high_arcana=true
func controlled(record: Dictionary,ids: Array) -> Dictionary:
 # Explicit valid development status fixture, never a production XP/save edit.
 var r: Dictionary=record.duplicate(true)
 for id in ids:
  var status := source.definition("statuses",id)
  r.runtime.statuses.append({"id":id,"source":"registered-control-fixture","remaining":int(status.duration.amount),"expiry":status.duration.expiry})
 check(kernel.validate_build(r).ok,"registered finite control fixture remains a lawful character")
 return r
func test_ward_progression() -> void:
 var controls: Array=["weakened","arcane-tether","slowed","unsteady-concentration","stillness-lattice","mind-tether"]
 var target := controlled(build("fighter",7),controls)
 for cls in ["wizard","sorcerer"]:
  for at in [1,3,5]:
   var actor: Dictionary=saved_records[cls+":ward:path"+str(at)].duplicate(true)
   var caps: Dictionary=kernel.derive_character(actor).snapshot.resource_capacities
   actor.runtime=RulesEffects.new(source).refresh_resources(actor.runtime,caps,"eligible_rest").runtime
   var aid: String="high-arcana-ward-"+str(at);var out := use(actor,target,aid)
   check(out.ok,"actual early/middle/late ward choice "+cls+str(at))
   if not out.ok:continue
   var removed: Array=[]
   if at>=3:removed=["weakened","arcane-tether"]
   if at==5:removed.append_array(["slowed","unsteady-concentration","stillness-lattice"])
   for id in controls:check(out.target.runtime.statuses.any(func(v: Dictionary):return v.id==id)== (not removed.has(id)),"precise ward cleanup/non-universal counterplay "+aid+id)
   check(out.target.runtime.temporary_hp==10+2*at,"real supported path-level buffer scaling "+str(at))
   check(out.target.runtime.resources==target.runtime.resources and out.target.runtime.hp==target.runtime.hp,"ward never grants actions/resources, healing or revival")
   check(out.actor.runtime.resources["high-arcana"]==actor.runtime.resources["high-arcana"]-1 and out.budget.main==0,"advanced cleansing uses the same finite action/pool")
  var r: Dictionary=saved_records[cls+":ward"]
  var blocked := controlled(r,["stillness-lattice"]);var before := RulesJson.digest(blocked)
  check(not use(blocked,target,"high-arcana-ward-5").ok and RulesJson.digest(blocked)==before,"main-action suppression cannot self-cleanse or bypass cost")
  var ward := use(r,fixtures.fighter,"high-arcana-ward-5")
  check(ward.ok,"late defensive ward for actual damage test")
  if not ward.ok:continue
  var attacker := select(saved_records.duskblade17,"duskblade-searing-grasp")
  var plain := use(attacker,fixtures.fighter,"duskblade-searing-grasp")
  var resisted := use(attacker,ward.target,"duskblade-searing-grasp")
  check(plain.ok and resisted.ok,"same real elemental spell against plain and warded target")
  if plain.ok and resisted.ok:
   var raw: int=int(fixtures.fighter.runtime.hp)-int(plain.target.runtime.hp)
   check(raw>3 and resisted.target.runtime.hp==fixtures.fighter.runtime.hp and resisted.target.runtime.temporary_hp==20-(raw-3),"actual resistance3 then separate buffer absorbs remaining fire damage")
   check(resisted.events.any(func(e: Dictionary):return e.get("type")=="damage_resisted" and e.amount==3),"observable exact elemental resistance event")
  var expired: Dictionary=ward.target.duplicate(true)
  for i in 3:expired.runtime=RulesEffects.new(source).expire_statuses(expired.runtime,"global_round_start").runtime
  check(not expired.runtime.statuses.any(func(v: Dictionary):return v.id=="draconic-ward"),"finite three-boundary ward status expires")
  check(kernel.derive_character(expired).snapshot.stats.defence==kernel.derive_character(fixtures.fighter).snapshot.stats.defence and expired.runtime.temporary_hp==20,"expiry removes ward defence; separate buffer follows shared temporary-HP policy")
  saved_records[cls+":cleansed"]=use(r,target,"high-arcana-ward-5").target
  saved_records[cls+":ward-expired"]=expired
  var b := encounter(r);b.units.b.record=target.duplicate(true);b.units.b.record.character_id="b";b.units.b.record.equipment=["shortblade"]
  var engine := TacticalAuras.new(r);b=engine.seal(b)
  var cast := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":"high-arcana-ward-5","target_id":"b"})
  check(cast.ok,"real battlefield ally liberation and ward "+cls)
  if cast.ok:
   check(cast.battle.budget.main==0 and not cast.battle.units.b.record.runtime.statuses.any(func(v: Dictionary):return v.id=="stillness-lattice"),"cleansing resolves without a free caster action or invented turn")
   battles[cls+":liberation"]=cast.battle
 contracts.ward_progression=true
func test_beguiler_route() -> void:
 # The existing third casting option is an integration route, not another cohort.
 var r := career_fixture("beguiler",14,["spell-focus","greater-spell-focus"])
 var available: Array=kernel.derive_character(r).snapshot.abilities.filter(func(id: String):return source.definition("abilities",id).get("casting_class")=="beguiler" and source.definition("abilities",id).get("spell_tier")==7)
 check(not available.is_empty(),"existing Beguiler has a real legal upper arcane tier")
 if available.is_empty():return
 r=prep(r,str(available[0]))
 for at in 5:
  var suggested := kernel.suggested_choice(r,"archmage")
  if at==0:suggested.choice.specialisations["archmage-casting"]="beguiler"
  for key in suggested.choice.specialisations:
   if str(key).begins_with("high-arcana-"):suggested.choice.specialisations[key]="ward" if at==2 else "force"
  if (r.advancement_history.size()+1)%4==0:suggested.choice.attribute_increase="INT"
  var advanced := kernel.preview_advancement(r,suggested.choice);check(advanced.ok,"existing Beguiler integration path advances legally")
  if not advanced.ok:return
  r=advanced.candidate
 var d := kernel.derive_character(r);r.runtime=RulesEffects.new(source).refresh_resources(r.runtime,d.snapshot.resource_capacities,"eligible_rest").runtime
 check(d.snapshot.casting_levels.beguiler==19 and d.context.casting_modifiers.archmage==int(floor(float(int(d.snapshot.attributes.INT)-10)/2.0)),"selected Beguiler progression and primary attribute remain exact")
 check(use(r,fixtures.fighter,"high-arcana-force-5").ok and use(r,fixtures.fighter,"high-arcana-ward-3").ok,"third existing parent executes its actually selected force and cleansing choices")
 saved_records["beguiler:archmage"]=r
 contracts.existing_beguiler_route=true
func test_permanent_gates() -> void:
 for cls in ["wizard","sorcerer"]:
  var qualified := career_fixture(cls,13,["spell-focus","greater-spell-focus"])
  if cls=="sorcerer":qualified=prep(qualified,"sorcerer-tier7-tempest")
  saved_records[cls+":qualified13"]=qualified
  var before := RulesJson.digest(qualified);var offered := kernel.available_advancement(qualified)
  check(offered.classes.archmage.ok and RulesJson.digest(qualified)==before,"qualification is permanent and never automatic "+cls)
  check(not kernel.derive_character(qualified).snapshot.class_levels.has("archmage"),"qualifying character still has no prestige level")
  var continued := kernel.suggested_choice(qualified,cls);var decline := kernel.preview_advancement(qualified,continued.choice)
  check(decline.ok and not kernel.derive_character(decline.candidate).snapshot.class_levels.has("archmage"),"qualified player can deliberately decline prestige")
  var spent: Dictionary=qualified.duplicate(true)
  for pool in spent.runtime.resources:spent.runtime.resources[pool]=0
  check(kernel.available_advancement(spent).classes.archmage.ok,"spent daily resources do not erase permanent entry "+cls)
  if cls=="sorcerer":
   var unknown: Dictionary=qualified.duplicate(true);unknown.choices.prepared_abilities=[]
   check(kernel.validate_build(unknown).ok and not kernel.available_advancement(unknown).classes.archmage.ok,"nominal caster13 without permanent tier7 knowledge cannot enter")
 var missing_feat := career_fixture("wizard",13)
 check(not kernel.available_advancement(missing_feat).classes.archmage.ok,"missing actual feat chain rejects prestige")
 var temporary: Dictionary=missing_feat.duplicate(true);temporary.runtime.granted_features.append("greater-spell-focus-feature")
 check(kernel.validate_build(temporary).ok,"real temporary focus feature is a valid runtime bonus")
 check(not kernel.available_advancement(temporary).classes.archmage.ok,"temporary feature/DC bonus cannot replace permanent feat prerequisite")
 saved_records["wizard:temporary-focus"]=temporary
 var fresh := kernel.create("forged",{"INT":15,"STR":14,"DEX":13,"CON":12,"WIS":10,"CHA":8},"heritage-human")
 check(not kernel.preview_choices(fresh,"archmage").ok,"forged first prestige level cannot enter")
 contracts.permanent_entry=true
func test_forms() -> void:
 var druid := prep(build("druid",20),"druid-wildheart-mantle")
 for cls in ["wizard","sorcerer"]:
  var original: Dictionary=saved_records[cls+":force"]
  var form := use(druid,original,"druid-wildheart-mantle")
  check(form.ok,"real owned ally transformation "+cls)
  if not form.ok:continue
  var before := RulesJson.digest(form.target);var cast := use(form.target,fixtures.fighter,"high-arcana-force-1")
  check(not cast.ok and RulesJson.digest(form.target)==before,"supernatural high arcana suppressed without costs/state change "+cls)
  check(kernel.derive_character(form.target).snapshot.abilities.has("revert-form"),"non-Druid Archmage has original reversion action")
  var reverted := use(form.target,form.target,"revert-form")
  check(reverted.ok and RulesEntities.form(reverted.actor,source).is_empty(),"real reversion restores original casting body")
  if reverted.ok:check(use(reverted.actor,fixtures.fighter,"high-arcana-force-1").ok,"chosen high arcana resumes after reversion")
  saved_records[cls+":suppressed_form"]=form.target
 contracts.body_suppression=true
func test_resource_boundaries() -> void:
 for cls in ["wizard","sorcerer"]:
  var r: Dictionary=saved_records[cls+":force"].duplicate(true);var initial: Dictionary=r.runtime.resources.duplicate()
  var count: int=int(r.runtime.resources["high-arcana"])
  for i in count:
   var cast := use(r,fixtures.fighter,"high-arcana-force-1");check(cast.ok,"finite high arcana use "+str(i))
   if cast.ok:r=cast.actor
  check(not use(r,fixtures.fighter,"high-arcana-force-1").ok,"high arcana resource exhausts")
  for pool in initial:
   if pool!="high-arcana":check(r.runtime.resources[pool]==initial[pool],"high arcana cannot consume/refill underlying spell pool "+pool)
  var capacities: Dictionary=kernel.derive_character(r).snapshot.resource_capacities
  for boundary in ["encounter","short_rest","daily","explicit"]:check(RulesEffects.new(source).refresh_resources(r.runtime,capacities,boundary).runtime.resources["high-arcana"]==0,"unrelated boundary grants no arcana recovery")
  var rested: Dictionary=r.duplicate(true);rested.runtime=RulesEffects.new(source).refresh_resources(r.runtime,capacities,"eligible_rest").runtime
  check(use(rested,fixtures.fighter,"high-arcana-force-1").ok,"eligible real policy restores arcana")
  saved_records[cls+":exhausted"]=r
 contracts.resources=true
func cold() -> void:
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for key in saved.records:
  var d := kernel.derive_character(saved.records[key])
  check(d.ok and d.snapshot.snapshot_hash==saved.hashes[key],"cold exact snapshot "+key)
  check(RulesJson.digest(saved.records[key])==saved.record_hashes[key],"cold exact ordered history/choices/gear/body/resources "+key)
 for key in saved.battles:
  var engine := TacticalAuras.new(saved.battles[key].units.a.record)
  check(engine.validate(saved.battles[key]).is_empty(),"cold valid battle "+key)
  var out := engine.command(saved.battles[key],saved.predicted[key].command)
  check(out.ok and out.battle.state_hash==saved.predicted[key].hash,"cold next command/log/RNG exact "+key)
 finish_acceptance(true)
func finish_acceptance(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"contracts":contracts,"development_fixtures":true,"earned_xp":false,"classes":["duskblade","archmage"]}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof),"  "))
 print("HYBRID_MECHANICS ",JSON.stringify(proof));get_tree().quit(1 if failures else 0)
