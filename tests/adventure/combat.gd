extends SceneTree
var checks := 0
var failures := 0
var engine := TacticalCombat.new()
func check(value: bool,why: String) -> void:
 checks+=1
 if not value: failures+=1;push_error(why)
func fixture(roles: Array=["vanguard","scout","adept"]) -> Dictionary:
 var members: Array=[];var roster: Array=[];var ids: Array=[]
 for i in roles.size():
  var id := "hero-"+str(i)
  members.append({"character_id":id,"role_id":roles[i],"people_id":"human","name":"Companion "+str(i)})
  roster.append({"id":id});ids.append(id)
 var state := {"party":{"status":"ready","members":members},"characters":roster,"party_ids":ids,"world_ref":{"id":"test-world"},"origin":{"home_burg_id":1}}
 return RulesRecords.preview_preparation(state).candidate
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var state := fixture()
 var initial := engine.create(state,"test-site")
 check(engine.validate(initial).is_empty(),"authored battle validates")
 check(initial==engine.create(state,"test-site"),"identical source produces identical battle")
 for omitted in ["vanguard","scout","adept","expert"]:
  var roles: Array=["vanguard","scout","adept","expert"].filter(func(role: String):return role!=omitted)
  check(engine.validate(engine.create(fixture(roles),"roles")).is_empty(),"supports generated composition missing "+omitted)
 var current := engine.current(initial)
 var bytes := RulesJson.canonical(initial)
 check(not engine.command(initial,{"revision":-1,"actor_id":current.id,"kind":"end"}).ok,"stale order rejects")
 check(not engine.command(initial,{"revision":0,"actor_id":"other","kind":"end"}).ok,"out of turn rejects")
 check(not engine.command(initial,{"revision":0,"actor_id":current.id,"kind":"move","destination":[3,0]}).ok,"blocked move rejects")
 check(not engine.command(initial,{"revision":0,"actor_id":current.id,"kind":"move","destination":[7,5]}).ok,"stride limit rejects")
 check(RulesJson.canonical(initial)==bytes,"invalid commands preserve input and RNG")
 var reachable := engine.paths(initial,current)
 var destination: Array=reachable.values()[1].back()
 var move := {"revision":0,"actor_id":current.id,"kind":"move","destination":destination}
 var moved := engine.command(initial,move)
 check(moved.ok and moved.battle.budget.move==0,"legal movement consumes one movement token")
 check(not engine.command(moved.battle,{"revision":1,"actor_id":current.id,"kind":"move","destination":current.position}).ok,"second movement rejects")
 check(engine.command(initial,move)==moved,"command output reproducible")
 var dynamic := {"revision":0,"actor_id":current.id,"kind":"move"};dynamic.destination=destination
 var dynamic_result := engine.command(initial,dynamic)
 var serialized: Dictionary=JSON.parse_string(JSON.stringify(dynamic_result.battle))
 check(engine.validate(serialized).is_empty() and RulesJson.digest(serialized)==RulesJson.digest(dynamic_result.battle),"dynamically added command keys have stable JSON checkpoint hashes")
 var bad := initial.duplicate(true);bad.rng.counter+=1
 check(not engine.validate(bad).is_empty(),"corrupt RNG checkpoint rejects")
 check(not engine.line_clear(initial,[2,0],[4,0]),"rocks block ranged line of sight")
 check(engine.line_clear(initial,[2,2],[5,3])==engine.line_clear(initial,[5,3],[2,2]),"line of sight is symmetric")
 # A controlled close engagement uses the same records and explicit dice.
 var close := initial.duplicate(true)
 close.units["hero-0"].position=[2,2];close.units["hero-1"].position=[2,3];close.units["hero-2"].position=[1,3]
 close.units["bandit-blade"].position=[3,2];close.units["bandit-bow"].position=[6,3]
 close.cursor=close.order.find("hero-0");close=engine.seal(close)
 var guarding := engine.command(close,{"revision":0,"actor_id":"hero-0","kind":"guard"})
 check(guarding.ok and guarding.battle.budget.main==0 and guarding.battle.units["hero-0"].record.runtime.statuses.size()==1,"Guard is a real class action")
 var departure := engine.command(close,{"revision":0,"actor_id":"hero-0","kind":"move","destination":[1,2]})
 check(departure.ok and departure.battle.units["bandit-blade"].reaction==0,"leaving melee spends foe shared reaction")
 var caster := close.duplicate(true);caster.cursor=caster.order.find("hero-2");caster=engine.seal(caster)
 var slow := engine.command(caster,{"revision":0,"actor_id":"hero-2","kind":"slow","target_id":"bandit-blade"})
 check(slow.ok and slow.battle.units["hero-2"].record.runtime.resources.focus==1,"Binding Step spends existing Focus")
 var heal := engine.command(caster,{"revision":0,"actor_id":"hero-2","kind":"healing-thread","target_id":"hero-1"})
 check(heal.ok and heal.battle.units["hero-2"].record.runtime.resources.focus==1,"Mending Thread targets an adjacent ally")
 # Match identical dice with and without an adjacent guarding ally.
 var protected: Dictionary= guarding.battle.duplicate(true)
 protected.units["bandit-blade"].position=[3,3]
 protected.cursor=protected.order.find("bandit-blade");protected.budget={"move":1,"main":1}
 var protected_result := {};var ordinary_result := {}
 for i in 30:
  protected.rng=RulesRng.initial("guard-hit-"+str(i));protected=engine.seal(protected)
  var ordinary: Dictionary= protected.duplicate(true);ordinary.units["hero-0"].record.runtime.statuses.clear();ordinary=engine.seal(ordinary)
  var attack := {"revision":protected.revision,"actor_id":"bandit-blade","kind":"attack","target_id":"hero-1"}
  protected_result=engine.command(protected,attack);ordinary_result=engine.command(ordinary,attack)
  if ordinary_result.battle.units["hero-1"].record.runtime.hp<ordinary.units["hero-1"].record.runtime.hp: break
 check(protected_result.battle.units["hero-1"].record.runtime.hp>ordinary_result.battle.units["hero-1"].record.runtime.hp and protected_result.battle.units["hero-0"].reaction==0,"Guard reduces an actual hit and spends shared reaction")
 # Opening Strike is applied to a qualifying hit, not to every attack.
 var precision_board := close.duplicate(true);precision_board.cursor=precision_board.order.find("hero-1")
 var precision_result := {};var plain_result := {}
 for i in 30:
  precision_board.rng=RulesRng.initial("precision-hit-"+str(i));precision_board=engine.seal(precision_board)
  var plain := precision_board.duplicate(true);plain.units["hero-0"].position=[0,0];plain=engine.seal(plain)
  var attack := {"revision":0,"actor_id":"hero-1","kind":"attack","target_id":"bandit-blade"}
  precision_result=engine.command(precision_board,attack);plain_result=engine.command(plain,attack)
  if precision_result.battle.units["hero-1"].precision_used: break
 check(precision_result.battle.units["hero-1"].precision_used and precision_result.battle.units["bandit-blade"].record.runtime.hp<plain_result.battle.units["bandit-blade"].record.runtime.hp,"Opening Strike adds damage with an allied melee threat")
 var doomed := initial.duplicate(true)
 for i in 600:
  if doomed.status!="active": break
  var input := engine.enemy_command(doomed) if engine.current(doomed).team=="enemy" else {"revision":doomed.revision,"actor_id":engine.current(doomed).id,"kind":"end"}
  doomed=engine.command(doomed,input).battle
 check(doomed.status=="defeat" and doomed.reason=="party_downed","enemy attacks produce a real defeat when the party falls")
 # Replay a complete legal battle using deterministic decisions, not HP edits.
 var b := initial.duplicate(true);var inputs: Array=[]
 for i in 600:
  if b.status!="active": break
  var input := engine.enemy_command(b)
  if engine.current(b).id=="hero-2" and int(b.budget.main)>0:
   for id in b.order:
    if b.units[id].team=="enemy" and engine.eligible(b,engine.current(b),b.units[id],"spark"):
     input.kind="spark";input.target_id=id;input.erase("destination");break
  var applied := engine.command(b,input)
  check(applied.ok,"legal complete battle command")
  if not applied.ok: break
  inputs.append(input);b=applied.battle
 check(b.status!="active","deterministic battle reaches a terminal outcome")
 check(engine.validate(b).is_empty(),"terminal checkpoint validates")
 var replay := initial.duplicate(true)
 for input in inputs: replay=engine.command(replay,input).battle
 check(replay.state_hash==b.state_hash and replay.rng==b.rng and replay.log==b.log,"full replay has identical hash, dice and ordering")
 var retreat := engine.command(initial,{"revision":0,"actor_id":current.id,"kind":"retreat"})
 check(retreat.ok and retreat.battle.status=="defeat" and retreat.battle.reason=="retreat","withdrawal provides an explicit defeat")
 print(JSON.stringify({"suite":"combat","checks":checks,"failures":failures,"battle_outcome":b.status,"battle_commands":inputs.size(),"hash":b.state_hash}))
 quit(1 if failures else 0)
