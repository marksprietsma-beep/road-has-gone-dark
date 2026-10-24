extends "res://tests/hybrid_acceptance/journey.gd"
## Continue an unmodified, source-guarded earned save in the exported executable.
## The first1690XP remain explicitly source-Godot evidence;270 more are earned here.
var imported := {}
func journey_xp() -> int:return 1960
func journey_level() -> int:return 15
func journey_cycles() -> int:return 8
func run() -> void:
 if OS.get_environment("GAME126_AUDIT_RESTART")!="1":
  var original_root := OS.get_environment("HYBRID_IMPORTED_EARNED").path_join("journeys/cohort-0")
  var proof := WorldOriginLore.read_json(original_root.path_join("proof.json"))
  check(not proof.is_empty() and int(proof.get("earned_xp",0))==1690 and proof.get("xp_injected",true)==false,"actual successful1690XP input, no fixture XP")
  if failures:finish_journey();return
  base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-0");DirAccess.make_dir_recursive_absolute(base)
  service.library.library_root=base.path_join("library");service.cache_root=base.path_join("cache")
  entry=service.library.discover()[0];slot=proof.slot
  var original := GamePlaythroughStore.new();original.save_root=original_root.path_join("saves")
  var loaded := original.load_save(slot,entry.world)
  check(loaded.ok,"exported native loads original exact-pinned earned campaign "+str(loaded.get("error","")))
  if not loaded.ok:finish_journey();return
  check(RulesJson.digest(loaded.state)==proof.state_hash,"imported complete campaign hash exact")
  service.store.save_root=base.path_join("saves");service.library.save_root=service.store.save_root
  check(service.store.save_new(slot,loaded.state,entry.world).ok,"native continuation fork uses the sole production writer without record edits")
  var histories := {}
  for id in loaded.state.party_ids:
   check(CharacterBuilderRecords.xp(loaded.state,id)==1690 and loaded.state.mechanics.records[id].advancement_history.size()==14,"unmodified actual input XP/history "+id)
   histories[id]=loaded.state.mechanics.records[id].advancement_history.duplicate(true)
  imported={"original_state_hash":proof.state_hash,"original_earned_xp":1690,"original_histories":histories,"source_run":OS.get_environment("HYBRID_EARNED_RUN"),"source_commit":OS.get_environment("HYBRID_EARNED_SOURCE")}
  entry_witnesses=proof.earned_entry_witnesses.duplicate(true)
  FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 super.run()
func prepare(index: int) -> void:
 # The inherited resume loop initialises its generic cohort before this hook.
 configs=[["duskblade","human",""],["wizard","human","archmage"],["sorcerer","human","archmage"]]
 super.prepare(index)
func checkpoint() -> void:
 super.checkpoint()
 var proof := WorldOriginLore.read_json(base.path_join("proof.json"))
 proof.source_import=imported
 proof.native_earned_xp=CharacterBuilderRecords.xp(state,state.party_ids[0])-1690
 for id in state.party_ids:
  check(state.mechanics.records[id].advancement_history.slice(0,14)==imported.original_histories[id],"native advancement never rewrites the source earned history")
 proof.checks=checks;proof.failures=failures
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
func test_known_authority() -> void:
 for index in [1,2]:
  var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
  check(kernel.derive_character(record).snapshot.class_levels.get("archmage",0)==2,"additional270 native XP deliberately funds Archmage2")
  var proposed := kernel.suggested_choice(record,"archmage")
  check(proposed.ok and kernel.preview_advancement(record,proposed.choice).ok,"further path meets permanent rules")
  if proposed.ok:check(not CharacterBuilderRecords.preview_advancement(state,id,proposed.choice).ok,"native selector cannot fund total16 with1960XP")
 var id: String=state.party_ids[2]
 var builder := CharacterBuilderService.new();builder.store=service.store;builder.library=service.library
 var before := FileAccess.get_file_as_string(service.store._slot_path(slot))
 var rejected := builder.operate(entry,slot,"builder_spells",3,{"before_hash":RulesJson.digest(state),"character_id":id,"spells":[],"preparations":{}})
 check(not rejected.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==before,"native writer preserves all permanent Sorcerer knowledge")
func test_real_combat() -> void:
 if cycle().results.size()==4:action("cycle_seek")
 var unfinished := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):unfinished=i;break
 check(unfinished>=0,"real unresolved opportunity for native home recovery")
 if unfinished<0:return
 travel(unfinished);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==1960 and state.mechanics.records[id].advancement_history.size()==15,"1690 source XP plus270 native-earned XP, no injection or earned20 claim")
