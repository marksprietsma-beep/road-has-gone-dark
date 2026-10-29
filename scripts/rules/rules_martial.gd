class_name RulesMartial
extends RefCounted
## v19 descriptors consumed at authoritative combat events, never a second resolver.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id")in ["trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29","trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33","trhgd-character-v34"]

static func validate_definition(category: String,row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if category=="abilities":
  if row.has("requires_status"):RulesRegistry._reference(tables,"statuses",row.requires_status,row.id,errors)
  if row.has("requires_weapon"):RulesRegistry._reference(tables,"equipment",row.requires_weapon,row.id,errors)
  for field in ["requires_melee","requires_adjacent","counterattack","requires_fencing"]:
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
  if row.has("activation_effects"):
   var periodic: Variant=row.activation_effects
   if not periodic is Array or periodic.size()!=1:
    errors.append(RulesJson.issue("activation.schema",row.id,"One bounded activation healing effect required"))
   else:
    var effect: Variant=periodic[0]
    if not effect is Dictionary or effect.size()!=2 or effect.get("op")!="heal" or not effect.get("amount") is Dictionary or effect.amount.size()!=2 or effect.amount.get("op")!="const" or not RulesJson.integer(effect.amount.get("value"),1,50):
     errors.append(RulesJson.issue("activation.effect",row.id,"Activation healing must be constant1–50; no actions, resources or arbitrary scripts"))
    else:RulesRegistry.validate_effect(effect,tables,row.id,errors,0,3)
  if row.has("weapon_override"):
   RulesRegistry._reference(tables,"equipment",row.weapon_override,row.id,errors)
   if tables.equipment.get(row.weapon_override,{}).get("kind")!="weapon":errors.append(RulesJson.issue("martial.weapon",row.id,"Actual weapon required"))
  if row.has("stance_group") and (row.stance_group not in ["martial-stance","maintained-performance"] or row.stance_group=="maintained-performance" and not row.has("upkeep")):errors.append(RulesJson.issue("martial.stance",row.id,"Registered exclusive stance group required"))

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

static func mobile_enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id") in ["trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29","trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33","trhgd-character-v34"]

static func fencing_equipment(record: Dictionary,source: RulesRegistry,include_runtime := true) -> bool:
 if include_runtime and not RulesEntities.form(record,source).is_empty():return false
 var weapon := false
 for id in record.equipment:
  var item := source.definition("equipment",str(id))
  if item.is_empty():return false
  if item.kind=="shield" or (item.kind=="armor" and item.get("proficiency")!="light"):return false
  if item.kind=="weapon":weapon=item.tags.has("fencing_weapon")
 if include_runtime:
  for status in record.runtime.statuses:
   var row := source.definition("statuses",str(status.get("id","")))
   if row.has("weapon_override"):return source.definition("equipment",row.weapon_override).tags.has("fencing_weapon")
 return weapon

static func precision_damage(record: Dictionary,source: RulesRegistry) -> int:
 var levels: Dictionary=RulesCharacter.new(source).derive_character(record).snapshot.class_levels
 return 2*int(ceil(float(int(levels.get("rogue",0))+int(levels.get("arcane-trickster",0)))/2.0))

static func effective_weapon(record: Dictionary,held: String,source: RulesRegistry,include_runtime := true) -> String:
 # Same form/manifestation/held precedence as the original tactical adapter.
 if include_runtime:
  var body := RulesEntities.form(record,source)
  if not body.is_empty():return str(body.weapon_id)
  for status in record.runtime.statuses:
   var row := source.definition("statuses",str(status.id))
   if row.has("weapon_override"):return str(row.weapon_override)
 return held

static func weapon_context_tags(record: Dictionary,source: RulesRegistry,include_runtime: bool,attack_weapon: String="") -> Array:
 var held := "unarmed"
 for id in record.equipment:
  if source.definition("equipment",str(id)).get("kind")=="weapon":held=str(id);break
 var active := effective_weapon(record,held,source,include_runtime)
 var result := []
 for pair in [["active",active],["attack",attack_weapon if not attack_weapon.is_empty() else active]]:
  var row := source.definition("equipment",str(pair[1]))
  var kind := "natural" if row.get("tags",[]).has("natural") else "unarmed" if row.get("tags",[]).has("unarmed") else "ranged" if row.get("tags",[]).has("ranged") else "melee"
  result.append(str(pair[0])+"_"+kind+"_weapon")
 return result

static func start_activation(combat: TacticalCombat,battle: Dictionary) -> void:
 # v23 descriptors execute at the existing turn boundary. Cold loading never ticks.
 if combat.registry.rules_ref().pack_id not in ["trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29","trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33","trhgd-character-v34"] or battle.status!="active":return
 var unit: Dictionary=combat.current(battle)
 if not combat.alive(unit):return
 var derived := combat.characters.derive_character(unit.record)
 if derived.snapshot.tags.has("main_action_suppressed"):
  battle.budget.main=0
  battle.log.append(unit.name+" loses this main action to Stillness; movement and the shared reaction remain available.")
 for instance in unit.record.runtime.statuses.duplicate(true):
  for effect in combat.registry.definition("statuses",instance.id).get("activation_effects",[]):
   var context: Dictionary=derived.context.duplicate(true)
   context.character_id=unit.id;context.source_character_id=instance.source
   context.target_id=unit.id;context.target_stats=derived.snapshot.stats
   var result := combat.effects.resolve_rules_effect(effect,unit.record.runtime,unit.record.runtime,context,battle.rng)
   if not result.ok:push_error("Validated activation effect failed: "+JSON.stringify(result.errors));return
   unit.record.runtime=result.target;battle.rng=result.rng
   for event in result.events:
    if event.type=="healing_applied":battle.log.append(unit.name+" receives "+str(event.amount)+" HP from Renewing benediction.")
