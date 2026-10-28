extends "res://tests/nature_repertoires/journey_driver.gd"
## Sanitized fresh campaign, original builder/save/AdventureService and real UI.
var measurements := []
var fixture_helper: Node
func goals_for(_index: int) -> Dictionary:return {"nodes":[],"feats":[]}
func creation_attributes(index: int,_goals: Dictionary) -> Dictionary:
 return [{"STR":8,"DEX":15,"CON":13,"INT":12,"WIS":10,"CHA":14},{"STR":15,"DEX":8,"CON":13,"INT":14,"WIS":12,"CHA":10},{"STR":10,"DEX":13,"CON":12,"INT":14,"WIS":15,"CHA":8}][index]
func planned(record: Dictionary,cls: String,_index: int) -> Dictionary:
 var proposal := kernel.suggested_choice(record,cls,"steady-study")
 if not proposal.ok:return proposal
 if cls=="druid":proposal.choice.specialisations["druid-companion"]="wolf"
 return kernel.preview_advancement(record,proposal.choice)
func spell_selection(record: Dictionary) -> Dictionary:
 var cls: String=record.advancement_history[0].class_id
 return {"spells":["druid-summon-sentinel"],"preparations":{"druid-summon-sentinel":1}}if cls=="druid"else{"spells":["sorcerer-arcane-bolt"],"preparations":{}}if cls=="sorcerer"else{"spells":[],"preparations":{}}
func pause_frames(n := 4) -> void:
 for i in n:await get_tree().process_frame
func idle(ui: Control,presentation := true) -> void:
 var deadline := Time.get_ticks_msec()+30000
 while ui.thread!=null or presentation and (ui.is_presenting()or ui.presentation_active):
  if Time.get_ticks_msec()>deadline:check(false,"production save/presentation completes within30seconds");return
  await get_tree().process_frame
 await pause_frames()
func visible_rect(control: Control) -> Rect2:
 var rect := control.get_global_rect().intersection(get_viewport().get_visible_rect());var parent := control.get_parent()
 while parent!=null:
  if parent is Control and (parent as Control).clip_contents:rect=rect.intersection((parent as Control).get_global_rect())
  parent=parent.get_parent()
 return rect
func press(control: Control,whole := false) -> void:
 check(control.is_visible_in_tree()and not control.get("disabled"),"actual requested control is enabled and visible")
 control.grab_focus();await pause_frames()
 var rect := visible_rect(control)
 check(rect.size.x>1 and rect.size.y>1,"genuine click has a nonempty on-screen hitbox")
 if whole:check(get_viewport().get_visible_rect().encloses(control.get_global_rect()),"entire essential footer control lies on screen")
 if rect.size.x<=1 or rect.size.y<=1:return
 var motion := InputEventMouseMotion.new();motion.position=rect.get_center();get_viewport().push_input(motion,true);await get_tree().process_frame
 for down in [true,false]:
  var event := InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=rect.get_center();get_viewport().push_input(event,true);await get_tree().process_frame
func image(ui: Control,label: String) -> void:
 var pixels := get_viewport().get_texture().get_image();var file := label+"-%dx%d.png"%[pixels.get_width(),pixels.get_height()];pixels.save_png(base.path_join(file))
 measurements.append({"file":file,"sha256":FileAccess.get_sha256(base.path_join(file)),"width":pixels.get_width(),"height":pixels.get_height(),"viewport":str(get_viewport().get_visible_rect()),"end":str(ui.end_button.get_global_rect()),"withdraw":str(ui.retreat_button.get_global_rect()),"end_enabled":not ui.end_button.disabled,"presenting":ui.is_presenting(),"actor":ui.engine.current(ui.battle()).id,"battle_hash":ui.battle().state_hash})
func open_ui() -> Control:
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 var ui: Control=load("res://scenes/combat/first_adventure.tscn").instantiate();get_tree().root.add_child(ui);await idle(ui);return ui
func seed_battle() -> Dictionary:
 var b: Dictionary=TacticalAuras.new(state).create(state,state.expedition.active.site_id,CombatBattlefields.LEGACY)
 var ids: Array=state.party_ids;var wolf := RulesEntities.identity(ids[2]);b.order=[ids[0],wolf,ids[2],ids[1],"bandit-blade","bandit-bow"];b.cursor=0;b=TacticalAuras.new(state).seal(b)
 var engine := TacticalAuras.new(state)
 b=fixture_helper.command(engine,b,"move","",[2,2]);b=fixture_helper.command(engine,b,"sorcerer-arcane-bolt","bandit-blade");b=fixture_helper.command(engine,b,"end")
 b=fixture_helper.command(engine,b,"move","",[0,4]);b=fixture_helper.command(engine,b,"end");b=fixture_helper.command(engine,b,"move","",[2,3])
 check(fixture_helper.failures==0 and b.revision==6 and engine.current(b).id==ids[2]and b.budget=={"main":1,"move":0},"six actual sanitized precursor commands; no private save/seed claim")
 return b
