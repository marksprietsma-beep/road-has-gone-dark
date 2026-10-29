class_name RulesCharacter
extends RefCounted
## Replay choices; final totals are never a second persisted authority.
var registry: RulesRegistry

func _init(source: RulesRegistry) -> void: registry=source

func create(identity: String, attributes: Dictionary, ancestry: String, background: String = "hometown-background") -> Dictionary:
 var record := {"schema_version":1,"character_id":identity,"rules_ref":registry.rules_ref(),"base_attributes":attributes.duplicate(true),"ancestry_ref":ancestry,"background_ref":background,"advancement_history":[],"equipment":[],"choices":{"prepared_abilities":[]},"runtime":{"hp":0,"temporary_hp":0,"resources":{},"statuses":[],"modifiers":[],"granted_features":[],"senses":[],"apparent_effects":[]},"revision":0}

 if registry.rules_ref().get("engine_schema")==3:record.choices.spell_preparations={}
 if RulesWaveFour.enabled(registry):record.runtime.manifested_powers=[]
 if RulesEntities.enabled(registry):
  record.runtime.companions={}
  record.runtime.resources=_context(attributes,{}, {},[],record,false).capacities.duplicate()
 return record

func feat_at(level: int,class_id: String,class_level: int) -> bool:
 return registry.rule("feat_levels").has(level) or registry.rules_ref().engine_schema==3 and registry.definition("classes",class_id).bonus_feat_levels.has(class_level)

func _shape(record: Dictionary) -> Array:
 var errors: Array = []
 var fields := ["schema_version","character_id","rules_ref","base_attributes","ancestry_ref","background_ref","advancement_history","equipment","choices","runtime","revision"]
 if record.size()!=fields.size() or record.get("schema_version")!=1: errors.append(RulesJson.issue("build.schema","build","Unsupported mechanical record"))
 for key in fields:
  if not record.has(key): errors.append(RulesJson.issue("build.field",key,"Required field is absent"))
 if not registry.ready() or RulesJson.normalize(record.get("rules_ref"))!=registry.rules_ref(): errors.append(RulesJson.issue("build.rules_pin","rules_ref","Exact rules pack/version/content is required"))
 if not record.get("character_id") is String or record.character_id.is_empty() or record.character_id.length()>160: errors.append(RulesJson.issue("build.identity","character_id","Stable character identity required"))
 if not record.get("base_attributes") is Dictionary or record.base_attributes.size()!=6: errors.append(RulesJson.issue("build.attributes","attributes","Exactly six base attributes required"))
 else:
  for id in RulesExpressions.ATTRIBUTES:
   if not RulesJson.integer(record.base_attributes.get(id),3,18): errors.append(RulesJson.issue("build.attribute",id,"Base attribute outside legal range"))
  var scores: Array=[]
  if RulesExpressions.ATTRIBUTES.all(func(id: String): return RulesJson.integer(record.base_attributes.get(id),3,18)): scores=RulesJson.normalize(record.base_attributes).values();scores.sort()
  var expected: Array=registry.rule("standard_array").duplicate();expected.sort()
  if scores!=expected: errors.append(RulesJson.issue("build.array","attributes","Use the reviewed standard array"))
 for pair in [["ancestry_ref","ancestries"],["background_ref","backgrounds"]]:
  if not record.get(pair[0]) is String or registry.definition(pair[1],str(record.get(pair[0]))).is_empty(): errors.append(RulesJson.issue("build.reference",pair[0],"Unknown mechanical heritage/background"))
 for key in ["advancement_history","equipment"]:
  if not record.get(key) is Array: errors.append(RulesJson.issue("build.array",key,"Expected array"))
 if not RulesJson.integer(record.get("revision"),0,RulesJson.LIMIT): errors.append(RulesJson.issue("build.revision","revision","Integer revision required"))
 if not record.get("choices") is Dictionary or record.choices.size()!=(2 if registry.rules_ref().get("engine_schema")==3 else 1) or not record.choices.get("prepared_abilities") is Array: errors.append(RulesJson.issue("build.choices","choices","Explicit prepared-ability choices required"))
 if registry.rules_ref().get("engine_schema")==3 and not record.get("choices",{}).get("spell_preparations") is Dictionary:errors.append(RulesJson.issue("build.preparations","choices","Typed prepared copy counts required"))
 if not record.get("runtime") is Dictionary: errors.append(RulesJson.issue("build.runtime","runtime","Mutable mechanical record required"))
 else:
  var runtime: Dictionary=record.runtime
  if runtime.size()!=(10 if RulesWaveFour.enabled(registry) else 9 if RulesEntities.enabled(registry) else 8): errors.append(RulesJson.issue("build.runtime","runtime","Unexpected runtime fields"))
  for key in ["hp","temporary_hp"]:
   if not RulesJson.integer(runtime.get(key),0,100000): errors.append(RulesJson.issue("build.runtime",key,"Bounded nonnegative current HP required"))
  if not runtime.get("resources") is Dictionary: errors.append(RulesJson.issue("build.runtime","resources","Resource values required"))
  for key in ["statuses","modifiers","granted_features","senses","apparent_effects"]:
   if not runtime.get(key) is Array: errors.append(RulesJson.issue("build.runtime",key,"Runtime array required"))
  for key in ["senses","granted_features"]:
   if runtime.get(key) is Array and not runtime[key].all(func(v: Variant): return v is String): errors.append(RulesJson.issue("build.runtime_list",key,"Runtime identifiers must be strings"))
 return errors

func validate_build(record: Dictionary) -> Dictionary:
 if RulesEntities.enabled(registry):record=RulesJson.string_keys(record)
 var replay := _replay(record)
 if not replay.ok: return replay
 var errors := _runtime_errors(record,replay.context)
 return RulesJson.result(errors)

