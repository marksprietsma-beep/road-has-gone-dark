extends "res://tests/adventure/review-flow.gd"
## Mouse/keyboard drive the real production controllers; no alternate resolver.
var captured_move := false
func run() -> void:
 AdventureService.legacy_review=false
 base=OS.get_environment("ADVENTURE_REVIEW_ROOT")
 if base.is_empty(): base=ProjectSettings.globalize_path("user://first-adventure-review-proof")
 DirAccess.make_dir_recursive_absolute(base)
 visual=DisplayServer.get_name()!="headless"
 tree.root.size=Vector2i(1280,720)
 proof={"platform":OS.get_name(),"visual":visual,"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"empty_path":OS.get_environment("PATH").is_empty()}
 tree.change_scene_to_file("res://scenes/ui/main_menu.tscn");await wait_scene("res://scenes/ui/main_menu.tscn")
 await click(ui.new_game_button);await wait_scene("res://scenes/ui/new_game_origin.tscn")
 ui.library.library_root=base.path_join("library");ui.store.save_root=base.path_join("saves");ui.library.save_root=ui.store.save_root
 ui._reload_library();ui.choose_world(0);ui.show_page()
 check(ui.library.helper_status().ok,"compatible offline helper available")
 # Same generation controller and button, with a reproducible review seed.
 ui.generation_button.pressed.disconnect(ui._start_generation)
 ui.generation_button.pressed.connect(func():ui._start_generation("game96-sandbox-review-v1"))
 await click(ui.generation_button)
 var deadline := Time.get_ticks_msec()+240000
 while ui.job_thread!=null and Time.get_ticks_msec()<deadline: await tree.process_frame
 check(ui.job_thread==null and not ui.entries[ui.world_index].preset,"fresh world generated and selected")
 print("REVIEW: generated world selected")
 proof.world_sha=ui.entries[ui.world_index].world.source_sha256
 await shot("world-created")
 for i in 3: await click(ui.next_button)
 check(ui.page==2 and ui.burg_id>=0,"origin, region and hometown selected")
 if ui.candidates.size()>1:ui.choose_home(1);ui.show_page();await frames()
 await shot("hometown-choice")
 await click(ui.next_button) # Review origin
 await click(ui.next_button) # Confirm origin
 await wait_scene("res://scenes/ui/party_creation.tscn")
 # Explicit review composition, through the existing party editor service path.
 for i in 3:
  ui.selected=i+1;ui._start("edit",{"role_id":["vanguard","scout","adept"][i]});await wait_job()
 ui.selected=1;ui.refresh();await shot("party")
 var preview_recipes: Dictionary=ui.preview_recipes.duplicate(true)
 check(preview_recipes.size()==3,"all three saved identities have LPC party previews")
 for row in ui.roster.rows:check(row.get_child(0).get_child(0).texture!=null,"actual generated preview texture")
 if visual:
  for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
   tree.root.size=resolution;await frames()
   check(ui.roster.get_item_rect(2).end.y<=ui.roster.size.y,"all three party previews fit")
   check(ui.finish_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"party footer fits")
   await shot("party-%dx%d"%[resolution.x,resolution.y])
  tree.root.size=Vector2i(1280,720);await frames()
 await click(ui.finish_button);await wait_job()
 await click(ui.finish_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 await click(ui.action_buttons.sandbox_begin);await wait_job()
 check(ui.state.sandbox.base.sites.size()==4 and not ui.state.has("first_adventure"),"normal production has choices, no authored opening")
 var immutable: String=ui.state.sandbox.base_sha
 var entry: Dictionary=ui.entry;var slot: String=ui.slot;var service: AdventureService=ui.service
 proof.sandbox={"base_sha":immutable,"home":ui.state.origin.home_burg_id,"scenarios":[]}
 await shot("local-opportunities")
 for index in 3:
  var site: Dictionary=ui.state.sandbox.base.sites[index]
  await click(ui.action_buttons[site.id])
  if index==0:
   var saved_before := RulesJson.digest(ui.state)
   await key(KEY_ESCAPE);check(ui.selected.is_empty() and RulesJson.digest(ui.state)==saved_before,"keyboard leaves opportunity detail without changing campaign")
   await click(ui.action_buttons[site.id])
  await shot("opportunity-"+site.kind)
  await click(ui.action_buttons.sandbox_accept);await wait_job()
  if ui.action_buttons.has("sandbox_scout"):await click(ui.action_buttons.sandbox_scout);await wait_job()
  await click(ui.action_buttons.sandbox_travel);await wait_job();await shot("site-"+site.kind)
  await click(ui.action_buttons.sandbox_fight);await wait_scene("res://scenes/combat/first_adventure.tscn")
  while ui.thread!=null or ui.is_presenting() or ui.presentation_active or engine.current(ui.battle()).team=="enemy":await tree.process_frame
  var before := RulesJson.canonical(ui.battle())
  check(ui.pawns.size()==3+site.board.enemies.size(),"actual generated composition displayed")
  for id in preview_recipes:check(ui.pawns[id].recipe.recipe_hash==preview_recipes[id],"same persistent companion preview/appearance")
  for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
   tree.root.size=resolution;await frames();await frames()
   check(ui.grid.get_global_rect().end.x<=tree.root.get_visible_rect().size.x,"generated board width fits")
   check(ui.end_button.get_global_rect().end.y<=tree.root.get_visible_rect().size.y,"generated combat footer fits")
   check(ui.grid.get_global_rect().end.y<=ui.targeting.get_global_rect().position.y,"target hint below generated board")
   await shot("generated-%s-%dx%d"%[site.kind,resolution.x,resolution.y])
  check(RulesJson.canonical(ui.battle())==before,"resizing/rendering cannot consume tactical RNG")
  proof.sandbox.scenarios.append({"kind":site.kind,"site_id":site.id,"board":site.board,"initial_render_hash":ui.battle().state_hash})
  tree.root.size=Vector2i(1280,720);await frames()
  if index==0:
   var paused: String=ui.battle().state_hash
   await click(ui.menu_button);await wait_scene("res://scenes/ui/main_menu.tscn")
   ui.refresh_party_resume(service);await click(ui.menu_content.get_node("ResumePartyButton"));await wait_scene("res://scenes/combat/first_adventure.tscn")
   check(ui.battle().state_hash==paused and not ui.is_presenting(),"generated menu resume exact saved RNG/battle")
  if index==2:
   await click(ui.retreat_button);await wait_job()
   check(ui.battle().status=="defeat","actual generated withdrawal saved")
  else:
   await play_fight()
   check(ui.battle().status=="victory","generated encounter victory")
  await shot("result-"+site.kind)
  await click(ui.return_button);await wait_scene("res://scenes/gameplay/expedition.tscn");await shot("regional-result-"+site.kind)
  await click(ui.home_button);await wait_job()
  check(ui.state.sandbox.active.is_empty() and ui.state.sandbox.results.size()==index+1,"another opportunity can follow saved result")
  check(ui.state.sandbox.base_sha==immutable and service.store.load_save(slot,entry.world).ok,"generated content unchanged and durable")
  await shot("returned-home-"+site.kind)
 check(ui.state.sandbox.characters.values().all(func(c: Dictionary):return c.xp==20 and c.history.size()==3),"two wins plus withdrawal produce exactly one history/reward per site")
 proof.sandbox.results=ui.state.sandbox.results;proof.sandbox.party_ids=ui.state.party_ids
 finish()
func play_fight() -> void:
 var deadline := Time.get_ticks_msec()+360000
 while ui.battle().status=="active" and Time.get_ticks_msec()<deadline:
  if ui.thread!=null or ui.is_presenting() or ui.presentation_active or engine.current(ui.battle()).team=="enemy":await tree.process_frame;continue
  var b: Dictionary=ui.battle();var actor := engine.current(b)
  var mode := "spark" if engine.characters.derive_character(actor.record).snapshot.abilities.has("spark") else "attack"
  var target := ""
  if int(b.budget.main)>0:
   for id in b.order:
    if engine.eligible(b,actor,b.units[id],mode):target=id;break
  if not target.is_empty():
   await click(ui.action_buttons[mode]);await click(ui.tiles[str(b.units[target].position)]);await wait_job()
  else:
   var command := engine.enemy_command(b)
   if command.kind=="move":
    await click(ui.action_buttons.move);await click(ui.tiles[str(command.destination)])
    if visual and not captured_move:captured_move=true;await capture_effect("generated-move")
    await wait_job()
   else:await click(ui.end_button);await wait_job()
 check(ui.battle().status!="active","bounded rendered encounter completion")
