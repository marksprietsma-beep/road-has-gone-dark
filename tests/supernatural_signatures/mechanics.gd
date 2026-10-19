extends "res://tests/class_signatures/mechanics_driver.gd"
## Lawful advanced fixtures; separate from the earned campaign phase.
func run() -> void:
 base=OS.get_environment("GAME148_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v21.json")
 check(loaded.ok,"v21 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_supernatural();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME148_RESTART")=="1":
  var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
  for id in saved.records:
   var d := kernel.derive_character(saved.records[id])
   check(d.ok and d.snapshot.snapshot_hash==saved.hashes[id],"cold exact supernatural derivation "+id)
   check(RulesJson.digest(saved.records[id])==saved.record_hashes[id],"cold exact character resources/choices "+id)
  for id in saved.battles:
   var engine := TacticalAuras.new(saved.battles[id].units.a.record)
   check(engine.validate(saved.battles[id]).is_empty(),"cold legal battle "+id)
   var next := engine.command(saved.battles[id],saved.next[id])
   check(next.ok and next.battle.state_hash==saved.after[id],"cold exact next log/command/RNG "+id)
  finish_supernatural(true);return
 fixtures.fighter=build("fighter",20)
 for cls in ["warlock","binder","dragonfire-adept"]:
  for at in [1,6,12,20]:
   var record := build(cls,at);check(not record.is_empty(),"lawful original identity "+cls+str(at))
   if not record.is_empty():records[cls+str(at)]=record
 if failures:finish_supernatural();return
 test_warlock();test_ward_combat();test_binder();test_binder_late();test_dragon();test_dragon_levels();test_multiclass_and_feats();test_counterplay();test_historical()
 var hashes := {};var record_hashes := {};var after := {};var next := {}
 for id in records:
  records[id]=RulesJson.string_keys(records[id]);var d := kernel.derive_character(records[id])
  check(d.ok,"save lawful record "+id)
  if d.ok:hashes[id]=d.snapshot.snapshot_hash;record_hashes[id]=RulesJson.digest(records[id])
 for id in battles:
  var engine := TacticalAuras.new(battles[id].units.a.record)
  next[id]={"actor_id":engine.current(battles[id]).id,"revision":battles[id].revision,"kind":"end"}
  var result := engine.command(battles[id],next[id]);check(result.ok,"predict next command "+id)
  if result.ok:after[id]=result.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes,"record_hashes":record_hashes,"battles":battles,"next":next,"after":after})))
 finish_supernatural()
func finish_supernatural(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"campaign_xp_injected":false,"classes":["warlock","binder","dragonfire-adept"]}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME148 ",JSON.stringify(proof));get_tree().quit(1 if failures else 0)
func alternative(r: Dictionary,choices: Dictionary) -> Dictionary:
 var result: Dictionary=r.duplicate(true)
 for step in result.advancement_history:
  for key in choices:
   if step.specialisations.has(key):step.specialisations[key]=choices[key]
 var d := kernel._replay(result);check(d.ok,"alternate permanent choices "+JSON.stringify(choices))
 if d.ok:result.runtime.resources=d.context.capacities.duplicate()
 check(kernel.validate_build(result).ok,"alternate exact build valid")
 return result
func defender(success: bool) -> Dictionary:
 var target: Dictionary=fixtures.fighter.duplicate(true);target.character_id="defender";target.equipment=["shortblade","leathers"]
 for stat in ["fortitude","reflex","will"]:target.runtime.modifiers.append({"stat":stat,"type":"untyped","value":100 if success else -100,"source":"explicit-save-development-fixture"})
 check(kernel.validate_build(target).ok,"lawful forced-save development target")
 return target
func has_status(r: Dictionary,id: String) -> bool:
 return r.runtime.statuses.any(func(s: Dictionary):return s.id==id)
