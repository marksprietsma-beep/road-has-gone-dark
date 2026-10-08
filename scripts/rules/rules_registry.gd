class_name RulesRegistry
extends RefCounted
const DEFAULT_PATH := "res://data/rules/trhgd-rules-v1.json"
const CATEGORIES := ["classes","features","feats","skills","resources","statuses","abilities","equipment","ancestries","backgrounds"]
const STATS := ["HP","defence","BAB","melee_attack","ranged_attack","fortitude","reflex","will","stride","reach","initiative","save_dc","damage"]
const TYPES := ["untyped","training","armor","shield","insight","circumstance","condition"]
const EFFECTS := ["modify_stat","grant_feature","spend_resource","restore_resource","damage","heal","apply_status","remove_status","temporary_hp","grant_sense","apparent_effect","defensive_duplicate","hook","save","modify_save"]
const EXPIRY := ["target_activation_end","source_activation_start","source_round_start","global_round_start","eligible_rest","explicit"]
var _pack := {}
var _tables := {}
var errors: Array = []
var content_hash := ""
var loads := 0

func load_pack(path: String = DEFAULT_PATH) -> Dictionary:
 loads+=1
 if not FileAccess.file_exists(path): return _fail([RulesJson.issue("pack.missing",path,"Rules content is unavailable")])
 var parser := JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary:
  return _fail([RulesJson.issue("pack.json",path,"Rules content is not a JSON object")])
 return load_data(parser.data)

func _fail(found: Array) -> Dictionary:
 errors=found;_pack={};_tables={};content_hash=""
 return RulesJson.result(errors)

func load_data(input: Dictionary) -> Dictionary:
 var candidate: Dictionary = RulesJson.normalize(input)
 var found: Array = []
 var required := ["pack_id","schema_version","rules_version","engine_schema","provenance","rules","role_recommendations"]+CATEGORIES
 for field in required:
  if not candidate.has(field): found.append(RulesJson.issue("pack.field",field,"Required pack field is absent"))
 for field in candidate:
  if not field in required: found.append(RulesJson.issue("pack.unknown",str(field),"Unknown pack field"))
 if candidate.get("pack_id")!="trhgd-rules-v1" or candidate.get("schema_version")!=1 or candidate.get("engine_schema")!=1 or candidate.get("rules_version")!="1.0.0": found.append(RulesJson.issue("pack.version","pack","Unsupported pack/schema/engine version"))
 if not candidate.get("provenance") is Dictionary or not candidate.provenance.get("origin") is String or not candidate.provenance.get("license") is String or candidate.provenance.get("origin","").is_empty() or candidate.provenance.get("license","").is_empty(): found.append(RulesJson.issue("pack.provenance","provenance","Original content provenance/licence is required"))
 var tables := {}
 var pattern := RegEx.new();pattern.compile("^[a-z][a-z0-9_-]{0,63}$")
 for category in CATEGORIES:
  tables[category]={}
  if not candidate.get(category) is Array:
   found.append(RulesJson.issue("pack.category",category,"Expected a definition array"));continue
  for row in candidate[category]:
   if not row is Dictionary or not row.get("id") is String or pattern.search(row.id)==null:
    found.append(RulesJson.issue("definition.id",category,"A bounded stable ID is required"));continue
   if tables[category].has(row.id): found.append(RulesJson.issue("definition.duplicate",category+"."+row.id,"Duplicate stable ID"))
   tables[category][row.id]=row
 if not found.is_empty(): return _fail(found)
 for category in CATEGORIES:
  for id in tables[category]:
   _validate_definition(category,tables[category][id],tables,found)
 if not found.is_empty(): return _fail(found)
 _validate_rules(candidate,tables,found)
 if not found.is_empty(): return _fail(found)
 _check_cycles(tables,found)
 if not found.is_empty(): return _fail(found)
 _pack=RulesJson.freeze(candidate);_tables=RulesJson.freeze(tables);content_hash=RulesJson.digest(candidate);errors=[]
 return {"ok":true,"rules_ref":rules_ref()}

func rules_ref() -> Dictionary:
 if _pack.is_empty(): return {}
 return {"pack_id":_pack.pack_id,"schema_version":_pack.schema_version,"rules_version":_pack.rules_version,"content_hash":content_hash,"engine_schema":_pack.engine_schema}

