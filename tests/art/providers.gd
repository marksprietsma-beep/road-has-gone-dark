extends SceneTree
var checks := 0
var failures := 0
func check(value: bool,why: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(why)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var source: SceneTree=load("res://tests/adventure/combat.gd").new()
 var state: Dictionary=source.fixture();source.free()
 var engine := TacticalCombat.new();var initial := engine.create(state,"test-site")
 var original := RulesJson.canonical(initial);var recipes := {};var appearances := []
 check(CombatArt.styles().size()==1 and CombatArt.styles()[0].id=="lpc","only LPC in production")
 check(CombatArt.available(CombatArt.styles()[0]),"all selected originals available")
 for id in initial.order:
  var unit: Dictionary=initial.units[id];var member: Dictionary={}
  for candidate in state.party.members:
   if candidate.character_id==id:member=candidate;break
  var art := CombatArt.recipe("lpc",unit,member)
  check(art.available,"original LPC provider available")
  check(CombatArt.paths_in(art.animations).all(func(path: String):return path.begins_with("res://assets/combat/lpc/")),"no comparison substitutes")
  check(art==CombatArt.recipe("lpc",JSON.parse_string(JSON.stringify(unit)),JSON.parse_string(JSON.stringify(member))),"full recipe stable across save/restart JSON")
  check(art==CombatArt.recipe("navinius",unit,member),"retired provider request safely resolves to LPC")
  check(CombatArt.recipe("lpc",unit,member,{"body":{"plan":"quadruped","features":["horns"]}}).warnings.size()>0,"unsupported anatomy explicitly neutral")
  check(art.profile.identity_layers.has_all(["ancestry_ref","heritage","culture","origin","background"]),"identity provenance layers remain separate")
  check(art.equipment==unit.record.equipment,"visual equipment sourced from actual build")
  for clip in art.animations:
   for layer in art.animations[clip]:
    check(layer.columns>0 and int(layer.directions) in [1,4],"native geometry valid")
    if not layer.hold:
     var frames: Array=art.timelines.get(clip,{"frames":[0]}).frames
     check(frames.max()<layer.columns,"shared timeline fits native layer, no independent wrapping")
  var idle_parts: Array=art.animations.idle.map(func(v: Dictionary):return v.part_id)
  check(idle_parts.has("shield")==unit.record.equipment.has("shield"),"shield only when actually owned")
  check(idle_parts.any(func(p: String):return p.begins_with("mail-"))==unit.record.equipment.has("mail"),"mail rather than invented plate")
  if unit.team=="enemy":check(not idle_parts.any(func(p: String):return p.begins_with("mail-") or p.begins_with("leather-")),"authored raiders have rough clothing, no unowned armour")
  check(not art.animations.spell.any(func(v: Dictionary):return v.part_id.begins_with("cane-")),"casting hands freed rather than floating held staff")
  var pawn := CombatPawn.new();root.add_child(pawn);pawn.present(unit,art,true,20,"1")
  pawn.play_action("attack",Vector2.LEFT)
  check(pawn.facing==1 and pawn.animation==("shoot" if unit.weapon=="bow" else "thrust" if unit.weapon=="staff" else "slash"),"correct weapon animation and real west row")
  pawn.face(Vector2.UP);check(pawn.facing==0,"north native facing")
  pawn.face(Vector2.DOWN);check(pawn.facing==2,"south native facing")
  pawn.face(Vector2.RIGHT);check(pawn.facing==3,"east native facing")
  pawn.animation="down";pawn.age=20
  check(pawn.frame_index(art.animations.down[0])==5,"defeat freezes last native hurt frame")
  pawn.react(0,"miss");check(pawn.feedback=="MISS","miss distinguished from damage")
  pawn.react(0,"blocked");check(pawn.feedback=="BLOCKED","absorbed damage not mislabelled miss")
  pawn.free()
  recipes[id]=art.recipe_hash;appearances.append(art.appearance)
 check(appearances[0]!=appearances[1] or appearances[1]!=appearances[2],"identity variation exists")
 var unit: Dictionary=initial.units["hero-0"]
 var before := CombatArt.recipe("lpc",unit)
 var changed: Dictionary=unit.duplicate(true);changed.weapon="bow"
 var after := CombatArt.recipe("lpc",changed)
 check(before.appearance==after.appearance and before.profile==after.profile,"equipment changes do not reroll body identity")
 var broken: Dictionary=CombatArt.styles()[0].duplicate(true);broken.parts["body-male"].actions.idle.path="res://assets/combat/lpc/missing.png"
 check(not CombatArt.available(broken),"missing source resources detected")
 var battle := initial.duplicate(true)
 for i in 40:
  if battle.status!="active":break
  var result := engine.command(battle,engine.enemy_command(battle));check(result.ok,"frozen authority command")
  battle=result.battle
  for id in battle.order:CombatArt.recipe("lpc",battle.units[id])
 check(battle.state_hash=="63763c2fd9326b8a36159e83f7d077ac96c5eb2829c4efa9eec7c55228306732","exact GAME-93 golden battle/log/RNG hash retained")
 check(RulesJson.canonical(initial)==original,"visual operations cannot mutate authority")
 var proof := {"suite":"LPC-V1","checks":checks,"failures":failures,"battle_hash":battle.state_hash,"recipes":recipes}
 FileAccess.open(OS.get_environment("GAME93_PROOF"),FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print(JSON.stringify(proof));quit(1 if failures else 0)
