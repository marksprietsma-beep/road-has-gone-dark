class_name OriginProfiles
extends RefCounted
## Additive profile package. V1 lore and its historical readers remain untouched.
const RUNTIME := "res://data/world_enrichment/runtime-profiles-v2.json"
const KEYS := ["schema_version", "provider", "generator_version", "content_pack_version", "content_pack_sha", "renderer_version", "base_world_id", "base_world_sha", "enrichment_sha", "public_projection_sha", "runtime_manifest_sha", "state_count", "region_count", "origin_count", "origin_v1_sha"]
const ROW_KEYS := ["record_id", "world_id", "state_id", "province_id", "burg_id", "cell_id", "name", "parents", "tags", "identity_tags", "compact_summary", "full_summary"]
var descriptor := {}
var projection := {}
var error := ""

static func directory(world: GameWorldTemplate) -> String:
 if not world.profiles_directory.is_empty(): return world.profiles_directory
 for key in GameWorldLibrary.PRESETS:
  var path := "res://data/world_enrichment/presets-profiles-v2/" + str(key)
  if WorldOriginLore.read_json(path.path_join("descriptor.json")).get("base_world_id") == world.world_id: return path
 if not world.enrichment_directory.is_empty(): return world.enrichment_directory.get_base_dir().path_join("profiles-v2")
 return "user://worlds/" + world.source_sha256 + "/enrichment/profiles-v2"

func _fail(why: String) -> bool:
 descriptor.clear()
 projection.clear()
 error = "Origin profile enrichment: " + why
 return false

