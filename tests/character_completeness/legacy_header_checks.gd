extends RefCounted
## Test-only strictness checks for the JSON fixture ingestion boundary.
static func verify(source: RulesRegistry,saved: Dictionary) -> Dictionary:
 var validator: GDScript=load("res://tests/character_completeness/native_launch.gd")
 var checks := 0;var failures := 0;var errors: Array=[]
 var cases := {"exact JSON numeric pin":saved,"missing pin":saved.duplicate(true),"wrong pack":saved.duplicate(true),"changed hash":saved.duplicate(true),"fractional schema":saved.duplicate(true),"missing witness":saved.duplicate(true),"missing hash":saved.duplicate(true),"wrong record pin":saved.duplicate(true),"extra pin field":saved.duplicate(true)}
 cases["missing pin"].erase("rules_ref")
 cases["wrong pack"].rules_ref.pack_id="trhgd-character-v16"
 cases["changed hash"].rules_ref.content_hash="0".repeat(64)
 cases["fractional schema"].rules_ref.engine_schema=3.5
 var id: String=saved.records.keys()[0]
 cases["missing witness"].records.erase(id)
 cases["missing hash"].hashes.erase(id)
 cases["wrong record pin"].records[id].rules_ref.rules_version="16.0.0"
 cases["extra pin field"].rules_ref.unexpected=true
 for label in cases:
  var found: Array=validator.legacy_header_errors(cases[label],source)
  checks+=1
  if found.is_empty()!=(label=="exact JSON numeric pin"):
   failures+=1;errors.append({"reason":"fixture boundary regression","case":label,"errors":found})
 return {"checks":checks,"failures":failures,"errors":errors}
