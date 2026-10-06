class_name PartyRecords
extends RefCounted
const MEMBER_KEYS := ["character_id", "slot", "name", "name_edited", "people_id", "role_id", "background_variant", "background_id", "origin_refs", "generated_facts", "biography"]

static func satisfies(rule: Variant, tags: Dictionary) -> bool:
 if rule == null: return true
 if rule is String: return tags.has(rule)
 if rule is Array: return rule.all(func(r: Variant): return satisfies(r, tags))
 if rule is Dictionary and rule.size() == 1:
  if rule.has("all") and rule.all is Array: return rule.all.all(func(r: Variant): return satisfies(r, tags))
  if rule.has("any") and rule.any is Array: return rule.any.any(func(r: Variant): return satisfies(r, tags))
  if rule.has("not"): return not satisfies(rule.not, tags)
 return false

static func validate(state: Dictionary, world: GameWorldTemplate) -> String:
 if not state.has("party"): return "" # Historical skeletons are still valid.
 var party: Variant = state.party
 if not party is Dictionary or party.size() != 7 or party.get("schema_version") != 1 or not party.get("status") in ["draft", "ready"] or party.get("generator_version") != "trhgd-party-1" or party.get("runtime_manifest_sha") != FileAccess.get_sha256(WorldPeoples.RUNTIME): return "Invalid party schema or runtime"
 var runtime := WorldOriginLore.read_json(WorldPeoples.RUNTIME)
 if party.get("content_pack_sha") != runtime.get("content_pack_sha"): return "Party content version mismatch"
 if state.get("onboarding_stage") != ("party_ready" if party.status == "ready" else "party_creation"): return "Party onboarding stage mismatch"
 var people := WorldPeoples.new()
 if not people.load_world(world): return people.error
 if party.get("peoples_pin") != people.descriptor: return "Pinned people enrichment mismatch"
 if not party.get("members") is Array or party.members.size() != 3 or state.characters.size() != 3 or state.party_ids.size() != 3: return "Exactly three party members required"
 var pack := WorldOriginLore.read_json(WorldPeoples.PACK)
 var people_ids: Array = pack.peoples.map(func(r: Dictionary): return r.id)
 var role_ids: Array = pack.roles.map(func(r: Dictionary): return r.id)
 var home: Dictionary = world.get_record("burg", int(state.origin.home_burg_id))
 var cell: Dictionary = world.get_record("cell", int(home.cell))
 var foundation := WorldOriginLore.read_json("res://data/world_enrichment/trhgd-expanded-v1.json")
 var profiles: Dictionary = WorldOriginLore.read_json(OriginProfiles.directory(world).path_join("enrichment.json")).get("profiles", {})
 var local: Dictionary = profiles.get("hometowns", {}).get(str(int(home.i)), {})
 if local.is_empty(): return "Missing hometown profile context"
 var tags := {}
 for tag in local.source_context.tags: tags[tag] = true
 if int(cell.get("religion", 0)) > 0 and not world.get_record("religion", int(cell.religion)).is_empty(): tags["religion"] = true
 var region: Dictionary = profiles.get("regions", {}).get(str(local.parents.region), {})
 if region.get("source_context", {}).get("tags", []).has("mine"): tags["regional-mine"] = true
 for i in 3:
  var m: Variant = party.members[i]
  if not m is Dictionary or m.size() != MEMBER_KEYS.size(): return "Invalid character structure"
  for key in MEMBER_KEYS:
   if not m.has(key): return "Missing character field"
  var id := str(state.playthrough_id) + ":adventurer:" + str(i + 1)
  if m.character_id != id or m.character_id != state.characters[i].id or state.party_ids[i] != id or m.slot != i + 1: return "Invalid immutable character ID or slot"
  if not m.name is String or m.name.strip_edges().is_empty() or m.name.length() > 48 or not m.name_edited is bool or state.characters[i].name != m.name: return "Invalid character name"
  if not people_ids.has(m.people_id) or not role_ids.has(m.role_id): return "Unsupported people or provisional role"
  if not (m.background_variant is int or m.background_variant is float) or m.background_variant != int(m.background_variant) or m.background_variant < 0 or m.background_variant > 9007199254740991 or not m.background_id is String or not m.background_id.begins_with(id + ":background:") or m.background_id.length() != id.length() + 32: return "Invalid background identity"
  var expected_background := id + ":background:" + JSON.stringify(["trhgd-party-1", party.content_pack_sha, int(m.background_variant), m.people_id, m.role_id]).sha256_text().left(20)
  if m.background_id != expected_background: return "Background digest mismatch"
  var refs: Variant = m.origin_refs
  if not refs is Dictionary or refs.size() != 8 or refs.get("world_id") != world.world_id or refs.get("world_sha") != world.source_sha256 or refs.get("burg_id") != home.i or refs.get("cell_id") != home.cell or refs.get("state_id") != cell.get("state") or refs.get("province_id") != cell.get("province") or refs.get("culture_id") != cell.get("culture") or refs.get("religion_id") != cell.get("religion"): return "Character origin source mismatch"
  var facts: Variant = m.generated_facts
  if not facts is Dictionary or facts.size() != 9 or facts.get("schema_version") != 1 or facts.get("people_id") != m.people_id or facts.has("secret") or not facts.get("background") is Dictionary or not facts.get("origin_identity") is Dictionary or not facts.get("provenance") is Dictionary: return "Invalid structured background"
  var background: Dictionary = facts.background
  var fields := ["name","naming","birthplace","age_band","occupation","training","family","childhood","value","habit","concern","contact","traits","keepsake","local_knowledge","first_failure","first_success","motivation","hometown_relationship"]
  if background.size() != fields.size(): return "Unsupported background fields"
  for field in fields:
   if not background.has(field): return "Missing background field"
  for field in ["birthplace", "local_knowledge", "naming", "contact"]:
   if not background[field] is Dictionary: return "Invalid background field type"
  if background.get("birthplace", {}).get("id") != home.i or background.get("local_knowledge", {}).get("hidden_pois") != [] or facts.provenance.get("visibility") != "character-owned public; no private generator facts": return "Invalid local knowledge or visibility"
  for field in ["family", "childhood", "training", "motivation", "keepsake", "value", "habit", "concern"]:
   if not foundation[field].any(func(row: Dictionary): return row.id == background.get(field)): return "Unknown background reference"
  var original: Array = foundation.occupations.filter(func(row: Dictionary): return row.id == facts.foundation_occupation_id)
  if original.size() != 1 or not satisfies(original[0].get("requires"), tags) or background.occupation != facts.foundation_occupation_id: return "Incompatible foundation occupation"
  var jobs: Array = pack.occupations.filter(func(row: Dictionary): return row.id == facts.get("occupation_id"))
  if jobs.is_empty(): jobs = foundation.occupations.filter(func(row: Dictionary): return row.id == facts.get("occupation_id"))
  if jobs.size() != 1 or not satisfies(jobs[0].get("requires"), tags) or jobs[0].get("foundation", jobs[0].id) != facts.foundation_occupation_id: return "Invalid occupation context"
  var training_tags := tags.duplicate()
  for tag in original[0].get("provides", []): training_tags[tag] = true
  var training: Array = foundation.training.filter(func(row: Dictionary): return row.id == background.training)
  if training.size() != 1 or not satisfies(training[0].get("requires"), training_tags): return "Incompatible training"
  if not background.traits is Array or background.traits.size() != 2 or background.traits[0] == background.traits[1]: return "Invalid character traits"
  for personality in background.traits:
   var rows: Array = foundation.traits.filter(func(row: Dictionary): return row.id == personality)
   if rows.size() != 1 or rows[0].get("conflicts", []).any(func(id: String): return background.traits.has(id)): return "Contradictory character traits"
  if not m.biography is String or m.biography.is_empty() or m.biography.length() > 2048 or m.biography.contains("<iframe") or m.biography.contains("http") or m.biography.contains("<"): return "Invalid biography"
 return ""
