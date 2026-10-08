class_name RulesEffects
extends RefCounted
var registry: RulesRegistry
var characters: RulesCharacter
func _init(source: RulesRegistry) -> void:
 registry=source;characters=RulesCharacter.new(source)

func activation_budget(remaining_reaction: int) -> Dictionary:
 if remaining_reaction<0 or remaining_reaction>int(registry.rule("shared_reaction")): return {"ok":false,"errors":[RulesJson.issue("cost.reaction","budget","Invalid shared reaction remainder")]}
 return {"ok":true,"budget":{"move":1,"main":1,"reaction":remaining_reaction}}

func refresh_shared_reaction(budget: Dictionary,trigger: String) -> Dictionary:
 if trigger!="global_round_start" or budget.size()!=3 or not ["move","main","reaction"].all(func(k: String): return RulesJson.integer(budget.get(k),0,1)): return RulesJson.result([RulesJson.issue("cost.refresh","reaction","Only an explicit global round boundary refreshes the shared reaction")])
 var candidate := budget.duplicate(true);candidate.reaction=int(registry.rule("shared_reaction"))
 return {"ok":true,"budget":candidate,"events":[{"type":"shared_reaction_refreshed","boundary":trigger}]}

func validate_ability_cost(ability_id: String, runtime: Dictionary, budget: Dictionary) -> Dictionary:
 var ability := registry.definition("abilities",ability_id)
 if ability.is_empty(): return RulesJson.result([RulesJson.issue("ability.missing",ability_id,"Unknown ability")])
 var errors: Array=[]
 if budget.size()!=3: errors.append(RulesJson.issue("cost.budget","budget","Only move/main/shared-reaction tokens are supported"))
 for token in ["move","main","reaction"]:
  if not RulesJson.integer(budget.get(token),0,1): errors.append(RulesJson.issue("cost.budget",token,"Invalid action token"))
  elif int(budget[token])<int(ability.cost[token]): errors.append(RulesJson.issue("cost."+token,token,"Action token unavailable"))
 if not runtime.get("resources") is Dictionary: errors.append(RulesJson.issue("cost.resources","resources","Current resources are unavailable"))
 else:
  for id in ability.cost.resources:
   if not RulesJson.integer(runtime.resources.get(id),0,100000) or int(runtime.resources.get(id,0))<int(ability.cost.resources[id]): errors.append(RulesJson.issue("cost.resource",id,"Insufficient current resource"))
 return RulesJson.result(errors)

