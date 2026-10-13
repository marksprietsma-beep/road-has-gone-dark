class_name BuildEditor
extends VBoxContainer
## Shared creation/advancement controls; every preview goes through GAME-32.
signal changed
var source := RulesRecords.registry()
var kernel := CharacterBuilderRecords.kernel()
var base := {}
var advance := false
var updating := false
var attribute_pickers := {}
var skill_pickers := {}
var equipment_pickers := {}
var preparation_pickers := {}
var class_filter: LineEdit
var feat_filter: LineEdit
var class_detail: Label
var class_picker: OptionButton
var feat_picker: OptionButton
var increase_picker: OptionButton
var budget: Label
var explanation: Label
var preview := {}
var ancestry_ref := ""
var background_ref := "hometown-background"
var attributes := {}
var allocation := {}
var class_id := ""
var sections: TabContainer
var spell_section: VBoxContainer
var class_help: Label
var feat_detail: Label
var progression_detail: Label
var feat_id := ""
var attribute_increase := ""
var specialisations := {}
var bonus_feats: Array=[]
var career_section: VBoxContainer
var career_pickers := {}
var bonus_picker: OptionButton
var bonus_column: VBoxContainer

func picker(parent: Control,title: String,rows: Array) -> OptionButton:
 var row := HBoxContainer.new();parent.add_child(row)
 var caption := GameUI.label(title,GameUI.META);caption.custom_minimum_size.x=88;row.add_child(caption)
 var control := OptionButton.new();control.size_flags_horizontal=Control.SIZE_EXPAND_FILL;control.clip_text=true;row.add_child(control)
 for item in rows:
  control.add_item(str(item.get("name",item.id)));control.set_item_metadata(control.item_count-1,item.id)
 return control
func id_of(control: OptionButton) -> String:
 return str(control.get_item_metadata(control.selected)) if control.selected>=0 else ""
func select_id(control: OptionButton,id: String) -> void:
 for i in control.item_count:
  if str(control.get_item_metadata(i))==id:control.select(i);return
