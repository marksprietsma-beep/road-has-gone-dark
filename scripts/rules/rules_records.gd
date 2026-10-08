class_name RulesRecords
extends RefCounted
static var _registry: RulesRegistry

static func registry() -> RulesRegistry:
 if _registry==null:
  _registry=RulesRegistry.new()
  _registry.load_pack()
 return _registry

static func preparation_status(state: Dictionary) -> String:
 return "prepared" if state.has("mechanics") else "not_prepared"

static func validate(state: Dictionary) -> String:
 if not state.has("mechanics"): return "" # Historical campaigns are not corrupt.
 var source := registry()
 if not source.ready(): return "rules.pack_unavailable: "+RulesJson.canonical(source.errors)
 var mechanics: Variant=state.mechanics
 if not mechanics is Dictionary or mechanics.size()!=5 or mechanics.get("schema_version")!=1 or RulesJson.normalize(mechanics.get("rules_ref"))!=source.rules_ref() or not RulesJson.integer(mechanics.get("revision"),1,RulesJson.LIMIT) or not mechanics.get("records") is Dictionary or not mechanics.get("source_party_sha") is String or mechanics.source_party_sha.length()!=64 or not mechanics.source_party_sha.is_valid_hex_number(false): return "rules.schema_or_pin: Invalid mechanical schema or exact rules pin"
 if state.get("party",{}).get("status")!="ready": return "rules.party: Mechanics require the existing ready party"
 if not state.get("characters") is Array or mechanics.records.size()!=state.characters.size(): return "rules.roster: Mechanical records must match existing character IDs"
 var characters := RulesCharacter.new(source)
 for character in state.characters:
  if not character is Dictionary or not character.get("id") is String or not mechanics.records.get(character.id) is Dictionary: return "rules.identity: Missing mechanical record for an existing ID"
  var record: Dictionary=mechanics.records[character.id]
  if record.get("character_id")!=character.id or record.get("advancement_history",[]).is_empty(): return "rules.identity: Mechanical identity/initial level mismatch"
  var result := characters.validate_build(record)
  if not result.ok: return "rules.build: "+RulesJson.canonical(result.errors)
 return ""

static func preview_preparation(state: Dictionary) -> Dictionary:
 if state.has("mechanics"):
  var why := validate(state)
  if not why.is_empty(): return {"ok":false,"error":why}
  return {"ok":true,"operation":"prepare","before_hash":RulesJson.digest(state),"candidate_hash":RulesJson.digest(state),"candidate":state.duplicate(true),"already_prepared":true}
 var source := registry()
 if not source.ready(): return {"ok":false,"error":"Rules content unavailable","errors":source.errors}
 if state.get("party",{}).get("status")!="ready" or not state.get("party",{}).get("members") is Array or not state.get("characters") is Array or not state.get("party_ids") is Array: return {"ok":false,"error":"Prepare the existing narrative party first; no character is regenerated"}
 if state.party.members.size()!=state.characters.size() or state.characters.size()!=state.party_ids.size(): return {"ok":false,"error":"Existing party identities are inconsistent"}
 var records := {};var characters := RulesCharacter.new(source)
 for i in state.characters.size():
  var member: Variant=state.party.members[i]
  if not member is Dictionary or member.get("character_id")!=state.characters[i].get("id") or member.character_id!=state.party_ids[i]: return {"ok":false,"error":"Existing party identity/slot mismatch"}
  var recommendation := source.recommendation(str(member.get("role_id")))
  if recommendation.is_empty(): return {"ok":false,"error":"No reviewed starting recommendation for narrative role"}
  var ancestry := "heritage-"+str(member.get("people_id"))
  var record := characters.create(member.character_id,recommendation.attributes,ancestry)
  record.equipment=recommendation.equipment.duplicate()
  var suggested := characters.suggested_choice(record,recommendation["class"],recommendation.feat)
  if not suggested.ok: return suggested
  var applied := characters.apply_advancement(record,suggested.choice,0)
  if not applied.ok: return applied
  record=applied.candidate
  # Explicit starting choices; ordinary/class abilities remain granted data.
  record.choices.prepared_abilities=applied.snapshot.abilities.filter(func(id: String): return source.definition("abilities",id).tags.has("perception") or source.definition("abilities",id).tags.has("control"))
  records[member.character_id]=record
 var candidate := state.duplicate(true)
 candidate.mechanics={"schema_version":1,"rules_ref":source.rules_ref(),"revision":1,"source_party_sha":RulesJson.digest(state.party),"records":records}
 var why := validate(candidate)
 if not why.is_empty(): return {"ok":false,"error":why}
 return {"ok":true,"operation":"prepare","before_hash":RulesJson.digest(state),"candidate_hash":RulesJson.digest(candidate),"candidate":candidate,"already_prepared":false}

static func preview_advancement(state: Dictionary,identity: String,choice: Dictionary) -> Dictionary:
 var why := validate(state)
 if not state.has("mechanics") or not why.is_empty(): return {"ok":false,"error":"Prepared exact-pinned mechanical records required. "+why}
 if not state.mechanics.records.has(identity): return {"ok":false,"error":"Unknown existing character identity"}
 var record: Dictionary=state.mechanics.records[identity]
 var changed := RulesCharacter.new(registry()).apply_advancement(record,choice,int(record.revision))
 if not changed.ok: return changed
 var candidate := state.duplicate(true)
 candidate.mechanics.records[identity]=changed.candidate
 candidate.mechanics.revision=int(candidate.mechanics.revision)+1
 return {"ok":true,"operation":"advance","character_id":identity,"choice":choice.duplicate(true),"before_hash":RulesJson.digest(state),"candidate_hash":RulesJson.digest(candidate),"candidate":candidate,"snapshot":changed.snapshot}
