class_name PartyService
extends RefCounted
## One helper and the existing save store. UI never commits unchecked candidates.
static var handoff := {}
var library := GameWorldLibrary.new()
var store := GamePlaythroughStore.new()
var error := ""

func fail(why: String) -> Dictionary:
 error = why
 return {"ok": false, "error": why}

func _journal(slot: String) -> String:
 return ProjectSettings.globalize_path(store._slot_path(slot)) + ".party-recovery"

func recover(slot: String, world: GameWorldTemplate) -> Dictionary:
 var path := ProjectSettings.globalize_path(store._slot_path(slot))
 var journal := _journal(slot)
 if not FileAccess.file_exists(journal): return store.load_save(slot, world)
 var j := WorldOriginLore.read_json(journal)
 if j.size() != 2 or not j.get("before") is String or not j.get("after_sha") is String: return fail("Party recovery record is unreadable. The campaign was preserved.")
 var old: Variant = JSON.parse_string(j.before)
 if not old is Dictionary or old.get("playthrough_id") != slot or not store._validate(old, world).is_empty(): return fail("Party recovery needs its exact world history restored. The campaign was preserved.")
 # Interrupted Windows rollback: the unverified file was moved aside before
 # publishing the previous bytes. Recover only that exact owned transaction.
 if not FileAccess.file_exists(path) and FileAccess.file_exists(path + ".party-unverified") and FileAccess.get_sha256(path + ".party-unverified") == j.after_sha:
  var prior := path + ".party-rollback"
  if FileAccess.get_sha256(prior) == str(j.before).sha256_text() and DirAccess.rename_absolute(prior, path) == OK:
   DirAccess.remove_absolute(path + ".party-unverified")
 if not FileAccess.file_exists(path) and FileAccess.file_exists(path + ".bak"):
  var interrupted := store.load_save(slot, world)
  if not interrupted.ok: return interrupted
 var current := FileAccess.get_sha256(path)
 if current == j.after_sha:
  var loaded := store.load_save(slot, world)
  if loaded.ok:
   DirAccess.remove_absolute(journal)
   return loaded
 if current != j.after_sha and current != str(j.before).sha256_text(): return fail("Campaign changed outside party setup. Recovery was preserved.")
 if current == str(j.before).sha256_text():
  if FileAccess.file_exists(path + ".tmp") and FileAccess.get_sha256(path + ".tmp") == j.after_sha: DirAccess.remove_absolute(path + ".tmp")
  DirAccess.remove_absolute(journal)
  return store.load_save(slot, world)
 if not _restore(slot, j): return fail("Party recovery could not restore the previous draft. The campaign was preserved.")
 return store.load_save(slot, world)

func _restore(slot: String, j: Dictionary) -> bool:
 var path := ProjectSettings.globalize_path(store._slot_path(slot))
 var temp := path + ".party-rollback"
 var rejected := path + ".party-unverified"
 if FileAccess.file_exists(temp) or FileAccess.file_exists(rejected): return false
 var file := FileAccess.open(temp, FileAccess.WRITE)
 if file == null: return false
 file.store_string(j.before)
 file.flush()
 file.close()
 if DirAccess.rename_absolute(path, rejected) != OK:
  DirAccess.remove_absolute(temp)
  return false
 if DirAccess.rename_absolute(temp, path) != OK:
  DirAccess.rename_absolute(rejected, path)
  return false
 DirAccess.remove_absolute(rejected)
 DirAccess.remove_absolute(_journal(slot))
 return true

func commit(slot: String, candidate: Dictionary, world: GameWorldTemplate) -> Dictionary:
 var before := recover(slot, world)
 if not before.ok: return before
 var why := store._validate(candidate, world)
 if not why.is_empty(): return fail(why)
 var path := ProjectSettings.globalize_path(store._slot_path(slot))
 var raw := FileAccess.get_file_as_string(path)
 if before.state.playthrough_id != candidate.playthrough_id: return fail("Campaign identity changed")
 var journal := {"before": raw, "after_sha": JSON.stringify(candidate, "  ").sha256_text()}
 var file := FileAccess.open(_journal(slot), FileAccess.WRITE)
 if file == null: return fail("Could not prepare party transaction. Existing draft was preserved.")
 file.store_string(JSON.stringify(journal))
 file.flush()
 file.close()
 var written := store.save_existing(slot, candidate, world)
 if not written.ok:
  DirAccess.remove_absolute(_journal(slot))
  return written
 var validated := store.load_save(slot, world)
 if not validated.ok:
  if not _restore(slot, journal): return fail("Written party could not be verified. Recovery is pending; no success was recorded.")
  return fail("Party could not be verified. The previous origin/draft was restored; please retry.")
 DirAccess.remove_absolute(_journal(slot))
 return validated

