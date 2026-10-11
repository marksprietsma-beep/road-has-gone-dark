class_name MapIconRoles
extends RefCounted
## Presentation only. Shared JSON is consumed by Godot and the Node map renderer.
const SOURCE := "res://data/map_icons/semantic-roles-v1.json"
static var _data: Dictionary = {}
static func data() -> Dictionary:
 if _data.is_empty():
  var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
  if parsed is Dictionary and parsed.get("schema_version")==1: _data=parsed
 return _data
static func settlement(record: Dictionary) -> String:
 var group: String=str(record.get("group",""))
 if data().settlement_aliases.has(group): return str(data().settlement_aliases[group])
 if group in data().settlement_roles: return group
 return "capital" if int(record.get("capital",0))==1 else "town"
static func marker(kind: String) -> String:
 return str(data().marker_aliases.get(kind,kind)) if kind in MapIconProvider.MARKER_TYPES else str(data().fallback)
static func site(kind: String) -> String:
 return str(data().site_roles.get(kind,data().fallback))
static func home(record: Dictionary) -> Dictionary:
 return {"name":str(record.get("name","Hometown")),"role":settlement(record),"provenance":"Azgaar source settlement"}