func setup(record_value: Dictionary,is_advance := false) -> void:
 source=RulesRecords.registry(record_value);kernel=CharacterBuilderRecords.kernel(record_value)
 base=record_value.duplicate(true);advance=is_advance
 class_id=str(base.advancement_history.back().class_id)
 ancestry_ref=base.ancestry_ref;background_ref=base.background_ref;attributes=base.base_attributes.duplicate(true)
 for child in get_children():remove_child(child);child.queue_free()
 attribute_pickers={};skill_pickers={};equipment_pickers={};preparation_pickers={};sections=null
 updating=true
 class_filter=LineEdit.new();class_filter.placeholder_text="Search classes · selected choice stays visible";add_child(class_filter)
 class_picker=picker(self,"Class",source.ids("classes").filter(func(id: String):return source.definition("classes",id).get("class_kind")!="companion").map(func(id: String):return {"id":id,"name":source.definition("classes",id).name}))
 class_detail=GameUI.label("",GameUI.META);add_child(class_detail)
 class_filter.text_changed.connect(func(_query: String):
  if updating:return
  class_picker.clear()
  for id in source.ids("classes"):
   var row := source.definition("classes",id)
   if row.get("class_kind")=="companion":continue
   if id==class_id or class_filter.text.to_lower() in str(row.name).to_lower():class_picker.add_item(row.name);class_picker.set_item_metadata(class_picker.item_count-1,id)
  select_id(class_picker,class_id);refresh_preview())
 class_picker.item_selected.connect(func(_index: int):
  if updating:return
  set_class(id_of(class_picker)))
 var attribute_section := form_section("Attributes")
 if not advance:
  attribute_section.add_child(GameUI.label("Allocate the standard array",GameUI.SECTION))
  attribute_section.add_child(GameUI.label("Base scores use each value once. Racial adjustments appear separately on the sheet; choosing a score swaps its allocation.",GameUI.META))
  for key in RulesExpressions.ATTRIBUTES:
   var rows: Array=source.rule("standard_array").map(func(value: Variant):return {"id":str(value),"name":str(value)})
   var control := picker(attribute_section,key,rows);select_id(control,str(attributes[key]));attribute_pickers[key]=control
   control.item_selected.connect(_score_selected.bind(str(key)))
 if advance:
  increase_picker=picker(self,"Increase",[{"id":"","name":"No attribute increase selected"}]+RulesExpressions.ATTRIBUTES.map(func(id: String):return {"id":id,"name":id+" +1"}))
  increase_picker.item_selected.connect(func(_index: int):
   if updating:return
   attribute_increase=id_of(increase_picker);refresh_preview())
 var skill_section := form_section("Skills")
 skill_section.add_child(GameUI.label("Skill ranks",GameUI.SECTION))
 budget=GameUI.label("",GameUI.META);skill_section.add_child(budget)
 for id in source.ids("skills"):
  var row := HBoxContainer.new();skill_section.add_child(row)
  var skill := source.definition("skills",id)
  var caption := GameUI.label(skill.name+" ("+skill.attribute+")",GameUI.META);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(caption)
  var spin := SpinBox.new();spin.min_value=0;spin.max_value=20;spin.step=1;spin.custom_minimum_size.x=90;row.add_child(spin);skill_pickers[id]=spin
  spin.value_changed.connect(func(value: float):
   if updating:return
   allocation[id]=int(value);refresh_preview())
 skill_section.add_child(GameUI.action("Suggested skill allocation",suggest_allocation))
 var feat_section := form_section("Feats")
 feat_filter=LineEdit.new();feat_filter.placeholder_text="Search feats · selected choice stays visible";feat_section.add_child(feat_filter)
 feat_filter.text_changed.connect(func(_query: String):if not updating:refresh_preview())
 feat_picker=picker(feat_section,"Feat",[])
 feat_picker.item_selected.connect(func(_index: int):
  if updating:return
  feat_id=id_of(feat_picker);refresh_preview())
 feat_detail=GameUI.label("",GameUI.META);feat_section.add_child(feat_detail)
 if RulesCareer.enabled(source):bonus_column=VBoxContainer.new();feat_section.add_child(bonus_column)
 if not advance:
  var gear_section := form_section("Equipment")
  gear_section.add_child(GameUI.label("Starting equipment",GameUI.SECTION))
  gear_section.add_child(GameUI.label("Choose one active weapon and compatible armour. Class proficiencies are enforced." if source.rules_ref().engine_schema==3 else "Bow, then staff, then blade determine your active legacy weapon.",GameUI.META))
  gear_section.add_child(GameUI.action("Suggested class equipment and spells",func():class_loadout();refresh_preview()))
  for id in source.ids("equipment"):
   var control := CheckBox.new();control.text=source.definition("equipment",id).name+ (" · "+str(source.definition("equipment",id).get("proficiency","")) if source.rules_ref().engine_schema==3 else "");equipment_pickers[id]=control
   control.button_pressed=base.equipment.has(id);gear_section.add_child(control);control.toggled.connect(func(_value: bool):if not updating:refresh_preview())
  spell_section=form_section("Spells")
  spell_controls()
 var progression := form_section("Progression")
 progression_detail=GameUI.label("",GameUI.META);progression.add_child(progression_detail)
 explanation=GameUI.label("",GameUI.META);add_child(explanation)
 if advance:
  var suggestion := kernel.suggested_choice(base,str(base.advancement_history.back().class_id))
  if suggestion.ok:
   class_id=suggestion.choice.class_id;allocation=suggestion.choice.skill_allocations;feat_id=suggestion.choice.feat_id;attribute_increase=suggestion.choice.attribute_increase
 else:
  var step: Dictionary=base.advancement_history[0]
  class_id=step.class_id;allocation=step.skill_allocations.duplicate(true);feat_id=step.feat_id
 select_id(class_picker,class_id)
 if advance:select_id(increase_picker,attribute_increase)
 if RulesCareer.enabled(source):
  career_section=form_section("Specialisation");career_controls()
 updating=false;refresh_preview()
