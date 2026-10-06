extends Control
var service := ExpeditionService.new()
var entry := {}
var slot := ""
var state := {}
var public_view := {}
var selected := ""
var thread: Thread
var message := "Preparing the local accounts and map…"
var title: Label
var reminder: Label
var status: Label
var content: VBoxContainer
var map: Control
var footer: Label
var menu_button: Button
var home_button: Button
var action_buttons := {}
func label(text: String, font: int=14) -> Label:
 var l := Label.new()
 l.text=text
 l.add_theme_font_size_override("font_size",font)
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 return l
func _ready() -> void:
 theme=preload("res://themes/menu_theme.tres").duplicate()
 theme.default_font_size=14
 theme.set_font_size("font_size","Button",14)
 var panel := StyleBoxFlat.new()
 panel.bg_color=Color("#15130e")
 panel.border_color=Color("#796338")
 panel.set_border_width_all(1)
 panel.set_content_margin_all(4)
 var focus := panel.duplicate()
 focus.border_color=Color("#ebc75f")
 theme.set_stylebox("normal","Button",panel)
 theme.set_stylebox("focus","Button",focus)
 theme.set_stylebox("hover","Button",focus)
 var bg := ColorRect.new()
 bg.color=Color.BLACK
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for s in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+s,10)
 add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",4)
 margin.add_child(column)
 title=label("Hometown",22)
 column.add_child(title)
 reminder=label("")
 reminder.autowrap_mode=TextServer.AUTOWRAP_OFF
 reminder.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 column.add_child(reminder)
 status=label(message,13)
 column.add_child(status)
 var body := HBoxContainer.new()
 body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 column.add_child(body)
 map=load("res://scripts/expedition/expedition_map.gd").new()
 map.custom_minimum_size=Vector2(240,200)
 map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 map.chosen.connect(select_site)
 body.add_child(map)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size.x=318
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_child(scroll)
 content=VBoxContainer.new()
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",4)
 scroll.add_child(content)
 footer=label("Home: gold ring · party: brown ring · numbered sites: known locations",12)
 column.add_child(footer)
 var controls := HBoxContainer.new()
 column.add_child(controls)
 home_button=Button.new()
 home_button.text="Return home · 1 turn"
 home_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 home_button.visible=false
 controls.add_child(home_button)
 home_button.pressed.connect(func(): start("return"))
 menu_button=Button.new()
 menu_button.text="Main menu (progress saved)"
 menu_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 controls.add_child(menu_button)
 menu_button.pressed.connect(return_menu)
 var h := PartyService.handoff
 entry=h.get("entry",{})
 slot=h.get("slot","")
 service.store.save_root=h.get("save_root",service.store.save_root)
 service.library.library_root=h.get("library_root",service.library.library_root)
 service.cache_root=h.get("cache_root",service.cache_root)
 if entry.is_empty() or slot.is_empty():
  message="No campaign selected. Return to the main menu."
  refresh()
 else: start("resume")
func start(operation: String, lead: String="") -> void:
 if thread!=null: return
 var changes := {"lead":lead,"revision":state.get("expedition",{}).get("revision",-1)}
 message="Preparing local map…" if operation=="resume" else "Saving and verifying…"
 thread=Thread.new()
 thread.start(func(): return service.operate(entry,slot,operation,1,changes))
 refresh()
func _process(_delta: float) -> void:
 if thread==null or thread.is_alive(): return
 var result: Dictionary = thread.wait_to_finish()
 thread=null
 if result.get("ok",false):
  var was_away: bool = not state.get("expedition",{}).get("active",{}).is_empty()
  state=result.state
  if was_away and state.expedition.active.is_empty(): selected=""
  public_view=ExpeditionRecords.projection(service.packet.content,state.expedition)
  message=""
 else: message=str(result.get("error","The previous campaign state was preserved."))
 refresh()
func button(id: String, text: String, callback: Callable, effect: String="") -> void:
 if id=="return":
  action_buttons[id]=home_button
  return
 var b := Button.new()
 b.text=text
 b.clip_text=true
 b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 b.tooltip_text=effect
 b.disabled=thread!=null
 content.add_child(b)
 b.pressed.connect(callback)
 action_buttons[id]=b
