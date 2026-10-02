class_name MapLandmarkKey
extends PanelContainer

## Retired the huge art-trial sheet; this legend stays collapsed by default.
## It is a reference for the 36 *official* Azgaar marker meanings, not a
## quest-discovery screen. Hidden game-world sites must remain a separate model.
signal show_overlaps_changed(show: bool)

const GROUPS := [
	{"title": "NATURE & SACRED", "types": ["volcanoes", "hot-springs", "water-sources", "waterfalls", "sacred-mountains", "sacred-forests", "sacred-pineries", "sacred-palm-groves", "mirage"]},
	{"title": "ROUTES & PLACES", "types": ["mines", "bridges", "inns", "lighthouses", "canoes", "statues", "ruins", "libraries", "caves"]},
	{"title": "DANGERS & MYSTERIES", "types": ["battlefields", "dungeons", "lake-monsters", "sea-monsters", "hill-monsters", "brigands", "pirates", "portals", "rifts", "disturbed-burials", "necropolises", "encounters"]},
	{"title": "TRAVELLERS & EVENTS", "types": ["circuses", "jousts", "fairs", "migration", "dances", "party"]},
]
const DESCRIPTIONS := {
	"volcanoes": "Dormant or active volcanic cones.",
	"hot-springs": "Naturally heated geothermal pools.",
	"water-sources": "Noteworthy or enchanted springs and wells.",
	"waterfalls": "Named cascades along rivers.",
	"sacred-mountains": "Sites of worship in high country.",
	"sacred-forests": "Holy or legendary woodland.",
	"sacred-pineries": "Sacred conifer groves.",
	"sacred-palm-groves": "Tropical sacred groves.",
	"mirage": "Illusory sights drawing travellers astray.",
	"mines": "Mineral extraction sites.",
	"bridges": "Important crossings.",
	"inns": "Roadside lodging and taverns.",
	"lighthouses": "Coastal navigation beacons.",
	"canoes": "Minor river jetties and crossings.",
	"statues": "Monuments and ancient sculptures.",
	"ruins": "Remains of former settlements.",
	"libraries": "Repositories of knowledge and lore.",
	"caves": "Natural underground passages.",
	"battlefields": "Historic battle locations.",
	"dungeons": "Dangerous or mysterious complexes.",
	"lake-monsters": "Dangerous creatures in inland waters.",
	"sea-monsters": "Creatures lurking at sea.",
	"hill-monsters": "Threats inhabiting the highlands.",
	"brigands": "Outlaws and bandit activity.",
	"pirates": "Sea raiders and their haunts.",
	"portals": "Supernatural passages.",
	"rifts": "Tears between worlds or planes.",
	"disturbed-burials": "Restless dead and disturbed graves.",
	"necropolises": "Large cities of the dead.",
	"encounters": "Unusual travellers and events.",
	"circuses": "Travelling performers.",
	"jousts": "Tournaments and martial contests.",
	"fairs": "Markets and seasonal gatherings.",
	"migration": "Moving groups of wild animals.",
	"dances": "Local celebrations and gatherings.",
	"party": "The generated party waypoint.",
}
const CLOSED_BOTTOM := 134.0
const OPEN_BOTTOM := 504.0

@onready var toggle_button: Button = $Layout/Toggle
@onready var scroll: ScrollContainer = $Layout/Scroll
@onready var entries: VBoxContainer = $Layout/Scroll/Entries

func _ready() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.055, 0.045, 0.035, 0.94)
	panel.set_content_margin_all(7.0)
	add_theme_stylebox_override("panel", panel)
	mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.visible = false
	offset_bottom = CLOSED_BOTTOM
	toggle_button.pressed.connect(_toggle)

func set_icon_provider(provider: MapIconProvider) -> void:
	for child in entries.get_children():
		child.queue_free()
	var help := _text("Crowded symbols are filtered, not deleted. Turn off Labels or Settlements to expose obscured sites.", 10, Color("#b9ac92"))
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entries.add_child(help)
	var all := CheckBox.new()
	all.text = "Show all overlaps (QA)"
	all.tooltip_text = "Disable decluttering temporarily to inspect every generated marker."
	all.add_theme_font_size_override("font_size", 11)
	all.toggled.connect(func(on: bool) -> void: show_overlaps_changed.emit(on))
	entries.add_child(all)
	for group in GROUPS:
		var section := _text(str(group["title"]), 12, Color("#ead1a0"))
		entries.add_child(HSeparator.new())
		entries.add_child(section)
		for kind in group["types"]:
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(0.0, 43.0)
			row.add_theme_constant_override("separation", 7)
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(25.0, 25.0)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var role := str(LandmarkMapLayer.EXISTING_ROLE_ALIASES.get(kind, kind))
			icon.texture = provider.texture_for(role)
			row.add_child(icon)
			var text_col := VBoxContainer.new()
			text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_col.add_theme_constant_override("separation", 0)
			var heading := _text(str(kind).replace("-", " ").capitalize(), 11, Color("#efdfb9"))
			text_col.add_child(heading)
			var note := _text(str(DESCRIPTIONS.get(kind, "")), 10, Color("#b9ac92"))
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_col.add_child(note)
			row.add_child(text_col)
			row.tooltip_text = str(kind) + ": " + str(DESCRIPTIONS.get(kind, ""))
			entries.add_child(row)

func _toggle() -> void:
	scroll.visible = not scroll.visible
	# "Show all" is diagnostic: closing the glossary restores the readable
	# default, so an old QA toggle cannot silently leave the map cluttered.
	if not scroll.visible and entries.get_child_count() > 1:
		var qa := entries.get_child(1) as CheckBox
		if qa:
			qa.button_pressed = false
	offset_bottom = OPEN_BOTTOM if scroll.visible else CLOSED_BOTTOM
	toggle_button.text = "MAP KEY  ▾" if scroll.visible else "MAP KEY  ▸"

func _text(value: String, size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", ink)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
