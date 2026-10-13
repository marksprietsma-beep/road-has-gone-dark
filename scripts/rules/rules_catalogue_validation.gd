class_name RulesCatalogueValidation
extends RefCounted
## Extra authoring gates for the expanded pack, independent of playable coverage.
static func validate(tables: Dictionary,errors: Array) -> void:
 for category in ["classes","feats","abilities"]:
  for row in tables[category].values():_requirements(row.requirements,tables,category+"."+row.id,errors)
 var visiting: Dictionary={};var done: Dictionary={}
 for id in tables.feats:_feat_cycle(id,tables,visiting,done,errors)
 for row in tables.abilities.values():
  if not row.tags.has("spell"):continue
  if not row.has_all(["casting_class","spell_tier"]):errors.append(RulesJson.issue("catalogue.spell",row.id,"Spells need an actual class and tier"));continue
  var slots := 0
  for id in row.cost.resources:
   var pool: Dictionary=tables.resources[id]
   if pool.has("slot_class"):
    slots+=1
    if pool.slot_class!=row.casting_class or pool.spell_tier!=row.spell_tier:errors.append(RulesJson.issue("catalogue.spell_resource",row.id,"Spell must spend the matching class/tier resource"))
  if slots!=1:errors.append(RulesJson.issue("catalogue.spell_resource",row.id,"One actual tier resource required"))
 for row in tables.ancestries.values():
  if not row.has("visual_profile"):continue
  var value: Variant=row.visual_profile
  if not value is Dictionary or value.size()!=8 or not value.has_all(["body_plan","size","head","torso","arms","legs","optional_features","art_status"]):errors.append(RulesJson.issue("catalogue.body",row.id,"Explicit body composition and honest art status required"));continue
  if value.body_plan!=row.body_plan or value.size!=row.size or not RulesJson.integer(value.arms,0,8) or not RulesJson.integer(value.legs,0,8) or not value.head is String or not value.torso is String or not value.optional_features is Array or not value.optional_features.all(func(id: Variant):return id is String) or value.art_status!="neutral_humanoid_fallback":errors.append(RulesJson.issue("catalogue.body",row.id,"Inconsistent inherited anatomy or unsupported art claim"))
 for row in tables.classes.values():
  if row.has("attribute_priority") and (not row.attribute_priority is Array or row.attribute_priority.size()!=6 or row.attribute_priority.size()!=RulesRegistry._unique_count(row.attribute_priority) or not row.attribute_priority.all(func(id: Variant):return id in RulesExpressions.ATTRIBUTES)):errors.append(RulesJson.issue("catalogue.attributes",row.id,"Six unique recommended attributes required"))
static func _requirements(node: Dictionary,tables: Dictionary,path: String,errors: Array) -> void:
 if node.op in ["all","any"]:
  for child in node.args:_requirements(child,tables,path,errors)
 elif node.op=="not":_requirements(node.arg,tables,path,errors)
 elif node.has("min"):
  var limit:=20
  if node.op=="class_level":limit=int(tables.classes[node.id].max_level)
  elif node.op=="attribute":limit=26
  elif node.op in ["resource","save"]:return
  if int(node.min)>limit:errors.append(RulesJson.issue("catalogue.unreachable",path,"Prerequisite exceeds supported permanent progression",{"required":node.min,"maximum":limit}))
static func _feat_refs(node: Dictionary) -> Array:
 if node.op=="feat":return [node.id]
 var found: Array=[]
 if node.op in ["all","any"]:
  for child in node.args:found.append_array(_feat_refs(child))
 return found
static func _feat_cycle(id: String,tables: Dictionary,visiting: Dictionary,done: Dictionary,errors: Array) -> void:
 if done.has(id):return
 if visiting.has(id):errors.append(RulesJson.issue("catalogue.feat_cycle",id,"Cyclic feat requirements cannot be earned"));return
 visiting[id]=true
 for child in _feat_refs(tables.feats[id].requirements):_feat_cycle(child,tables,visiting,done,errors)
 visiting.erase(id);done[id]=true
