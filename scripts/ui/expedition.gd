extends Control
var service := AdventureService.new()
var entry := {}
var slot := ""
var state := {}
var public_view := {}
var selected := ""
var selected_companion := ""
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
var saved_indicator: Label
func label(text: String, font: int=14) -> Label:
 return GameUI.label(text, font)
func _ready() -> void:
 GameUI.install(self)
 var bg := ColorRect.new()
 bg.color=Color.BLACK
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for s in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+s,GameUI.MARGIN)
 add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",4)
 margin.add_child(column)
 var heading := HBoxContainer.new()
 column.add_child(heading)
 title=label("Hometown",GameUI.TITLE)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 heading.add_child(title)
 saved_indicator=label("",GameUI.META)
 saved_indicator.autowrap_mode=TextServer.AUTOWRAP_OFF
 saved_indicator.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 heading.add_child(saved_indicator)
 reminder=label("",GameUI.META)
 reminder.autowrap_mode=TextServer.AUTOWRAP_OFF
 reminder.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 column.add_child(reminder)
 status=label(message,GameUI.META)
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
 scroll.follow_focus=true
 scroll.custom_minimum_size.x=292
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_child(scroll)
 content=VBoxContainer.new()
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",4)
 scroll.add_child(content)
 footer=label("",GameUI.META)
 column.add_child(footer)
 var controls := HBoxContainer.new()
 column.add_child(controls)
 menu_button=GameUI.action("Main menu",return_menu)
 controls.add_child(menu_button)
 controls.add_child(GameUI.spacer())
 home_button=GameUI.action("Return to hometown · 1 turn",func(): start("return"),true)
 home_button.visible=false
 controls.add_child(home_button)
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
 message="Preparing local map…" if operation=="resume" else "Saving…"
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
  var battle: Dictionary=state.get("first_adventure",{}).get("battle",{})
  if not battle.is_empty() and battle.status=="active":
   get_tree().change_scene_to_file("res://scenes/combat/first_adventure.tscn")
   return
 else: message=str(result.get("error","The previous campaign state was preserved."))
 refresh()
func button(id: String, text: String, callback: Callable, effect: String="") -> void:
 if id=="return":
  action_buttons[id]=home_button
  return
 var b := GameUI.action(text,callback,id in ["accept","depart","scout","travel","prepare_adventure","begin_battle"])
 b.alignment=HORIZONTAL_ALIGNMENT_LEFT
 b.clip_text=true
 b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 b.tooltip_text=effect
 b.disabled=thread!=null
 content.add_child(b)
 if not effect.is_empty(): content.add_child(label(effect,GameUI.META))
 action_buttons[id]=b
