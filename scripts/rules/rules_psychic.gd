class_name RulesPsychic
extends RefCounted
## v13 presentation/qualification adapter. Ordered history and GAME-32 effects own state.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id") in ["trhgd-character-v13","trhgd-character-v14","trhgd-character-v15","trhgd-character-v16","trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23"]
static func level(context: Dictionary,source: RulesRegistry) -> int:
 var total := 0
 for id in context.classes:
  if source.definition("classes",id).has("psychic_profile"):total+=int(context.classes[id])
 return mini(20,total)
static func known(context: Dictionary,source: RulesRegistry) -> Array:
 var powers: Array=[]
 for id in context.features:
  var power: String=str(source.definition("features",id).get("known_power",""))
  if not power.is_empty() and not powers.has(power):powers.append(power)
 powers.sort();return powers
static func eligibility(power_id: String,cls: String,class_level: int,context: Dictionary,source: RulesRegistry,chosen: Dictionary={}) -> Dictionary:
 var power := source.definition("psychic_powers",power_id)
 var profile: Dictionary=source.definition("classes",cls).get("psychic_profile",{})
 if power.is_empty() or profile.is_empty() or not power.class_ids.has(cls):return RulesJson.result([RulesJson.issue("psychic.class",power_id,"Power is unavailable to this class")])
 var incoming: Dictionary=context.duplicate(true);incoming.classes[cls]=class_level
 var tier: int=mini(int(profile.max_tier),(level(incoming,source)+1)/2)
 if int(power.tier)>tier:return RulesJson.result([RulesJson.issue("psychic.tier",power_id,"Requires manifesting level %d; class tier cap %d"%[2*int(power.tier)-1,int(profile.max_tier)])])
 if int(context.attributes.get(profile.attribute,0))<10+int(power.tier):return RulesJson.result([RulesJson.issue("psychic.attribute",power_id,"Requires %s %d"%[profile.attribute,10+int(power.tier)])])
 if known(context,source).has(power_id):return RulesJson.result([RulesJson.issue("psychic.duplicate",power_id,"Power already learned; choose a different power")])
 if profile.mantle_restricted:
  var tags: Array=context.tags.duplicate()
  for group in RulesCareer.groups(source,cls,class_level):
   for option in group.options:
    if chosen.get(group.id)!=option.id:continue
    for id in option.features:
     for tag in source.definition("features",id).tags:
      if not tags.has(tag):tags.append(tag)
  if not power.mantle_tags.any(func(tag: String):return tags.has(tag)):return RulesJson.result([RulesJson.issue("psychic.mantle",power_id,"Requires one of the selected mantles: "+", ".join(power.mantle_tags))])
 return {"ok":true}
static func project(context: Dictionary,source: RulesRegistry) -> void:
 context.manifesting_level=level(context,source);context.known_powers=known(context,source)
 context.manifesting_modifier=-5
 for cls in context.classes:
  var profile: Dictionary=source.definition("classes",cls).get("psychic_profile",{})
  if not profile.is_empty():context.manifesting_modifier=maxi(int(context.manifesting_modifier),int(floor(float(int(context.attributes[profile.attribute])-10)/2.0)))
 if int(context.manifesting_level)==0:context.manifesting_modifier=0
 context.abilities=context.abilities.filter(func(id: String):
  var row := source.definition("abilities",id)
  if not row.has("psychic_power"):return true
  return context.known_powers.has(row.psychic_power) and int(row.cost.resources.get("psychic-points",0))<=int(context.manifesting_level))
static func validate_power(row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if row.size()!=10 or not row.has_all(["id","name","description","tier","discipline","class_ids","mantle_tags","feature_id","variants","provenance"]):errors.append(RulesJson.issue("psychic.schema",row.id,"Typed power repertoire required"));return
 if not row.name is String or not row.description is String or not RulesJson.integer(row.tier,1,9) or row.discipline not in ["energy","mind","body","insight","unity"] or not row.class_ids is Array or row.class_ids.is_empty() or not row.mantle_tags is Array or not row.mantle_tags.all(func(id: Variant):return id is String) or not row.variants is Array or row.variants.is_empty() or not row.provenance is Dictionary or not row.provenance.get("license") is String:errors.append(RulesJson.issue("psychic.schema",row.id,"Valid tiers, discipline, eligibility and provenance required"));return
 RulesRegistry._reference(tables,"features",row.feature_id,row.id,errors)
 for cls in row.class_ids:
  RulesRegistry._reference(tables,"classes",cls,row.id,errors)
  if not tables.classes.get(cls,{}).has("psychic_profile"):errors.append(RulesJson.issue("psychic.class",row.id,"Power access requires an actual manifesting class"))
 if tables.features.get(row.feature_id,{}).get("abilities",[])!=row.variants:errors.append(RulesJson.issue("psychic.knowledge",row.id,"Known feature must grant exactly the authored augmentation variants"))
 var seen := {}
 for id in row.variants:
  RulesRegistry._reference(tables,"abilities",id,row.id,errors)
  var ability: Dictionary=tables.abilities.get(id,{})
  if ability.get("psychic_power")!=row.id or not RulesJson.integer(ability.get("augmentation"),0,18) or ability.get("cost",{}).get("resources",{}).get("psychic-points")!=2*int(row.tier)-1+int(ability.get("augmentation",-1)):errors.append(RulesJson.issue("psychic.variant",row.id,"Variants require actual point expenditure matching base tier plus augmentation"))
  if seen.has(ability.get("augmentation")):errors.append(RulesJson.issue("psychic.variant",row.id,"Distinct augmentation amounts required"))
  seen[ability.get("augmentation")]=true
 if not seen.has(0):errors.append(RulesJson.issue("psychic.base",row.id,"Unaugmented power required"))
 if tables.features.get(row.feature_id,{}).get("known_power")!=row.id:errors.append(RulesJson.issue("psychic.knowledge",row.id,"Known-power feature must identify this power"))
static func validate_definition(category: String,row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if row.has("psychic_profile"):
  var value: Variant=row.psychic_profile
  if category!="classes" or not value is Dictionary or value.size()!=4 or not value.has_all(["max_tier","attribute","points_per_level","mantle_restricted"]) or not RulesJson.integer(value.max_tier,1,9) or value.attribute not in ["INT","WIS","CHA"] or not RulesJson.integer(value.points_per_level,1,3) or not value.mantle_restricted is bool:errors.append(RulesJson.issue("psychic.profile",row.id,"Typed class manifesting profile required"))
 if row.has("unique_selection") and (category!="features" or row.unique_selection!=true):errors.append(RulesJson.issue("career.unique",row.id,"Explicit permanent unique selection required"))
 if row.has("known_power"):RulesRegistry._reference(tables,"psychic_powers",row.known_power,row.id,errors)
 if row.has("psychic_power"):RulesRegistry._reference(tables,"psychic_powers",row.psychic_power,row.id,errors)
 if row.has("augmentation") and (not row.has("psychic_power") or not RulesJson.integer(row.augmentation,0,18)):errors.append(RulesJson.issue("psychic.augmentation",row.id,"Augmentation belongs to a typed psychic power"))
 if row.has("companion_growth"):
  if category!="features":errors.append(RulesJson.issue("bond.growth",row.id,"Growth belongs to permanent features"))
  RulesRegistry._formula(row.companion_growth,tables,row.id,errors)
  if row.companion_growth is Dictionary and RulesRegistry._contains_stat(row.companion_growth):errors.append(RulesJson.issue("bond.growth",row.id,"Growth cannot depend on derived stats"))
