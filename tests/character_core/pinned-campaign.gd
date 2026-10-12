extends SceneTree
## Construct a private previous-core fixture from its installed immutable content,
## then exercise production load/sheets. No production migration/upgrade is invoked.
var checks := 0
var failures := 0
func check(ok: bool,why: String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func run():
 var base := OS.get_environment("GAME103_TEST_ROOT")
 var service := CharacterBuilderService.new();service.store.save_root=base.path_join("pinned-core/saves");service.library.library_root=base.path_join("library")
 var entry: Dictionary=service.library.discover()[0]
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"same canonical source profiles")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 var generated := service.generate_party_preview(entry,born.state)
 check(generated.ok,"original source-grounded party fixture")
 if not generated.ok:quit(1);return
 var old: RulesRegistry
 for row in RulesRecords.installed_packs():
  if row.rules_ref.pack_id=="trhgd-character-v4":old=RulesRecords.registry(row.rules_ref)
 var shadow: Dictionary=generated.candidate;shadow.party.status="ready";shadow.onboarding_stage="party_ready"
 var prepared := RulesRecords.preview_preparation(shadow,old.rules_ref())
 check(prepared.ok,"fixture mechanics come from the actual installed v4 pack")
 if not prepared.ok:quit(1);return
 var candidate: Dictionary=prepared.candidate
 candidate.party.schema_version=3;candidate.party.generator_version="player-party-2"
 for i in 3:
  var m: Dictionary=candidate.party.members[i]
  m.people_id=old.definition("ancestries",candidate.mechanics.records[m.character_id].ancestry_ref).people_id
  m.generated_facts.people_id=m.people_id;m.generated_facts.public_relationship.kind="party-companions"
  m.background_id=m.character_id+":background:"+JSON.stringify(["trhgd-party-1",candidate.party.content_pack_sha,int(m.background_variant),m.people_id,m.role_id]).sha256_text().left(20)
  for key in ["people_id","background_id"]:candidate.characters[i][key]=m[key]
 candidate.mechanics.source_party_sha=RulesJson.digest(candidate.party)
 candidate.character_builder={"version":1,"rules_ref":old.rules_ref(),"revision":4,"confirmed":candidate.party_ids.duplicate(),"drafts":{},"advancements":[],"policy_sha":FileAccess.get_sha256(CharacterBuilderRecords.CORE_POLICY),"initial_levels":{}}
 for id in candidate.party_ids:candidate.character_builder.initial_levels[id]=1
 # Match the exact serialized legacy fixture boundary, including StringName keys.
 candidate=JSON.parse_string(JSON.stringify(candidate))
 var saved := service.store.save_new(born.state.playthrough_id,candidate,entry.world)
 check(saved.ok,"previous-core fixture passes the real campaign writer: "+str(saved.get("error","")))
 if not saved.ok:quit(1);return
 var path := service.store._slot_path(born.state.playthrough_id);var bytes := FileAccess.get_file_as_bytes(path)
 var before := {}
 for id in candidate.party_ids:before[id]=RulesCharacter.new(old).derive_character(candidate.mechanics.records[id]).snapshot.snapshot_hash
 PartyService.handoff={"entry":entry,"slot":born.state.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root}
 change_scene_to_file("res://scenes/ui/party_creation.tscn")
 for frame in 10:await process_frame
 var ui: CharacterScreen=current_scene
 var deadline := Time.get_ticks_msec()+90000
 while ui.thread!=null and Time.get_ticks_msec()<deadline:await process_frame
 check(ui.thread==null and ui.ready_view,"previous-core campaign loads as ready, not a new creator")
 check(RulesJson.normalize(ui.state.mechanics.rules_ref)==RulesJson.normalize(old.rules_ref()),"v4 campaign retains its exact original pin")
 check(ui.people_picker.item_count==7 and ui.class_choice.item_count==11,"old campaign options do not silently gain new ancestries")
 check(FileAccess.get_file_as_bytes(path)==bytes,"opening the saved party does not write or upgrade it")
 for index in 3:
  ui.selected=index+1;ui.refresh()
  check(ui.name_edit.text==candidate.party.members[index].name and ui.statistics.text.contains(candidate.party.members[index].name),"saved identities survive sheet navigation")
  var id: String=candidate.party_ids[index]
  check(RulesCharacter.new(RulesRecords.registry(ui.state)).derive_character(ui.state.mechanics.records[id]).snapshot.snapshot_hash==before[id],"previous-core class mechanics remain identical")
 var reload := service.store.load_save(born.state.playthrough_id,entry.world)
 check(reload.ok and RulesJson.digest(reload.state)==RulesJson.digest(candidate),"subsequent campaign reload is exact")
 var output := OS.get_environment("GAME118_TEST_ROOT")
 if not output.is_empty():FileAccess.open(output.path_join("pinned-campaign-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":old.rules_ref()},"  "))
 print("GAME118 PINNED CAMPAIGN ",checks," / ",failures);quit(1 if failures else 0)
