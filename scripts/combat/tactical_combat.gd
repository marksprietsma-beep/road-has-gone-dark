class_name TacticalCombat
extends RefCounted
## One tactical authority for authored and generated specs; commands are pure.
const ENCOUNTER := "res://data/combat/first-road-encounter.json"
var registry := RulesRecords.registry()
var characters := RulesCharacter.new(registry)
var effects := RulesEffects.new(registry)

func _init(context: Dictionary = {}) -> void:configure(context)
func configure(context: Dictionary) -> void:
 registry=RulesRecords.registry(context);characters=RulesCharacter.new(registry);effects=RulesEffects.new(registry)

func create(state: Dictionary, site_id: String, layout_id: String=CombatBattlefields.LEGACY) -> Dictionary:
 var definition := CombatBattlefields.definition(layout_id)
 if not CombatBattlefields.valid_definition(definition):return {}
 return create_definition(state,site_id,definition,FileAccess.get_sha256(CombatBattlefields.PATHS[layout_id]))

func create_generated(state: Dictionary,site_id: String,definition: Dictionary) -> Dictionary:
 if not SandboxGenerator.valid_board(definition) or definition.generation.site_id!=site_id:return {}
 return create_definition(state,site_id,definition,RulesJson.digest(definition))

func create_definition(state: Dictionary,site_id: String,definition: Dictionary,pin: String) -> Dictionary:
 configure(state)
 if not registry.ready():return {}
 var battle := {"version":1,"encounter_sha":pin,"site_id":site_id,"board":definition.duplicate(true),"units":{},"order":[],"cursor":0,"round":1,"revision":0,"status":"active","reason":"","budget":{"move":1,"main":1},"rng":RulesRng.initial(RulesJson.digest([state.world_ref,state.origin,site_id,definition.id])),"log":[],"commands":[]}
 for i in state.party_ids.size():
  var id: String = state.party_ids[i]
  var member: Dictionary = state.party.members[i]
  var record: Dictionary = state.mechanics.records[id].duplicate(true)
  # A downed character can join this first encounter only after minimal recovery.
  record.runtime.hp=maxi(1,int(record.runtime.hp))
  var weapon := weapon_for(record)
  battle.units[id]=unit(id,member.name,"party",definition.party_positions[i],record,weapon)
  battle.order.append(id)
 for enemy in definition.enemies:
  var recommendation: Dictionary = registry.recommendation(enemy.role)
  var record := characters.create(enemy.id,recommendation.attributes,"heritage-human")
  record.equipment=[enemy.weapon] # Fixed lightly armed opponents; no equipment generation.
  var choice := characters.suggested_choice(record,recommendation["class"],recommendation.feat)
  var advanced := characters.apply_advancement(record,choice.choice,0)
  record=advanced.candidate
  battle.units[enemy.id]=unit(enemy.id,enemy.name,"enemy",enemy.position,record,enemy.weapon)
  battle.order.append(enemy.id)
 # Stable initiative, ties resolve by authored/party order. No random initiative.
 var ranks := {};var initiative := {}
 for i in battle.order.size():
  var id: String=battle.order[i]
  ranks[id]=i;initiative[id]=int(stats(battle.units[id]).initiative)
 battle.order.sort_custom(func(a: String,b: String): return initiative[a]>initiative[b] if initiative[a]!=initiative[b] else ranks[a]<ranks[b])
 battle.log.append("The party meets armed raiders on the approach to this local site." if not definition.has("generation") else "The party approaches the generated site: "+str(definition.title)+".")
 return seal(battle)

static func weapon_for(record: Dictionary) -> String:
 if record.get("rules_ref",{}).get("engine_schema")==3:
  for id in record.equipment:
   if RulesRecords.registry(record).definition("equipment",id).get("kind")=="weapon":return id
 return "bow" if record.equipment.has("bow") else "staff" if record.equipment.has("staff") else "shortblade"

func unit(id: String, title: String, team: String, position: Array, record: Dictionary, weapon: String) -> Dictionary:
 return {"id":id,"name":title,"team":team,"position":position.duplicate(),"record":record,"weapon":weapon,"reaction":1,"precision_used":false}

func stats(u: Dictionary) -> Dictionary:
 return characters.derive_character(u.record).snapshot.stats
