class_name RulesEntities
extends RefCounted
## v12+ body/owned-creature records. GAME-32 still derives every actor and action.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id")in ["trhgd-character-v12","trhgd-character-v13","trhgd-character-v14","trhgd-character-v15","trhgd-character-v16","trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25"]
static func form(record: Dictionary,source: RulesRegistry) -> Dictionary:
 if not enabled(source):return {}
 for status in record.runtime.statuses:
  if not status is Dictionary:continue
  var definition := source.definition("statuses",str(status.get("id","")))
  if definition.has("body_form"):return definition.body_form
 return {}
static func validate_form(value: Variant,tables: Dictionary,errors: Array) -> void:
 if not value is Dictionary or value.size()!=8 or not value.has_all(["id","body_plan","size","attributes","feature_id","weapon_id","suppressed_equipment","art_status"]):
  errors.append(RulesJson.issue("form.schema","body_form","Typed anatomy, equipment and mechanics required"));return
 if not value.id is String or not value.body_plan is String or value.size not in ["small","medium","large"] or value.art_status!="neutral_humanoid_fallback" or not value.attributes is Dictionary or not value.suppressed_equipment is Array:
  errors.append(RulesJson.issue("form.schema",str(value.id),"Bounded physical form and honest art fallback required"));return
 for id in value.attributes:
  if id not in ["STR","DEX"] or not RulesJson.integer(value.attributes[id],-6,8):errors.append(RulesJson.issue("form.attributes",str(value.id),"Only physical attack/defence attributes change; health belongs to original character"))
 for id in value.suppressed_equipment:
  if id not in ["weapon","armor","shield"]:errors.append(RulesJson.issue("form.equipment",str(value.id),"Known equipment slots required"))
 RulesRegistry._reference(tables,"features",value.feature_id,"body_form",errors)
 RulesRegistry._reference(tables,"equipment",value.weapon_id,"body_form",errors)
 if tables.equipment.get(value.weapon_id,{}).get("kind")!="weapon":errors.append(RulesJson.issue("form.weapon",str(value.id),"Natural weapon definition required"))
static func validate_bond(value: Variant,tables: Dictionary,errors: Array) -> void:
 if not value is Dictionary or value.size()!=4 or not value.has_all(["creature_id","level_class","offset","divisor"]):errors.append(RulesJson.issue("bond.schema","companion","Typed ownership/scaling required"));return
 RulesRegistry._reference(tables,"creatures",value.creature_id,"companion",errors)
 RulesRegistry._reference(tables,"classes",value.level_class,"companion",errors)
 if not RulesJson.integer(value.offset,-10,0) or not RulesJson.integer(value.divisor,1,4):errors.append(RulesJson.issue("bond.scaling","companion","Bounded class-relative progression required"))