func spell_controls() -> void:
 if spell_section==null:return
 for child in spell_section.get_children():spell_section.remove_child(child);child.queue_free()
 preparation_pickers={}
 var cls := source.definition("classes",class_id)
 spell_section.add_child(GameUI.label("Prepared spells / known repertoire",GameUI.SECTION))
 var help := "Legacy preparations record granted choices."
 if source.rules_ref().engine_schema==3:
  help="Prepare copies of individual spells; copies and tier slots are spent on each cast. Copies in each tier cannot exceed its slot capacity." if cls.spell_mode=="prepared" else "Spontaneous casting: choose up to %d known spells; casts spend shared tier slots. Known spells remain learned."%RulesCoreContent.selection_limit(class_id,1,source) if cls.spell_mode=="spontaneous" else "This class has no starting spellcasting."
 spell_section.add_child(GameUI.label(help,GameUI.META))
 var granted: Array=[]
 for tier in cls.features:
  if int(tier.at)==1:granted.append_array(source.definition("features",tier.id).abilities)
 if source.rules_ref().engine_schema==3:spell_section.add_child(GameUI.action("Suggested spell selections",suggest_spell_selections))
 for id in source.ids("abilities"):
  if source.rule("base_abilities").has(id):continue
  var row := source.definition("abilities",id)
  if source.rules_ref().engine_schema==3 and (not granted.has(id) or not row.tags.has("spell")):continue
  if source.rules_ref().engine_schema==3 and row.tags.has("prepared"):
   var line := HBoxContainer.new();spell_section.add_child(line)
   var caption := GameUI.label(row.name,GameUI.META);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(caption)
   var control := SpinBox.new();control.min_value=0;control.max_value=30;control.step=1;control.tooltip_text=row.get("description",row.name)+" · choose prepared copies";control.custom_minimum_size.x=88;line.add_child(control)
   control.value=int(base.choices.get("spell_preparations",{}).get(id,0));preparation_pickers[id]=control
   control.value_changed.connect(func(_value: float):if not updating:refresh_preview())
  else:
   var control := CheckBox.new();control.text=row.name;control.tooltip_text=row.get("description",row.name);preparation_pickers[id]=control
   control.button_pressed=base.choices.prepared_abilities.has(id);spell_section.add_child(control);control.toggled.connect(func(_value: bool):if not updating:refresh_preview())
func prepared_ids() -> Array:
 return preparation_pickers.keys().filter(func(id: String):return int(preparation_pickers[id].value)>0 if preparation_pickers[id] is SpinBox else preparation_pickers[id].button_pressed)
func prepared_counts() -> Dictionary:
 var copies := {}
 for id in preparation_pickers:
  if preparation_pickers[id] is SpinBox and int(preparation_pickers[id].value)>0:copies[id]=int(preparation_pickers[id].value)
 return copies

func form_section(title: String) -> VBoxContainer:
 if sections==null:
  sections=TabContainer.new();sections.custom_minimum_size.y=250;sections.size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_child(sections)
 var scroll := ScrollContainer.new();scroll.name=title;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;sections.add_child(scroll)
 var column := VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",6);scroll.add_child(column)
 return column
func _score_selected(index: int,key: String) -> void:
 if updating:return
 var score := int(attribute_pickers[key].get_item_metadata(index));var old := int(attributes[key])
 updating=true
 for other in attributes:
  if other!=key and int(attributes[other])==score:attributes[other]=old;break
 attributes[key]=score
 for id in attribute_pickers:select_id(attribute_pickers[id],str(attributes[id]))
 updating=false;refresh_preview()
func class_loadout() -> void:
 if advance or source.rules_ref().engine_schema!=3:return
 var cls := source.definition("classes",class_id)
 spell_controls()
 var blocked: Array=source.definition("ancestries",ancestry_ref).get("capabilities",{}).get("blocked_equipment",[])
 for id in equipment_pickers:equipment_pickers[id].button_pressed=cls.recommended_equipment.has(id) and not source.definition("equipment",id).kind in blocked
 _suggest_spells()
func suggest_spell_selections() -> void:
 if advance or source.rules_ref().engine_schema!=3:return
 var before := updating
 updating=true;_suggest_spells();updating=before
 if not updating:refresh_preview()
func _suggest_spells() -> void:
 var cls := source.definition("classes",class_id)
 var initial := kernel.create(base.character_id,attributes,ancestry_ref,background_ref)
 initial.equipment=cls.recommended_equipment.filter(func(id: String):return not source.definition("equipment",id).kind in source.definition("ancestries",ancestry_ref).get("capabilities",{}).get("blocked_equipment",[]))
 var suggestion := kernel.suggested_choice(initial,class_id,"toughness")
 if not suggestion.ok:return
 var starting := kernel.preview_advancement(initial,suggestion.choice)
 if not starting.ok:return
 var copies := RulesCoreContent.starting_preparations(starting.snapshot,source)
 var selected := RulesCoreContent.suggested_spells(starting.snapshot,source)
 for id in preparation_pickers:
  if preparation_pickers[id] is SpinBox:preparation_pickers[id].set_value_no_signal(int(copies.get(id,0)))
  else:preparation_pickers[id].button_pressed=selected.has(id)

