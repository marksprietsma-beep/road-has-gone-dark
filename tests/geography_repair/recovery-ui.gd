extends "res://tests/sandbox/review-flow.gd"
## Resume a genuine old-version blocked save via production menu/controllers.
func run() -> void:
 AdventureService.legacy_review=false
 base=OS.get_environment("ADVENTURE_REVIEW_ROOT");DirAccess.make_dir_recursive_absolute(base)
 var campaign_root := OS.get_environment("GAME99_OLD_CAMPAIGN")
 var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(campaign_root.path_join("checkpoint.json")))
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(campaign_root.path_join("old-save.json")))
 visual=DisplayServer.get_name()!="headless";tree.root.size=Vector2i(1280,720)
 proof={"platform":OS.get_name(),"visual":visual,"empty_path":OS.get_environment("PATH").is_empty(),"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty()}
 var service := AdventureService.new();service.store.save_root=campaign_root.path_join("saves");service.library.library_root=campaign_root.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=campaign_root.path_join("cache")
 tree.change_scene_to_file("res://scenes/ui/main_menu.tscn");await wait_scene("res://scenes/ui/main_menu.tscn")
 ui.refresh_party_resume(service);await frames()
 check(not ui.party_resume.is_empty() and ui.party_resume.slot==metadata.slot,"menu finds old preserved campaign")
 await click(ui.menu_content.get_node("ResumePartyButton"));await wait_scene("res://scenes/gameplay/expedition.tscn")
 check(ui.entry.world.source_sha256==metadata.world_sha and ui.state.origin.home_burg_id==metadata.home,"same formerly failing world and home")
 check(RulesJson.digest(ui.state.party)==RulesJson.digest(old.party) and ui.state.party_ids==metadata.party_ids,"same original people and builds")
 await shot("recovered-local-region")
 await click(ui.action_buttons.sandbox_begin);await wait_job();await shot("recovered-opportunities")
 var immutable: String=ui.state.sandbox.base_sha;var site: Dictionary=ui.state.sandbox.base.sites[0]
 await click(ui.action_buttons[site.id]);await click(ui.action_buttons.sandbox_accept);await wait_job()
 if ui.action_buttons.has("sandbox_scout"):await click(ui.action_buttons.sandbox_scout);await wait_job()
 await click(ui.action_buttons.sandbox_travel);await wait_job();await click(ui.action_buttons.sandbox_fight);await wait_scene("res://scenes/combat/first_adventure.tscn")
 while ui.thread!=null or ui.is_presenting() or ui.presentation_active or engine.current(ui.battle()).team=="enemy":await tree.process_frame
 await shot("recovered-combat");var paused: String=ui.battle().state_hash
 await click(ui.menu_button);await wait_scene("res://scenes/ui/main_menu.tscn")
 ui.refresh_party_resume(service);await click(ui.menu_content.get_node("ResumePartyButton"));await wait_scene("res://scenes/combat/first_adventure.tscn")
 check(ui.battle().state_hash==paused,"old campaign resumes exact new battle")
 await play_fight();check(ui.battle().status=="victory","recovered campaign resolves combat");await shot("recovered-victory")
 await click(ui.return_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 await click(ui.home_button);await wait_job();await shot("recovered-returned-home")
 check(ui.state.sandbox.base_sha==immutable and ui.state.sandbox.results.size()==1,"no opportunity reroll, one result")
 check(ui.state.sandbox.characters.values().all(func(c: Dictionary):return c.xp==10 and c.history.size()==1),"one history and reward per original adventurer")
 check(RulesJson.digest(ui.state.party)==RulesJson.digest(old.party),"identity/build preserved after return")
 var bytes := FileAccess.get_file_as_string(service.store._slot_path(metadata.slot));check(service.operate(ui.entry,metadata.slot,"resume").ok and FileAccess.get_file_as_string(service.store._slot_path(metadata.slot))==bytes,"return and reload remain idempotent")
 proof.recovery={"world_sha":metadata.world_sha,"slot":metadata.slot,"home":metadata.home,"party_ids":metadata.party_ids,"base_sha":immutable,"results":ui.state.sandbox.results}
 finish()
