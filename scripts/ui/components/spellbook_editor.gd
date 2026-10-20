class_name SpellbookEditor
extends VBoxContainer
signal changed
var source: RulesRegistry
var record := {}
var controls := {}
var repertoire_search: LineEdit
var selection_summaries := {}
var preparation_summaries := {}
var slot_capacities := {}
func setup(value: Dictionary) -> void:
 record=value.duplicate(true);source=RulesRecords.registry(value);controls={};selection_summaries={};preparation_summaries={}
 for child in get_children():remove_child(child);child.queue_free()
 var result := RulesCharacter.new(source).derive_character(record)
 if not result.ok:return
 slot_capacities=result.snapshot.resource_capacities.duplicate(true)
 repertoire_search=LineEdit.new();repertoire_search.placeholder_text="Find spell or tier (e.g. tier 6)";add_child(repertoire_search)
 repertoire_search.text_changed.connect(func(query: String):
  for child in get_children():
   if child.has_meta("spell_search"):child.visible=query.strip_edges().is_empty() or query.to_lower() in str(child.get_meta("spell_search")))
 for cls in result.snapshot.class_levels:
  var definition := source.definition('classes',cls)
  if definition.get('spell_mode','').is_empty():continue
  var level: int=int(result.snapshot.get("casting_levels",result.snapshot.class_levels)[cls])
  add_child(GameUI.label(definition.name+' · '+str(definition.spell_mode).capitalize(),GameUI.SECTION))
  add_child(GameUI.label('Select up to %d spells. %s Casting uses %s; each spell below shows its actual permanent requirement.'%[RulesCoreContent.selection_limit(cls,level,source),'Retrieved spirit spells may be exchanged once after an eligible home-return rest.' if RulesWaveFive.retrieval_class(cls,source) else 'Known spontaneous spells are retained; add new choices as progression permits.' if definition.spell_mode=='spontaneous' else 'Prepared selections may change at home. Current spell slots are preserved.',definition.casting_attribute],GameUI.META))
  var retrieval := RulesWaveFive.retrieval_class(cls,source)
  var permit: int=int(record.runtime.resources.get(definition.get("retrieval_resource",""),0))
  if retrieval:add_child(GameUI.label("Spirit retrieval · %d change available. Return from an expedition and rest to refresh one change; selecting spells does not restore slots."%permit,GameUI.META))
  var summary := GameUI.label("",GameUI.META);selection_summaries[cls]=summary;add_child(summary)
  if definition.spell_mode=="prepared":
   var tiers := GameUI.label("",GameUI.META);preparation_summaries[cls]=tiers;add_child(tiers)
   tiers.tooltip_text="Staged copies share each tier's daily capacity. Rules reject excess copies. Saving preparations at home refills selected copy allocations, while current shared slots stay spent. Eligible rest refills the daily slots."
  var ordered: Array=result.snapshot.abilities.duplicate()
  ordered.sort_custom(func(a: String,b: String):
   var left := source.definition("abilities",a);var right := source.definition("abilities",b)
   return int(left.get("spell_tier",0))<int(right.get("spell_tier",0)) if left.get("spell_tier",0)!=right.get("spell_tier",0) else str(left.name)<str(right.name))
  for id in ordered:
   var ability := source.definition('abilities',id)
   if ability.get('casting_class')!=cls or not ability.tags.has('spell') or ability.has('channel_spell'):continue
   if ability.tags.has('prepared'):
    var row := HBoxContainer.new();row.set_meta("spell_search",(ability.name+" tier "+str(ability.spell_tier)+" "+ability.get("description","")).to_lower());add_child(row)
    var caption := GameUI.label(ability.name+' · '+RulesCareer.requirement_text(ability.requirements,source)+' · '+', '.join(ability.tags.filter(func(tag: String):return tag.begins_with('tier_'))).replace('_',' '),GameUI.META);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(caption)
    var spin := SpinBox.new();spin.min_value=0;spin.max_value=30;spin.step=1;spin.custom_minimum_size.x=88;spin.tooltip_text=ability.get('description',ability.name);row.add_child(spin)
    if source.rules_ref().pack_id in ["trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23"] and not RulesCoreContent.spell_eligible(result.snapshot,ability):spin.editable=false;spin.tooltip_text+="\nUnavailable: "+RulesCareer.requirement_text(ability.requirements,source)
    spin.value=int(record.choices.spell_preparations.get(id,0));controls[id]=spin;spin.value_changed.connect(func(_value: float):update_selection_summaries();changed.emit())
   else:
    var control := CheckBox.new();control.text=ability.name+' · '+RulesCareer.requirement_text(ability.requirements,source)+' · '+', '.join(ability.tags.filter(func(tag: String):return tag.begins_with('tier_'))).replace('_',' ')
    control.tooltip_text=ability.get('description',ability.name);control.button_pressed=record.choices.prepared_abilities.has(id)
    control.disabled=permit<1 if retrieval else definition.spell_mode=='spontaneous' and control.button_pressed
    if source.rules_ref().pack_id in ["trhgd-character-v17","trhgd-character-v18","trhgd-character-v19","trhgd-character-v20","trhgd-character-v21","trhgd-character-v22","trhgd-character-v23"] and not RulesCoreContent.spell_eligible(result.snapshot,ability):control.disabled=true;control.tooltip_text+="\nUnavailable: "+RulesCareer.requirement_text(ability.requirements,source)
    control.set_meta("spell_search",(ability.name+" tier "+str(ability.spell_tier)+" "+ability.get("description","")).to_lower());add_child(control);controls[id]=control;control.toggled.connect(func(_on: bool):update_selection_summaries();changed.emit())

 update_selection_summaries()
func update_selection_summaries() -> void:
 for cls in selection_summaries:
  var count: int=selection().filter(func(id: String):return source.definition("abilities",id).get("casting_class")==cls).size()
  selection_summaries[cls].text="Proposed selection: "+str(count)+" · commit saves choices; current spell slots are preserved."
 for cls in preparation_summaries:
  var lines: Array[String]=[]
  for tier in range(1,10):
   var pool: String=cls+"-slots-"+str(tier)
   if not slot_capacities.has(pool):continue
   var copies := 0
   for id in controls:
    var ability := source.definition("abilities",id)
    if controls[id] is SpinBox and ability.get("casting_class")==cls and int(ability.get("spell_tier",0))==tier:copies+=int(controls[id].value)
   var maximum: int=int(slot_capacities[pool])
   lines.append("Tier%d: copies%d/%d%s · slots%d/%d"%[tier,copies,maximum," OVER" if copies>maximum else"",int(record.runtime.resources.get(pool,0)),maximum])
  preparation_summaries[cls].text="Staged copies / daily capacity; current slots stay unchanged:\n"+"; ".join(lines)

func selection() -> Array:
 return controls.keys().filter(func(id: String):return int(controls[id].value)>0 if controls[id] is SpinBox else controls[id].button_pressed)
func preparations() -> Dictionary:
 var copies := {}
 for id in controls:
  if controls[id] is SpinBox and int(controls[id].value)>0:copies[id]=int(controls[id].value)
 return copies
