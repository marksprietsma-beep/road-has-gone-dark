class_name RulesJson
extends RefCounted
## Integer-only mechanical values have the same canonical bytes after JSON reload.
const LIMIT := 1000000000

static func integer(value: Variant, minimum: int = -LIMIT, maximum: int = LIMIT) -> bool:
 if not (value is int or value is float): return false
 return is_finite(float(value)) and value == int(value) and value >= minimum and value <= maximum

static func normalize(value: Variant) -> Variant:
 if value is Dictionary:
  var result := {}
  for key in value: result[key] = normalize(value[key])
  return result
 if value is Array:
  var result: Array = []
  for item in value: result.append(normalize(item))
  return result
 if value is float and integer(value): return int(value)
 return value

static func canonical(value: Variant) -> String:
 if value is Dictionary:
  var keys: Array = value.keys()
  keys.sort()
  var pieces: Array[String] = []
  for key in keys: pieces.append(JSON.stringify(key) + ":" + canonical(value[key]))
  return "{" + ",".join(pieces) + "}"
 if value is Array:
  var pieces: Array[String] = []
  for item in value: pieces.append(canonical(item))
  return "[" + ",".join(pieces) + "]"
 if value is int or value is float:
  if integer(value): return str(int(value))
 return JSON.stringify(value)

static func digest(value: Variant) -> String:
 return canonical(value).sha256_text()

static func freeze(value: Variant) -> Variant:
 if value is Dictionary:
  for key in value: freeze(value[key])
  value.make_read_only()
 elif value is Array:
  for item in value: freeze(item)
  value.make_read_only()
 return value

static func issue(code: String, path: String, detail: String, extra: Dictionary = {}) -> Dictionary:
 var result := {"code":code,"path":path,"detail":detail}
 result.merge(extra)
 return result

static func result(errors: Array) -> Dictionary:
 return {"ok":errors.is_empty(),"errors":errors}