func refresh() -> void:
 var old_focus := ""
 var focused := get_viewport().gui_get_focus_owner()
 for key in action_buttons:
  if action_buttons[key]==focused: old_focus=key
 for child in content.get_children():
  content.remove_child(child)
  child.queue_free()
 # A new lead/phase starts at its heading. Follow-focus may then reveal an
 # action, but a result must not inherit the previous choices' scroll offset.
 content.get_parent().scroll_vertical=0
 action_buttons={}
 menu_button.disabled=thread!=null
 home_button.disabled=thread!=null
 home_button.visible=not state.get("expedition",{}).get("active",{}).is_empty()
 home_button.theme_type_variation="PrimaryAction" if state.get("expedition",{}).get("active",{}).get("phase")=="result" else "QuietAction"
 if state.is_empty():
  status.text=message
  return
 var w: GameWorldTemplate = entry.world
 var home := w.get_record("burg",int(state.origin.home_burg_id))
 var area := w.get_record("province",int(state.origin.province_id))
 var e: Dictionary = state.expedition
 var a: Dictionary = e.active
 title.text=home.name+" · Hometown" if a.is_empty() else {"map":"Local expedition","site":"At the site","result":"Expedition record"}.get(a.phase,"Local expedition")
 reminder.text=str(area.get("name","Unassigned districts"))+" · "+str(w.get_record("state",int(state.origin.state_id)).name)+" · "+", ".join(state.party.members.map(func(m: Dictionary): return m.name))
 reminder.tooltip_text=reminder.text
 status.text=message if not message.is_empty() else "Turn %d%s" % [int(state.game_clock.tick)," · Provisions %d / 4"%int(a.supplies) if not a.is_empty() else " · Local accounts"]
 status.add_theme_color_override("font_color",GameUI.ERROR if not message.is_empty() and thread==null else GameUI.MUTED)
 saved_indicator.text="Saved" if thread==null and message.is_empty() else ("Saving…" if thread!=null else "")
 var location: String = str(a.get("site_id",""))
 var markers: Array = public_view.leads.filter(func(l: Dictionary): return l.id==selected)
 var selected_site: String = str(markers[0].site) if not markers.is_empty() else ""
 if not a.is_empty():
  var active_leads: Array=public_view.leads.filter(func(l: Dictionary):return l.id==a.lead_id)
  if not active_leads.is_empty(): selected_site=str(active_leads[0].site)
 map.setup(service.packet.svg,public_view,location,selected_site)
 footer.text="Party at hometown · "+str(home.name)
 for s in public_view.sites:
  if s.id==location: footer.text="Party at "+str(s.name)
 if a.is_empty():
  var chosen: Array = public_view.leads.filter(func(l: Dictionary): return l.id==selected)
  if not chosen.is_empty():
   var l: Dictionary = chosen[0]
   content.add_child(label(l.title,18))
   content.add_child(GameUI.badge(l.status.capitalize()+" · "+l.knowledge.capitalize()))
   content.add_child(label(l.goal+"."))
   content.add_child(label("Account from a local "+l.issuer,GameUI.META))
   content.add_child(label(l.clue))
   if l.status in ["available","withdrawn"]: button("accept","Accept local lead",func(): start("accept",l.id))
   elif l.status=="accepted": button("depart","Begin expedition",func(): start("depart",l.id))
   button("leads","Back to local leads",func(): selected="";refresh())
  else:
   content.add_child(label("First adventure" if state.get("first_adventure",{}).get("result",{}).is_empty() else "Continue your journey",GameUI.SECTION))
   content.add_child(label("Meet your companions, then follow a local account." if not state.has("first_adventure") else "Choose a local account below and begin an expedition.",GameUI.META))
   if not state.has("first_adventure"):
    button("prepare_adventure","Prepare first adventure",func(): start("prepare_adventure"),"Keep these companions and prepare their starting abilities.")
   var leads_section := GameUI.section("Local accounts")
   content.add_child(leads_section)
   var cell := w.get_record("cell",int(home.cell))
   var biome := w.get_record("biome",int(cell.get("biome",-1)))
   leads_section.add_child(label(str(biome.get("name","The surrounding country")),GameUI.META))
   for l in public_view.leads:
    var row := GameUI.row(l.title,l.status.capitalize(),func(): selected=l.id;refresh())
    row.disabled=thread!=null
    leads_section.add_child(row)
    action_buttons[l.id]=row
   var party_section := GameUI.section("Travelling companions")
   content.add_child(party_section)
   for member in state.party.members:
    var life := AdventureRecords.identity(state,member)
    var companion_id: String=member.character_id
    var row := GameUI.row(life.name+" · "+life.archetype,life.background,func(): selected_companion="" if selected_companion==companion_id else companion_id;refresh())
    row.disabled=thread!=null
    row.tooltip_text=life.motivation+". "+life.hook
    party_section.add_child(row);action_buttons["companion:"+companion_id]=row
    if selected_companion==companion_id:
     party_section.add_child(label("Motivation: "+life.motivation+".\n"+life.hook+"\n"+life.relationship,GameUI.META))
     if not life.history.is_empty(): party_section.add_child(label("Journey XP: %d · %s"%[life.xp,life.history.back().summary],GameUI.META))
   if not e.log.is_empty():
    var recent := GameUI.section("Recent events")
    content.add_child(recent)
    for event in e.log.slice(maxi(0,e.log.size()-3)):
     recent.add_child(label(event.text,GameUI.META))
 elif a.phase=="map":
  var l: Dictionary = public_view.leads.filter(func(x: Dictionary): return x.id==a.lead_id)[0]
  content.add_child(label(l.title,18))
  content.add_child(GameUI.badge("Location unknown" if l.knowledge=="rumoured" else "Location known"))
  content.add_child(label(l.goal+".\n"+l.clue))
  if l.knowledge=="rumoured": button("scout","Scout the rumour · 2 turns / 1 provision",func(): start("scout"))
  else: button("travel","Travel to the site · 1 turn / 1 provision",func(): start("travel"))
  content.add_child(label("Scout to locate this account." if l.knowledge=="rumoured" else "The marked location is ready to visit.",GameUI.META))
  button("return","Return home · 1 turn",func(): start("return"))
 else:
  var site: Dictionary = public_view.sites.filter(func(s: Dictionary): return s.id==a.site_id)[0]
  content.add_child(label(site.name,18))
  content.add_child(label(site.description))
  if a.phase=="site":
   if state.has("first_adventure") and state.first_adventure.battle.is_empty() and not e.outcomes.has(site.id):
    content.add_child(label("Armed raiders block this approach. An authored first encounter, attached to this local journey.",GameUI.META))
    button("begin_battle","Bandits on the Old Road · fight",func(): start("begin_battle"),"Three companions, two raiders. Victory records the site; defeat allows withdrawal.")
   content.add_child(label("Investigate: 2 turns · 1 provision",GameUI.META))
   for o in ExpeditionService.choices(state,site): button(o.id,o.label,func(): start(o.id))
   content.add_child(label("Leaving the site costs nothing.",GameUI.META))
  else:
   var out: Dictionary = e.outcomes[site.id]
   content.add_child(GameUI.badge(str(e.knowledge[site.id]).capitalize()))
   content.add_child(label("What changed",GameUI.SECTION))
   content.add_child(label(out.text))
   content.add_child(label("Return to close this account." if out.approach!="leave" else "This account remains unresolved.",GameUI.META))
  button("return","Return home · 1 turn",func(): start("return"))
 if thread==null:
  if action_buttons.has(old_focus): action_buttons[old_focus].call_deferred("grab_focus")
  elif focused==null or not is_instance_valid(focused) or focused!=menu_button and (focused!=home_button or not home_button.visible):
   var target := ""
   for key in ["accept","depart","scout","travel","survey","return","leads"]:
    if action_buttons.has(key):
     target=key
     break
   if target.is_empty() and not action_buttons.is_empty(): target=str(action_buttons.keys()[0])
   if not target.is_empty(): action_buttons[target].call_deferred("grab_focus")
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
