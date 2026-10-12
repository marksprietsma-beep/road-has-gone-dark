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
var feat_id := ""
var attribute_increase := ""

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
 ancestry_ref=base.ancestry_ref;background_ref=base.background_ref;attributes=base.base_attributes.duplicate(true)
 for child in get_children():remove_child(child);child.queue_free()
 attribute_pickers={};skill_pickers={};equipment_pickers={};preparation_pickers={}
 updating=true
 if not advance:
  add_child(GameUI.label("Allocate the standard array",GameUI.SECTION))
  add_child(GameUI.label("Choosing a score swaps its previous allocation. Every score is used once.",GameUI.META))
  for key in RulesExpressions.ATTRIBUTES:
   var rows: Array=source.rule("standard_array").map(func(value: Variant):return {"id":str(value),"name":str(value)})
   var control := picker(self,key,rows);select_id(control,str(attributes[key]));attribute_pickers[key]=control
   control.item_selected.connect(func(_index: int):
    if updating:return
    var score := int(id_of(control));var old: int=int(attributes[key])
    for other in attributes:
     if other!=key and int(attributes[other])==score:attributes[other]=old;select_id(attribute_pickers[other],str(old));break
    attributes[key]=score;refresh_preview())
 class_filter=LineEdit.new();class_filter.placeholder_text="Search classes · selected choice stays visible";add_child(class_filter)
 class_picker=picker(self,"Class",source.ids("classes").map(func(id: String):return {"id":id,"name":source.definition("classes",id).name}))
 class_detail=GameUI.label("",GameUI.META);add_child(class_detail)
 class_filter.text_changed.connect(func(_query: String):
  if updating:return
  class_picker.clear()
  for id in source.ids("classes"):
   var row := source.definition("classes",id)
   if id==class_id or class_filter.text.to_lower() in str(row.name).to_lower():class_picker.add_item(row.name);class_picker.set_item_metadata(class_picker.item_count-1,id)
  select_id(class_picker,class_id);refresh_preview())
 class_picker.item_selected.connect(func(_index: int):
  if updating:return
  class_id=id_of(class_picker);allocation={};feat_id="";refresh_preview())
 if advance:
  increase_picker=picker(self,"Increase",[{"id":"","name":"No attribute increase selected"}]+RulesExpressions.ATTRIBUTES.map(func(id: String):return {"id":id,"name":id+" +1"}))
  increase_picker.item_selected.connect(func(_index: int):
   if updating:return
   attribute_increase=id_of(increase_picker);refresh_preview())
 add_child(GameUI.label("Skill ranks",GameUI.SECTION))
 budget=GameUI.label("",GameUI.META);add_child(budget)
 for id in source.ids("skills"):
  var row := HBoxContainer.new();add_child(row)
  var skill := source.definition("skills",id)
  var caption := GameUI.label(skill.name+" ("+skill.attribute+")",GameUI.META);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(caption)
  var spin := SpinBox.new();spin.min_value=0;spin.max_value=20;spin.step=1;spin.custom_minimum_size.x=90;row.add_child(spin);skill_pickers[id]=spin
  spin.value_changed.connect(func(value: float):
   if updating:return
   allocation[id]=int(value);refresh_preview())
 add_child(GameUI.action("Suggested skill allocation",suggest_allocation))
 feat_filter=LineEdit.new();feat_filter.placeholder_text="Search feats · selected choice stays visible";add_child(feat_filter)
 feat_filter.text_changed.connect(func(_query: String):if not updating:refresh_preview())
 feat_picker=picker(self,"Feat",[])
 feat_picker.item_selected.connect(func(_index: int):
  if updating:return
  feat_id=id_of(feat_picker);refresh_preview())
 if not advance:
  add_child(GameUI.label("Starting equipment",GameUI.SECTION))
  add_child(GameUI.label("Bow is the active weapon when carried; otherwise staff, then blade. Armour and shields affect defence through GAME-32.",GameUI.META))
  for id in source.ids("equipment"):
   var control := CheckBox.new();control.text=source.definition("equipment",id).name;equipment_pickers[id]=control
   control.button_pressed=base.equipment.has(id);add_child(control);control.toggled.connect(func(_value: bool):if not updating:refresh_preview())
  add_child(GameUI.label("Preparations",GameUI.SECTION))
  add_child(GameUI.label("Granted abilities remain usable under current V0 combat rules. Preparations record your choices; they do not grant unknown abilities or extra casts.",GameUI.META))
  for id in source.ids("abilities"):
   if source.rule("base_abilities").has(id):continue
   var control := CheckBox.new();control.text=source.definition("abilities",id).name;preparation_pickers[id]=control
   control.button_pressed=base.choices.prepared_abilities.has(id);add_child(control);control.toggled.connect(func(_value: bool):if not updating:refresh_preview())
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
 updating=false;refresh_preview()
func unlevelled() -> Dictionary:
 return kernel.create(base.character_id,attributes,ancestry_ref,background_ref)
func skill_draft() -> Dictionary:
 return {"skill_allocations":allocation.duplicate(true),"attribute_increase":attribute_increase if advance else ""}
func choice() -> Dictionary:
 return {"class_id":class_id,"skill_allocations":allocation.duplicate(true),"feat_id":feat_id,"attribute_increase":attribute_increase if advance else ""}
func definition() -> Dictionary:
 return {"attributes":attributes.duplicate(true),"ancestry_ref":ancestry_ref,"background_ref":background_ref,"class_id":class_id,"skill_allocations":allocation.duplicate(true),"feat_id":feat_id,"equipment":equipment_pickers.keys().filter(func(id: String):return equipment_pickers[id].button_pressed),"prepared_abilities":preparation_pickers.keys().filter(func(id: String):return preparation_pickers[id].button_pressed)}
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
 if preview.ok and not advance:
  for id in preparation_pickers:
   var granted: bool=preview.snapshot.abilities.has(id)
   preparation_pickers[id].disabled=not granted
   preparation_pickers[id].tooltip_text="Granted by this build" if granted else "Not granted by this build"
 # Keep explicitly selected illegal preparations visible until the player removes them.
 explanation.text=("Valid GAME-32 preview." if preview.ok else CharacterBuilderRecords.reason(preview))+"\n\n"+"\n".join(messages)
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
 var text: String=str(row.get("name",id))
 for m in row.get("modifiers",[]):text+=" · "+str(m.stat)+" "+formula_text(m.value)+" ("+str(m.type)+")"
 for ability in row.get("abilities",[]):text+=" · "+str(source.definition("abilities",ability).name)
 return text

func formula_text(node: Dictionary) -> String:
 if node.get("op")=="const":return "%+d"%int(node.value)
 return RulesJson.canonical(node)
func progression_text(node: Dictionary) -> String:
 var values: Array[String]=[]
 for level in [1,5,10,15,20]:
  var result := RulesExpressions.evaluate_formula(node,{"classes":{class_id:level}})
  values.append("%d:%+d"%[level,int(result.get("value",0))])
 return " ".join(values)+" (level:value)"
