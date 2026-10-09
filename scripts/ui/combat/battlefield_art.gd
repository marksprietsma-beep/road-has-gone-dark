class_name BattlefieldArt
extends RefCounted
## Art stays outside the board pin. Painting cannot change any tile's legality.
const SOURCE := "res://data/combat/battlefields/old-road-presentation-v1.json"
static var _layouts := {}
static func profile(battle: Dictionary) -> Dictionary:
 if _layouts.is_empty():_layouts=JSON.parse_string(FileAccess.get_file_as_string(SOURCE)).layouts
 return _layouts.get(CombatBattlefields.identify(battle),{}).duplicate(true)
static func cell(profile: Dictionary,p: Array) -> Dictionary:
 var ground := "g";var feature := ""
 var rows: Array=profile.get("ground",[])
 if int(p[1])<rows.size() and int(p[0])<str(rows[int(p[1])]).length():ground=str(rows[int(p[1])])[int(p[0])]
 for item in profile.get("features",[]):
  if int(item.at[0])==int(p[0]) and int(item.at[1])==int(p[1]):feature=item.kind;break
 return {"ground":ground,"feature":feature}