func load_world(world: GameWorldTemplate, path: String = "") -> bool:
 descriptor = {}
 projection = {}
 error = ""
 if path.is_empty(): path = directory(world)
 var cache_key := "scripts/world_enrichment/origin_profiles.gd:" + path
 var fingerprint := ImmutableValidationCache.fingerprint(world, path, RUNTIME)
 var cached: Dictionary = world._validation_cache.get(cache_key,{})
 if cached.get("fingerprint")==fingerprint:
  descriptor = cached.descriptor.duplicate(true)
  projection = cached.projection.duplicate(true)
  return true
 var d := WorldOriginLore.read_json(path.path_join("descriptor.json"))
 if d.size() != KEYS.size(): return _fail("descriptor is missing or corrupt.")
 for key in KEYS:
  if not d.has(key): return _fail("descriptor field missing: " + key)
 if d.schema_version != 2 or d.provider != "trhgd-hierarchical-lexicon" or d.base_world_id != world.world_id or d.base_world_sha != world.source_sha256: return _fail("world or schema mismatch.")
 var runtime := WorldOriginLore.read_json(RUNTIME)
 for key in ["generator_version", "content_pack_version", "content_pack_sha", "renderer_version"]:
  if d[key] != runtime.get(key): return _fail("unsupported pinned version: " + key)
 if not runtime.get("files") is Dictionary or d.runtime_manifest_sha != FileAccess.get_sha256(RUNTIME): return _fail("runtime pin mismatch.")
 var helper := GameWorldLibrary.new().helper_location()
 for file in runtime.files:
  var location: String = "res://" + str(file)
  if not FileAccess.file_exists(location): location = helper.path_join(str(file))
  if not FileAccess.file_exists(location) or FileAccess.get_sha256(location) != runtime.files[file]: return _fail("runtime integrity failure: " + str(file))
 for pair in [["enrichment.json", "enrichment_sha"], ["public.json", "public_projection_sha"]]:
  if not FileAccess.file_exists(path.path_join(pair[0])) or FileAccess.get_sha256(path.path_join(pair[0])) != d[pair[1]]: return _fail("file integrity failure: " + pair[0])
 var old := WorldOriginLore.new()
 if not old.load_world(world, world.enrichment_directory): return _fail(old.error)
 if d.origin_v1_sha != old.descriptor.enrichment_sha: return _fail("historical V1 dependency mismatch.")
 var p := WorldOriginLore.read_json(path.path_join("public.json"))
 if p.size() != 6 or p.get("schema_version") != 2 or p.get("world_id") != world.world_id or p.get("world_sha") != world.source_sha256: return _fail("invalid public projection.")
 var columns := world.political_columns()
 var expected_states := {}
 var expected_regions := {}
 for index in columns.ids.size():
  if float(columns.heights[index]) < 20: continue
  var state_id := int(columns.state[index])
  var state := world.get_record("state", state_id)
  if state_id <= 0 or state.is_empty() or state.get("removed", false) or state.get("hidden", false): continue
  expected_states[str(state_id)] = true
  var province_id := int(columns.province[index])
  var province := world.get_record("province", province_id)
  if province_id == 0 or not province.is_empty() and not province.get("removed", false) and not province.get("hidden", false) and int(province.get("state", -1)) == state_id:
   expected_regions["%d:%d" % [state_id, province_id]] = true
 if not p.get("states") is Dictionary or not p.get("regions") is Dictionary or p.states.size() != expected_states.size() or p.regions.size() != expected_regions.size(): return _fail("incomplete political coverage.")
 for key in p.states:
  if not expected_states.has(key): return _fail("unknown state.")
 for key in p.regions:
  if not expected_regions.has(key): return _fail("unknown region.")
 for group in ["states", "regions", "hometowns"]:
  if not p.get(group) is Dictionary: return _fail("missing public group.")
  var count_key: String = "origin_count" if group == "hometowns" else ("state_count" if group == "states" else "region_count")
  if p[group].size() != d[count_key]: return _fail("coverage count mismatch.")
  for key in p[group]:
   if not p[group][key] is Dictionary: return _fail("invalid public row.")
   var row: Dictionary = p[group][key]
   var expected := ROW_KEYS.duplicate()
   if group == "hometowns": expected.append_array(["memory", "tradition"])
   if row.size() != expected.size(): return _fail("unsupported public fields.")
   for field in expected:
    if not row.has(field): return _fail("missing public field.")
   if not (row.state_id is int or row.state_id is float) or row.state_id != int(row.state_id): return _fail("invalid state ID type.")
   for field in ["province_id", "burg_id", "cell_id"]:
    if row[field] != null and (not (row[field] is int or row[field] is float) or row[field] != int(row[field])): return _fail("invalid source ID type.")
   if group != "regions" and (not str(key).is_valid_int() or str(int(key)) != str(key)): return _fail("invalid record key.")
   if row.world_id != world.world_id or not p.states.has(str(int(row.state_id))): return _fail("cross-world or parent mismatch.")
   if not row.parents is Dictionary or not row.tags is Array or not row.identity_tags is Array: return _fail("invalid profile relationships.")
   for field in ["compact_summary", "full_summary"]:
    if not row[field] is String or row[field].is_empty() or row[field].length() > 2048: return _fail("invalid public text.")
   if group == "states":
    var state := world.get_record("state", int(key))
    if int(row.state_id) != int(key) or row.province_id != null or row.burg_id != null or row.cell_id != null or state.is_empty() or row.record_id != "state:" + str(key) or row.name != state.name or row.parents != {"world": world.world_id}: return _fail("state source mismatch.")
   elif group == "regions":
    if row.record_id != "province:" + str(key) or row.burg_id != null or row.cell_id != null or str(key) != "%d:%d" % [int(row.state_id), int(row.province_id)] or row.parents != {"state": "state:%d" % int(row.state_id)}: return _fail("region parent mismatch.")
    if int(row.province_id) > 0:
     var province := world.get_record("province", int(row.province_id))
     if province.is_empty() or int(province.state) != int(row.state_id) or row.name != province.name: return _fail("province source mismatch.")
   else:
    var legacy := old.public_origin(world, int(key))
    if legacy.is_empty() or row.record_id != "burg:" + str(key): return _fail("ineligible hometown.")
    for field in ["burg_id", "cell_id", "state_id", "province_id", "memory", "tradition"]:
     if row[field] != legacy[field]: return _fail("hometown/V1 source mismatch.")
    var region_key := "%d:%d" % [int(row.state_id), int(row.province_id)]
    if not p.regions.has(region_key) or row.parents != {"state": "state:%d" % int(row.state_id), "region": region_key} or row.name != world.get_record("burg", int(key)).name: return _fail("hometown profile parent mismatch.")
 if p.hometowns.size() != old.origins.size(): return _fail("incomplete hometown coverage.")
 descriptor = d
 projection = p
 world._validation_cache[cache_key] = {"fingerprint":fingerprint,"descriptor":descriptor.duplicate(true),"projection":projection.duplicate(true)}
 return true

func public_profile(group: String, key: String) -> Dictionary:
 return projection.get(group, {}).get(key, {}).duplicate(true)

func validate_pin(pin: Variant, world: GameWorldTemplate, path: String = "") -> String:
 if not pin is Dictionary: return "Invalid origin profile enrichment pin."
 if not load_world(world, path): return error
 if pin != descriptor: return "Pinned origin profile enrichment mismatch."
 return ""