func _replay(record: Dictionary,attack_weapon: String="") -> Dictionary:
 var errors := _shape(record)
 if not errors.is_empty(): return RulesJson.result(errors)
 if record.advancement_history.size()>int(registry.rule("max_level")): return RulesJson.result([RulesJson.issue("build.level_cap","history","Total level limit exceeded")])
 var attributes: Dictionary=RulesJson.normalize(record.base_attributes)
 if registry.rules_ref().engine_schema==3:
  for id in registry.definition("ancestries",record.ancestry_ref).attribute_adjustments:attributes[id]+=int(registry.definition("ancestries",record.ancestry_ref).attribute_adjustments[id])
 var classes := {};var ranks := {};var feats: Array=[]
 for skill in registry.ids("skills"): ranks[skill]=0
 var context := _context(attributes,classes,ranks,feats,record,false)
 if not context.errors.is_empty(): return RulesJson.result(context.errors)
 for i in record.advancement_history.size():
  var step: Variant=record.advancement_history[i]
  var path := "advancement_history."+str(i)
  if not step is Dictionary or step.size()!=(7 if RulesCareer.enabled(registry) else 5) or step.get("level")!=i+1 or not step.get("class_id") is String or not step.get("skill_allocations") is Dictionary or not step.get("feat_id") is String or not step.get("attribute_increase") is String:
   return RulesJson.result([RulesJson.issue("advancement.schema",path,"Invalid ordered advancement step")])
  var cls := registry.definition("classes",step.class_id)
  if cls.get("class_kind")=="companion" and not (record.character_id.ends_with(":companion") or record.character_id.contains(":summon:")):return RulesJson.result([RulesJson.issue("companion.class",path,"Creature advancement is internal to owned actors")])
  if cls.is_empty(): return RulesJson.result([RulesJson.issue("advancement.class",path,"Unknown class")])
  if i==0 and cls.get("class_kind")=="prestige":return RulesJson.result([RulesJson.issue("advancement.prestige_start",path,"Prestige paths require prior permanent class progression and an explicit advancement choice")])
  if int(classes.get(step.class_id,0))>=int(cls.max_level): return RulesJson.result([RulesJson.issue("advancement.class_cap",path,"Class level cap exceeded")])
  var requirement := RulesCompleteness.entry_requirements(cls.requirements,context,record,registry)
  if not requirement.ok:
   for reason in requirement.errors: reason.path=path+"."+str(reason.path)
   return requirement
  if registry.rule("attribute_increase_levels").has(i+1):
   if not step.attribute_increase in RulesExpressions.ATTRIBUTES or int(attributes[step.attribute_increase])>=22: return RulesJson.result([RulesJson.issue("advancement.attribute",path,"A legal scheduled attribute increase is required")])
   attributes[step.attribute_increase]+=1
  elif not step.attribute_increase.is_empty(): return RulesJson.result([RulesJson.issue("advancement.attribute_schedule",path,"No attribute increase at this level")])
  if RulesCareer.enabled(registry):
   var options_errors := RulesCareer.validate_choices(registry,step.class_id,int(classes.get(step.class_id,0))+1,step.get("specialisations"),context)
   if not options_errors.is_empty():return RulesJson.result(options_errors)
   if not step.get("bonus_feats") is Array:return RulesJson.result([RulesJson.issue("career.feats",path,"Explicit additional feat selections required")])
  classes[step.class_id]=int(classes.get(step.class_id,0))+1
  var points := maxi(1,int(cls.skill_points)+int(floor(float(int(attributes.INT)-10)/2.0)))
  var allocated := 0
  for skill in step.skill_allocations:
   if not ranks.has(skill) or not RulesJson.integer(step.skill_allocations[skill],0,points): return RulesJson.result([RulesJson.issue("advancement.skill",path,"Invalid skill allocation")])
   allocated+=int(step.skill_allocations[skill]);ranks[skill]+=int(step.skill_allocations[skill])
   if int(ranks[skill])>i+1: return RulesJson.result([RulesJson.issue("advancement.rank_cap",path,"Skill rank exceeds total level")])
  if allocated!=points: return RulesJson.result([RulesJson.issue("advancement.skill_budget",path,"Exact skill-point allocation required",{"expected":points,"current":allocated})])
  context=_context(attributes,classes,ranks,feats,record,false)
  if not context.errors.is_empty(): return RulesJson.result(context.errors)
  if feat_at(i+1,step.class_id,int(classes[step.class_id])):
   var feat := registry.definition("feats",step.feat_id)
   if feat.is_empty(): return RulesJson.result([RulesJson.issue("advancement.feat",path,"A legal feat choice is required")])
   if feats.has(step.feat_id) and not feat.repeatable: return RulesJson.result([RulesJson.issue("advancement.feat_repeat",path,"Feat is not repeatable")])
   requirement=RulesExpressions.evaluate_requirements(feat.requirements,context)
   if not requirement.ok:
    for reason in requirement.errors: reason.path=path+"."+str(reason.path)
    return requirement
   feats.append(step.feat_id)
  elif not step.feat_id.is_empty(): return RulesJson.result([RulesJson.issue("advancement.feat_schedule",path,"No feat choice at this level")])
  if RulesCareer.enabled(registry):
   var remaining := RulesCareer.feat_count(registry,i+1,step.class_id,int(classes[step.class_id]))-int(feat_at(i+1,step.class_id,int(classes[step.class_id])))
   if step.bonus_feats.size()!=remaining:return RulesJson.result([RulesJson.issue("career.feat_count",path,"Every simultaneous feat grant requires its own choice")])
   for id in step.bonus_feats:
    var feat := registry.definition("feats",str(id))
    if feat.is_empty() or feats.has(id) and not feat.repeatable:return RulesJson.result([RulesJson.issue("career.feat",path,"Choose a legal, unclaimed additional feat")])
    context=_context(attributes,classes,ranks,feats,record,false)
    var valid := RulesExpressions.evaluate_requirements(feat.requirements,context)
    if not valid.ok:return valid
    feats.append(id)
  context=_context(attributes,classes,ranks,feats,record,false)
  if not context.errors.is_empty(): return RulesJson.result(context.errors)
 var permanent_spell_context := context
 context=_context(attributes,classes,ranks,feats,record,true,attack_weapon)
 if not context.errors.is_empty(): return RulesJson.result(context.errors)
 var slots := {}
 for id in record.equipment:
  if not id is String: return RulesJson.result([RulesJson.issue("equipment.reference","equipment","Equipment ID must be a string")])
  var item := registry.definition("equipment",id)
  if item.is_empty(): return RulesJson.result([RulesJson.issue("equipment.reference","equipment","Unknown equipment",{"id":id})])
  if RulesMartial.enabled(registry) and item.tags.has("manifested"):return RulesJson.result([RulesJson.issue("equipment.manifested",id,"Manifested weapons come from active abilities, never inventory or starting gear")])
  if slots.has(id): return RulesJson.result([RulesJson.issue("equipment.duplicate","equipment","Duplicate equipment reference")])
  if registry.rules_ref().engine_schema==3 and not classes.is_empty() and not RulesCoreContent.equipment_legal(item,classes,registry):return RulesJson.result([RulesJson.issue("equipment.proficiency",id,"Not proficient with this equipment, or incompatible with Monk discipline")])
  if registry.rules_ref().engine_schema==3 and item.kind=="weapon" and slots.has("slot:weapon"):return RulesJson.result([RulesJson.issue("equipment.slot",id,"Choose one active weapon")])
  if item.kind in ["armor","shield"] and slots.has("slot:"+item.kind): return RulesJson.result([RulesJson.issue("equipment.slot","equipment","Conflicting equipment slot")])
  slots[id]=true;slots["slot:"+item.kind]=true
  var legal := RulesExpressions.evaluate_requirements(item.requirements,context)
  if not legal.ok: return legal
 if RulesCapabilities.enabled(registry):
  var body_caps := RulesCapabilities.derive(context,record,registry,false)
  for id in record.equipment:
   if registry.definition("equipment",id).kind in body_caps.blocked_equipment:return RulesJson.result([RulesJson.issue("equipment.body",id,"Inherited body configuration cannot use this slot")])
 if record.choices.prepared_abilities.size()!=RulesRegistry._unique_count(record.choices.prepared_abilities): return RulesJson.result([RulesJson.issue("build.prepared_duplicate","choices","Prepared abilities must be unique")])
 for id in record.choices.prepared_abilities:
  if not id is String or not (context.abilities.has(id) or RulesEntities.enabled(registry) and not RulesEntities.form(record,registry).is_empty() and _context(attributes,classes,ranks,feats,record,false).abilities.has(id)): return RulesJson.result([RulesJson.issue("build.prepared","choices","Prepared ability is not granted")])
 if registry.rules_ref().engine_schema==3:
  var spell_errors := RulesCoreContent.selection_errors(record,permanent_spell_context if registry.rules_ref().pack_id in ["trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29","trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33","trhgd-character-v34","trhgd-character-v35"] else context,registry)
  if not spell_errors.is_empty():return RulesJson.result(spell_errors)
 return {"ok":true,"context":context}