func test_warlock() -> void:
 for at in [1,6,12,20]:
  var r: Dictionary=records["warlock"+str(at)]
  var control := use(r,defender(false),"warlock-invocation-assault")
  check(control.ok and has_status(control.target,"slowed"),"selected at-will control actually slows "+str(at))
  if control.ok:
   check(control.actor.runtime.resources==r.runtime.resources and control.budget.main==0,"at-will spends main, no pool")
   check(use(control.actor,defender(false),"warlock-invocation-assault").ok,"at-will can be used on another action")
   check(not RulesEffects.new(source).use_ability(control.actor,defender(false),"warlock-invocation-assault",control.budget,control.rng).ok,"at-will cannot bypass spent main")
  var resisted := use(r,defender(true),"warlock-invocation-assault")
  check(resisted.ok and not has_status(resisted.target,"slowed"),"Will save prevents invocation control")
  var ward := alternative(r,{"warlock-discipline":"ward"})
  check(not use(ward,defender(false),"warlock-invocation-assault").ok,"unselected invocation cannot execute")
  ward.runtime.statuses.append({"id":"weakened","source":"fixture","remaining":3,"expiry":"global_round_start"})
  var veiled := use(ward,ward,"warlock-invocation-ward")
  check(veiled.ok and has_status(veiled.actor,"beguiling-veil") and not has_status(veiled.actor,"weakened"),"ward choice provides concealment and actual cleanse")
 for at in [13,16,20]:
  var r := build("warlock",at);var id := "warlock-master-"+str(at)
  var fail_save := use(r,defender(false),id);var pass_save := use(r,defender(true),id)
  check(fail_save.ok and pass_save.ok,"late sapping legal "+str(at))
  if fail_save.ok and pass_save.ok:
   check(has_status(fail_save.target,"weakened") and not has_status(pass_save.target,"weakened"),"late condition has actual save counterplay")
   check(fail_save.events.any(func(e: Dictionary):return e.get("type")=="save_resolved"),"late action resolves authoritative save")
   check(pass_save.target.runtime.hp>fail_save.target.runtime.hp,"save reduces late damage")
 var pressure := alternative(records.warlock20,{"warlock-career-16":"pressure"})
 var pinned := use(pressure,defender(false),"warlock-career-pressure")
 check(pinned.ok and has_status(pinned.target,"mind-tether"),"Pressure grants actual defining control rather than weapon-only bonus")
 check(not use(records.warlock20,defender(false),"warlock-career-pressure").ok,"unselected high invocation rejected")
 records.warlock_pressure=pressure
 var b := encounter(pressure);b.board.blocked=[]
 var engine := TacticalAuras.new(pressure)
 b.units["bandit-blade"].record=defender(false);b.units["bandit-blade"].record.character_id="bandit-blade"
 b=engine.seal(b)
 var cast := execute(engine,b,"warlock-career-pressure","bandit-blade")
 check(cast.ok,"real tactical pressure command")
 if cast.ok:battles.warlock=cast.battle
func test_binder() -> void:
 for at in [1,6,12,20]:
  var embers: Dictionary=records["binder"+str(at)]
  var sentinel := alternative(embers,{"binder-pact":"sentinel"})
  var enemy := defender(false)
  var fire := use(embers,enemy,"binder-embers")
  check(fire.ok and has_status(fire.target,"off-balance"),"Embers actually harms/disrupts on failed save")
  var saved := use(embers,defender(true),"binder-embers")
  check(saved.ok and not has_status(saved.target,"off-balance"),"Embers save prevents control")
  check(not use(sentinel,enemy,"binder-embers").ok and not use(embers,embers,"binder-sentinel").ok,"covenants remain mutually exclusive")
  var ally: Dictionary=enemy.duplicate(true);ally.runtime.statuses.append({"id":"weakened","source":"fixture","remaining":3,"expiry":"global_round_start"})
  var support := use(sentinel,ally,"binder-sentinel")
  check(support.ok and has_status(support.target,"guarding") and not has_status(support.target,"weakened"),"Sentinel grants real defensive role and cleansing")
  if support.ok:
   check(int(support.actor.runtime.resources["binder-commitments"])==int(sentinel.runtime.resources["binder-commitments"])-1,"finite covenant pays once")
   check(int(support.target.runtime.temporary_hp)==at+2,"covenant scales with Binder class level")
   var spent: Dictionary=sentinel.duplicate(true);spent.runtime.resources["binder-commitments"]=0
   check(not use(spent,ally,"binder-sentinel").ok,"exhausted covenant rejected")
   var effects := RulesEffects.new(source)
   var rest := effects.refresh_resources(spent.runtime,kernel.derive_character(spent).snapshot.resource_capacities,"eligible_rest")
   check(rest.ok and int(rest.runtime.resources["binder-commitments"])>0,"eligible rest restores pact commitments")
  if at==20:records.binder_sentinel=sentinel
 var r: Dictionary=records.binder_sentinel;var b := encounter(r);b.board.blocked=[]
 b.units.b.position=[1,2];var engine := TacticalAuras.new(r);b=engine.seal(b)
 check(not execute(engine,b,"binder-sentinel","bandit-blade").ok,"support cannot target enemy through tactical authority")
 var cast := execute(engine,b,"binder-sentinel","b")
 check(cast.ok,"actual ally-target intercession")
 if cast.ok:
  var guarded: Dictionary=cast.battle.duplicate(true);guarded.units.c.position=[2,2]
  guarded.units.c.record=defender(true);guarded.units.c.record.character_id="c"
  guarded.cursor=guarded.order.find("bandit-blade");guarded.budget={"main":1,"move":1};guarded.rng=attack_seed(19,6);guarded=engine.seal(guarded)
  var unguarded: Dictionary=guarded.duplicate(true)
  unguarded.units.b.record.runtime.statuses=unguarded.units.b.record.runtime.statuses.filter(func(s: Dictionary):return s.id!="guarding")
  unguarded=engine.seal(unguarded)
  var attack := {"actor_id":"bandit-blade","revision":guarded.revision,"kind":"attack","target_id":"c"}
  var protected := engine.command(guarded,attack);var ordinary := engine.command(unguarded,attack)
  check(protected.ok and ordinary.ok,"actual covenant protection attack comparison")
  if protected.ok and ordinary.ok:
   check(protected.battle.units.c.record.runtime.hp==ordinary.battle.units.c.record.runtime.hp+4,"interceding ally reduces actual adjacent weapon damage by4")
   check(protected.battle.units.b.reaction==0,"covenant protection spends recipient shared reaction")
   battles.binder=protected.battle
  else:battles.binder=cast.battle
