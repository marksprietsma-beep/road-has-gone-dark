class_name RulesExpressions
extends RefCounted
const ATTRIBUTES := ["STR", "DEX", "CON", "INT", "WIS", "CHA"]
const SAVES := ["fortitude", "reflex", "will"]
const FORMULA_OPS := ["const", "attribute", "modifier", "level", "class_level", "stat", "sum", "min", "max", "multiply", "floor_divide"]
const REQUIREMENT_OPS := ["all", "any", "not", "level", "class_level", "attribute", "skill", "feat", "feature", "tag", "bab", "save", "casting", "resource", "ancestry"]

static func validate_formula(node: Variant, path: String = "formula", depth: int = 0) -> Array:
 var errors: Array = []
 if depth > 24 or not node is Dictionary or not node.get("op") in FORMULA_OPS:
  return [RulesJson.issue("formula.operator",path,"Unknown, malformed or excessively deep formula")]
 var op: String = node.op
 var fields: Array = ["op"]
 if op == "const":
  fields.append("value")
  if not RulesJson.integer(node.get("value")): errors.append(RulesJson.issue("formula.value",path,"An integer constant is required"))
 elif op in ["attribute", "modifier"]:
  fields.append("id")
  if not node.get("id") in ATTRIBUTES: errors.append(RulesJson.issue("formula.attribute",path,"Unknown attribute"))
 elif op in ["class_level", "stat"]:
  fields.append("id")
  if not node.get("id") is String or node.id.is_empty(): errors.append(RulesJson.issue("formula.reference",path,"A stable reference is required"))
 elif op in ["sum", "min", "max", "multiply", "floor_divide"]:
  fields.append("args")
  if not node.get("args") is Array or node.args.is_empty() or node.args.size() > 16 or (op == "floor_divide" and node.args.size() != 2):
   errors.append(RulesJson.issue("formula.arguments",path,"Invalid formula arity"))
  else:
   for i in node.args.size(): errors.append_array(validate_formula(node.args[i],path+".args."+str(i),depth+1))
 for field in node:
  if not field in fields: errors.append(RulesJson.issue("formula.field",path+"."+str(field),"Unexpected formula field"))
 return errors

static func evaluate_formula(node: Dictionary, context: Dictionary) -> Dictionary:
 var errors := validate_formula(node)
 if not errors.is_empty(): return {"ok":false,"errors":errors}
 return _formula(node,context)

static func _formula(node: Dictionary, context: Dictionary) -> Dictionary:
 var op: String = node.op
 var value := 0
 if op == "const": value = int(node.value)
 elif op == "level": value = int(context.get("level",0))
 elif op == "class_level": value = int(context.get("classes",{}).get(node.id,0))
 elif op in ["attribute", "modifier"]:
  value = int(context.get("attributes",{}).get(node.id,10))
  if op == "modifier": value = int(floor(float(value-10)/2.0))
 elif op == "stat":
  if not context.get("stats",{}).has(node.id): return {"ok":false,"errors":[RulesJson.issue("formula.context","stat."+node.id,"Required derived input is absent")]}
  value = int(context.stats[node.id])
 else:
  var values: Array[int] = []
  for child in node.args:
   var evaluated := _formula(child,context)
   if not evaluated.ok: return evaluated
   values.append(evaluated.value)
  value = values[0] if op in ["min","max","multiply"] else 0
  if op == "floor_divide":
   if values[1] == 0: return {"ok":false,"errors":[RulesJson.issue("formula.zero_divisor","formula","Division by zero")]}
   value = int(floor(float(values[0])/float(values[1])))
  else:
   for i in values.size():
    if op == "sum": value += values[i]
    elif op == "min": value = mini(value,values[i])
    elif op == "max": value = maxi(value,values[i])
    elif op == "multiply" and i > 0:
     if values[i] != 0 and abs(value) > RulesJson.LIMIT / abs(values[i]): return {"ok":false,"errors":[RulesJson.issue("formula.range","formula","Multiplication exceeds supported range")]}
     value *= values[i]
    if abs(value)>RulesJson.LIMIT: return {"ok":false,"errors":[RulesJson.issue("formula.range","formula","Formula exceeds supported range")]}
 if abs(value)>RulesJson.LIMIT: return {"ok":false,"errors":[RulesJson.issue("formula.range","formula","Formula exceeds supported range")]}
 return {"ok":true,"value":value}

