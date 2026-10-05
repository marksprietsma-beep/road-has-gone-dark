extends Control
## Choices are previews until confirm_origin; GAME-7 owns identity and persistence.
const TEMPLATES := ["game-11-determinism", "atlas-showcase"]
const TITLES := ["World I", "World II"]
const PREVIEW := preload("res://scripts/ui/origin_map_preview.gd")
var worlds: Array[GameWorldTemplate] = []
var previews: Array[Dictionary] = []
var store := GamePlaythroughStore.new()
var world_index := 0
var state_id := -1
var province_id := -1
var burg_id := -1
var page := 0
var saved_slot := ""
# Only a slot created by this confirmation can be discarded after failed validation.
var unvalidated_save_path := ""
var candidates: Array[Dictionary] = []
var title: Label
var steps: Label
var left: VBoxContainer
var facts: Label
var map: Control
var next_button: Button
var back_button: Button
var options: ItemList
var state_picker: OptionButton
var province_picker: OptionButton
var message := ""
var map_world_index := -1
var library := GameWorldLibrary.new()
var entries: Array[Dictionary] = []
var world_titles: Array[String] = []
var delete_target: Dictionary = {}
var generation_button: Button
var deletion_button: Button
var job_thread: Thread
var job_mutex := Mutex.new()
var job_phase := ""
var working_label: Label
var job_is_generation := false

func _ready() -> void:
 _reload_library()
 _build_ui()
 show_page()

func _label(text: String, font_size: int = 14) -> Label:
 var label := Label.new()
 label.text = text
 label.add_theme_font_size_override("font_size", font_size)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 return label

func _button(text: String, action: Callable) -> Button:
 var button := Button.new()
 button.text = text
 button.add_theme_font_size_override("font_size", 16)
 button.custom_minimum_size.y = 30
 button.pressed.connect(action)
 return button

func _build_ui() -> void:
 theme = preload("res://themes/menu_theme.tres").duplicate()
 theme.default_font_size = 14
 var style := StyleBoxFlat.new()
 style.bg_color = Color("12110d")
 style.border_color = Color("78613b")
 style.set_border_width_all(1)
 var focus := style.duplicate()
 focus.border_color = Color("ffdc81")
 focus.draw_center = false
 theme.set_stylebox("panel", "ItemList", style)
 theme.set_stylebox("focus", "ItemList", focus)
 var selected := StyleBoxFlat.new()
 selected.bg_color = Color("42351e")
 theme.set_stylebox("selected", "ItemList", selected)
 theme.set_stylebox("selected_focus", "ItemList", selected)
 theme.set_color("font_color", "ItemList", Color("d9bd7d"))
 theme.set_color("font_selected_color", "ItemList", Color("ffe29b"))
 theme.set_stylebox("hover", "Button", selected)
 theme.set_stylebox("pressed", "Button", selected)
 theme.set_stylebox("disabled", "Button", style)
 theme.set_stylebox("normal", "Button", style)
 theme.set_stylebox("focus", "Button", focus)
 theme.set_stylebox("hover", "OptionButton", selected)
 theme.set_stylebox("pressed", "OptionButton", selected)
 theme.set_stylebox("normal", "OptionButton", style)
 theme.set_stylebox("focus", "OptionButton", focus)
 var background := ColorRect.new()
 background.color = Color.BLACK
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(background)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 16)
 add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 8)
 margin.add_child(column)
 title = _label("", 22)
 column.add_child(title)
 steps = _label("", 12)
 column.add_child(steps)
 var body := HBoxContainer.new()
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation", 16)
 column.add_child(body)
 left = VBoxContainer.new()
 left.custom_minimum_size.x = 236
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(left)
 var right := VBoxContainer.new()
 right.custom_minimum_size.x = 300
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(right)
 map = PREVIEW.new()
 map.custom_minimum_size.y = 146
 map.size_flags_vertical = Control.SIZE_EXPAND_FILL
 right.add_child(map)
 facts = _label("")
 facts.custom_minimum_size.y = 64
 right.add_child(facts)
 var footer := HBoxContainer.new()
 column.add_child(footer)
 back_button = _button("Back", go_back)
 back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 footer.add_child(back_button)
 next_button = _button("Next", advance)
 next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 footer.add_child(next_button)

func states() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for id in worlds[world_index].raw_counts().states:
  var record := worlds[world_index].get_record("state", id)
  if id > 0 and not record.is_empty() and not record.get("removed", false): result.append(record)
 return result

