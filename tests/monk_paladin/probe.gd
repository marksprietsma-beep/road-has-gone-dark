extends "res://tests/class_signatures/mechanics_driver.gd"
## Released30 witnesses. Lawful development histories, no campaign XP grants.
var observations := {}
func make(cls: String,level: int,options: Dictionary={}) -> Dictionary:
 var attributes := {"STR":14,"DEX":13,"CON":12,"INT":10,"WIS":15,"CHA":8} if cls=="monk" else {"STR":14,"DEX":12,"CON":13,"INT":10,"WIS":8,"CHA":15}
 var r := kernel.create("discipline-probe",attributes,"heritage-human")
 return more(r,cls,level,options)
func more(record: Dictionary,cls: String,count: int,options: Dictionary={}) -> Dictionary:
 var r := record.duplicate(true)
 for n in count:
  var proposed := kernel.suggested_choice(r,cls,"steady-study")
  check(proposed.ok,"lawful suggested "+cls+str(n+1))
  if not proposed.ok:return {}
  for key in proposed.choice.specialisations:
   if options.has(key):proposed.choice.specialisations[key]=options[key]
  var result := kernel.preview_advancement(r,proposed.choice)
  check(result.ok,"lawful selected "+cls+str(n+1)+JSON.stringify(result.get("errors",[])))
  if not result.ok:return {}
  r=result.candidate
 r.equipment=["unarmed"] if r.advancement_history.any(func(s: Dictionary):return s.class_id=="monk") else ["shortblade","mail","shield"]
 var d := kernel.derive_character(r);check(d.ok,"lawful development equipment and history "+JSON.stringify(d.get("errors",[])))
 if not d.ok:return {}
 r.runtime.hp=int(d.snapshot.stats.HP);r.runtime.resources=d.snapshot.resource_capacities.duplicate(true)
 return RulesJson.string_keys(r)
func stats_of(r: Dictionary) -> Dictionary:
 var d := kernel.derive_character(r);check(d.ok,"observed state valid")
 return d.get("snapshot",{}).get("stats",{})
func run() -> void:
 base=OS.get_environment("MONK_PALADIN_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v30.json").ok,"released30 reproduction")
 kernel=RulesCharacter.new(source);fixtures.fighter=build("fighter",20)
 var monk := make("monk",2,{"monk-choice-1":"wind"})
 var wind := use(monk,monk,"monk-wind-1");check(wind.ok,"paid Wind step")
 if wind.ok:
  check(stats_of(wind.actor).reflex==stats_of(monk).reflex,"reproduced: paid Wind Reflex swallowed by own Evasion training")
  observations.wind={"before":stats_of(monk),"after":stats_of(wind.actor),"ki_before":monk.runtime.resources.ki,"ki_after":wind.actor.runtime.resources.ki}
 var hybrid := more(make("monk",1),"soulknife",1)
 var manifested := use(hybrid,hybrid,"soulknife-manifest");check(manifested.ok,"actual owned manifestation")
 if manifested.ok:
  var manifested_engine := TacticalAuras.new(manifested.actor);var manifested_battle := encounter(manifested.actor)
  check(manifested_battle.units.a.weapon=="unarmed" and manifested_engine.active_weapon(manifested_battle.units.a)=="mind-blade","original versus actual weapon differs")
  var flurried := execute(manifested_engine,manifested_battle,"flurry","bandit-blade")
  check(flurried.ok,"reproduced: Flurry accepts manifested blade instead of advertised unarmed strikes")
  observations.flurry={"held":manifested_battle.units.a.weapon,"active":manifested_engine.active_weapon(manifested_battle.units.a),"accepted":flurried.ok,"log":flurried.get("battle",{}).get("log",[])}
 var paladin := more(make("paladin",1),"fighter",1);paladin.equipment=["bow","mail"]
 var engine := TacticalAuras.new(paladin);var b := encounter(paladin)
 b=engine.seal(b)
 var used := execute(engine,b,"smite","bandit-blade")
 check(used.ok,"reproduced: described melee Smite accepts a bow")
 observations.smite={"weapon":engine.active_weapon(b.units.a),"accepted":used.ok,"description":source.definition("abilities","smite").description,"log":used.get("battle",{}).get("log",[])}
 # Working mechanics are controls, not assumed redesign requests.
 var unarmed := make("monk",1);var original := encounter(unarmed);engine=TacticalAuras.new(unarmed)
 check(execute(engine,original,"flurry","bandit-blade").ok,"existing free two-strike main-action Flurry is legal")
 var armoured := unarmed.duplicate(true);armoured.equipment=["unarmed","mail"]
 check(not kernel.validate_build(armoured).ok,"existing Monk armour restriction remains authoritative")
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false,"observations":observations,"production_changed":false}
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("MONK_PALADIN_V30_PROBE ",JSON.stringify({"checks":checks,"failures":failures}))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
