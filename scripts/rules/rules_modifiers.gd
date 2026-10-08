class_name RulesModifiers
extends RefCounted
## Typed positive bonuses keep their maximum. Typed penalties keep their worst.
## Untyped bonuses/penalties stack. Stable source IDs decide equal magnitudes.
static func combine(base: int, modifiers: Array, context: Dictionary) -> Dictionary:
 for m in modifiers:
  if not m is Dictionary or not m.get("type") in RulesRegistry.TYPES or not RulesJson.integer(m.get("value")) or not m.get("source") is String:
   return {"ok":false,"errors":[RulesJson.issue("modifier.schema","modifier","Invalid typed modifier")]}
 for m in modifiers:
  if m.has("when"):
   var errors := RulesExpressions.validate_requirement(m.when)
   if not errors.is_empty(): return RulesJson.result(errors)
 var groups := {}
 var untyped := 0
 var applied: Array = []
 var sorted: Array = modifiers.duplicate(true)
 sorted.sort_custom(func(a: Dictionary,b: Dictionary): return RulesJson.canonical(a)<RulesJson.canonical(b) if a.source==b.source else a.source<b.source)
 for m in sorted:
  if not m is Dictionary or not m.get("type") in RulesRegistry.TYPES or not RulesJson.integer(m.get("value")) or not m.get("source") is String:
   return {"ok":false,"errors":[RulesJson.issue("modifier.schema","modifier","Invalid typed modifier")]}
  if m.has("when"):
   var condition := RulesExpressions.evaluate_requirements(m.when,context)
   if not condition.ok: continue
  if m.type=="untyped": untyped+=int(m.value);applied.append(m)
  else:
   if not groups.has(m.type): groups[m.type]={"positive":null,"negative":null}
   var side := "positive" if m.value>=0 else "negative"
   var existing: Variant = groups[m.type][side]
   if existing==null or (side=="positive" and m.value>existing.value) or (side=="negative" and m.value<existing.value): groups[m.type][side]=m
 var types: Array = groups.keys();types.sort()
 var total := base+untyped
 for type in types:
  for side in ["positive","negative"]:
   if groups[type][side]!=null:
    total+=int(groups[type][side].value);applied.append(groups[type][side])
 if abs(total)>RulesJson.LIMIT: return {"ok":false,"errors":[RulesJson.issue("modifier.range","modifier","Modifier result out of bounds")]}
 return {"ok":true,"value":total,"applied":applied}