func provinces() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for id in worlds[world_index].raw_counts().provinces:
  var record := worlds[world_index].get_record("province", id)
  if id > 0 and int(record.get("state", -1)) == state_id and not record.get("removed", false): result.append(record)
 return result

func choose_world(index: int) -> void:
 if world_index != index:
  world_index = index
  state_id = -1
  province_id = -1
  burg_id = -1
 if map_world_index != world_index:
  var entry := entries[world_index]
  if not entry.preset and not library.preview_valid(entry.directory, entry.world.source_sha256):
   if message.begins_with("Map preparation could not") or message.begins_with("The map preview could not"):
    map.package = {}
    map.queue_redraw()
   else:
    _start_preview_rebuild(entry)
   return
  map.set_world(previews[world_index], entry.key, worlds[world_index].source_sha256, entry.directory)
  map_world_index = world_index
 _refresh_facts()

func choose_state(id: int) -> void:
 if state_id != id:
  state_id = id
  province_id = -1
  burg_id = -1
 show_page()

func choose_province(id: int) -> void:
 if province_id != id:
  province_id = id
  burg_id = -1
 _refresh_facts()

func choose_home(index: int) -> void:
 burg_id = int(candidates[index].id)
 _refresh_facts()

func show_page() -> void:
 if job_thread != null:
  _show_working()
  return
 map.visible = true
 for child in left.get_children():
  left.remove_child(child)
  child.queue_free()
 if worlds.is_empty():
  title.text = "Worlds unavailable"
  facts.text = message
  next_button.disabled = true
  return
 title.text = ["Choose your world", "Choose your region", "Choose your hometown", "Review your origin", "Origin established"][page]
 steps.text = "%d / 4   WORLD  >  REGION  >  HOMETOWN  >  CONFIRM" % (page + 1) if page < 4 else "PARTY CREATION NEXT"
 back_button.text = "Main menu" if page == 0 or page == 4 else "Back"
 next_button.text = ("Return to handoff" if not saved_slot.is_empty() else "Confirm origin") if page == 3 else ("Review origin" if page == 4 else "Next")
 next_button.disabled = false
 if page == 0:
  if not delete_target.is_empty():
   title.text = "Delete this world?"
   left.add_child(_label(str(delete_target.label), 18))
   left.add_child(_label("This removes the world and its map cache. Saved games will never be deleted."))
   back_button.text = "Keep world"
   next_button.text = "Delete world"
   _refresh_facts()
   back_button.call_deferred("grab_focus")
   return
  left.add_child(_label(message if not message.is_empty() else "Choose a world from your library."))
  options = ItemList.new()
  options.custom_minimum_size.y = 86
  options.add_theme_font_size_override("font_size", 16)
  for value in world_titles: options.add_item(value)
  left.add_child(options)
  options.select(world_index)
  options.item_selected.connect(choose_world)
  choose_world(world_index)
  if job_thread != null: return
  generation_button = _button("Generate New World", _start_generation)
  left.add_child(generation_button)
  deletion_button = _button("Delete World", request_delete)
  deletion_button.disabled = entries[world_index].preset
  left.add_child(deletion_button)
 elif page == 1:
  var areas := states()
  if state_id < 0 and not areas.is_empty(): state_id = int(areas[0].i)
  left.add_child(_label("State"))
  state_picker = OptionButton.new()
  state_picker.fit_to_longest_item = false
  state_picker.clip_text = true
  state_picker.add_theme_font_size_override("font_size", 16)
  left.add_child(state_picker)
  for record in areas:
   state_picker.add_item(str(record.name), int(record.i))
   if int(record.i) == state_id: state_picker.select(state_picker.item_count - 1)
  state_picker.item_selected.connect(func(index: int): choose_state(state_picker.get_item_id(index)))
  var subdivisions := provinces()
  if not subdivisions.is_empty():
   left.add_child(_label("Province / region"))
   province_picker = OptionButton.new()
   province_picker.fit_to_longest_item = false
   province_picker.clip_text = true
   province_picker.add_theme_font_size_override("font_size", 16)
   left.add_child(province_picker)
   province_picker.add_item("Across this state", -1)
   for record in subdivisions:
    province_picker.add_item(str(record.name), int(record.i))
    if int(record.i) == province_id: province_picker.select(province_picker.item_count - 1)
   province_picker.item_selected.connect(func(index: int): choose_province(province_picker.get_item_id(index)))
  left.add_child(_label("Choose a province, or explore the whole state. The gold wash marks your area."))
 elif page == 2:
  candidates = worlds[world_index].home_candidates(state_id, province_id, 8)
  if candidates.is_empty():
   left.add_child(_label("No eligible small hometowns here. Go Back to choose another region."))
   burg_id = -1
   next_button.disabled = true
  else:
   if not candidates.any(func(c: Dictionary): return int(c.id) == burg_id): burg_id = int(candidates[0].id)
   left.add_child(_label("Small settlements · suggested first"))
   options = ItemList.new()
   options.custom_minimum_size.y = 158
   options.add_theme_font_size_override("font_size", 15)
   left.add_child(options)
   for candidate in candidates:
    options.add_item(str(candidate.name))
    if int(candidate.id) == burg_id: options.select(options.item_count - 1)
   options.item_selected.connect(choose_home)
 elif page >= 3:
  var world := worlds[world_index]
  var home := world.get_record("burg", burg_id)
  var state := world.get_record("state", state_id)
  var province := world.get_record("province", int(world.get_record("cell", int(home.get("cell", -1))).get("province", 0)))
  left.add_child(_label(world_titles[world_index], 18))
  left.add_child(_label(str(state.get("name", ""))))
  if not province.is_empty(): left.add_child(_label(str(province.get("name", ""))))
  left.add_child(_label(str(home.get("name", "")), 20))
  left.add_child(_label("Party creation is the next step. Your origin has been saved." if page == 4 else "Establish this origin? A new independent playthrough will be saved."))
  if not message.is_empty(): left.add_child(_label(message))
 _refresh_facts()
 if page == 0 or page == 2 and not candidates.is_empty(): _focus_later(options)
 elif page == 1: _focus_later(state_picker)
 elif next_button.disabled: _focus_later(back_button)
 else: _focus_later(next_button)