func alive(u: Dictionary) -> bool: return int(u.record.runtime.hp)>0
func current(b: Dictionary) -> Dictionary: return b.units[b.order[int(b.cursor)]]
func distance(a: Array,b: Array) -> int: return absi(int(a[0])-int(b[0]))+absi(int(a[1])-int(b[1]))
func inside(b: Dictionary,p: Array) -> bool:
 return p.size()==2 and RulesJson.integer(p[0],0,int(b.board.width)-1) and RulesJson.integer(p[1],0,int(b.board.height)-1) and not blocked(b,p)
func blocked(b: Dictionary,p: Array) -> bool:
 return b.board.blocked.any(func(tile: Array):return distance(tile,p)==0)
func occupant(b: Dictionary,p: Array) -> String:
 for id in b.order:
  if alive(b.units[id]) and distance(b.units[id].position,p)==0: return id
 return ""
func neighbours(p: Array) -> Array:
 return [[int(p[0]),int(p[1])-1],[int(p[0])-1,int(p[1])],[int(p[0])+1,int(p[1])],[int(p[0]),int(p[1])+1]]
func paths(b: Dictionary,u: Dictionary) -> Dictionary:
 if RulesCapabilities.enabled(registry) and characters.derive_character(u.record).snapshot.capabilities.immobile:return {}
 b=RulesJson.normalize(b);u=RulesJson.normalize(u)
 var found := {str(u.position):[u.position]}
 var queue: Array = [u.position]
 var index := 0
 var stride: int=int(stats(u).stride)
 while index<queue.size():
  var p: Array = queue[index];index+=1
  if found[str(p)].size()-1>=stride: continue
  for n in neighbours(p):
   if not inside(b,n) or not occupant(b,n).is_empty() or found.has(str(n)): continue
   found[str(n)]=found[str(p)].duplicate();found[str(n)].append(n);queue.append(n)
 return found
func line_clear(b: Dictionary,a: Array,z: Array) -> bool:
 # Symmetric supercover: crossing a blocked tile or corner blocks the shot.
 var dx := int(z[0])-int(a[0]);var dy := int(z[1])-int(a[1])
 var nx := absi(dx);var ny := absi(dy)
 var sx := signi(dx);var sy := signi(dy)
 var x := int(a[0]);var y := int(a[1]);var ix := 0;var iy := 0
 while ix<nx or iy<ny:
  var decision := (1+2*ix)*ny-(1+2*iy)*nx
  if decision==0:
   if blocked(b,[x+sx,y]) or blocked(b,[x,y+sy]): return false
   x+=sx;y+=sy;ix+=1;iy+=1
  elif decision<0: x+=sx;ix+=1
  else: y+=sy;iy+=1
  if blocked(b,[x,y]): return false
 return true
func threat_reach(u: Dictionary) -> int:
 if RulesCapabilities.enabled(registry):return maxi(1,int(stats(u).reach))
 return 1
func weapon_range(u: Dictionary) -> int:
 var value: int=int(registry.definition("equipment",u.weapon).range)
 return maxi(value,threat_reach(u)) if RulesCapabilities.enabled(registry) else value
func engaged(b: Dictionary,u: Dictionary) -> bool:
 for id in b.order:
  var other: Dictionary=b.units[id]
  if alive(other) and other.team!=u.team and distance(other.position,u.position)<=threat_reach(other): return true
 return false
func eligible(b: Dictionary,u: Dictionary,t: Dictionary,ability: String) -> bool:
 if not alive(t): return false
 if registry.rules_ref().engine_schema==3 and ability!="attack":
  var definition := registry.definition("abilities",ability)
  if definition.is_empty() or definition.tags.has("passive") or definition.has("trigger"):return false
  var targeting: Dictionary=definition.targeting
  if targeting.kind=="self":return u.id==t.id
  if targeting.kind=="ally":return t.team==u.team and distance(u.position,t.position)<=int(targeting.get("range",0)) and line_clear(b,u.position,t.position)
  if targeting.kind!="creature" or t.team==u.team:return false
  if definition.tags.has("weapon_strike"):
   var weapon := registry.definition("equipment",definition.get("attack_weapon",u.weapon))
   if definition.tags.has("flurry") and u.weapon!="unarmed":return false
   if definition.tags.has("power_strike") and weapon.tags.has("ranged"):return false
   return distance(u.position,t.position)<=(int(weapon.range) if definition.has("attack_weapon") else weapon_range(u)) and line_clear(b,u.position,t.position)
  return distance(u.position,t.position)<=int(targeting.get("range",1)) and line_clear(b,u.position,t.position)
 if ability=="guard": return u.id==t.id
 if ability=="healing-thread": return t.team==u.team and distance(u.position,t.position)<=1
 if t.team==u.team: return false
 var reach: int=weapon_range(u) if ability=="attack" else 5
 return distance(u.position,t.position)<=reach and line_clear(b,u.position,t.position)