func _feature(context: Dictionary,id: String,source: String) -> void:
 var definition := registry.definition("features",id)
 if definition.is_empty(): return
 if not context.features.has(id): context.features.append(id)
 context.feature_sources.append({"id":id,"source":source})
 for key in ["tags","senses","abilities","resources"]:
  for value in definition.get(key,[]):
   if not context[key].has(value): context[key].append(value)
 for child in definition.grants: _feature(context,child,source+">"+child)

func _context(attributes: Dictionary,classes: Dictionary,ranks: Dictionary,feats: Array,record: Dictionary,include_runtime: bool,attack_weapon: String="") -> Dictionary:
 var context := {"attributes":attributes.duplicate(true),"classes":classes.duplicate(true),"skills":ranks.duplicate(true),"feats":feats.duplicate(),"features":[],"feature_sources":[],"tags":[],"ancestry_tags":[],"senses":["sight","hearing"],"abilities":registry.rule("base_abilities").duplicate(),"resources":[],"casting":{},"capacities":{},"level":0,"stats":{},"errors":[]}
 for id in classes: context.level+=int(classes[id])
 if RulesCareer.enabled(registry):context.casting_levels=RulesCareer.casting_levels(record,classes,registry)
 for pair in [["ancestries",record.ancestry_ref],["backgrounds",record.background_ref]]:
  var source := registry.definition(pair[0],pair[1])
  for tag in source.get("tags",[]):
   if not context.tags.has(tag): context.tags.append(tag)
   if pair[0]=="ancestries": context.ancestry_tags.append(tag)
  for id in source.get("features",[]): _feature(context,id,pair[1]+":"+id)
 var base := {"HP":int(registry.rule("base_hp")),"BAB":0,"defence":int(registry.rule("base_defence")),"fortitude":0,"reflex":0,"will":0,"stride":int(registry.rule("base_stride")),"reach":int(registry.rule("base_reach")),"initiative":0,"save_dc":0,"damage":0}
 for id in classes:
  var cls := registry.definition("classes",id)
  base.HP+=int(classes[id])*int(cls.hp_per_level)
  base.BAB+=_value(cls.bab,context)
  for save in RulesExpressions.SAVES: base[save]+=_value(cls.saves[save],context)
  if not cls.casting_tradition.is_empty(): context.casting[cls.casting_tradition]=int(context.casting.get(cls.casting_tradition,0))+_value(cls.casting,context)
  for tier in cls.features:
   if int(classes[id])>=int(tier.at): _feature(context,tier.id,id+":"+str(tier.at)+":"+tier.id)
 if RulesCareer.enabled(registry):
  for option in RulesCareer.selections(record,classes,registry):
   for id in option.features:_feature(context,id,"choice:"+str(option.id)+":"+id)
  for id in context.casting_levels:
   var cls := registry.definition("classes",id)
   if cls.get("spell_mode","").is_empty():continue
   var extra := int(context.casting_levels[id])-int(classes.get(id,0))
   context.casting[cls.casting_tradition]=int(context.casting.get(cls.casting_tradition,0))+extra
   for tier in cls.features:
    if int(tier.at)>int(classes.get(id,0)) and int(tier.at)<=int(context.casting_levels[id]) and registry.definition("features",tier.id).tags.has("casting_tier"):_feature(context,tier.id,"hybrid:"+id+":"+tier.id)
 for i in feats.size():
  for id in registry.definition("feats",feats[i]).get("features",[]): _feature(context,id,"feat:"+str(i)+":"+id)
 if include_runtime:
  for id in record.runtime.granted_features: _feature(context,str(id),"granted:"+str(id))
  for sense in record.runtime.senses:
   if not context.senses.has(sense): context.senses.append(sense)
 var active_form := RulesEntities.form(record,registry) if include_runtime else {}
 if not active_form.is_empty():
  for id in active_form.attributes:context.attributes[id]+=int(active_form.attributes[id])
  _feature(context,active_form.feature_id,"form:"+active_form.id)
 if registry.rules_ref().pack_id in ["trhgd-character-v28","trhgd-character-v29","trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33","trhgd-character-v34","trhgd-character-v35"]:context.casting_modifiers=RulesCareer.casting_modifiers(record,classes,context.attributes,registry)
 var physical: Dictionary=context.attributes
 var con := int(floor(float(int(attributes.CON)-10)/2.0))
 var dex := int(floor(float(int(physical.DEX)-10)/2.0))
 base.HP=maxi(1,int(base.HP)+con*int(context.level));base.defence+=dex;base.fortitude+=con;base.reflex+=dex
 base.will+=int(floor(float(int(attributes.WIS)-10)/2.0));base.initiative=dex
 if registry.rules_ref().engine_schema==3:
  if context.tags.has("monk_unarmoured") and not record.equipment.any(func(id: String):return registry.definition("equipment",id).kind in ["armor","shield"]):base.defence+=maxi(0,int(floor(float(int(attributes.WIS)-10)/2.0)))
  if context.tags.has("divine_grace"):
   for save in RulesExpressions.SAVES:base[save]+=maxi(0,int(floor(float(int(attributes.CHA)-10)/2.0)))
 base.melee_attack=int(base.BAB)+int(floor(float(int(physical.STR)-10)/2.0));base.ranged_attack=int(base.BAB)+dex
 context.stats=base.duplicate(true)
 for resource in context.resources:
  var definition := registry.definition("resources",resource)
  context.capacities[resource]=maxi(0,_value(definition.capacity,context))
  if registry.rules_ref().engine_schema==3 and definition.has("prepared_ability"):context.capacities[resource]=int(record.choices.spell_preparations.get(definition.prepared_ability,0))
 if RulesCapabilities.enabled(registry):
  var bonuses: Dictionary=RulesCapabilities.derive(context,record,registry,false).resource_bonuses
  for id in bonuses:
   if not context.capacities.has(id):context.errors.append(RulesJson.issue("capability.resource_unowned",id,"Capacity bonus requires an owned pool"))
   else:context.capacities[id]=maxi(0,int(context.capacities[id])+int(bonuses[id]))
 var modifiers := {}
 for stat in RulesRegistry.STATS: modifiers[stat]=[]
 for entry in context.feature_sources: _collect_modifiers(registry.definition("features",entry.id).modifiers,entry.source,context,modifiers)
 for pair in [["ancestries",record.ancestry_ref],["backgrounds",record.background_ref]]: _collect_modifiers(registry.definition(pair[0],pair[1]).get("modifiers",[]),pair[1],context,modifiers)
 for id in record.equipment:
  if not active_form.is_empty() and registry.definition("equipment",str(id)).kind in active_form.suppressed_equipment:continue
  var item := registry.definition("equipment",str(id))
  _collect_modifiers(item.get("modifiers",[]),"equipment:"+str(id),context,modifiers)
  for tag in item.get("tags",[]):
   if not context.tags.has(tag): context.tags.append(tag)
  base.reach=maxi(int(base.reach),int(item.get("reach",1)))
 if include_runtime:
  for status in record.runtime.statuses:
   if status is Dictionary:
    var definition := registry.definition("statuses",str(status.get("id")))
    _collect_modifiers(definition.get("modifiers",[]),str(status.get("source","status"))+":"+str(status.get("id")),context,modifiers)
    for tag in definition.get("tags",[]):
     if not context.tags.has(tag): context.tags.append(tag)
  for m in record.runtime.modifiers:
   if m is Dictionary and modifiers.has(m.get("stat")): modifiers[m.stat].append(m)
 if RulesMartial.mobile_enabled(registry) and RulesMartial.fencing_equipment(record,registry,include_runtime):context.tags.append("fencing_ready")
 if registry.rules_ref().pack_id in ["trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33","trhgd-character-v34","trhgd-character-v35"]:context.tags.append_array(RulesMartial.weapon_context_tags(record,registry,include_runtime,attack_weapon))
 var applied := {}
 for stat in RulesRegistry.STATS:
  var combined := RulesModifiers.combine(int(base.get(stat,0)),modifiers[stat],context)
  if not combined.ok: context.errors.append_array(combined.errors)
  context.stats[stat]=combined.get("value",0);applied[stat]=combined.get("applied",[])
 context.stats.stride=maxi(1,int(context.stats.stride));context.stats.HP=maxi(1,int(context.stats.HP))
 if not active_form.is_empty():
  context.abilities=context.abilities.filter(func(id: String):return not registry.definition("abilities",id).tags.has("spell") and (not RulesPsychic.enabled(registry) or not registry.definition("abilities",id).tags.has("psychic")) and (not RulesWaveFive.enabled(registry) or not registry.definition("abilities",id).tags.has("supernatural")))
  context.body_form=active_form.duplicate(true)
  if registry.rules_ref().pack_id in ["trhgd-character-v27","trhgd-character-v28","trhgd-character-v29","trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33","trhgd-character-v34","trhgd-character-v35"] and not context.abilities.has("revert-form"):context.abilities.append("revert-form")
 if RulesPsychic.enabled(registry):RulesPsychic.project(context,registry,record)
 context.applied_modifiers=applied
 for key in ["features","tags","ancestry_tags","abilities","resources","senses"]: context[key].sort()
 return context

