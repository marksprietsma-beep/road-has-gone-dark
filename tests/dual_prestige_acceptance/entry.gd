extends Node
var checks := 0
var failures := 0
var folder := ""
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 folder=OS.get_environment("DUAL_ENTRY_ROOT");DirAccess.make_dir_recursive_absolute(folder)
 var earned := OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0")
 var library := GameWorldLibrary.new();library.library_root=earned.path_join("library")
 var entry: Dictionary=library.discover()[0]
 if OS.get_environment("DUAL_RESTART")=="1":cold(entry);return
 var proof := WorldOriginLore.read_json(earned.path_join("proof.json"));var records := {}
 check(proof.earned_xp==640 and not proof.xp_injected,"actual completed ordinary campaign input")
 for cls in ["wizard","sorcerer","duskblade"]:
  var witness: Dictionary=proof.earned_entry_witnesses[cls]
  var state := WorldOriginLore.read_json(earned.path_join(witness.file));var id: String=witness.character_id
  check(RulesJson.digest(state)==witness.state_hash and not witness.class_assigned,"unchanged actual pre-entry witness "+cls)
  var driver: Node=load("res://tests/dual_prestige_acceptance/journey.gd").new();driver.source=RulesRecords.registry(state);driver.kernel=RulesCharacter.new(driver.source)
  var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new();planner.source=driver.source;planner.kernel=driver.kernel;driver.planner=planner
  driver.configure()
  var index: int=state.party_ids.find(id)
  check(driver.kernel.available_advancement(state.mechanics.records[id]).classes[witness.path].ok,"durable saved prerequisites remain eligible "+cls)
  for accept in [false,true]:
   var chosen: String=witness.path if accept else cls
   var planned: Dictionary=driver.planned(state.mechanics.records[id],chosen,index);check(planned.ok,"actual permanent accept/decline choice "+chosen)
   if not planned.ok:continue
   var choice: Dictionary=planned.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   var preview := CharacterBuilderRecords.preview_advancement(state,id,choice);check(preview.ok,"genuine earned XP funds explicit choice "+chosen)
   if not preview.ok:continue
   var name: String=cls+("-accept" if accept else "-decline")
   var store := GamePlaythroughStore.new();store.save_root=folder.path_join(name)
   check(store.save_new(state.playthrough_id,state,entry.world).ok,"sole writer forks original earned state")
   var builder := CharacterBuilderService.new();builder.store=store;builder.library=library
   var out := builder.operate(entry,state.playthrough_id,"builder_advance",index+1,{"character_id":id,"before_hash":preview.before_hash,"candidate_hash":preview.candidate_hash,"choice":preview.choice})
   check(out.ok,"actual writer commits chosen prestige or deliberate base continuation "+name+str(out.get("error","")))
   if not out.ok:continue
   var record: Dictionary=out.state.mechanics.records[id];var derived: Dictionary=driver.kernel.derive_character(record)
   check(derived.ok and record.advancement_history.size()==int(witness.next_level) and record.advancement_history.back().class_id==chosen,"ordered manual history "+name)
   check(CharacterBuilderRecords.xp(out.state,id)==int(witness.earned_xp) and int(derived.snapshot.class_levels.get(witness.path,0))==(1 if accept else 0),"no generated XP or automatic prestige "+name)
   records[name]={"slot":state.playthrough_id,"character_id":id,"chosen":chosen,"xp":witness.earned_xp,"state_hash":RulesJson.digest(out.state),"snapshot_hash":derived.snapshot.snapshot_hash}
  check(RulesJson.digest(state)==witness.state_hash,"entry forks never overwrite original witness")
  planner.free();driver.free()
 FileAccess.open(folder.path_join("entry-saved.json"),FileAccess.WRITE).store_string(JSON.stringify(records))
 finish()
func cold(entry: Dictionary) -> void:
 var records := WorldOriginLore.read_json(folder.path_join("entry-saved.json"))
 check(records.size()==6,"three actual earned characters each have accept and decline saves")
 for name in records:
  var row: Dictionary=records[name];var store := GamePlaythroughStore.new();store.save_root=folder.path_join(name)
  var loaded := store.load_save(row.slot,entry.world);check(loaded.ok,"real earned fork cold loads "+name)
  if not loaded.ok:continue
  var r: Dictionary=loaded.state.mechanics.records[row.character_id];var d := CharacterBuilderRecords.kernel(loaded.state).derive_character(r)
  check(d.ok and RulesJson.digest(loaded.state)==row.state_hash and d.snapshot.snapshot_hash==row.snapshot_hash,"exact state and derived snapshot after full process restart "+name)
  check(r.advancement_history.back().class_id==row.chosen and CharacterBuilderRecords.xp(loaded.state,row.character_id)==int(row.xp),"saved deliberate history and actual XP survive restart")
 finish(true)
func finish(restart := false) -> void:
 FileAccess.open(folder.path_join("entry-restart-proof.json" if restart else "entry-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Six actual earned pre-entry campaign forks; explicit manual prestige or base continuation through the existing builder writer, no XP injection"}))
 print("DUAL_PRESTIGE_ENTRY ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
