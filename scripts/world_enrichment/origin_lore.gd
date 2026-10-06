class_name WorldOriginLore
extends RefCounted
## Only this validated, allowlisted projection crosses into player presentation.
const RUNTIME := "res://data/world_enrichment/runtime.json"
const DESCRIPTOR_KEYS := ["schema_version", "provider", "generator_version", "content_pack_version", "content_pack_sha", "renderer_version", "base_world_id", "base_world_sha", "enrichment_sha", "public_projection_sha", "runtime_manifest_sha", "origin_count"]
const ORIGIN_KEYS := ["record_id", "burg_id", "cell_id", "state_id", "province_id", "memory", "tradition", "text"]
var descriptor: Dictionary = {}
var origins: Dictionary = {}
var error := ""

static func directory(world: GameWorldTemplate) -> String:
 for key in GameWorldLibrary.PRESETS:
  var path: String = "res://data/world_enrichment/presets/" + str(key)
  var d := read_json(path.path_join("descriptor.json"))
  if d.get("base_world_id") == world.world_id: return path
 return "user://worlds/" + world.source_sha256 + "/enrichment/origin-v1"

static func read_json(path: String) -> Dictionary:
 var file := FileAccess.open(path, FileAccess.READ)
 if file == null or file.get_length() > 67108864: return {}
 var value: Variant = JSON.parse_string(file.get_as_text())
 return value if value is Dictionary else {}

func _fail(why: String) -> bool:
 descriptor.clear()
 origins.clear()
 error = why
 return false

func load_world(world: GameWorldTemplate, path: String = "") -> bool:
 descriptor = {}
 origins = {}
 error = ""
 if path.is_empty(): path = directory(world)
 var d := read_json(path.path_join("descriptor.json"))
 if d.size() != DESCRIPTOR_KEYS.size(): return _fail("Origin enrichment descriptor is missing or corrupt.")
 for key in DESCRIPTOR_KEYS:
  if not d.has(key): return _fail("Origin enrichment descriptor field is missing: " + key)
 var runtime := read_json(RUNTIME)
 if d.schema_version != 1 or d.provider != "sha-staged" or d.base_world_id != world.world_id or d.base_world_sha != world.source_sha256: return _fail("Origin enrichment belongs to a different world or schema.")
 for key in ["generator_version", "content_pack_version", "content_pack_sha", "renderer_version"]:
  if d[key] != runtime.get(key): return _fail("Unsupported pinned origin enrichment version: " + key)
 if not runtime.get("files") is Dictionary: return _fail("Origin content runtime manifest is invalid.")
 var helper := GameWorldLibrary.new().helper_location()
 for file in runtime.files:
  var location: String = "res://" + str(file)
  if not FileAccess.file_exists(location): location = helper.path_join(str(file))
  if not FileAccess.file_exists(location) or FileAccess.get_sha256(location) != runtime.files[file]: return _fail("Origin enrichment runtime integrity failure: " + str(file))
 if d.runtime_manifest_sha != FileAccess.get_sha256(RUNTIME): return _fail("Origin enrichment runtime pin mismatch.")
 for pair in [["enrichment.json", "enrichment_sha"], ["public.json", "public_projection_sha"]]:
  if not FileAccess.file_exists(path.path_join(pair[0])) or FileAccess.get_sha256(path.path_join(pair[0])) != d[pair[1]]: return _fail("Origin enrichment integrity failure: " + pair[0])
 var p := read_json(path.path_join("public.json"))
 if p.size() != 4 or p.get("schema_version") != 1 or p.get("world_id") != world.world_id or p.get("world_sha") != world.source_sha256 or not p.get("origins") is Dictionary: return _fail("Invalid public origin projection.")
 var expected: Dictionary = {}
 for state in world.raw_counts().states:
  for home in world.home_candidates(state, -1, -1): expected[str(home.id)] = home
 if p.origins.size() != expected.size() or d.origin_count != expected.size(): return _fail("Origin enrichment does not cover every eligible hometown.")
 for key in p.origins:
  if not expected.has(key) or not p.origins[key] is Dictionary: return _fail("Origin enrichment contains an ineligible hometown.")
  var row: Dictionary = p.origins[key]
  if row.size() != ORIGIN_KEYS.size(): return _fail("Public origin contains unsupported fields.")
  for field in ORIGIN_KEYS:
   if not row.has(field): return _fail("Public origin field missing: " + field)
  var home: Dictionary = expected[key]
  for field in ["burg_id", "cell_id", "state_id", "province_id"]:
   var actual: int = int(home.id) if field == "burg_id" else int(home[field])
   if not (row[field] is float or row[field] is int) or row[field] != actual: return _fail("Public origin source identity mismatch.")
  if row.record_id != "settlements:%s/origin:0" % key: return _fail("Public origin record identity mismatch.")
  for field in ["memory", "tradition", "text"]:
   if not row[field] is String or row[field].is_empty() or row[field].length() > 2048: return _fail("Invalid public origin text.")
 descriptor = d
 origins = p.origins
 return true

func public_origin(world: GameWorldTemplate, burg_id: int) -> Dictionary:
 if descriptor.get("base_world_id") != world.world_id: return {}
 return origins.get(str(burg_id), {}).duplicate(true)

func validate_pin(pin: Variant, world: GameWorldTemplate, burg_id: int, path: String = "") -> String:
 if not pin is Dictionary: return "Invalid origin enrichment reference."
 if not load_world(world, path): return error
 if pin.size() != descriptor.size(): return "Origin enrichment reference is incomplete."
 for key in DESCRIPTOR_KEYS:
  if pin.get(key) != descriptor.get(key): return "Pinned origin enrichment mismatch: " + key
 if burg_id >= 0 and public_origin(world, burg_id).is_empty(): return "Pinned origin lore has no matching hometown."
 return ""
