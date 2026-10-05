class_name OriginContext
extends RefCounted
## Read-only analysis of GAME-7 identity + GAME-76 validated canonical snapshot.
const BIOME_WORDS := {"Hot desert":"Hot desert", "Cold desert":"Cold desert", "Savanna":"Savanna", "Grassland":"Grassland", "Tropical seasonal forest":"Tropical woodland", "Temperate deciduous forest":"Temperate woodland", "Tropical rainforest":"Tropical rainforest", "Temperate rainforest":"Rainforest", "Taiga":"Taiga", "Tundra":"Tundra", "Glacier":"Glacier", "Wetland":"Wetland"}
var world_id := ""
var source: Dictionary
var cells: Dictionary
var biomes := {}
var features := {}
var towns: Array[Dictionary] = []
var by_id := {}
var roads := {}
var trails := {}
var positions := {}
var radius := -1.0
var _cache := {}
var _densities := {}

func _init(world: GameWorldTemplate, snapshot: Dictionary) -> void:
 world_id = world.world_id
 source = snapshot.duplicate(true)
 source.erase("markers")
 cells = source.get("cells", {})
 for biome in source.get("biomes", []):
  if biome is Dictionary: biomes[int(biome.i)] = biome
 for feature in source.get("map", {}).get("geography", []):
  if feature is Dictionary: features[int(feature.i)] = feature
 for value in source.get("settlements", []):
  if not value is Dictionary or int(value.get("i", 0)) <= 0 or value.get("hidden", false) or value.get("removed", false) or float(value.get("population", 0)) <= 0: continue
  towns.append(value)
  by_id[int(value.i)] = value
  positions[int(value.i)] = Vector2(float(value.x), float(value.y))
 towns.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.i) < int(b.i))
 _index_routes()
 _measure_neighbours()

func _recorded_port(town: Dictionary) -> bool:
 var value: Variant = town.get("port")
 return (value is int or value is float) and float(value)>0

func _land(cell: int) -> bool:
 return cell >= 0 and cell < cells.ids.size() and float(cells.heights[cell]) >= 20

func _feature(cell: int) -> int:
 if not _land(cell): return -1
 var id := int(cells.features[cell])
 return id if features.get(id, {}).get("land", false) else -1

func water(cell: int) -> String:
 if not _land(cell): return "Unknown"
 var lake := false
 var unknown_water := false
 for neighbor in cells.neighbors[cell]:
  var n := int(neighbor)
  if n < 0 or n >= cells.ids.size() or _land(n): continue
  var feature: Dictionary = features.get(int(cells.features[n]), {})
  if feature.get("type") == "ocean": return "Coastal"
  if feature.get("type") == "lake": lake = true
  if not ["ocean", "lake"].has(feature.get("type")): unknown_water = true
 return "Lake shores" if lake else ("Unknown" if unknown_water else "Inland")

func _index_routes() -> void:
 var towns_by_cell := {}
 for town in towns:
  var cell := int(town.cell)
  if not towns_by_cell.has(cell): towns_by_cell[cell] = []
  towns_by_cell[cell].append(int(town.i))
 for route in source.get("routes", []):
  if not route is Dictionary or route.get("hidden", false) or route.get("removed", false) or not ["roads", "trails"].has(route.get("group")): continue
  for point in route.get("points", []):
   if not point is Array or point.size() < 3 or float(point[2]) != int(point[2]): continue
   for id in towns_by_cell.get(int(point[2]), []):
    if positions[id].distance_to(Vector2(float(point[0]), float(point[1]))) > 0.02: continue
    var index: Dictionary = roads if route.group == "roads" else trails
    if not index.has(id): index[id] = []
    if not index[id].has(int(route.i)): index[id].append(int(route.i))
 for index in [roads, trails]:
  for id in index: index[id].sort()

