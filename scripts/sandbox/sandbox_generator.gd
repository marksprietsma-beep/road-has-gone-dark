class_name SandboxGenerator
extends RefCounted
## Pure, versioned composition. Never reads campaign RNG or writes a save.
const VERSION := "sandbox-spine-v1"
const SOURCE := "res://data/sandbox/generation-v1.json"
static var _rules := {}
static var _boards := {}
static func rules() -> Dictionary:
 if _rules.is_empty():_rules=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string(SOURCE)))
 return _rules
static func pick(seed: String,domain: String,count: int) -> int:
 return (seed+":"+domain).sha256_text().left(7).hex_to_int()%count
static func nearest_route(world: GameWorldTemplate,point: Array,cell: int) -> Dictionary:
 var best := {"id":-1,"distance":1000000.0}
 for route in world._raw.routes:
  if not route is Dictionary or route.get("group") not in ["roads","trails"] or not route.get("points") is Array or route.get("hidden",false) or route.get("removed",false):continue
  if not route.points.any(func(p: Array):return p.size()>2 and int(p[2])==cell):continue
  for i in range(1,route.points.size()):
   var a := Vector2(route.points[i-1][0],route.points[i-1][1]);var b := Vector2(route.points[i][0],route.points[i][1])
   var distance := Vector2(point[0],point[1]).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(point[0],point[1]),a,b))
   if distance<float(best.distance):best={"id":int(route.i),"distance":distance}
 return best
static func generate(world: GameWorldTemplate,home_id: int,content: Dictionary) -> Dictionary:
 var home := world.get_record("burg",home_id);var cell := world.get_record("cell",int(home.cell))
 var biome := str(world.get_record("biome",int(cell.biome)).get("name","Unclassified land"))
 var environment := "forest" if "forest" in biome.to_lower() else "dry" if "desert" in biome.to_lower() or "savanna" in biome.to_lower() else "upland" if int(cell.get("heights",20))>=60 else "grass"
 var seed := RulesJson.digest([VERSION,FileAccess.get_sha256(SOURCE),world.source_sha256,home_id,int(home.cell),content.sha])
 var sites: Array=[]
 for i in int(rules().opportunity_count):
  var slot := (i+pick(seed,"placement-offset",8))%8
  var placement: Dictionary=content.sites[slot]
  var id := "sandbox-site:"+RulesJson.digest([VERSION,world.world_id,home_id,int(home.cell),slot])
  var local_seed := RulesJson.digest([seed,id])
  var route := nearest_route(world,placement.world_position,int(home.cell))
  var kind: String=["camp","ruins","clearing","roadside"][i]
  if kind=="roadside" and float(route.distance)>2.0:kind=["camp","clearing"][pick(local_seed,"fallback-site",2)]
  var names := {"camp":"Secluded camp","ruins":"Broken work-yard","clearing":"Hostile clearing","roadside":"Roadside obstruction"}
  var reasons := {"camp":"Shelter and abandoned supplies make this patch useful to armed travellers.","ruins":"A disused work-yard offers shelter and stone worth scavenging.","clearing":"A local opening offers a vantage point and space to gather supplies.","roadside":"The source route passes near this position; armed travellers exploit its approach."}
  var threats := {"camp":"A small armed group has occupied the shelter.","ruins":"Armed scavengers dispute access to the remaining work.","clearing":"Hostile lookouts watch the approach.","roadside":"Armed travellers obstruct passage near the route."}
  var recipe := {"version":VERSION,"rules_sha":FileAccess.get_sha256(SOURCE),"seed":local_seed,"site_id":id,"kind":kind,"environment":environment,"composition":pick(local_seed,"opponents",rules().compositions.size())}
  var board := battlefield(recipe)
  if board.is_empty():return {}
  sites.append({"id":id,"opportunity_id":"opportunity:"+RulesJson.digest([VERSION,id]),"name":str(names[kind])+" · "+str(i+1),"kind":kind,"position":placement.position.duplicate(),"world_position":placement.world_position.duplicate(),"description":str(reasons[kind])+" "+str(threats[kind]),"reward":"10 journey XP per companion on victory; the site stays resolved.","context":{"home_id":home_id,"cell_id":int(home.cell),"region_id":int(cell.get("province",0)),"biome":biome,"environment":environment,"route_ref":int(route.id) if kind=="roadside" else -1,"placement_ref":placement.id,"placement_slot":slot,"source":"Verified GAME-62/84 original-cell-owned dry land; fine terrain and occupation inferred/generated, not canonical Azgaar history."},"provenance":{"version":VERSION,"seed":local_seed,"world_sha":world.source_sha256,"content_sha":content.sha,"rules_sha":FileAccess.get_sha256(SOURCE),"authorship":"TRHGD generated local fiction"},"board":board})
 return {"version":VERSION,"seed":seed,"world_ref":world.world_ref.duplicate(true),"home_id":home_id,"cell_id":int(home.cell),"content_sha":content.sha,"home_position":content.home_position.duplicate(),"sites":sites}
