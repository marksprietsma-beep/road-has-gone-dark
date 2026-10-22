class_name RulesCompleteness
extends RefCounted
## v16 onward: permanent competence and contextual uses of existing character skills.
## This projects existing authority; it never grants XP, casts spells or writes saves.
static func enabled(source: RulesRegistry) -> bool:
 return source.rules_ref().get("pack_id")in ["trhgd-character-v16","trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25"]

static func has_spell_gate(node: Dictionary) -> bool:
 if node.op=="spell_tier":return true
 if node.has("arg") and has_spell_gate(node.arg):return true
 return node.get("args",[]).any(func(child: Dictionary):return has_spell_gate(child))

static func entry_requirements(node: Dictionary,permanent: Dictionary,record: Dictionary,source: RulesRegistry) -> Dictionary:
 if not enabled(source) or not has_spell_gate(node):return RulesExpressions.evaluate_requirements(node,permanent)
 # Compute repertoire only where a permanent entry requirement asks for it,
 # rather than for every historical level of every ordinary skill preview.
 var projected := permanent.duplicate()
 projected.spell_tiers=spell_tiers(record,permanent,source)
 return RulesExpressions.evaluate_requirements(node,projected)

static func spell_tiers(record: Dictionary,permanent: Dictionary,source: RulesRegistry) -> Dictionary:
 var tiers := {"arcane":0,"divine":0}
 for id in permanent.abilities:
  var spell := source.definition("abilities",str(id))
  if not spell.get("tags",[]).has("spell") or spell.has("channel_spell"):continue
  var cls := source.definition("classes",str(spell.get("casting_class","")))
  var tradition: String=str(cls.get("casting_tradition",""))
  if not tiers.has(tradition):continue
  # Known spells are permanent spontaneous choices. Prepared/retrieved casters
  # may choose another owned legal spell at home; depleted copies are not entry gates.
  if cls.spell_mode=="spontaneous" and not RulesWaveFive.retrieval_class(cls.id,source) and not record.choices.prepared_abilities.has(id):continue
  if not RulesExpressions.evaluate_requirements(spell.requirements,permanent).ok:continue
  var has_slot := false;var sufficient := true
  for pool in spell.cost.resources:
   if source.definition("resources",pool).has("prepared_ability"):continue
   if source.definition("resources",pool).has("slot_class"):has_slot=true
   if int(permanent.capacities.get(pool,0))<int(spell.cost.resources[pool]):sufficient=false
  if has_slot and sufficient:tiers[tradition]=maxi(int(tiers[tradition]),int(spell.get("spell_tier",0)))
 return tiers

static func validate_approaches(value: Variant,tables: Dictionary,errors: Array) -> void:
 if not value is Array or value.size()>32:
  errors.append(RulesJson.issue("skill.approaches","rules","Bounded contextual skill approaches required"));return
 var seen := {}
 for row in value:
  if not row is Dictionary:
   errors.append(RulesJson.issue("skill.approach","rules","Typed approach required"));continue
  RulesRegistry._known_fields(row,["skill","activities","min_ranks","label","information","event","provisions","gain","reveal","dc_adjustment","outcome"],"skill.approach",errors)
  RulesRegistry._reference(tables,"skills",row.get("skill"),"skill.approach",errors)
  if not row.get("activities") is Array or row.activities.is_empty() or row.activities.size()!=RulesRegistry._unique_count(row.activities):errors.append(RulesJson.issue("skill.activities","rules","Unique authored activity IDs required"));continue
  for id in row.activities:
   if id not in ["lost_supplies","abandoned_shelter","old_work","unusual_traces","camp_access","salvage_dispute","road_passage"] or seen.has(str(id)+":"+str(row.get("skill"))):errors.append(RulesJson.issue("skill.activity",str(id),"Known, nonduplicate activity/skill pair required"))
   seen[str(id)+":"+str(row.get("skill"))]=true
  for field in ["label","information"]:
   if not row.get(field) is String or row[field].is_empty() or row[field].length()>300:errors.append(RulesJson.issue("skill.text",field,"Bounded explanation required"))
  for field in ["min_ranks","provisions","gain","dc_adjustment"]:
   if not RulesJson.integer(row.get(field),0,10):errors.append(RulesJson.issue("skill.value",field,"Bounded nonnegative value required"))
  if row.get("event") not in ["recover","quick","inspect","negotiate"] or row.get("outcome") not in ["recovered","investigated","peaceful_access"] or not row.get("reveal") is bool:errors.append(RulesJson.issue("skill.result","rules","Existing activity event/outcome required"))

static func approaches(source: RulesRegistry,activity: String) -> Array:
 if not enabled(source):return []
 return source.rule("skill_approaches").filter(func(row: Dictionary):return row.activities.has(activity))

static func skill_usage(source: RulesRegistry,skill: String) -> String:
 if not enabled(source):return ""
 var existing := {"craft":"Recovery checks on existing opportunities.","survival":"Recovery checks on existing opportunities.","perception":"Investigation checks on existing opportunities.","arcana":"Investigation checks on existing opportunities.","religion":"Investigation checks on existing opportunities.","persuasion":"Negotiated access checks on existing opportunities.","insight":"Negotiated access checks on existing opportunities.","nature":"Natural Scholar: each five ranks adds one training spell DC when that feat is owned.","performance":"Bard performance capacity gains one use per five ranks."}
 if existing.has(skill):return existing[skill]
 var labels: Array=[]
 for row in source.rule("skill_approaches"):
  if row.skill==skill:labels.append(str(row.label)+" · trained, contextual adventure check")
 return "; ".join(labels)