func _measure_neighbours() -> void:
 var grouped := {}
 var nearest := {}
 for town in towns:
  var feature := _feature(int(town.cell))
  if feature < 0: continue
  if not grouped.has(feature): grouped[feature] = []
  grouped[feature].append(int(town.i))
 for group in grouped.values():
  for a in group.size():
   for b in range(a + 1, group.size()):
    var distance: float = positions[group[a]].distance_to(positions[group[b]])
    nearest[group[a]] = minf(float(nearest.get(group[a], INF)), distance)
    nearest[group[b]] = minf(float(nearest.get(group[b], INF)), distance)
 var values: Array = nearest.values()
 values.sort()
 if not values.is_empty():
  var mid := values.size() / 2
  radius = 2.0 * (float(values[mid]) if values.size() % 2 else (float(values[mid - 1]) + float(values[mid])) / 2.0)

func _output(lines: Array, tags: Array, facts: Dictionary, rules: Array) -> Dictionary:
 return {"summary": "\n".join(lines), "tags": tags, "facts": facts, "rules": rules, "world_id": world_id}

func _area_facts(state: int = -1, province: int = -1) -> Dictionary:
 var totals := {}
 var land_area := 0.0
 var coastal := 0
 var lake := 0
 var unknown_water := 0
 var land_count := 0
 var land_features := {}
 for i in cells.ids.size():
  if not _land(i) or (state > 0 and int(cells.state[i]) != state) or (province > 0 and int(cells.province[i]) != province): continue
  var area := maxf(0.0, float(cells.area[i]))
  land_count += 1
  land_area += area
  var biome := int(cells.biome[i])
  totals[biome] = float(totals.get(biome, 0)) + area
  var feature := _feature(i)
  if feature >= 0: land_features[feature] = float(land_features.get(feature, 0)) + area
  var category := water(i)
  coastal += int(category == "Coastal")
  lake += int(category == "Lake shores")
  unknown_water += int(category == "Unknown")
 var selected: Array[Dictionary] = []
 for town in towns:
  var cell := int(town.cell)
  if not _land(cell) or (state > 0 and int(cells.state[cell]) != state) or (province > 0 and int(cells.province[cell]) != province): continue
  selected.append(town)
 var order: Array = totals.keys()
 order.sort_custom(func(a: int,b: int): return totals[a] > totals[b] if totals[a] != totals[b] else a < b)
 var landscape := "Terrain unavailable"
 if not order.is_empty():
  var name: String = str(biomes.get(order[0], {}).get("name", ""))
  landscape = str(BIOME_WORDS.get(name, name)) if not name.is_empty() else landscape
 return {"land_area":land_area,"land_cells":land_count,"coastal_cells":coastal,"lake_shore_cells":lake,"unknown_water_cells":unknown_water,"biome_areas":totals,"biome_order":order,"landscape":landscape,"land_features":land_features,"town_ids":selected.map(func(t:Dictionary):return int(t.i)),"town_count":selected.size(),"port_ids":selected.filter(func(t:Dictionary):return _recorded_port(t)).map(func(t:Dictionary):return int(t.i)),"walled_ids":selected.filter(func(t:Dictionary):return bool(t.get("walls",false))).map(func(t:Dictionary):return int(t.i)),"larger_ids":selected.filter(func(t:Dictionary):return float(t.population)>5).map(func(t:Dictionary):return int(t.i))}

