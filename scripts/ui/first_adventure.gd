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

func _ready() -> void:
 GameUI.install(self)
 var background := ColorRect.new();background.color=Color("090c0c")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
 var margin := MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
 add_child(margin)
 var column := VBoxContainer.new();column.add_theme_constant_override("separation",4);margin.add_child(column)
 title=GameUI.label("Bandits on the Old Road",GameUI.TITLE);column.add_child(title)
 status=GameUI.label(message,GameUI.META);column.add_child(status)
 turn_label=GameUI.label("",GameUI.META);column.add_child(turn_label)
 var body := HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(body)
 var board_column := VBoxContainer.new();body.add_child(board_column)
 grid=GridContainer.new();grid.columns=8;grid.add_theme_constant_override("h_separation",2);grid.add_theme_constant_override("v_separation",2);board_column.add_child(grid)
 board_column.add_child(GameUI.label("Blue: party · Red: raiders · Gold: turn",10))
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
 var handoff := PartyService.handoff
 entry=handoff.get("entry",{});slot=handoff.get("slot","")
 service.store.save_root=handoff.get("save_root",service.store.save_root)
 service.library.library_root=handoff.get("library_root",service.library.library_root)
 service.cache_root=handoff.get("cache_root",service.cache_root)
 if entry.is_empty() or slot.is_empty(): message="No campaign selected. Return to the main menu.";refresh()
 else: operate("resume")

func battle() -> Dictionary: return state.get("first_adventure",{}).get("battle",{})
func operate(operation: String,command_input: Dictionary={}) -> void:
 if thread!=null: return
 var changes := {"revision":state.get("expedition",{}).get("revision",-1),"command":command_input}
 thread=Thread.new();thread.start(func():return service.operate(entry,slot,operation,1,changes))
 message="Saving…";refresh()
func send(kind: String,target: String="",destination: Array=[]) -> void:
 var b := battle()
 if b.is_empty() or b.status!="active" or engine.current(b).team!="party" or thread!=null: return
 var input := {"revision":b.revision,"actor_id":engine.current(b).id,"kind":kind}
 if not target.is_empty(): input.target_id=target
 if not destination.is_empty(): input.destination=destination
 operate("battle_command",input)
func _process(delta: float) -> void:
 if thread!=null:
  if thread.is_alive(): return
  var result: Dictionary=thread.wait_to_finish();thread=null
  if result.get("ok",false):
   state=result.state;message="";ai_delay=0.45
   if not battle().is_empty() and engine.current(battle()).id!=actor_id:
    actor_id=engine.current(battle()).id;mode="attack"
  else: message=str(result.get("error","The previous save was preserved."))
  refresh()
 var b := battle()
 if not b.is_empty() and b.status=="active" and engine.current(b).team=="enemy" and message.is_empty():
  ai_delay-=delta
  if ai_delay<=0: operate("battle_command",engine.enemy_command(b))
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
 button.tooltip_text=text
 actions.add_child(button);action_buttons[id]=button
