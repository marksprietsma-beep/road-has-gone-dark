class_name RulesCoreContent
extends RefCounted
## Engine 3 content capabilities. Legacy packs never enter this adapter.
static func validate_definition(category: String,row: Dictionary,tables: Dictionary,errors: Array) -> void:
 if row.get("tags") is Array and row.tags.size()!=RulesRegistry._unique_count(row.tags):errors.append(RulesJson.issue("core.tags_duplicate",row.id,"Duplicate content tags are invalid"))
 if category=="classes":
  RulesCareer.validate_definition(row,tables,errors)
  if row.has("known_spell_limits"):
   var limits: Variant=row.known_spell_limits
   if row.get("spell_mode")!="spontaneous" or not limits is Array or limits.size()!=int(row.max_level)+1 or not limits.all(func(n: Variant):return RulesJson.integer(n,0,40)) or limits[0]!=0:
    errors.append(RulesJson.issue("core.known_limits",row.id,"Spontaneous repertoire needs a bounded allowance for every class level"));return
   for i in range(1,limits.size()):
    if limits[i]<limits[i-1]:errors.append(RulesJson.issue("core.known_limits",row.id,"Learned repertoire cannot shrink"))
  if not row.get("bonus_feat_levels") is Array or not row.bonus_feat_levels.all(func(n: Variant):return RulesJson.integer(n,1,int(row.max_level))) or not row.get("description") is String or not RulesJson.integer(row.get("hit_die"),4,12) or not row.get("class_skills") is Array or not row.get("proficiencies") is Array or not row.get("recommended_equipment") is Array or row.get("spell_mode") not in ["","prepared","spontaneous"] or row.get("casting_attribute") not in ["","STR","DEX","CON","INT","WIS","CHA"]:errors.append(RulesJson.issue("core.class",row.id,"Typed class skills, proficiencies and casting required"));return
  for id in row.class_skills:RulesRegistry._reference(tables,"skills",id,row.id,errors)
  for id in row.recommended_equipment:RulesRegistry._reference(tables,"equipment",id,row.id,errors)
  for value in row.proficiencies:
   if value not in ["simple","martial","light","medium","heavy","shield"]:errors.append(RulesJson.issue("core.proficiency",row.id,"Unknown proficiency"))
 elif category=="ancestries":
  if not row.get("name") is String or not row.get("description") is String or not row.get("attribute_adjustments") is Dictionary or not row.get("skill_bonuses") is Dictionary or row.get("size") not in ["small","medium","large"] or not row.get("body_plan") is String:errors.append(RulesJson.issue("core.ancestry",row.id,"Typed inherited traits required"));return
  for id in row.attribute_adjustments:
   if id not in RulesExpressions.ATTRIBUTES or not RulesJson.integer(row.attribute_adjustments[id],-4,4):errors.append(RulesJson.issue("core.attribute",row.id,"Invalid inherited attribute adjustment"))
  for id in row.skill_bonuses:
   if not tables.skills.has(id) or not RulesJson.integer(row.skill_bonuses[id],-4,4):errors.append(RulesJson.issue("core.skill",row.id,"Invalid inherited skill bonus"))
 elif category in ["resources","abilities"]:
  if row.has("attack_weapon"):
   RulesRegistry._reference(tables,"equipment",row.attack_weapon,row.id,errors)
   if tables.equipment.get(row.attack_weapon,{}).get("kind")!="weapon":errors.append(RulesJson.issue("core.natural_weapon",row.id,"Natural strike requires an actual weapon definition"))
  if row.has("prepared_ability"):RulesRegistry._reference(tables,"abilities",row.prepared_ability,row.id,errors)
  for field in ["slot_class","casting_class"]:
   if row.has(field):RulesRegistry._reference(tables,"classes",row[field],row.id,errors)
  if row.has("spell_tier") and not RulesJson.integer(row.spell_tier,1,9):errors.append(RulesJson.issue("core.spell_tier",row.id,"Bounded tier required"))
 elif category=="equipment" and row.get("proficiency") not in ["","simple","martial","light","medium","heavy","shield"]:errors.append(RulesJson.issue("core.equipment",row.id,"Typed proficiency required"))
static func initial_ancestry(people: String) -> String:
 if people in ["human","dwarf","elf","halfling","gnome","half-elf","half-orc"]:return "heritage-"+people
 return "heritage-"+{"human":"human","dwarf":"dwarf","wood-elf":"elf","woodland-elf":"elf","hearth-elf":"elf","smallfolk":"halfling","orc":"half-orc"}.get(people,"human")