func set_class(id: String) -> void:
 if advance:
  class_id=id;select_id(class_picker,id)
  var suggestion := kernel.suggested_choice(base,id)
  if suggestion.ok:
   allocation=suggestion.choice.skill_allocations;feat_id=suggestion.choice.feat_id;attribute_increase=suggestion.choice.attribute_increase
   select_id(increase_picker,attribute_increase)
  if RulesCareer.enabled(source):career_controls()
  refresh_preview();return
 updating=true;class_id=id;select_id(class_picker,id);allocation={};feat_id="toughness" if source.rules_ref().engine_schema==3 else "steady-study"
 if source.rules_ref().engine_schema==3:
  var priorities: Array={"barbarian":["STR","CON","DEX","WIS","CHA","INT"],"bard":["CHA","DEX","INT","CON","WIS","STR"],"cleric":["WIS","CON","STR","CHA","INT","DEX"],"druid":["WIS","CON","DEX","INT","CHA","STR"],"fighter":["STR","CON","DEX","WIS","INT","CHA"],"monk":["WIS","DEX","STR","CON","INT","CHA"],"paladin":["STR","CHA","CON","WIS","DEX","INT"],"ranger":["DEX","WIS","CON","STR","INT","CHA"],"rogue":["DEX","INT","CON","WIS","CHA","STR"],"sorcerer":["CHA","DEX","CON","INT","WIS","STR"],"wizard":["INT","DEX","CON","WIS","CHA","STR"]}.get(id,RulesExpressions.ATTRIBUTES)
  priorities=source.definition("classes",id).get("attribute_priority",priorities)
  var values: Array=source.rule("standard_array")
  for i in priorities.size():attributes[priorities[i]]=values[i]
  for attribute in attribute_pickers:select_id(attribute_pickers[attribute],str(attributes[attribute]))
 class_loadout()
 if RulesCareer.enabled(source):career_controls()
 updating=false
 suggest_allocation()
func unlevelled() -> Dictionary:
 return kernel.create(base.character_id,attributes,ancestry_ref,background_ref)
func skill_draft() -> Dictionary:
 return {"skill_allocations":allocation.duplicate(true),"attribute_increase":attribute_increase if advance else ""}
func choice() -> Dictionary:
 var value := {"class_id":class_id,"skill_allocations":allocation.duplicate(true),"feat_id":feat_id,"attribute_increase":attribute_increase if advance else ""}
 if RulesCareer.enabled(source):value.specialisations=specialisations.duplicate(true);value.bonus_feats=bonus_feats.duplicate()
 return value
func definition() -> Dictionary:
 var value := {"attributes":attributes.duplicate(true),"ancestry_ref":ancestry_ref,"background_ref":background_ref,"class_id":class_id,"skill_allocations":allocation.duplicate(true),"feat_id":feat_id,"equipment":equipment_pickers.keys().filter(func(id: String):return equipment_pickers[id].button_pressed),"prepared_abilities":prepared_ids()}
 if source.rules_ref().engine_schema==3:value.spell_preparations=prepared_counts()
 if RulesCareer.enabled(source):value.specialisations=specialisations.duplicate(true);value.bonus_feats=bonus_feats.duplicate()
 return value
func refresh_preview() -> void:
 if updating or base.is_empty():return
 updating=true
 var current := base if advance else unlevelled()
 var available := kernel.available_advancement(current)
 var messages: Array=[]
 if available.ok:
  for i in class_picker.item_count:
   var id: String=str(class_picker.get_item_metadata(i));var why := CharacterBuilderRecords.reason(available.classes[id])
   class_picker.set_item_disabled(i,not why.is_empty());class_picker.get_popup().set_item_tooltip(i,why)
   if not why.is_empty():messages.append(source.definition("classes",id).name+": "+why)
 var cls := source.definition("classes",class_id)
 class_detail.text="%s · HP +%d/level · %d skill points + INT · cap %d
