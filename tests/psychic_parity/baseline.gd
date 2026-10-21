extends Node
## Frozen v23 reproductions. No progression here is claimed as earned.
var source := RulesRegistry.new()
var kernel: RulesCharacter
var checks := 0
var failures := 0
var traces := {}
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(message)
func _ready() -> void:call_deferred("run")
func build(identity: String,route: Array,attributes: Dictionary,options: Dictionary={},increase := "",feats: Dictionary={},spells: Array=[]) -> Dictionary:
 var record := kernel.create(identity,attributes,"heritage-human")
 for cls in route:
  var suggested := kernel.suggested_choice(record,cls)
  check(suggested.ok,"lawful fixture suggestion "+cls+JSON.stringify(suggested.get("errors",[])))
  if not suggested.ok:return {}
  var choice: Dictionary=suggested.choice
  if feats.has(int(choice.level)):choice.feat_id=feats[int(choice.level)]
  if not increase.is_empty() and not choice.attribute_increase.is_empty():choice.attribute_increase=increase
  for group in options:
   if choice.specialisations.has(group):choice.specialisations[group]=options[group]
  var advanced := kernel.preview_advancement(record,choice)
  check(advanced.ok,"lawful fixture advancement "+cls+JSON.stringify(advanced.get("errors",[])))
  if not advanced.ok:return {}
  record=advanced.candidate
  if not spells.is_empty():
   var owned: Array=kernel.derive_character(record).get("snapshot",{}).get("abilities",[])
   if spells.all(func(id: String):return owned.has(id)):record.choices.prepared_abilities=spells.duplicate()
 var derived := kernel.derive_character(record)
 check(derived.ok,"complete fixture validates "+JSON.stringify(derived.get("errors",[])))
 if not derived.ok:return {}
 record.runtime.hp=int(derived.snapshot.stats.HP)
 record.runtime.resources=kernel._replay(record).context.capacities.duplicate(true)
 return record
func use(actor: Dictionary,target: Dictionary,id: String) -> Dictionary:
 return RulesEffects.new(source).use_ability(actor,target,id,{"main":1,"move":1,"reaction":1},RulesRng.initial("game152-baseline"))
func lost(result: Dictionary,before: Dictionary) -> int:
 check(result.get("ok",false),"baseline effect executes "+JSON.stringify(result.get("errors",[])))
 return int(before.runtime.hp)-int(result.get("target",before).runtime.hp)
func run() -> void:
 check(source.load_pack("res://data/rules/trhgd-character-v23.json").ok,"frozen v23 source")
 kernel=RulesCharacter.new(source)
 var attrs := {"STR":8,"DEX":13,"CON":14,"INT":15,"WIS":12,"CHA":10}
 # Enough health for an independent surge and a later activation's power.
 var foe := build("foe",["fighter","fighter","fighter","fighter","fighter","fighter","fighter","fighter"],attrs)
 var options := {"psion-power-1":"power-kinetic-bolt","psion-second-power":"power-force-screen","psion-discipline":"assault"}
 var assault := build("assault",["psion","psion","psion"],attrs,options)
 options["psion-discipline"]="ward"
 var ward := build("ward",["psion","psion","psion"],attrs,options)
 var wilder := build("wilder",["wilder","wilder","wilder"],{"STR":8,"DEX":13,"CON":14,"INT":12,"WIS":10,"CHA":15},{"wilder-power-1":"power-kinetic-bolt"})
 var mixed := build("mixed",["psion","wilder","wilder","wilder"],{"STR":8,"DEX":12,"CON":14,"INT":15,"WIS":10,"CHA":13},{"psion-power-1":"power-kinetic-bolt","psion-second-power":"power-force-screen","wilder-power-1":"power-thought-thrust"},"INT")
 if foe.is_empty()or assault.is_empty()or ward.is_empty()or wilder.is_empty()or mixed.is_empty():finish();return
 var assault_hit := lost(use(assault,foe,"power-kinetic-bolt"),foe)
 var ward_hit := lost(use(ward,foe,"power-kinetic-bolt"),foe)
 var surge := use(wilder,foe,"wilder-surge");check(surge.ok,"existing finite surge executes")
 if not surge.ok:finish();return
 var fresh := lost(use(wilder,foe,"power-kinetic-bolt"),foe)
 var weakened := lost(use(surge.actor,foe,"power-kinetic-bolt"),foe)
 var hollow := build("hollow",["psion","psion","psion","sorcerer","sorcerer","sorcerer"],{"STR":10,"DEX":14,"CON":13,"INT":15,"WIS":12,"CHA":8},{},"INT",{3:"psychic-discipline"})
 if hollow.is_empty():finish();return
 var actual_arcane := int(RulesCompleteness.spell_tiers(hollow,kernel._replay(hollow).context,source).arcane)
 check(actual_arcane==0 and kernel.available_advancement(hollow).classes.cerebremancer.ok,"reproduce nominal arcane levels qualifying without usable arcane magic")
 var casted := use(mixed,foe,"power-thought-thrust");check(casted.ok,"mixed-origin power executes")
 if not casted.ok:finish();return
 var save: Dictionary=casted.events.filter(func(e: Dictionary):return e.type=="save_resolved")[0]
 var attrs_now: Dictionary=kernel.derive_character(mixed).snapshot.attributes
 var expected_dc := 11+int(floor(float(int(attrs_now.CHA)-10)/2.0))
 check(assault_hit==ward_hit and kernel.derive_character(assault).snapshot.stats.damage>kernel.derive_character(ward).snapshot.stats.damage,"reproduce projected Assault bonus missing from psychic damage")
 check(fresh==weakened and kernel.derive_character(surge.actor).snapshot.stats.damage==-2,"reproduce established Weakened damage penalty missing from psychic damage")
 check(int(save.dc)>expected_dc,"reproduce unrelated Psion INT inflating Wilder-known power DC")
 traces={"assault_damage":assault_hit,"ward_damage":ward_hit,"fresh_psychic_damage":fresh,"weakened_psychic_damage":weakened,"actual_wilder_power_dc":save.dc,"expected_wilder_attribute_dc":expected_dc,"mixed_attributes":attrs_now,"hollow_arcane_tier":actual_arcane,"hollow_prestige_eligible":kernel.available_advancement(hollow).classes.cerebremancer.ok,"surge_point_cost":int(wilder.runtime.resources["psychic-points"])-int(surge.actor.runtime.resources["psychic-points"])}
 finish()
func finish() -> void:
 var base := OS.get_environment("GAME152_ROOT");DirAccess.make_dir_recursive_absolute(base)
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"traces":traces,"development_fixtures":true,"earned_xp":false}
 FileAccess.open(base.path_join("baseline-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME152_BASELINE ",JSON.stringify(proof));get_tree().quit(1 if failures else 0)
