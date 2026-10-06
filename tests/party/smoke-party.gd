extends SceneTree
var failures := 0
func check(ok: bool, why: String) -> void:
 if not ok:
  failures += 1
  push_error(why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var service := PartyService.new()
 service.store.save_root = "user://game81-smoke-" + Crypto.new().generate_random_bytes(8).hex_encode()
 var entry: Dictionary = service.library.discover()[0]
 var world: GameWorldTemplate = entry.world
 var reader := OriginProfiles.new()
 check(reader.load_world(world), reader.error)
 var first: Dictionary = reader.projection.hometowns.values()[0]
 var created := service.store.create_playthrough(world, int(first.state_id), int(first.burg_id), int(first.province_id))
 var state: Dictionary = created.state
 state.origin_profiles = reader.descriptor
 var legacy := WorldOriginLore.new()
 check(legacy.load_world(world), legacy.error)
 state.origin_enrichment = legacy.descriptor
 var slot: String = state.playthrough_id
 check(service.store.save_new(slot, state, world).ok, "origin saved once")
 var made := service.operate(entry, slot, "generate")
 check(made.ok, str(made.get("error")))
 if made.ok:
  print(made.state.party.members[0].biography)
  var changed := service.operate(entry, slot, "edit", 2, {"name":"Edited Member","regenerate":true})
  check(changed.ok, str(changed.get("error")))
  if changed.ok:
   check(changed.state.party.members[1].name == "Edited Member", "name persists")
   check(changed.state.party.members[0] == made.state.party.members[0], "sibling unchanged")
  var ready := service.operate(entry, slot, "ready")
  check(ready.ok, str(ready.get("error")))
  check(service.store.load_save(slot, world).ok, "ready reload")
 print("GAME-81 smoke failures: ", failures)
 quit(1 if failures else 0)
