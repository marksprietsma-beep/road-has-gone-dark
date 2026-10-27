class_name RulesWaveFive
extends RefCounted
## v15 selected repertoire/channel adapters. Existing history, costs, effects and save owner remain authority.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id")in ["trhgd-character-v15","trhgd-character-v16","trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29","trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33"]

static func spell_selected(record: Dictionary,ability: Dictionary,source: RulesRegistry) -> bool:
 var id: String=str(ability.get("channel_spell",ability.get("id",""))) if enabled(source) else str(ability.get("id",""))
 return record.choices.prepared_abilities.has(id)

static func channel_access(record: Dictionary,ability: Dictionary,context: Dictionary,source: RulesRegistry) -> Dictionary:
 if not enabled(source) or not ability.has("channel_spell"):return {"ok":true}
 var spell_id: String=ability.channel_spell
 var spell := source.definition("abilities",spell_id)
 if not context.abilities.has(spell_id) or not spell_selected(record,ability,source):return RulesJson.result([RulesJson.issue("channel.selection",spell_id,"Channeling requires the actual owned, selected original spell")])
 var valid := RulesExpressions.evaluate_requirements(spell.requirements,context)
 if not valid.ok:return valid
 var weapons: Array=record.equipment.filter(func(id: String):return source.definition("equipment",id).kind=="weapon")
 if weapons.size()!=1 or not melee_weapon(record,str(weapons[0]),source):return RulesJson.result([RulesJson.issue("channel.weapon",spell_id,"Select one proficient equipped melee weapon; ranged, natural and suppressed weapons cannot channel")])
 return {"ok":true}

static func melee_weapon(record: Dictionary,id: String,source: RulesRegistry) -> bool:
 var weapon := source.definition("equipment",id)
 var replay := RulesCharacter.new(source)._replay(record)
 var manifested: bool= RulesMartial.enabled(source) and record.runtime.statuses.any(func(s: Dictionary):return source.definition("statuses",s.id).get("weapon_override")==id)
 return replay.ok and (record.equipment.has(id) or manifested) and weapon.get("kind")=="weapon" and not weapon.get("tags",[]).has("ranged") and not weapon.get("tags",[]).has("natural") and RulesEntities.form(record,source).is_empty() and RulesCoreContent.equipment_legal(weapon,replay.context.classes,source)

static func channel_effects(actor: Dictionary,target: Dictionary,id: String,rng: Dictionary,source: RulesRegistry) -> Dictionary:
 var kernel := RulesCharacter.new(source)
 var a := kernel.derive_character(actor);var t := kernel.derive_character(target)
 if not a.ok:return a
 if not t.ok:return t
 var context: Dictionary=a.context.duplicate(true)
 context.character_id=actor.character_id;context.source_character_id=actor.character_id
 context.target_id=target.character_id;context.stats=a.snapshot.stats;context.target_stats=t.snapshot.stats
 context.capacities=a.snapshot.resource_capacities;context.target_capacities=t.snapshot.resource_capacities
 context.capabilities=a.snapshot.capabilities;context.target_capabilities=t.snapshot.capabilities;context.target_tags=t.snapshot.tags
 var result := {"ok":true,"actor":actor.duplicate(true),"target":target.duplicate(true),"rng":rng.duplicate(true),"events":[]}
 var effects := RulesEffects.new(source)
 for effect in source.definition("abilities",id).effects:
  var applied := effects.resolve_rules_effect(effect,result.actor.runtime,result.target.runtime,context,result.rng)
  if not applied.ok:return applied
  result.actor.runtime=applied.actor;result.target.runtime=applied.target;result.rng=applied.rng;result.events.append_array(applied.events)
 for value in [result.actor,result.target]:
  var valid := kernel.validate_build(value)
  if not valid.ok:return valid
 return RulesJson.string_keys(result)

static func retrieval_class(cls: String,source: RulesRegistry) -> bool:
 return enabled(source) and source.definition("classes",cls).get("rest_retrieval",false)

static func retrieval_changes(before: Dictionary,after: Dictionary,source: RulesRegistry) -> Array:
 var changed: Array=[]
 for cls in source.ids("classes"):
  if not retrieval_class(cls,source):continue
  var old: Array=before.choices.prepared_abilities.filter(func(id: String):return source.definition("abilities",id).get("casting_class")==cls)
  var fresh: Array=after.choices.prepared_abilities.filter(func(id: String):return source.definition("abilities",id).get("casting_class")==cls)
  old.sort();fresh.sort()
  if old!=fresh:changed.append(cls)
 return changed

static func commit_retrieval(before: Dictionary,after: Dictionary,source: RulesRegistry) -> Dictionary:
 for cls in retrieval_changes(before,after,source):
  var pool: String=source.definition("classes",cls).retrieval_resource
  if int(before.runtime.resources.get(pool,0))<1:return RulesJson.result([RulesJson.issue("spell.retrieval_rest",cls,"Return from an expedition and rest before changing retrieved spells again. Restarting or opening this screen grants no rest.")])
  after.runtime.resources[pool]=int(before.runtime.resources[pool])-1
 return {"ok":true}

static func validate_definition(category: String,row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if row.has("rest_retrieval") or row.has("retrieval_resource"):
  if category!="classes" or row.get("rest_retrieval")!=true or row.get("spell_mode")!="spontaneous" or not row.has("known_spell_limits"):errors.append(RulesJson.issue("retrieval.schema",row.id,"Bounded spontaneous rest-retrieval class required"))
  RulesRegistry._reference(tables,"resources",row.get("retrieval_resource"),row.id,errors)
  var pool: Dictionary=tables.resources.get(row.get("retrieval_resource"),{})
  if pool.get("refresh")!="eligible_rest" or pool.get("capacity")!={"op":"const","value":1}:errors.append(RulesJson.issue("retrieval.resource",row.id,"One permit refreshed only by eligible rest required"))
 if not row.has("channel_spell"):return
 if category!="abilities":errors.append(RulesJson.issue("channel.schema",row.id,"Channel wrapper must be an ability"));return
 RulesRegistry._reference(tables,"abilities",row.channel_spell,row.id,errors)
 var spell: Dictionary=tables.abilities.get(row.channel_spell,{})
 if spell.is_empty():return
 if spell.has("channel_spell") or not spell.tags.has("spell") or spell.targeting.kind!="creature" or int(spell.targeting.get("radius",0))!=0 or not _channel_effects_valid(spell.effects):errors.append(RulesJson.issue("channel.spell",row.id,"An original single-enemy spell with supported hit effects is required"))
 if not row.tags.has("spell") or not row.tags.has("weapon_strike") or row.get("attack_weapon")!=null or row.cost!=spell.cost or row.effects!=[] or row.targeting.kind!="creature" or int(row.targeting.get("radius",0))!=0:errors.append(RulesJson.issue("channel.cost",row.id,"One ordinary melee strike plus the original spell cost, without duplicate effects, required"))
 if row.get("casting_class")!=spell.get("casting_class") or row.get("spell_tier")!=spell.get("spell_tier"):errors.append(RulesJson.issue("channel.identity",row.id,"Wrapper must retain its original spell's class/tier"))

static func _channel_effects_valid(effects: Array) -> bool:
 for effect in effects:
  if effect.op not in ["damage","apply_status","remove_status","save"]:return false
  if effect.get("recipient","")!="":return false
  if effect.op=="save" and (not _channel_effects_valid(effect.on_failure) or not _channel_effects_valid(effect.get("on_success",[]))):return false
 return true