func command(source: Dictionary,input: Dictionary) -> Dictionary:
 source=RulesJson.normalize(source)
 if source.get("units") is Dictionary and not source.units.is_empty():configure(source.units.values()[0].get("record",{}))
 if not registry.ready():return fail("Rules pack unavailable")
 # Dot-added GDScript keys can be StringName; JSON saves contain Strings.
 input=RulesJson.normalize(JSON.parse_string(JSON.stringify(input)))
 if source.status!="active" or input.get("revision")!=source.revision: return fail("This turn changed. Resume the saved battle.")
 var b := source.duplicate(true)
 var actor := current(b)
 if input.get("actor_id")!=actor.id: return fail("It is another character's turn.")
 var kind: String=str(input.get("kind",""))
 if kind=="retreat": b.status="defeat";b.reason="retreat";b.log.append("The party withdraws from the raiders.")
 elif kind=="end": next_turn(b)
 elif kind=="move":
  if int(b.budget.move)<1: return fail("Movement already used this turn.")
  var destination = input.get("destination",[])
  if not destination is Array or not inside(b,destination): return fail("Choose a clear battlefield tile.")
  var reachable := paths(b,actor)
  if destination==actor.position or not reachable.has(str(destination)): return fail("That tile cannot be reached this turn.")
  var route: Array=reachable[str(destination)]
  for i in range(1,route.size()):
   var previous: Array=actor.position
   for id in b.order:
    var enemy: Dictionary=b.units[id]
    if alive(enemy) and enemy.team!=actor.team and int(enemy.reaction)>0 and distance(enemy.position,previous)<=threat_reach(enemy) and distance(enemy.position,route[i])>threat_reach(enemy):
     enemy.reaction=0
     weapon_attack(b,enemy,actor,true)
     if not alive(actor): break
   if not alive(actor): break
   actor.position=route[i].duplicate()
  b.budget.move=0;b.log.append(actor.name+" moves.")
  if not alive(actor): next_turn(b)
 elif kind in ["attack","guard","spark","slow","healing-thread"] or registry.rules_ref().engine_schema==3 and not registry.definition("abilities",kind).is_empty():
  var definition := registry.definition("abilities",kind)
  var target_id: String=str(input.get("target_id",actor.id if definition.targeting.kind=="self" else ""))
  if not b.units.has(target_id) or not eligible(b,actor,b.units[target_id],kind): return fail("Choose a living target in range and line of sight.")
  var target: Dictionary=b.units[target_id]
  var budget := {"move":int(b.budget.move),"main":int(b.budget.main),"reaction":int(actor.reaction)}
  var used := effects.use_ability(actor.record,target.record,kind,budget,b.rng)
  if not used.ok: return fail("Action unavailable: "+RulesJson.canonical(used.errors))
  actor.record=used.actor;target.record=used.target;b.rng=used.rng
  b.budget={"move":used.budget.move,"main":used.budget.main};actor.reaction=used.budget.reaction
  if registry.rules_ref().engine_schema==3 and int(definition.targeting.get("radius",0))>0:
   # The action/slot is spent exactly once. Deterministic allies are resolved in turn order.
   for id in b.order:
    var ally: Dictionary=b.units[id]
    if id==target.id or ally.team!=target.team or not alive(ally) or distance(target.position,ally.position)>int(definition.targeting.radius) or not line_clear(b,target.position,ally.position):continue
    var actor_snapshot: Dictionary= characters.derive_character(actor.record).snapshot
    var ally_snapshot: Dictionary= characters.derive_character(ally.record).snapshot
    var context := {"source_character_id":actor.id,"character_id":actor.id,"target_id":ally.id,"stats":actor_snapshot.stats,"target_stats":ally_snapshot.stats,"target_tags":ally_snapshot.tags,"attributes":actor_snapshot.attributes,"classes":actor_snapshot.class_levels,"capacities":actor_snapshot.resource_capacities}
    if RulesCapabilities.enabled(registry):
     context.target_capabilities=ally_snapshot.capabilities;context.capabilities=actor_snapshot.capabilities;context.casting_levels=actor_snapshot.casting_levels
    for effect in definition.effects:
     var area := effects.resolve_rules_effect(effect,actor.record.runtime,ally.record.runtime,context,b.rng)
     if not area.ok:return fail("Area effect unavailable: "+RulesJson.canonical(area.errors))
     ally.record.runtime=area.target;actor.record.runtime=area.actor;b.rng=area.rng;used.events.append_array(area.events)
  if kind=="attack": weapon_attack(b,actor,target,false)
  elif registry.rules_ref().engine_schema==3 and definition.tags.has("weapon_strike"):
   weapon_attack(b,actor,target,false,kind)
   if definition.tags.has("flurry") and alive(target):weapon_attack(b,actor,target,false,kind)
  else: b.log.append(actor.name+" uses "+registry.definition("abilities",kind).name+" on "+target.name+". "+ability_summary(used.events))
 else: return fail("Unknown battle action.")
 finish_if_needed(b)
 b.revision+=1;b.commands.append(input.duplicate(true))
 return {"ok":true,"battle":seal(b)}