func _refresh_facts() -> void:
 var world := worlds[world_index]
 if page == 0:
  var entry := entries[world_index]
  var kind := "Preset world" if entry.preset else "Generated · " + str(entry.created).left(10)
  facts.text = "%s\n%d states · %d settlements" % [kind, states().size(), world.raw_counts().settlements - 1]
  if is_instance_valid(deletion_button): deletion_button.disabled = entry.preset
  map.select_area(-1, -1)
  return
 var home := world.get_record("burg", burg_id) if page >= 2 and burg_id > 0 else {}
 map.select_area(state_id, province_id, home)
 if home.is_empty():
  facts.text = "%d eligible small hometowns\nSelect from the lists; no map clicks required." % world.home_candidates(state_id, province_id, -1).size()
 else:
  var cell := world.get_record("cell", int(home.cell))
  var biome := world.get_record("biome", int(cell.get("biome", -1)))
  facts.text = "%s\n%s\nWalls: %s · Port: %s" % [
   str(home.get("group", "Settlement")).capitalize(),
   str(biome.get("name", "Terrain unknown")),
   "present" if home.get("walls", false) else "none recorded",
   "present" if int(home.get("port", 0)) > 0 else "none recorded"
  ]

func advance() -> void:
 if job_thread != null: return
 if not delete_target.is_empty():
  library.save_root = store.save_root
  var result := library.delete_world(delete_target)
  delete_target = {}
  message = "World deleted." if result.ok else str(result.error)
  if result.ok: _reload_library()
  show_page()
  return
 if page == 4:
  page = 3
 elif page == 3:
  if not saved_slot.is_empty():
   page = 4
  else:
   if not _discard_unvalidated_save():
    message = "Unable to clear the unverified save. Please retry."
    show_page()
    return
   library.save_root = store.save_root
   var guard := library.begin_origin(entries[world_index])
   if not guard.ok:
    message = str(guard.error)
    show_page()
    return
   var created := store.create_playthrough(worlds[world_index], state_id, burg_id, province_id)
   if not created.ok:
    message = str(created.error)
   else:
    var slot: String = created.state.playthrough_id
    var result := store.save_new(slot, created.state, worlds[world_index])
    if result.ok:
     unvalidated_save_path = ProjectSettings.globalize_path(store.save_root.path_join(slot + ".json"))
     var reload := store.load_save(slot, worlds[world_index])
     if reload.ok:
      saved_slot = slot
      unvalidated_save_path = ""
      message = ""
      page = 4
     else:
      message = "Your origin could not be verified. Please try again."
      if not _discard_unvalidated_save():
       message = "Unable to clear the unverified save. Please retry."
    else: message = "Unable to save. " + str(result.error)
   library.end_origin(guard)
 elif page == 2 and burg_id <= 0: return
 else: page += 1
 show_page()

