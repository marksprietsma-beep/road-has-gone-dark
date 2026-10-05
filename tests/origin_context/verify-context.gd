extends SceneTree
var failures := 0
var checks := 0
var examples: Array = []
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
# Independent reference aggregation: every displayed landscape/region tag is
# checked against the original snapshot, not against another service instance.
func backed_area(raw: Dictionary, context: Dictionary) -> void:
 var f: Dictionary=context.facts
 var weights := {}
 var coast := 0
 var shores := 0
 var count := 0
 var area := 0.0
 var state := int(f.get("state_id",-1))
 var province := int(f.get("province_id",-1))
 for i in raw.cells.ids.size():
  if float(raw.cells.heights[i])<20 or (state>0 and int(raw.cells.state[i])!=state) or (province>0 and int(raw.cells.province[i])!=province): continue
  count+=1
  area+=float(raw.cells.area[i])
  var biome := int(raw.cells.biome[i])
  weights[biome]=float(weights.get(biome,0))+float(raw.cells.area[i])
  var ocean := false
  var lake := false
  for n in raw.cells.neighbors[i]:
   if float(raw.cells.heights[n])>=20: continue
   for feature in raw.map.geography:
    if feature is Dictionary and int(feature.i)==int(raw.cells.features[n]):
     ocean=ocean or feature.get("type")=="ocean"
     lake=lake or feature.get("type")=="lake"
  coast+=int(ocean)
  shores+=int(not ocean and lake)
 check(count==f.land_cells and is_equal_approx(area,float(f.land_area)),"region land area directly backed")
 check(coast==f.coastal_cells and shores==f.lake_shore_cells,"region coastal/lake description directly backed")
 check(weights==f.biome_areas,"landscape weighting uses original land-cell areas")
 if not f.biome_order.is_empty():
  var top: int=f.biome_order[0]
  for id in weights: check(float(weights[id])<=float(weights[top]),"displayed dominant landscape truly dominant")
 for kind in ["port_ids","walled_ids","larger_ids"]:
  for id in f[kind]:
   var record: Dictionary=raw.settlements[id]
   check(f.town_ids.has(id),"region tagged town belongs to public aggregate")
   if kind=="port_ids": check(int(record.get("port",0))>0,"region PORTS supported")
   elif kind=="walled_ids": check(record.get("walls",false),"region walls supported")
   else: check(float(record.population)>5,"larger threshold reuses small-home ceiling")
 if f.has("peer_densities_source_area"):
  var peers: Array=f.peer_densities_source_area
  var density: float=f.density_source_area
  if peers.size()>=3 and f.town_count>0:
   check((f.concentration=="Sparsely settled")== (density<float(peers[peers.size()/3])),"sparse wording follows supported peer distribution")
   check((f.concentration=="Densely settled")== (density>float(peers[(peers.size()*2)/3])),"dense wording follows supported peer distribution")
