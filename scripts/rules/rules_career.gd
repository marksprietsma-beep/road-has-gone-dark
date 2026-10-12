class_name RulesCareer
extends RefCounted
## Ordered, durable player choices. No runtime grants qualify historical entry.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id")in ["trhgd-character-v7","trhgd-character-v8","trhgd-character-v9"]
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
static func validate_choices(source: RulesRegistry,cls: String,level: int,chosen: Variant,context: Dictionary) -> Array:
 if not chosen is Dictionary:return [RulesJson.issue("career.schema",cls,"Select explicit class specialisations")]
 var scheduled := groups(source,cls,level);var errors: Array=[]
 if chosen.size()!=scheduled.size():errors.append(RulesJson.issue("career.count",cls,"Select exactly the scheduled class options"))
 for group in scheduled:
  var matches: Array=group.options.filter(func(option: Dictionary):return option.id==chosen.get(group.id))
  if matches.size()!=1:errors.append(RulesJson.issue("career.option",group.id,"Choose one valid specialisation"));continue
  errors.append_array(RulesExpressions.evaluate_requirements(matches[0].requirements,context).get("errors",[]))
 return errors
static func casting_levels(record: Dictionary,classes: Dictionary,source: RulesRegistry) -> Dictionary:
 var levels := classes.duplicate()
 for option in selections(record,classes,source):
  if option.has("advance_casting"):
   var target: String=option.advance_casting
   levels[target]=int(levels.get(target,0))+int(classes.get(option.progression_class,0))
 return levels
static func validate_definition(row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if row.has("class_kind") and row.class_kind not in ["base","prestige"]:errors.append(RulesJson.issue("career.kind",row.id,"Known base/prestige classification required"))
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
    if field not in ["id","name","description","features","requirements","advance_casting","progression_class"]:errors.append(RulesJson.issue("career.field",group.id,"Unknown option field"))
   for id in option.features:RulesRegistry._reference(tables,"features",id,group.id,errors)
   RulesRegistry._requirement(option.requirements,tables,group.id,errors)
   if option.has("advance_casting"):
    RulesRegistry._reference(tables,"classes",option.advance_casting,group.id,errors)
    if option.get("progression_class")!=row.id or tables.classes.get(option.advance_casting,{}).get("spell_mode","").is_empty():errors.append(RulesJson.issue("career.casting",group.id,"Casting must advance an actual caster from this prestige track"))

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
 return label+(" ≥ "+str(int(node.min)) if node.has("min") else "")
static func history_choices(step: Dictionary,source: RulesRegistry,class_level: int) -> Array[String]:
 var names: Array[String]=[]
 for group in groups(source,step.class_id,class_level):
  for option in group.options:
   if step.get("specialisations",{}).get(group.id)==option.id:names.append(group.name+": "+option.name)
 for id in step.get("bonus_feats",[]):names.append("Bonus feat: "+str(source.definition("feats",id).name))
 return names
