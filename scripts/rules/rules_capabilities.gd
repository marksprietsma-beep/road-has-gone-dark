class_name RulesCapabilities
extends RefCounted
## Additive v10 capability projection. Earlier exact pins retain their original path.
const FIELDS := ["resistances", "immunities", "blocked_equipment", "weapon_damage", "concealment", "moving_damage", "immobile", "resource_bonuses"]
const DAMAGE_TYPES := ["physical", "arcane", "fire", "cold", "electricity", "acid", "radiant", "psychic", "necrotic", "force"]
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id") in ["trhgd-character-v10","trhgd-character-v11","trhgd-character-v12"]
static func validate(value: Variant,tables: Dictionary,path: String,errors: Array) -> void:
 if not value is Dictionary:errors.append(RulesJson.issue("capability.schema",path,"Expected typed inherited/class capabilities"));return
 for field in value:
  if field not in FIELDS:errors.append(RulesJson.issue("capability.field",path+"."+str(field),"Unknown capability"));continue
  if field=="resistances":
   if not value[field] is Dictionary:errors.append(RulesJson.issue("capability.resistance",path,"Typed damage reductions required"));continue
   for kind in value[field]:
    if kind not in DAMAGE_TYPES or not RulesJson.integer(value[field][kind],0,30):errors.append(RulesJson.issue("capability.resistance",path,"Unknown damage type or unbounded resistance"))
  elif field in ["immunities","blocked_equipment"]:
   if not value[field] is Array or value[field].size()!=RulesRegistry._unique_count(value[field]):errors.append(RulesJson.issue("capability.list",path,"Unique capability references required"));continue
   for id in value[field]:
    if field=="immunities":RulesRegistry._reference(tables,"statuses",id,path,errors)
    elif id not in ["armor","shield","weapon"]:errors.append(RulesJson.issue("capability.equipment",path,"Unknown body equipment slot"))
  elif field=="resource_bonuses":
   if not value[field] is Dictionary:errors.append(RulesJson.issue("capability.resources",path,"Typed resource capacity bonuses required"));continue
   for id in value[field]:
    RulesRegistry._reference(tables,"resources",id,path,errors)
    RulesRegistry._formula(value[field][id],tables,path,errors)
    if value[field][id] is Dictionary and RulesRegistry._contains_stat(value[field][id]):errors.append(RulesJson.issue("capability.resources",path,"Resource bonus must not depend on derived statistics"))
  elif field=="weapon_damage":
   if not value[field] is Dictionary:errors.append(RulesJson.issue("capability.weapon",path,"Weapon overrides must use equipment IDs"));continue
   for id in value[field]:
    RulesRegistry._reference(tables,"equipment",id,path,errors)
    if not value[field][id] is String or not RulesRng.parse_dice(value[field][id]).ok:errors.append(RulesJson.issue("capability.weapon",path,"Valid weapon damage dice required"))
  elif field=="concealment":
   if not RulesJson.integer(value[field],0,50):errors.append(RulesJson.issue("capability.concealment",path,"Weapon miss chance must be 0–50 percent"))
  elif field=="immobile":
   if not value[field] is bool:errors.append(RulesJson.issue("capability.immobile",path,"Boolean movement restriction required"))
  elif field=="moving_damage":RulesRegistry._formula(value[field],tables,path,errors)
static func derive(context: Dictionary,record: Dictionary,source: RulesRegistry,include_runtime: bool) -> Dictionary:
 var result := {"resistances":{},"immunities":[],"blocked_equipment":[],"weapon_damage":{},"concealment":0,"moving_damage":0,"immobile":false,"resource_bonuses":{}}
 var rows: Array=[source.definition("ancestries",record.ancestry_ref)]
 for id in context.features:rows.append(source.definition("features",id))
 if include_runtime:
  for status in record.runtime.statuses:rows.append(source.definition("statuses",status.id))
 for row in rows:
  var caps: Dictionary=row.get("capabilities",{})
  for field in caps:
   if field=="resistances":
    for kind in caps[field]:result[field][kind]=maxi(int(result[field].get(kind,0)),int(caps[field][kind]))
   elif field=="resource_bonuses":
    for id in caps[field]:result[field][id]=int(result[field].get(id,0))+int(RulesExpressions.evaluate_formula(caps[field][id],context).get("value",0))
   elif field=="weapon_damage":
    for id in caps[field]:result[field][id]=caps[field][id]
   elif field in ["immunities","blocked_equipment"]:
    for id in caps[field]:
     if not result[field].has(id):result[field].append(id)
   elif field=="immobile":result.immobile=result.immobile or caps.immobile
   elif field=="moving_damage":result.moving_damage=maxi(int(result.moving_damage),int(RulesExpressions.evaluate_formula(caps[field],context).get("value",0)))
   else:result[field]=maxi(int(result[field]),int(caps[field]))
 return result
static func reduce_damage(amount: int,kind: String,caps: Dictionary) -> int:
 return maxi(0,amount-int(caps.get("resistances",{}).get(kind,0)))
static func summary(caps: Dictionary) -> String:
 var words: Array[String]=[]
 for kind in caps.get("resistances",{}):words.append(str(kind)+" resistance "+str(caps.resistances[kind]))
 for id in caps.get("immunities",[]):words.append("immune to "+str(id).replace("-"," "))
 for id in caps.get("blocked_equipment",[]):words.append("incompatible "+str(id))
 for id in caps.get("resource_bonuses",{}):words.append(str(id).replace("-"," ")+" capacity +"+formula_text(caps.resource_bonuses[id]))
 for id in caps.get("weapon_damage",{}):words.append(str(id)+" damage "+str(caps.weapon_damage[id]))
 if int(caps.get("concealment",0))>0:words.append(str(caps.concealment)+"% weapon concealment")
 if caps.get("moving_damage",0) is Dictionary or int(caps.get("moving_damage",0))>0:words.append("first hit after movement +"+formula_text(caps.moving_damage)+" damage")
 if caps.get("immobile",false):words.append("cannot move")
 return "; ".join(words) if not words.is_empty() else "No additional inherited/class damage or body restrictions"
static func formula_text(value: Variant) -> String:
 if not value is Dictionary:return str(value)
 if value.op=="const":return str(value.value)
 if value.op in ["class_level","casting_level"]:return str(value.id).replace("-"," ").capitalize()+" level"
 if value.has("args"):
  var parts: Array[String]=[]
  for child in value.args:parts.append(formula_text(child))
  return "("+str({"sum":" + ","multiply":" × ","floor_divide":" / "}.get(value.op,", ")).join(parts)+")"
 return str(value.get("id",value.op)).replace("_"," ")