func world_summary() -> Dictionary:
 if _cache.has("world"): return _cache.world.duplicate(true)
 var facts := _area_facts()
 var landscape: String = facts.landscape
 if facts.biome_order.size() > 1:
  var second: String = str(biomes.get(facts.biome_order[1], {}).get("name", ""))
  var words := str(BIOME_WORDS.get(second, second))
  if float(facts.biome_areas[facts.biome_order[1]]) >= facts.land_area * 0.15 and landscape.length() + words.length() <= 37: landscape += " / " + words
 var largest := 0.0
 for area in facts.land_features.values(): largest = maxf(largest, float(area))
 facts.largest_land_share = largest / facts.land_area if facts.land_area > 0 else 0.0
 var shape := "More than one landmass."
 if facts.largest_land_share >= 0.75: shape = "One main landmass dominates."
 elif facts.largest_land_share < 0.5: shape = "Land spread across several landmasses."
 var known_land_area := 0.0
 for area in facts.land_features.values(): known_land_area += float(area)
 if not is_equal_approx(known_land_area,float(facts.land_area)) or facts.land_features.is_empty(): shape = "Landmass context unavailable."
 var coast_count := 0
 var unknown_count := 0
 for id in facts.town_ids:
  var setting := water(int(by_id[id].cell))
  coast_count += int(setting == "Coastal")
  unknown_count += int(setting == "Unknown")
 facts.coastal_town_count = coast_count
 facts.unknown_water_town_count = unknown_count
 var coast_line := "Coastal and inland settlements."
 if facts.town_count == 0: coast_line = "No public settlements recorded."
 elif (facts.town_count - coast_count - unknown_count) * 3 >= facts.town_count * 2: coast_line = "Most towns away from the sea."
 elif coast_count * 3 >= facts.town_count * 2: coast_line = "Most towns lie along the coast."
 elif coast_count==0 or facts.town_count-coast_count-unknown_count==0: coast_line = "Coastal context unavailable."
 _cache.world = _output([landscape, shape, coast_line], [], facts, ["land-biome-area-v1", "largest-land-feature-share-v1", "public-coastal-town-share-v1"])
 return _cache.world.duplicate(true)

func _concentration(state: int, province: int, facts: Dictionary) -> String:
 facts.density_source_area = float(facts.town_count)/float(facts.land_area) if facts.land_area>0 else null
 if facts.land_area <= 0: return "Settlement context unavailable"
 if facts.town_count == 0: return "No public settlements recorded"
 var group := "province" if province > 0 else "state"
 var key := group + ":" + str(state if province > 0 else -1)
 if not _densities.has(key):
  var values: Array[float] = []
  for item in source.get("provinces" if province > 0 else "states", []):
   if not item is Dictionary or int(item.get("i",0))<=0 or item.get("removed",false) or (province > 0 and int(item.get("state",-1))!=state): continue
   var area := _area_facts(state if province > 0 else int(item.i), int(item.i) if province > 0 else -1)
   if area.land_area>0: values.append(float(area.town_count)/float(area.land_area))
  values.sort()
  _densities[key] = values
 var samples: Array = _densities[key]
 facts.peer_densities_source_area = samples.duplicate()
 if samples.size()<3 or facts.land_area<=0: return "Recorded settlements"
 var density: float = float(facts.town_count)/float(facts.land_area)
 if density < float(samples[samples.size()/3]): return "Scattered settlements"
 if density > float(samples[(samples.size()*2)/3]): return "Closely settled"
 return "Moderately settled"

func region_summary(state: int, province: int = -1) -> Dictionary:
 var key := "area:%d:%d" % [state,province]
 if _cache.has(key): return _cache[key].duplicate(true)
 var facts := _area_facts(state,province)
 facts.state_id = state
 facts.province_id = province
 facts.concentration = _concentration(state,province,facts)
 var waters := "Coastal" if facts.coastal_cells>0 else ("Lake shores" if facts.lake_shore_cells>0 else "Inland")
 if facts.land_cells == 0 or (facts.coastal_cells==0 and facts.lake_shore_cells==0 and facts.unknown_water_cells>0): waters = "Unknown"
 var tags: Array[String] = []
 if not facts.port_ids.is_empty(): tags.append("PORTS")
 if not facts.walled_ids.is_empty(): tags.append("WALLED SETTLEMENTS")
 if tags.is_empty(): tags.append("No town walls or ports recorded")
 _cache[key] = _output([str(facts.landscape)+" · "+waters, facts.concentration, " · ".join(tags)],tags,facts,["land-biome-area-v1","area-water-neighbours-v1","within-peer-density-tertiles-v1","public-burg-port-walls-v1"])
 return _cache[key].duplicate(true)

