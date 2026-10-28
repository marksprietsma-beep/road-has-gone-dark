extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 var manifest: Dictionary=RulesJson.normalize(WorldOriginLore.read_json("res://data/rules/packs.json"));var failures := 0;var checks := 0;var hashes := {}
 for row in manifest.packs:
  var source:=RulesRegistry.new();var loaded: Dictionary=source.load_pack(row.path)
  checks+=1
  if not loaded.ok:failures+=1;print("ASSERTION_FAILED bundled pack loads ",row.path," ",JSON.stringify(loaded.get("errors",[])));continue
  checks+=1
  if RulesJson.normalize(source.rules_ref())!=row.rules_ref:failures+=1;print("ASSERTION_FAILED exact bundled pin ",row.path)
  hashes[row.rules_ref.pack_id]=FileAccess.get_sha256(row.path)
 var current: Dictionary=RulesJson.normalize(RulesRecords.new_character_registry().rules_ref());checks+=1
 if current!=manifest.packs.back().rules_ref:failures+=1;print("ASSERTION_FAILED fresh campaign latest default")
 var folder: String=OS.get_environment("DRAGON_WARSHAPER_ROOT");DirAccess.make_dir_recursive_absolute(folder)
 FileAccess.open(folder.path_join("pins-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":current,"pack_count":manifest.packs.size(),"raw_sha256":hashes}))
 print("DRAGON_WARSHAPER_PINS ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
