class_name TacticalAuras
extends TacticalCombat
## Versioned presentation/effect adapter. Frozen GAME-32 command/target/turn/attack authority is inherited.
var _channel_error := ""
func command(source: Dictionary,input: Dictionary) -> Dictionary:
 _channel_error=""
 var result := super.command(source,input)
 return fail(_channel_error) if not _channel_error.is_empty() else result
func eligible(b: Dictionary,u: Dictionary,t: Dictionary,ability: String) -> bool:
 if registry.rules_ref().get("pack_id")=="trhgd-character-v17":
  var definition := registry.definition("abilities",ability)
  if definition.get("tags",[]).has("spell") and characters.derive_character(u.record).snapshot.tags.has("spell_suppressed"):return false
  # Recovery can reach a downed campaign character, never an expired summon or
  # a slain enemy. Turn order, initiative and current action budgets stay intact.
  if definition.get("tags",[]).has("recover_downed") and not alive(t):
   return occupant(b,t.position).is_empty() and t.team==u.team and not t.has("entity") and definition.targeting.kind=="ally" and distance(u.position,t.position)<=int(definition.targeting.range) and line_clear(b,u.position,t.position)
 if RulesWaveFive.enabled(registry) and registry.definition("abilities",ability).has("channel_spell") and not RulesWaveFive.melee_weapon(u.record,active_weapon(u),registry):return false
 return super.eligible(b,u,t,ability)
func seal(b: Dictionary) -> Dictionary:
 if RulesWaveFour.enabled(registry):
  RulesWaveFour.project_auras(self,b)
  CombatEntities.capture(b)
 return super.seal(b)
func weapon_attack(b: Dictionary,a: Dictionary,t: Dictionary,reaction: bool,technique: String="") -> void:
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