func verify_negative_cases(world: GameWorldTemplate, raw: Dictionary, id: int) -> void:
 # Mutations are isolated unit-test snapshots, never screenshot/world fixtures.
 var altered := raw.duplicate(true)
 var town: Dictionary=altered.settlements[id]
 town.erase("walls")
 town.port=null
 altered.routes=[{"i":991,"group":"roads","points":[[float(town.x)+1,float(town.y),int(town.cell)]]},{"i":992,"group":"searoutes","points":[[town.x,town.y,town.cell]]},{"i":993,"group":"roads","hidden":true,"points":[[town.x,town.y,town.cell]]}]
 var info := OriginContext.new(world,altered).hometown_summary(id)
 check(info.facts.walls==null and info.facts.port==null,"missing wall/port facts remain unknown")
 check(not info.tags.has("WALLED") and not info.tags.has("PORT") and not info.tags.has("RIVER PORT"),"unknown facts never become positive claims")
 check(info.facts.road_ids.is_empty() and info.facts.trail_ids.is_empty(),"nearby road, sea route and hidden route never become direct connection")
 altered=raw.duplicate(true)
 for t in altered.settlements:
  if t is Dictionary and int(t.get("i",0))>0 and int(t.i)!=id: t.hidden=true
 info=OriginContext.new(world,altered).hometown_summary(id)
 check(info.facts.nearby_ids.is_empty() and info.facts.nearby_radius_source_units<0 and info.summary.contains("unavailable"),"insufficient public neighbours remain unavailable, not isolated")
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var paths := ["res://tests/worldgen/fixtures/game-11-determinism.json", "res://tests/worldgen/fixtures/atlas-showcase.json"]
 var fresh := OS.get_environment("GAME75_GENERATED_DIR")
 if fresh.is_empty(): fresh = "/tmp/game75 fresh worlds"
 for seed in ["game75-context-a","game75-context-b","game75-context-c"]: paths.append(fresh.path_join(seed).path_join("world.json"))
 var signatures := {}
 for path in paths:
  var world := GameWorldTemplate.new()
  check(world.load_fixture(path), "load actual canonical world "+path)
  if world.world_id.is_empty(): continue
  var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
  var original_hash := FileAccess.get_sha256(path)
  var ctx := OriginContext.new(world,raw)
  var repeated := OriginContext.new(world,raw)
  check(ctx.world_summary()==repeated.world_summary(), "deterministic world context")
  backed_area(raw,ctx.world_summary())
  var visible := {}
  for town in raw.settlements:
   if town is Dictionary and int(town.get("i",0))>0 and not town.get("hidden",false) and not town.get("removed",false) and float(town.get("population",0))>0: visible[int(town.i)] = town
  var contrasts := {"coastal":[],"inland":[],"walled":[],"unwalled":[],"port":[],"nonport":[],"sparse":[],"clustered":[]}
  var region_texts := {}
  for state in raw.states:
   if not state is Dictionary or int(state.get("i",0))<=0 or state.get("removed",false): continue
   var summary := ctx.region_summary(int(state.i))
   check(summary==repeated.region_summary(int(state.i)), "deterministic state summary")
   backed_area(raw,summary)
   region_texts[summary.summary] = true
   for id in summary.facts.town_ids: check(int(raw.cells.state[visible[id].cell])==int(state.i), "region ownership")
   for province in raw.provinces:
    if province is Dictionary and int(province.get("state",-1))==int(state.i) and int(province.get("i",0))>0:
     var region := ctx.region_summary(int(state.i),int(province.i))
     check(region==repeated.region_summary(int(state.i),int(province.i)), "deterministic province summary")
     backed_area(raw,region)
     for id in region.facts.town_ids: check(int(raw.cells.province[visible[id].cell])==int(province.i), "province ownership")
   for candidate in world.home_candidates(int(state.i),-1,-1):
    var id := int(candidate.id)
    var town: Dictionary = visible[id]
    var context := ctx.hometown_summary(id)
    var facts: Dictionary = context.facts
    check(context==repeated.hometown_summary(id), "deterministic hometown "+str(id))
    check(facts.state_id==int(state.i) and facts.cell_id==int(town.cell), "correct source IDs")
    check(context.world_id==world.world_id, "immutable identity independent of prose")
    check(context.tags.has("WALLED")==bool(town.get("walls",false)), "walls claim exactly supported")
    check((context.tags.has("PORT") or context.tags.has("RIVER PORT"))==(int(town.get("port",0))>0), "port claim exactly supported")
    if facts.water=="Coastal":
     var backed := false
     for neighbor in raw.cells.neighbors[town.cell]:
      for feature in raw.map.geography:
       if feature is Dictionary and int(feature.i)==int(raw.cells.features[neighbor]) and feature.get("type")=="ocean" and float(raw.cells.heights[neighbor])<20: backed = true
     check(backed, "coastal claim backed by ocean neighbour")
    if facts.river_port:
     var backed := false
     for river in raw.rivers:
      if int(river.i)==facts.river_id and river.cells.has(town.cell): backed=true
     check(backed and int(town.get("port",0))>0 and facts.water=="Inland", "river port supported; downstream port ID never implies sea coast")
    for route_id in facts.road_ids + facts.trail_ids:
     var backed := false
     for route in raw.routes:
      if int(route.i)!=route_id: continue
      check(["roads","trails"].has(route.group), "sea routes never become roads")
      for point in route.points:
       if point.size()>=3 and int(point[2])==int(town.cell) and Vector2(float(point[0]),float(point[1])).distance_to(Vector2(float(town.x),float(town.y)))<=0.02: backed=true
     check(backed, "road/trail matches actual burg position and cell")
    if facts.nearby_ids.is_empty(): check(context.summary.contains("on this landmass"), "negative proximity statement exposes its geographical scope")
    for other_id in facts.nearby_ids:
     check(visible.has(other_id) and other_id!=id, "nearby original public settlement exists")
     var other: Dictionary = visible[other_id]
     check(int(raw.cells.features[other.cell])==int(raw.cells.features[town.cell]), "nearby same land feature")
     check(Vector2(float(other.x),float(other.y)).distance_to(Vector2(float(town.x),float(town.y)))<=facts.nearby_radius_source_units, "source-relative proximity rule")
    for other_id in facts.walled_larger_nearby_ids:
     check(facts.nearby_ids.has(other_id) and bool(visible[other_id].get("walls",false)) and float(visible[other_id].population)>maxf(5.0,float(town.population)), "larger fortified neighbour is backed")
    if facts.water=="Coastal": contrasts.coastal.append(id)
    elif facts.water=="Inland": contrasts.inland.append(id)
    contrasts["walled" if facts.walls else "unwalled"].append(id)
    contrasts["port" if int(town.get("port",0))>0 else "nonport"].append(id)
    contrasts["clustered" if facts.nearby_ids.size()>=3 else "sparse"].append(id)
    var text := str(context.summary).to_lower()
    for forbidden in ["danger","prosperity","protected","guild","safety","kilomet","travel time","graph degree","source size"]: check(not text.contains(forbidden), "no unsupported claim: "+forbidden)
  check(region_texts.size()>1,"real contrasting regions distinguish choices")
  for pair in [["coastal","inland"],["walled","unwalled"],["port","nonport"],["sparse","clustered"]]:
   check(not contrasts[pair[0]].is_empty() and not contrasts[pair[1]].is_empty(), "genuine contrast exists: "+str(pair))
   if not contrasts[pair[0]].is_empty() and not contrasts[pair[1]].is_empty():
    check(ctx.hometown_summary(contrasts[pair[0]][0]).summary!=ctx.hometown_summary(contrasts[pair[1]][0]).summary,"comparison differs: "+str(pair))
  var modified := raw.duplicate(true)
  var first_id: int = ctx.towns[0].i
  verify_negative_cases(world,raw,first_id)
  for town in modified.settlements:
   if town is Dictionary and int(town.get("i",0))==first_id: town.name="RENAMED_DISPLAY_ONLY"
  modified.markers=[{"name":"HIDDEN_POI_SECRET","hidden":true}]
  var renamed := OriginContext.new(world,modified)
  check(renamed.hometown_summary(first_id)==ctx.hometown_summary(first_id),"name/hidden POI changes do not alter classification")
  check(not JSON.stringify(renamed.world_summary()).contains("HIDDEN_POI_SECRET"),"no hidden POI disclosure")
  modified = raw.duplicate(true)
  for town in modified.settlements:
   if town is Dictionary and int(town.get("i",0))==first_id: town.hidden=true
  var hidden := OriginContext.new(world,modified)
  check(hidden.hometown_summary(first_id).facts.is_empty(),"hidden hometown context not returned")
  for id in hidden.world_summary().facts.town_ids: check(id!=first_id,"hidden town excluded from world aggregates")
  var clone := ctx.world_summary()
  clone.summary="Edited output only"
  check(clone.summary!=ctx.world_summary().summary and ctx.world_id==world.world_id,"defensive outputs; prose never changes identity")
  check(FileAccess.get_sha256(path)==original_hash,"source bytes remain unchanged")
  signatures[ctx.world_summary().summary]=true
  examples.append({"world_ref":world.source_metadata(),"world":ctx.world_summary(),"contrasts":contrasts,"sample_home":ctx.hometown_summary(contrasts.coastal[0])})
 check(signatures.size()>1,"worlds distinguish source-backed character")
 var file := FileAccess.open("res://docs/implementation/game75/context-proof.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"worlds":examples},"  ")+"\n")
 print("GAME-75 context: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
