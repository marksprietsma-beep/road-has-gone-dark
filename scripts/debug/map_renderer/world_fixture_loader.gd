class_name WorldFixtureLoader
extends RefCounted

## Owns the canonical JSON boundary for the development map viewer.

func load_fixture(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open fixture: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Fixture is not a JSON object: %s" % path)
		return {}
	var fixture := parsed as Dictionary
	if int(fixture.get("schemaVersion", -1)) != 1 or not fixture.get("cells", null) is Dictionary:
		push_error("Unsupported generated-world fixture schema")
		return {}
	return fixture
