class_name SpellbookEditor
extends VBoxContainer
signal changed
var source: RulesRegistry
var record := {}
var controls := {}
func setup(value: Dictionary) -> void:
 record=value.duplicate(true);source=RulesRecords.registry(value);controls={}
 for child in get_children():remove_child(child);child.queue_free()
 var result := RulesCharacter.new(source).derive_character(record)
 if not result.ok:return
 for cls in result.snapshot.class_levels:
  var definition := source.definition('classes',cls)
  if definition.get('spell_mode','').is_empty():continue
  var level: int=int(result.snapshot.get("casting_levels",result.snapshot.class_levels)[cls])
  add_child(GameUI.label(definition.name+' · '+str(definition.spell_mode).capitalize(),GameUI.SECTION))
  add_child(GameUI.label('Select up to %d spells. %s Casting uses %s; required score is 10 + spell tier.'%[RulesCoreContent.selection_limit(cls,level,source),'Known spontaneous spells are retained; add new choices as progression permits.' if definition.spell_mode=='spontaneous' else 'Prepared selections may change at home. Current spell slots are preserved.',definition.casting_attribute],GameUI.META))
  for id in result.snapshot.abilities:
   var ability := source.definition('abilities',id)
   if ability.get('casting_class')!=cls or not ability.tags.has('spell'):continue
   if ability.tags.has('prepared'):
    var row := HBoxContainer.new();add_child(row)
    var caption := GameUI.label(ability.name+' · '+', '.join(ability.tags.filter(func(tag: String):return tag.begins_with('tier_'))).replace('_',' '),GameUI.META);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(caption)
    var spin := SpinBox.new();spin.min_value=0;spin.max_value=30;spin.step=1;spin.custom_minimum_size.x=88;spin.tooltip_text=ability.get('description',ability.name);row.add_child(spin)
    spin.value=int(record.choices.spell_preparations.get(id,0));controls[id]=spin;spin.value_changed.connect(func(_value: float):changed.emit())
   else:
    var control := CheckBox.new();control.text=ability.name+' · '+', '.join(ability.tags.filter(func(tag: String):return tag.begins_with('tier_'))).replace('_',' ')
    control.tooltip_text=ability.get('description',ability.name);control.button_pressed=record.choices.prepared_abilities.has(id)
    control.disabled=definition.spell_mode=='spontaneous' and control.button_pressed
    add_child(control);controls[id]=control;control.toggled.connect(func(_on: bool):changed.emit())

func selection() -> Array:
 return controls.keys().filter(func(id: String):return int(controls[id].value)>0 if controls[id] is SpinBox else controls[id].button_pressed)
func preparations() -> Dictionary:
 var copies := {}
 for id in controls:
  if controls[id] is SpinBox and int(controls[id].value)>0:copies[id]=int(controls[id].value)
 return copies
