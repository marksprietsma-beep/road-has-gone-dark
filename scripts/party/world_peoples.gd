class_name WorldPeoples
extends RefCounted
const RUNTIME := "res://data/world_enrichment/runtime-party-v1.json"
const PACK := "res://data/world_enrichment/trhgd-party-v1.json"
const KEYS := ["schema_version", "provider", "generator_version", "content_pack_version", "content_pack_sha", "base_world_id", "base_world_sha", "profiles_sha", "runtime_manifest_sha", "enrichment_sha"]
var descriptor := {}
var records := {}
var error := ""

static func directory(world: GameWorldTemplate) -> String:
 for key in GameWorldLibrary.PRESETS:
  var path := "res://data/world_enrichment/presets-peoples-v1/" + str(key)
  if WorldOriginLore.read_json(path.path_join("descriptor.json")).get("base_world_id") == world.world_id: return path
 return OriginProfiles.directory(world).get_base_dir().path_join("peoples-v1")

func fail(why: String) -> bool:
 descriptor.clear()
 records.clear()
 error = "People enrichment: " + why
 return false

func load_world(world: GameWorldTemplate, path: String = "") -> bool:
 descriptor.clear()
 records.clear()
 error = ""
 if path.is_empty(): path = directory(world)
 var d := WorldOriginLore.read_json(path.path_join("descriptor.json"))
 if d.size() != KEYS.size(): return fail("missing or corrupt descriptor")
 for key in KEYS:
  if not d.has(key): return fail("missing field")
 var runtime := WorldOriginLore.read_json(RUNTIME)
 if d.schema_version != 1 or d.provider != "trhgd-peoples" or d.generator_version != runtime.get("generator_version") or d.content_pack_version != "trhgd-party-1" or d.content_pack_sha != runtime.get("content_pack_sha") or d.runtime_manifest_sha != FileAccess.get_sha256(RUNTIME) or d.base_world_id != world.world_id or d.base_world_sha != world.source_sha256: return fail("world/version mismatch")
 var helper := GameWorldLibrary.new().helper_location()
 for file in runtime.get("files", {}):
  var location: String = "res://" + str(file)
  if not FileAccess.file_exists(location): location = helper.path_join(str(file))
  if FileAccess.get_sha256(location) != runtime.files[file]: return fail("runtime integrity failure")
 var profiles := OriginProfiles.new()
 if not profiles.load_world(world) or d.profiles_sha != profiles.descriptor.enrichment_sha: return fail("historical profile dependency mismatch")
 var file := path.path_join("enrichment.json")
 if not FileAccess.file_exists(file) or FileAccess.get_sha256(file) != d.enrichment_sha: return fail("package integrity failure")
 var data := WorldOriginLore.read_json(file)
 if data.get("schema_version") != 1 or data.get("base_world", {}).get("id") != world.world_id or not data.get("records") is Dictionary: return fail("invalid presence data")
 var people_ids: Array = WorldOriginLore.read_json(PACK).peoples.map(func(p: Dictionary): return p.id)
 for group in ["world", "states", "regions", "hometowns"]:
  if not data.records.get(group) is Dictionary: return fail("missing hierarchy")
  if group != "world" and data.records[group].size() != profiles.projection[group].size(): return fail("incomplete coverage")
  for key in data.records[group]:
   if group == "world" and key != world.world_id or group != "world" and not profiles.projection[group].has(key): return fail("unknown source entity")
   var row: Variant = data.records[group][key]
   if not row is Dictionary or not row.get("source_culture_ids") is Array or not row.get("peoples") is Array or row.peoples.size() != people_ids.size(): return fail("invalid people row")
   var seen := {}
   for p in row.peoples:
    if not p is Dictionary or not people_ids.has(p.get("people_id")) or seen.has(p.people_id) or not p.get("status") in ["common", "present", "uncommon"] or not (p.get("presence_weight") is int or p.get("presence_weight") is float) or p.presence_weight < 1 or p.presence_weight > 100: return fail("invalid qualitative presence")
    seen[p.people_id] = true
   for culture in row.source_culture_ids:
    if not (culture is int or culture is float) or culture <= 0 or world.get_record("culture", int(culture)).is_empty(): return fail("invalid culture reference")
 descriptor = d
 records = data.records
 return true

func local(burg: int) -> Dictionary:
 return records.get("hometowns", {}).get(str(burg), {}).duplicate(true)