func ability_summary(events: Array) -> String:
 var summaries: Array[String]=[]
 for event in events:
  if event.type=="save_resolved": summaries.append("Save %d + %d vs %d: %s."%[event.roll,event.bonus,event.dc,"resisted" if event.success else "failed"])
  elif event.type=="damage_applied": summaries.append("%d damage."%event.amount)
  elif event.type=="healing_applied": summaries.append("%d HP restored."%event.amount)
  elif event.type=="status_applied": summaries.append(str(event.id).capitalize()+" applied.")
 return " ".join(summaries)

func weapon_attack(b: Dictionary,a: Dictionary,t: Dictionary,reaction: bool,technique: String="") -> void:
 var weapon := registry.definition("equipment","shortblade" if reaction and a.weapon=="bow" else a.weapon)
 var attack_weapon: String=str(registry.definition("abilities",technique).get("attack_weapon",a.weapon)) if RulesCapabilities.enabled(registry) else str(a.weapon)
 if attack_weapon!=a.weapon:weapon=registry.definition("equipment",attack_weapon)
 if registry.rules_ref().engine_schema==3 and attack_weapon=="unarmed" and int(characters.derive_character(a.record).snapshot.class_levels.get("monk",0))>=4:weapon=weapon.duplicate(true);weapon.damage="1d8"
 if RulesCapabilities.enabled(registry):
  var overrides: Dictionary=characters.derive_character(a.record).snapshot.capabilities.weapon_damage
  if overrides.has(attack_weapon):weapon=weapon.duplicate(true);weapon.damage=overrides[attack_weapon]
 var ranged: bool=weapon.tags.has("ranged")
 var s := stats(a)
 var bonus: int=int(s.ranged_attack if ranged else s.melee_attack)
 if registry.rules_ref().engine_schema==3:
  var snap: Dictionary= characters.derive_character(a.record).snapshot
  if snap.tags.has("favoured_raider") and t.team=="enemy":bonus+=2
  # GAME119 v7-only target profile; frozen legacy branch above remains exact.
  if RulesCareer.enabled(registry) and RulesCareer.quarry_matches(snap,t,registry):bonus+=2
  if technique in ["power-strike","flurry"]:bonus-=2
  if technique=="aimed-shot":bonus+=2
  if technique=="smite":bonus+=maxi(0,int(floor(float(int(snap.attributes.CHA)-10)/2.0)))
 if ranged and engaged(b,a): bonus-=4
 if RulesCapabilities.enabled(registry):
  var chance: int=int(characters.derive_character(t.record).snapshot.capabilities.concealment)
  if chance>0:
   var conceal := RulesRng.roll("1d100",b.rng);b.rng=conceal.rng
   if int(conceal.total)<=chance:
    b.log.append(a.name+" loses the target in concealment.");return
 var roll := RulesRng.attack_roll(bonus,int(stats(t).defence),registry.rule("critical"),b.rng)
 b.rng=roll.rng
 if not roll.hit:
  b.log.append("%s %s %s: %d + %d vs %d, miss."%[a.name,"reacts against" if reaction else "attacks",t.name,roll.total,bonus,stats(t).defence]);return
 var damage := RulesRng.roll(weapon.damage,b.rng);b.rng=damage.rng
 var amount: int=int(damage.total)+int(roll.critical_bonus)
 if registry.rules_ref().engine_schema==3:
  var snap: Dictionary= characters.derive_character(a.record).snapshot
  amount+=int(s.damage)
  if not ranged:amount+=int(floor(float(int(snap.attributes.STR)-10)/2.0))
  if snap.tags.has("favoured_raider") and t.team=="enemy":amount+=2
  # GAME119 v7-only target profile; frozen legacy branch above remains exact.
  if RulesCareer.enabled(registry) and RulesCareer.quarry_matches(snap,t,registry):amount+=2
  if technique=="power-strike":amount+=4
  if technique=="smite":amount+=int(snap.class_levels.get("paladin",0))
 else:
  if not ranged:amount+=maxi(0,int(floor((int(a.record.base_attributes.STR)-10)/2.0)))
 var allied_threat := false
 for id in b.order:
  var ally: Dictionary=b.units[id]
  if ally.id!=a.id and ally.team==a.team and alive(ally) and distance(ally.position,t.position)==1: allied_threat=true
 if not a.precision_used and allied_threat and characters.derive_character(a.record).snapshot.abilities.has("precision"):
  var precision := effects.use_ability(a.record,t.record,"precision",{"move":1,"main":1,"reaction":a.reaction},b.rng,{"trigger":"qualifying_hit","tags":["allied_melee_threat"],"event_id":str(b.revision)})
  if precision.ok:
   for event in precision.events:
    if event.type=="event_modifier" and event.stat=="damage": amount+=int(event.value) if registry.rules_ref().engine_schema!=3 else 2*int(ceil(float(characters.derive_character(a.record).snapshot.class_levels.get("rogue",0))/2.0))
   a.precision_used=true;b.log.append(a.name+" finds an opening: Precision +"+str(2*int(ceil(float(characters.derive_character(a.record).snapshot.class_levels.get("rogue",0))/2.0)))+"." if registry.rules_ref().engine_schema==3 else a.name+" finds an opening: Precision +4.")
 for id in b.order:
  var guard: Dictionary=b.units[id]
  if guard.id!=t.id and guard.team==t.team and alive(guard) and int(guard.reaction)>0 and distance(guard.position,t.position)==1 and guard.record.runtime.statuses.any(func(v: Dictionary):return v.id=="guarding"):
   guard.reaction=0;amount=maxi(0,amount-4);b.log.append(guard.name+" protects "+t.name+": damage reduced by 4.");break
 if RulesCapabilities.enabled(registry):
  var caps: Dictionary=characters.derive_character(a.record).snapshot.capabilities
  if not reaction and b.budget.move==0 and not a.precision_used and int(caps.moving_damage)>0:
   amount+=int(caps.moving_damage);a.precision_used=true;b.log.append(a.name+" exploits movement: +"+str(caps.moving_damage)+" damage.")
  amount=RulesCapabilities.reduce_damage(amount,str(weapon.get("damage_type","physical")),characters.derive_character(t.record).snapshot.capabilities)
 amount=maxi(0,amount)
 var absorbed := mini(amount,int(t.record.runtime.temporary_hp))
 t.record.runtime.temporary_hp-=absorbed
 t.record.runtime.hp=maxi(0,int(t.record.runtime.hp)-(amount-absorbed))
 b.log.append("%s hits %s: %d + %d vs %d, %d damage%s."%[a.name,t.name,roll.total,bonus,stats(t).defence,amount," (critical)" if roll.critical else ""])
 if not alive(t): b.log.append(t.name+" is down.")