static func proficiencies(classes: Dictionary,source: RulesRegistry) -> Array:
 var values: Array=[]
 for id in classes:
  for value in source.definition("classes",id).proficiencies:
   if not values.has(value):values.append(value)
 values.sort();return values
static func equipment_legal(item: Dictionary,classes: Dictionary,source: RulesRegistry) -> bool:
 if classes.has("monk") and item.kind in ["armor","shield"]:return false
 return str(item.proficiency).is_empty() or proficiencies(classes,source).has(item.proficiency)
static func selection_limit(cls: String,level: int,source: RulesRegistry) -> int:
 var definition := source.definition("classes",cls)
 if definition.has("known_spell_limits"):
  var limits: Array=definition.known_spell_limits
  return int(limits[clampi(level,0,limits.size()-1)])
 return 2+level if source.definition("classes",cls).spell_mode=="prepared" else 1+int(ceil(float(level)/2.0))
static func selection_errors(record: Dictionary,context: Dictionary,source: RulesRegistry) -> Array:
 var counts := {};var errors: Array=[]
 if RulesWaveFive.enabled(source):
  for id in record.choices.prepared_abilities:
   if source.definition("abilities",id).has("channel_spell"):errors.append(RulesJson.issue("channel.known",id,"Select the original spell; its channel action is granted automatically"))
 for id in record.choices.prepared_abilities:
  var spell := source.definition("abilities",id)
  if not spell.tags.has("spell"):continue
  if source.rules_ref().pack_id in ["trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29"] and not RulesExpressions.evaluate_requirements(spell.requirements,context).ok:errors.append(RulesJson.issue("spell.requirements",id,"Permanent spell requirements are not met"))
  var cls: String=str(spell.get("casting_class",""));counts[cls]=int(counts.get(cls,0))+1
 for cls in counts:
  if not context.classes.has(cls) or int(counts[cls])>selection_limit(cls,int(context.get("casting_levels",context.classes).get(cls,0)),source):errors.append(RulesJson.issue("spell.limit",cls,"Too many prepared or known spells"))
 var budgets := {};var spent := {}
 for id in context.capacities:
  if source.definition("resources",str(id)).has("slot_class"):budgets[id]=int(context.capacities[id])
 for id in record.choices.spell_preparations:
  var count: Variant=record.choices.spell_preparations[id]
  var ability := source.definition("abilities",str(id))
  if not RulesJson.integer(count,1,100) or ability.is_empty() or not ability.tags.has("prepared") or not record.choices.prepared_abilities.has(id):errors.append(RulesJson.issue("spell.preparation",str(id),"A selected prepared spell needs a positive integer copy count"));continue
  for pool in ability.cost.resources:
   if source.definition("resources",str(pool)).has("slot_class"):spent[pool]=int(spent.get(pool,0))+int(count)
 for pool in spent:
  if not budgets.has(pool) or int(spent[pool])>int(budgets.get(pool,0)):errors.append(RulesJson.issue("spell.preparation_budget",pool,"Prepared copies exceed this tier's slot capacity",{"expected":int(budgets.get(pool,0)),"current":int(spent[pool])}))
 for id in record.choices.prepared_abilities:
  if source.definition("abilities",str(id)).tags.has("prepared") and not record.choices.spell_preparations.has(id):errors.append(RulesJson.issue("spell.preparation_missing",str(id),"Choose how many copies to prepare"))
 return errors
static func starting_preparations(snapshot: Dictionary,source: RulesRegistry) -> Dictionary:
 var proposed := _legacy_starting_preparations(snapshot,source)
 if not RulesPsychic.enabled(source):return proposed
 # Reserve one legal suggestion per unlocked tier before adding variety.
 # Distinct-spell limits and total tier slots are independent ceilings.
 var copies := {};var counts := {};var tiers := {}
 for id in proposed:
  var ability := source.definition("abilities",id)
  if int(proposed[id])<=0 or not ability.tags.has("prepared"):continue
  for pool in ability.cost.resources:
   if not source.definition("resources",pool).has("slot_class"):continue
   if not tiers.has(pool):tiers[pool]=[]
   tiers[pool].append(id)
 var pools: Array=tiers.keys();pools.sort()
 for pass_index in [0,1]:
  for pool in pools:
   var cls: String=source.definition("resources",pool).slot_class
   var limit := selection_limit(cls,int(snapshot.get("casting_levels",snapshot.class_levels).get(cls,0)),source)
   for id in tiers[pool]:
    if copies.has(id):continue
    if int(counts.get(cls,0))>=limit:break
    copies[id]=int(proposed[id]);counts[cls]=int(counts.get(cls,0))+1
    if pass_index==0:break
 for pool in pools:
  var selected: Array=tiers[pool].filter(func(id: String):return copies.has(id))
  if selected.is_empty():continue
  var spent := 0
  for id in selected:spent+=int(copies[id])
  var remaining: int=int(snapshot.resource_capacities[pool])-spent
  if remaining>0:copies[selected[0]]+=remaining
 return copies