func _discard_unvalidated_save() -> bool:
 if unvalidated_save_path.is_empty(): return true
 if FileAccess.file_exists(unvalidated_save_path):
  if DirAccess.remove_absolute(unvalidated_save_path) != OK: return false
 unvalidated_save_path = ""
 return true

func go_back() -> void:
 if job_thread != null: return
 if not delete_target.is_empty():
  delete_target = {}
  show_page()
  return
 if not _discard_unvalidated_save():
  message = "Unable to clear the unverified save. Please retry before going Back."
  show_page()
  return
 if page == 0 or page == 4 or not saved_slot.is_empty():
  get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
 else:
  page -= 1
  show_page()

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
  get_viewport().set_input_as_handled()
  go_back()

func _focus_later(control: Control) -> void:
 await get_tree().process_frame
 if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()

func _reload_library(selected_id: String = "") -> void:
 entries = library.discover()
 worlds.clear()
 previews.clear()
 world_titles.clear()
 world_index = 0
 for i in entries.size():
  worlds.append(entries[i].world)
  previews.append(entries[i].raw)
  world_titles.append(str(entries[i].label))
  if entries[i].id == selected_id: world_index = i
 map_world_index = -1
 state_id = -1
 province_id = -1
 burg_id = -1

func request_delete() -> void:
 if job_thread != null or page != 0 or entries[world_index].preset: return
 library.save_root = store.save_root
 var status := library.reference_status(entries[world_index])
 if not status.ok:
  message = str(status.error)
 elif status.count > 0:
  message = "This world is used by %d saved game%s.\nIt cannot be deleted." % [status.count, "" if status.count == 1 else "s"]
 else:
  message = ""
  delete_target = entries[world_index]
 show_page()

func _start_generation(seed: String = "") -> void:
 if job_thread != null or page != 0 or not delete_target.is_empty(): return
 if seed.is_empty(): seed = "world-" + Crypto.new().generate_random_bytes(16).hex_encode()
 job_is_generation = true
 job_phase = "Building geography and settlements…"
 job_thread = Thread.new()
 if job_thread.start(_generate_worker.bind(seed)) != OK:
  job_thread = null
  message = "World generation could not be started. Please retry."
 show_page()

func _start_preview_rebuild(entry: Dictionary) -> void:
 if job_thread != null: return
 job_is_generation = false
 job_phase = "Rebuilding the map preview…"
 job_thread = Thread.new()
 if job_thread.start(_preview_worker.bind(entry)) != OK:
  job_thread = null
  message = "Map preparation could not be started. Please retry."
 show_page()

func _set_phase(text: String) -> void:
 job_mutex.lock()
 job_phase = text
 job_mutex.unlock()

func _generate_worker(seed: String) -> Dictionary:
 var stage := library.create_staging()
 if not stage.ok: return stage
 var generated := library.run_generator(stage.directory, seed)
 if not generated.ok:
  library._remove_flat_directory(stage.directory)
  return generated
 _set_phase("Preparing map…")
 return library.import_generated(stage.directory)

func _preview_worker(entry: Dictionary) -> Dictionary:
 if not library.build_preview(entry.directory, entry.raw, entry.world.source_sha256):
  return {"ok": false, "error": "The map preview could not be rebuilt. Please retry."}
 return {"ok": true, "entry": entry}

func _show_working() -> void:
 for child in left.get_children():
  left.remove_child(child)
  child.queue_free()
 title.text = "Generating world…" if job_is_generation else "Preparing map…"
 working_label = _label(job_phase)
 left.add_child(working_label)
 left.add_child(_label("Please wait. Your existing worlds and saves remain available afterward."))
 back_button.disabled = true
 next_button.disabled = true
 map.visible = false
 facts.text = ""

func _process(_delta: float) -> void:
 if job_thread == null: return
 if job_thread.is_alive():
  job_mutex.lock()
  var text := job_phase
  job_mutex.unlock()
  if is_instance_valid(working_label): working_label.text = text
  return
 var result: Dictionary = job_thread.wait_to_finish()
 job_thread = null
 back_button.disabled = false
 message = "World created." if result.ok and job_is_generation else ("" if result.ok else str(result.error))
 var selected_id: String = str(result.entry.id) if result.ok else str(entries[world_index].id)
 _reload_library(selected_id)
 page = 0
 show_page()

func _exit_tree() -> void:
 # No unsafe cancellation: helper is bounded to 120s; wait before freeing resources.
 if job_thread != null:
  job_thread.wait_to_finish()
  job_thread = null
