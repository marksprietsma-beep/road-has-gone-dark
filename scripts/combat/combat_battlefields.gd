class_name CombatBattlefields
extends RefCounted
## Registered, immutable mechanical layouts. Historical pins are never migrated.
const LEGACY := "legacy-8x6-v1"
const DEFAULT := "old-road-12x8-v1"
const PATHS := {
 LEGACY:"res://data/combat/first-road-encounter.json",
 "old-road-10x8-v1":"res://data/combat/battlefields/old-road-10x8-v1.json",
 DEFAULT:"res://data/combat/battlefields/old-road-12x8-v1.json"}
static var _definitions := {}
static func definition(id: String) -> Dictionary:
 if not PATHS.has(id):return {}
 if not _definitions.has(id):_definitions[id]=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string(PATHS[id])))
 return _definitions[id].duplicate(true)
static func identify(battle: Dictionary) -> String:
 for id in PATHS:
  if battle.get("encounter_sha")==FileAccess.get_sha256(PATHS[id]) and RulesJson.normalize(battle.get("board",{}))==definition(id):return id
 return ""
static func valid_definition(board: Dictionary) -> bool:
 if not board.has_all(["id","title","width","height","blocked","party_positions","enemies"]):return false
 if not RulesJson.integer(board.width,8,12) or not RulesJson.integer(board.height,6,8):return false
 if board.id!="first-road-v1" or not [Vector2i(8,6),Vector2i(10,8),Vector2i(12,8)].has(Vector2i(board.width,board.height)):return false
 if not board.blocked is Array or not board.party_positions is Array or board.party_positions.size()!=3 or not board.enemies is Array or board.enemies.size()!=2:return false
 var seen := {}
 for p in board.blocked:
  if not valid_position(board,p) or seen.has(str(p)):return false
  seen[str(p)]=true
 for p in board.party_positions+board.enemies.map(func(e: Dictionary):return e.position):
  if not valid_position(board,p) or seen.has(str(p)):return false
  seen[str(p)]=true
 return true
static func valid_position(board: Dictionary,p: Variant) -> bool:
 return p is Array and p.size()==2 and RulesJson.integer(p[0],0,int(board.width)-1) and RulesJson.integer(p[1],0,int(board.height)-1)
