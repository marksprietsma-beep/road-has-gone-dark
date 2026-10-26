class_name RulesCareer
extends RefCounted
## Ordered, durable player choices. No runtime grants qualify historical entry.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id")in ["trhgd-character-v7","trhgd-character-v8","trhgd-character-v9","trhgd-character-v10","trhgd-character-v11","trhgd-character-v12","trhgd-character-v13","trhgd-character-v14","trhgd-character-v15","trhgd-character-v16","trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29","trhgd-character-v30","trhgd-character-v31"]
static func groups(source: RulesRegistry,cls: String,level: int) -> Array:
 return source.definition("classes",cls).get("career_choices",[]).filter(func(row: Dictionary):return int(row.at)==level)
static func feat_count(source: RulesRegistry,level: int,cls: String,class_level: int) -> int:
 return int(source.rule("feat_levels").has(level))+int(source.definition("classes",cls).bonus_feat_levels.has(class_level))
static func defaults(source: RulesRegistry,cls: String,level: int) -> Dictionary:
 var chosen := {}
 for group in groups(source,cls,level):chosen[group.id]=group.options[0].id
 return chosen
static func selections(record: Dictionary,classes: Dictionary,source: RulesRegistry) -> Array:
 var selected: Array=[];var counts := {}
 for step in record.advancement_history:
  var cls: String=str(step.class_id);counts[cls]=int(counts.get(cls,0))+1
  if int(counts[cls])>int(classes.get(cls,0)):continue
  for group in groups(source,cls,int(counts[cls])):
   for option in group.options:
    if step.get("specialisations",{}).get(group.id)==option.id:selected.append(option)
 return selected
static func option_eligibility(source: RulesRegistry,cls: String,level: int,option: Dictionary,context: Dictionary,chosen: Dictionary={}) -> Dictionary:
 var result := RulesExpressions.evaluate_requirements(option.requirements,context)
 if not result.ok or not RulesPsychic.enabled(source):return result
 for id in option.features:
  var feature := source.definition("features",id)
  if feature.get("unique_selection",false) and context.features.has(id):return RulesJson.result([RulesJson.issue("career.unique",id,"This permanent selection is already learned")])
  var power: String=str(feature.get("known_power",""))
  if not power.is_empty():
   var eligible := RulesPsychic.eligibility(power,cls,level,context,source,chosen)
   if not eligible.ok:return eligible
 return {"ok":true}
static func validate_choices(source: RulesRegistry,cls: String,level: int,chosen: Variant,context: Dictionary) -> Array:
 if not chosen is Dictionary:return [RulesJson.issue("career.schema",cls,"Select explicit class specialisations")]
 var scheduled := groups(source,cls,level);var errors: Array=[];var learned: Array=[];var unique: Array=[]
 if chosen.size()!=scheduled.size():errors.append(RulesJson.issue("career.count",cls,"Select exactly the scheduled class options"))
 for group in scheduled:
  var matches: Array=group.options.filter(func(option: Dictionary):return option.id==chosen.get(group.id))
  if matches.size()!=1:errors.append(RulesJson.issue("career.option",group.id,"Choose one valid specialisation"));continue
  errors.append_array(option_eligibility(source,cls,level,matches[0],context,chosen).get("errors",[]))
  if RulesPsychic.enabled(source):
   for id in matches[0].features:
    if source.definition("features",id).get("unique_selection",false):
     if unique.has(id):errors.append(RulesJson.issue("career.unique",id,"Choose different permanent selections"))
     unique.append(id)
    var power: String=str(source.definition("features",id).get("known_power",""))
    if power.is_empty():continue
    if learned.has(power):errors.append(RulesJson.issue("psychic.duplicate",power,"Choose distinct powers at this level"))
    learned.append(power)
 return errors
static func casting_levels(record: Dictionary,classes: Dictionary,source: RulesRegistry) -> Dictionary:
 var levels := classes.duplicate()
 for option in selections(record,classes,source):
  if option.has("advance_casting"):
   var target: String=option.advance_casting
   levels[target]=int(levels.get(target,0))+int(floor(float(classes.get(option.progression_class,0))/float(option.get("advance_ratio",1))))
 return levels
