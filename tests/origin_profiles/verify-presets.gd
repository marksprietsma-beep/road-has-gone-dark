extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr(message)
func _initialize() -> void:
 for key in GameWorldLibrary.PRESETS:
  var world := GameWorldTemplate.new()
  check(world.load_fixture("res://tests/worldgen/fixtures/" + key + ".json"), "source loads")
  var profiles := OriginProfiles.new()
  check(profiles.load_world(world), profiles.error)
  var old := WorldOriginLore.new()
  check(old.load_world(world), old.error)
  for state in world.raw_counts().states:
   for home in world.home_candidates(state, -1, -1):
    var row := profiles.public_profile("hometowns", str(home.id))
    check(not row.is_empty(), "profile for every eligible hometown")
    check(row.get("memory") == old.public_origin(world, int(home.id)).get("memory"), "exact legacy memory")
    check(row.get("state_id") == home.state_id, "profile state source")
  var store := GamePlaythroughStore.new()
  var state := int(profiles.projection.states.keys()[0]) if not profiles.projection.is_empty() else -1
  var homes := world.home_candidates(state, -1, 1)
  if not homes.is_empty():
   var created := store.create_playthrough(world, state, int(homes[0].id))
   check(created.ok, "playthrough created")
   created.state.origin_enrichment = old.descriptor.duplicate(true)
   created.state.origin_profiles = profiles.descriptor.duplicate(true)
   check(store._validate(created.state, world).is_empty(), "both pinned packages validate")
   created.state.origin_profiles.enrichment_sha = "wrong"
   check(not store._validate(created.state, world).is_empty(), "wrong profile pin refused")
   created.state.erase("origin_profiles")
   check(store._validate(created.state, world).is_empty(), "unchanged V1 campaign accepted")
 print("GAME-80 preset/legacy: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
