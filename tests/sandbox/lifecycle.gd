extends SceneTree
class FaultStore extends GamePlaythroughStore:
 var fault := ""
 var pending := false
 func save_existing(slot: String,state: Dictionary,world: GameWorldTemplate) -> Dictionary:
  if fault=="write":return _fail("Injected write failure")
  var saved := super.save_existing(slot,state,world)
  if saved.ok and fault=="reload":pending=true
  return saved
 func load_save(slot: String,world: GameWorldTemplate) -> Dictionary:
  if pending:pending=false;return _fail("Injected immediate reload failure")
  return super.load_save(slot,world)
var checks := 0
var failures := 0
var service := AdventureService.new()
var engine := TacticalCombat.new()
var entry := {}
var state := {}
var slot := ""
var base: String
func _initialize() -> void:call_deferred("run")
func check(value: bool,why: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(why);quit(1)
func action(operation: String,extra: Dictionary={}) -> void:
 var changes := {"revision":state.expedition.revision};changes.merge(extra)
 var result := service.operate(entry,slot,operation,1,changes)
 check(result.get("ok",false),operation+": "+str(result.get("error","")))
 state=result.get("state",state)
func campaign() -> void:
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),profiles.error)
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var origin := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(origin.ok,"canonical origin");slot=origin.state.playthrough_id
 check(service.store.save_new(slot,origin.state,entry.world).ok,"existing save owner")
 var party := PartyService.new();party.store=service.store;party.library=service.library
 check(party.operate(entry,slot,"generate").ok,"actual persistent party")
 for i in 3:check(party.operate(entry,slot,"edit",i+1,{"role_id":["vanguard","scout","adept"][i]}).ok,"existing role edit")
 check(party.operate(entry,slot,"ready").ok,"party ready")
 var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"existing hometown loop")
 state=loaded.state
 var identities: Dictionary=state.party.duplicate(true)
 action("sandbox_begin")
 check(state.party==identities and not state.has("first_adventure"),"no regenerated party or mandatory authored quest")
 check(state.sandbox.base.sites.size()==4,"four generated opportunities")
func travel(index: int) -> void:
 var site: Dictionary=state.sandbox.base.sites[index]
 action("sandbox_accept",{"lead":site.id})
 if state.sandbox.knowledge[site.id]=="rumoured":
  var projection := SandboxRecords.projection(state.sandbox)
  check(not projection.sites.any(func(s: Dictionary):return s.id==site.id),"rumoured position hidden")
  action("sandbox_scout")
  check(state.sandbox.knowledge[site.id]=="discovered","discovery persists")
 action("sandbox_travel")
 check(state.sandbox.knowledge[site.id]=="visited","visit persists")
func command(b: Dictionary) -> Dictionary:
 var result := engine.enemy_command(b);var actor := engine.current(b)
 if actor.team=="party" and int(b.budget.main)>0 and engine.characters.derive_character(actor.record).snapshot.abilities.has("spark"):
  for id in b.order:
   if engine.eligible(b,actor,b.units[id],"spark"):result.kind="spark";result.target_id=id;result.erase("destination");break
 return result
func fight_to_result() -> void:
 for i in 180:
  var b := AdventureService.active_battle(state)
  if b.status!="active":break
  var c := command(b);var expected := engine.command(b,c)
  action("sandbox_command",{"command":c})
  check(AdventureService.active_battle(state).state_hash==expected.battle.state_hash,"save authority equals pure command")
 check(AdventureService.active_battle(state).status!="active","generated fight resolves")
func reject(operation: String,extra: Dictionary={}) -> void:
 var raw := FileAccess.get_file_as_string(service.store._slot_path(slot))
 var changes := {"revision":state.expedition.revision};changes.merge(extra)
 var rejected := service.operate(entry,slot,operation,1,changes)
 check(not rejected.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==raw,"reject/retry preserves exact save: "+operation)
