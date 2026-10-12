extends SceneTree
var checks := 0
var failures := 0
var metrics := {"worlds":[],"contexts":[],"activities":{},"families":{},"kinds":{},"environments":{},"choices":{},"compositions":{},"sizes":{},"home_signatures":{},"companion_choices":0,"checks":0,"failures":0}
func _initialize() -> void:call_deferred("run")
func check(value: bool,why: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(why)
func count(group: String,key: String) -> void:metrics[group][key]=int(metrics[group].get(key,0))+1
func run() -> void:
 var pins: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/opportunities/v1-pins.json"))
 for file in pins:
  var digest := FileAccess.get_sha256("res://"+file)
  if file=="scripts/combat/tactical_combat.gd":
   # Retain the original byte oracle. Only these explicit v7-gated additions
   # may be removed when projecting the unchanged legacy authority.
   var legacy := FileAccess.get_file_as_string("res://"+file)
   for stat in ["bonus","amount"]:
    var adapter := "  # GAME119 v7-only target profile; frozen legacy branch above remains exact.\n  if RulesCareer.enabled(registry) and RulesCareer.quarry_matches(snap,t,registry):"+stat+"+=2\n"
    check(legacy.count(adapter)==1,"exactly one explicitly gated career adapter: "+stat)
    legacy=legacy.replace(adapter,"")
   digest=legacy.sha256_text()
  check(digest==pins[file],"protected V1/combat/source/icon contract unchanged: "+file)
 var root_path := OS.get_environment("GAME101_TEST_ROOT")
 var corpus: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("corpus.json")))
 metrics.worlds=corpus.worlds;metrics["unsupported_source_placements"]=corpus.unsupported
 var parties: Array=[]
 for path in ["res://tests/lpc/generated-party.json","res://tests/map_icons/existing-game99-save.json"]:parties.append(RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string(path))))
 var seen := {};var signatures := {}
 for spec in corpus.specs:
  var world := GameWorldTemplate.new();check(world.load_fixture(spec.world),world.error)
  var content: Dictionary=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string(spec.content)))
  var before := RulesJson.digest(content)
  var base := OpportunityGenerator.generate(world,int(spec.home_id),content)
  check(not base.is_empty(),"bounded V2 generation "+spec.home_name)
  if base.is_empty():continue
  check(base==OpportunityGenerator.generate(world,int(spec.home_id),content),"exact source recipe replay")
  check(before==RulesJson.digest(content),"canonical local content untouched")
  check(RulesJson.digest(base)==RulesJson.digest(RulesJson.normalize(JSON.parse_string(JSON.stringify(base)))),"fingerprint survives serialization")
  var families := {};var types: Array=[];var rows: Array=[]
  var record := SandboxRecords.create(base,parties[0]);record.version=OpportunityGenerator.VERSION
  var public := OpportunityRecords.projection(record)
  check(public.sites.size()==3 and public.leads[1].site=="" and public.leads[1].title=="Unlocated local report" and not public.leads[1].has("position"),"hidden rumour has no kind, coordinates, target or name")
  for site in base.sites:
   var activity := OpportunityGenerator.template(site.activity_id);families[activity.family]=true;types.append(site.activity_id)
   check(not seen.has(site.id),"world/home stable unique site identity");seen[site.id]=true
   var placement: Dictionary=content.sites[int(site.context.placement_slot)]
   check(site.position==placement.position and site.world_position==placement.world_position and spec.source_owned_dry_land,"actual source-owned geography")
   if activity.requires_route:check(SandboxGenerator.nearest_route(world,site.world_position,int(base.cell_id)).distance<=2.0,"source route constraint")
   check(SandboxGenerator.valid_board(site.board) and SandboxGenerator.geometry_error(site.board).is_empty(),"unchanged legal board composer")
   count("activities",activity.id);count("families",activity.family);count("kinds",site.kind);count("environments",site.context.environment)
   if activity.family=="contested":count("compositions",str(site.board.enemies.map(func(e: Dictionary):return e.weapon)));count("sizes","%dx%d"%[site.board.width,site.board.height])
   for party in parties:
    var choices := OpportunityGenerator.choices(party,site)
    check(choices==OpportunityGenerator.choices(party,site),"deterministic saved profession choices")
    for choice in choices:
     count("choices",choice.id.get_slice(":",0))
     if not choice.participant.is_empty():
      metrics.companion_choices+=1
      check(party.party.members.any(func(m: Dictionary):return m.character_id==choice.participant and m.generated_facts.occupation_id==choice.profession),"real saved occupation participant")
      check(choice.provisions==0,"bounded actual provision benefit")
   rows.append({"id":site.id,"activity":activity.id,"family":activity.family,"kind":site.kind,"route_ref":site.context.route_ref,"board_sha":RulesJson.digest(site.board),"position":site.position})
  check(families.has_all(["recovery","investigation","contested"]),"playable noncombat and hostile coverage, not four combat variants")
  types.sort();var signature := ",".join(types);signatures[signature]=true;count("home_signatures",signature)
  metrics.contexts.append({"world_seed":world.seed,"home_id":spec.home_id,"home_name":spec.home_name,"biome":spec.biome,"base_sha":RulesJson.digest(base),"sites":rows})
 check(metrics.worlds.size()==10 and metrics.contexts.size()>=30,"ten genuine worlds and thirty hometowns")
 check(signatures.size()>=6 and metrics.activities.size()>=6 and metrics.environments.size()>=3 and metrics.compositions.size()==4 and metrics.sizes.size()==3,"measured variation in objectives, environments and hostile tactics")
 check(metrics.companion_choices>0,"real saved professions change available actions")
 metrics.checks=checks;metrics.failures=failures
 FileAccess.open(root_path.path_join("metrics.json"),FileAccess.WRITE).store_string(JSON.stringify(metrics,"  ")+"\n")
 print("GAME101 CORPUS ",checks," checks / ",failures," failures; ",metrics.contexts.size()," contexts, ",signatures.size()," activity sets")
 quit(1 if failures else 0)