func ready() -> bool: return not _pack.is_empty()
func definition(category: String, id: String) -> Dictionary: return _tables.get(category,{}).get(id,{})
func ids(category: String) -> Array:
 var values: Array = _tables.get(category,{}).keys();values.sort();return values
func rule(id: String) -> Variant: return _pack.get("rules",{}).get(id)
func recommendation(role: String) -> Dictionary: return _pack.get("role_recommendations",{}).get(role,{})
func source_data() -> Dictionary: return _pack.duplicate(true)

static func _reference(tables: Dictionary, category: String, id: Variant, path: String, found: Array) -> void:
 if not id is String or not tables.get(category,{}).has(id): found.append(RulesJson.issue("reference.missing",path,"Unknown "+category+" reference",{"id":id}))

static func _refs(node: Dictionary, tables: Dictionary, path: String, found: Array, requirement: bool) -> void:
 var op: String = node.get("op","")
 var categories := {"class_level":"classes","skill":"skills","feat":"feats","feature":"features","resource":"resources"}
 if categories.has(op): _reference(tables,categories[op],node.get("id"),path,found)
 if op=="stat" and not node.get("id") in STATS: found.append(RulesJson.issue("reference.stat",path,"Unknown derived statistic"))
 if op=="casting" and node.get("id")!="arcane": found.append(RulesJson.issue("reference.casting",path,"Unknown casting tradition"))
 if node.get("args") is Array:
  for i in node.args.size():
   if node.args[i] is Dictionary: _refs(node.args[i],tables,path+"."+str(i),found,requirement)
 if node.get("arg") is Dictionary: _refs(node.arg,tables,path+".not",found,requirement)

static func _formula(node: Variant,tables: Dictionary,path: String,found: Array) -> void:
 var issues := RulesExpressions.validate_formula(node,path);found.append_array(issues)
 if issues.is_empty():
  _refs(node,tables,path,found,false)
  _check_divisors(node,path,found)

static func _check_divisors(node: Dictionary,path: String,found: Array) -> void:
 if node.op=="floor_divide" and node.args[1].op=="const" and node.args[1].value==0: found.append(RulesJson.issue("formula.zero_divisor",path,"Constant zero divisor is prohibited"))
 for child in node.get("args",[]): _check_divisors(child,path,found)

static func _requirement(node: Variant,tables: Dictionary,path: String,found: Array) -> void:
 var issues := RulesExpressions.validate_requirement(node,path);found.append_array(issues)
 if issues.is_empty(): _refs(node,tables,path,found,true)

static func _modifiers(value: Variant,tables: Dictionary,path: String,found: Array) -> void:
 if not value is Array: found.append(RulesJson.issue("modifier.schema",path,"Expected modifier array"));return
 for i in value.size():
  var m: Variant = value[i];var at := path+"."+str(i)
  if not m is Dictionary or not m.get("stat") in STATS or not m.get("type") in TYPES: found.append(RulesJson.issue("modifier.schema",at,"Unknown statistic/type"));continue
  _formula(m.get("value"),tables,at+".value",found)
  if m.has("when"): _requirement(m.when,tables,at+".when",found)

static func _duration(value: Variant,path: String,found: Array) -> void:
 if not value is Dictionary or value.size()!=3 or not value.get("type") in ["round","activation","rest","explicit"] or not RulesJson.integer(value.get("amount"),1,1000) or not value.get("expiry") in EXPIRY: found.append(RulesJson.issue("duration.schema",path,"Invalid explicit duration/expiry"))

static func _amount(value: Variant,tables: Dictionary,path: String,found: Array) -> void:
 if value is Dictionary and value.has("dice"):
  if value.size()!=2 or not RulesRng.parse_dice(value.dice).ok: found.append(RulesJson.issue("dice.invalid",path,"Invalid amount dice"))
  _formula(value.get("bonus"),tables,path+".bonus",found)
 else: _formula(value,tables,path,found)

