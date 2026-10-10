extends Control
## Presentation reads persisted party facts. All generation and commits are deliberate jobs.
var service := PartyService.new()
var entry := {}
var slot := ""
var state := {}
var selected := 1
var thread: Thread
var after_save := ""
var message := ""
var ready_view := false
var expedition_cache_root := "user://expedition-content"
var title: Label
var origin: Label
var roster: PartyRoster
var name_edit: LineEdit
var people_picker: OptionButton
var role_picker: OptionButton
var commonness: Label
var description: Label
var biography: Label
var overview: Label
var detail_tabs: TabContainer
var message_label: Label
var save_button: Button
var finish_button: Button
var reroll_button: Button
var back_button: Button
var pack := WorldOriginLore.read_json(WorldPeoples.PACK)
var updating := false
var pending_edit := {}
var local_people: Array = []
var member_heading: Label
var preview_recipes := {}

func label(text: String, size: int = 14) -> Label:
 return GameUI.label(text, size)

func _ready() -> void:
 GameUI.install(self)
 var background := ColorRect.new()
 background.color = Color.BLACK
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
 add_child(margin)
 GameUI.reading_width(margin,self,860)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 4)
 margin.add_child(column)
 title = label("Party creation", GameUI.TITLE)
 column.add_child(title)
 origin = label("", GameUI.META)
 origin.custom_minimum_size.y = 20
 origin.autowrap_mode = TextServer.AUTOWRAP_OFF
 origin.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 origin.clip_text = true
 column.add_child(origin)
 var body := HBoxContainer.new()
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation", 12)
 column.add_child(body)
 var left := VBoxContainer.new()
 left.custom_minimum_size.x = 218
 body.add_child(left)
 roster = PartyRoster.new()
 roster.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 roster.custom_minimum_size.y = 178
 left.add_child(roster)
 roster.item_selected.connect(_select_member)
 overview = label("Three adventurers", GameUI.META)
 left.add_child(overview)
 detail_tabs = TabContainer.new()
 detail_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 detail_tabs.add_theme_font_size_override("font_size", 14)
 body.add_child(detail_tabs)
 var identity := VBoxContainer.new()
 identity.name = "Identity"
 identity.add_theme_constant_override("separation", 3)
 detail_tabs.add_child(identity)
 member_heading = label("", GameUI.SECTION)
 identity.add_child(member_heading)
 name_edit = LineEdit.new()
 name_edit.placeholder_text = "Name"
 name_edit.max_length = 48
 name_edit.add_theme_font_size_override("font_size", 14)
 identity.add_child(name_edit)
 name_edit.text_submitted.connect(func(_value: String): _save_changes())
 people_picker = OptionButton.new()
 people_picker.add_theme_font_size_override("font_size", 14)
 identity.add_child(people_picker)
 for p in pack.peoples: people_picker.add_item(p.name)
 people_picker.item_selected.connect(func(_index: int): _presence())
 commonness = label("",GameUI.META)
 identity.add_child(commonness)
 description = label("", 13)
 var people_scroll := ScrollContainer.new()
 people_scroll.follow_focus = true
 people_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 people_scroll.custom_minimum_size.y = 52
 people_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 identity.add_child(people_scroll)
 description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 people_scroll.add_child(description)
 role_picker = OptionButton.new()
 role_picker.add_theme_font_size_override("font_size", 14)
 identity.add_child(role_picker)
 for r in pack.roles: role_picker.add_item(r.name)
 var background_tab := VBoxContainer.new()
 background_tab.name = "Background"
 detail_tabs.add_child(background_tab)
 var scroll := ScrollContainer.new()
 scroll.follow_focus = true
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 background_tab.add_child(scroll)
 biography = label("")
 biography.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(biography)
 reroll_button = GameUI.action("Another background",func(): _save_changes(true))
 reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 background_tab.add_child(reroll_button)
 message_label = label("", GameUI.META)
 message_label.custom_minimum_size.y = 18
 message_label.max_lines_visible = 2
 message_label.clip_text = true
 column.add_child(message_label)
 var actions := HBoxContainer.new()
 column.add_child(actions)
 back_button = GameUI.action("Main menu",_return_menu)
 actions.add_child(back_button)
 actions.add_child(GameUI.spacer())
 save_button = GameUI.action("Save character",_save_changes)
 actions.add_child(save_button)
 finish_button = GameUI.action("Party ready",_finish,true)
 actions.add_child(finish_button)
 var handoff := PartyService.handoff
 PartyService.handoff = {}
 if handoff.is_empty(): handoff = service.resumable()
 if handoff.is_empty():
  message = "Choose a hometown through New Game before creating a party."
  refresh()
  return
 expedition_cache_root = str(handoff.get("cache_root", expedition_cache_root))
 entry = handoff.entry
 slot = handoff.slot
 service.store.save_root = str(handoff.get("save_root", service.store.save_root))
 service.library.library_root = str(handoff.get("library_root", service.library.library_root))
 _start("generate")

