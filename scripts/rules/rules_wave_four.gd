class_name RulesWaveFour
extends RefCounted
## v14 adapters only. Ordinary effects, history, action costs and saves remain authoritative.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id") in ["trhgd-character-v14","trhgd-character-v15","trhgd-character-v16","trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22"]
static func starting_equipment_allowed(item: Dictionary,source: RulesRegistry) -> bool:
 # Natural attacks come from anatomy, forms or creatures, never a new hero's loadout.
 # Existing saved records are not reclassified by this creation-only predicate.
 return (not enabled(source) or not item.get("tags",[]).has("natural")) and (not RulesMartial.enabled(source) or not item.get("tags",[]).has("manifested"))
static func distinct_limit(context: Dictionary,source: RulesRegistry) -> int:
 var limit := 1000
 for cls in context.classes:
  var definition := source.definition("classes",cls)
  if definition.has("distinct_power_limit"):
   limit=mini(limit,int(RulesExpressions.evaluate_formula(definition.distinct_power_limit,context).get("value",0)))
 return limit
static func power_access(record: Dictionary,ability: Dictionary,context: Dictionary,source: RulesRegistry) -> Dictionary:
 if ability.has("psychic_power") and not record.runtime.manifested_powers.has(ability.psychic_power) and record.runtime.manifested_powers.size()>=distinct_limit(context,source):
  return RulesJson.result([RulesJson.issue("psychic.distinct_limit",ability.psychic_power,"Distinct powers per eligible rest exhausted. Reuse an already manifested power or rest at home.")])
 return {"ok":true}
static func validate_runtime(record: Dictionary,context: Dictionary,source: RulesRegistry) -> Array:
 var errors: Array=[]
 var powers: Variant=record.runtime.get("manifested_powers")
 if not powers is Array or powers.size()!=RulesRegistry._unique_count(powers):return [RulesJson.issue("psychic.manifested","runtime","Unique persistent manifested powers required")]
 for id in powers:
  if not id is String or not context.known_powers.has(id):errors.append(RulesJson.issue("psychic.manifested",str(id),"Manifested powers must belong to the permanent learned repertoire"))
 if powers.size()>distinct_limit(context,source):errors.append(RulesJson.issue("psychic.distinct_limit","runtime","Persisted distinct-power allowance exceeded"))
 return errors
static func validate_definition(category: String,row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if row.has("distinct_power_limit"):
  if category!="classes":errors.append(RulesJson.issue("psychic.distinct_schema",row.id,"Limit belongs to a class"))
  RulesRegistry._formula(row.distinct_power_limit,tables,row.id,errors)
  if RulesRegistry._contains_stat(row.distinct_power_limit):errors.append(RulesJson.issue("psychic.distinct_schema",row.id,"Limit must use permanent progression"))
 if row.has("upkeep"):
  var upkeep: Variant=row.upkeep
  if category!="statuses" or not row.has("aura") or not upkeep is Dictionary or upkeep.size()!=2 or not RulesJson.integer(upkeep.get("amount"),1,10):errors.append(RulesJson.issue("upkeep.schema",row.id,"Aura upkeep requires one bounded resource cost"))
  else:RulesRegistry._reference(tables,"resources",upkeep.get("resource"),row.id,errors)
 if row.has("aura"):
  var aura: Variant=row.aura
  if category!="statuses" or not aura is Dictionary or aura.size()!=2 or not RulesJson.integer(aura.get("radius"),1,6) or not aura.get("modifiers") is Array or aura.modifiers.is_empty():errors.append(RulesJson.issue("aura.schema",row.id,"Bounded radius and typed party modifiers required"));return
  RulesRegistry._modifiers(aura.modifiers,tables,row.id,errors)
  for modifier in aura.modifiers:
   if modifier.get("stat")=="HP" or modifier.has("when") or RulesRegistry._contains_stat(modifier.get("value",{})):errors.append(RulesJson.issue("aura.formula",row.id,"Aura magnitude must use unconditional permanent progression, never projected stats"))
static func maintained_cleanup(combat: TacticalCombat,battle: Dictionary) -> void:
 if combat.registry.rules_ref().pack_id!="trhgd-character-v22":return
 for unit in battle.units.values():
  if battle.status!="active" or not combat.alive(unit) or not RulesEntities.form(unit.record,combat.registry).is_empty():
   unit.record.runtime.statuses=unit.record.runtime.statuses.filter(func(s: Dictionary):return not combat.registry.definition("statuses",s.id).has("upkeep"))

static func maintained_activation(combat: TacticalCombat,battle: Dictionary) -> void:
 if combat.registry.rules_ref().pack_id!="trhgd-character-v22" or battle.status!="active":return
 var unit: Dictionary=combat.current(battle)
 if not combat.alive(unit):return
 for instance in unit.record.runtime.statuses.duplicate():
  var definition := combat.registry.definition("statuses",instance.id)
  if not definition.has("upkeep"):continue
  var pool: String=definition.upkeep.resource;var amount: int=int(definition.upkeep.amount)
  if int(unit.record.runtime.resources.get(pool,0))<amount:
   unit.record.runtime.statuses.erase(instance);battle.log.append(unit.name+" stops the maintained performance: reserve exhausted.")
  else:
   unit.record.runtime.resources[pool]=int(unit.record.runtime.resources[pool])-amount
   battle.log.append(unit.name+" maintains the performance; "+str(combat.registry.definition("resources",pool).name)+" -"+str(amount)+". Main action remains available.")

static func project_auras(combat: TacticalCombat,battle: Dictionary) -> void:
 # Recomputed from live positions; never advances RNG or persists a new authority.
 for unit in battle.units.values():
  unit.record.runtime.modifiers=unit.record.runtime.modifiers.filter(func(m: Dictionary):return not str(m.source).begins_with("aura:"))
 if battle.status!="active":return
 for id in battle.order:
  var owner: Dictionary=battle.units[id]
  if not combat.alive(owner) or not RulesEntities.form(owner.record,combat.registry).is_empty():continue
  var instances: Array=owner.record.runtime.statuses.filter(func(instance: Dictionary):return combat.registry.definition("statuses",instance.id).has("aura"))
  if instances.is_empty():continue
  var context: Dictionary=combat.characters.derive_character(owner.record).context
  for instance in instances:
   var definition := combat.registry.definition("statuses",instance.id)
   for ally in battle.units.values():
    if not combat.alive(ally) or ally.team!=owner.team or combat.distance(owner.position,ally.position)>int(definition.aura.radius) or not combat.line_clear(battle,owner.position,ally.position):continue
    for modifier in definition.aura.modifiers:
     var value := RulesExpressions.evaluate_formula(modifier.value,context)
     ally.record.runtime.modifiers.append({"stat":modifier.stat,"type":modifier.type,"value":int(value.value),"source":"aura:"+id+":"+instance.id})