func _value(expression: Dictionary,context: Dictionary) -> int:
 var result := RulesExpressions.evaluate_formula(expression,context)
 if not result.ok: context.errors.append_array(result.errors)
 return int(result.get("value",0))

func _collect_modifiers(definitions: Array,source: String,context: Dictionary,output: Dictionary) -> void:
 for i in definitions.size():
  var definition: Dictionary=definitions[i]
  var evaluated := RulesExpressions.evaluate_formula(definition.value,context)
  if not evaluated.ok: context.errors.append_array(evaluated.errors)
  var modifier := {"stat":definition.stat,"source":source+":"+str(i),"type":definition.type,"value":int(evaluated.get("value",0))}
  if definition.has("when"): modifier.when=definition.when
  output[definition.stat].append(modifier)

func _runtime_errors(record: Dictionary,context: Dictionary) -> Array:
 var errors: Array=[];var runtime: Dictionary=record.runtime
 if RulesEntities.enabled(registry):errors.append_array(RulesEntities.runtime_errors(record,registry))
 for key in ["granted_features","senses"]:
  if runtime[key].size()!=RulesRegistry._unique_count(runtime[key]): errors.append(RulesJson.issue("runtime.duplicate","runtime."+key,"Granted identifiers must be unique"))
 var status_ids := {}
 for status in runtime.statuses:
  if status is Dictionary:
   var definition := registry.definition("statuses",str(status.get("id")))
   if not definition.is_empty() and definition.stacking!="stack" and status_ids.has(status.get("id")): errors.append(RulesJson.issue("runtime.status_stack","runtime.statuses","Persisted instances violate the status stacking policy"))
   status_ids[status.get("id")]=true
 if int(runtime.hp)>int(context.stats.HP): errors.append(RulesJson.issue("runtime.hp","runtime.hp","Current HP exceeds derived maximum"))
 for id in runtime.resources:
  if not context.capacities.has(id) or not RulesJson.integer(runtime.resources[id],0,int(context.capacities.get(id,0))): errors.append(RulesJson.issue("runtime.resource","runtime.resources."+str(id),"Unowned or out-of-capacity resource"))
 for id in context.capacities:
  if not runtime.resources.has(id): errors.append(RulesJson.issue("runtime.resource_missing","runtime.resources."+str(id),"Granted resource has no current value"))
 for id in runtime.granted_features:
  if not id is String or registry.definition("features",id).is_empty(): errors.append(RulesJson.issue("runtime.feature","runtime.granted_features","Unknown granted feature"))
 for sense in runtime.senses:
  if not sense is String or sense.length()>64: errors.append(RulesJson.issue("runtime.sense","runtime.senses","Invalid sense"))
 for status in runtime.statuses:
  if not status is Dictionary or status.size()!=4 or registry.definition("statuses",str(status.get("id"))).is_empty() or not status.get("source") is String or not RulesJson.integer(status.get("remaining"),1,1000) or not status.get("expiry") in RulesRegistry.EXPIRY: errors.append(RulesJson.issue("runtime.status","runtime.statuses","Invalid persisted status instance"))
 for status in runtime.statuses:
  if status is Dictionary:
   var definition := registry.definition("statuses",str(status.get("id")))
   if not definition.is_empty() and (status.get("expiry")!=definition.duration.expiry or not RulesJson.integer(status.get("remaining"),1,int(definition.duration.amount))): errors.append(RulesJson.issue("runtime.status_duration","runtime.statuses","Status expiry must match its pinned definition"))
 for modifier in runtime.modifiers:
  if not modifier is Dictionary or not modifier.get("stat") in RulesRegistry.STATS or not modifier.get("type") in RulesRegistry.TYPES or not RulesJson.integer(modifier.get("value")) or not modifier.get("source") is String: errors.append(RulesJson.issue("runtime.modifier","runtime.modifiers","Invalid persisted modifier"))
  elif modifier.has("when"): errors.append_array(RulesExpressions.validate_requirement(modifier.when,"runtime.modifiers.when"))
 for appearance in runtime.apparent_effects:
  if not appearance is Dictionary or not appearance.get("apparent_id") is String or not appearance.apparent_id.begins_with("apparent:") or not appearance.get("source_character_id") is String or not RulesJson.integer(appearance.get("dc"),0,1000): errors.append(RulesJson.issue("runtime.appearance","runtime.apparent_effects","Invalid nonphysical descriptor"))
  else:
   var descriptor: Dictionary=appearance.duplicate(true);descriptor.erase("apparent_id");descriptor.erase("source_character_id")
   descriptor.dc={"op":"const","value":int(descriptor.dc)}
   RulesRegistry.validate_effect({"op":"apparent_effect","descriptor":descriptor},registry._tables,"runtime.apparent_effects",errors)
 if RulesWaveFour.enabled(registry):errors.append_array(RulesWaveFour.validate_runtime(record,context,registry))
 return errors

