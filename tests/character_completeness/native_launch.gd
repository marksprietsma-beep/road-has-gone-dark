extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME126_PHASE")
 var path: String={"audit":"audit_driver","repair":"repair_driver","legacy_mechanics":"legacy_mechanics","options":"options_driver","compatibility":"compatibility_driver","journey":"journey_driver"}.get(phase,"")
 if phase=="legacy_routes":
  var saved := WorldOriginLore.read_json("res://tests/character_completeness/fixtures/prestige-v15-records.json")
  var source := RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v15.json")
  var errors: Array=legacy_header_errors(saved,source) if loaded.ok else loaded.get("errors",[])
  var boundary := {"checks":0,"failures":0,"errors":[]}
  if errors.is_empty():boundary=load("res://tests/character_completeness/legacy_header_checks.gd").verify(source,saved)
  errors.append_array(boundary.errors)
  var checks := 0;var failures := errors.size();var kernel := RulesCharacter.new(source)
  if errors.is_empty():
   for id in saved.records:
    var record: Dictionary=saved.records[id]
    var result := kernel.derive_character(record);checks+=1
    if not result.ok:
     failures+=1;errors.append({"route":id,"reason":"derivation","errors":result.get("errors",[])})
    elif result.snapshot.snapshot_hash!=saved.hashes[id]:
     failures+=1;errors.append({"route":id,"reason":"exact snapshot hash","expected":saved.hashes[id],"actual":result.snapshot.snapshot_hash})
  for error in errors:push_error("Legacy route verification: "+JSON.stringify(error))
  FileAccess.open(OS.get_environment("GAME126_ROOT").path_join("legacy-routes-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"rules_ref":source.rules_ref(),"checks":checks,"failures":failures,"errors":errors,"fixture_boundary":boundary,"earned_xp":false,"scope":"Cold replay of485 legal v15 fixture routes, not an exhaustive search or human career acceptance."}))
  print("LEGACY ROUTES checks=",checks," failures=",failures)
  get_tree().quit(1 if failures else 0);return
 if path.is_empty():push_error("Unknown completeness QA phase");get_tree().quit(1);return
 var script_path: String="res://tests/character_wave_five/mechanics_driver.gd" if phase=="legacy_mechanics" else "res://tests/character_completeness/"+path+".gd"
 var worker: Node=load(script_path).new()
 worker.no_quit=true;add_child(worker);await worker.completed
 get_tree().quit(1 if worker.failures else 0)

static func legacy_header_errors(saved: Dictionary,source: RulesRegistry) -> Array:
 var errors: Array=[]
 # JSON numbers reload as floats. Use the same integer-only normalization as
 # production pack/character ingestion; never replace or ignore a pin field.
 var pin: Variant=RulesJson.normalize(saved.get("rules_ref",{}))
 if pin!=source.rules_ref():errors.append({"reason":"exact v15 rules pin","expected":source.rules_ref(),"actual":pin})
 if not saved.get("records") is Dictionary or not saved.get("hashes") is Dictionary:
  errors.append({"reason":"fixture records/hashes dictionaries missing"});return errors
 if saved.records.size()!=485 or saved.hashes.size()!=485:errors.append({"reason":"expected485 exact historical witnesses","records":saved.records.size(),"hashes":saved.hashes.size()})
 for id in saved.records:
  if not saved.hashes.has(id):errors.append({"reason":"missing expected hash","route":id})
  if not saved.records[id] is Dictionary or RulesJson.normalize(saved.records[id].get("rules_ref",{}))!=source.rules_ref():errors.append({"reason":"route pin differs from v15","route":id})
 for id in saved.hashes:
  if not saved.records.has(id):errors.append({"reason":"unexpected hash without record","route":id})
 return errors