func use_ability(actor: Dictionary,target: Dictionary,ability_id: String,budget: Dictionary,rng: Dictionary,event_context: Dictionary = {}) -> Dictionary:
 if not RulesRng.valid_state(rng): return RulesJson.result([RulesJson.issue("rng.state","rng","Explicit validated RNG required")])
 var a := characters.derive_character(actor)
 if not a.ok: return a
 var t := characters.derive_character(target)
 if not t.ok: return t
 var ability := registry.definition("abilities",ability_id)
 if ability.is_empty() or not a.snapshot.abilities.has(ability_id): return RulesJson.result([RulesJson.issue("ability.unowned",ability_id,"Actor does not own the ability")])
 var requirements := RulesExpressions.evaluate_requirements(ability.requirements,a.context)
 if not requirements.ok: return requirements
 var cost := validate_ability_cost(ability_id,actor.runtime,budget)
 if not cost.ok: return cost
 if ability.has("trigger") and event_context.get("trigger")!=ability.trigger: return RulesJson.result([RulesJson.issue("ability.trigger",ability_id,"Required explicit trigger context is absent")])
 if ability.tags.has("passive") and event_context.get("trigger")!="qualifying_hit": return RulesJson.result([RulesJson.issue("ability.passive",ability_id,"Passive descriptors require their declared event")])
 if actor.character_id==target.character_id and actor!=target: return RulesJson.result([RulesJson.issue("ability.identity",ability_id,"Two different records share the same ID")])
 var new_actor: Dictionary=actor.duplicate(true)
 var new_target: Dictionary=new_actor if actor.character_id==target.character_id else target.duplicate(true)
 var new_budget := budget.duplicate(true)
 var events: Array=[]
 for token in ["move","main","reaction"]: new_budget[token]=int(new_budget[token])-int(ability.cost[token])
 for id in ability.cost.resources:
  new_actor.runtime.resources[id]=int(new_actor.runtime.resources[id])-int(ability.cost.resources[id])
  events.append({"type":"resource_spent","character_id":actor.character_id,"id":id,"amount":int(ability.cost.resources[id])})
 var context: Dictionary=a.context.duplicate(true)
 for field in event_context:
  if not field in ["tags","trigger","event_id","apparent_id","observer_id"]: return RulesJson.result([RulesJson.issue("ability.context_field",str(field),"Authoritative values cannot be supplied as event context")])
  if field=="tags":
   if not event_context.tags is Array or not event_context.tags.all(func(v: Variant): return v is String): return RulesJson.result([RulesJson.issue("ability.context_tags","tags","Explicit tactical tags must be strings")])
   for tag in event_context.tags:
    if not context.tags.has(tag): context.tags.append(tag)
  else:
   if not event_context[field] is String: return RulesJson.result([RulesJson.issue("ability.context_value",str(field),"Event identifiers must be strings")])
   context[field]=event_context[field]
 # Reserved authoritative fields cannot be overridden by hook/event payloads.
 context.character_id=actor.character_id;context.source_character_id=actor.character_id
 context.target_id=target.character_id;context.target_stats=t.snapshot.stats
 context.target_capacities=t.snapshot.resource_capacities
 context.stats=a.snapshot.stats;context.capacities=a.snapshot.resource_capacities
 if ability.timing.kind!="instant":
  events.append({"type":"ability_deferred","ability_id":ability_id,"timing":ability.timing.duplicate(true)})
  # Only an intent descriptor. GAME-33 owns scheduling, targets and pending effects.
  return {"ok":true,"actor":new_actor,"target":new_target,"budget":new_budget,"rng":rng.duplicate(true),"events":events,"deferred":{"ability_id":ability_id,"timing":ability.timing.duplicate(true),"effects":ability.effects.duplicate(true)}}
 var state := {"actor":new_actor.runtime,"target":new_target.runtime,"rng":rng.duplicate(true),"events":events}
 for effect in ability.effects:
  var applied := _apply(effect,state,context)
  if not applied.ok: return applied
 for record in [new_actor,new_target]:
  var replay := characters._replay(record)
  if not replay.ok: return replay
  for id in replay.context.capacities:
   if not record.runtime.resources.has(id): record.runtime.resources[id]=0
  var valid := characters.validate_build(record)
  if not valid.ok: return valid
 return {"ok":true,"actor":new_actor,"target":new_target,"budget":new_budget,"rng":state.rng,"events":state.events}

func resolve_rules_effect(effect: Dictionary,actor_runtime: Dictionary,target_runtime: Dictionary,context: Dictionary,rng: Dictionary) -> Dictionary:
 if not RulesRng.valid_state(rng): return RulesJson.result([RulesJson.issue("rng.state","rng","Explicit validated RNG required")])
 var errors: Array=[]
 RulesRegistry.validate_effect(effect,registry._tables,"effect",errors)
 if not errors.is_empty(): return RulesJson.result(errors)
 if not _primitive_runtime(actor_runtime) or not _primitive_runtime(target_runtime): return RulesJson.result([RulesJson.issue("effect.runtime","runtime","Invalid current mechanical state")])
 var state := {"actor":actor_runtime.duplicate(true),"target":target_runtime.duplicate(true),"rng":rng.duplicate(true),"events":[]}
 var result := _apply(effect,state,context.duplicate(true))
 if not result.ok: return result
 state.ok=true
 return state

func _primitive_runtime(value: Dictionary) -> bool:
 for status in value.get("statuses",[]):
  if not status is Dictionary or not status.get("id") is String: return false
 return RulesJson.integer(value.get("hp"),0,100000) and RulesJson.integer(value.get("temporary_hp"),0,100000) and value.get("resources") is Dictionary and value.get("statuses") is Array and value.get("modifiers") is Array and value.get("granted_features") is Array and value.get("senses") is Array and value.get("apparent_effects") is Array

func _amount(expression: Dictionary,state: Dictionary,context: Dictionary) -> Dictionary:
 if expression.has("dice"):
  var roll := RulesRng.roll(expression.dice,state.rng)
  if not roll.ok: return roll
  var bonus := RulesExpressions.evaluate_formula(expression.bonus,context)
  if not bonus.ok: return bonus
  state.rng=roll.rng
  return {"ok":true,"value":roll.total+int(bonus.value)}
 return RulesExpressions.evaluate_formula(expression,context)

