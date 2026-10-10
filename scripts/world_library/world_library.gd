class_name GameWorldLibrary
extends RefCounted
## Immutable templates, never campaigns. Directory rename is the commit boundary.
const PRESETS := ["game-11-determinism", "atlas-showcase"]
const UPSTREAM := "cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6"
var library_root := "user://worlds"
var save_root := "user://game_world_saves"
var helper_root := ""
var error := ""

func _fail(reason: String) -> Dictionary:
 error = reason
 return {"ok": false, "error": reason}

func _json(path: String) -> Dictionary:
 var file := FileAccess.open(path, FileAccess.READ)
 if file == null or file.get_length() > 67108864: return {}
 var parser := JSON.new()
 if parser.parse(file.get_as_text()) != OK: return {}
 return parser.data if parser.data is Dictionary else {}

func _write_json(path: String, value: Dictionary) -> bool:
 var file := FileAccess.open(path, FileAccess.WRITE)
 if file == null: return false
 file.store_string(JSON.stringify(value, "  ") + "\n")
 file.flush()
 file.close()
 return true

func _root() -> String:
 return ProjectSettings.globalize_path(library_root).simplify_path()

func _hash_name(name: String) -> bool:
 return name.length() == 64 and name.is_valid_hex_number(false)

func _numeric(value: Variant) -> bool:
 return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT

func _load_world(path: String) -> Dictionary:
 var raw := _json(path)
 if raw.is_empty() or not raw.get("generator") is Dictionary or not raw.get("map") is Dictionary or not raw.get("cells") is Dictionary or not raw.get("seed") is String: return {}
 var cells: Dictionary = raw.cells
 if not cells.get("ids") is Array: return {}
 var count: int = cells.ids.size()
 if count < 1 or count > 100000: return {}
 for dimension in ["width", "height"]:
  if not _numeric(raw.map.get(dimension)) or float(raw.map[dimension]) < 1 or float(raw.map[dimension]) > 8192: return {}
 for field in ["points", "heights", "biome", "state", "province", "neighbors"]:
  if not cells.get(field) is Array or cells[field].size() != count: return {}
 for i in count:
  if not _numeric(cells.ids[i]) or int(cells.ids[i]) != i: return {}
  if not cells.points[i] is Array or cells.points[i].size() != 2 or not cells.neighbors[i] is Array: return {}
  for coordinate in cells.points[i]:
   if not _numeric(coordinate): return {}
  for field in ["heights", "biome", "state", "province"]:
   if not _numeric(cells[field][i]): return {}
  for neighbor in cells.neighbors[i]:
   if not _numeric(neighbor) or int(neighbor) < 0 or int(neighbor) >= count: return {}
 for group in ["states", "provinces", "settlements", "cultures", "religions", "biomes", "rivers", "routes", "markers"]:
  if not raw.get(group) is Array: return {}
  for record in raw[group]:
   if record is Dictionary and record.has("i") and not _numeric(record.i): return {}
 var world := GameWorldTemplate.new()
 if not world.load_fixture(path) or world.world_ref.generator.get("upstreamCommit") != UPSTREAM: return {}
 return {"world": world, "raw": raw}