func run() -> void:
 base=OS.get_environment("SENTINEL_ROOT").path_join("campaign");DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache");entry=service.library.discover()[0]
 source=RulesRecords.new_character_registry();kernel=RulesCharacter.new(source)
 if OS.get_environment("SENTINEL_RESTART")=="1":await cold_campaign();return
 configs=[["sorcerer","human",""],["knight","human",""],["druid","ogre",""]];create_party()
 if failures:finish_test();return
 action("prepare_adventure");var lead: Dictionary=state.expedition.leads[0];action("accept",{"lead":lead.id});action("depart",{"lead":lead.id})
 if state.expedition.knowledge[lead.site_id]=="rumoured":action("scout")
 action("travel");action("begin_battle")
 fixture_helper=load("res://tests/sentinel_turn/probe.gd").new();fixture_helper.source=source;fixture_helper.kernel=kernel
 state.first_adventure.battle=seed_battle();var baseline := state.duplicate(true);var checkpoint := {}
 for dimensions in [Vector2i(640,360),Vector2i(1280,720),Vector2i.ZERO]:
  if dimensions==Vector2i.ZERO:get_window().mode=Window.MODE_FULLSCREEN
  else:get_window().mode=Window.MODE_WINDOWED;get_window().size=dimensions
  await pause_frames()
  check(service.store.save_existing(slot,baseline,entry.world).ok,"sanitized diagnostic state uses sole validated campaign writer")
  var ui: Control=await open_ui();check(ui.battle().revision==6,"production resume loads existing v33 caster state exactly")
  # Ordinary unsummoned turn still ends through the same real primary control.
  var initial: Dictionary=ui.battle().duplicate(true);await press(ui.end_button,true);await idle(ui)
  check(ui.battle().commands.back().kind=="end"and ui.battle().revision==7,"ordinary unsummoned End Turn uses production save/command path")
  ui.queue_free();await pause_frames();check(service.store.save_existing(slot,baseline,entry.world).ok,"reset independent sanitized case through authority")
  ui=await open_ui();await press(ui.action_buttons["druid-summon-sentinel"]);await idle(ui,false)
  if ui.is_presenting():
   check(ui.end_button.disabled and ui.retreat_button.disabled,"both controls gate during actual summon presentation")
  await idle(ui);var b: Dictionary=ui.battle();var summon: String=b.order[3]
  check(b.revision==7 and b.cursor==2 and b.budget=={"main":0,"move":0}and b.units[summon].entity.remaining==3,"real mouse cast commits exact reported exhausted state")
  check(ui.engine.alive(b.units[RulesEntities.identity(state.party_ids[2])])and ui.engine.alive(b.units[summon]),"permanent Wolf and temporary Sentinel coexist")
  check(not ui.end_button.disabled and not ui.retreat_button.disabled,"presentation ends and zero budgets cannot disable End")
  image(ui,"post-summon-"+("fullscreen"if dimensions==Vector2i.ZERO else str(dimensions.x)))
  var expected: Dictionary=ui.engine.command(b,{"actor_id":state.party_ids[2],"revision":7,"kind":"end"})
  await press(ui.end_button,true);await idle(ui)
  check(ui.battle().state_hash==expected.battle.state_hash and ui.engine.current(ui.battle()).id==summon,"real End click persists exact command and advances to scheduled Sentinel")
  image(ui,"sentinel-turn-"+("fullscreen"if dimensions==Vector2i.ZERO else str(dimensions.x)))
  if dimensions==Vector2i(1280,720):
   var fork := GamePlaythroughStore.new();fork.save_root=base.path_join("cold-saves");check(fork.save_new(slot,ui.state,entry.world).ok,"mid-summon cold fixture uses original writer")
   var next: Dictionary={"actor_id":summon,"revision":ui.battle().revision,"kind":"end"};var predicted: Dictionary=ui.engine.command(ui.battle(),next)
   checkpoint={"slot":slot,"state_hash":RulesJson.digest(ui.state),"battle_hash":ui.battle().state_hash,"next_command":next,"next_hash":predicted.battle.state_hash,"rules_ref":source.rules_ref()}
  # Actual owned actor's production movement button and authoritative tile.
  b=ui.battle();var current: Dictionary=ui.engine.current(b);var paths: Dictionary=ui.engine.paths(b,current);var destinations := []
  for path in paths.values():
   if path.size()>1:destinations.append(path.back())
  destinations.sort_custom(func(a: Array,c: Array):return ui.engine.distance(a,b.units["bandit-blade"].position)<ui.engine.distance(c,b.units["bandit-blade"].position))
  check(not destinations.is_empty(),"new Sentinel has legal movement")
  if not destinations.is_empty():
   await press(ui.action_buttons.move);await press(ui.tiles[str(destinations[0])]);await idle(ui)
   check(ui.battle().commands.back().kind=="move"and ui.engine.current(ui.battle()).id==summon,"Sentinel executes a real owned movement action")
  await press(ui.end_button,true);await idle(ui)
  check(ui.engine.current(ui.battle()).id==state.party_ids[1],"remaining Knight receives normal activation")
  await press(ui.end_button,true);await idle(ui)
  var deadline := Time.get_ticks_msec()+30000
  while ui.battle().status=="active"and ui.engine.current(ui.battle()).team=="enemy":
   if Time.get_ticks_msec()>deadline:check(false,"deterministic enemy turns finish");break
   await get_tree().process_frame
  await idle(ui)
  check(ui.battle().commands.any(func(c: Dictionary):return c.actor_id.begins_with("bandit-"))and ui.engine.current(ui.battle()).team=="party","normal deterministic enemy and subsequent party turns proceed")
  check(not ui.battle().commands.any(func(c: Dictionary):return c.kind=="retreat")and ui.battle().reason!="retreat","successful summon never requires or invents retreat")
  state=ui.state;ui.queue_free();await pause_frames()
 # Independent pure-authority all-pass duration fixture: no enemy damage or
 # owner death can be mistaken for three-boundary expiry. Not an AI battle.
 var timeline: Dictionary=fixture_helper.command(TacticalAuras.new(baseline),baseline.first_adventure.battle,"druid-summon-sentinel",state.party_ids[2]);var engine := TacticalAuras.new(baseline);var summoned: String=timeline.order[3];var rounds := []
 for i in 40:
  if not timeline.units[summoned].entity.active:break
  var old_round: int=timeline.round;timeline=fixture_helper.command(engine,timeline,"end")
  if timeline.round!=old_round:rounds.append(timeline.units[summoned].entity.remaining)
 check(rounds==[2,1,0]and not timeline.units[summoned].entity.active and timeline.units[summoned].record.runtime.hp>0,"live Sentinel expires at exactly its three original global boundaries")
 check(fixture_helper.failures==0,"all controlled timeline commands legal");fixture_helper.free()
 checkpoint.checks=checks;checkpoint.failures=failures;checkpoint.measurements=measurements;checkpoint.expiry=rounds;checkpoint.private_save_used=false
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(checkpoint));finish_test()
func cold_campaign() -> void:
 var p: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));slot=p.slot;service.store.save_root=base.path_join("cold-saves");service.library.save_root=service.store.save_root
 var ui: Control=await open_ui();check(RulesJson.digest(ui.state)==p.state_hash and ui.battle().state_hash==p.battle_hash,"exact complete v33 campaign and active summon survive independent process")
 check(ui.engine.registry.rules_ref()==p.rules_ref,"original33 rules pin remains exact")
 await press(ui.end_button,true);await idle(ui);check(ui.battle().state_hash==p.next_hash and ui.battle().commands.back().kind=="end","cold real mouse End matches predicted log/resources/RNG and advances normally")
 # Retreat remains possible only as a separate explicit player's request.
 await press(ui.retreat_button,true);await idle(ui)
 check(ui.battle().status=="defeat"and ui.battle().reason=="retreat"and ui.battle().commands.back().kind=="retreat","only deliberately clicked Withdraw commits retreat")
 ui.queue_free();await pause_frames();FileAccess.open(base.path_join("restart-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"exact_cold":true,"rules_ref":source.rules_ref(),"private_save_used":false}));finish_test()
func finish_test() -> void:
 print("GAME165_CAMPAIGN ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