static func validate_creature(row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if row.size()!=8 or not row.has_all(["id","name","attributes","feature_id","weapon_id","body_plan","size","provenance"]):errors.append(RulesJson.issue("creature.schema",row.id,"Typed creature definition required"));return
 if not row.name is String or not row.body_plan is String or row.size not in ["small","medium","large"] or not row.provenance is Dictionary or not row.provenance.get("license") is String or not row.attributes is Dictionary or row.attributes.size()!=6:errors.append(RulesJson.issue("creature.schema",row.id,"Valid identity/anatomy/attributes/provenance required"));return
 var scores: Array=row.attributes.values();scores.sort();var standard: Array=[8,10,12,13,14,15]
 if scores!=standard:errors.append(RulesJson.issue("creature.attributes",row.id,"Reviewed standard array required"))
 for id in row.attributes:
  if id not in RulesExpressions.ATTRIBUTES:errors.append(RulesJson.issue("creature.attributes",row.id,"Known attributes required"))
 RulesRegistry._reference(tables,"features",row.feature_id,row.id,errors)
 RulesRegistry._reference(tables,"equipment",row.weapon_id,row.id,errors)
 if tables.equipment.get(row.weapon_id,{}).get("kind")!="weapon":errors.append(RulesJson.issue("creature.weapon",row.id,"Actual weapon required"))
static func bonds(record: Dictionary,source: RulesRegistry) -> Array:
 var replay := RulesCharacter.new(source)._replay(record)
 if not replay.ok:return []
 var result: Array=[]
 var durable_features: Array=replay.context.features
 if RulesPsychic.enabled(source):
  durable_features=durable_features.filter(func(id: String):return replay.context.feature_sources.any(func(entry: Dictionary):return entry.id==id and not str(entry.source).begins_with("granted:")))
 for id in durable_features:
  var feature := source.definition("features",id)
  if not feature.has("companion"):continue
  var bond: Dictionary=feature.companion
  var level: int=maxi(1,(int(replay.context.classes.get(bond.level_class,0))+int(bond.offset))/int(bond.divisor))
  var row := {"creature_id":bond.creature_id,"level":mini(20,level)}
  if result.is_empty():result.append(row)
  elif row.level>result[0].level:result[0]=row
 if RulesPsychic.enabled(source) and not result.is_empty():
  var growth := 0
  for id in durable_features:
   var feature := source.definition("features",id)
   if feature.has("companion_growth"):growth+=int(RulesExpressions.evaluate_formula(feature.companion_growth,replay.context).get("value",0))
  result[0].level=clampi(int(result[0].level)+growth,1,20)
 return result # One durable nature bond per owner, including multiclassing.
static func identity(owner: String) -> String:return owner+":companion"
static func creature_record(id: String,definition_id: String,level: int,source: RulesRegistry) -> Dictionary:
 var definition := source.definition("creatures",definition_id)
 if definition.is_empty():return {}
 var kernel := RulesCharacter.new(source)
 var record := kernel.create(id,definition.attributes,"heritage-human")
 record.runtime.granted_features=[definition.feature_id]
 if RulesPsychic.enabled(source):record.runtime.resources=kernel._replay(record).context.capacities.duplicate()
 for n in level:
  var choice := kernel.suggested_choice(record,"bond-creature")
  if not choice.ok:return {}
  var step := kernel.preview_advancement(record,choice.choice)
  if not step.ok:return {}
  record=step.candidate
 record.runtime.hp=int(kernel.derive_character(record).snapshot.stats.HP)
 return record
static func synchronize(record: Dictionary,source: RulesRegistry) -> Dictionary:
 var desired := bonds(record,source)
 if desired.is_empty():return {"ok":true}
 var bond: Dictionary=desired[0];var id := identity(record.character_id)
 var previous: Dictionary=record.runtime.companions.get(id,{})
 if previous.get("definition_id")==bond.creature_id and previous.get("record",{}).get("advancement_history",[]).size()==bond.level:return {"ok":true}
 var pet := creature_record(id,bond.creature_id,bond.level,source)
 if pet.is_empty():return RulesJson.result([RulesJson.issue("companion.progression",id,"Could not build scaled companion")])
 if not previous.is_empty():
  var old := RulesCharacter.new(source).derive_character(previous.record)
  if not old.ok:return old
  var deficit: int=int(old.snapshot.stats.HP)-int(previous.record.runtime.hp)
  pet.runtime.hp=maxi(0,int(pet.runtime.hp)-deficit)
  pet.runtime.statuses=previous.record.runtime.statuses.duplicate(true)
  if RulesPsychic.enabled(source):
   for resource in pet.runtime.resources:
    if previous.record.runtime.resources.has(resource):pet.runtime.resources[resource]=mini(int(pet.runtime.resources[resource]),int(previous.record.runtime.resources[resource]))
 record.runtime.companions={id:{"definition_id":bond.creature_id,"record":pet}}
 return {"ok":true}
static func runtime_errors(record: Dictionary,source: RulesRegistry) -> Array:
 var errors: Array=[]
 if not record.runtime.get("companions") is Dictionary or record.runtime.companions.size()>1:return [RulesJson.issue("companion.runtime","companions","At most one typed permanent companion per owner")]
 var expected := bonds(record,source)
 if expected.size()!=record.runtime.companions.size():errors.append(RulesJson.issue("companion.missing","companions","Permanent bond must retain its companion record"))
 var forms: Array=record.runtime.statuses.filter(func(s: Variant):return s is Dictionary and source.definition("statuses",str(s.get("id",""))).has("body_form"))
 if forms.size()>1:errors.append(RulesJson.issue("form.overlap","statuses","Only one active body form"))
 for id in record.runtime.companions:
  var value: Variant=record.runtime.companions[id]
  if id!=identity(record.character_id) or not value is Dictionary or value.size()!=2 or not value.get("record") is Dictionary or value.record.get("character_id")!=id or source.definition("creatures",str(value.get("definition_id",""))).is_empty():errors.append(RulesJson.issue("companion.identity",str(id),"Owned stable creature identity required"));continue
  var pet: Dictionary=value.record
  if not pet.get("runtime",{}).get("companions",{}).is_empty():errors.append(RulesJson.issue("companion.recursion",str(id),"Companions cannot own companions"));continue
  var kernel := RulesCharacter.new(source)
  if not kernel.validate_build(pet).ok:errors.append(RulesJson.issue("companion.build",str(id),"Invalid pinned creature build"));continue
  var desired := bonds(record,source)
  if desired.size()!=1 or desired[0].creature_id!=value.definition_id or desired[0].level!=pet.advancement_history.size():errors.append(RulesJson.issue("companion.entitlement",str(id),"Companion must match permanent bond and owner progression"))
  var definition := source.definition("creatures",value.definition_id)
  if pet.base_attributes!=definition.attributes or pet.equipment!=[] or pet.runtime.granted_features!=[definition.feature_id] or pet.advancement_history.any(func(s: Dictionary):return s.class_id!="bond-creature"):errors.append(RulesJson.issue("companion.definition",str(id),"Creature mechanics must match its pinned definition"))
 return errors
static func recover_companions(record: Dictionary,source: RulesRegistry) -> void:
 if not enabled(source):return
 for value in record.runtime.companions.values():
  var pet: Dictionary=value.record
  var snap := RulesCharacter.new(source).derive_character(pet)
  if snap.ok:
   pet.runtime.hp=int(snap.snapshot.stats.HP);pet.runtime.statuses=[]
   pet.runtime.resources=snap.snapshot.resource_capacities.duplicate()