func hometown_summary(id: int) -> Dictionary:
 var key := "home:"+str(id)
 if _cache.has(key): return _cache[key].duplicate(true)
 if not by_id.has(id): return _output(["Origin context unavailable."],[],{},["nonpublic-or-unavailable"])
 var town: Dictionary = by_id[id]
 var cell := int(town.cell)
 var name := str(biomes.get(int(cells.biome[cell]),{}).get("name","Terrain unavailable"))
 var landscape := str(BIOME_WORDS.get(name,name))
 var tags: Array[String] = []
 tags.append("WALLED" if bool(town.get("walls",false)) else "No walls recorded")
 var river_port := false
 var river_id := int(cells.river[cell])
 if _recorded_port(town):
  if water(cell)=="Inland" and river_id>0:
   for river in source.get("rivers",[]):
    if river is Dictionary and int(river.get("i",-1))==river_id and river.get("cells",[]).has(cell): river_port = true
  tags.append("RIVER PORT" if river_port else "PORT")
 var road_ids: Array = roads.get(id,[])
 var trail_ids: Array = trails.get(id,[])
 if road_ids.size()>1: tags.append("ROAD LINKS")
 elif road_ids.size()==1: tags.append("ROAD")
 elif not trail_ids.is_empty(): tags.append("TRAIL")
 var nearby: Array[int] = []
 var nearby_distances := {}
 var larger: Array[int] = []
 var fortified: Array[int] = []
 for other in towns:
  var other_id := int(other.i)
  if other_id==id or _feature(cell)<0 or _feature(int(other.cell))!=_feature(cell) or radius<0: continue
  if positions[id].distance_to(positions[other_id])>radius: continue
  nearby.append(other_id)
  nearby_distances[other_id] = positions[id].distance_to(positions[other_id])
  if float(other.population)>maxf(5.0, float(town.population)):
   larger.append(other_id)
   if bool(other.get("walls",false)): fortified.append(other_id)
 var neighbours := "No nearby towns recorded."
 if radius<0 or _feature(cell)<0: neighbours = "Nearby places unavailable."
 elif not fortified.is_empty(): neighbours = "Cluster; a larger walled neighbour." if nearby.size()>=3 else "Near a larger walled settlement."
 elif not larger.is_empty(): neighbours = "Cluster; larger settlements nearby." if nearby.size()>=3 else "Larger settlements nearby."
 elif nearby.size()>=3: neighbours = "Part of a close settlement cluster."
 elif nearby.size()>0: neighbours = "A few settlements nearby."
 var facts := {"burg_id":id,"cell_id":cell,"state_id":int(cells.state[cell]),"province_id":int(cells.province[cell]),"biome_id":int(cells.biome[cell]),"landscape":landscape,"water":water(cell),"walls":town.get("walls",null),"port":town.get("port",null),"river_port":river_port,"river_id":river_id if river_port else -1,"population":town.get("population",null),"road_ids":road_ids,"trail_ids":trail_ids,"nearby_ids":nearby,"nearby_distances_source_units":nearby_distances,"larger_nearby_ids":larger,"walled_larger_nearby_ids":fortified,"nearby_radius_source_units":radius}
 _cache[key] = _output([str(town.get("group","Settlement")).capitalize()+" · "+landscape+" · "+water(cell)," · ".join(tags),neighbours],tags,facts,["burg-cell-biome-v1","ocean-lake-cell-neighbours-v1","public-burg-port-walls-v1","recorded-inland-port-river-cell-v1","route-exact-point-v1","same-feature-median-nearest-radius-v1","source-population-comparison-v1"])
 return _cache[key].duplicate(true)