static func battlefield(recipe: Dictionary) -> Dictionary:
 if not recipe.has_all(["version","rules_sha","seed","site_id","kind","environment","composition"]) or recipe.version!=VERSION or recipe.rules_sha!=FileAccess.get_sha256(SOURCE) or not recipe.seed is String or recipe.seed.length()!=64 or not recipe.kind in ["camp","ruins","clearing","roadside"] or not recipe.environment in ["forest","grass","dry","upland"] or not RulesJson.integer(recipe.composition,0,rules().compositions.size()-1):return {}
 var key := RulesJson.digest(recipe)
 if _boards.has(key):return _boards[key].duplicate(true)
 for attempt in int(rules().max_attempts):
  var b := candidate(recipe,attempt)
  if not geometry_error(b).is_empty():continue
  _boards[key]=b
  return b.duplicate(true)
 return {}
static func candidate(recipe: Dictionary,attempt: int) -> Dictionary:
 var seed: String=recipe.seed+":attempt:"+str(attempt)
 var dimensions: Array=rules().sizes[pick(seed,"size",rules().sizes.size())]
 var w: int=dimensions[0];var h: int=dimensions[1]
 var middle: int=2+pick(seed,"approach-row",h-4);var left: int=w/2-3
 var party := [[left,middle-1],[left,middle],[left-1,middle+1]]
 var composition: Array=rules().compositions[int(recipe.composition)]
 var enemies: Array=[]
 for i in composition.size():
  var bow: bool=composition[i]=="bow"
  enemies.append({"id":str(recipe.site_id)+":opponent:"+str(i+1),"name":"Hostile lookout" if bow else "Armed scavenger","role":"scout" if bow else "vanguard","weapon":"bow" if bow else "shortblade","position":[left+(4 if w==8 else 5),middle if composition.size()==1 else middle-1+i]})
 var rows: Array=[];var features: Array=[];var blocked: Array=[]
 var ground: String="d" if recipe.environment=="dry" else "u" if recipe.environment=="upland" else "g"
 for y in h:rows.append(ground.repeat(w))
 # Composed corridors, courtyards and clusters, not independent noisy tiles.
 if recipe.kind=="roadside":
  rows[middle-1]="r".repeat(w);rows[middle]="r".repeat(w)
 elif recipe.kind=="ruins":
  for y in range(middle-1,mini(h,middle+2)):
   var row: String=rows[y]
   for x in range(1,w-1):row[x]="p"
   rows[y]=row
 elif recipe.kind=="camp":
  features.append({"kind":"campfire","at":[w/2,middle+1]})
 var reserved: Array=party+enemies.map(func(e: Dictionary):return e.position)
 for index in 3:
  var kind: String="broken_wall" if recipe.kind=="ruins" and index<2 else "grove" if recipe.environment=="forest" else "boulder"
  var shape: Array=rules().pieces[kind]
  var anchor := [2+pick(seed,"piece-x:"+str(index),w-4),pick(seed,"piece-y:"+str(index),h-2)]
  for offset in shape:
   var p := [anchor[0]+offset[0],anchor[1]+offset[1]]
   if p[0]>=w or p[1]>=h or reserved.has(p) or blocked.has(p) or p[1] in range(middle-1,middle+2):continue
   blocked.append(p);features.append({"kind":"wall" if kind=="broken_wall" else "tree" if kind=="grove" else "rock","at":p.duplicate()})
 # Keep three connected approach lanes compatible with the existing greedy AI.
 # A single pillar interrupts ranged sightlines without enclosing a combatant.
 if pick(seed,"approach-pillar",3)>0:
  var pillar := [left+2+pick(seed,"pillar-column",2),middle]
  blocked.append(pillar);features.append({"kind":"wall" if recipe.kind=="ruins" else "rock","at":pillar.duplicate()})
 features.append({"kind":"cart" if recipe.kind in ["camp","roadside"] else "rubble" if recipe.kind=="ruins" else "scrub","at":[0,h-1]})
 # 180-degree deployment reversal changes approaches without changing tile rules.
 if pick(seed,"deployment-side",2)==1:
  for p in party+blocked:p[0]=w-1-p[0];p[1]=h-1-p[1]
  for enemy in enemies:enemy.position=[w-1-enemy.position[0],h-1-enemy.position[1]]
  for feature in features:feature.at=[w-1-feature.at[0],h-1-feature.at[1]]
  rows.reverse()
  for y in rows.size():rows[y]=str(rows[y]).reverse()
 blocked.sort_custom(func(a: Array,b: Array):return a[1]<b[1] if a[1]!=b[1] else a[0]<b[0])
 return {"id":"encounter:"+RulesJson.digest([VERSION,recipe.site_id]),"title":{"camp":"Skirmish at the camp","ruins":"Scavengers in the broken yard","clearing":"Lookouts in the clearing","roadside":"Threat near the source road"}[recipe.kind],"width":w,"height":h,"blocked":blocked,"party_positions":party,"enemies":enemies,"generation":recipe.duplicate(true),"attempt":attempt,"presentation":{"ground":rows,"features":features,"environment":recipe.environment}}
