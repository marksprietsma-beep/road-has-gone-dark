extends "res://tests/class_signatures/mechanics_driver.gd"
## Released31 reproduction. Every history is replayed by the existing authority.
var observations := {}
func make(level: int,style := "archery",pet := "wolf",ancestry := "heritage-human") -> Dictionary:
 var r := kernel.create("ranger-probe",{"STR":13,"DEX":15,"CON":12,"INT":10,"WIS":14,"CHA":8},ancestry)
 var result := more(r,"ranger",level,{"ranger-choice-1":style,"ranger-choice-6":style,"ranger-choice-15":style,"ranger-companion":pet})
 if not result.is_empty():result.equipment=["shortblade","leathers"]if style=="blade"else["bow","leathers"]
 return result
func more(record: Dictionary,cls: String,count: int,options: Dictionary={}) -> Dictionary:
 var r := record.duplicate(true)
 for n in count:
  var proposed := kernel.suggested_choice(r,cls,"steady-study")
  check(proposed.ok,"lawful suggested "+cls+str(n+1))
  if not proposed.ok:return {}
  for key in proposed.choice.specialisations:
   if options.has(key):proposed.choice.specialisations[key]=options[key]
  if (r.advancement_history.size()+1)%4==0:proposed.choice.attribute_increase="WIS"
  var out := kernel.preview_advancement(r,proposed.choice)
  check(out.ok,"lawful selected "+cls+str(n+1)+JSON.stringify(out.get("errors",[])))
  if not out.ok:return {}
  r=out.candidate
 if r.equipment.is_empty():r.equipment=["bow","leathers"]
 var d := kernel.derive_character(r);check(d.ok,"legal history, equipment and owned creature "+JSON.stringify(d.get("errors",[])))
 if not d.ok:return {}
 r.runtime.hp=int(d.snapshot.stats.HP);r.runtime.resources=d.snapshot.resource_capacities.duplicate(true)
 return RulesJson.string_keys(r)
func stats_of(r: Dictionary) -> Dictionary:
 var d := kernel.derive_character(r);check(d.ok,"observed legal state")
 return d.get("snapshot",{}).get("stats",{})
func run() -> void:
 base=OS.get_environment("RANGER_STEWARD_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v31.json").ok,"released31 exact pin")
 kernel=RulesCharacter.new(source);fixtures.fighter=build("fighter",20)
 var ranger := make(1,"blade");ranger.equipment=["shortblade","leathers"]
 var engine := TacticalAuras.new(ranger);var b := encounter(ranger);b.rng=attack_seed(19);b=engine.seal(b)
 var shot := execute(engine,b,"aimed-shot","bandit-blade")
 check(shot.ok,"reproduced: described Bow Aimed Shot accepts an actual shortblade")
 observations.aimed_shot={"weapon":engine.active_weapon(b.units.a),"description":source.definition("abilities","aimed-shot").description,"accepted":shot.ok,"log":shot.get("battle",{}).get("log",[])}
 ranger=make(1);ranger.equipment=["shortblade","leathers"]
 var paid := use(ranger,ranger,"ranger-archery-1");check(paid.ok,"real paid Archery style")
 if paid.ok:
  check(stats_of(paid.actor).damage==stats_of(ranger).damage+2,"reproduced: Archery style adds damage to a melee weapon")
  engine=TacticalAuras.new(ranger);b=encounter(ranger);b.rng=attack_seed(19);b=engine.seal(b)
  var plain := execute(engine,b,"attack","bandit-blade")
  var active := b.duplicate(true);active.units.a.record=paid.actor.duplicate(true);active.units.a.record.character_id="a";active=engine.seal(active)
  var boosted := execute(engine,active,"attack","bandit-blade")
  check(plain.ok and boosted.ok and boosted.battle.units["bandit-blade"].record.runtime.hp==plain.battle.units["bandit-blade"].record.runtime.hp-2,"reproduced: exact same melee attack/RNG gains2 Archery damage")
  observations.archery={"before":stats_of(ranger),"after":stats_of(paid.actor),"before_resolve":ranger.runtime.resources["tracker-resolve"],"after_resolve":paid.actor.runtime.resources["tracker-resolve"],"plain":plain.get("battle",{}).get("log",[]),"boosted":boosted.get("battle",{}).get("log",[])}
 var owner := make(4);var id: String=RulesEntities.identity(owner.character_id)
 owner.runtime.companions[id].record.runtime.hp=0
 check(kernel.validate_build(owner).ok,"defeated owned companion is a valid persistent record")
 var proposal := kernel.suggested_choice(owner,"ranger");check(proposal.ok,"normal next Ranger level after companion defeat")
 var grown := kernel.preview_advancement(owner,proposal.choice);check(grown.ok,"legal companion growth")
 if grown.ok:
  check(grown.candidate.runtime.companions[id].record.runtime.hp>0,"reproduced: advancement revives defeated companion without eligible rest")
  observations.growth={"before":owner.runtime.companions[id],"after":grown.candidate.runtime.companions[id],"owner_identity":owner.character_id,"pin":owner.rules_ref}
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"observations":observations,"development_fixtures":true,"earned_xp":false,"production_changed":false}
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("RANGER_STEWARD_V31_PROBE ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
