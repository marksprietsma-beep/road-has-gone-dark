extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var source:=RulesRegistry.new();var result: Dictionary=source.load_pack("res://data/rules/trhgd-character-v35.json");var checks := 1;var failures := 0
 if not result.ok:failures+=1;print("ASSERTION_FAILED typed candidate35 schema ",JSON.stringify(result.errors))
 if result.ok:
  checks+=1
  if RulesRecords.new_character_registry().rules_ref()!=source.rules_ref():failures+=1;print("ASSERTION_FAILED actual fresh campaign defaults to35")
 var folder: String=OS.get_environment("FINAL_PRESTIGE_ROOT");DirAccess.make_dir_recursive_absolute(folder)
 FileAccess.open(folder.path_join("schema-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"errors":result.get("errors",[]),"scope":"Typed complete current pack and actual fresh-campaign registry, not mechanical acceptance."}))
 print("FINAL_PRESTIGE_SCHEMA ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