func derive_character(record: Dictionary,attack_weapon: String="") -> Dictionary:
 # Optional transient attack context never enters saved records, permanent
 # advancement requirements, normal sheets or the default snapshot hash.
 if not attack_weapon.is_empty() and (registry.rules_ref().pack_id not in ["trhgd-character-v30","trhgd-character-v31","trhgd-character-v32","trhgd-character-v33","trhgd-character-v34","trhgd-character-v35"] or registry.definition("equipment",attack_weapon).get("kind")!="weapon"):return RulesJson.result([RulesJson.issue("build.attack_context","attack_weapon","A supported actual weapon is required")])
 if int(registry.rules_ref().get("engine_schema",1))>=2:record=RulesJson.string_keys(record)
 var replay := _replay(record,attack_weapon)
 if not replay.ok: return replay
 var errors := _runtime_errors(record,replay.context)
 if not errors.is_empty(): return RulesJson.result(errors)
 var c: Dictionary=replay.context
 var skills := {}
 for id in registry.ids("skills"):
  var definition := registry.definition("skills",id)
  var modifiers: Array=[]
  for i in definition.modifiers.size():
   var m: Dictionary=definition.modifiers[i]
   var evaluated := RulesExpressions.evaluate_formula(m.value,c)
   if not evaluated.ok: return evaluated
   var typed := {"source":"skill:"+id+":"+str(i),"type":m.type,"value":int(evaluated.value)}
   if m.has("when"): typed.when=m.when
   modifiers.append(typed)
  var total := RulesModifiers.combine(int(c.skills[id])+int(floor(float(int(c.attributes[definition.attribute])-10)/2.0)),modifiers,c)
  if not total.ok: return total
  if registry.rules_ref().engine_schema==3:
   var ancestry := registry.definition("ancestries",record.ancestry_ref)
   total.value+=int(ancestry.skill_bonuses.get(id,0))
   if int(c.skills[id])>0 and c.classes.keys().any(func(cls: String):return registry.definition("classes",cls).class_skills.has(id)):total.value+=3
  skills[id]={"ranks":int(c.skills[id]),"total":total.value,"usable":not definition.trained_only or int(c.skills[id])>0,"typed_modifiers":total.applied}
 var snapshot := {"schema_version":1,"rules_ref":registry.rules_ref(),"character_id":record.character_id,"build_hash":RulesJson.digest(record),"level":c.level,"class_levels":c.classes,"attributes":c.attributes,"stats":c.stats,"skills":skills,"features":c.features,"feats":c.feats,"tags":c.tags,"senses":c.senses,"abilities":c.abilities,"resource_capacities":c.capacities,"current_resources":record.runtime.resources.duplicate(true),"prepared_abilities":record.choices.prepared_abilities.duplicate(),"casting":c.casting,"runtime_statuses":record.runtime.statuses.duplicate(true),"maintained_effects":record.runtime.apparent_effects.duplicate(true),"current_hp":int(record.runtime.hp),"temporary_hp":int(record.runtime.temporary_hp),"equipment":record.equipment.duplicate(true),"typed_modifiers":c.applied_modifiers,"action_contract":{"move":1,"main":1,"shared_reaction":int(registry.rule("shared_reaction")),"reaction_refresh":"global_round_start"}}
 if int(registry.rules_ref().get("engine_schema",1))>=2:snapshot=RulesJson.string_keys(snapshot)
 if registry.rules_ref().engine_schema==3:
  snapshot.spell_preparations=record.choices.spell_preparations.duplicate(true)
  snapshot.ancestry=registry.definition("ancestries",record.ancestry_ref).duplicate(true)
  snapshot.base_attributes=record.base_attributes.duplicate(true)
  snapshot.proficiencies=RulesCoreContent.proficiencies(c.classes,registry)
  if RulesCareer.enabled(registry):
   snapshot.specialisations=RulesCareer.selections(record,c.classes,registry).duplicate(true)
   snapshot.casting_levels=c.casting_levels.duplicate()
  snapshot=RulesJson.string_keys(snapshot)
 if RulesCapabilities.enabled(registry):snapshot.capabilities=RulesCapabilities.derive(c,record,registry,true)
 if RulesEntities.enabled(registry):
  snapshot.body_form=c.get("body_form",{}).duplicate(true)
  snapshot.companions=record.runtime.companions.duplicate(true)
 if RulesPsychic.enabled(registry):
  snapshot.manifesting_level=c.manifesting_level;snapshot.known_powers=c.known_powers.duplicate()
  if RulesPsychic.parity_enabled(registry):snapshot.power_origins=c.power_origins.duplicate(true)
 if RulesWaveFour.enabled(registry):
  snapshot.manifested_powers=record.runtime.manifested_powers.duplicate()
  snapshot.distinct_power_limit=RulesWaveFour.distinct_limit(c,registry)
 # v13 appends typed psychic/creature fields after the legacy snapshot boundary.
 # Canonicalise those keys before hashing; mixed String/StringName sorting can
 # otherwise depend on which historical scripts were loaded earlier in a process.
 if RulesPsychic.enabled(registry):
  snapshot=RulesJson.string_keys(snapshot)
  snapshot["snapshot_hash"]=RulesJson.digest(snapshot)
 else:snapshot.snapshot_hash=RulesJson.digest(snapshot)
 return {"ok":true,"snapshot":RulesJson.freeze(snapshot),"context":c}

