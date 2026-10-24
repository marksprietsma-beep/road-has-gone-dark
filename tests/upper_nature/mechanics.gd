extends "res://tests/nature_repertoires/mechanics_driver.gd"
## Lawful high-level development fixtures. Ordinary earned careers are separate.
const NEW := ["sorcerer-refraction-guard","sorcerer-cascade-well","druid-heartwood-renewal","druid-wildheart-mantle"]
var battles := {}
var contracts := {}
func encounter(record: Dictionary) -> Dictionary:
 var battle := super.encounter(record)
 battle.units.a.name=source.definition("classes",record.advancement_history[0].class_id).name+" · development fixture"
 return TacticalAuras.new(record).seal(battle)
func run() -> void:
 base=OS.get_environment("UPPER_NATURE_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v27.json")
 check(loaded.ok,"v27 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:complete();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("UPPER_NATURE_RESTART")=="1":cold();return
 fixtures.fighter=build("fighter",20);fixtures.save_target=build("fighter",7)
 for cls in ["sorcerer","druid"]:
  for at in [1,5,6,14,15,16,17,20]:
   saved_records[cls+str(at)]=build(cls,at)
  fixtures[cls]=saved_records[cls+"20"]
  check(not fixtures[cls].is_empty(),"lawful full level20 "+cls)
 if failures:complete();return
 test_new_spells();test_decoys();test_exchange();test_renewal();test_shared_form();test_choices();test_bloodlines();test_druid_bonds();test_owned_forms();test_multiclass_upper()
 # Reuse GAME-133's executable tier4–7/owned-creature tests on the new pin.
 for aid in source.ids("abilities"):
  var row := source.definition("abilities",aid)
  if row.get("provenance",{}).get("revision")=="game133-sorcerer-druid-repertoires":test_spell(row)
 test_creatures_and_forms();test_hybrid();test_spellbook();test_legacy()
 for cls in ["sorcerer","druid"]:
  for tier in [8,9]:
   for family in ["tempest","sanctuary"]:test_spell(source.definition("abilities",cls+"-tier"+str(tier)+"-"+family))
 var hashes := {};var record_hashes := {};var next := {};var after := {}
 for id in saved_records:
  saved_records[id]=RulesJson.string_keys(saved_records[id]);var d := kernel.derive_character(saved_records[id])
  check(d.ok,"persist valid known/prepared/body/companion/resources "+id)
  if d.ok:hashes[id]=d.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(saved_records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  check(engine.validate(battles[id]).is_empty(),"saved battle validates "+id)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var out := engine.command(battles[id],next[id]);check(out.ok,"predict saved next command "+id)
  if out.ok:after[id]=out.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":saved_records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 complete()

func complete(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_level20":false,"classes":["sorcerer","druid"],"new_spells":NEW,"contracts":contracts,"traces":traces}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof),"  "))
 print("UPPER_NATURE ",JSON.stringify({"checks":checks,"failures":failures,"cold":restart}))
 get_tree().quit(1 if failures else 0)

func cold() -> void:
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for id in saved.records:
  var d := kernel.derive_character(saved.records[id])
  check(d.ok and d.snapshot.snapshot_hash==saved.hashes[id],"cold exact snapshot "+id)
  check(RulesJson.digest(saved.records[id])==saved.record_hashes[id],"cold full history/known/copies/status/ownership/equipment exact "+id)
 for id in saved.battles:
  var engine := TacticalAuras.new(saved.battles[id].units.a.record)
  check(engine.validate(saved.battles[id]).is_empty(),"cold saved battle valid "+id)
  var out := engine.command(saved.battles[id],saved.next[id])
  check(out.ok and out.battle.state_hash==saved.after[id],"cold next command/log/RNG exact "+id)
 complete(true)

func test_new_spells() -> void:
 for aid in NEW:
  var row := source.definition("abilities",aid);var actor := prepared(fixtures[row.casting_class],aid)
  var target: Dictionary=actor if row.targeting.kind=="self" else fixtures.save_target.duplicate(true)
  var before := RulesJson.digest([actor,target]);var out := cast(actor,target,aid)
  check(out.ok,"new choice actually executes "+aid+JSON.stringify(out.get("errors",[])))
  if not out.ok:continue
  check(RulesJson.digest([actor,target])==before,"pure input state "+aid)
  check(out==cast(actor,target,aid),"deterministic identical execution "+aid)
  check(out.budget.main==0 and out.budget.move==1,"one main, movement retained "+aid)
  for pool in row.cost.resources:check(out.actor.runtime.resources[pool]==actor.runtime.resources[pool]-1,"exact finite slot/copy cost "+pool)
  var spent: Dictionary=actor.duplicate(true);spent.runtime.resources[row.casting_class+"-slots-"+str(row.spell_tier)]=0
  check(not cast(spent,spent if row.targeting.kind=="self" else target,aid).ok,"no slot bypass "+aid)
  var unknown: Dictionary=actor.duplicate(true);unknown.choices.prepared_abilities=[];unknown.choices.spell_preparations={};unknown.runtime.resources=kernel._replay(unknown).context.capacities.duplicate()
  check(not cast(unknown,unknown if row.targeting.kind=="self" else target,aid).ok,"unknown/unprepared cannot cast "+aid)
  check(not RulesEffects.new(source).use_ability(actor,target,aid,out.budget,out.rng).ok,"spent main rejects "+aid)
  if row.casting_class=="druid":check(not cast(out.actor,target,aid).ok,"prepared copy exhausted "+aid)
  else:check(cast(out.actor,out.actor,aid).ok,"permanently known can reuse remaining shared slot "+aid)
  var cap: Dictionary=kernel.derive_character(out.actor).snapshot.resource_capacities
  for boundary in ["encounter","short_rest","daily","explicit"]:check(RulesEffects.new(source).refresh_resources(out.actor.runtime,cap,boundary).runtime.resources==out.actor.runtime.resources,"unrelated boundary never refills "+aid+boundary)
  var rested: Dictionary=out.actor.duplicate(true);rested.runtime=RulesEffects.new(source).refresh_resources(rested.runtime,cap,"eligible_rest").runtime
  check(cast(rested,rested if row.targeting.kind=="self" else target,aid).ok,"eligible recovery "+aid)
  var engine := TacticalAuras.new(actor);var b := encounter(actor);b.units.b.position=[2,2];b=engine.seal(b)
  var target_id: String="a" if row.targeting.kind=="self" else "b"
  var tactical := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":aid,"target_id":target_id})
  check(tactical.ok,"real tactical intent "+aid+str(tactical.get("error","")))
  if tactical.ok:battles[aid]=tactical.battle;traces[aid]=tactical.battle.log;saved_records[aid]=tactical.battle.units.a.record
  check(not engine.eligible(b,b.units.a,b.units["bandit-blade"],aid),"hostile target rejected "+aid)
  if target_id=="b":
   b.units.b.position=[7,5];b=engine.seal(b)
   check(not engine.eligible(b,b.units.a,b.units.b,aid),"range/clear sight authority "+aid)

func test_decoys() -> void:
 var actor := prepared(fixtures.sorcerer,"sorcerer-refraction-guard");var engine := TacticalAuras.new(actor);var b := encounter(actor)
 var casted := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":"sorcerer-refraction-guard","target_id":"a"})
 check(casted.ok,"refraction tactical setup")
 if not casted.ok:return
 b=casted.battle;var hp: int=int(b.units.a.record.runtime.hp);var rng := RulesJson.digest(b.rng)
 var commanded: Dictionary=b.duplicate(true);commanded.cursor=commanded.order.find("bandit-blade");commanded.budget={"main":1,"move":1};commanded=engine.seal(commanded)
 var actual := engine.command(commanded,{"actor_id":"bandit-blade","revision":commanded.revision,"kind":"attack","target_id":"a"})
 check(actual.ok and actual.battle.budget.main==0 and shells(actual.battle.units.a.record)==2,"intercepted real command still pays its main action")
 for n in 3:
  engine.weapon_attack(b,b.units["bandit-blade"],b.units.a,false)
  check(b.units.a.record.runtime.hp==hp and shells(b.units.a.record)==2-n,"each legal weapon attempt consumes exactly one shell")
  check(RulesJson.digest(b.rng)==rng,"interception occurs before accuracy/damage RNG")
  check(not b.log.back().contains("hits"),"no weapon hit or rider claimed")
 engine.weapon_attack(b,b.units["bandit-blade"],b.units.a,false)
 check(RulesJson.digest(b.rng)!=rng,"fourth attempt reaches actual d20 authority")
 var guarded: Dictionary=cast(actor,actor,"sorcerer-refraction-guard").actor
 var refreshed := cast(guarded,guarded,"sorcerer-refraction-guard")
 check(refreshed.ok and shells(refreshed.actor)==3,"no six-shell stacking")
 var true_board := encounter(guarded);true_board.units["bandit-blade"].record.runtime.senses.append("true_sight");var initial := RulesJson.digest(true_board.rng)
 engine.weapon_attack(true_board,true_board.units["bandit-blade"],true_board.units.a,false)
 check(shells(true_board.units.a.record)==3 and RulesJson.digest(true_board.rng)!=initial,"true sight bypasses without consuming shell")
 var target: Dictionary=guarded.duplicate(true);target.character_id="protected-sorcerer"
 var spellcaster := prepared(fixtures.sorcerer,"sorcerer-arcane-bolt")
 var spell := cast(spellcaster,target,"sorcerer-arcane-bolt")
 check(spell.ok and spell.target.runtime.hp<target.runtime.hp and shells(spell.target)==3,"direct spell damage bypasses weapon-only decoys")
 var expiry: Dictionary=guarded.runtime.duplicate(true)
 for n in 2:expiry=RulesEffects.new(source).expire_statuses(expiry,"global_round_start").runtime
 check(expiry.statuses.all(func(s: Dictionary):return not source.definition("statuses",s.id).tags.has("weapon_decoy")),"two-boundary finite expiry")
 saved_records.guarded=guarded;battles.decoys=engine.seal(true_board);contracts.decoys=true

func shells(record: Dictionary) -> int:
 return record.runtime.statuses.filter(func(s: Dictionary):return source.definition("statuses",s.id).tags.has("weapon_decoy")).size()

func test_exchange() -> void:
 var actor := prepared(fixtures.sorcerer,"sorcerer-cascade-well");actor.runtime.resources["sorcerer-slots-4"]=0;actor.runtime.resources["sorcerer-slots-6"]=0
 actor.choices.prepared_abilities.append("sorcerer-crystal-reservoir")
 var before: Dictionary=actor.runtime.resources.duplicate(true);var out := cast(actor,actor,"sorcerer-cascade-well")
 check(out.ok,"finite cascade exchange executes")
 if not out.ok:return
 check(out.actor.runtime.resources["sorcerer-slots-4"]==2 and out.actor.runtime.resources["sorcerer-slots-6"]==1,"exact lower-tier conversion")
 var useful := cast(out.actor,out.actor,"sorcerer-crystal-reservoir")
 check(useful.ok and useful.actor.runtime.resources["sorcerer-slots-4"]==1 and useful.actor.runtime.temporary_hp>0,"converted slot actually pays for a permanently known lower spell on a later main action")
 var engine := TacticalAuras.new(actor);var board := encounter(actor)
 var converted := engine.command(board,{"actor_id":"a","revision":board.revision,"kind":"sorcerer-cascade-well","target_id":"a"})
 check(converted.ok,"conversion delivers through real tactical command")
 if converted.ok:battles.cascade_conversion=converted.battle
 for pool in before:
  if pool not in ["sorcerer-slots-4","sorcerer-slots-6","sorcerer-slots-9"]:check(out.actor.runtime.resources[pool]==before[pool],"exchange never refills unrelated pool "+pool)
 var cap: Dictionary=kernel.derive_character(out.actor).snapshot.resource_capacities
 while int(out.actor.runtime.resources["sorcerer-slots-9"])>0:
  out=cast(out.actor,out.actor,"sorcerer-cascade-well");check(out.ok,"remaining finite high slot can be converted")
  if not out.ok:return
  check(out.actor.runtime.resources["sorcerer-slots-4"]<=cap["sorcerer-slots-4"] and out.actor.runtime.resources["sorcerer-slots-6"]<=cap["sorcerer-slots-6"],"cannot exceed either permanent capacity")
 check(not cast(out.actor,out.actor,"sorcerer-cascade-well").ok,"exchange cannot recover its own cost or loop indefinitely")
 check(out.actor.choices==actor.choices,"conversion does not learn or reselect spells")
 saved_records.cascade_spent=out.actor;contracts.exchange=true

func test_renewal() -> void:
 var actor := prepared(fixtures.druid,"druid-heartwood-renewal");var target: Dictionary=fixtures.fighter.duplicate(true);target.character_id="recovering";target.runtime.hp-=50
 for sid in ["bramble-tether","winter-lock","slowed"]:target.runtime.statuses.append({"id":sid,"source":"controlled-fixture","remaining":int(source.definition("statuses",sid).duration.amount),"expiry":source.definition("statuses",sid).duration.expiry})
 var out := cast(actor,target,"druid-heartwood-renewal");check(out.ok,"delayed renewal executes "+JSON.stringify(out.get("errors",[])))
 if not out.ok:return
 check(out.target.runtime.hp==target.runtime.hp and out.target.runtime.statuses.size()==1,"cleanses exact three roots/slow without burst healing")
 var engine := TacticalAuras.new(actor);var b := encounter(actor);out.target.character_id="b";b.units.b.record=out.target
 b.cursor=b.order.find("b");var hp: int=int(b.units.b.record.runtime.hp);var rng := RulesJson.digest(b.rng)
 RulesMartial.start_activation(engine,b)
 check(b.units.b.record.runtime.hp==hp+12 and b.budget.main==1,"real own activation heals without extra action")
 check(RulesJson.digest(b.rng)==rng,"fixed recovery consumes no RNG")
 var sealed := engine.seal(b);var before := RulesJson.digest(sealed)
 check(RulesJson.digest(engine.seal(sealed))==before,"previews/seals never cause healing")
 var down: Dictionary=b.duplicate(true);down.units.b.record.runtime.hp=0;RulesMartial.start_activation(engine,down)
 check(down.units.b.record.runtime.hp==0,"no downed resurrection")
 for n in 3:b.units.b.record.runtime=RulesEffects.new(source).expire_statuses(b.units.b.record.runtime,"global_round_start").runtime
 hp=int(b.units.b.record.runtime.hp);RulesMartial.start_activation(engine,b)
 check(b.units.b.record.runtime.hp==hp,"expiry stops future ticks")
 saved_records.renewing=out.target;battles.renewal=engine.seal(b);contracts.renewal=true

func test_shared_form() -> void:
 var actor := prepared(fixtures.druid,"druid-wildheart-mantle");var target: Dictionary=fixtures.fighter.duplicate(true);target.character_id="willing-fighter";target.equipment=["shortblade"]
 for kind in ["armor","shield"]:
  var legal: Array=source.ids("equipment").filter(func(id: String):return source.definition("equipment",id).kind==kind)
  if not legal.is_empty():target.equipment.append(legal[0])
 var before: Dictionary=kernel.derive_character(target).snapshot;var out := cast(actor,target,"druid-wildheart-mantle")
 check(out.ok,"actual allied transformation "+JSON.stringify(out.get("errors",[])))
 if not out.ok:return
 var snap: Dictionary=kernel.derive_character(out.target).snapshot
 check(snap.body_form.id=="bear-form" and snap.attributes.STR==before.attributes.STR+4 and snap.attributes.DEX==before.attributes.DEX-2,"existing body changes actual physical attributes")
 check(out.target.character_id==target.character_id and out.target.runtime.hp==target.runtime.hp and out.target.equipment==target.equipment,"identity/health/equipment record authoritative")
 check(snap.abilities.has("revert-form"),"allied non-Druid can deliberately return")
 var reverted := cast(out.target,out.target,"revert-form")
 check(reverted.ok and kernel.derive_character(reverted.actor).snapshot.stats==before.stats and reverted.actor.equipment==target.equipment,"manual reversion restores exact original equipment statistics")
 var engine := TacticalAuras.new(actor);var b := encounter(actor);b.units.b.record=out.target;b.units.b.record.character_id="b"
 check(engine.active_weapon(b.units.b)=="bear-claws","actual weapon authority uses natural claws")
 var hp: int=int(b.units["bandit-blade"].record.runtime.hp);engine.weapon_attack(b,b.units.b,b.units["bandit-blade"],false)
 check(not b.log.is_empty() and b.units["bandit-blade"].record.runtime.hp<=hp,"natural attack reaches existing d20/damage authority")
 var own := cast(actor,actor,"druid-wildheart-mantle")
 check(own.ok and kernel.derive_character(own.actor).snapshot.abilities.all(func(id: String):return not source.definition("abilities",id).tags.has("spell")),"transformed casting remains unsupported")
 var expired: Dictionary=out.target.duplicate(true)
 for n in 3:expired.runtime=RulesEffects.new(source).expire_statuses(expired.runtime,"global_round_start").runtime
 check(kernel.derive_character(expired).snapshot.stats==before.stats,"expiry restores body/equipment without healing")
 var pet_id := RulesEntities.identity("a");var pet_board := encounter(actor)
 check(pet_board.units.has(pet_id),"permanent owned companion present")
 if pet_board.units.has(pet_id):
  pet_board.units[pet_id].position=[1,2];pet_board=engine.seal(pet_board)
  var original: Dictionary=pet_board.units[pet_id].record.duplicate(true)
  var transformed := engine.command(pet_board,{"actor_id":"a","revision":pet_board.revision,"kind":"druid-wildheart-mantle","target_id":pet_id})
  check(transformed.ok,"wildheart targets real owned creature")
  if transformed.ok:
   check(transformed.battle.units[pet_id].record.character_id==original.character_id and transformed.battle.units[pet_id].record.runtime.hp==original.runtime.hp,"creature identity and HP preserved")
   check(transformed.battle.units.a.record.runtime.companions[pet_id].record==transformed.battle.units[pet_id].record,"sole ownership record captures active form")
   saved_records.transformed_owner=transformed.battle.units.a.record;battles.companion_form=transformed.battle
 saved_records.allied_form=out.target;saved_records.own_form=own.actor;battles.shared_form=engine.seal(b);contracts.forms=true

func test_choices() -> void:
 for cls in ["sorcerer","druid"]:
  for at in [14,15,16,17,20]:
   var available: Array=kernel.derive_character(saved_records[cls+str(at)]).snapshot.abilities
   for aid in NEW:
    var row := source.definition("abilities",aid)
    if row.casting_class==cls:check(available.has(aid)==(at>=(15 if row.spell_tier==8 else 17)),"actual unlock boundary "+cls+str(at)+aid)
  var aid: String=NEW[1] if cls=="sorcerer" else NEW[3]
  check(not kernel.derive_character(prepared(saved_records[cls+"14"],aid)).ok,"forged early high-tier choice rejected "+cls)
  var attrs := {"STR":12,"DEX":14,"CON":13,"INT":15,"WIS":10,"CHA":8}
  if cls=="druid":attrs.WIS=8;attrs.CHA=10
  var poor := kernel.create("lawful-low-casting-"+cls,attrs,"heritage-human")
  for n in 20:
   var suggested := kernel.suggested_choice(poor,cls)
   check(suggested.ok,"lawful low-casting advancement suggestion")
   if not suggested.ok:return
   if (n+1)%4==0:suggested.choice.attribute_increase="INT"
   var next := kernel.preview_advancement(poor,suggested.choice)
   check(next.ok,"valid low-casting history; no retrospective feat/score mutation "+JSON.stringify(next.get("errors",[])))
   if not next.ok:return
   poor=next.candidate
  var lawful := kernel.derive_character(poor)
  check(lawful.ok,"low-casting negative fixture is a legal permanent character")
  if not lawful.ok:return
  poor.runtime.resources=lawful.snapshot.resource_capacities.duplicate()
  check(not kernel.derive_character(prepared(poor,aid)).ok,"permanent score gate cannot be bypassed by high total level "+cls)
 contracts.permanent_choices=true

func branch(record: Dictionary,cls: String,choice: String,companion := "") -> Dictionary:
 var r := kernel.create(cls+choice+str(record.advancement_history.size()),record.base_attributes,record.ancestry_ref)
 for step in record.advancement_history:
  var planned: Dictionary=step.duplicate(true);planned.erase("level")
  for group in planned.specialisations:
   if group in [cls+"-choice-1",cls+"-choice-6",cls+"-choice-15"]:planned.specialisations[group]=choice
   if group=="druid-companion" and not companion.is_empty():planned.specialisations[group]=companion
  var next := kernel.preview_advancement(r,planned);check(next.ok,"lawful permanent branch "+cls+choice+str(r.advancement_history.size()))
  if not next.ok:return {}
  r=next.candidate
 r.runtime.hp=int(kernel.derive_character(r).snapshot.stats.HP);r.runtime.resources=kernel._replay(r).context.capacities.duplicate();return r

func test_bloodlines() -> void:
 for choice in ["draconic","fey"]:
  for at in [1,6,20]:
   var r := branch(saved_records["sorcerer"+str(at)],"sorcerer",choice)
   if r.is_empty():return
   var id: String="sorcerer-"+choice+"-"+str(1 if at<6 else 6)
   var out := cast(r,fixtures.save_target,id)
   check(out.ok,"actual bloodline action "+choice+str(at))
   if out.ok:
    check(out.actor.runtime.resources["bloodline-uses"]==r.runtime.resources["bloodline-uses"]-1,"finite bloodline reserve distinct from slots")
    check(out.target.runtime.hp<fixtures.save_target.runtime.hp if choice=="draconic" else kernel.derive_character(out.target).snapshot.stats.will<kernel.derive_character(fixtures.save_target).snapshot.stats.will,"bloodlines produce different damage/control outcomes")
   var empty: Dictionary=r.duplicate(true);empty.runtime.resources["bloodline-uses"]=0;check(not cast(empty,fixtures.save_target,id).ok,"exhausted bloodline rejects")
   saved_records[choice+str(at)]=r
 var a: Dictionary=kernel.derive_character(saved_records.draconic20).snapshot;var b: Dictionary=kernel.derive_character(saved_records.fey20).snapshot
 check(a.stats.defence==b.stats.defence+2 and b.stats.save_dc==a.stats.save_dc+2,"late bloodline alternatives retain distinct permanent defence/DC")
 contracts.bloodlines=true

func test_druid_bonds() -> void:
 for choice in ["growth","storm"]:
  for at in [1,6,20]:
   var r := branch(saved_records["druid"+str(at)],"druid",choice)
   if r.is_empty():return
   var id: String="druid-"+choice+"-"+str(1 if at==1 else 6)
   var out := cast(r,fixtures.save_target,id)
   check(out.ok,"actual nature specialisation "+choice+str(at))
   if out.ok:check(out.actor.runtime.resources["nature-bond-uses"]==r.runtime.resources["nature-bond-uses"]-1,"nature action has its own finite reserve")
   saved_records["nature-"+choice+str(at)]=r
 for companion in ["wolf","ancestor-sentinel"]:
  var actor := prepared(branch(fixtures.druid,"druid","growth",companion),"druid-heartwood-renewal")
  var engine := TacticalAuras.new(actor);var b := encounter(actor);var pid := RulesEntities.identity("a")
  check(b.units.has(pid),"chosen permanent companion exists "+companion)
  if not b.units.has(pid):continue
  b.units[pid].position=[1,2];b.units[pid].record.runtime.hp-=10;b=engine.seal(b)
  var out := engine.command(b,{"actor_id":"a","revision":b.revision,"kind":"druid-heartwood-renewal","target_id":pid})
  check(out.ok,"new recovery targets actual chosen creature "+companion)
  if not out.ok:continue
  var hp: int=int(out.battle.units[pid].record.runtime.hp)
  out.battle.cursor=out.battle.order.find(pid);RulesMartial.start_activation(engine,out.battle);out.battle=engine.seal(out.battle)
  check(out.battle.units[pid].record.runtime.hp>hp,"actual creature activation receives capped recovery "+companion)
  check(out.battle.units.a.record.runtime.companions.size()==1 and out.battle.units.a.record.runtime.companions[pid].record==out.battle.units[pid].record,"single owner retains exact creature state "+companion)
  saved_records["renewing-owner-"+companion]=out.battle.units.a.record;battles["renewing-pet-"+companion]=out.battle
 contracts.companions=true

func test_owned_forms() -> void:
 var actor: Dictionary=fixtures.druid;var before: Dictionary=kernel.derive_character(actor).snapshot;var count := 0
 for aid in before.abilities:
  var row := source.definition("abilities",aid)
  if row.tags.has("spell"):continue
  var forms: Array=row.effects.filter(func(e: Dictionary):return e.op=="apply_status" and source.definition("statuses",e.id).has("body_form"))
  if forms.is_empty():continue
  var out := cast(actor,actor,aid);check(out.ok,"owned Druid form actually executes "+aid+JSON.stringify(out.get("errors",[])))
  if not out.ok:continue
  var snap: Dictionary=kernel.derive_character(out.actor).snapshot
  check(not snap.body_form.is_empty() and snap.attributes!=before.attributes,"owned form changes physical build "+aid)
  check(out.actor.runtime.hp==actor.runtime.hp and snap.abilities.has("revert-form"),"owned form preserves HP and deliberate return "+aid)
  var restored := cast(out.actor,out.actor,"revert-form")
  check(restored.ok and kernel.derive_character(restored.actor).snapshot.stats==before.stats,"owned form restores original statistics "+aid)
  saved_records["owned-form-"+aid]=out.actor;count+=1
 check(count>=4,"multiple genuinely different owned Druid forms verified")
 contracts.owned_forms=count

func test_multiclass_upper() -> void:
 # The existing five-level Theurge cannot unlock tier9 on both tracks in20.
 var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new();planner.source=source;planner.kernel=kernel
 for primary in ["sorcerer","druid"]:
  var secondary: String="druid" if primary=="sorcerer" else "sorcerer"
  var attrs := {"STR":8,"DEX":10,"CON":12,"INT":13,"WIS":14,"CHA":15}
  if primary=="druid":attrs.WIS=15;attrs.CHA=14
  var r := kernel.create("upper-hybrid-"+primary,attrs,"heritage-human");var goals: Dictionary=planner.requirements("mystic-theurge",0)
  var route: Array=[]
  for pair in [[primary,13],[secondary,3],["mystic-theurge",4]]:
   for n in pair[1]:route.append(pair[0])
  for cls in route:
   var next: Dictionary=planner.advance(r,cls,goals);check(next.ok,"legal upper hybrid route "+primary+cls)
   if not next.ok:break
   var selected: Dictionary=next.candidate.advancement_history.back().duplicate(true);selected.erase("level")
   if (r.advancement_history.size()+1)%4==0:selected.attribute_increase="CHA" if primary=="sorcerer" else "WIS"
   next=kernel.preview_advancement(r,selected);check(next.ok,"deliberate hybrid casting attribute")
   if not next.ok:break
   r=next.candidate
  if r.advancement_history.size()!=20:continue
  var snap: Dictionary=kernel.derive_character(r).snapshot
  check(snap.casting_levels[primary]==17 and snap.casting_levels[secondary]==7,"independent hybrid17/7 caps; total20 is not both tier9")
  var id: String="sorcerer-cascade-well" if primary=="sorcerer" else "druid-wildheart-mantle"
  var chosen := prepared(r,id);var out := cast(chosen,chosen,id)
  check(out.ok,"actual supported hybrid upper spell "+id)
  if out.ok:saved_records["hybrid-"+primary]=out.actor
 planner.free();contracts.hybrid=true