func _start(operation: String, changes: Dictionary = {}) -> void:
 if thread != null or entry.is_empty(): return
 if operation == "edit": pending_edit = changes.duplicate(true)
 message = "Preparing your party…" if operation == "generate" else "Saving…"
 thread = Thread.new()
 thread.start(service.operate.bind(entry, slot, operation, selected, changes))
 refresh()

func _process(_delta: float) -> void:
 if thread == null or thread.is_alive(): return
 var result: Dictionary = thread.wait_to_finish()
 thread = null
 if not result.get("ok", false):
  message = str(result.get("error", "Party setup failed. The campaign was preserved."))
  after_save = ""
 else:
  pending_edit = {}
  var first_display := state.is_empty()
  var was_ready := ready_view
  state = result.state
  ready_view = state.party.status == "ready"
  if ready_view and (first_display or not was_ready): detail_tabs.current_tab=1
  message = "Party saved and verified." if not ready_view else "Party setup complete. Your hometown awaits."
 refresh()
 if not after_save.is_empty() and result.get("ok", false):
  var action := after_save
  after_save = ""
  if action == "menu": get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
  elif action == "ready": _start("ready")
  elif action.begins_with("member:"):
   selected = int(action.trim_prefix("member:"))
   refresh()

func dirty() -> bool:
 if state.is_empty() or updating: return false
 var m: Dictionary = state.party.members[selected - 1]
 return name_edit.text.strip_edges() != m.name or pack.peoples[people_picker.selected].id != m.people_id or pack.roles[role_picker.selected].id != m.role_id

func _save_changes(regenerate: bool = false) -> void:
 if thread != null: return
 if state.is_empty():
  _start("generate")
  return
 var changes := {"people_id":pack.peoples[people_picker.selected].id,"role_id":pack.roles[role_picker.selected].id}
 var m: Dictionary = state.party.members[selected - 1]
 if name_edit.text.strip_edges() != m.name: changes.name = name_edit.text
 if regenerate: changes.regenerate = true
 _start("edit", changes)

func _select_member(index: int) -> void:
 if updating or thread != null or state.is_empty(): return
 if dirty():
  after_save = "member:" + str(index + 1)
  _save_changes()
 else:
  selected = index + 1
  refresh()

func _presence() -> void:
 if updating or entry.is_empty(): return
 var people: Dictionary = pack.peoples[people_picker.selected]
 if local_people.is_empty():
  var reader := WorldPeoples.new()
  if not reader.load_world(entry.world): return
  local_people = reader.local(int(state.origin.home_burg_id)).peoples
 var row: Dictionary = local_people.filter(func(p: Dictionary): return p.people_id == people.id)[0]
 commonness.text = {"common":"Common locally","present":"Present locally","uncommon":"Uncommon locally"}[row.status]
 commonness.tooltip_text = "Every ancestry is available. Local presence is descriptive."
 description.text = people.description

func occupation_label(id: String) -> String:
 var rows: Array = pack.occupations.filter(func(r: Dictionary): return r.id == id)
 if not rows.is_empty(): return rows[0].label
 var foundation := WorldOriginLore.read_json("res://data/world_enrichment/trhgd-expanded-v1.json")
 rows = foundation.occupations.filter(func(r: Dictionary): return r.id == id)
 return str(rows[0].key) if not rows.is_empty() else id.replace("-", " ")