func preview_advancement(record: Dictionary,choice: Dictionary) -> Dictionary:
 if RulesWaveFour.enabled(registry):choice=RulesJson.string_keys(choice)
 var old := validate_build(record)
 if not old.ok: return old
 var candidate: Dictionary=record.duplicate(true)
 if choice.size()!=(6 if RulesCareer.enabled(registry) else 4) or not choice.get("skill_allocations") is Dictionary or not choice.get("class_id") is String or not choice.get("feat_id") is String or not choice.get("attribute_increase") is String: return RulesJson.result([RulesJson.issue("advancement.choice","choice","Exactly six typed choice fields required, including specialisations and additional feats" if RulesCareer.enabled(registry) else "Exactly four typed choice fields required")])
 if RulesCareer.enabled(registry) and (not choice.get("specialisations") is Dictionary or not choice.get("bonus_feats") is Array or not choice.bonus_feats.all(func(id: Variant):return id is String)):
  return RulesJson.result([RulesJson.issue("career.choice","choice","Typed specialisations and additional feat IDs required")])
 var next_level: int=candidate.advancement_history.size()+1
 var step := {"level":next_level,"class_id":choice.get("class_id",""),"skill_allocations":choice.get("skill_allocations",{}).duplicate(true),"feat_id":choice.get("feat_id",""),"attribute_increase":choice.get("attribute_increase","")}
 if RulesCareer.enabled(registry):
  step["specialisations"]=choice.get("specialisations",{}).duplicate(true)
  step["bonus_feats"]=choice.get("bonus_feats",[]).duplicate()
 candidate.advancement_history.append(step)
 var replay := _replay(candidate)
 if not replay.ok: return replay
 candidate.revision=int(candidate.revision)+1
 for id in replay.context.capacities:
  if not candidate.runtime.resources.has(id): candidate.runtime.resources[id]=int(replay.context.capacities[id])
 if next_level==1: candidate.runtime.hp=int(replay.context.stats.HP)
 candidate.runtime.hp=mini(int(candidate.runtime.hp),int(replay.context.stats.HP))
 if RulesEntities.enabled(registry):
  var synced := RulesEntities.synchronize(candidate,registry)
  if not synced.ok:return synced
 var derived := derive_character(candidate)
 if not derived.ok: return derived
 return {"ok":true,"candidate":candidate,"snapshot":derived.snapshot,"before_hash":RulesJson.digest(record)}

