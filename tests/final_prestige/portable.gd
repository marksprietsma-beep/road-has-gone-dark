extends Node
## Copy a real earned save byte-for-byte to clean paths; no alternate save writer.
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base: String=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0")
 var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));var slot: String=proof.slot
 var original: String=base.path_join("saves").path_join(slot+".json");var before: String=FileAccess.get_sha256(original)
 var folder: String=OS.get_environment("FINAL_PRESTIGE_ROOT").get_base_dir().path_join("portable-cold")
 var checks := 0;var failures := 0;var fresh: bool=not DirAccess.dir_exists_absolute(folder)
 DirAccess.make_dir_recursive_absolute(folder.path_join("saves"))
 var copied: int=DirAccess.copy_absolute(original,folder.path_join("saves").path_join(slot+".json"));checks+=1
 if not fresh or copied!=OK:failures+=1;print("ASSERTION_FAILED portable campaign starts with clean paths and a byte-identical original save")
 var service:=AdventureService.new();service.store.save_root=folder.path_join("saves");service.library.library_root=folder.path_join("worlds");service.library.save_root=service.store.save_root;service.cache_root=folder.path_join("cache")
 var entry: Dictionary=service.library.discover()[0];var loaded: Dictionary=service.operate(entry,slot,"resume");checks+=1
 if not loaded.ok or RulesJson.digest(loaded.get("state",{}))!=proof.state_hash:failures+=1;print("ASSERTION_FAILED exact earned campaign loads against bundled world and clean library/cache ",JSON.stringify(loaded.get("error","")))
 if loaded.ok:
  for id in loaded.state.party_ids:
   checks+=1
   if CharacterBuilderRecords.xp(loaded.state,id)!=proof.earned_xp or loaded.state.mechanics.records[id].advancement_history!=proof.builds[id].history:failures+=1;print("ASSERTION_FAILED portable identity/earned XP/history exact")
 checks+=1
 if FileAccess.get_sha256(original)!=before:failures+=1;print("ASSERTION_FAILED clean import changed primary earned save")
 var pin: Dictionary=RulesRecords.new_character_registry().rules_ref()
 FileAccess.open(folder.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":pin,"slot":slot,"earned_xp":proof.earned_xp,"source_save_sha256":before,"clean_library_cache":fresh,"exact_earned_campaign":failures==0,"xp_injected":false,"scope":"Independent native process copies a real original-writer save byte-for-byte; loads with bundled preset world and fresh library/cache. No second writer, XP grant or altered identities."}))
 print("FINAL_PRESTIGE_PORTABLE ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