func _apply(effect: Dictionary,state: Dictionary,context: Dictionary) -> Dictionary:
 var op: String=effect.op
 var target: Dictionary=state.target
 if op in ["damage","heal","temporary_hp","spend_resource","restore_resource"]:
  var evaluated := _amount(effect.amount,state,context)
  if not evaluated.ok: return evaluated
  var amount: int=int(evaluated.value)
  if amount<0 or amount>100000: return RulesJson.result([RulesJson.issue("effect.amount",op,"Effect amount must be nonnegative and bounded")])
  if op=="damage":
   var absorbed := mini(amount,int(target.temporary_hp));target.temporary_hp-=absorbed
   var lost := mini(amount-absorbed,int(target.hp));target.hp-=lost
   state.events.append({"type":"damage_applied","target":context.get("target_id",""),"amount":lost,"temporary_absorbed":absorbed,"damage_type":effect.damage_type})
  elif op=="heal":
   var maximum: Variant=context.get("target_stats",{}).get("HP")
   if not RulesJson.integer(maximum,1,100000): return RulesJson.result([RulesJson.issue("effect.context","HP","Validated target capacity is required")])
   var healed := mini(amount,maxi(0,int(maximum)-int(target.hp)));target.hp+=healed
   state.events.append({"type":"healing_applied","target":context.get("target_id",""),"amount":healed})
  elif op=="temporary_hp":
   target.temporary_hp=maxi(int(target.temporary_hp),amount)
   state.events.append({"type":"temporary_hp_granted","amount":amount})
  else:
   var owner: Dictionary=state.actor
   var capacity: Variant=context.get("capacities",{}).get(effect.id)
   if not RulesJson.integer(capacity,0,100000) or not RulesJson.integer(owner.resources.get(effect.id),0,int(capacity)): return RulesJson.result([RulesJson.issue("effect.resource",effect.id,"Validated owned resource/current value required")])
   var before := int(owner.resources[effect.id])
   if op=="spend_resource":
    if int(owner.resources[effect.id])<amount: return RulesJson.result([RulesJson.issue("effect.resource",effect.id,"Resource cannot become negative")])
    owner.resources[effect.id]-=amount
   else: owner.resources[effect.id]=mini(int(capacity),int(owner.resources[effect.id])+amount)
   state.events.append({"type":"resource_spent" if op=="spend_resource" else "resource_restored","id":effect.id,"amount":absi(int(owner.resources[effect.id])-before)})
 elif op in ["modify_stat","modify_save"]:
  if effect.has("when") and not RulesExpressions.evaluate_requirements(effect.when,context).ok: return {"ok":true}
  var evaluated := RulesExpressions.evaluate_formula(effect.value,context)
  if not evaluated.ok: return evaluated
  target.modifiers.append({"stat":effect.stat,"type":effect.type,"value":int(evaluated.value),"source":str(context.get("source_character_id","effect"))+":"+str(context.get("event_id","primitive"))+":"+effect.stat})
  state.events.append({"type":"modifier_granted","stat":effect.stat,"amount":int(evaluated.value)})
 elif op=="grant_feature":
  if not target.granted_features.has(effect.id): target.granted_features.append(effect.id)
  state.events.append({"type":"feature_granted","id":effect.id})
 elif op=="grant_sense":
  if not target.senses.has(effect.id): target.senses.append(effect.id)
  state.events.append({"type":"sense_granted","id":effect.id})
 elif op=="apply_status":
  var definition := registry.definition("statuses",effect.id)
  var existing: Array=target.statuses.filter(func(s: Dictionary): return s.id==effect.id)
  if not existing.is_empty() and definition.stacking=="reject": return RulesJson.result([RulesJson.issue("effect.status_stack",effect.id,"Existing status rejects stacking")])
  if definition.stacking in ["refresh","replace"]: target.statuses=target.statuses.filter(func(s: Dictionary): return s.id!=effect.id)
  target.statuses.append({"id":effect.id,"source":str(context.get("source_character_id","effect")),"remaining":int(definition.duration.amount),"expiry":definition.duration.expiry})
  state.events.append({"type":"status_applied","id":effect.id})
 elif op=="remove_status":
  target.statuses=target.statuses.filter(func(s: Dictionary): return s.id!=effect.id)
  state.events.append({"type":"status_removed","id":effect.id})
 elif op=="save":
  var dc := RulesExpressions.evaluate_formula(effect.dc,context)
  if not dc.ok: return dc
  var bonus: Variant=context.get("target_stats",{}).get(effect.save)
  if not RulesJson.integer(bonus,-1000,1000): return RulesJson.result([RulesJson.issue("effect.context",effect.save,"Validated target save required")])
  var save := RulesRng.saving_throw(int(bonus),int(dc.value),state.rng)
  if not save.ok: return save
  state.rng=save.rng;state.events.append(save.event)
  if not save.success:
   for child in effect.on_failure:
    var result := _apply(child,state,context)
    if not result.ok: return result
 elif op in ["apparent_effect","defensive_duplicate"]:
  var descriptor: Dictionary=effect.descriptor.duplicate(true)
  var dc := RulesExpressions.evaluate_formula(descriptor.dc,context)
  if not dc.ok: return dc
  descriptor.dc=int(dc.value)
  descriptor.apparent_id="apparent:"+RulesJson.digest([context.get("source_character_id",""),context.get("event_id",""),descriptor.kind,state.actor.apparent_effects.size()])
  descriptor.source_character_id=context.get("source_character_id","")
  if state.actor.apparent_effects.size()>=int(descriptor.maximum_maintained):
   if descriptor.replacement=="reject": return RulesJson.result([RulesJson.issue("effect.maintenance",op,"Maintained effect limit reached")])
   state.actor.apparent_effects.clear();state.events.append({"type":"maintained_effect_replaced"})
  state.actor.apparent_effects.append(descriptor)
  state.events.append({"type":"apparent_effect_created","apparent_id":descriptor.apparent_id})
 elif op=="hook":
  var result := RulesHooks.invoke(effect.id,context)
  if not result.ok: return result
  # Trusted hook descriptors remain authority-only intentions for GAME-33.
  state.events.append_array(result.events)
  state.events.append({"type":"hook_intent","hook":effect.id,"effects":result.effects})
 return {"ok":true}