static func validate_effect(effect: Variant,tables: Dictionary,path: String,found: Array,depth: int = 0) -> void:
 if depth>16 or not effect is Dictionary or not effect.get("op") in EFFECTS: found.append(RulesJson.issue("effect.operator",path,"Unknown, malformed or deep effect"));return
 var op: String = effect.op
 var fields := {"modify_stat":["op","stat","type","value","when"],"modify_save":["op","stat","type","value","when"],"grant_feature":["op","id"],"grant_sense":["op","id"],"spend_resource":["op","id","amount"],"restore_resource":["op","id","amount"],"damage":["op","amount","damage_type"],"heal":["op","amount"],"temporary_hp":["op","amount"],"apply_status":["op","id"],"remove_status":["op","id"],"save":["op","save","dc","on_failure"],"hook":["op","id"],"apparent_effect":["op","descriptor"],"defensive_duplicate":["op","descriptor"]}
 for field in effect:
  if not field in fields[op]: found.append(RulesJson.issue("effect.field",path+"."+str(field),"Unknown effect field"))
 if op in ["modify_stat","modify_save"]:
  if not effect.get("stat") in STATS or not effect.get("type") in TYPES: found.append(RulesJson.issue("effect.modifier",path,"Invalid effect statistic/type"))
  _formula(effect.get("value"),tables,path+".value",found)
  if effect.has("when"): _requirement(effect.when,tables,path+".when",found)
 elif op=="grant_feature": _reference(tables,"features",effect.get("id"),path,found)
 elif op in ["spend_resource","restore_resource"]:
  _reference(tables,"resources",effect.get("id"),path,found);_formula(effect.get("amount"),tables,path+".amount",found)
 elif op in ["damage","heal","temporary_hp"]:
  _amount(effect.get("amount"),tables,path+".amount",found)
  if op=="damage" and (not effect.get("damage_type") is String or effect.damage_type.is_empty()): found.append(RulesJson.issue("effect.damage_type",path,"Damage type required"))
 elif op in ["apply_status","remove_status"]: _reference(tables,"statuses",effect.get("id"),path,found)
 elif op=="grant_sense":
  if not effect.get("id") is String: found.append(RulesJson.issue("effect.sense",path,"Sense ID required"))
 elif op=="hook":
  if not effect.get("id") in RulesHooks.REGISTERED: found.append(RulesJson.issue("hook.unregistered",path,"No trusted hook handler"))
 elif op=="save":
  if not effect.get("save") in RulesExpressions.SAVES: found.append(RulesJson.issue("effect.save",path,"Unknown save"))
  _formula(effect.get("dc"),tables,path+".dc",found)
  if not effect.get("on_failure") is Array: found.append(RulesJson.issue("effect.save_failure",path,"Failure effects required"))
  else:
   for i in effect.on_failure.size(): validate_effect(effect.on_failure[i],tables,path+".on_failure."+str(i),found,depth+1)
 elif op in ["apparent_effect","defensive_duplicate"]:
  var d: Variant=effect.get("descriptor")
  if not d is Dictionary or not d.get("kind") in ["false_target","defensive_duplicate","apparent_obstacle","glamer","concealment","figment"] or d.get("collision")!=false or not d.get("senses") is Array or d.senses.is_empty() or not d.get("presentation") is Dictionary:
   found.append(RulesJson.issue("effect.appearance",path,"A nonphysical, sense-dependent appearance descriptor is required"));return
  _duration(d.get("duration"),path+".duration",found)
  _formula(d.get("dc"),tables,path+".dc",found)
  if not d.get("save") in RulesExpressions.SAVES or not d.get("investigation_trigger") is String or not d.get("bypass_tags") is Array or not RulesJson.integer(d.get("maximum_maintained"),1,10) or not d.get("replacement") in ["cancel_prior","reject"] or not d.get("break_conditions") is Array or not d.get("success") is String or not d.get("failure") is String: found.append(RulesJson.issue("effect.observer",path,"Explicit observer/disbelief/maintenance metadata is required"))

