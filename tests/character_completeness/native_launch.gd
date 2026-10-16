extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var phase := OS.get_environment("GAME126_PHASE")
 var path: String={"audit":"audit_driver","repair":"repair_driver","options":"options_driver","compatibility":"compatibility_driver","journey":"journey_driver"}.get(phase,"")
 if phase=="legacy_routes":
  var saved := WorldOriginLore.read_json("res://tests/character_completeness/fixtures/prestige-v15-records.json")
  var source := RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v15.json")
  if not loaded.ok or source.rules_ref()!=saved.rules_ref:get_tree().quit(1);return
  var checks := 0;var failures := 0;var kernel := RulesCharacter.new(source)
  for id in saved.records:
   var result := kernel.derive_character(saved.records[id]);checks+=1
   if not result.ok or result.snapshot.snapshot_hash!=saved.hashes[id]:failures+=1;push_error("Exact legacy route "+id)
  FileAccess.open(OS.get_environment("GAME126_ROOT").path_join("legacy-routes-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"rules_ref":source.rules_ref(),"checks":checks,"failures":failures,"earned_xp":false,"scope":"Cold replay of485 legal v15 fixture routes, not an exhaustive search or human career acceptance."}))
  get_tree().quit(1 if failures else 0);return
 if path.is_empty():push_error("Unknown completeness QA phase");get_tree().quit(1);return
 var worker: Node=load("res://tests/character_completeness/"+path+".gd").new()
 worker.no_quit=true;add_child(worker);await worker.completed
 get_tree().quit(1 if worker.failures else 0)