func test_dragon() -> void:
 for element in ["fire","cold","electricity"]:
  var r := alternative(records["dragonfire-adept12"],{"draconic-element":element,"draconic-breath-shape":element+"-focused"})
  var id: String="dragon-focused-"+element
  var cast := use(r,defender(false),id)
  check(cast.ok and has_status(cast.actor,"breath-recovering"),"focused breath enters persisted recovery "+element)
  if not cast.ok:continue
  check(cast.actor.runtime.resources==r.runtime.resources,"focused breath is action/cooldown limited, not point limited")
  check(not use(cast.actor,defender(false),id).ok,"focused breath cannot repeat during recovery")
  check(use(cast.actor,defender(false),"dragon-breath-"+element).ok,"basic breath remains repeatable during focused recovery")
  var expired := RulesEffects.new(source).expire_statuses(cast.actor.runtime,"global_round_start")
  var recovering: Dictionary=cast.actor.duplicate(true);recovering.runtime=expired.runtime
  check(not use(recovering,defender(false),id).ok,"one global boundary still recovering")
  recovering.runtime=RulesEffects.new(source).expire_statuses(recovering.runtime,"global_round_start").runtime
  check(use(recovering,defender(false),id).ok,"second real expiry boundary restores focused breath")
  var wide := alternative(r,{"draconic-breath-shape":element+"-wide"})
  check(not use(wide,defender(false),id).ok,"unchosen focused shape rejected")
  var broad := use(wide,defender(false),"dragon-wide-"+element)
  check(broad.ok and int(broad.actor.runtime.resources["draconic-resolve"])==int(wide.runtime.resources["draconic-resolve"])-1,"wide breath finite invocation cost")
  records["dragon-"+element]=cast.actor
  if element=="fire":
   var focus_engine := TacticalAuras.new(r);var focus_battle := encounter(r);focus_battle.board.blocked=[];focus_battle=focus_engine.seal(focus_battle)
   var focus_command := execute(focus_engine,focus_battle,id,"bandit-blade")
   check(focus_command.ok,"actual focused breath starts recovery even when saved")
   if focus_command.ok:battles.dragon_focused=focus_command.battle
 var wide_record := alternative(records["dragonfire-adept12"],{"draconic-breath-shape":"fire-wide"})
 var engine := TacticalAuras.new(wide_record);var b := encounter(wide_record);b.board.blocked=[]
 b.units["bandit-bow"].position=[4,1];b.units["bandit-bow"].record=defender(false);b.units["bandit-bow"].record.character_id="bandit-bow";b.units["bandit-bow"].record.equipment=["bow","leathers"]
 b=engine.seal(b);var before := RulesJson.digest(b)
 var preview := engine.area_preview(b,b.units.a,b.units["bandit-blade"],"dragon-wide-fire")
 check(preview.has("bandit-blade") and preview.has("bandit-bow") and not preview.has("b"),"area preview shares enemy/radius/line-of-sight restrictions")
 var used := execute(engine,b,"dragon-wide-fire","bandit-blade")
 check(used.ok,"wide breath executes real area command")
 if used.ok:
  check(used.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp and used.battle.units["bandit-bow"].record.runtime.hp<b.units["bandit-bow"].record.runtime.hp,"wide breath affects both enemies")
  check(used.battle.units.b.record==b.units.b.record,"wide enemy burst excludes allies")
  check(int(used.battle.units.a.record.runtime.resources["draconic-resolve"])==int(b.units.a.record.runtime.resources["draconic-resolve"])-1,"area spends resource once, not per target")
  check(engine.command(JSON.parse_string(JSON.stringify(b)),used.battle.commands.back()).battle.state_hash==used.battle.state_hash,"area exact command/RNG replay")
  battles.dragon=used.battle
 check(RulesJson.digest(b)==before,"preview/action leaves source unchanged")
 check(not execute(engine,b,"dragon-wide-cold","bandit-blade").ok,"unselected element/shape forged command rejected")