func apply_advancement(record: Dictionary,choice: Dictionary,expected_revision: int) -> Dictionary:
 if record.get("revision")!=expected_revision: return RulesJson.result([RulesJson.issue("advancement.stale","revision","Expected revision differs")])
 return preview_advancement(record,choice)

func starting_classes() -> Array:
 # Older packs have ordinary classes without an explicit class_kind field.
 return registry.ids("classes").filter(func(id: String):return registry.definition("classes",id).get("class_kind","base")=="base")

func available_advancement(record: Dictionary) -> Dictionary:
 var derived := derive_character(record)
 if not derived.ok: return derived
 # Entry options must use the same durable qualification basis as replay.
 # Temporary battle/runtime grants do not rewrite historical class entry.
 var c: Dictionary=derived.context
 var entry_attributes: Dictionary=c.attributes.duplicate()
 if RulesEntities.enabled(registry):
  for id in RulesEntities.form(record,registry).get("attributes",{}):entry_attributes[id]-=int(RulesEntities.form(record,registry).attributes[id])
 var entry_context := _context(entry_attributes,c.classes,c.skills,c.feats,record,false)
 if not entry_context.errors.is_empty(): return RulesJson.result(entry_context.errors)
 var options := {}
 for id in registry.ids("classes"):
  if registry.definition("classes",id).get("class_kind")=="companion":continue
  var definition := registry.definition("classes",id)
  var result := RulesCompleteness.entry_requirements(definition.requirements,entry_context,record,registry)
  if int(c.level)==0 and definition.get("class_kind")=="prestige":result=RulesJson.result([RulesJson.issue("advancement.prestige_start",id,"Prestige paths are earned advancement choices, not starting classes")])
  if int(derived.context.level)>=int(registry.rule("max_level")) or int(derived.context.classes.get(id,0))>=int(definition.max_level): result=RulesJson.result([RulesJson.issue("advancement.level_cap",id,"Progression limit reached")])
  options[id]=result
 return {"ok":true,"classes":options,"next_level":int(derived.context.level)+1}

