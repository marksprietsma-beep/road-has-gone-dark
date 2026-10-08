class_name RulesRng
extends RefCounted
const VERSION := "sha256-counter-v1"

static func initial(seed_value: String) -> Dictionary:
 return {"version":VERSION,"seed":seed_value,"counter":0}

static func valid_state(state: Dictionary) -> bool:
 return state.size()==3 and state.get("version")==VERSION and state.get("seed") is String and state.seed.length()<=256 and RulesJson.integer(state.get("counter"),0,RulesJson.LIMIT-1)

static func draw(state: Dictionary, sides: int) -> Dictionary:
 if not valid_state(state) or sides<2 or sides>1000000:
  return {"ok":false,"errors":[RulesJson.issue("rng.state","rng","Invalid explicit RNG state or die") ]}
 var next_state := state.duplicate(true)
 var threshold := 4294967296 % sides
 while true:
  if next_state.counter >= RulesJson.LIMIT: return {"ok":false,"errors":[RulesJson.issue("rng.exhausted","rng","Counter exhausted")]}
  var key := RulesJson.canonical([VERSION,next_state.seed,int(next_state.counter)])
  next_state.counter = int(next_state.counter)+1
  var value := key.sha256_text().left(8).hex_to_int()
  if value >= threshold: return {"ok":true,"value":value%sides+1,"rng":next_state}
 return {"ok":false}

static func parse_dice(value: Variant) -> Dictionary:
 var dice := {}
 if value is String:
  var pattern := RegEx.new()
  pattern.compile("^([0-9]{1,3})d([0-9]{1,4})([+-][0-9]{1,5})?$")
  var match_value := pattern.search(value)
  if match_value == null: return {"ok":false,"errors":[RulesJson.issue("dice.syntax","dice","Expected count d sides with an optional signed bonus")]}
  dice = {"count":int(match_value.get_string(1)),"sides":int(match_value.get_string(2)),"bonus":int(match_value.get_string(3)) if not match_value.get_string(3).is_empty() else 0}
 elif value is Dictionary: dice=value.duplicate(true)
 if dice.size()!=3 or not RulesJson.integer(dice.get("count"),1,100) or not RulesJson.integer(dice.get("sides"),2,1000) or not RulesJson.integer(dice.get("bonus"),-10000,10000):
  return {"ok":false,"errors":[RulesJson.issue("dice.bounds","dice","Invalid structured dice or bounds")]}
 return {"ok":true,"dice":RulesJson.normalize(dice)}

static func roll(value: Variant, state: Dictionary) -> Dictionary:
 var parsed := parse_dice(value)
 if not parsed.ok: return parsed
 var rng := state.duplicate(true)
 var rolls: Array[int] = []
 var total: int = parsed.dice.bonus
 for i in int(parsed.dice.count):
  var sample := draw(rng,int(parsed.dice.sides))
  if not sample.ok: return sample
  rng=sample.rng;rolls.append(sample.value);total+=sample.value
 return {"ok":true,"total":total,"rolls":rolls,"rng":rng}

static func saving_throw(bonus: int, dc: int, state: Dictionary) -> Dictionary:
 if abs(bonus)>1000 or dc<0 or dc>1000: return {"ok":false,"errors":[RulesJson.issue("save.bounds","save","Invalid save bonus/DC")]}
 var rolled := roll("1d20",state)
 if not rolled.ok: return rolled
 rolled.merge({"success":rolled.total+bonus>=dc,"bonus":bonus,"dc":dc,"event":{"type":"save_resolved","roll":rolled.total,"bonus":bonus,"dc":dc,"success":rolled.total+bonus>=dc}})
 return rolled

static func attack_roll(bonus: int,defence: int,critical: Dictionary,state: Dictionary) -> Dictionary:
 # A numeric contest only. GAME-33 supplies geometry, eligibility and damage.
 if abs(bonus)>1000 or defence<0 or defence>1000 or critical.size()!=2 or not RulesJson.integer(critical.get("natural"),2,20) or not RulesJson.integer(critical.get("bonus_damage"),0,1000): return RulesJson.result([RulesJson.issue("attack.bounds","attack","Invalid attack/defence/critical contract")])
 var rolled := roll("1d20",state)
 if not rolled.ok: return rolled
 var hit: bool=rolled.total+bonus>=defence
 var is_critical: bool=hit and rolled.total>=int(critical.natural)
 rolled.merge({"hit":hit,"critical":is_critical,"critical_bonus":int(critical.bonus_damage) if is_critical else 0,"event":{"type":"attack_resolved","roll":rolled.total,"bonus":bonus,"defence":defence,"hit":hit,"critical":is_critical}})
 return rolled
