class_name ImmutableValidationCache
extends RefCounted
## Cache successful interpretation only. Every access rehashes every dependent
## immutable file and runtime input; changed/corrupt bytes always miss the cache.
static func fingerprint(world: GameWorldTemplate, directory: String, runtime_path: String) -> String:
 var paths: Array[String] = [runtime_path]
 for dir in [directory,OriginProfiles.directory(world),WorldOriginLore.directory(world) if world.enrichment_directory.is_empty() else world.enrichment_directory]:
  for name in ["descriptor.json","enrichment.json","public.json"]: paths.append(dir.path_join(name))
 var runtime := WorldOriginLore.read_json(runtime_path)
 var helper := GameWorldLibrary.new().helper_location()
 for file in runtime.get("files",{}):
  var path := "res://"+str(file)
  if not FileAccess.file_exists(path): path=helper.path_join(str(file))
  paths.append(path)
 paths.sort()
 var hashes: Array = [world.world_id,world.source_sha256]
 for path in paths: hashes.append([path,FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"])
 return JSON.stringify(hashes).sha256_text()