static func _validate_definition(category: String,row: Dictionary,tables: Dictionary,found: Array) -> void:
 var path: String = category+"."+row.id
 var allowed := {
  "classes":["id","name","max_level","requirements","hp_per_level","skill_points","bab","saves","casting","casting_tradition","features","provenance"],
  "features":["id","name","modifiers","abilities","resources","tags","senses","hooks","grants","provenance"],
  "feats":["id","name","requirements","features","repeatable","choice_parameters","provenance"],
  "skills":["id","name","attribute","trained_only","max_rank","tags","modifiers","provenance"],
  "resources":["id","name","capacity","refresh","provenance"],
  "statuses":["id","tags","duration","stacking","modifiers","effects","provenance"],
  "abilities":["id","name","cost","effects","tags","timing","requirements","targeting","provenance","movement","trigger","follow_up"],
  "equipment":["id","name","kind","requirements","modifiers","tags","reach","range","damage","damage_type","provenance"],
  "ancestries":["id","people_id","tags","features","modifiers","provenance"],
  "backgrounds":["id","tags","features","modifiers","provenance"]
 }
 var optional := ["movement","trigger","follow_up","reach","range","damage","damage_type"]
 for field in allowed[category]:
  if not field in optional and not row.has(field): found.append(RulesJson.issue("definition.field_missing",path+"."+field,"Required definition field absent"))
 for field in row:
  if not field in allowed[category]: found.append(RulesJson.issue("definition.field",path+"."+str(field),"Unknown definition field"))
 if not row.get("provenance") is Dictionary or not row.provenance.get("license") is String: found.append(RulesJson.issue("definition.provenance",path,"Definition provenance is required"))
 if category not in ["resources","statuses","ancestries","backgrounds"] and (not row.get("name") is String or row.name.is_empty()): found.append(RulesJson.issue("definition.name",path,"Name required"))
 if row.has("requirements"): _requirement(row.requirements,tables,path+".requirements",found)
 if row.has("modifiers"):
  if category=="skills":
   if not row.modifiers is Array: found.append(RulesJson.issue("skill.modifiers",path,"Skill modifier array required"))
   else:
    for m in row.modifiers:
     if not m is Dictionary: found.append(RulesJson.issue("skill.modifier",path,"Skill modifier object required"));continue
     var typed: Dictionary=m.duplicate(true);typed.stat="damage"
     _modifiers([typed],tables,path+".modifiers",found)
  else: _modifiers(row.modifiers,tables,path+".modifiers",found)
 if category=="classes":
  if not RulesJson.integer(row.get("max_level"),1,20) or not RulesJson.integer(row.get("hp_per_level"),1,30) or not RulesJson.integer(row.get("skill_points"),1,10): found.append(RulesJson.issue("class.progression",path,"Invalid bounded progression"))
  if not row.get("casting_tradition") in ["","arcane"]: found.append(RulesJson.issue("class.casting",path,"Unsupported casting tradition"))
  _formula(row.get("bab"),tables,path+".bab",found)
  _formula(row.get("casting"),tables,path+".casting",found)
  if not row.get("saves") is Dictionary: found.append(RulesJson.issue("class.saves",path,"Save progression required"))
  else:
   for save in RulesExpressions.SAVES: _formula(row.saves.get(save),tables,path+"."+save,found)
  if not row.get("features") is Array: found.append(RulesJson.issue("class.features",path,"Tiered features required"))
  else:
   var seen := {}
   for tier in row.features:
    if not tier is Dictionary or not RulesJson.integer(tier.get("at"),1,int(row.get("max_level",20))): found.append(RulesJson.issue("class.tier",path,"Invalid tier"));continue
    _reference(tables,"features",tier.get("id"),path,found)
    var key := str(tier.at)+":"+str(tier.get("id"))
    if seen.has(key): found.append(RulesJson.issue("class.tier_duplicate",path,"Duplicate feature tier"))
    seen[key]=true
 elif category=="features":
  for pair in [["abilities","abilities"],["resources","resources"],["grants","features"]]:
   if not row.get(pair[0]) is Array: found.append(RulesJson.issue("feature.list",path,"Feature reference array required"));continue
   for id in row[pair[0]]: _reference(tables,pair[1],id,path+"."+pair[0],found)
  if not row.get("hooks") is Array: found.append(RulesJson.issue("feature.hooks",path,"Hook list required"))
  else:
   for id in row.hooks:
    if not id in RulesHooks.REGISTERED: found.append(RulesJson.issue("hook.unregistered",path,"Unknown hook"))
 elif category=="feats":
  if not row.get("repeatable") is bool or not row.get("choice_parameters") is Array or not row.get("features") is Array: found.append(RulesJson.issue("feat.schema",path,"Explicit repeatability/choices/features required"))
  else:
   for id in row.features: _reference(tables,"features",id,path,found)
 elif category=="skills":
  if not row.get("attribute") in RulesExpressions.ATTRIBUTES or not row.get("trained_only") is bool or row.get("max_rank")!="character_level": found.append(RulesJson.issue("skill.schema",path,"Invalid skill attribute/rank rule"))
 elif category=="resources":
  _formula(row.get("capacity"),tables,path+".capacity",found)
  if not row.get("refresh") in ["encounter","eligible_rest","short_rest","daily","explicit"]: found.append(RulesJson.issue("resource.refresh",path,"Unknown refresh scope"))
 elif category=="statuses":
  _duration(row.get("duration"),path+".duration",found)
  if not row.get("stacking") in ["refresh","replace","reject","stack"]: found.append(RulesJson.issue("status.stacking",path,"Unknown stacking rule"))
  if not row.get("effects") is Array: found.append(RulesJson.issue("status.effects",path,"Explicit status effects required"))
  else:
   for i in row.effects.size(): validate_effect(row.effects[i],tables,path+".effects."+str(i),found)
 elif category=="abilities":
  var cost: Variant=row.get("cost")
  if not cost is Dictionary or cost.size()!=4 or not cost.get("resources") is Dictionary: found.append(RulesJson.issue("ability.cost",path,"Structured move/main/shared-reaction costs required"))
  else:
   for key in ["move","main","reaction"]:
    if not RulesJson.integer(cost.get(key),0,1): found.append(RulesJson.issue("ability.cost",path+"."+key,"Invalid action token cost"))
   for id in cost.resources:
    _reference(tables,"resources",id,path,found)
    if not RulesJson.integer(cost.resources[id],1,100): found.append(RulesJson.issue("ability.resource_cost",path,"Invalid resource cost"))
  var timing: Variant=row.get("timing")
  if not timing is Dictionary or not timing.get("kind") in ["instant","next_activation","after_event"]: found.append(RulesJson.issue("ability.timing",path,"Unknown timing contract"))
  elif timing.kind!="instant" and (not timing.get("interruptible") is bool or timing.get("locked_target")!="tile" or not timing.get("cancel_event") is String): found.append(RulesJson.issue("ability.delayed",path,"Explicit delayed target/cancellation required"))
  if not row.get("targeting") is Dictionary or not row.get("targeting",{}).get("kind") in ["self","creature","ally","tile","tile_or_apparent"]: found.append(RulesJson.issue("ability.targeting",path,"Known targeting descriptor required"))
  if not row.get("effects") is Array: found.append(RulesJson.issue("ability.effects",path,"Effect array required"))
  else:
   for i in row.effects.size(): validate_effect(row.effects[i],tables,path+".effects."+str(i),found)
 elif category=="equipment":
  if not row.get("kind") in ["weapon","armor","shield","utility"]: found.append(RulesJson.issue("equipment.kind",path,"Unknown equipment kind"))
  if row.get("kind")=="weapon":
   if not RulesRng.parse_dice(row.get("damage")).ok or not RulesJson.integer(row.get("reach"),1,20) or not RulesJson.integer(row.get("range"),1,50): found.append(RulesJson.issue("equipment.weapon",path,"Invalid dice/range/reach"))
 elif category in ["ancestries","backgrounds"]:
  if not row.get("features") is Array: found.append(RulesJson.issue("heritage.features",path,"Feature list required"))
  else:
   for id in row.features: _reference(tables,"features",id,path,found)
 if row.has("tags") and (not row.tags is Array or not row.tags.all(func(t: Variant): return t is String)): found.append(RulesJson.issue("definition.tags",path,"Tags must be strings"))
 if row.has("senses") and (not row.senses is Array or not row.senses.all(func(t: Variant): return t is String)): found.append(RulesJson.issue("definition.senses",path,"Senses must be strings"))