static func geometry_error(b: Dictionary) -> String:
 var seen := {};var positions: Array=b.party_positions+b.enemies.map(func(e: Dictionary):return e.position)
 for p in positions:
  if not CombatBattlefields.valid_position(b,p) or b.blocked.has(p) or seen.has(str(p)):return "invalid spawn"
  seen[str(p)]=true
 var paths := flood(b,positions[0])
 if paths.size()!=int(b.width)*int(b.height)-b.blocked.size():return "disconnected walkable area"
 for p in b.party_positions:
  var from := flood(b,p);var nearest := 1000
  for enemy in b.enemies:nearest=mini(nearest,int(from.get(str(enemy.position),1000)))
  if nearest>7:return "excessive approach distance"
 return ""
static func flood(b: Dictionary,start: Array) -> Dictionary:
 var found := {str(start):0};var queue: Array=[start];var cursor := 0
 while cursor<queue.size():
  var p: Array=queue[cursor];cursor+=1
  for n in [[p[0],p[1]-1],[p[0]-1,p[1]],[p[0]+1,p[1]],[p[0],p[1]+1]]:
   if not CombatBattlefields.valid_position(b,n) or b.blocked.has(n) or found.has(str(n)):continue
   found[str(n)]=int(found[str(p)])+1;queue.append(n)
 return found
static func valid_board(board: Dictionary) -> bool:
 if not board.get("generation") is Dictionary:return false
 var expected := battlefield(board.generation)
 return not expected.is_empty() and RulesJson.normalize(board)==expected