static func validate_definition(row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if row.has("class_kind") and row.class_kind not in (["base","prestige","companion"] if tables.has("creatures") else ["base","prestige"]):errors.append(RulesJson.issue("career.kind",row.id,"Known base/prestige classification required"))
 if not row.has("career_choices"):return
 if not row.career_choices is Array:errors.append(RulesJson.issue("career.definition",row.id,"Career groups must be an array"));return
 var ids := {}
 for group in row.career_choices:
  if not group is Dictionary or group.size()!=4 or not group.has_all(["id","name","at","options"]) or not group.id is String or not group.name is String or not RulesJson.integer(group.at,1,int(row.max_level)) or not group.options is Array or group.options.is_empty():errors.append(RulesJson.issue("career.group",row.id,"Typed scheduled choice group required"));continue
  if ids.has(group.id):errors.append(RulesJson.issue("career.duplicate",row.id,"Choice group IDs must be unique"))
  ids[group.id]=true;var options := {}
  for option in group.options:
   if not option is Dictionary or not option.has_all(["id","name","description","features","requirements"]) or not option.id is String or not option.name is String or not option.description is String or not option.features is Array:errors.append(RulesJson.issue("career.option_schema",group.id,"Typed explained option required"));continue
   if options.has(option.id):errors.append(RulesJson.issue("career.duplicate",group.id,"Option IDs must be unique"))
   options[option.id]=true
   for field in option:
    if field not in ["id","name","description","features","requirements","advance_casting","progression_class","advance_ratio"]:errors.append(RulesJson.issue("career.field",group.id,"Unknown option field"))
   for id in option.features:RulesRegistry._reference(tables,"features",id,group.id,errors)
   RulesRegistry._requirement(option.requirements,tables,group.id,errors)
   if option.has("advance_ratio") and (not option.has("advance_casting") or not RulesJson.integer(option.advance_ratio,1,4)):errors.append(RulesJson.issue("career.ratio",group.id,"Explicit bounded casting advancement ratio required"))
   if option.has("advance_casting"):
    RulesRegistry._reference(tables,"classes",option.advance_casting,group.id,errors)
    if option.get("progression_class")!=row.id or tables.classes.get(option.advance_casting,{}).get("spell_mode","").is_empty():errors.append(RulesJson.issue("career.casting",group.id,"Casting must advance an actual caster from this prestige track"))

static func casting_modifiers(record: Dictionary,classes: Dictionary,attributes: Dictionary,source: RulesRegistry) -> Dictionary:
 # Derive from ordered permanent choices, never runtime grants or highest score.
 var result := {};var targets := {}
 for id in classes:
  var attribute: String=str(source.definition("classes",id).get("casting_attribute",""))
  if not attribute.is_empty():result[id]=int(floor(float(int(attributes[attribute])-10)/2.0))
 for option in selections(record,classes,source):
  if not option.has("advance_casting"):continue
  var path: String=option.progression_class
  if not targets.has(path):targets[path]=[]
  if not targets[path].has(option.advance_casting):targets[path].append(option.advance_casting)
 for path in targets:
  # A multi-track path must name a base track, not choose an arbitrary one.
  if targets[path].size()!=1:continue
  var attribute: String=str(source.definition("classes",targets[path][0]).get("casting_attribute",""))
  if not attribute.is_empty():result[path]=int(floor(float(int(attributes[attribute])-10)/2.0))
 return result

static func quarry_matches(snapshot: Dictionary,target: Dictionary,source: RulesRegistry) -> bool:
 return enabled(source) and snapshot.tags.has("quarry_archer") and target.team=="enemy" and source.definition("equipment",target.weapon).tags.has("ranged")

static func requirement_text(node: Dictionary,source: RulesRegistry) -> String:
 var op: String=node.op
 if op in ["all","any"]:
  var words: Array=node.args.map(func(child: Dictionary):return requirement_text(child,source))
  return ("; " if op=="all" else " or ").join(words) if not words.is_empty() else "No entry restrictions"
 if op=="not":return "Excludes "+requirement_text(node.arg,source)
 var category: String={"class_level":"classes","skill":"skills","feat":"feats","feature":"features","resource":"resources"}.get(op,"")
 var label: String=str(source.definition(category,str(node.get("id",""))).get("name",str(node.get("id",op)).replace("_"," ").replace("-"," ").capitalize())) if not category.is_empty() else str(node.get("id",op)).replace("_"," ").capitalize()
 if op=="bab":label="BAB"
 if op=="level":label="Total level"
 if op=="class_level":label+=" class level"
 if op=="casting":label+=" casting level"
 if op=="skill":label+=" ranks"
 if op=="spell_tier":label="Permanent "+label.to_lower()+" spell tier"
 return label+(" ≥ "+str(int(node.min)) if node.has("min") else "")
static func history_choices(step: Dictionary,source: RulesRegistry,class_level: int) -> Array[String]:
 var names: Array[String]=[]
 for group in groups(source,step.class_id,class_level):
  for option in group.options:
   if step.get("specialisations",{}).get(group.id)==option.id:names.append(group.name+": "+option.name)
 for id in step.get("bonus_feats",[]):names.append("Bonus feat: "+str(source.definition("feats",id).name))
 return names