BAB %s · Saves %s
Features: %s"%[cls.get("name",class_id),int(cls.get("hp_per_level",0)),int(cls.get("skill_points",0)),int(cls.get("max_level",0)),progression_text(cls.get("bab",{}))," / ".join(RulesExpressions.SAVES.map(func(save: String):return save+" "+progression_text(cls.get("saves",{}).get(save,{})))),", ".join(cls.get("features",[]).map(func(t: Dictionary):return "L%d %s"%[int(t.at),feature_text(t.id)]))]
 if source.rules_ref().engine_schema==3:
  class_detail.text=str(cls.description)+"\nHit die d%d · %s BAB · %s casting\nProficiencies: %s\nClass skills (+3 when trained): %s\nPlayable levels 1–%d; higher-level content remains in the programme."%[int(cls.hit_die),"full" if cls.bab.op=="class_level" else "partial",str(cls.spell_mode)+" "+str(cls.casting_attribute) if not cls.spell_mode.is_empty() else "no",", ".join(cls.proficiencies),", ".join(cls.class_skills),int(cls.max_level)]
  class_detail.tooltip_text="\n".join(cls.features.map(func(t: Dictionary):return "Level %d: %s"%[int(t.at),feature_text(t.id)]))
 progression_detail.text="%s · HP +%d/level + CON · %d skill points + INT\nBAB: %s\nSaves: %s\n%s"%[cls.name,int(cls.hp_per_level),int(cls.skill_points),progression_text(cls.bab)," / ".join(RulesExpressions.SAVES.map(func(save: String):return save+" "+progression_text(cls.saves[save]))),"\n".join(cls.features.map(func(tier: Dictionary):return "Level %d: %s"%[int(tier.at),feature_text(tier.id)]))]
 if RulesCareer.enabled(source):
  class_detail.text+="\nEntry: "+RulesCareer.requirement_text(cls.requirements,source)
  if cls.get("class_kind")=="prestige" and not cls.career_choices.is_empty():class_detail.text=class_detail.text.replace("no casting","advances chosen casting tracks")
 if source.rules_ref().engine_schema==3:progression_detail.text+="\nBonus feat choices at class levels: "+str(cls.bonus_feat_levels)
 var options := kernel.preview_choices(current,class_id,skill_draft())
 if options.ok:
  budget.text="%d points remaining / %d this level. Ranks cannot exceed total level."%[options.skill_points_remaining,options.skill_points]
  for id in skill_pickers:
   skill_pickers[id].max_value=options.skill_rank_room[id];skill_pickers[id].set_value_no_signal(float(allocation.get(id,0)))
  if advance:increase_picker.visible=not options.attribute_options.is_empty()
  feat_picker.clear()
  if options.feat_choices.is_empty():
   feat_id="";feat_picker.add_item("No feat at this level");feat_picker.set_item_metadata(0,"");feat_picker.disabled=true
  else:
   feat_picker.disabled=false
   for id in options.feat_choices:
    if id!=feat_id and not feat_filter.text.to_lower() in str(source.definition("feats",id).name).to_lower():continue
    var why := CharacterBuilderRecords.reason(options.feat_choices[id]);var index: int=feat_picker.item_count
    feat_picker.add_item(str(source.definition("feats",id).name)+( " · locked" if not why.is_empty() else ""));feat_picker.set_item_metadata(index,id)
    feat_picker.set_item_disabled(index,not why.is_empty());feat_picker.get_popup().set_item_tooltip(index,why+"\n"+", ".join(source.definition("feats",id).features.map(func(feature_id: String):return feature_text(feature_id))))
    if not why.is_empty():messages.append(source.definition("feats",id).name+": "+why)
   select_id(feat_picker,feat_id)
   if feat_id.is_empty():feat_picker.select(-1)
 else:budget.text=CharacterBuilderRecords.reason(options)
 preview=kernel.preview_advancement(base,choice()) if advance else CharacterBuilderRecords.create(base.character_id,definition(),base)
 if not advance:
  var granted_ids: Array=[]
  for tier in cls.get("features",[]):
   if int(tier.at)<=1:granted_ids.append_array(source.definition("features",tier.id).get("abilities",[]))
  for id in preparation_pickers:
   var granted: bool=granted_ids.has(id)
   if preparation_pickers[id] is BaseButton:preparation_pickers[id].disabled=not granted
   else:preparation_pickers[id].editable=granted
   preparation_pickers[id].tooltip_text="Granted by this build" if granted else "Not granted by this build"
 if feat_detail!=null:
  var feat := source.definition("feats",feat_id)
  feat_detail.text="Choose a feat to see its mechanical benefits and requirements." if feat.is_empty() else str(feat.name)+"\n"+"\n".join(feat.features.map(func(id: String):return feature_text(id)))
 # Keep explicitly selected illegal preparations visible until the player removes them.
 explanation.text=("Ready to save: attributes, class, skills, feat and equipment are valid." if preview.ok else CharacterBuilderRecords.reason(preview))+"\n\n"+"\n".join(messages)
 explanation.add_theme_color_override("font_color",GameUI.MUTED if preview.ok else GameUI.ERROR)
 updating=false;changed.emit()
