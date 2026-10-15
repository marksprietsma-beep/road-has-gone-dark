extends Node
signal completed
var no_quit := false
var failures := 0
var checks := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var captured: Dictionary=WorldOriginLore.read_json("res://tests/character_entities/fixtures/blocked-surge-battle.json")
 var before := RulesJson.digest(captured)
 var b: Dictionary=captured.duplicate(true)
 var id: String=b.units.keys().filter(func(key: String):return b.units[key].name=="Bran")[0]
 var driver: Node=load("res://tests/character_entities/journey_driver.gd").new()
 var engine := TacticalCombat.new(b.units[id].record);driver.engine=engine
 # Reconstruct the trapped second-turn layout from the captured CI commands.
 # This is a fresh mechanics fixture, not a rewritten save or an earned campaign.
 b.status="active";b.reason="";b.round=2;b.cursor=b.order.find(id)
 b.budget={"main":1,"move":1};b.revision=0;b.commands=[];b.log=["Captured blocked-corner regression fixture"]
 for u in b.units.values():
  if u.team=="enemy":u.record.runtime.hp=int(engine.stats(u).HP)
  elif u.name=="Fen":u.position=[3,4]
  elif u.get("entity",{}).get("kind")=="companion":u.position=[2,5]
 b=engine.seal(b)
 check(engine.validate(b).is_empty(),"captured layout forms a valid battle: "+engine.validate(b))
 check(engine.enemy_command(b).kind=="end","old melee strategy stalls at blocked corner")
 check(not b.units.values().any(func(u: Dictionary):return u.team=="enemy" and engine.eligible(b,b.units[id],u,"wilder-surge")),"initial surge line of sight genuinely blocked")
 var command: Dictionary=driver.surge_demonstration_command(b,b.units[id])
 check(command.get("kind")=="move","ranged strategy finds an ordinary reachable movement")
 var moved := engine.command(b,command)
 check(moved.ok,"authoritative movement accepted")
 if moved.ok:
  check(moved.battle.rng==b.rng and moved.battle.budget.move==0 and moved.battle.budget.main==1,"movement does not invent RNG or a main action")
  var surge: Dictionary=driver.surge_demonstration_command(moved.battle,engine.current(moved.battle))
  check(surge.get("kind")=="wilder-surge","move creates a genuinely legal surge target")
  var cast := engine.command(moved.battle,surge)
  check(cast.ok,"original authority executes costed surge")
  if cast.ok:
   var target: String=surge.target_id
   check(int(cast.battle.units[target].record.runtime.hp)<int(moved.battle.units[target].record.runtime.hp),"surge causes actual damage")
   check(int(cast.battle.units[id].record.runtime.resources["psychic-points"])==0 and cast.battle.budget.main==0,"four power points and main spent")
   check(cast.battle.units[id].record.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened"),"original surge drawback retained")
   var replay := engine.command(JSON.parse_string(JSON.stringify(moved.battle)),surge)
   check(replay.ok and replay.battle.state_hash==cast.battle.state_hash,"exact JSON replay and RNG")
   check(engine.validate(cast.battle).is_empty(),"resolved battle validates")
   check(driver.surge_demonstration_command(cast.battle,cast.battle.units[id]).is_empty(),"spent action/resources never bypassed")
 check(RulesJson.digest(captured)==before,"captured source evidence untouched")
 driver.free()
 print("BLOCKED SURGE ",checks," checks ",failures," failures")
 var base := OS.get_environment("GAME112W2_TEST_ROOT")
 if not base.is_empty():
  DirAccess.make_dir_recursive_absolute(base)
  FileAccess.open(base.path_join("blocked-surge-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":engine.registry.rules_ref(),"captured_battle_hash":before,"development_fixture":true,"source_run":38722381984}))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
