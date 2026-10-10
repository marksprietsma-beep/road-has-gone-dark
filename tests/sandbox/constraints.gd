extends SceneTree
## Synthetic safety fixtures complement the measured real-world corpus.
var checks := 0
var failures := 0
func check(value: bool,why: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(why)
func _initialize() -> void:
 for index in [25,46,172]:
  var recipe := {"version":SandboxGenerator.VERSION,"rules_sha":FileAccess.get_sha256(SandboxGenerator.SOURCE),"seed":("retry-constraint:"+str(index)).sha256_text(),"site_id":"constraint-probe:"+str(index),"kind":"ruins","environment":"forest","composition":index%4}
  check(SandboxGenerator.geometry_error(SandboxGenerator.candidate(recipe,0))=="disconnected walkable area","real composed initial candidate rejected")
  var board := SandboxGenerator.battlefield(recipe)
  check(board.get("attempt")==1 and SandboxGenerator.geometry_error(board).is_empty(),"bounded deterministic retry finds connected next candidate")
  SandboxGenerator._boards.erase(RulesJson.digest(recipe))
  check(SandboxGenerator.battlefield(recipe)==board,"cold regeneration retains exact accepted attempt")
 var saved_rules := SandboxGenerator.rules().duplicate(true)
 var saved_boards := SandboxGenerator._boards.duplicate(true)
 SandboxGenerator._rules=saved_rules.duplicate(true)
 SandboxGenerator._rules.sizes=[[3,6]] # Impossible deployment; test-only invalid configuration.
 SandboxGenerator._boards={}
 var invalid := {"version":SandboxGenerator.VERSION,"rules_sha":FileAccess.get_sha256(SandboxGenerator.SOURCE),"seed":"bounded-exhaustion".sha256_text(),"site_id":"constraint-probe:exhaustion","kind":"ruins","environment":"forest","composition":0}
 for attempt in int(saved_rules.max_attempts):check(SandboxGenerator.geometry_error(SandboxGenerator.candidate(invalid,attempt))=="invalid spawn","every exhausted attempt is invalid")
 check(SandboxGenerator.battlefield(invalid).is_empty(),"exhaustion returns explicit failure; no unrestricted reseeding")
 SandboxGenerator._rules=saved_rules;SandboxGenerator._boards=saved_boards
 var evidence := OS.get_environment("GAME96_TEST_ROOT")
 DirAccess.make_dir_recursive_absolute(evidence)
 FileAccess.open(evidence.path_join("constraints.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"synthetic_rejected_candidates":3,"accepted_attempt":1,"exhausted_attempts":saved_rules.max_attempts},"  ")+"\n")
 print("GAME96 GENERATION CONSTRAINTS ",checks," checks / ",failures," failures");quit(1 if failures else 0)
