class_name TacticalAuras
extends TacticalCombat
## Versioned presentation/effect adapter. Frozen GAME-32 command/target/turn/attack authority is inherited.
var _channel_error := ""
func command(source: Dictionary,input: Dictionary) -> Dictionary:
 _channel_error=""
 var result := super.command(source,input)
 if not _channel_error.is_empty():return fail(_channel_error)
 # A newly supported counter may defeat the currently acting character. Finish
 # that activation through the same turn authority, never leave a dead cursor.
 if result.ok and RulesMartial.enabled(registry) and result.battle.status=="active" and not alive(current(result.battle)):
  next_turn(result.battle);result.battle=seal(result.battle)
 return result
func eligible(b: Dictionary,u: Dictionary,t: Dictionary,ability: String) -> bool:
 if registry.rules_ref().get("pack_id") in ["trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21"]:
  var definition := registry.definition("abilities",ability)
  if definition.get("tags",[]).has("spell") and characters.derive_character(u.record).snapshot.tags.has("spell_suppressed"):return false
  # Recovery can reach a downed campaign character, never an expired summon or
  # a slain enemy. Turn order, initiative and current action budgets stay intact.
  if definition.get("tags",[]).has("recover_downed") and not alive(t):
   return occupant(b,t.position).is_empty() and t.team==u.team and not t.has("entity") and definition.targeting.kind=="ally" and distance(u.position,t.position)<=int(definition.targeting.range) and line_clear(b,u.position,t.position)
 if RulesMartial.enabled(registry):
  if registry.definition("equipment",str(u.weapon)).get("tags",[]).has("manifested"):return false
  var row := registry.definition("abilities",ability)
  if RulesMartial.mobile_enabled(registry) and row.get("requires_fencing",false) and not RulesMartial.fencing_equipment(u.record,registry):return false
  if row.has("requires_status") and not u.record.runtime.statuses.any(func(s: Dictionary):return s.id==row.requires_status):return false
  if row.has("requires_weapon") and active_weapon(u)!=row.requires_weapon:return false
  if row.get("requires_melee",false) and not RulesWaveFive.melee_weapon(u.record,active_weapon(u),registry):return false
 if RulesWaveFive.enabled(registry) and registry.definition("abilities",ability).has("channel_spell") and not RulesWaveFive.melee_weapon(u.record,active_weapon(u),registry):return false
 return super.eligible(b,u,t,ability)
func seal(b: Dictionary) -> Dictionary:
 if RulesWaveFour.enabled(registry):
  RulesWaveFour.project_auras(self,b)
  CombatEntities.capture(b)
 return super.seal(b)
func _historical_attack(b: Dictionary,a: Dictionary,t: Dictionary,reaction: bool,technique: String="") -> void:
 if RulesWaveFour.enabled(registry):RulesWaveFour.project_auras(self,b)
 var ability := registry.definition("abilities",technique)
 if RulesWaveFive.enabled(registry) and not reaction and ability.has("channel_spell"):
  var events := RulesAttackTrace.capture(_delegated_attack.bind(b,a,t,reaction,technique))
  if events.any(func(event: Dictionary):return event.get("type")=="attack_resolved" and event.get("hit",false)):
   var applied := RulesWaveFive.channel_effects(a.record,t.record,ability.channel_spell,b.rng,registry)
   if not applied.ok:_channel_error="Channel effect unavailable: "+RulesJson.canonical(applied.errors);return
   a.record=applied.actor;t.record=applied.target;b.rng=applied.rng
   b.log.append(a.name+" channels "+registry.definition("abilities",ability.channel_spell).name+". "+ability_summary(applied.events))
  else:b.log.append(a.name+" loses the channelled spell: action and slot spent; no spell effect on a missed or concealed strike.")
 else:super.weapon_attack(b,a,t,reaction,technique)
func _delegated_attack(b: Dictionary,a: Dictionary,t: Dictionary,reaction: bool,technique: String) -> void:
 super.weapon_attack(b,a,t,reaction,technique)

func active_weapon(u: Dictionary) -> String:
 if RulesMartial.enabled(registry) and RulesEntities.form(u.record,registry).is_empty():
  for status in u.record.runtime.statuses:
   var row := registry.definition("statuses",status.id)
   if row.has("weapon_override"):return row.weapon_override
 return super.active_weapon(u)

