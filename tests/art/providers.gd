extends SceneTree
var checks := 0
var failures := 0
func check(value: bool,why: String) -> void:
 checks+=1
 if not value: failures+=1;push_error(why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var combat_tests: SceneTree=load("res://tests/adventure/combat.gd").new()
 var state: Dictionary=combat_tests.fixture()
 combat_tests.free()
 var engine := TacticalCombat.new()
 var initial := engine.create(state,"test-site")
 var original := RulesJson.canonical(initial)
 var hashes := {};var recipes := {}
 check(CombatArt.styles().size()==4,"four providers present")
 for style in CombatArt.styles():
  check(CombatArt.available(style),"original resources available: "+style.id)
  for id in initial.order:
   var unit: Dictionary=initial.units[id]
   var member: Dictionary={}
   for candidate in state.party.members:
    if candidate.character_id==id: member=candidate;break
   var art := CombatArt.recipe(style.id,unit,member)
   check(art.available,"unit has genuine provider: "+id)
   check(CombatArt.paths_in(art.animations).all(func(path: String):return path.begins_with("res://assets/combat/"+style.id+"/")),"no cross-pack substitutes")
   check(art==CombatArt.recipe(style.id,unit,member),"identity recipe stable")
   check(art==CombatArt.recipe(style.id,JSON.parse_string(JSON.stringify(unit)),JSON.parse_string(JSON.stringify(member))),"JSON save/reload preserves complete recipe")
   check(CombatArt.recipe(style.id,unit,member,{"body":{"plan":"quadruped","size":0.75,"features":["horns"]}}).warnings.size()>=1,"unsupported anatomy honestly flagged")
   recipes[style.id+":"+id]=art.recipe_hash
  check(CombatArt.recipe(style.id,initial.units["bandit-blade"]).role=="vanguard" and CombatArt.recipe(style.id,initial.units["bandit-bow"]).role=="scout","blade and bow bandit distinguished")
  var battle := initial.duplicate(true)
  for i in 40:
   if battle.status!="active": break
   var result := engine.command(battle,engine.enemy_command(battle))
   check(result.ok,"same deterministic command resolves")
   battle=result.battle
   for id in battle.order: CombatArt.recipe(style.id,battle.units[id])
  hashes[style.id]=battle.state_hash
 check(hashes.values().all(func(value: String):return value==hashes.values()[0]),"no battle/log/RNG hash divergence across all four styles")
 check(original==RulesJson.canonical(initial),"presentation leaves complete input state unchanged")
 var broken: Dictionary=CombatArt.styles()[0].duplicate(true)
 broken.roles.vanguard.animations.idle.append({"path":"res://assets/combat/lpc/missing.png"})
 check(not CombatArt.available(broken),"missing assets detectable")
 var unit: Dictionary=initial.units["hero-0"]
 var before := CombatArt.recipe("lpc",unit)
 var changed: Dictionary=unit.duplicate(true);changed.weapon="bow"
 var after := CombatArt.recipe("lpc",changed)
 check(before.profile==after.profile and before.variant==after.variant and before.role!=after.role,"equipment updates preserve body identity and visual seed")
 var proof := {"suite":"art-providers","checks":checks,"failures":failures,"battle_hashes":hashes,"recipes":recipes}
 var path := OS.get_environment("GAME93_PROOF")
 if not path.is_empty(): FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print(JSON.stringify(proof));quit(1 if failures else 0)