func run() -> void:
 base=OS.get_environment("GAME96_TEST_ROOT")
 DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 var phase := OS.get_environment("GAME96_PHASE")
 if phase=="create":
  campaign();var first: Dictionary=state.sandbox.base.sites[0]
  var immutable: String=state.sandbox.base_sha
  travel(0);action("sandbox_return")
  check(state.sandbox.encounters.is_empty() and state.sandbox.knowledge[first.id]=="visited","leave unstarted encounter without reroll")
  travel(0);action("sandbox_fight")
  check(state.sandbox.base_sha==immutable,"base remains immutable across visits")
  var b := AdventureService.active_battle(state);var c := command(b)
  action("sandbox_command",{"command":c});reject("sandbox_command",{"command":c})
  var checkpoint := {"slot":slot,"battle_hash":AdventureService.active_battle(state).state_hash,"base_sha":immutable,"party_ids":state.party_ids,"rng":AdventureService.active_battle(state).rng}
  FileAccess.open(base.path_join("checkpoint.json"),FileAccess.WRITE).store_string(JSON.stringify(checkpoint))
 else:
  var checkpoint: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("checkpoint.json")));slot=checkpoint.slot
  var loaded := service.operate(entry,slot,"resume");check(loaded.ok,str(loaded.get("error","")));state=loaded.state
  check(AdventureService.active_battle(state).state_hash==checkpoint.battle_hash and RulesJson.digest(AdventureService.active_battle(state).rng)==RulesJson.digest(checkpoint.rng) and state.party_ids==checkpoint.party_ids,"separate process restores exact encounter/RNG/identities")
  fight_to_result();var first_id: String=state.sandbox.active.site_id
  action("sandbox_return");reject("sandbox_accept",{"lead":first_id})
  travel(1);action("sandbox_fight");fight_to_result();action("sandbox_return")
  check(state.sandbox.results.size()==2 and state.sandbox.base_sha==checkpoint.base_sha,"second generated opportunity resolves without resetting first")
  var journal_size: int=state.sandbox.characters[state.party_ids[0]].history.size()
  check(journal_size==2,"one history entry per resolved opportunity")
  travel(2);action("sandbox_fight")
  while engine.current(AdventureService.active_battle(state)).team=="enemy":action("sandbox_command",{"command":engine.enemy_command(AdventureService.active_battle(state))})
  var b := AdventureService.active_battle(state)
  action("sandbox_command",{"command":{"revision":b.revision,"actor_id":engine.current(b).id,"kind":"retreat"}})
  check(state.sandbox.results[state.sandbox.active.site_id].outcome=="defeat","withdrawal and survivors stay terminal/saved")
  action("sandbox_return")
  check(state.sandbox.results.size()==3 and state.sandbox.encounters.size()==3,"no silent respawns across opportunities")
  var raw := FileAccess.get_file_as_string(service.store._slot_path(slot))
  var faulty := FaultStore.new();faulty.save_root=service.store.save_root;service.store=faulty
  for mode in ["write","reload"]:
   faulty.fault=mode
   var failed := service.operate(entry,slot,"sandbox_accept",1,{"revision":state.expedition.revision,"lead":state.sandbox.base.sites[3].id})
   check(not failed.ok and FileAccess.get_file_as_string(faulty._slot_path(slot))==raw,"existing journal rolls back exact bytes: "+mode)
  faulty.fault=""
  var corrupt := state.duplicate(true);corrupt.sandbox.base.sites[0].board.blocked.append([0,0]);corrupt.sandbox.base_sha=RulesJson.digest(corrupt.sandbox.base)
  check(not service.commit(slot,corrupt,entry.world).ok and FileAccess.get_file_as_string(faulty._slot_path(slot))==raw,"self-resealed bad generated geometry rejected")
  # The store checks structure; the service pins source geography independently.
  # A self-resealed coordinate mutation must not become a new discovered place.
  var moved := state.duplicate(true);moved.sandbox.base.sites[0].position[0]+=17;moved.sandbox.base_sha=RulesJson.digest(moved.sandbox.base)
  check(faulty.save_existing(slot,moved,entry.world).ok,"isolated self-resealed coordinate corruption fixture")
  var tampered_bytes := FileAccess.get_file_as_string(faulty._slot_path(slot))
  var mismatch := service.operate(entry,slot,"resume")
  check(not service.operate(entry,slot,"sandbox_begin",1,{"revision":state.expedition.revision}).ok,"repeat preparation cannot accept source-coordinate drift")
  check(not mismatch.ok and FileAccess.get_file_as_string(faulty._slot_path(slot))==tampered_bytes,"source regeneration rejects moved site without overwriting save")
  check(faulty.save_existing(slot,state,entry.world).ok,"restore owned corruption fixture through existing writer")
  check(service.recover(slot,entry.world).ok,"final campaign remains valid")
  FileAccess.open(base.path_join("final-state.json"),FileAccess.WRITE).store_string(JSON.stringify(state,"  "))
 var proof := {"phase":phase,"checks":checks,"failures":failures,"slot":slot,"base_sha":state.sandbox.base_sha,"results":state.sandbox.results,"party_ids":state.party_ids}
 FileAccess.open(base.path_join("lifecycle-"+phase+".json"),FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print("GAME96 LIFECYCLE ",phase," ",checks," checks / ",failures," failures");quit(1 if failures else 0)