func _helper(entry: Dictionary, request: Dictionary) -> Dictionary:
 var ready := library.helper_status()
 if not ready.ok: return ready
 var temp := ProjectSettings.globalize_path("user://party-jobs").path_join(Crypto.new().generate_random_bytes(16).hex_encode())
 if DirAccess.make_dir_recursive_absolute(temp) != OK: return fail("Cannot prepare character generation")
 var input := temp.path_join("request.json")
 var output := temp.path_join("result.json")
 var f := FileAccess.open(input, FileAccess.WRITE)
 if f == null: return fail("Cannot write character request")
 f.store_string(JSON.stringify(request))
 f.close()
 var helper := library.helper_location()
 var log: Array = []
 var code := OS.execute(helper.path_join("node.exe" if OS.get_name() == "Windows" else "node"), [helper.path_join("tools/party/entry.mjs"), "--world", ProjectSettings.globalize_path(entry.path), "--peoples", ProjectSettings.globalize_path(WorldPeoples.directory(entry.world)), "--request", input, "--output", output], log, true, false)
 var result := WorldOriginLore.read_json(output)
 for name in [input, output]:
  if FileAccess.file_exists(name): DirAccess.remove_absolute(name)
 DirAccess.remove_absolute(temp)
 if code != 0 or not result.get("ok", false): return fail("Character generation failed. The campaign was preserved. " + str(log).left(300))
 return result

func operate(entry: Dictionary, slot: String, operation: String, member: int = 1, changes: Dictionary = {}) -> Dictionary:
 if store._slot_path(slot).is_empty(): return fail("Invalid campaign slot")
 var lock := ProjectSettings.globalize_path(store.save_root).path_join(".party-lock-" + slot)
 if DirAccess.dir_exists_absolute(lock):
  var owner := WorldOriginLore.read_json(lock.path_join("owner.json"))
  if not owner.get("pid") is float and not owner.get("pid") is int or OS.is_process_running(int(owner.get("pid", -1))): return fail("Party setup is already updating this campaign.")
  DirAccess.remove_absolute(lock.path_join("owner.json"))
  DirAccess.remove_absolute(lock)
 if DirAccess.make_dir_absolute(lock) != OK: return fail("Cannot lock party draft. The campaign was preserved.")
 var owner_file := FileAccess.open(lock.path_join("owner.json"), FileAccess.WRITE)
 if owner_file == null:
  DirAccess.remove_absolute(lock)
  return fail("Cannot record party transaction ownership.")
 owner_file.store_string(JSON.stringify({"pid":OS.get_process_id()}))
 owner_file.close()
 library.save_root = store.save_root
 var guard := library.begin_origin(entry)
 var result := guard
 if guard.ok:
  result = _operate_locked(entry, slot, operation, member, changes)
  library.end_origin(guard)
 DirAccess.remove_absolute(lock.path_join("owner.json"))
 DirAccess.remove_absolute(lock)
 return result

func _operate_locked(entry: Dictionary, slot: String, operation: String, member: int, changes: Dictionary) -> Dictionary:
 var world: GameWorldTemplate = entry.world
 var loaded := recover(slot, world)
 if not loaded.ok: return loaded
 var state: Dictionary = loaded.state
 var peoples := WorldPeoples.new()
 if not peoples.load_world(world):
  if FileAccess.file_exists(WorldPeoples.directory(world).path_join("descriptor.json")): return fail(peoples.error)
  var ensured := _helper(entry, {"operation": "ensure"})
  if not ensured.ok: return ensured
  if not peoples.load_world(world): return fail(peoples.error)
 if operation == "generate" and state.has("party"): return {"ok": true, "state": state}
 var generated := _helper(entry, {"operation": operation, "campaign": state, "slot": member, "changes": changes})
 if not generated.ok: return generated
 var candidate := state.duplicate(true)
 candidate.party = generated.party
 candidate.onboarding_stage = "party_ready" if candidate.party.status == "ready" else "party_creation"
 for i in 3:
  candidate.characters[i].name = candidate.party.members[i].name
  candidate.characters[i].people_id = candidate.party.members[i].people_id
  candidate.characters[i].role_id = candidate.party.members[i].role_id
  candidate.characters[i].background_id = candidate.party.members[i].background_id
 return commit(slot, candidate, world)

func resumable() -> Dictionary:
 var entries := library.discover()
 if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(store.save_root)): return {}
 var names := DirAccess.get_files_at(store.save_root)
 var choices: Array = []
 for name in names:
  if not name.ends_with(".json"): continue
  var raw := WorldOriginLore.read_json(store.save_root.path_join(name))
  if raw.get("save_version") != 1: continue
  for entry in entries:
   if entry.id == raw.get("world_ref", {}).get("id"):
    choices.append({"entry": entry, "slot": name.trim_suffix(".json"), "modified": FileAccess.get_modified_time(store.save_root.path_join(name))})
 choices.sort_custom(func(a: Dictionary, b: Dictionary): return a.modified > b.modified if a.modified != b.modified else a.slot < b.slot)
 return choices[0] if not choices.is_empty() else {}