func _read_entry(path: String, staged: bool = false) -> Dictionary:
 var meta := _json(path.path_join("metadata.json"))
 if meta.get("library_version") != 1 or meta.get("preset", true) != false: return {}
 var loaded := _load_world(path.path_join("world.json"))
 if loaded.is_empty(): return {}
 var world: GameWorldTemplate = loaded.world
 if not meta.get("world_ref") is Dictionary or not meta.world_ref.get("generator") is Dictionary or not _numeric(meta.world_ref.get("schema_version")) or not world.validate_save_reference(meta.world_ref): return {}
 if meta.has("origin_enrichment"):
  var lore := WorldOriginLore.new()
  var why := lore.validate_pin(meta.origin_enrichment, world, -1, path.path_join("enrichment/origin-v1"))
  if not why.is_empty():
   error = why
   if staged: return {}
 if meta.has("origin_profiles"):
  world.enrichment_directory = path.path_join("enrichment/origin-v1")
  world.profiles_directory = path.path_join("enrichment/profiles-v2")
  var profile_error := OriginProfiles.new().validate_pin(meta.origin_profiles, world, path.path_join("enrichment/profiles-v2"))
  if not profile_error.is_empty():
   error = profile_error
   if staged: return {}
 world.enrichment_directory = path.path_join("enrichment/origin-v1")
 if not staged and path.get_file() != world.source_sha256: return {}
 return {"id": world.world_id, "preset": false, "label": str(meta.get("label", "Generated World")).left(80),
  "created": str(meta.get("created", "")), "world": world, "raw": loaded.raw, "directory": path,
  "key": "", "path": path.path_join("world.json"), "cache_ok": preview_valid(path, world.source_sha256)}

func _remove_flat_directory(path: String, enrichment_child: bool = false) -> bool:
 var parent := DirAccess.open(path.get_base_dir())
 if parent == null or parent.is_link(path): return false
 var dir := DirAccess.open(path)
 if dir != null: dir.include_hidden = true
 if dir == null: return not DirAccess.dir_exists_absolute(path)
 # Follow only the owned enrichment tree, never arbitrary nested data or links.
 for name in dir.get_directories():
  var child := path.path_join(name)
  if dir.is_link(child): return false
  if not enrichment_child and name != "enrichment": return false
  if enrichment_child and not (name == "origin-v1" or name.begins_with("origin-v1.pending-") or name == "profiles-v2" or name.begins_with("profiles-v2.pending-")): return false
  if not _remove_flat_directory(child, true): return false
 for file in dir.get_files():
  if DirAccess.remove_absolute(path.path_join(file)) != OK: return false
 return DirAccess.remove_absolute(path) == OK

func _pid_alive(pid: int) -> bool:
 if pid == OS.get_process_id(): return true
 if pid <= 0: return true
 # Godot 4.6's is_process_running only tracks its own spawned children on Unix.
 # The bundled runtime probes arbitrary owners portably; uncertain status is live.
 var binary := helper_location().path_join("node.exe" if OS.get_name() == "Windows" else "node")
 if not FileAccess.file_exists(binary): return true
 var code := "try{process.kill(Number(process.argv[1]),0);process.exit(0)}catch(e){process.exit(e.code==='ESRCH'?1:2)}"
 var result := OS.execute(binary, ["-e", code, str(pid)], [], true, false)
 return result != 1

func _recover() -> void:
 var dir := DirAccess.open(_root())
 if dir != null: dir.include_hidden = true
 if dir == null or not _acquire_lock(): return
 for name in dir.get_directories():
  var path := _root().path_join(name)
  if dir.is_link(path): continue
  if name.begins_with(".trash-"):
   var entry := _read_entry(path, true)
   if entry.is_empty():
    # A partly removed directory still cannot be purged if dependencies are uncertain.
    var sha := name.substr(7, 64)
    if not _hash_name(sha): continue
    var stub := GameWorldTemplate.new()
    stub.source_sha256 = sha
    entry = {"id": "", "world": stub}
   var refs := reference_status(entry)
   if not refs.ok or refs.count > 0:
    if entry.has("directory"):
     var target := _root().path_join(entry.world.source_sha256)
     if not DirAccess.dir_exists_absolute(target): DirAccess.rename_absolute(path, target)
   else:
    _remove_flat_directory(path)
  elif name.begins_with(".pending-"):
   var owner := _json(path.path_join("owner.json"))
   if not _numeric(owner.get("pid")) or _pid_alive(int(owner.pid)): continue
   var entry := _read_entry(path, true)
   if entry.is_empty():
    _remove_flat_directory(path)
   else:
    var target := _root().path_join(entry.world.source_sha256)
    if not DirAccess.dir_exists_absolute(target):
     DirAccess.rename_absolute(path, target)
    elif not _read_entry(target).is_empty():
     _remove_flat_directory(path)

 _release_lock()

