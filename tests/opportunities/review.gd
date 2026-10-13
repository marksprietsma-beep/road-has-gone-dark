extends "res://tests/map_icons/review.gd"
## Actual production New Game, generation, party, map, choices and combat controls.
var journeys: Array=[]
func run() -> void:
 SandboxAdventure.legacy_review=false;AdventureService.legacy_review=false
 base=OS.get_environment("GAME101_TEST_ROOT");DirAccess.make_dir_recursive_absolute(base)
 visual=DisplayServer.get_name()!="headless";tree.root.size=Vector2i(1280,720)
 if OS.get_environment("GAME101_RESTART")=="1":await restart();return
 proof={"platform":OS.get_name(),"visual":visual,"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"empty_path":OS.get_environment("PATH").is_empty()}
 tree.create_timer(850).timeout.connect(func():push_error("GAME101 review watchdog");tree.quit(1))
 var specs: Array=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("review-contexts.json")))
 for i in specs.size():await journey(specs[i],i)
 await existing_campaign()
 proof.journeys=journeys;proof.checks=checks;proof.failures=failures
 FileAccess.open(base.path_join("review-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print("GAME101 PRODUCTION REVIEW ",checks," / ",failures,"; six hometowns, two generated worlds and preserved V1")
 tree.quit(1 if failures else 0)
func journey(spec: Dictionary,index: int) -> void:
 print("GAME101 REVIEW hometown ",index," ",spec.home_name)
 tree.change_scene_to_file("res://scenes/ui/main_menu.tscn");await wait_scene("res://scenes/ui/main_menu.tscn")
 await click(ui.new_game_button);await wait_scene("res://scenes/ui/new_game_origin.tscn")
 ui.library.library_root=base.path_join("review/library");ui.store.save_root=base.path_join("review/saves");ui.library.save_root=ui.store.save_root
 ui._reload_library();ui.choose_world(0);ui.show_page()
 if index in [0,3]:
  ui.generation_button.pressed.disconnect(ui._start_generation)
  ui.generation_button.pressed.connect(func():ui._start_generation(spec.seed))
  await click(ui.generation_button)
  var deadline := Time.get_ticks_msec()+240000
  while ui.job_thread!=null and Time.get_ticks_msec()<deadline:await tree.process_frame
  check(ui.job_thread==null,"production generator completes offline")
 var entry_index := -1
 for i in ui.entries.size():
  if ui.entries[i].world.seed==spec.seed:entry_index=i;break
 check(entry_index>=0,"real generated world remains selectable")
 ui.choose_world(entry_index);ui.show_page()
 var home: Dictionary=ui.worlds[entry_index].get_record("burg",int(spec.home_id))
 var cell: Dictionary=ui.worlds[entry_index].get_record("cell",int(home.cell))
 await click(ui.next_button)
 ui.choose_state(int(cell.state));ui.choose_province(int(cell.province));ui.show_page()
 await click(ui.next_button)
 var home_index := -1
 for i in ui.candidates.size():
  if int(ui.candidates[i].id)==int(spec.home_id):home_index=i;break
 check(home_index>=0,"requested source hometown is genuinely offered")
 ui.choose_home(home_index);ui.show_page();await frames();await shot("home-%02d-origin"%index)
 await click(ui.next_button);await click(ui.next_button);await wait_scene("res://scenes/ui/party_creation.tscn")
 await review_content(index)
 for i in 3:
  var role: String=(["vanguard","scout","adept"] if index%2==0 else ["expert","vanguard","adept"])[i]
  ui.selected=i+1;ui.refresh();ui.pick(ui.role_picker,role);ui.recommend(role)
  await review_build(index,i)
  ui.detail_tabs.current_tab=0
  await click(ui.save_button);await wait_job()
  check(ui.state.character_builder.confirmed.has(ui.state.party_ids[i]),"actual creator confirms each distinct build")
 await review_creation(index)
 await click(ui.finish_button);await wait_job();await click(ui.finish_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 await click(ui.action_buttons.sandbox_begin);await wait_job()
 check(ui.state.sandbox.version==OpportunityGenerator.VERSION,"production defaults to V2")
 var identities: Dictionary=ui.state.party.duplicate(true);var immutable: String=ui.state.sandbox.base_sha
 var service: AdventureService=ui.service;var entry: Dictionary=ui.entry;var slot: String=ui.slot
 var paths: Array=[]
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  tree.root.size=resolution;await frames()
  check(ui.home_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"responsive expedition footer")
  await shot("home-%02d-opportunities-%dx%d"%[index,resolution.x,resolution.y])
 tree.root.size=Vector2i(1280,720);await frames()
 var preferred: Array=["recovery","investigation","contested"] if index in [0,3] else [["recovery"],["investigation"],["contested"],["investigation"]][[1,2,4,5].find(index)]
 for family in preferred:
  var candidates: Array=ui.state.sandbox.base.sites.filter(func(s: Dictionary):return OpportunityGenerator.template(s.activity_id).family==family and not ui.state.sandbox.results.has(s.id))
  check(not candidates.is_empty(),"available activity family "+family)
  var site: Dictionary=candidates[0]
  await click(ui.action_buttons[site.id]);await click(ui.action_buttons.sandbox_accept);await wait_job()
  if ui.action_buttons.has("sandbox_scout"):await click(ui.action_buttons.sandbox_scout);await wait_job()
  await click(ui.action_buttons.sandbox_travel);await wait_job()
  for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
   tree.root.size=resolution;await frames()
   check(ui.action_buttons.size()>=3,"choices remain keyboard-accessible in scrollable panel")
   await shot("home-%02d-%s-actions-%dx%d"%[index,family,resolution.x,resolution.y])
  tree.root.size=Vector2i(1280,720);await frames()
  var options := OpportunityGenerator.choices(ui.state,site)
  if family=="contested" and index==0:
   await click(ui.action_buttons.sandbox_fight);await wait_scene("res://scenes/combat/first_adventure.tscn")
   while ui.thread!=null or ui.is_presenting() or ui.presentation_active or engine.current(ui.battle()).team=="enemy":await tree.process_frame
   await shot("home-%02d-combat"%index);await play_fight();await shot("home-%02d-combat-result"%index)
   await click(ui.return_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
  else:
   var contributions := options.filter(func(o: Dictionary):return not o.participant.is_empty())
   var choice: String="negotiate" if family=="contested" else contributions[0].id if not contributions.is_empty() else "quick" if index%2 else "careful"
   ui.action_buttons["choice:"+choice].grab_focus();await frames();await shot("home-%02d-%s-selected-choice"%[index,family])
   await click(ui.action_buttons["choice:"+choice]);await wait_job()
   if family=="contested" and choice.begins_with("companion:"):
    check(ui.state.sandbox.active.phase=="site","contribution observes without resolving confrontation")
    await shot("home-%02d-companion-observation"%index)
    await click(ui.action_buttons["choice:leave"]);await wait_job()
   check(ui.state.sandbox.results[site.id].xp_each==0 and not ui.state.sandbox.encounters.has(site.id),"actual noncombat resolution grants no combat XP")
  await shot("home-%02d-%s-saved-result"%[index,family])
  paths.append(ui.state.sandbox.results[site.id])
  await click(ui.home_button);await wait_job();await shot("home-%02d-%s-returned"%[index,family])
  check(ui.state.sandbox.base_sha==immutable and ui.state.party==identities,"no reroll or replacement of saved companions")
 # Resume from the real menu after completing a journey, then verify saved bytes.
 var bytes := FileAccess.get_file_as_bytes(service.store._slot_path(slot));var saved := RulesJson.digest(ui.state.sandbox)
 await click(ui.menu_button);await wait_scene("res://scenes/ui/main_menu.tscn")
 ui.refresh_party_resume(service);await click(ui.menu_content.get_node("ResumePartyButton"));await wait_scene("res://scenes/gameplay/expedition.tscn")
 check(RulesJson.digest(ui.state.sandbox)==saved and FileAccess.get_file_as_bytes(service.store._slot_path(slot))==bytes,"saved outcome restored without duplicate cost/reward")
 await shot("home-%02d-resumed-outcomes"%index)
 journeys.append({"world_sha":entry.world.source_sha256,"seed":spec.seed,"home_id":ui.state.origin.home_burg_id,"home_name":spec.home_name,"biome":spec.biome,"base_sha":immutable,"party":identities.members.map(func(m: Dictionary):return {"id":m.character_id,"name":m.name,"role":m.role_id,"profession":m.generated_facts.occupation_id}),"paths":paths,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root,"slot":slot,"sandbox_sha":saved})
func restart() -> void:
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("review-proof.json")))
 var restored: Array=[]
 for index in saved.journeys.size():
  var journey: Dictionary=saved.journeys[index]
  var service := AdventureService.new();service.store.save_root=journey.save_root;service.library.library_root=journey.library_root;service.library.save_root=journey.save_root;service.cache_root=journey.cache_root
  var entries := service.library.discover().filter(func(e: Dictionary):return e.world.source_sha256==journey.world_sha)
  check(entries.size()==1,"fresh process retains exact generated source world")
  var path := service.store._slot_path(journey.slot);var bytes := FileAccess.get_file_as_bytes(path)
  PartyService.handoff={"entry":entries[0],"slot":journey.slot,"save_root":journey.save_root,"library_root":journey.library_root,"cache_root":journey.cache_root}
  tree.change_scene_to_file("res://scenes/gameplay/expedition.tscn");await wait_scene("res://scenes/gameplay/expedition.tscn")
  check(RulesJson.digest(ui.state.sandbox)==journey.sandbox_sha and FileAccess.get_file_as_bytes(path)==bytes,"fresh process restores exact costs, information, history, RNG and results")
  await shot("home-%02d-after-process-restart"%index)
  restored.append({"home_id":journey.home_id,"sandbox_sha":journey.sandbox_sha,"paths":ui.state.sandbox.results})
 FileAccess.open(base.path_join("restart-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"journeys":restored,"platform":OS.get_name(),"empty_path":OS.get_environment("PATH").is_empty(),"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty()},"  ")+"\n")
 print("GAME101 FRESH PROCESS ",checks," / ",failures);tree.quit(1 if failures else 0)

func review_creation(_index: int) -> void:
 pass

func review_content(_index: int) -> void:pass
func review_build(_index: int,_slot: int) -> void:pass