func next_turn(b: Dictionary) -> void:
 var old := current(b)
 old.record.runtime=effects.expire_statuses(old.record.runtime,"target_activation_end").runtime
 for i in b.order.size():
  b.cursor=(int(b.cursor)+1)%b.order.size()
  if b.cursor==0:
   b.round+=1
   for id in b.order:
    var u: Dictionary=b.units[id]
    u.reaction=1;u.precision_used=false
    u.record.runtime=effects.expire_statuses(u.record.runtime,"global_round_start").runtime
  if alive(current(b)): break
 b.budget={"move":1,"main":1}
func finish_if_needed(b: Dictionary) -> void:
 for team in ["enemy","party"]:
  if not b.units.values().any(func(u: Dictionary):return u.team==team and alive(u)):
   b.status="victory" if team=="enemy" else "defeat";b.reason="opponents_downed" if team=="enemy" else "party_downed"
   b.log.append("Victory: the raiders withdraw." if b.status=="victory" else "Defeat: the party is driven back.")
   return

func enemy_command(b: Dictionary) -> Dictionary:
 b=RulesJson.normalize(b)
 var a := current(b)
 var targets: Array=b.order.filter(func(id: String):return b.units[id].team!=a.team and alive(b.units[id]))
 targets.sort_custom(func(x: String,y: String):
  var dx := distance(a.position,b.units[x].position);var dy := distance(a.position,b.units[y].position)
  return dx<dy if dx!=dy else b.order.find(x)<b.order.find(y))
 var input := {"revision":b.revision,"actor_id":a.id,"kind":"end"}
 if int(b.budget.main)>0:
  for id in targets:
   if eligible(b,a,b.units[id],"attack"): input.kind="attack";input["target_id"]=id;return input
 if int(b.budget.move)>0 and not targets.is_empty():
  var reachable := paths(b,a)
  var best: Array=a.position
  var best_score: int=distance(best,b.units[targets[0]].position)
  for path in reachable.values():
   var p: Array=path.back()
   var score := distance(p,b.units[targets[0]].position)
   if score<best_score: best=p;best_score=score
  if best!=a.position: input.kind="move";input["destination"]=best
 return input
