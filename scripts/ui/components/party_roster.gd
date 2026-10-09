class_name PartyRoster
extends VBoxContainer
## Three compact choice rows; native ItemList left icons cannot show two text lines.
signal item_selected(index: int)
var selected_index := -1
var rows: Array[Button]=[]
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL
 add_theme_constant_override("separation",4)
func clear() -> void:
 for child in get_children():remove_child(child);child.queue_free()
 rows=[];selected_index=-1
func add_item(caption: String,icon: Texture2D) -> void:
 var index := rows.size();var parts := caption.split("\n")
 var button := Button.new();button.custom_minimum_size.y=56;button.focus_mode=Control.FOCUS_NONE
 button.pressed.connect(func():if mouse_filter!=Control.MOUSE_FILTER_IGNORE:item_selected.emit(index))
 add_child(button);rows.append(button)
 var line := HBoxContainer.new();line.mouse_filter=Control.MOUSE_FILTER_IGNORE
 line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);line.offset_left=6;line.offset_right=-6;line.offset_top=4;line.offset_bottom=-4
 button.add_child(line)
 var portrait := TextureRect.new();portrait.texture=icon;portrait.custom_minimum_size=Vector2(48,48);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 line.add_child(portrait)
 var labels := VBoxContainer.new();labels.add_theme_constant_override("separation",1);labels.size_flags_horizontal=Control.SIZE_EXPAND_FILL;labels.mouse_filter=Control.MOUSE_FILTER_IGNORE
 line.add_child(labels)
 var title := GameUI.label(parts[0],14);title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;labels.add_child(title)
 var details := GameUI.label(parts[1] if parts.size()>1 else "",12);details.custom_minimum_size.y=28;details.max_lines_visible=2;details.clip_text=true;labels.add_child(details)
func set_item_tooltip(index: int,value: String) -> void:rows[index].tooltip_text=value
func get_item_rect(index: int) -> Rect2:return Rect2(rows[index].position,rows[index].size)
func get_item_count() -> int:return rows.size()
func select(index: int) -> void:
 selected_index=index
 for i in rows.size():
  rows[i].add_theme_stylebox_override("normal",GameUI.box(Color("343022") if i==index else Color("10120f"),GameUI.GOLD if i==index else Color.TRANSPARENT,1))
func set_enabled(value: bool) -> void:
 for row in rows:row.disabled=not value
func _gui_input(event: InputEvent) -> void:
 if mouse_filter==Control.MOUSE_FILTER_IGNORE:return
 var next := selected_index
 if event.is_action_pressed("ui_down"):next=mini(rows.size()-1,selected_index+1)
 elif event.is_action_pressed("ui_up"):next=maxi(0,selected_index-1)
 else:return
 accept_event()
 if next!=selected_index:item_selected.emit(next)
