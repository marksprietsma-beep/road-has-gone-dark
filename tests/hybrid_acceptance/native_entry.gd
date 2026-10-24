extends Node
## Actually commit or decline prestige in native forks of the real earned13/1690XP witnesses.
var checks := 0
var failures := 0
var root := ""
var library := GameWorldLibrary.new()
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 root=OS.get_environment("HYBRID_NATIVE_ENTRY_ROOT");DirAccess.make_dir_recursive_absolute(root)
 var input := OS.get_environment("HYBRID_IMPORTED_EARNED").path_join("journeys/cohort-0")
 library.library_root=input.path_join("library")
 var entry: Dictionary=library.discover()[0]
 if OS.get_environment("HYBRID_RESTART")=="1":cold(entry);return
 var proof := WorldOriginLore.read_json(input.path_join("proof.json"));var results := {}
 for cls in ["wizard","sorcerer"]:
  var state := WorldOriginLore.read_json(input.path_join("earned-qualified-"+cls+".json"))
  var index: int=1 if cls=="wizard" else 2;var id: String=state.party_ids[index];var before := RulesJson.digest(state)
  check(before==proof.earned_entry_witnesses[cls].state_hash and CharacterBuilderRecords.xp(state,id)==1690,"actual immutable earned pre-entry witness "+cls)
  var driver: Node=load("res://tests/hybrid_acceptance/journey.gd").new();driver.source=RulesRecords.registry(state);driver.kernel=CharacterBuilderRecords.kernel(state);driver.configs=[["duskblade","human",""],["wizard","human","archmage"],["sorcerer","human","archmage"]]
  var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new();planner.source=driver.source;planner.kernel=driver.kernel;driver.planner=planner
  check(driver.kernel.available_advancement(state.mechanics.records[id]).classes.archmage.ok,"native permanent entry is genuinely available "+cls)
  for accept in [false,true]:
   var chosen: String="archmage" if accept else cls
   var planned: Dictionary=driver.planned(state.mechanics.records[id],chosen,index);check(planned.ok,"native legal deliberate choice "+chosen)
   if not planned.ok:continue
   var choice: Dictionary=planned.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   var preview := CharacterBuilderRecords.preview_advancement(state,id,choice);check(preview.ok,"actual earned1690XP funds chosen/declined path "+cls)
   if not preview.ok:continue
   var name: String=cls+("-accept" if accept else "-decline")
   var store := GamePlaythroughStore.new();store.save_root=root.path_join(name)
   check(store.save_new(state.playthrough_id,state,entry.world).ok,"one authoritative writer creates untouched verification fork")
   var builder := CharacterBuilderService.new();builder.store=store;builder.library=library
   var out := builder.operate(entry,state.playthrough_id,"builder_advance",index+1,{"character_id":id,"before_hash":preview.before_hash,"candidate_hash":preview.candidate_hash,"choice":preview.choice})
   check(out.ok,"actual production writer commit "+name+str(out.get("error","")))
   if not out.ok:continue
   var r: Dictionary=out.state.mechanics.records[id];var d: Dictionary=driver.kernel.derive_character(r)
   check(d.ok and r.advancement_history.size()==14 and r.advancement_history.back().class_id==chosen and CharacterBuilderRecords.xp(out.state,id)==1690,"native ordered manual history and unchanged legitimate XP")
   check(int(d.snapshot.class_levels.get("archmage",0))==(1 if accept else 0),"qualification never automatically assigns prestige "+name)
   results[name]={"slot":state.playthrough_id,"character_id":id,"state_hash":RulesJson.digest(out.state),"snapshot_hash":d.snapshot.snapshot_hash,"chosen":chosen}
  check(RulesJson.digest(state)==before,"native choice tests never rewrite the original earned witness")
  planner.free();driver.free()
 FileAccess.open(root.path_join("entry-saved.json"),FileAccess.WRITE).store_string(JSON.stringify(results))
 finish()
func cold(entry: Dictionary) -> void:
 var saved := WorldOriginLore.read_json(root.path_join("entry-saved.json"))
 check(saved.size()==4,"both parents have real accept and decline saves")
 for name in saved:
  var row: Dictionary=saved[name];var store := GamePlaythroughStore.new();store.save_root=root.path_join(name)
  var loaded := store.load_save(row.slot,entry.world);check(loaded.ok,"native real entry/decline cold loads "+name)
  if not loaded.ok:continue
  var r: Dictionary=loaded.state.mechanics.records[row.character_id];var d := CharacterBuilderRecords.kernel(loaded.state).derive_character(r)
  check(RulesJson.digest(loaded.state)==row.state_hash and d.ok and d.snapshot.snapshot_hash==row.snapshot_hash,"exact whole campaign and derived snapshot after native entry/decline restart")
  check(r.advancement_history.back().class_id==row.chosen and CharacterBuilderRecords.xp(loaded.state,row.character_id)==1690,"durable chosen level without an XP grant")
 finish(true)
func finish(restart := false) -> void:
 FileAccess.open(root.path_join("entry-restart-proof.json" if restart else "entry-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual source-earned13/1690XP witnesses; production writer explicitly commits or declines first Archmage level. Separate forks, original source untouched."}))
 print("HYBRID_NATIVE_ENTRY ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
