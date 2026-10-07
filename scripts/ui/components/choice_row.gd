extends Button
## One keyboard/mouse target, with a separate status rather than a long button label.
func configure(caption: String, status: String) -> void:
 theme_type_variation = "ChoiceRow"
 custom_minimum_size.y = 30
 tooltip_text = caption + (" · " + status if not status.is_empty() else "")
 var layout := HBoxContainer.new()
 layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
 layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layout.offset_left = 8
 layout.offset_right = -8
 layout.offset_top = 4
 layout.offset_bottom = -4
 add_child(layout)
 var title := GameUI.label(caption)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title.autowrap_mode = TextServer.AUTOWRAP_OFF
 title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 layout.add_child(title)
 if not status.is_empty(): layout.add_child(GameUI.badge(status))
