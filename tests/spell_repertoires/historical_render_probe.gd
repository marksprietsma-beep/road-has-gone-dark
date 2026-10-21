extends SceneTree
## Actual archived records and authoritative validators; Windows-only runner.
const FIXTURES := "res://tests/spell_repertoires/historical-render-fixtures.json"
const Capture = preload("res://tests/spell_repertoires/capture_driver.gd")
var checks := 0
var failures := 0
var diagnostics := {}
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("GAME151_ROOT");DirAccess.make_dir_recursive_absolute(base)
 var archived: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(FIXTURES))
 var original_bytes := FileAccess.get_sha256(FIXTURES)
 var display := RulesRecords.new_character_registry();var kernel := RulesCharacter.new(display)
 check(display.rules_ref().pack_id=="trhgd-character-v23","current display remains immutable23")
 if OS.get_environment("GAME151_RESTART")=="1":
  var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
  check(original_bytes==saved.fixture_sha256,"archived source bytes unchanged across processes")
  for group in ["originals","rendered"]:
   for key in saved[group]:
    var record: Dictionary=saved[group][key];var source := RulesRecords.registry(record)
    var d := RulesCharacter.new(source).derive_character(record)
    check(d.ok and d.snapshot.snapshot_hash==saved.hashes[group][key],"exact cold derived history/resources "+group+"/"+key)
    check(RulesJson.digest(record)==saved.record_hashes[group][key],"exact cold record/pin "+group+"/"+key)
  finish(base,true);return
 var rendered := {};var hashes := {"originals":{},"rendered":{}};var record_hashes := hashes.duplicate(true)
 for key in archived.records:
  var record: Dictionary=archived.records[key];var source := RulesRecords.registry(record)
  var d := RulesCharacter.new(source).derive_character(record)
  check(d.ok and source.rules_ref().pack_id=="trhgd-character-v17","original actual historical fixture validates "+key)
  if not d.ok:continue
  check(d.snapshot.snapshot_hash==archived.hashes[key] and RulesJson.digest(record)==archived.record_hashes[key],"original snapshot and exact-record hashes match successful native history "+key)
  var before := RulesJson.digest(record)
  var naive: Dictionary=record.duplicate(true);naive.character_id="display:"+key;naive.rules_ref=display.rules_ref()
  var broken := kernel.derive_character(naive)
  var expected: Array=[]
  if key=="wizard-dissonant-seal":expected=["wizard-stillness-lattice-prepared","wizard-unweaving-tide-prepared"]
  if key=="cleric-return-to-breath":expected=["cleric-concord-release-prepared","cleric-renewing-benediction-prepared"]
  var errors: Array=broken.get("errors",[])
  diagnostics[key]=errors
  print("GAME151 original repin diagnostics ",key,": ",JSON.stringify(errors))
  check(broken.ok==expected.is_empty(),"precise prior display failure scope "+key)
  check(errors.size()==expected.size() and errors.all(func(e: Dictionary):return e.code=="runtime.resource_missing" and expected.has(str(e.path).trim_prefix("runtime.resources."))),"only exact new missing copy pools fail; permanent selections remain legal "+key)
  var projected := Capture.render_record(record,naive.character_id,display)
  check(projected.ok,"same helper used by actual capture validates "+key+JSON.stringify(projected.get("errors",[])))
  if not projected.ok:continue
  var r: Dictionary=projected.candidate;var current := kernel.derive_character(r)
  check(current.ok and r.rules_ref==display.rules_ref(),"projected record fully validates under current pin")
  check(RulesJson.digest(record)==before,"render projection never changes archived record")
  var comparable: Dictionary=r.duplicate(true);comparable.character_id=record.character_id;comparable.rules_ref=record.rules_ref
  for pool in projected.added_zero_pools:
   check(r.runtime.resources[pool]==0 and current.snapshot.resource_capacities[pool]==0,"new copy pool has no casts or capacity "+pool)
   comparable.runtime.resources.erase(pool)
  check(RulesJson.digest(comparable)==before,"identity/display pin/empty new pools are the only differences; all history/feats/skills/choices/resources remain exact")
  check(projected.added_zero_pools.size()==expected.size(),"no arbitrary resource normalisation")
  for pool in record.runtime.resources:check(r.runtime.resources[pool]==record.runtime.resources[pool],"no existing slot/copy/resource refill "+pool)
  for pool in expected:
   var aid: String=display.definition("resources",pool).prepared_ability
   var casted := RulesEffects.new(display).use_ability(r,r,aid,{"main":1,"move":1,"reaction":1},RulesRng.initial("unprepared"))
   check(not casted.ok,"projection cannot grant an unprepared new spell")
  rendered[key]=r;hashes.originals[key]=d.snapshot.snapshot_hash;record_hashes.originals[key]=before
  hashes.rendered[key]=current.snapshot.snapshot_hash;record_hashes.rendered[key]=RulesJson.digest(r)
 # A historically legal mixed domain must remain rejected by current permanent
 # requirements, not be silently rewritten by the diagnostic projection.
 var crossed: Dictionary=archived.records["cleric-return-to-breath"].duplicate(true)
 crossed.advancement_history[5].specialisations["cleric-choice-6"]="war"
 check(RulesCharacter.new(RulesRecords.registry(crossed)).derive_character(crossed).ok,"v17 cross-domain fixture remains legal under its original pin")
 var cross_hash := RulesJson.digest(crossed);var rejected := Capture.render_record(crossed,"crossed",display)
 check(not rejected.ok and rejected.errors.any(func(e: Dictionary):return e.code=="requirement.feature" and e.id=="cleric-war-1-feature" and e.path=="requirements"),"v23 domain prerequisite rejects rather than respecs historical choices: "+JSON.stringify(rejected.get("errors",[])))
 check(RulesJson.digest(crossed)==cross_hash,"negative projection retains exact original choice history")
 var bad_pin: Dictionary=archived.records["wizard-dissonant-seal"].duplicate(true);bad_pin.rules_ref.content_hash="0".repeat(64)
 check(not Capture.render_record(bad_pin,"bad-pin",display).ok,"forged historical version pin still rejects")
 check(FileAccess.get_sha256(FIXTURES)==original_bytes,"source artifact fixture never rewritten")
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify({"originals":archived.records,"rendered":rendered,"hashes":hashes,"record_hashes":record_hashes,"fixture_sha256":original_bytes}))
 finish(base)
func finish(base: String,restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"diagnostics":diagnostics,"source_rules":"trhgd-character-v17","display_rules":"trhgd-character-v23","fixture_file_sha256":FileAccess.get_sha256(FIXTURES),"production_changed":false}
 FileAccess.open(base.path_join("restart-proof.json" if restart else "proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME151 ",JSON.stringify(proof));quit(1 if failures else 0)
