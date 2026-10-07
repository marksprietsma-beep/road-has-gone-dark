class_name GameUI
extends RefCounted
## Shared presentation vocabulary. No world, campaign or gameplay dependencies.
const BODY := 14
const META := 12
const SECTION := 16
const TITLE := 22
const GAP := 8
const MARGIN := 12
const INK := Color("ded8c8")
const MUTED := Color("afa88f")
const GOLD := Color("e9c66d")
const ERROR := Color("efab92")
static var _theme: Theme

static func box(fill: Color, border := Color.TRANSPARENT, width := 0) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = fill
 style.border_color = border
 style.set_border_width_all(width)
 style.content_margin_left = 8
 style.content_margin_right = 8
 style.content_margin_top = 4
 style.content_margin_bottom = 4
 return style

static func shared_theme() -> Theme:
 if _theme != null: return _theme
 _theme = preload("res://themes/menu_theme.tres").duplicate()
 _theme.default_font_size = BODY
 var quiet := box(Color("111210"))
 var selected := box(Color("343022"), Color("81704a"), 1)
 var focus := box(Color.TRANSPARENT, GOLD, 1)
 focus.draw_center = false
 var hover := box(Color("22241f"))
 for type in ["Button", "OptionButton", "LineEdit", "PopupMenu", "ItemList", "TabContainer"]:
  _theme.set_font_size("font_size", type, BODY)
  _theme.set_color("font_color", type, INK)
  _theme.set_color("font_hover_color", type, GOLD)
  _theme.set_color("font_focus_color", type, GOLD)
  _theme.set_color("font_pressed_color", type, GOLD)
  _theme.set_color("font_selected_color", type, GOLD)
  _theme.set_color("font_disabled_color", type, Color("777565"))
  _theme.set_stylebox("normal", type, quiet)
  _theme.set_stylebox("panel", type, quiet)
  _theme.set_stylebox("focus", type, focus)
  _theme.set_stylebox("hover", type, hover)
  _theme.set_stylebox("pressed", type, selected)
  _theme.set_stylebox("disabled", type, box(Color("0b0c0a")))
 _theme.set_stylebox("selected", "ItemList", selected)
 _theme.set_stylebox("selected_focus", "ItemList", selected)
 _theme.set_constant("v_separation", "ItemList", 4)
 _theme.set_stylebox("tab_selected", "TabContainer", selected)
 _theme.set_stylebox("tab_unselected", "TabContainer", quiet)
 _theme.set_stylebox("tab_hovered", "TabContainer", hover)
 _theme.set_color("font_color", "Label", INK)
 for definition in [["ScreenTitle", TITLE, GOLD], ["SectionTitle", SECTION, GOLD], ["Metadata", META, MUTED], ["MenuTitle", 28, GOLD]]:
  _theme.set_type_variation(definition[0], "Label")
  _theme.set_font_size("font_size", definition[0], definition[1])
  _theme.set_color("font_color", definition[0], definition[2])
 _theme.set_type_variation("PrimaryAction", "Button")
 _theme.set_stylebox("normal", "PrimaryAction", box(Color("332c1d"), Color("a18a54"), 1))
 _theme.set_color("font_color", "PrimaryAction", GOLD)
 _theme.set_type_variation("QuietAction", "Button")
 _theme.set_stylebox("normal", "QuietAction", box(Color.TRANSPARENT))
 _theme.set_type_variation("ChoiceRow", "Button")
 _theme.set_stylebox("normal", "ChoiceRow", box(Color("10120f")))
 _theme.set_type_variation("StatusBadge", "PanelContainer")
 _theme.set_stylebox("panel", "StatusBadge", box(Color("24271f")))
 _theme.set_constant("separation", "HBoxContainer", GAP)
 _theme.set_constant("separation", "VBoxContainer", GAP)
 return _theme

static func install(screen: Control) -> void:
 screen.theme = shared_theme()
 var responsive := preload("res://scripts/ui/components/responsive_canvas.gd").new()
 screen.add_child(responsive)

static func label(text: String, font := BODY) -> Label:
 var result := Label.new()
 result.text = text
 result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 result.theme_type_variation = "ScreenTitle" if font >= TITLE else ("SectionTitle" if font >= SECTION else ("Metadata" if font <= META else "Label"))
 return result

static func action(text: String, callback: Callable, primary := false) -> Button:
 var result := Button.new()
 result.text = text
 result.theme_type_variation = "PrimaryAction" if primary else "QuietAction"
 result.custom_minimum_size.y = 28
 result.pressed.connect(callback)
 return result

static func spacer() -> Control:
 var result := Control.new()
 result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return result

static func badge(text: String) -> PanelContainer:
 var result := PanelContainer.new()
 result.theme_type_variation = "StatusBadge"
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 result.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 var caption := label(text, META)
 caption.autowrap_mode = TextServer.AUTOWRAP_OFF
 caption.add_theme_color_override("font_color", GOLD)
 result.add_child(caption)
 return result

static func row(text: String, status: String, callback: Callable) -> Button:
 var result := preload("res://scripts/ui/components/choice_row.gd").new()
 result.configure(text, status)
 result.pressed.connect(callback)
 return result

static func section(title: String) -> VBoxContainer:
 var result := VBoxContainer.new()
 result.add_child(label(title, SECTION))
 return result