func weapon_attack(b: Dictionary,a: Dictionary,t: Dictionary,reaction: bool,technique: String="") -> void:
 if not RulesMartial.enabled(registry):
  _historical_attack(b,a,t,reaction,technique);return
 if not alive(a):return # A previous flurry strike may have provoked a lethal counter.
 RulesWaveFour.project_auras(self,b)
 var ability := registry.definition("abilities",technique)
 var weapon := registry.definition("equipment",ability.get("attack_weapon",active_weapon(a)))
 var melee: bool=not weapon.tags.has("ranged")
 var events := RulesAttackTrace.capture(_delegated_attack.bind(b,a,t,reaction,technique))
 # No attack result means concealment prevented an attack roll. It is not an
 # accuracy miss and cannot trigger a riposte or deliver any hit rider.
 if events.is_empty():return
 var hit: bool=events[0].get("hit",false)
 if hit and ability.has("channel_spell"):
  var result := RulesWaveFive.channel_effects(a.record,t.record,ability.channel_spell,b.rng,registry)
  if not result.ok:_channel_error="Channel effect unavailable: "+RulesJson.canonical(result.errors);return
  a.record=result.actor;t.record=result.target;b.rng=result.rng
  b.log.append(a.name+" channels "+registry.definition("abilities",ability.channel_spell).name+". "+ability_summary(result.events))
 elif not hit and ability.has("channel_spell"):
  b.log.append(a.name+" loses the channelled spell: action and slot spent; no effect on a miss.")
 if hit and ability.has("strike_effects"):
  var applied := RulesMartial.apply_hit(a.record,t.record,ability,b.rng,registry)
  if not applied.ok:_channel_error="Strike effect unavailable: "+RulesJson.canonical(applied.errors);return
  a.record=applied.actor;t.record=applied.target;b.rng=applied.rng
  b.log.append(a.name+" confirms "+ability.name+". "+ability_summary(applied.events))
 # Triggered/counter/opportunity attacks never recursively trigger more attacks.
 if reaction or not melee:return
 if hit:_martial_event(b,a,t,"weapon_hit")
 _martial_event(b,t,a,"melee_hit" if hit else "melee_miss")

func _martial_event(b: Dictionary,owner: Dictionary,other: Dictionary,event: String) -> void:
 if not alive(owner):return
 var owned: Array=characters.derive_character(owner.record).snapshot.abilities.duplicate();owned.sort()
 for id in owned:
  var row := registry.definition("abilities",id)
  if row.get("trigger")!=event:continue
  if row.get("counterattack",false) and (not alive(other) or not RulesWaveFive.melee_weapon(owner.record,active_weapon(owner),registry) or distance(owner.position,other.position)>weapon_range(owner) or not line_clear(b,owner.position,other.position)):continue
  var target: Dictionary=owner if row.targeting.kind=="self" else other
  var result := effects.use_ability(owner.record,target.record,id,{"main":0,"move":0,"reaction":int(owner.reaction)},b.rng,{"trigger":event,"event_id":str(b.revision)})
  if not result.ok:continue
  owner.record=result.actor;target.record=result.target;owner.reaction=result.budget.reaction;b.rng=result.rng
  b.log.append(owner.name+" triggers "+row.name+". "+ability_summary(result.events))
  if row.get("counterattack",false):weapon_attack(b,owner,other,true)

func next_turn(b: Dictionary) -> void:
 super.next_turn(b)
 if RulesMartial.enabled(registry) and alive(current(b)):_martial_event(b,current(b),current(b),"activation_start")

func create_definition(state: Dictionary,site_id: String,definition: Dictionary,pin: String) -> Dictionary:
 var battle := super.create_definition(state,site_id,definition,pin)
 if not battle.is_empty() and RulesMartial.enabled(registry):
  _martial_event(battle,current(battle),current(battle),"activation_start")
  return seal(battle)
 return battle

func validate(b: Dictionary) -> String:
 var why := super.validate(b)
 if not why.is_empty():return why
 if RulesMartial.enabled(registry):
  for unit in b.units.values():
   if registry.definition("equipment",str(unit.weapon)).get("tags",[]).has("manifested"):return "Manifested weapons cannot be stored as held equipment"
 return ""

func area_preview(b: Dictionary,u: Dictionary,t: Dictionary,ability: String) -> Array:
 var row := registry.definition("abilities",ability)
 if row.is_empty() or not eligible(b,u,t,ability):return []
 var result: Array=[]
 for id in b.order:
  var other: Dictionary=b.units[id]
  if id==t.id or (other.team==t.team and alive(other) and distance(t.position,other.position)<=int(row.targeting.get("radius",0)) and line_clear(b,t.position,other.position)):result.append(id)
 return result