func refresh() -> void:
 updating = true
 var busy := thread != null
 title.text = "Party ready" if ready_view else "Party creation"
 if not entry.is_empty() and not state.is_empty():
  var world: GameWorldTemplate = entry.world
  var home := world.get_record("burg", int(state.origin.home_burg_id))
  var area := world.get_record("province", int(state.origin.province_id))
  origin.text = "From %s · %s · %s" % [home.name, area.get("name", "Unassigned districts"), world.get_record("state", int(state.origin.state_id)).name]
 origin.tooltip_text = origin.text
 roster.clear()
 preview_recipes={}
 if not state.is_empty():
  var previews := CombatArt.party_units(state)
  for m in state.party.members:
   var people: Dictionary = pack.peoples.filter(func(p: Dictionary): return p.id == m.people_id)[0]
   var role: Dictionary = pack.roles.filter(func(r: Dictionary): return r.id == m.role_id)[0]
   var recipe := CombatArt.recipe("lpc",previews[m.character_id],m) if previews.has(m.character_id) else {}
   if not recipe.is_empty():preview_recipes[m.character_id]=recipe.recipe_hash
   roster.add_item("%s\n%s · %s" % [m.name,people.name,role.name],CombatArt.thumbnail(recipe))
   roster.set_item_tooltip(m.slot - 1, people.name + " · " + role.name+" · Saved starting equipment preview"+(" · Art unavailable" if recipe.is_empty() or not recipe.available else ""))
  roster.select(selected - 1)
  var member: Dictionary = state.party.members[selected - 1]
  var ancestry: Dictionary = pack.peoples.filter(func(p: Dictionary): return p.id == member.people_id)[0]
  var calling: Dictionary = pack.roles.filter(func(r: Dictionary): return r.id == member.role_id)[0]
  overview.text = calling.name
  overview.tooltip_text = calling.description
  member_heading.text = member.name + " · " + ancestry.name
  role_picker.tooltip_text = calling.description
  name_edit.text = member.name
  for i in pack.peoples.size():
   if pack.peoples[i].id == member.people_id: people_picker.select(i)
  for i in pack.roles.size():
   if pack.roles[i].id == member.role_id: role_picker.select(i)
  var f: Dictionary = member.generated_facts
  biography.text = member.biography + "\n\nUPBRINGING: " + str(f.background.family).replace("-", " ") + "\nFORMER WORK: " + occupation_label(str(f.occupation_id)) + "\nMOTIVATION: " + str(f.background.motivation).replace("-", " ")
 if not state.is_empty() and not pending_edit.is_empty():
  if pending_edit.has("name"): name_edit.text = pending_edit.name
  for i in pack.peoples.size():
   if pack.peoples[i].id == pending_edit.get("people_id"): people_picker.select(i)
  for i in pack.roles.size():
   if pack.roles[i].id == pending_edit.get("role_id"): role_picker.select(i)
 message_label.text = ("Saved" if message.begins_with("Party saved") else message).left(240)
 message_label.tooltip_text = message
 name_edit.editable = not busy and not ready_view and not state.is_empty()
 for control in [people_picker,role_picker,reroll_button]: control.disabled = busy or state.is_empty() or ready_view
 save_button.text = "Retry preparation" if state.is_empty() else "Save character"
 save_button.disabled = busy or ready_view or entry.is_empty()
 save_button.visible = not ready_view
 reroll_button.visible = not ready_view
 member_heading.visible = ready_view
 name_edit.visible = not ready_view
 people_picker.visible = not ready_view
 role_picker.visible = not ready_view
 commonness.visible = not ready_view
 roster.mouse_filter = Control.MOUSE_FILTER_IGNORE if busy else Control.MOUSE_FILTER_STOP
 roster.set_enabled(not busy)
 back_button.disabled = busy
 finish_button.disabled = busy or state.is_empty()
 finish_button.text = "Enter hometown" if ready_view else "Party ready"
 detail_tabs.visible = not state.is_empty()
 updating = false
 if not state.is_empty(): _presence()

func _finish() -> void:
 if thread != null or state.is_empty(): return
 if ready_view:
  PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":expedition_cache_root}
  get_tree().change_scene_to_file("res://scenes/gameplay/expedition.tscn")
 elif dirty():
  after_save = "ready"
  _save_changes()
 else: _start("ready")

func _return_menu() -> void:
 if thread != null: return
 if dirty():
  after_save = "menu"
  _save_changes()
 else: get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  _return_menu()

func _exit_tree() -> void:
 if thread != null: thread.wait_to_finish()