func discover(recover: bool = true) -> Array[Dictionary]:
 if recover: _recover()
 var entries: Array[Dictionary] = []
 for i in PRESETS.size():
  var path := "res://tests/worldgen/fixtures/%s.json" % PRESETS[i]
  var loaded := _load_world(path)
  if not loaded.is_empty():
   entries.append({"id": loaded.world.world_id, "world": loaded.world, "raw": loaded.raw, "preset": true,
    "label": "World %s" % ("I" if i == 0 else "II"), "key": PRESETS[i], "path": path, "directory": "", "created": "", "cache_ok": true})
 var dir := DirAccess.open(_root())
 if dir != null: dir.include_hidden = true
 if dir == null: return entries
 var names := dir.get_directories()
 names.sort()
 for name in names:
  if not _hash_name(name) or dir.is_link(_root().path_join(name)): continue
  var entry := _read_entry(_root().path_join(name))
  if not entry.is_empty() and not entries.any(func(known: Dictionary): return known.id == entry.id): entries.append(entry)
 return entries

func preview_valid(directory: String, sha: String) -> bool:
 var meta := _json(directory.path_join("preview.meta.json"))
 if meta.get("world_sha256") != sha or meta.get("version") != 1: return false
 for name in ["preview.png", "preview.cells"]:
  if not FileAccess.file_exists(directory.path_join(name)) or meta.get(name) != FileAccess.get_sha256(directory.path_join(name)): return false
 var image := Image.new()
 if image.load(directory.path_join("preview.png")) != OK: return false
 return FileAccess.get_file_as_bytes(directory.path_join("preview.cells")).size() == image.get_width() * image.get_height() * 4