static func _legacy_starting_preparations(snapshot: Dictionary,source: RulesRegistry) -> Dictionary:
 var copies := {}
 for pool in snapshot.resource_capacities:
  if not source.definition("resources",str(pool)).has("slot_class"):continue
  var cls: String=str(source.definition("resources",str(pool)).slot_class)
  if source.definition("classes",cls).spell_mode!="prepared":continue
  var candidates: Array=snapshot.abilities.filter(func(id: String):return source.definition("abilities",id).cost.resources.has(pool))
  if source.rules_ref().pack_id in ["trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29"]:candidates=candidates.filter(func(id: String):return spell_eligible(snapshot,source.definition("abilities",id)))
  var remaining: int=int(snapshot.resource_capacities[pool])
  var offensive: Array=candidates.filter(func(id: String):return source.definition("abilities",id).effects.any(func(effect: Dictionary):return effect.op=="damage"))
  var wards: Array=candidates.filter(func(id: String):return source.definition("abilities",id).targeting.kind=="ally" and source.definition("abilities",id).effects.any(func(effect: Dictionary):return effect.op=="apply_status"))
  if cls=="wizard" and not offensive.is_empty():
   if remaining>1 and not wards.is_empty():copies[wards[0]]=1;remaining-=1
   copies[offensive[0]]=remaining;continue
  for id in candidates:
   if remaining<=0:break
   copies[id]=1;remaining-=1
  if remaining>0 and not candidates.is_empty():copies[candidates[0]]=int(copies.get(candidates[0],0))+remaining
 return copies
static func refill_prepared(record: Dictionary,source: RulesRegistry) -> void:
 # Only creation/home preparations call this. Shared tier slots remain the total-cast ceiling.
 var context: Dictionary=RulesCharacter.new(source)._replay(record).get("context",{})
 for id in context.get("capacities",{}):
  if source.definition("resources",id).has("prepared_ability"):record.runtime.resources[id]=int(context.capacities[id])
static func suggested_spells(snapshot: Dictionary,source: RulesRegistry) -> Array:
 var selected: Array=[]
 for cls in snapshot.class_levels:
  var limit := selection_limit(cls,int(snapshot.get("casting_levels",snapshot.class_levels).get(cls,0)),source)
  for id in snapshot.abilities:
   if RulesCompleteness.enabled(source) and source.definition("abilities",id).has("channel_spell"):continue
   if source.rules_ref().pack_id in ["trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23","trhgd-character-v24","trhgd-character-v25","trhgd-character-v26","trhgd-character-v27","trhgd-character-v28","trhgd-character-v29"] and not spell_eligible(snapshot,source.definition("abilities",id)):continue
   if source.definition("abilities",id).get("casting_class")==cls and source.definition("abilities",id).tags.has("spell") and limit>0:selected.append(id);limit-=1
 return selected
static func ancestry_rows(source: RulesRegistry) -> Array:
 var rows: Array=[];var seen := {}
 for id in source.ids("ancestries"):
  var row := source.definition("ancestries",id)
  if not seen.has(row.people_id):rows.append({"id":row.people_id,"name":str(row.name).trim_suffix(" Standard"),"description":row.description});seen[row.people_id]=true
 return rows
static func ancestry_description(row: Dictionary) -> String:
 # Keep original pins intact while accurately describing the current battlefield.
 var text: String=str(row.get("description",""))
 var pattern:=RegEx.new();pattern.compile("(?i)(darkvision|low-light vision)(; | and |;| )?")
 var unavailable:=pattern.search(text)!=null
 if unavailable:
  text=pattern.sub(text,"",true).strip_edges()
  text+=" Inherited vision is recorded; darkness/low-light battlefield rules are not implemented."
 return text

static func spell_eligible(snapshot: Dictionary,spell: Dictionary) -> bool:
 return RulesExpressions.evaluate_requirements(spell.requirements,{"attributes":snapshot.attributes,"classes":snapshot.class_levels,"stats":snapshot.stats,"features":snapshot.features,"feats":snapshot.feats,"level":snapshot.level,"tags":snapshot.tags,"capacities":snapshot.resource_capacities}).ok