static func _validate_rules(pack: Dictionary,tables: Dictionary,found: Array) -> void:
 var rules: Variant=pack.get("rules")
 if not rules is Dictionary: found.append(RulesJson.issue("rules.schema","rules","Rules object required"));return
 var fields := ["max_level","base_hp","base_defence","base_stride","base_reach","shared_reaction","feat_levels","attribute_increase_levels","base_abilities","standard_array","engaged_ranged","critical","save_natural_overrides"]
 for field in rules:
  if not field in fields: found.append(RulesJson.issue("rules.field",str(field),"Unknown root rule"))
 var critical: Variant=rules.get("critical")
 if not critical is Dictionary or critical.size()!=2 or not RulesJson.integer(critical.get("natural"),2,20) or not RulesJson.integer(critical.get("bonus_damage"),0,1000): found.append(RulesJson.issue("rules.critical","critical","Explicit critical metadata required"))
 if rules.get("save_natural_overrides")!=false: found.append(RulesJson.issue("rules.save","save","V1 numeric saves have no natural overrides"))
 for field in ["max_level","base_hp","base_defence","base_stride","base_reach","shared_reaction"]:
  if not RulesJson.integer(rules.get(field),1,100): found.append(RulesJson.issue("rules.value","rules."+field,"Bounded integer required"))
 if rules.get("max_level")!=20 or rules.get("shared_reaction")!=1: found.append(RulesJson.issue("rules.contract","rules","V1 supports total level20 and exactly one shared reaction"))
 for key in ["feat_levels","attribute_increase_levels"]:
  if not rules.get(key) is Array or not rules[key].all(func(n: Variant): return RulesJson.integer(n,1,20)) or rules[key].size()!=_unique_count(rules[key]): found.append(RulesJson.issue("rules.schedule",key,"Unique level schedule required"))
 if not rules.get("standard_array") is Array or rules.standard_array.size()!=6 or not rules.standard_array.all(func(v: Variant): return RulesJson.integer(v,3,18)):
  found.append(RulesJson.issue("rules.array","standard_array","Six legal deterministic scores required"));return
 if not rules.get("base_abilities") is Array: found.append(RulesJson.issue("rules.abilities","base_abilities","Ability list required"))
 else:
  for id in rules.base_abilities: _reference(tables,"abilities",id,"base_abilities",found)
 _modifiers([rules.get("engaged_ranged")],tables,"engaged_ranged",found)
 if not pack.get("role_recommendations") is Dictionary: found.append(RulesJson.issue("rules.roles","roles","Role recommendations required"));return
 for role in ["vanguard","scout","adept","expert"]:
  var r: Variant=pack.role_recommendations.get(role)
  if not r is Dictionary: found.append(RulesJson.issue("rules.role",role,"Role recommendation is missing"));continue
  _reference(tables,"classes",r.get("class"),role,found);_reference(tables,"feats",r.get("feat"),role,found)
  if not r.get("attributes") is Dictionary or r.attributes.size()!=6: found.append(RulesJson.issue("rules.attributes",role,"Six allocated scores required"))
  else:
   var values: Array = r.attributes.values();values.sort()
   var expected: Array = rules.get("standard_array",[]).duplicate();expected.sort()
   if values!=expected: found.append(RulesJson.issue("rules.attributes",role,"Allocation must be the exact standard array"))
   for attribute in RulesExpressions.ATTRIBUTES:
    if not r.attributes.has(attribute): found.append(RulesJson.issue("rules.attributes",role,"Unknown/missing attribute"))
  if not r.get("equipment") is Array: found.append(RulesJson.issue("rules.equipment",role,"Loadout references required"))
  else:
   for id in r.equipment: _reference(tables,"equipment",id,role,found)

static func _check_cycles(tables: Dictionary,found: Array) -> void:
 var visiting := {};var done := {}
 for id in tables.features: _visit_feature(id,tables.features,visiting,done,found)

static func _visit_feature(id: String,features: Dictionary,visiting: Dictionary,done: Dictionary,found: Array) -> void:
 if done.has(id) or not features.has(id): return
 if visiting.has(id): found.append(RulesJson.issue("reference.cycle","features."+id,"Feature-grant cycle"));return
 visiting[id]=true
 for child in features[id].get("grants",[]): _visit_feature(child,features,visiting,done,found)
 visiting.erase(id);done[id]=true

static func _unique_count(values: Array) -> int:
 var seen := {}
 for value in values: seen[value]=true
 return seen.size()