func test_multiclass_and_feats() -> void:
 var r := build("warlock",4)
 for n in 4:
  var choice := kernel.suggested_choice(r,"binder","steady-study")
  check(choice.ok,"multiclass suggestion")
  if not choice.ok:return
  var next := kernel.preview_advancement(r,choice.choice);check(next.ok,"ordered supernatural multiclass")
  if not next.ok:return
  r=next.candidate
 r.runtime.resources=kernel._replay(r).context.capacities.duplicate()
 var basic := use(build("warlock",4),defender(false),"warlock-technique-1")
 var mixed := use(r,defender(false),"warlock-technique-1")
 check(basic.ok and mixed.ok and basic.target.runtime.hp==mixed.target.runtime.hp,"Binder levels do not inflate Warlock blast scaling")
 check(mixed.ok and mixed.actor.runtime.resources==r.runtime.resources,"at-will blast does not spend multiclass covenant pool")
 records.multiclass=r
 var feat := build("dragonfire-adept",6,"heritage-human","draconic-vigor")
 check(kernel.derive_character(feat).snapshot.resource_capacities["draconic-resolve"]==kernel.derive_character(records["dragonfire-adept6"]).snapshot.resource_capacities["draconic-resolve"]+1,"actual draconic feat expands finite invocation pool")
 records.draconic_feat=feat
func test_historical() -> void:
 var historical := RulesRegistry.new();check(historical.load_pack("res://data/rules/trhgd-character-v20.json").ok,"historical v20 remains loadable")
 var current := source;var current_kernel := kernel;source=historical;kernel=RulesCharacter.new(historical)
 var r := build("warlock",20);var target := build("fighter",20);target.character_id="legacy-target"
 var old := use(r,target,"warlock-master-20")
 check(old.ok and not old.events.any(func(e: Dictionary):return e.get("type")=="save_resolved"),"historical late action preserves original no-save behaviour")
 source=current;kernel=current_kernel

