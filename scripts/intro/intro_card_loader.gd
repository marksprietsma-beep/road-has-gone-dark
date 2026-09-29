class_name IntroCardLoader
extends RefCounted


static func load_cards(file_path: String) -> Array[Dictionary]:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Could not open intro card data at %s" % file_path)
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("Intro card data must contain a JSON array")
		return []

	var cards: Array[Dictionary] = []
	for entry: Variant in parsed:
		if entry is Dictionary and entry.has("body"):
			cards.append(entry)
		else:
			push_warning("Ignoring an intro card without a body")
	return cards