func suggest_allocation() -> void:
 var suggested := kernel.suggested_choice(base if advance else unlevelled(),class_id,feat_id if not feat_id.is_empty() else "steady-study")
 if suggested.ok:
  allocation=suggested.choice.skill_allocations
  if advance:attribute_increase=suggested.choice.attribute_increase;select_id(increase_picker,attribute_increase)
 refresh_preview()

func feature_text(id: String) -> String:
 var row := source.definition("features",id)
 var text: String=str(row.get("name",id))+ (" · "+str(row.description) if not str(row.get("description","")).is_empty() else "")
 for m in row.get("modifiers",[]):text+=" · "+str(m.stat)+" "+formula_text(m.value)+" ("+str(m.type)+")"
 if row.has("capabilities"):text+=" · "+RulesCapabilities.summary(row.capabilities)
 for ability in row.get("abilities",[]):text+=" · "+str(source.definition("abilities",ability).name)
 return text

func formula_text(node: Dictionary) -> String:
 if node.get("op")=="const":return "%+d"%int(node.value)
 return RulesJson.canonical(node)
func progression_text(node: Dictionary) -> String:
 var values: Array[String]=[]
 var cap: int=int(source.definition("classes",class_id).get("max_level",20))
 var levels: Array=[1,5,10,15,20].filter(func(level: int):return level<=cap)
 if not levels.has(cap):levels.append(cap);levels.sort()
 for level in levels:
  var result := RulesExpressions.evaluate_formula(node,{"classes":{class_id:level}})
  values.append("%d:%+d"%[level,int(result.get("value",0))])
 return " ".join(values)+" (level:value)"

func career_controls() -> void:
 if career_section==null:return
 for child in career_section.get_children():career_section.remove_child(child);child.queue_free()
 if bonus_column!=null:
  for child in bonus_column.get_children():bonus_column.remove_child(child);child.queue_free()
 career_pickers={};bonus_picker=null
 var classes: Dictionary=kernel.derive_character(base).get("snapshot",{}).get("class_levels",{}) if advance else {}
 var class_level := int(classes.get(class_id,0))+1
 var level: int=base.advancement_history.size()+1 if advance else 1
 specialisations=RulesCareer.defaults(source,class_id,class_level)
 if advance:
  var suggestion := kernel.suggested_choice(base,class_id)
  if suggestion.ok:specialisations=suggestion.choice.specialisations.duplicate(true)
 if not advance and base.advancement_history[0].class_id==class_id:specialisations=base.advancement_history[0].specialisations.duplicate(true)
 career_section.add_child(GameUI.label("Deliberate class choices",GameUI.SECTION))
 career_section.add_child(GameUI.label("Recommended choices are shown below. Review alternatives: each choice persists in your ordered class history.",GameUI.META))
 for group in RulesCareer.groups(source,class_id,class_level):
  var control := picker(career_section,group.name,group.options)
  career_pickers[group.id]=control;select_id(control,str(specialisations.get(group.id,"")))
  if advance:
   var context: Dictionary=kernel.derive_character(base).context
   for i in group.options.size():
    var why := CharacterBuilderRecords.reason(RulesExpressions.evaluate_requirements(group.options[i].requirements,context))
    control.set_item_disabled(i,not why.is_empty());control.get_popup().set_item_tooltip(i,why)
  var detail := GameUI.label("",GameUI.META);career_section.add_child(detail)
  var update_detail := func():
   var option: Dictionary=group.options.filter(func(row: Dictionary):return row.id==id_of(control))[0]
   specialisations[group.id]=option.id
   detail.text=option.description+"\n"+"\n".join(option.features.map(func(id: String):return feature_text(id)))
  update_detail.call()
  control.item_selected.connect(func(_i: int):update_detail.call();if not updating:refresh_preview())
 if career_pickers.is_empty():career_section.add_child(GameUI.label("No new specialisation at this class level. Existing choices remain on the character sheet.",GameUI.META))
 bonus_feats=[]
 if RulesCareer.feat_count(source,level,class_id,class_level)>1:
  bonus_column.add_child(GameUI.label("Two feat grants coincide: choose both separately.",GameUI.SECTION))
  bonus_picker=picker(bonus_column,"Additional feat",source.ids("feats").map(func(id: String):return {"id":id,"name":source.definition("feats",id).name}))
  select_id(bonus_picker,"steady-study");bonus_feats=[id_of(bonus_picker)]
  bonus_picker.item_selected.connect(func(_i: int):bonus_feats=[id_of(bonus_picker)];if not updating:refresh_preview())