func refresh() -> void:
 for child in content.get_children():
  content.remove_child(child)
  child.queue_free()
 action_buttons={}
 menu_button.disabled=thread!=null
 home_button.disabled=thread!=null
 home_button.visible=not state.get("expedition",{}).get("active",{}).is_empty()
 if state.is_empty():
  status.text=message
  return
 var w: GameWorldTemplate = entry.world
 var home := w.get_record("burg",int(state.origin.home_burg_id))
 var area := w.get_record("province",int(state.origin.province_id))
 var e: Dictionary = state.expedition
 var a: Dictionary = e.active
 title.text=home.name+" · Hometown" if a.is_empty() else "Local expedition"
 reminder.text=str(area.get("name","Unassigned districts"))+" · "+str(w.get_record("state",int(state.origin.state_id)).name)+" · "+", ".join(state.party.members.map(func(m: Dictionary): return m.name))
 reminder.tooltip_text=reminder.text
 status.text=message if not message.is_empty() else "Expedition turns: %d%s · Progress saved and verified" % [int(state.game_clock.tick)," · Provisions: %d"%int(a.supplies) if not a.is_empty() else ""]
 var location: String = str(a.get("site_id",""))
 var markers: Array = public_view.leads.filter(func(l: Dictionary): return l.id==selected)
 var selected_site: String = str(markers[0].site) if not markers.is_empty() else ""
 map.setup(service.packet.svg,public_view,location,selected_site)
 if a.is_empty():
  var chosen: Array = public_view.leads.filter(func(l: Dictionary): return l.id==selected)
  if not chosen.is_empty():
   var l: Dictionary = chosen[0]
   content.add_child(label(l.title,18))
   content.add_child(label(l.knowledge.capitalize()+" · "+l.status.capitalize(),13))
   content.add_child(label(l.goal+". An account from a local "+l.issuer+".",13))
   content.add_child(label(l.clue,13))
   if l.status in ["available","withdrawn"]: button("accept","Accept local lead",func(): start("accept",l.id))
   elif l.status=="accepted": button("depart","Depart / view local map",func(): start("depart",l.id))
   button("leads","Back to local leads",func(): selected="";refresh())
  else:
   content.add_child(label("LOCAL LEADS",16))
   var cell := w.get_record("cell",int(home.cell))
   var biome := w.get_record("biome",int(cell.get("biome",-1)))
   content.add_child(label("Your home stands in "+str(biome.get("name","the surrounding country"))+". These accounts offer no promise of safety.",13))
   for l in public_view.leads:
    button(l.id,l.title+" · "+l.status.capitalize(),func(): selected=l.id;refresh())
   if not e.log.is_empty():
    content.add_child(label("RECENT EXPEDITION",14))
    content.add_child(label(e.log[-1].text,13))
 elif a.phase=="map":
  var l: Dictionary = public_view.leads.filter(func(x: Dictionary): return x.id==a.lead_id)[0]
  content.add_child(label(l.title,18))
  content.add_child(label(l.goal+".\n"+l.clue,13))
  if l.knowledge=="rumoured": button("scout","Scout the rumour · 2 turns / 1 provision",func(): start("scout"))
  else: button("travel","Travel to the site · 1 turn / 1 provision",func(): start("travel"))
  content.add_child(label("Choose a known destination. Travel costs one turn and one provision.",12))
  button("return","Return home · 1 turn",func(): start("return"))
 else:
  var site: Dictionary = public_view.sites.filter(func(s: Dictionary): return s.id==a.site_id)[0]
  content.add_child(label(site.name,18))
  content.add_child(label(site.description,13))
  if a.phase=="site":
   content.add_child(label("Choose an approach · investigation costs 2 turns / 1 provision",12))
   for o in ExpeditionService.choices(state,site): button(o.id,o.label,func(): start(o.id),o.effect)
  else:
   var out: Dictionary = e.outcomes[site.id]
   content.add_child(label(out.text,14))
   content.add_child(label("SITE: "+str(e.knowledge[site.id]).capitalize()+"\nYour choice is recorded in this campaign.",13))
  button("return","Return home · 1 turn",func(): start("return"))
func select_site(id: String) -> void:
 for l in public_view.leads:
  if l.site==id:
   if not state.expedition.active.is_empty() and state.expedition.active.lead_id!=l.id:
    message="This expedition follows another account. Return home to choose this lead."
   else:
    message=""
    selected=l.id
   refresh()
   return
func return_menu() -> void:
 if thread==null: get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  if not state.is_empty() and state.expedition.active.is_empty() and not selected.is_empty():
   selected=""
   refresh()
  else: return_menu()
func _exit_tree() -> void:
 if thread!=null: thread.wait_to_finish()
