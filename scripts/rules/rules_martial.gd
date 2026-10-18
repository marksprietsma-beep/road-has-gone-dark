class_name RulesMartial
extends RefCounted
## v19 descriptors consumed at authoritative combat events, never a second resolver.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id")=="trhgd-character-v19"

static func validate_definition(category: String,row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if category=="abilities":
  if row.has("requires_status"):RulesRegistry._reference(tables,"statuses",row.requires_status,row.id,errors)
  if row.has("requires_weapon"):RulesRegistry._reference(tables,"equipment",row.requires_weapon,row.id,errors)
  for field in ["requires_melee","counterattack"]:
   if row.has(field) and not row[field] is bool:errors.append(RulesJson.issue("martial.boolean",row.id,"Boolean tactical descriptor required"))
  if row.has("strike_effects"):
   if not row.strike_effects is Array or not row.get("tags",[]).has("weapon_strike"):errors.append(RulesJson.issue("martial.strike",row.id,"Only actual weapon strikes can declare hit riders"))
   else:
    for effect in row.strike_effects:RulesRegistry.validate_effect(effect,tables,row.id,errors,0,3)
  if row.get("counterattack",false) and (row.get("trigger")!="melee_miss" or row.get("cost",{}).get("reaction")!=1):errors.append(RulesJson.issue("martial.counter",row.id,"Counters require an actual melee miss and the shared reaction"))
  if row.get("trigger") in ["weapon_hit","melee_hit","melee_miss","activation_start"]:
   if row.cost.main!=0 or row.cost.move!=0 or row.timing.kind!="instant":errors.append(RulesJson.issue("martial.trigger",row.id,"Triggered effects cannot consume another actor's main or movement"))
   if row.trigger=="activation_start" and (row.targeting.kind!="self" or row.cost.reaction!=0):errors.append(RulesJson.issue("martial.activation",row.id,"Activation recovery is self-only and cannot borrow a reaction"))
   if row.trigger!="activation_start" and row.cost.reaction!=1:errors.append(RulesJson.issue("martial.trigger",row.id,"Combat triggers must spend the shared reaction"))
 elif category=="statuses":
  if row.has("weapon_override"):
   RulesRegistry._reference(tables,"equipment",row.weapon_override,row.id,errors)
   if tables.equipment.get(row.weapon_override,{}).get("kind")!="weapon":errors.append(RulesJson.issue("martial.weapon",row.id,"Actual weapon required"))
  if row.has("stance_group") and row.stance_group!="martial-stance":errors.append(RulesJson.issue("martial.stance",row.id,"Registered exclusive stance group required"))

static func apply_hit(actor: Dictionary,target: Dictionary,ability: Dictionary,rng: Dictionary,source: RulesRegistry) -> Dictionary:
 var a := RulesCharacter.new(source).derive_character(actor)
 var t := RulesCharacter.new(source).derive_character(target)
 if not a.ok:return a
 if not t.ok:return t
 var context: Dictionary=a.context.duplicate(true)
 context.character_id=actor.character_id;context.source_character_id=actor.character_id
 context.target_id=target.character_id;context.target_stats=t.snapshot.stats
 context.target_tags=t.snapshot.tags;context.target_capacities=t.snapshot.resource_capacities
 context.target_capabilities=t.snapshot.capabilities;context.capabilities=a.snapshot.capabilities
 var state := {"ok":true,"actor":actor.duplicate(true),"target":target.duplicate(true),"rng":rng.duplicate(true),"events":[]}
 for effect in ability.get("strike_effects",[]):
  var result := RulesEffects.new(source).resolve_rules_effect(effect,state.actor.runtime,state.target.runtime,context,state.rng)
  if not result.ok:return result
  state.actor.runtime=result.actor;state.target.runtime=result.target;state.rng=result.rng;state.events.append_array(result.events)
 return state

static func moved_this_activation(battle: Dictionary,id: String) -> bool:
 # Successful movement is already sealed into the command history. Spending a
 # movement token on a stance, arm action or meditation is not displacement.
 for index in range(battle.commands.size()-1,-1,-1):
  var command: Dictionary=battle.commands[index]
  if command.kind=="end":break
  if command.get("actor_id")==id and command.kind=="move":return true
 return false