func suggested_choice(record: Dictionary,class_id: String,preferred_feat: String = "steady-study") -> Dictionary:
 var replay := _replay(record)
 if not replay.ok: return replay
 var cls := registry.definition("classes",class_id)
 if cls.is_empty(): return RulesJson.result([RulesJson.issue("advancement.class",class_id,"Unknown class")])
 var c: Dictionary=replay.context
 var next: int=int(c.level)+1
 var attribute := ""
 if registry.rule("attribute_increase_levels").has(next):
  for id in RulesExpressions.ATTRIBUTES:
   if int(c.attributes[id])>=22:continue
   if attribute.is_empty() or int(c.attributes[id])>int(c.attributes[attribute]): attribute=id
 var int_value: int=int(c.attributes.INT)+(1 if attribute=="INT" else 0)
 var points := maxi(1,int(cls.skill_points)+int(floor(float(int_value-10)/2.0)))
 var allocation := {}
 # Skills are selected by stable content ID, prioritising the explicitly named
 # arcane skill for any build with casting. No role becomes a class implicitly.
 var order := registry.ids("skills")
 if registry.rules_ref().engine_schema==3:
  var preferred: Array=cls.class_skills.duplicate()
  for id in order:
   if not preferred.has(id):preferred.append(id)
  order=preferred
 if cls.casting_tradition=="arcane": order.erase("arcana");order.push_front("arcana")
 for skill in order:
  var amount := mini(points,next-int(c.skills.get(skill,0)))
  if amount>0: allocation[skill]=amount;points-=amount
 if points!=0: return RulesJson.result([RulesJson.issue("advancement.skill_capacity","skills","Insufficient skill capacity")])
 var feat := preferred_feat if feat_at(next,class_id,int(c.classes.get(class_id,0))+1) else ""
 var choice := {"class_id":class_id,"skill_allocations":allocation,"feat_id":feat,"attribute_increase":attribute}
 if RulesCareer.enabled(registry):
  choice.specialisations=RulesCareer.defaults(registry,class_id,int(c.classes.get(class_id,0))+1)
  var learned: Array=[]
  for group in RulesCareer.groups(registry,class_id,int(c.classes.get(class_id,0))+1):
   for option in group.options:
    if not RulesCareer.option_eligibility(registry,class_id,int(c.classes.get(class_id,0))+1,option,c,choice.specialisations).ok:continue
    var powers: Array=option.features.map(func(id: String):return str(registry.definition("features",id).get("known_power",""))).filter(func(id: String):return not id.is_empty())
    if powers.any(func(id: String):return learned.has(id)):continue
    choice.specialisations[group.id]=option.id;learned.append_array(powers);break
  choice.bonus_feats=["steady-study"] if RulesCareer.feat_count(registry,next,class_id,int(c.classes.get(class_id,0))+1)>1 else []
 return {"ok":true,"choice":choice}

func preview_choices(record: Dictionary,class_id: String,draft: Dictionary = {}) -> Dictionary:
 # Explain options after a selected class and partial choices, without applying.
 var valid := derive_character(record)
 if not valid.ok: return valid
 var available := available_advancement(record)
 if not available.classes.has(class_id): return RulesJson.result([RulesJson.issue("advancement.class",class_id,"Unknown class")])
 if not available.classes[class_id].ok: return available.classes[class_id]
 for key in draft:
  if not key in ["attribute_increase","skill_allocations"]: return RulesJson.result([RulesJson.issue("advancement.draft",str(key),"Unknown draft choice")])
 var level: int=int(valid.context.level)+1
 var attributes: Dictionary=valid.context.attributes.duplicate(true)
 var scheduled: bool=registry.rule("attribute_increase_levels").has(level)
 var chosen: String=str(draft.get("attribute_increase",""))
 var attribute_options: Array=[]
 if scheduled:
  for id in RulesExpressions.ATTRIBUTES:
   if int(attributes[id])<22: attribute_options.append(id)
 if not chosen.is_empty():
  if not attribute_options.has(chosen): return RulesJson.result([RulesJson.issue("advancement.attribute","draft","Attribute choice unavailable")])
  attributes[chosen]+=1
 var cls := registry.definition("classes",class_id)
 var points := maxi(1,int(cls.skill_points)+int(floor(float(int(attributes.INT)-10)/2.0)))
 var ranks: Dictionary=valid.context.skills.duplicate(true)
 var caps := {};var allocation: Variant=draft.get("skill_allocations",{})
 if not allocation is Dictionary: return RulesJson.result([RulesJson.issue("advancement.skill","draft","Skill allocations must be a dictionary")])
 var spent := 0
 for id in ranks: caps[id]=level-int(ranks[id])
 for id in allocation:
  if not caps.has(id) or not RulesJson.integer(allocation[id],0,int(caps.get(id,0))): return RulesJson.result([RulesJson.issue("advancement.skill","draft","Skill/rank allocation exceeds legal limit")])
  ranks[id]+=int(allocation[id]);spent+=int(allocation[id])
 if spent>points: return RulesJson.result([RulesJson.issue("advancement.skill_budget","draft","Skill-point budget exceeded")])
 var classes: Dictionary=valid.context.classes.duplicate(true)
 classes[class_id]=int(classes.get(class_id,0))+1
 var context := _context(attributes,classes,ranks,valid.context.feats,record,false)
 if not context.errors.is_empty(): return RulesJson.result(context.errors)
 var feats := {}
 if feat_at(level,class_id,int(classes[class_id])):
  for id in registry.ids("feats"):
   var feat := registry.definition("feats",id)
   feats[id]=RulesExpressions.evaluate_requirements(feat.requirements,context)
   if valid.context.feats.has(id) and not feat.repeatable: feats[id]=RulesJson.result([RulesJson.issue("advancement.feat_repeat",id,"Feat is not repeatable")])
 return {"ok":true,"level":level,"class_id":class_id,"attribute_options":attribute_options,"attribute_choice_required":scheduled and chosen.is_empty(),"skill_points":points,"skill_points_remaining":points-spent,"skill_rank_room":caps,"feat_choices":feats,"snapshot_unchanged":valid.snapshot.snapshot_hash}