static func validate_requirement(node: Variant, path: String = "requirements", depth: int = 0) -> Array:
 if depth > 24 or not node is Dictionary or not node.get("op") in REQUIREMENT_OPS:
  return [RulesJson.issue("requirement.operator",path,"Unknown, malformed or excessively deep requirement")]
 var errors: Array = []
 var op: String = node.op
 var fields: Array = ["op"]
 if op in ["all","any"]:
  fields.append("args")
  if not node.get("args") is Array or node.args.size()>32 or (op == "any" and node.args.is_empty()): errors.append(RulesJson.issue("requirement.arguments",path,"Invalid logical argument list"))
  else:
   for i in node.args.size(): errors.append_array(validate_requirement(node.args[i],path+"."+str(i),depth+1))
 elif op == "not":
  fields.append("arg")
  errors.append_array(validate_requirement(node.get("arg"),path+".not",depth+1))
 else:
  if op not in ["level","bab"]:
   fields.append("id")
   if not node.get("id") is String or node.id.is_empty(): errors.append(RulesJson.issue("requirement.reference",path,"A stable reference is required"))
   elif op == "attribute" and not node.id in ATTRIBUTES: errors.append(RulesJson.issue("requirement.attribute",path,"Unknown attribute"))
   elif op == "save" and not node.id in SAVES: errors.append(RulesJson.issue("requirement.save",path,"Unknown save"))
  if op in ["level","class_level","attribute","skill","bab","save","casting","resource"]:
   fields.append("min")
   if not RulesJson.integer(node.get("min"),0,1000): errors.append(RulesJson.issue("requirement.minimum",path,"A bounded integer minimum is required"))
 for field in node:
  if not field in fields: errors.append(RulesJson.issue("requirement.field",path+"."+str(field),"Unexpected requirement field"))
 return errors

static func evaluate_requirements(node: Dictionary, context: Dictionary) -> Dictionary:
 var errors := validate_requirement(node)
 if not errors.is_empty(): return RulesJson.result(errors)
 return RulesJson.result(_requirements(node,context,"requirements"))

static func _requirements(node: Dictionary, context: Dictionary, path: String) -> Array:
 var op: String = node.op
 if op in ["all","any"]:
  var errors: Array = []
  for i in node.args.size():
   var child := _requirements(node.args[i],context,path+"."+str(i))
   if op == "any" and child.is_empty(): return []
   errors.append_array(child)
  return errors
 if op == "not":
  return [RulesJson.issue("requirement.not",path,"An excluded requirement is satisfied")] if _requirements(node.arg,context,path+".not").is_empty() else []
 var current: Variant = 0
 var expected: Variant = node.get("min",true)
 if op == "level": current = context.get("level",0)
 elif op == "bab": current = context.get("stats",{}).get("BAB",0)
 elif op == "class_level": current = context.get("classes",{}).get(node.id,0)
 elif op == "attribute": current = context.get("attributes",{}).get(node.id,0)
 elif op == "skill": current = context.get("skills",{}).get(node.id,0)
 elif op == "save": current = context.get("stats",{}).get(node.id,0)
 elif op == "casting": current = context.get("casting",{}).get(node.id,0)
 elif op == "resource": current = context.get("capacities",{}).get(node.id,0)
 elif op == "ancestry": current = context.get("ancestry_tags",[]).has(node.id)
 else: current = context.get(op+"s",[]).has(node.id)
 if (current == true if expected is bool else int(current) >= int(expected)): return []
 return [RulesJson.issue("requirement."+op,path,"Prerequisite is not met",{"id":node.get("id",""),"expected":expected,"current":current})]