func refresh() -> void:
 for child in grid.get_children(): grid.remove_child(child);child.queue_free()
 for child in actions.get_children(): actions.remove_child(child);child.queue_free()
 tiles={};action_buttons={}
 var b := battle()
 var playing: bool=not b.is_empty() and b.status=="active"
 end_button.visible=playing;retreat_button.visible=playing;return_button.visible=not playing and not b.is_empty()
 menu_button.disabled=thread!=null
 end_button.disabled=thread!=null or not playing or engine.current(b).team!="party"
 retreat_button.disabled=end_button.disabled;return_button.disabled=thread!=null
 if b.is_empty(): status.text=message;return
 var actor := engine.current(b)
 title.text=b.board.title
 status.text=message if not message.is_empty() else ("Saved · Round %d · %s's turn"%[b.round,actor.name] if playing else "Saved · "+b.status.capitalize())
 turn_label.text=" → ".join(b.order.filter(func(id: String):return engine.alive(b.units[id])).map(func(id: String):return b.units[id].name))
 var reachable := engine.paths(b,actor) if playing and mode=="move" and int(b.budget.move)>0 else {}
 for y in int(b.board.height):
  for x in int(b.board.width):
   var p := [x,y];var id := engine.occupant(b,p)
   var button := Button.new();button.custom_minimum_size=Vector2(36,30);button.add_theme_font_size_override("font_size",10)
   var color := Color("202d24")
   if b.board.blocked.has(p): color=Color("41433b");button.text="■";button.disabled=true
   elif not id.is_empty():
    var u: Dictionary=b.units[id]
    color=Color("25465a") if u.team=="party" else Color("623732")
    button.text=(str(state.party_ids.find(id)+1) if u.team=="party" else "B")+"\n"+str(u.record.runtime.hp)
    button.tooltip_text="%s · %d / %d HP · %s"%[u.name,u.record.runtime.hp,engine.stats(u).HP,u.weapon]
   elif reachable.has(str(p)): color=Color("38482e");button.text="·"
   var border := GameUI.GOLD if actor.position==p and playing else Color("454c3d")
   var style := GameUI.box(color,border,2 if actor.position==p and playing else 1)
   style.content_margin_top=1;style.content_margin_bottom=1;style.content_margin_left=2;style.content_margin_right=2
   button.add_theme_stylebox_override("normal",style)
   var hover := style.duplicate();hover.bg_color=color.lightened(0.15);hover.border_color=GameUI.GOLD
   button.add_theme_stylebox_override("hover",hover)
   button.disabled=button.disabled or thread!=null or not playing or actor.team!="party"
   button.pressed.connect(func():choose_tile(p));grid.add_child(button);tiles[str(p)]=button
 var summary: Array[String]=[]
 for id in b.order:
  var u: Dictionary=b.units[id]
  summary.append("%s%s · %d/%d HP"%[str(state.party_ids.find(id)+1)+". " if u.team=="party" else "",u.name,u.record.runtime.hp,engine.stats(u).HP])
 detail.text="\n".join(summary)
 if playing:
  var abilities: Array=engine.characters.derive_character(actor.record).snapshot.abilities
  if actor.team=="party":
   var focus: int=int(actor.record.runtime.resources.get("focus",0))
   detail.text="%s · Move %d / Action %d\n%s"%[actor.name,b.budget.move,b.budget.main,detail.text]
   add_action("move","Move · select a clear tile")
   add_action("attack","Attack · select enemy")
   if abilities.has("guard"):
    var guard := GameUI.action("Guard · protect adjacent ally",func():send("guard",actor.id))
    guard.disabled=thread!=null or int(b.budget.main)<1;actions.add_child(guard);action_buttons.guard=guard
   if abilities.has("precision"): actions.add_child(GameUI.label("Opening Strike: +4 once per round when an ally threatens your target.",GameUI.META))
   if abilities.has("spark"):
    add_action("spark","Lantern Spark · range 5")
    add_action("slow","Binding Step · 1 Focus (%d left)"%focus)
    add_action("healing-thread","Mending Thread · 1 Focus / adjacent ally")
   actions.add_child(GameUI.label("Mode: "+mode.capitalize()+". Leaving an enemy's adjacent tile can provoke an attack. Ranged attacks while engaged take −4.",GameUI.META))
 else:
  detail.text=state.first_adventure.get("result",{}).get("text","Encounter complete.")+"\n\n"+detail.text
 log_label.text="Battle record\n"+"\n".join(b.log.slice(maxi(0,b.log.size()-7)))
func return_region() -> void:
 if thread==null: get_tree().change_scene_to_file("res://scenes/gameplay/expedition.tscn")
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel") and thread==null:
  get_viewport().set_input_as_handled();get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
func _exit_tree() -> void:
 if thread!=null: thread.wait_to_finish()