func test_counterplay() -> void:
 var r: Dictionary=records.binder20
 var ordinary := defender(false);var resistant: Dictionary=ordinary.duplicate(true)
 resistant.runtime.granted_features.append("ember-ward-feature")
 check(kernel.validate_build(resistant).ok,"existing resistance feature fixture is valid")
 var plain := use(r,ordinary,"binder-embers");var warded := use(r,resistant,"binder-embers")
 check(plain.ok and warded.ok,"fire covenant works against resistance")
 if plain.ok and warded.ok:
  check(warded.target.runtime.hp>plain.target.runtime.hp and warded.events.any(func(e: Dictionary):return e.get("type")=="damage_resisted"),"real fire resistance reduces covenant damage")
 var immune := defender(false);immune.runtime.granted_features.append("iron-soul-feature")
 check(kernel.validate_build(immune).ok,"existing condition immunity fixture valid")
 var sapped := use(records.warlock20,immune,"warlock-master-20")
 check(sapped.ok and not has_status(sapped.target,"weakened") and sapped.events.any(func(e: Dictionary):return e.get("type")=="status_resisted"),"late invocation respects actual condition immunity")
 var breath := alternative(records["dragonfire-adept12"],{"draconic-element":"fire","draconic-breath-shape":"fire-focused"})
 var normal_breath := use(breath,ordinary,"dragon-focused-fire")
 var resisted_breath := use(breath,resistant,"dragon-focused-fire")
 check(normal_breath.ok and resisted_breath.ok and resisted_breath.target.runtime.hp>normal_breath.target.runtime.hp,"breath uses existing elemental resistance authority")
 var evading := defender(true);evading.runtime.granted_features.append("rogue-evasion")
 var evaded := use(breath,evading,"dragon-focused-fire")
 check(evaded.ok and evaded.target.runtime.hp==evading.runtime.hp and has_status(evaded.actor,"breath-recovering"),"successful Reflex Evasion avoids breath damage but still starts recovery")
 var concealed := defender(false);concealed.runtime.statuses.append({"id":"beguiling-veil","source":"fixture","remaining":3,"expiry":"global_round_start"})
 var veil_cast := use(breath,concealed,"dragon-focused-fire")
 check(veil_cast.ok and veil_cast.target.runtime.hp==normal_breath.target.runtime.hp and veil_cast.rng==normal_breath.rng,"save-based breath bypasses weapon concealment without an attack roll or extra RNG")
 var engine := TacticalAuras.new(breath);var b := encounter(breath);b.board.blocked=[]
 b.units["bandit-blade"].position=[7,5];b=engine.seal(b)
 check(not execute(engine,b,"dragon-focused-fire","bandit-blade").ok,"breath rejects out-of-range command")
 b.units["bandit-blade"].position=[3,1];b.board.blocked=[[2,1]];b=engine.seal(b)
 check(not execute(engine,b,"dragon-focused-fire","bandit-blade").ok,"breath rejects blocked line of sight")

func test_binder_late() -> void:
 var r: Dictionary=records.binder20;var engine := TacticalAuras.new(r);var b := encounter(r);b.board.blocked=[];b=engine.seal(b)
 var summoned := execute(engine,b,"binder-technique-16","a")
 check(summoned.ok,"late Binder summons through existing tactical authority")
 if summoned.ok:
  var summoned_battle: Dictionary=summoned.battle
  var pets: Array=summoned_battle.units.values().filter(func(u: Dictionary):return u.get("entity",{}).get("kind")=="summon")
  check(pets.size()==1 and pets[0].entity.owner_id=="a" and pets[0].entity.remaining==4,"one owned four-boundary covenant sentinel")
  if pets.size()==1:
   var pet: Dictionary=pets[0]
   for tile in engine.neighbours(pet.position):
    if engine.inside(summoned_battle,tile) and engine.occupant(summoned_battle,tile).is_empty():summoned_battle.units["bandit-blade"].position=tile;break
   summoned_battle=engine.seal(summoned_battle)
   var turn := execute(engine,summoned_battle,"end")
   check(turn.ok and engine.current(turn.battle).id==pet.id,"owned sentinel receives actual tactical activation")
   if turn.ok:
    turn.battle.rng=attack_seed(19);turn.battle=engine.seal(turn.battle)
    var attack := execute(engine,turn.battle,"attack","bandit-blade")
    check(attack.ok and attack.battle.units["bandit-blade"].record.runtime.hp<turn.battle.units["bandit-blade"].record.runtime.hp,"sentinel actually attacks")
    if attack.ok:
     battles.binder_summon=attack.battle
     var again: Dictionary=attack.battle
     for n in again.order.size()+1:
      if engine.current(again).id=="a":break
      var ended := execute(engine,again,"end");check(ended.ok,"advance normal summon turn list")
      if not ended.ok:break
      again=ended.battle
     var before := RulesJson.digest(again)
     check(not execute(engine,again,"binder-technique-16","a").ok and RulesJson.digest(again)==before,"no duplicate summon or failed-command resource mutation")
     var dismissed := execute(engine,again,"dismiss",pet.id)
     check(dismissed.ok and not dismissed.battle.units[pet.id].entity.active,"actual covenant summon dismissal")
 var shaped := execute(engine,b,"binder-technique-20","a")
 check(shaped.ok and not RulesEntities.form(shaped.battle.units.a.record,source).is_empty(),"late Binder form actually changes body")
 if shaped.ok:
  check(shaped.battle.units.a.record.advancement_history==b.units.a.record.advancement_history and shaped.battle.units.a.record.runtime.hp==b.units.a.record.runtime.hp,"form preserves history and current health")
  battles.binder_form=shaped.battle

