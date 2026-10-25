extends "res://tests/dual_prestige_acceptance/base.gd"
## Additional original mechanics acceptance; no new rules or campaign writes.
func run() -> void:
 base=OS.get_environment("DUAL_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 source=RulesRecords.registry(saved.records.champion20);kernel=RulesCharacter.new(source)
 if OS.get_environment("DUAL_RESTART")=="1":
  var rows: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("interactions-saved.json")))
  for key in rows.records:check(kernel.derive_character(rows.records[key]).snapshot.snapshot_hash==rows.hashes[key],"exact ward/caster cold state "+key)
  for key in rows.battles:
   var b: Dictionary=rows.battles[key];var engine := TacticalAuras.new(b.units.a.record)
   check(engine.validate(b).is_empty(),"exact interaction battle remains valid "+key)
   var next := engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"})
   check(next.ok and next.battle.state_hash==rows.next[key],"same next command/log/RNG after restart "+key)
  complete_interactions(true);return
 fixtures.fighter=saved.records.fighter
 var r := select(saved.records["champion:retaliation5"],"duskblade-searing-grasp")
 check(kernel.derive_character(r).ok,"lawful Champion selected own Duskblade spell")
 var defender := warded_defender()
 for roll in [1,19,20]:
  var b := encounter(r);b.units["bandit-blade"].record=defender.duplicate(true);b.units["bandit-blade"].record.character_id="bandit-blade";b.rng=attack_seed(roll)
  var engine := TacticalAuras.new(r);b=engine.seal(b)
  var plain := engine.command(b,order(b,"attack"));var out := engine.command(b,order(b,"channel-duskblade-searing-grasp"))
  check(plain.ok and out.ok,"Champion's real selected caster channels with actual melee roll "+str(roll))
  if not out.ok or not plain.ok:continue
  check(out.battle.budget.main==0 and out.battle.units.a.record.runtime.resources["duskblade-slots-1"]==b.units.a.record.runtime.resources["duskblade-slots-1"]-1,"own slot paid on hit/miss; no free prestige casting")
  check(out.battle.units.a.record.runtime.resources["abjurant-resolve"]==b.units.a.record.runtime.resources["abjurant-resolve"],"spell channel never borrows or spends resolve")
  check(not engine.command(out.battle,order(out.battle,"abjurant-retaliation-1")).ok,"channel and Retaliation compete for the same main action")
  if roll==1:check(out.battle.units["bandit-blade"].record==plain.battle.units["bandit-blade"].record and out.battle.rng==plain.battle.rng,"numeric miss spends slot without hidden spell effect or extra RNG")
  else:
   var expected := RulesWaveFive.channel_effects(out.battle.units.a.record,plain.battle.units["bandit-blade"].record,"duskblade-searing-grasp",plain.battle.rng,source)
   check(expected.ok and expected.target==out.battle.units["bandit-blade"].record and expected.rng==out.battle.rng,"exact ordinary melee plus one original spell effect")
  battles[str(roll)]=out.battle
 var ward := use(saved.records["champion:aegis5"],fixtures.fighter,"abjurant-aegis-1");check(ward.ok,"actual paid defensive equipment-compatible Aegis")
 if ward.ok:
  var caster := prep(build("wizard",20),"wizard-arcane-bolt")
  var plain := use(caster,fixtures.fighter,"wizard-arcane-bolt");var protected := use(caster,ward.target,"wizard-arcane-bolt")
  check(plain.ok and protected.ok,"same real force spell against original and warded armoured target")
  if plain.ok and protected.ok:
   var raw: int=int(fixtures.fighter.runtime.hp)-int(plain.target.runtime.hp)
   check(raw>3 and protected.events.any(func(e: Dictionary):return e.type=="damage_resisted" and e.amount==3),"real mental shelter force resistance3 before the buffer")
   var remaining: int=maxi(0,raw-3)
   check(protected.target.runtime.temporary_hp==maxi(0,9-remaining) and protected.target.runtime.hp==int(fixtures.fighter.runtime.hp)-maxi(0,remaining-9),"actual resistance then finite temporary HP, no invented health or stacking")
   saved_records.ward_spent=protected.target
  var expired: Dictionary=ward.target.duplicate(true)
  for n in 3:expired.runtime=RulesEffects.new(source).expire_statuses(expired.runtime,"global_round_start").runtime
  check(not expired.runtime.statuses.any(func(s: Dictionary):return s.id in ["runic-shell","spirit-shelter"]),"actual Aegis status duration expires after three global boundaries")
  var after := kernel.derive_character(expired).snapshot;var before := kernel.derive_character(fixtures.fighter).snapshot
  check(after.stats.defence==before.stats.defence and after.stats.will==before.stats.will and expired.runtime.temporary_hp==9,"expiry removes defence/mental protection; separate buffer follows existing policy")
  saved_records.ward_expired=expired
 var healing := use(saved.records["wizard:theurge3"],fixtures.fighter,"mystic-theurge-power-3");check(healing.ok,"middle Theurge restoration executes at its real path level3")
 if healing.ok:check(healing.actor.runtime.resources["mystic-theurge-uses"]==saved.records["wizard:theurge3"].runtime.resources["mystic-theurge-uses"]-1 and healing.budget.main==0,"middle support pays one own finite use and main action")
 var rows := {"records":saved_records,"hashes":{},"battles":battles,"next":{}}
 for key in saved_records:rows.hashes[key]=kernel.derive_character(saved_records[key]).snapshot.snapshot_hash
 for key in battles:
  var b: Dictionary=battles[key];var engine := TacticalAuras.new(b.units.a.record)
  rows.next[key]=engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"}).battle.state_hash
 FileAccess.open(base.path_join("interactions-saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(rows)))
 complete_interactions()
func complete_interactions(cold := false) -> void:
 FileAccess.open(base.path_join("interactions-restart-proof.json" if cold else "interactions-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"scope":"Actual Champion melee spell channel/slot/action competition, armour-compatible Aegis resistance/buffer/expiry and middle Theurge support; exact cold continuation"}))
 get_tree().quit(1 if failures else 0)
