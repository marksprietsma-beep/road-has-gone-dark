extends Control
var service := AdventureService.new()
var engine := TacticalCombat.new()
var entry := {}
var slot := ""
var state := {}
var mode := "attack"
var thread: Thread
var message := "Loading saved encounter…"
var ai_delay := 0.0
var actor_id := ""
var targeting: Label
var title: Label
var status: Label
var turn_label: Label
var detail: Label
var log_label: Label
var grid: GridContainer
var actions: VBoxContainer
var end_button: Button
var return_button: Button
var retreat_button: Button
var menu_button: Button
var action_buttons := {}
var tiles := {}
var pawns := {}
var art_style := CombatArt.preferred()
var art_note: Label
var board_column: VBoxContainer
var tile_side := 34.0
var presentation_until := 0
var presentation_active := false
var presentation_actor := ""
var presentation_kind := ""

func _ready() -> void:
 GameUI.install(self)
 var background := ColorRect.new();background.color=Color("090c0c")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
 var margin := MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
 add_child(margin)
 var column := VBoxContainer.new();column.add_theme_constant_override("separation",4);margin.add_child(column)
 var heading := HBoxContainer.new();column.add_child(heading)
 title=GameUI.label("Bandits on the Old Road",18);title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
 var art_label := GameUI.label("Universal LPC",12);art_label.autowrap_mode=TextServer.AUTOWRAP_OFF;heading.add_child(art_label)
 var credits := GameUI.action("Art credits",show_art_credits);credits.add_theme_font_size_override("font_size",12);heading.add_child(credits)
 resized.connect(layout_board)
 status=GameUI.label(message,GameUI.META);column.add_child(status)
 turn_label=GameUI.label("",GameUI.META);turn_label.autowrap_mode=TextServer.AUTOWRAP_OFF;turn_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;column.add_child(turn_label)
 var body := HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(body)
 board_column=VBoxContainer.new();board_column.add_theme_constant_override("separation",4);body.add_child(board_column)
 grid=GridContainer.new();grid.columns=8;grid.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;grid.add_theme_constant_override("h_separation",0);grid.add_theme_constant_override("v_separation",0);board_column.add_child(grid)
 board_column.add_child(GameUI.label("◆ Party · × Opponents · Gold: turn",10))
 targeting=GameUI.label("",GameUI.META);targeting.custom_minimum_size=Vector2(302,22);targeting.max_lines_visible=1;targeting.clip_text=true;board_column.add_child(targeting)
 var scroll := ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(scroll)
 var side := VBoxContainer.new();side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;side.add_theme_constant_override("separation",4);scroll.add_child(side)
 detail=GameUI.label("",GameUI.META);side.add_child(detail)
 actions=VBoxContainer.new();actions.add_theme_constant_override("separation",4);side.add_child(actions)
 log_label=GameUI.label("",GameUI.META);side.add_child(log_label)
 var footer := HBoxContainer.new();column.add_child(footer)
 menu_button=GameUI.action("Main menu",func(): if thread==null: get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"));footer.add_child(menu_button)
 retreat_button=GameUI.action("Withdraw · defeat",func(): send("retreat"));footer.add_child(retreat_button)
 footer.add_child(GameUI.spacer())
 end_button=GameUI.action("End turn",func(): send("end"),true);footer.add_child(end_button)
 return_button=GameUI.action("Return to regional play",return_region,true);footer.add_child(return_button)
 art_note=GameUI.label("",10);side.add_child(art_note)
 layout_board()
 var handoff := PartyService.handoff
 entry=handoff.get("entry",{});slot=handoff.get("slot","")
 service.store.save_root=handoff.get("save_root",service.store.save_root)
 service.library.library_root=handoff.get("library_root",service.library.library_root)
 service.cache_root=handoff.get("cache_root",service.cache_root)
 if entry.is_empty() or slot.is_empty(): message="No campaign selected. Return to the main menu.";refresh()
 else: operate("resume")

func battle() -> Dictionary: return AdventureService.active_battle(state)
func is_presenting() -> bool:return Time.get_ticks_msec()<presentation_until
func operate(operation: String,command_input: Dictionary={}) -> void:
 if thread!=null: return
 var changes := {"revision":state.get("expedition",{}).get("revision",-1),"command":command_input}
 thread=Thread.new();thread.start(func():return service.operate(entry,slot,operation,1,changes))
 message="Saving…";refresh()
func send(kind: String,target: String="",destination: Array=[]) -> void:
 var b := battle()
 if b.is_empty() or b.status!="active" or engine.current(b).team!="party" or thread!=null or is_presenting(): return
 var input := {"revision":b.revision,"actor_id":engine.current(b).id,"kind":kind}
 if not target.is_empty(): input.target_id=target
 if not destination.is_empty(): input.destination=destination
 operate("sandbox_command" if state.has("sandbox") and not state.sandbox.active.is_empty() else "battle_command",input)
func _process(delta: float) -> void:
 if thread!=null:
  if thread.is_alive(): return
  var result: Dictionary=thread.wait_to_finish();thread=null
  var previous := battle().duplicate(true)
  if result.get("ok",false):
   state=result.state;message="";ai_delay=CombatPacing.AI_PAUSE_SECONDS
   start_presentation(previous)
   if not battle().is_empty() and engine.current(battle()).id!=actor_id:
    actor_id=engine.current(battle()).id;mode="attack"
  else: message=str(result.get("error","The previous save was preserved."))
  refresh()
  if result.get("ok",false): animate_committed(previous)
 if is_presenting():return
 if presentation_active:
  presentation_active=false;presentation_until=0
  # The committed board already exists. Unlock it without replacing focused
  # buttons or cancelling the pawn's final recovery frame.
  for button in action_buttons.values()+tiles.values()+[end_button,retreat_button,return_button]:
   button.disabled=bool(button.get_meta("ready_disabled",true))
  var ready_battle := battle()
  var playing: bool=ready_battle.status=="active"
  status.text="Saved · Round %d · %s's turn"%[ready_battle.round,engine.current(ready_battle).name] if playing else "Saved · "+ready_battle.status.capitalize()
  targeting.text=("Choose a dotted tile." if mode=="move" else "Choose a highlighted target.") if playing else "Encounter complete · return to the region."
 var b := battle()
 if not b.is_empty() and b.status=="active" and engine.current(b).team=="enemy" and message.is_empty():
  ai_delay-=delta
  if ai_delay<=0: operate("sandbox_command" if state.has("sandbox") and not state.sandbox.active.is_empty() else "battle_command",engine.enemy_command(b))
func choose_tile(p: Array) -> void:
 var b := battle()
 if b.is_empty() or b.status!="active": return
 if mode=="move": send("move","",p)
 else:
  var id := engine.occupant(b,p)
  if not id.is_empty(): send(mode,id)
func select_mode(value: String) -> void:
 mode=value;message="";refresh()
func add_action(id: String,text: String) -> void:
 var button := GameUI.action(text,func():select_mode(id),mode==id)
 button.disabled=thread!=null or engine.current(battle()).team!="party" or int(battle().budget.move if id=="move" else battle().budget.main)<1
 if id in ["slow","healing-thread"]: button.disabled=button.disabled or int(engine.current(battle()).record.runtime.resources.get("focus",0))<1
 gate_button(button)
 button.tooltip_text=text
 actions.add_child(button);action_buttons[id]=button
func gate_button(button: Button) -> void:
 button.set_meta("ready_disabled",button.disabled)
 button.disabled=button.disabled or is_presenting()
func refresh() -> void:
 var retained: Dictionary=pawns.duplicate()
 for pawn in retained.values():
  if is_instance_valid(pawn) and pawn.get_parent()!=null:pawn.get_parent().remove_child(pawn)
 for child in grid.get_children(): grid.remove_child(child);child.queue_free()
 for child in actions.get_children(): actions.remove_child(child);child.queue_free()
 tiles={};pawns={};action_buttons={}
 var b := battle()
 grid.columns=int(b.get("board",{}).get("width",8))
 layout_board()
 var art := BattlefieldArt.profile(b) if not b.is_empty() else {}
 var playing: bool=not b.is_empty() and b.status=="active"
 end_button.visible=playing;retreat_button.visible=playing;return_button.visible=not playing and not b.is_empty()
 menu_button.disabled=thread!=null
 end_button.disabled=thread!=null or not playing or engine.current(b).team!="party"
 retreat_button.disabled=end_button.disabled;return_button.disabled=thread!=null
 for button in [end_button,retreat_button,return_button]:gate_button(button)
 if b.is_empty(): status.text=message;return
 var actor := engine.current(b)
 title.text=b.board.title
 status.text=message if not message.is_empty() else ("Saved · Round %d · %s's turn"%[b.round,actor.name] if playing else "Saved · "+b.status.capitalize())
 if is_presenting():status.text="Saved · %s · %s"%[presentation_actor,presentation_kind.capitalize()]
 turn_label.text="Order: "+" → ".join(b.order.filter(func(id: String):return engine.alive(b.units[id])).map(func(id: String):return b.units[id].name))
 turn_label.tooltip_text=turn_label.text
 targeting.text="Choose a dotted tile." if mode=="move" else "Choose a highlighted target."
 if not playing: targeting.text="Encounter complete · return to the region."
 if is_presenting():targeting.text="Watching "+presentation_actor+" · "+presentation_kind.capitalize()
 var reachable := engine.paths(b,actor) if playing and mode=="move" and int(b.budget.move)>0 else {}
 for y in int(b.board.height):
  for x in int(b.board.width):
   var p := [x,y];var id := engine.occupant(b,p)
   if id.is_empty():
    for candidate in b.order:
     if b.units[candidate].position==p and not engine.alive(b.units[candidate]): id=candidate;break
   var button := BattlefieldTile.new();button.custom_minimum_size=Vector2(tile_side,tile_side);button.add_theme_font_size_override("font_size",10)
   var cell := BattlefieldArt.cell(art,p)
   button.ground=cell.ground;button.feature=cell.feature;button.coordinates=Vector2i(x,y)
   button.terrain_blocked=b.board.blocked.has(p)
   if button.terrain_blocked:button.disabled=true;button.tooltip_text="Blocked · "+(cell.feature.capitalize() if not cell.feature.is_empty() else "Obstacle")
   elif not id.is_empty():
    var u: Dictionary=b.units[id]
    button.faction=u.team
    var member := {}
    for candidate in state.party.members:
     if candidate.character_id==id: member=candidate;break
    var recipe := CombatArt.recipe(art_style,u,member)
    var pawn: CombatPawn=retained[id] if retained.has(id) else CombatPawn.new();button.add_child(pawn)
    var badge: String=str(state.party_ids.find(id)+1) if u.team=="party" else "A" if u.weapon=="bow" else "B"
    pawn.present(u,recipe,actor.id==id and playing,int(engine.stats(u).HP),badge)
    pawns[id]=pawn
    button.tooltip_text="%s · %d / %d HP · %s"%[u.name,u.record.runtime.hp,engine.stats(u).HP,u.weapon]
    if not recipe.warnings.is_empty(): button.tooltip_text+=" · "+"; ".join(recipe.warnings)
   var valid_target: bool=playing and not id.is_empty() and mode!="move" and engine.eligible(b,actor,b.units[id],mode)
   var valid_move: bool=playing and mode=="move" and reachable.has(str(p)) and actor.position!=p
   button.active_tile=actor.position==p and playing;button.target_tile=valid_target;button.move_tile=valid_move
   var style := GameUI.box(Color.TRANSPARENT)
   style.content_margin_top=1;style.content_margin_bottom=1;style.content_margin_left=2;style.content_margin_right=2
   for variation in ["normal","hover","pressed","disabled"]:button.add_theme_stylebox_override(variation,style)
   button.disabled=button.disabled or thread!=null or not playing or actor.team!="party"
   gate_button(button)
   if not valid_target and not valid_move: button.mouse_default_cursor_shape=Control.CURSOR_ARROW
   else: button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
   if button.disabled: button.add_theme_stylebox_override("disabled",style)
   button.mouse_entered.connect(func():
    if not id.is_empty(): targeting.text=button.tooltip_text
    elif valid_move: targeting.text="Move here · %d tiles"%(reachable[str(p)].size()-1)
    else: targeting.text="Outside movement or target range."
   )
   button.pressed.connect(func():choose_tile(p));grid.add_child(button);tiles[str(p)]=button
 for id in retained:
  if not pawns.has(id):retained[id].queue_free()
 var summary: Array[String]=[]
 for id in b.order:
  var u: Dictionary=b.units[id]
  summary.append("%s%s · %d/%d HP"%[str(state.party_ids.find(id)+1)+". " if u.team=="party" else "",u.name,u.record.runtime.hp,engine.stats(u).HP])
 detail.text="\n".join(summary)
 if playing:
  var abilities: Array=engine.characters.derive_character(actor.record).snapshot.abilities
  if actor.team=="party":
   var focus: int=int(actor.record.runtime.resources.get("focus",0))
   detail.text="%s\nMove: %s · Action: %s"%[actor.name,"ready" if int(b.budget.move)>0 else "spent","ready" if int(b.budget.main)>0 else "spent"]
   detail.add_theme_color_override("font_color",GameUI.GOLD)
   add_action("move","Move · select a clear tile")
   add_action("attack","Attack · select enemy")
   if abilities.has("guard"):
    var guard := GameUI.action("Guard · protect adjacent ally",func():send("guard",actor.id))
    guard.disabled=thread!=null or int(b.budget.main)<1;gate_button(guard);actions.add_child(guard);action_buttons.guard=guard
   if abilities.has("precision"): actions.add_child(GameUI.label("Opening Strike: +4 once per round when an ally threatens your target.",GameUI.META))
   if abilities.has("spark"):
    add_action("spark","Lantern Spark · range 5")
    add_action("slow","Binding Step · 1 Focus (%d left)"%focus)
    add_action("healing-thread","Mending Thread · 1 Focus / adjacent ally")
   actions.add_child(GameUI.label("Mode: "+mode.capitalize()+". Leaving an enemy's adjacent tile can provoke an attack. Ranged attacks while engaged take −4.",GameUI.META))
 else:
  detail.text=AdventureService.active_result(state).get("text","Encounter complete.")+"\n\n"+detail.text
 for style in CombatArt.styles():
  if style.id==art_style: art_note.text=style.note if CombatArt.available(style) else "Art unavailable: "+style.name+" · neutral tokens shown"
 var context := location_context()
 if not context.is_empty():art_note.text+="\n"+context
 title.tooltip_text=context
 log_label.text="Party & opponents\n"+"\n".join(summary)+"\n\nBattle record\n"+"\n".join(b.log.slice(maxi(0,b.log.size()-7)))
func return_region() -> void:
 if thread==null: get_tree().change_scene_to_file("res://scenes/gameplay/expedition.tscn")
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel") and thread==null:
  get_viewport().set_input_as_handled();get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
func _exit_tree() -> void:
 if thread!=null: thread.wait_to_finish()

func layout_board() -> void:
 if grid==null: return
 # At the smallest viewport the order is available in its tooltip and side panel.
 turn_label.visible=size.x>700
 var board: Dictionary=battle().get("board",{})
 var columns: int=int(board.get("width",8));var rows: int=int(board.get("height",6))
 tile_side=floor(minf((size.y-(182 if turn_label.visible else 164))/rows,(size.x*0.66-24)/columns))
 tile_side=maxf(20,tile_side)
 if targeting!=null:targeting.custom_minimum_size.x=columns*tile_side
 for button in tiles.values(): button.custom_minimum_size=Vector2(tile_side,tile_side)

func show_art_credits() -> void:
 var dialog := AcceptDialog.new();dialog.title="Universal LPC · artwork credits"
 var scroll := ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scroll.offset_top=8;scroll.offset_left=8;scroll.offset_right=-8;scroll.offset_bottom=-42
 dialog.add_child(scroll)
 var text := RichTextLabel.new();text.fit_content=true;text.scroll_active=false;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 text.add_theme_font_size_override("normal_font_size",14);text.text=FileAccess.get_file_as_string("res://assets/combat/LPC-CREDITS.txt");scroll.add_child(text)
 add_child(dialog);dialog.popup_centered_ratio(0.8);dialog.confirmed.connect(dialog.queue_free)

func animate_committed(previous: Dictionary) -> void:
 var after := battle()
 if previous.is_empty() or after.is_empty() or int(after.revision)<=int(previous.revision):return
 var command: Dictionary=after.commands.back();var actor: String=command.actor_id
 # Install the starting offset before any draw at the committed destination.
 var pitch := Vector2(tile_side,tile_side)
 var target: String=str(command.get("target_id",""))
 var delay := 0.10;var action_serial := -1
 if pawns.has(actor):
  if command.kind=="move":
   var final_position: Array=after.units[actor].position
   var route: Array=engine.paths(previous,previous.units[actor]).get(str(final_position),[])
   pawns[actor].animate_route(route.map(func(p: Array):return Vector2(p[0]-final_position[0],p[1]-final_position[1])*pitch))
   delay=0.20
  elif command.kind not in ["end","retreat"]:
   var direction := Vector2.ZERO
   if after.units.has(target):direction=Vector2(after.units[target].position[0]-after.units[actor].position[0],after.units[target].position[1]-after.units[actor].position[1])
   action_serial=pawns[actor].play_action(command.kind,direction)
   delay=float(pawns[actor].recipe.timelines.get(pawns[actor].animation,{}).get("impact",0.1))
 visual_impact(previous,after.duplicate(true),command,delay,action_serial)

func visual_impact(previous: Dictionary, committed: Dictionary, command: Dictionary, delay: float, action_serial: int) -> void:
 await get_tree().create_timer(delay).timeout
 if not is_inside_tree():return
 var actor: String=command.actor_id;var target: String=str(command.get("target_id",""))
 if action_serial>=0 and (not pawns.has(actor) or pawns[actor].serial!=action_serial):return
 if pawns.has(actor) and pawns.has(target) and (command.kind in ["spark","slow","healing-thread"] or command.kind=="attack" and committed.units[actor].weapon=="bow"):
  var effect := CombatEffect.new();effect.from=pawns[actor].get_global_rect().get_center();effect.to=pawns[target].get_global_rect().get_center()
  effect.kind="arrow" if command.kind=="attack" else command.kind;add_child(effect)
  await get_tree().create_timer(CombatPacing.PROJECTILE_SECONDS).timeout
  if not is_inside_tree():return
 var added_logs: Array=committed.log.slice(previous.log.size())
 for id in committed.order:
  if not pawns.has(id):continue
  var change: int=int(committed.units[id].record.runtime.hp)-int(previous.units[id].record.runtime.hp)
  if change!=0:pawns[id].react(change)
  elif target==id and command.kind in ["attack","spark"]:
   var missed: bool=added_logs.any(func(line: String):return line.ends_with(", miss."))
   pawns[id].react(0,"miss" if missed else "resisted" if command.kind=="spark" else "blocked")

func start_presentation(previous: Dictionary) -> void:
 var seconds := presentation_seconds(previous)
 if seconds<=0:return
 presentation_until=Time.get_ticks_msec()+ceili(seconds*1000);presentation_active=true
 var command: Dictionary=battle().commands.back()
 presentation_actor=battle().units[command.actor_id].name;presentation_kind=command.kind

func presentation_seconds(previous: Dictionary) -> float:
 var after := battle()
 if previous.is_empty() or after.is_empty() or int(after.revision)<=int(previous.revision):return 0.0
 var command: Dictionary=after.commands.back();var actor: String=command.actor_id
 var kind: String=command.kind
 if kind in ["end","retreat"]:return CombatPacing.POST_BEAT_SECONDS
 var downed: bool=after.order.any(func(id: String):return engine.alive(previous.units[id]) and not engine.alive(after.units[id]))
 var reaction := CombatPacing.clip_seconds(CombatPacing.timelines(CombatArt.styles()[0].timelines),"down") if downed else CombatPacing.REACTION_SECONDS
 if kind=="move":
  var route: Array=engine.paths(previous,previous.units[actor]).get(str(after.units[actor].position),[])
  return minf(CombatPacing.MAX_BEAT_SECONDS,maxf((route.size()-1)*CombatPacing.TILE_SECONDS,0.20+reaction)+CombatPacing.POST_BEAT_SECONDS)
 var clip := "shoot" if kind=="attack" and after.units[actor].weapon=="bow" else "thrust" if kind=="attack" and after.units[actor].weapon=="staff" else "slash" if kind=="attack" else "spell" if kind in ["spark","slow","healing-thread"] else "guard"
 var timelines := CombatPacing.timelines(CombatArt.styles()[0].timelines)
 var projectile: float=CombatPacing.PROJECTILE_SECONDS if clip in ["shoot","spell"] else 0.0
 var impact: float=float(timelines.get(clip,{}).get("impact",0.10))
 return minf(CombatPacing.MAX_BEAT_SECONDS,maxf(CombatPacing.clip_seconds(timelines,clip),impact+projectile+reaction)+CombatPacing.POST_BEAT_SECONDS)

func location_context() -> String:
 var b := battle()
 if b.is_empty():return ""
 var text := "Old Road · authored roadside approach"
 if b.board.has("generation"):
  var site := SandboxRecords.site(state.sandbox,b.site_id)
  return str(site.name)+" · "+str(site.context.biome)+" · inferred/generated local terrain"
 for site in service.packet.get("content",{}).get("sites",[]):
  if site.id==b.site_id:text="Roadside approach to "+str(site.name);break
 if not entry.is_empty() and entry.get("world") is GameWorldTemplate:
  var home: Dictionary=entry.world.get_record("burg",int(state.origin.home_burg_id))
  if not home.is_empty():text+=" · near "+str(home.name)
 return text