func build_preview(directory: String, raw: Dictionary, sha: String) -> bool:
 var package := MapRenderBaker.new().bake(MapRenderModel.new(raw))
 var image: Image = package.texture.get_image()
 image.blend_rect(package.political_texture.get_image(), Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
 image.blend_rect(package.border_texture.get_image(), Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
 if image.save_png(directory.path_join("preview.png.tmp")) != OK: return false
 var file := FileAccess.open(directory.path_join("preview.cells.tmp"), FileAccess.WRITE)
 if file == null: return false
 file.store_buffer(package.cell_ids.to_byte_array())
 file.flush()
 file.close()
 var meta := {"version": 1, "world_sha256": sha,
  "preview.png": FileAccess.get_sha256(directory.path_join("preview.png.tmp")),
  "preview.cells": FileAccess.get_sha256(directory.path_join("preview.cells.tmp"))}
 if not _write_json(directory.path_join("preview.meta.json.tmp"), meta): return false
 for name in ["preview.png", "preview.cells", "preview.meta.json"]:
  var target := directory.path_join(name)
  if FileAccess.file_exists(target) and DirAccess.remove_absolute(target) != OK: return false
  if DirAccess.rename_absolute(target + ".tmp", target) != OK: return false
 return preview_valid(directory, sha)

func create_staging() -> Dictionary:
 if DirAccess.make_dir_recursive_absolute(_root()) != OK: return _fail("Cannot create the world library.")
 var path := _root().path_join(".pending-" + Crypto.new().generate_random_bytes(16).hex_encode())
 if DirAccess.make_dir_absolute(path) != OK: return _fail("Cannot prepare the new world.")
 if not _write_json(path.path_join("owner.json"), {"pid": OS.get_process_id()}):
  _remove_flat_directory(path)
  return _fail("Cannot record world generation ownership.")
 return {"ok": true, "directory": path}

func helper_location() -> String:
 if not helper_root.is_empty(): return helper_root
 var override := OS.get_environment("GAME76_HELPER_ROOT")
 if not override.is_empty(): return override
 var beside := OS.get_executable_path().get_base_dir().path_join("worldgen-helper")
 if FileAccess.file_exists(beside.path_join("runtime.json")): return beside
 return ProjectSettings.globalize_path("res://worldgen-helper")

func run_generator(stage: String, seed: String) -> Dictionary:
 if stage.get_base_dir() != _root() or not stage.get_file().begins_with(".pending-"): return _fail("Invalid generator output directory.")
 var helper := helper_location()
 var manifest := _json(helper.path_join("runtime.json"))
 var binary := helper.path_join("node.exe" if OS.get_name() == "Windows" else "node")
 if manifest.get("helperVersion") != 1 or manifest.get("nodeVersion") != "v24.19.0" or manifest.get("upstreamCommit") != UPSTREAM:
  return _fail("The bundled world generator is missing or unsupported.")
 if not FileAccess.file_exists(binary) or FileAccess.get_sha256(binary) != manifest.get("runtimeSha256"):
  return _fail("The bundled world generator failed its integrity check.")
 var ready := helper_status()
 if not ready.ok: return ready
 var log: Array = []
 var exit := OS.execute(binary, [helper.path_join("tools/worldgen/helper-entry.mjs"), "--seed", seed, "--output", stage.path_join("world.json")], log, true, false)
 var diagnostic := FileAccess.open(_root().path_join("generation-last.log"), FileAccess.WRITE)
 if diagnostic != null:
  diagnostic.store_string("\n".join(log).left(32768))
  diagnostic.close()
 if exit != 0: return _fail("World generation failed (code %d). No world was added." % exit)
 return {"ok": true}

func import_generated(stage: String) -> Dictionary:
 if stage.get_base_dir() != _root() or not stage.get_file().begins_with(".pending-"): return _fail("Invalid staging directory.")
 var loaded := _load_world(stage.path_join("world.json"))
 if loaded.is_empty():
  _remove_flat_directory(stage)
  return _fail("The generated world did not pass canonical validation.")
 var world: GameWorldTemplate = loaded.world
 for entry in discover(false):
  if entry.id == world.world_id:
   _remove_flat_directory(stage)
   var enriched := ensure_enrichment(entry)
   if not enriched.ok: return enriched
   var profiled := ensure_profiles(entry)
   if not profiled.ok: return profiled
   return {"ok": true, "entry": entry, "deduplicated": true}
 if not build_preview(stage, loaded.raw, world.source_sha256):
  _remove_flat_directory(stage)
  return _fail("The new map preview could not be prepared.")
 var enriched := ensure_enrichment({"id": world.world_id, "world": world, "directory": stage, "path": stage.path_join("world.json"), "preset": false})
 if not enriched.ok:
  _remove_flat_directory(stage)
  return enriched
 var profiled := ensure_profiles({"id": world.world_id, "world": world, "directory": stage, "path": stage.path_join("world.json"), "preset": false})
 if not profiled.ok:
  _remove_flat_directory(stage)
  return profiled
 if not _acquire_lock():
  _remove_flat_directory(stage)
  return _fail("The world library is busy. No world was added; please retry.")
 var target := _root().path_join(world.source_sha256)
 if DirAccess.dir_exists_absolute(target):
  var existing := _read_entry(target)
  _release_lock()
  if existing.is_empty(): return _fail("An existing library entry failed validation; it was not overwritten.")
  _remove_flat_directory(stage)
  return {"ok": true, "entry": existing, "deduplicated": true}
 var labels: Array = discover(false).map(func(entry: Dictionary): return entry.label)
 var number := 1
 while labels.has("Generated World %d" % number): number += 1
 var meta := {"library_version": 1, "preset": false, "world_ref": world.source_metadata(),
  "created": Time.get_datetime_string_from_system(true), "label": "Generated World %d" % number,
  "origin_enrichment": enriched.descriptor, "origin_profiles": profiled.descriptor}
 if not _write_json(stage.path_join("metadata.json"), meta):
  _release_lock()
  _remove_flat_directory(stage)
  return _fail("World metadata could not be committed.")
 var committed := DirAccess.rename_absolute(stage, target) == OK
 _release_lock()
 if not committed: return _fail("World commit failed; complete staging will be recovered on restart.")
 return {"ok": true, "entry": _read_entry(target), "deduplicated": false}

func _acquire_lock() -> bool:
 if DirAccess.make_dir_recursive_absolute(_root()) != OK: return false
 var path := _root().path_join(".lock")
 if DirAccess.dir_exists_absolute(path):
  var owner := _json(path.path_join("owner.json"))
  if not _numeric(owner.get("pid")) or _pid_alive(int(owner.pid)): return false
  if not _remove_flat_directory(path): return false
 if DirAccess.make_dir_absolute(path) != OK: return false
 if not _write_json(path.path_join("owner.json"), {"pid": OS.get_process_id()}):
  _remove_flat_directory(path)
  return false
 return true

func _release_lock() -> void:
 _remove_flat_directory(_root().path_join(".lock"))

func begin_origin(entry: Dictionary) -> Dictionary:
 if entry.preset: return {"ok": true, "locked": false}
 if not _acquire_lock(): return _fail("The world library is busy or its lock needs recovery.")
 var current := _read_entry(entry.directory)
 if current.is_empty() or current.id != entry.id:
  _release_lock()
  return _fail("This world is no longer available. Choose another world.")
 return {"ok": true, "locked": true}

func end_origin(guard: Dictionary) -> void:
 if guard.get("locked", false): _release_lock()

func reference_status(entry: Dictionary) -> Dictionary:
 var path := ProjectSettings.globalize_path(save_root)
 if not DirAccess.dir_exists_absolute(path): return {"ok": true, "count": 0}
 var dir := DirAccess.open(path)
 if dir != null: dir.include_hidden = true
 if dir == null or not dir.get_directories().is_empty(): return _fail("Saved game dependencies could not be checked safely.")
 var matches := {}
 for name in dir.get_files():
  if not (name.ends_with(".json") or name.ends_with(".json.bak") or name.ends_with(".json.tmp")): continue
  var save := _json(path.path_join(name))
  var ref: Variant = save.get("world_ref")
  if save.get("save_version") != 1 or not ref is Dictionary: return _fail("A saved game's world reference is unreadable. Deletion is blocked.")
  var generator: Variant = ref.get("generator")
  if not generator is Dictionary or generator.get("provider") != "azgaar" or generator.get("version") != "1.153.1" or generator.get("upstreamCommit") != UPSTREAM or ref.get("schema_version") != 1:
   return _fail("A saved game's world reference is unsupported. Deletion is blocked.")
  if not ref.get("sha256") is String or not _hash_name(ref.sha256) or not ref.get("seed") is String or str(ref.seed).is_empty() or ref.get("id") != "azgaar:1.153.1:%s:%s" % [ref.seed, ref.sha256]:
   return _fail("A saved game's world reference is ambiguous. Deletion is blocked.")
  if ref.id == entry.id or ref.sha256 == entry.world.source_sha256:
   matches[str(save.get("playthrough_id", name))] = true
 return {"ok": true, "count": matches.size()}

func delete_world(entry: Dictionary) -> Dictionary:
 if entry.get("preset", true): return _fail("Preset worlds cannot be deleted.")
 if entry.get("directory", "").get_base_dir() != _root() or not _hash_name(str(entry.directory.get_file())): return _fail("Invalid world-library deletion target.")
 if not _acquire_lock(): return _fail("The world library is busy or its lock needs recovery.")
 var current := _read_entry(entry.directory)
 if current.is_empty() or current.id != entry.id:
  _release_lock()
  return _fail("The selected world changed or is unavailable.")
 var references := reference_status(current)
 if not references.ok or references.count > 0:
  _release_lock()
  if not references.ok: return references
  return _fail("This world is used by %d saved game%s.\nIt cannot be deleted." % [references.count, "" if references.count == 1 else "s"])
 var trash := _root().path_join(".trash-" + current.world.source_sha256 + "-" + Crypto.new().generate_random_bytes(8).hex_encode())
 var moved := DirAccess.rename_absolute(current.directory, trash) == OK
 _release_lock()
 if not moved: return _fail("Deletion could not be committed. The world remains available.")
 # Once in trash, it is unavailable. A later scan completes interrupted cleanup.
 _remove_flat_directory(trash)
 return {"ok": true}


func enrichment_directory(entry: Dictionary) -> String:
 if entry.get("preset", false): return "res://data/world_enrichment/presets/" + str(entry.key)
 return str(entry.directory).path_join("enrichment/origin-v1")

func ensure_enrichment(entry: Dictionary) -> Dictionary:
 var world: GameWorldTemplate = entry.world
 var target := enrichment_directory(entry)
 var lore := WorldOriginLore.new()
 if entry.get("preset", false) or DirAccess.dir_exists_absolute(target):
  if not lore.load_world(world, target): return _fail(lore.error)
  return {"ok": true, "descriptor": lore.descriptor}
 # Missing-only upgrade under the existing library lock. Publication follows
 # validation against every existing campaign pin, including recovery backups.
 if not _acquire_lock(): return _fail("The world library is busy. Local history was not changed.")
 var result := _compile_enrichment(entry, target)
 _release_lock()
 return result

func _compile_enrichment(entry: Dictionary, target: String) -> Dictionary:
 var world: GameWorldTemplate = entry.world
 var refs := reference_status(entry)
 if not refs.ok: return refs
 var pins: Array = []
 var save_names := DirAccess.get_files_at(save_root) if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(save_root)) else PackedStringArray()
 for name in save_names:
  if not (name.ends_with(".json") or name.ends_with(".json.bak") or name.ends_with(".json.tmp")): continue
  var save := _json(save_root.path_join(name))
  var reference: Dictionary = save.get("world_ref", {})
  if (reference.get("id") == world.world_id or reference.get("sha256") == world.source_sha256) and save.has("origin_enrichment"):
   pins.append(save.origin_enrichment)
 var helper := helper_location()
 var binary := helper.path_join("node.exe" if OS.get_name() == "Windows" else "node")
 var manifest := _json(helper.path_join("runtime.json"))
 if manifest.get("nodeVersion") != "v24.19.0" or not FileAccess.file_exists(binary) or FileAccess.get_sha256(binary) != manifest.get("runtimeSha256"):
  return _fail("The bundled enrichment runtime is missing or invalid. Factual world data remains available.")
 var pending := target + ".pending-upgrade-" + Crypto.new().generate_random_bytes(8).hex_encode()
 var log: Array = []
 var exit := OS.execute(binary, [helper.path_join("tools/world_enrichment/origin-world.mjs"), "--world", ProjectSettings.globalize_path(entry.path), "--output", ProjectSettings.globalize_path(pending)], log, true, false)
 var lore := WorldOriginLore.new()
 if exit != 0 or not lore.load_world(world, pending):
  _remove_flat_directory(pending, true)
  return _fail("Origin enrichment failed (code %d). No partial world was added. %s %s" % [exit, "\n".join(log).left(512), lore.error])
 for pin in pins:
  var why := lore.validate_pin(pin, world, -1, pending)
  if not why.is_empty():
   _remove_flat_directory(pending, true)
   return _fail("Origin enrichment cannot be upgraded without changing a saved campaign: " + why)
 if DirAccess.dir_exists_absolute(target) or DirAccess.rename_absolute(pending, target) != OK:
  _remove_flat_directory(pending, true)
  return _fail("Local history could not be committed. Please retry; existing history was preserved.")
 return {"ok": true, "descriptor": lore.descriptor}


func profiles_directory(entry: Dictionary) -> String:
 if entry.get("preset", false): return "res://data/world_enrichment/presets-profiles-v2/" + str(entry.key)
 return str(entry.directory).path_join("enrichment/profiles-v2")

func helper_status() -> Dictionary:
 var helper := helper_location()
 var manifest := _json(helper.path_join("runtime.json"))
 var runtime := helper.path_join("node.exe" if OS.get_name() == "Windows" else "node")
 if manifest.get("nodeVersion") != "v24.19.0" or not FileAccess.file_exists(runtime) or FileAccess.get_sha256(runtime) != manifest.get("runtimeSha256"):
  return _fail("The bundled world generator is unavailable. Install the matching game distribution or run the checkout bootstrap.")
 for pair in [["origin-v1", "runtime.json"], ["profiles-v2", "runtime-profiles-v2.json"], ["party-v1", "runtime-party-v1.json"]]:
  var packaged := helper.path_join("data/world_enrichment/" + pair[1])
  var expected := FileAccess.get_sha256("res://data/world_enrichment/" + pair[1])
  if manifest.get("enrichmentRuntimes", {}).get(pair[0]) != expected or not FileAccess.file_exists(packaged) or FileAccess.get_sha256(packaged) != expected:
   return _fail("The bundled generator does not match this game version. Run the checkout bootstrap or use the complete matching game distribution.")
 var profile_manifest := _json(helper.path_join("data/world_enrichment/runtime-party-v1.json"))
 for file in profile_manifest.get("files", {}):
  var path := helper.path_join(str(file))
  if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != profile_manifest.files[file]: return _fail("The bundled generator failed its content integrity check. Rebuild the matching helper.")
 return {"ok": true}

func ensure_profiles(entry: Dictionary) -> Dictionary:
 var world: GameWorldTemplate = entry.world
 world.enrichment_directory = enrichment_directory(entry)
 var target := profiles_directory(entry)
 world.profiles_directory = target
 var profiles := OriginProfiles.new()
 if entry.get("preset", false) or DirAccess.dir_exists_absolute(target):
  if not profiles.load_world(world, target): return _fail(profiles.error)
  return {"ok": true, "descriptor": profiles.descriptor}
 var ready := helper_status()
 if not ready.ok: return ready
 if not _acquire_lock(): return _fail("The world library is busy. Origin profiles were not changed.")
 var refs := reference_status(entry)
 if not refs.ok:
  _release_lock()
  return refs
 var pins: Array = []
 var save_names := DirAccess.get_files_at(save_root) if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(save_root)) else PackedStringArray()
 for name in save_names:
  if not (name.ends_with(".json") or name.ends_with(".json.bak") or name.ends_with(".json.tmp")): continue
  var save := _json(save_root.path_join(name))
  var ref: Dictionary = save.get("world_ref", {})
  if (ref.get("id") == world.world_id or ref.get("sha256") == world.source_sha256) and save.has("origin_profiles"): pins.append(save.origin_profiles)
 var pending := target + ".pending-" + Crypto.new().generate_random_bytes(8).hex_encode()
 var helper := helper_location()
 var binary := helper.path_join("node.exe" if OS.get_name() == "Windows" else "node")
 var log: Array = []
 var code := OS.execute(binary, [helper.path_join("tools/world_enrichment/profiles-world.mjs"), "--world", ProjectSettings.globalize_path(entry.path), "--output", ProjectSettings.globalize_path(pending)], log, true, false)
 var why := ""
 if code != 0 or not profiles.load_world(world, pending): why = "Origin profile enrichment could not be prepared. Existing worlds and saves were preserved. " + profiles.error
 if why.is_empty():
  for pin in pins:
   why = profiles.validate_pin(pin, world, pending)
   if not why.is_empty(): break
 if not why.is_empty():
  _remove_flat_directory(pending, true)
  _release_lock()
  return _fail(why)
 var committed := not DirAccess.dir_exists_absolute(target) and DirAccess.rename_absolute(pending, target) == OK
 if not committed: _remove_flat_directory(pending, true)
 _release_lock()
 if not committed: return _fail("Origin profiles could not be committed. Existing history was preserved.")
 return {"ok": true, "descriptor": profiles.descriptor}