func refresh_resources(runtime: Dictionary,capacities: Dictionary,scope: String) -> Dictionary:
 if not scope in ["encounter","eligible_rest","short_rest","daily","explicit"]: return RulesJson.result([RulesJson.issue("resource.scope",scope,"Unknown refresh scope")])
 var candidate:=runtime.duplicate(true);var events: Array=[]
 for id in candidate.get("resources",{}):
  var definition := registry.definition("resources",str(id))
  if definition.is_empty() or not RulesJson.integer(capacities.get(id),0,100000) or not RulesJson.integer(candidate.resources[id],0,int(capacities.get(id,0))): return RulesJson.result([RulesJson.issue("resource.capacity",str(id),"Unknown or invalid resource capacity/current value")])
  if definition.refresh==scope:
   candidate.resources[id]=int(capacities[id]);events.append({"type":"resource_refreshed","id":id,"scope":scope})
 return {"ok":true,"runtime":candidate,"events":events}

func expire_statuses(runtime: Dictionary,trigger: String) -> Dictionary:
 if not trigger in RulesRegistry.EXPIRY: return RulesJson.result([RulesJson.issue("status.trigger",trigger,"Unknown expiry boundary")])
 var candidate:=runtime.duplicate(true);var retained: Array=[];var events: Array=[]
 for status in candidate.get("statuses",[]):
  if not status is Dictionary or registry.definition("statuses",str(status.get("id"))).is_empty() or not RulesJson.integer(status.get("remaining"),1,1000) or not status.get("expiry") in RulesRegistry.EXPIRY: return RulesJson.result([RulesJson.issue("status.instance","statuses","Invalid persisted status")])
  if status.expiry==trigger: status.remaining=int(status.remaining)-1
  if int(status.remaining)>0: retained.append(status)
  else: events.append({"type":"status_expired","id":status.id})
 candidate.statuses=retained
 return {"ok":true,"runtime":candidate,"events":events}

static func public_appearance(descriptor: Dictionary) -> Dictionary:
 # The battlefield authority chooses WHICH observer sees this projection.
 # No hidden kind, origin, disbelief status or physical identity is exposed.
 return {"apparent_id":descriptor.get("apparent_id",""),"presentation":descriptor.get("presentation",{}).duplicate(true),"senses":descriptor.get("senses",[]).duplicate()}