func seal(b: Dictionary) -> Dictionary:
 b.erase("state_hash");b["state_hash"]=RulesJson.digest(b);return b
func validate(b: Dictionary) -> String:
 b=RulesJson.normalize(b)
 if b.get("units") is Dictionary and not b.units.is_empty():
  var first: Variant=b.units.values()[0]
  if first is Dictionary and first.get("record") is Dictionary:configure(first.record)
 if not registry.ready():return "Rules pack unavailable"
 if not b.has_all(["version","encounter_sha","site_id","board","units","order","cursor","round","revision","status","reason","budget","rng","log","commands","state_hash"]): return "Incomplete battle"
 var generated: bool=b.board is Dictionary and b.board.has("generation")
 if b.version!=1 or (not generated and CombatBattlefields.identify(b).is_empty()) or (generated and (not SandboxGenerator.valid_board(b.board) or b.encounter_sha!=RulesJson.digest(b.board) or b.board.generation.site_id!=b.site_id)): return "Battlefield pin mismatch"
 var copy := b.duplicate(true);copy.erase("state_hash")
 if RulesJson.digest(copy)!=b.state_hash: return "Battle checksum mismatch"
 var count: int=3+b.board.enemies.size()
 if not b.units is Dictionary or not b.order is Array or b.order.size()!=count or b.units.size()!=count or not RulesJson.integer(b.cursor,0,count-1) or not RulesJson.integer(b.round,1,100000) or not RulesJson.integer(b.revision,0,100000) or not b.status in ["active","victory","defeat"] or not RulesRng.valid_state(b.rng): return "Invalid battle state"
 if not b.budget is Dictionary or b.budget.size()!=2 or not RulesJson.integer(b.budget.get("move"),0,1) or not RulesJson.integer(b.budget.get("main"),0,1) or not b.log is Array or not b.commands is Array or b.commands.size()!=int(b.revision): return "Invalid action history"
 var occupied := {};var seen := {}
 for id in b.order:
  if not id is String or not b.units.get(id) is Dictionary: return "Invalid unit identity"
  if seen.has(id): return "Duplicate turn identity"
  seen[id]=true
  var u: Dictionary=b.units[id]
  if not u.has_all(["id","name","team","position","record","weapon","reaction","precision_used"]) or u.id!=id or not u.name is String or registry.definition("equipment",str(u.weapon)).get("kind")!="weapon" or not u.team in ["party","enemy"] or not u.position is Array or not inside(b,u.position) or not RulesJson.integer(u.reaction,0,1) or not u.precision_used is bool or not characters.validate_build(u.record).ok or u.record.character_id!=id: return "Invalid unit"
  if alive(u):
   if occupied.has(str(u.position)): return "Overlapping units"
   occupied[str(u.position)]=true
 if b.status=="active" and not alive(current(b)): return "Downed active unit"
 return ""
func fail(why: String) -> Dictionary: return {"ok":false,"error":why}