func test_ward_combat() -> void:
 var ward := alternative(records.warlock20,{"warlock-discipline":"ward"})
 var veiled := use(ward,ward,"warlock-invocation-ward")
 check(veiled.ok,"prepare actual ward combat witness")
 if not veiled.ok:return
 var engine := TacticalAuras.new(veiled.actor);var b := encounter(veiled.actor);b.cursor=b.order.find("bandit-blade");b.budget={"main":1,"move":1}
 var found := false
 for n in 5000:
  var rng := RulesRng.initial("ward-native-"+str(n))
  if RulesRng.roll("1d100",rng).total==19:b.rng=rng;found=true;break
 check(found,"lawful deterministic concealed-hit comparison seed")
 b=engine.seal(b)
 var exposed: Dictionary=b.duplicate(true)
 exposed.units.a.record.runtime.statuses=exposed.units.a.record.runtime.statuses.filter(func(s: Dictionary):return s.id!="beguiling-veil")
 exposed=engine.seal(exposed)
 var attack := {"actor_id":"bandit-blade","revision":b.revision,"kind":"attack","target_id":"a"}
 var hidden := engine.command(b,attack);var ordinary := engine.command(exposed,attack)
 check(hidden.ok and ordinary.ok,"real enemy weapon commands against ward")
 if hidden.ok and ordinary.ok:
  check(hidden.battle.units.a.record.runtime.hp==b.units.a.record.runtime.hp and ordinary.battle.units.a.record.runtime.hp<exposed.units.a.record.runtime.hp,"chosen Ward invocation actually prevents a would-hit weapon strike")
  check(hidden.battle.budget.main==0,"concealment still spends enemy main action")
  battles.warlock_ward=hidden.battle

func encounter(record: Dictionary) -> Dictionary:
 var b := super.encounter(record)
 b.units.a.name=str(source.definition("classes",record.advancement_history[0].class_id).name)+" fixture"
 return TacticalAuras.new(record).seal(b)

func test_dragon_levels() -> void:
 for at in [1,6,12,20]:
  var r: Dictionary=records["dragonfire-adept"+str(at)]
  var engine := TacticalAuras.new(r);var b := encounter(r);b.board.blocked=[]
  b.units["bandit-blade"].record=defender(false);b.units["bandit-blade"].record.character_id="bandit-blade";b=engine.seal(b)
  var basic := execute(engine,b,"dragon-breath-fire","bandit-blade")
  check(basic.ok and basic.battle.units["bandit-blade"].record.runtime.hp<b.units["bandit-blade"].record.runtime.hp,"actual basic breath early/middle/high "+str(at))
  if basic.ok:check(basic.battle.units.a.record.runtime.resources==b.units.a.record.runtime.resources,"basic breath never consumes invocation reserve "+str(at))
  var tier: int=1 if at==1 else 6 if at==6 else 11 if at==12 else 16
  for kind in ["ward","veil","hindrance"]:
   var variant := alternative(r,{"draconic-invocation-"+str(tier):kind})
   var action: String="draconic-"+kind+"-"+str(tier)
   var tactical := TacticalAuras.new(variant);var board := encounter(variant);board.board.blocked=[]
   board.units["bandit-blade"].record=defender(false);board.units["bandit-blade"].record.character_id="bandit-blade";board=tactical.seal(board)
   var row := source.definition("abilities",action)
   var target: String="a"if row.targeting.kind=="self"else"b"if row.targeting.kind=="ally"else"bandit-blade"
   var used := execute(tactical,board,action,target)
   check(used.ok,"selected invocation actual legal target "+action)
   if not used.ok:continue
   var status: String="draconic-ward"if kind=="ward"else"beguiling-veil"if kind=="veil"else"mind-tether"
   check(has_status(used.battle.units[target].record,status),"selected invocation actual status "+action)
   check(int(used.battle.units.a.record.runtime.resources["draconic-resolve"])==int(board.units.a.record.runtime.resources["draconic-resolve"])-int(row.cost.resources["draconic-resolve"]),"exact invocation cost once for all affected "+action)
   if row.targeting.kind=="ally":check(not execute(tactical,board,action,"bandit-blade").ok,"ally invocation cannot be aimed at an enemy")
   if tier==16 and kind=="hindrance":check(has_status(used.battle.units[target].record,"weakened"),"late control has distinct additional attack debuff")
   battles["dragon-"+action]=used.battle
