extends SceneTree
var checks := 0
var failures := 0
var engine := TacticalCombat.new()
var oracle := Game94CombatOracle.new()
var metrics := {"worlds":[],"contexts":0,"sites":0,"kinds":{},"environments":{},"sizes":{},"compositions":{},"attempts":{},"rejections":{},"generation_failures":0,"geometry_hashes":[],"outcomes":{},"commands":0,"checks":0,"failures":0}
func _initialize() -> void:call_deferred("run")
func check(value: bool,why: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(why)
func count(key: String,value: String) -> void:metrics[key][value]=int(metrics[key].get(value,0))+1
func run() -> void:
 var root_path := OS.get_environment("GAME96_TEST_ROOT")
 var corpus: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("corpus.json")))
 metrics.worlds=corpus.worlds
 var state: Dictionary=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/lpc/generated-party.json")))
 var seen_ids := {};var distinct := {}
 for spec in corpus.specs:
  var world := GameWorldTemplate.new();check(world.load_fixture(spec.world),world.error)
  var content: Dictionary=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string(spec.content)))
  var original := RulesJson.canonical(content)
  var base := SandboxGenerator.generate(world,int(spec.home_id),content)
  check(not base.is_empty(),"bounded real-world generation: "+spec.home_name)
  if base.is_empty():metrics.generation_failures+=1;continue
  metrics.contexts+=1
  check(base==SandboxGenerator.generate(world,int(spec.home_id),content),"exact generation replay")
  check(RulesJson.canonical(content)==original,"canonical region remains untouched")
  var kinds := {}
  for site in base.sites:
   metrics.sites+=1;kinds[site.kind]=true
   check(not seen_ids.has(site.id),"unique world/home/site identity");seen_ids[site.id]=true
   check(site.position==content.sites[int(site.context.placement_slot)].position and site.world_position==content.sites[int(site.context.placement_slot)].world_position and spec.source_owned_dry_land,"actual verified owned placement")
   if site.kind=="roadside":check(float(SandboxGenerator.nearest_route(world,site.world_position,int(base.cell_id)).distance)<=2,"actual source-route proximity")
   var board: Dictionary=site.board
   check(SandboxGenerator.geometry_error(board).is_empty(),"valid connectivity/spawns/engagement")
   check(board.attempt<int(SandboxGenerator.rules().max_attempts),"bounded attempts")
   for attempt in int(board.attempt):
    var reason := SandboxGenerator.geometry_error(SandboxGenerator.candidate(board.generation,attempt))
    check(not reason.is_empty(),"earlier candidate genuinely rejected");count("rejections",reason)
   for feature in board.presentation.features:
    if feature.kind in ["tree","rock","wall"]:check(board.blocked.has(feature.at),"visible blocking matches real blockers")
   for p in board.blocked:
    if int(p[0])>0 and int(p[0])<int(board.width)-1:
     check(not engine.line_clear({"board":board},[int(p[0])-1,int(p[1])],[int(p[0])+1,int(p[1])]),"actual blocker stops authoritative LOS")
   var malformed := board.duplicate(true);malformed.party_positions[1]=malformed.party_positions[0].duplicate()
   check(SandboxGenerator.geometry_error(malformed)=="invalid spawn" and not SandboxGenerator.valid_board(malformed),"overlap rejected without reseeding")
   malformed=board.duplicate(true);malformed.generation.rules_sha="unsupported"
   check(not SandboxGenerator.valid_board(malformed),"unsupported recipe fails closed")
   for p in board.blocked:check(board.presentation.features.any(func(f: Dictionary):return f.at==p and f.kind in ["tree","rock","wall"]),"every blocker is rendered")
   count("kinds",site.kind);count("environments",site.context.environment);count("sizes","%dx%d"%[board.width,board.height]);count("attempts",str(board.attempt));count("compositions",str(board.enemies.map(func(e: Dictionary):return e.weapon)))
   var geometry := RulesJson.digest([board.width,board.height,board.blocked,board.party_positions,board.enemies.map(func(e: Dictionary):return [e.weapon,e.position])]);distinct[geometry]=true
   state.world_ref=world.world_ref;state.origin.home_burg_id=spec.home_id
   var initial := engine.create_generated(state,site.id,board)
   check(engine.validate(initial).is_empty(),"generated enemy builds and battle valid")
   check(initial==engine.create_generated(state,site.id,board),"generation and starting dice are separate/stable")
   var played := initial.duplicate(true);var old_played := initial.duplicate(true)
   for step in 180:
    if played.status!="active":break
    var command := engine.enemy_command(played)
    check(command==oracle.enemy_command(old_played),"unmodified AI on generated geometry/composition")
    var after := engine.command(played,command);var old_after := oracle.command(old_played,command)
    check(after.ok and after==old_after,"same resolver results, log and RNG as frozen GAME94")
    if not after.ok:break
    played=after.battle;old_played=old_after.battle;metrics.commands+=1
    check(engine.validate(RulesJson.normalize(JSON.parse_string(JSON.stringify(played)))).is_empty(),"command survives save/reload")
   check(played.status!="active","bounded encounter resolves")
   count("outcomes",played.status)
  check(kinds.size()>=3,"coherent site archetype diversity in each hometown")
 metrics.geometry_hashes=distinct.keys();metrics.checks=checks;metrics.failures=failures
 check(metrics.worlds.size()>=5 and metrics.contexts>=30 and distinct.size()>=50,"multi-world meaningful geometry coverage")
 metrics.checks=checks;metrics.failures=failures
 FileAccess.open(root_path.path_join("metrics.json"),FileAccess.WRITE).store_string(JSON.stringify(metrics,"  ")+"\n")
 print("GAME96 CORPUS ",JSON.stringify(metrics));quit(1 if failures else 0)
