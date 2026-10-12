class_name CharacterScreen
extends Control
## Persistent sheet and creator shell. BuildEditor delegates mechanics to GAME-32.
static var handoff := {}
var sheet_mode := false
var return_scene := "res://scenes/gameplay/expedition.tscn"
var service := CharacterBuilderService.new()
var entry := {}
var slot := ""
var state := {}
var selected := 1
var thread: Thread
var message := ""
var ready_view := false
var expedition_cache_root := "user://expedition-content"
var content_button: Button
var title: Label
var origin: Label
var roster: PartyRoster
var name_edit: LineEdit
var people_picker: OptionButton
var heritage_picker: OptionButton
var role_picker: OptionButton
var origin_picker: OptionButton
var background_picker: OptionButton
var commonness: Label
var description: Label
var biography: Label
var overview: Label
var live_summary: Label
var revert_button: Button
var detail_tabs: TabContainer
var message_label: Label
var save_button: Button
var finish_button: Button
var reroll_button: Button
var back_button: Button
var editor: BuildEditor
var advance_editor: BuildEditor
var statistics: Label
var advancement_status: Label
var advancement_button: Button
var preview_recipes := {}
var updating := false
var pack := WorldOriginLore.read_json(WorldPeoples.PACK)
var identity_draft := {}
var saved_form := ""
var pane: HBoxContainer
var pending_selection := 0

static func open_sheet(screen: Control,source_entry: Dictionary,source_slot: String,save_root: String,library_root: String,cache_root: String,back: String) -> void:
 handoff={"entry":source_entry,"slot":source_slot,"save_root":save_root,"library_root":library_root,"cache_root":cache_root,"return_scene":back}
 screen.get_tree().change_scene_to_file("res://scenes/ui/character_sheet.tscn")
func label(text: String,size_value: int=14) -> Label:return GameUI.label(text,size_value)
func scroll_tab(tab_name: String) -> VBoxContainer:
 var scroll := ScrollContainer.new();scroll.name=tab_name;scroll.follow_focus=true;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;detail_tabs.add_child(scroll)
 var column := VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",4);scroll.add_child(column)
 return column
func option(parent: Control,caption: String,rows: Array) -> OptionButton:
 parent.add_child(label(caption,GameUI.META))
 var result := OptionButton.new();result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.clip_text=true;parent.add_child(result)
 for item in rows:result.add_item(str(item.get("name",item.id)));result.set_item_metadata(result.item_count-1,item.id)
 return result
func selected_id(control: OptionButton) -> String:return str(control.get_item_metadata(control.selected)) if control.selected>=0 else ""
func pick(control: OptionButton,id: String) -> void:
 for i in control.item_count:
  if str(control.get_item_metadata(i))==id:control.select(i);return
func _ready() -> void:
 GameUI.install(self)
 var background := ColorRect.new();background.color=Color.BLACK;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
 var margin := MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(margin);GameUI.reading_width(margin,self,1040)
 for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,8)
 var column := VBoxContainer.new();margin.add_child(column);column.add_theme_constant_override("separation",4)
 title=label("Character builder",GameUI.TITLE);column.add_child(title)
 content_button=GameUI.action("Use expanded martial content · new party only",func():
  if thread==null and not state.is_empty():_start("builder_content",{"before_hash":RulesJson.digest(state),"pack_id":RulesRecords.NEW_PACK}))
 column.add_child(content_button)
 origin=label("",GameUI.META);origin.autowrap_mode=TextServer.AUTOWRAP_OFF;origin.clip_text=true;origin.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;column.add_child(origin)
 pane=HBoxContainer.new();pane.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(pane)
 var left := VBoxContainer.new();left.custom_minimum_size.x=164;pane.add_child(left)
 roster=PartyRoster.new();roster.custom_minimum_size.y=170;roster.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;left.add_child(roster);roster.item_selected.connect(_select_member)
 overview=label("Create each adventurer",GameUI.META);left.add_child(overview)
 live_summary=label("",GameUI.META);left.add_child(live_summary)
 detail_tabs=TabContainer.new();detail_tabs.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail_tabs.add_theme_font_size_override("font_size",12);pane.add_child(detail_tabs)
 var identity := scroll_tab("Identity")
 name_edit=LineEdit.new();name_edit.max_length=48;name_edit.placeholder_text="Character name";identity.add_child(name_edit);name_edit.text_changed.connect(func(_value: String):if not updating:_identity_changed())
 name_edit.text_submitted.connect(func(_value: String):_save_changes())
 people_picker=option(identity,"Ancestry · current prototype options",pack.peoples)
 people_picker.item_selected.connect(func(_i: int):if not updating:_heritages();_identity_changed())
 heritage_picker=option(identity,"Compatible heritage",[])
 heritage_picker.item_selected.connect(func(_i: int):if not updating:_identity_changed())
 commonness=label("These eight peoples are provisional. Current heritage definitions have no ancestry bonuses.",GameUI.META);identity.add_child(commonness)
 description=label("",GameUI.META);identity.add_child(description)
 role_picker=option(identity,"Narrative role · recommendations only",pack.roles)
 role_picker.item_selected.connect(func(_i: int):if not updating:_identity_changed())
 origin_picker=option(identity,"Personal origin · source-world hometown",[])
 origin_picker.item_selected.connect(func(_i: int):if not updating:_backgrounds();_identity_changed())
 background_picker=option(identity,"Background profession · grounded in your origin",[])
 background_picker.item_selected.connect(func(_i: int):if not updating:_identity_changed())
 biography=label("",GameUI.META);identity.add_child(biography)
 reroll_button=GameUI.action("Another background",func():
  if background_picker.item_count>0:background_picker.select((background_picker.selected+1)%background_picker.item_count);_identity_changed())
 identity.add_child(reroll_button)
 var build := scroll_tab("Build")
 build.add_child(label("Recommendations are optional",GameUI.SECTION))
 var suggestions := HBoxContainer.new();build.add_child(suggestions)
 for role in pack.roles:
  suggestions.add_child(GameUI.action(str(role.name),func():recommend(str(role.id))))
 editor=BuildEditor.new();build.add_child(editor);editor.changed.connect(_preview_changed)
 var details := scroll_tab("Sheet")
 statistics=label("",GameUI.BODY);details.add_child(statistics)
 var advance_tab := scroll_tab("Advance")
 advancement_status=label("",GameUI.META);advance_tab.add_child(advancement_status)
 advance_editor=BuildEditor.new();advance_tab.add_child(advance_editor);advance_editor.changed.connect(_advance_changed)
 advancement_button=GameUI.action("Commit reviewed level",_commit_advancement,true);advance_tab.add_child(advancement_button)
 message_label=label("",GameUI.META);message_label.max_lines_visible=2;message_label.clip_text=true;column.add_child(message_label)
 var actions := HBoxContainer.new();column.add_child(actions)
 back_button=GameUI.action("Back" if sheet_mode else "Main menu",_return_menu);actions.add_child(back_button);actions.add_child(GameUI.spacer())
 revert_button=GameUI.action("Revert edits",refresh);actions.add_child(revert_button)
 revert_button.visible=not sheet_mode
 save_button=GameUI.action("Save adventurer",_save_changes,true);actions.add_child(save_button)
 finish_button=GameUI.action("Party ready",_finish,true);actions.add_child(finish_button)
 var input: Dictionary=handoff if sheet_mode else PartyService.handoff
 handoff={};PartyService.handoff={}
 if input.is_empty():input=service.resumable()
 if input.is_empty():message="Choose a hometown through New Game first.";refresh();return
 entry=input.entry;slot=input.slot;expedition_cache_root=str(input.get("cache_root",expedition_cache_root));return_scene=str(input.get("return_scene",return_scene))
 service.store.save_root=str(input.get("save_root",service.store.save_root));service.library.library_root=str(input.get("library_root",service.library.library_root))
 _start("builder_open")
func _start(operation: String,changes: Dictionary={}) -> void:
 if thread!=null or entry.is_empty():return
 message="Loading saved characters…" if operation=="builder_open" else "Saving and verifying…"
 thread=Thread.new();thread.start(service.operate.bind(entry,slot,operation,selected,changes));_busy()
func _busy() -> void:
 var busy := thread!=null
 content_button.disabled=busy or ready_view or not state.get("character_builder",{}).get("confirmed",[]).is_empty()
 save_button.text="Retry preparation" if state.is_empty() else "Save adventurer"
 save_button.disabled=busy or ready_view or entry.is_empty() or not state.is_empty() and not editor.preview.get("ok",false)
 finish_button.disabled=busy or state.is_empty() or not ready_view and state.get("character_builder",{}).get("confirmed",[]).size()!=3
 back_button.disabled=busy;roster.set_enabled(not busy)
 revert_button.disabled=busy
 lock_input(detail_tabs,busy)
 message_label.text=message;message_label.tooltip_text=message
func lock_input(node: Node,busy: bool) -> void:
 if node is Control:
  if busy and not node.has_meta("builder_focus"):
   node.set_meta("builder_focus",node.focus_mode);node.focus_mode=Control.FOCUS_NONE
   if node.has_focus():node.release_focus()
  elif not busy and node.has_meta("builder_focus"):
   node.focus_mode=node.get_meta("builder_focus");node.remove_meta("builder_focus")
 if node is BaseButton:
  if busy and not node.has_meta("builder_disabled"):node.set_meta("builder_disabled",node.disabled);node.disabled=true
  elif not busy and node.has_meta("builder_disabled"):node.disabled=node.get_meta("builder_disabled");node.remove_meta("builder_disabled")
 if node is LineEdit:
  if busy and not node.has_meta("builder_editable"):node.set_meta("builder_editable",node.editable);node.editable=false
  elif not busy and node.has_meta("builder_editable"):node.editable=node.get_meta("builder_editable");node.remove_meta("builder_editable")
 for child in node.get_children():lock_input(child,busy)
func _process(_delta: float) -> void:
 if thread==null or thread.is_alive():return
 var result: Dictionary=thread.wait_to_finish();thread=null
 lock_input(detail_tabs,false)
 if result.get("ok",false):
  state=result.state;message="Character saved and verified." if state.party.status=="draft" else "Saved character sheet."
  if pending_selection>0:selected=pending_selection;pending_selection=0
  refresh()
 else:message=CharacterBuilderRecords.reason(result);_busy()
func refresh() -> void:
 updating=true
 ready_view=not state.is_empty() and state.party.status=="ready"
 content_button.visible=not ready_view and not sheet_mode and not state.is_empty() and state.get("character_builder",{}).get("rules_ref",{}).get("pack_id","")!=RulesRecords.NEW_PACK
 content_button.disabled=thread!=null or not state.get("character_builder",{}).get("confirmed",[]).is_empty()
 title.text="Character sheet" if sheet_mode else ("Party ready" if ready_view else "Build your adventurers")
 save_button.visible=not ready_view and not sheet_mode;finish_button.visible=not sheet_mode
 revert_button.visible=not ready_view and not sheet_mode
 reroll_button.visible=not ready_view and not sheet_mode
 finish_button.text="Enter hometown" if ready_view else "Party ready"
 detail_tabs.visible=not state.is_empty();roster.clear();preview_recipes={}
 if state.is_empty():updating=false;_busy();return
 var members: Array=state.party.members
 var visuals := state.duplicate(true)
 if not visuals.has("mechanics") and state.has("character_builder"):visuals.mechanics={"schema_version":1,"rules_ref":state.character_builder.rules_ref,"revision":1,"source_party_sha":RulesJson.digest(state.party),"records":state.character_builder.drafts}
 var units := CombatArt.party_units(visuals)
 for m in members:
  var r := CharacterBuilderRecords.record(state,m.character_id)
  var recipe := CombatArt.recipe("lpc",units[m.character_id],m) if units.has(m.character_id) else {}
  if not recipe.is_empty():preview_recipes[m.character_id]=recipe.recipe_hash
  var roles: Dictionary={}
  for step in r.get("advancement_history",[]):roles[step.class_id]=int(roles.get(step.class_id,0))+1
  var text := " / ".join(roles.keys().map(func(id: String):return str(RulesRecords.registry(state).definition("classes",id).name)))
  roster.add_item(m.name+"\n"+text,CombatArt.thumbnail(recipe))
  roster.set_item_tooltip(int(m.slot)-1,text+" · "+str(m.people_id)+" · "+str(m.role_id)+" narrative role")
 roster.select(selected-1)
 var m: Dictionary=members[selected-1]
 var r := CharacterBuilderRecords.record(state,m.character_id)
 var world: GameWorldTemplate=entry.world
 var home := world.get_record("burg",int(state.origin.home_burg_id))
 origin.text="Party hometown: "+str(home.name)+" · Saved identities and source-world culture retained"
 overview.text="%d / 3 reviewed"%state.get("character_builder",{}).get("confirmed",[]).size() if not ready_view else "Journey XP: %d"%CharacterBuilderRecords.xp(state,m.character_id)
 name_edit.text=m.name;pick(people_picker,m.people_id);pick(role_picker,m.role_id)
 origin_picker.clear()
 var profiles := OriginProfiles.new()
 if profiles.load_world(world):
  var rows: Array=profiles.projection.hometowns.values();rows.sort_custom(func(a: Dictionary,b: Dictionary):return str(a.name)<str(b.name))
  for row in rows:
   origin_picker.add_item(str(row.name)+" · "+str(world.get_record("state",int(row.state_id)).name));origin_picker.set_item_metadata(origin_picker.item_count-1,str(int(row.burg_id)))
 pick(origin_picker,str(int(m.origin_refs.burg_id)));_backgrounds();pick(background_picker,str(m.generated_facts.occupation_id));_heritages()
 if not r.is_empty():pick(heritage_picker,r.ancestry_ref)
 description.text=str(pack.peoples[people_picker.selected].description)
 biography.text=m.biography+"\n\nMotivation: "+AdventureRecords.foundation_label("motivation",m.generated_facts.background.motivation)+"\nPersonal origin: "+str(world.get_record("burg",int(m.origin_refs.burg_id)).name)+"\nCulture is source-world context, separate from ancestry."
 name_edit.editable=not ready_view
 for control in [people_picker,heritage_picker,role_picker,origin_picker,background_picker,reroll_button]:control.disabled=ready_view
 detail_tabs.set_tab_disabled(1,ready_view or sheet_mode)
 detail_tabs.set_tab_disabled(3,not ready_view or r.is_empty())
 if not ready_view and not r.is_empty():editor.setup(r)
 if ready_view:
  detail_tabs.current_tab=2
  var battle := AdventureService.active_battle(state)
  if battle.get("status")=="active" and battle.units.has(m.character_id):r=battle.units[m.character_id].record
  statistics.text=sheet(r,m)
  var derived := CharacterBuilderRecords.kernel(state).derive_character(r) if not r.is_empty() else {}
  live_summary.text="HP %d / %d · Defence %d\nMelee %+d · Ranged %+d"%[derived.snapshot.current_hp,derived.snapshot.stats.HP,derived.snapshot.stats.defence,derived.snapshot.stats.melee_attack,derived.snapshot.stats.ranged_attack] if derived.get("ok",false) else ""
  if not r.is_empty():advance_editor.setup(CharacterBuilderRecords.record(state,m.character_id),true)
  _advance_changed()
 else:
  identity_draft=_identity();saved_form=RulesJson.digest({"identity":identity_draft,"build":editor.definition()});_preview_changed()
 updating=false;_busy()
func _identity() -> Dictionary:
 return {"name":name_edit.text.strip_edges(),"people_id":selected_id(people_picker),"role_id":selected_id(role_picker),"origin_burg":int(selected_id(origin_picker)),"occupation_id":selected_id(background_picker)}
func _heritages() -> void:
 heritage_picker.clear()
 for id in CharacterBuilderRecords.ancestry(selected_id(people_picker),state):
  var row := RulesRecords.registry(state).definition("ancestries",id)
  var caption: String="Standard lineage · "+str(row.people_id) if id.begins_with("heritage-") else id.trim_prefix("lineage-").replace("-"," ").capitalize()
  heritage_picker.add_item(caption);heritage_picker.set_item_metadata(heritage_picker.item_count-1,id)
  heritage_picker.get_popup().set_item_tooltip(heritage_picker.item_count-1,", ".join(row.get("modifiers",[]).map(func(modifier: Dictionary):return str(modifier.stat)+" %+d (%s)"%[int(modifier.value.value),modifier.type])))
func _backgrounds() -> void:
 if entry.is_empty():return
 background_picker.clear()
 for job in CharacterBuilderRecords.backgrounds(entry.world,int(selected_id(origin_picker))):
  background_picker.add_item(str(job.get("label",job.get("key",job.id))).replace("-"," "));background_picker.set_item_metadata(background_picker.item_count-1,job.id)
func _identity_changed() -> void:
 if ready_view or state.is_empty():return
 identity_draft=_identity()
 editor.ancestry_ref=selected_id(heritage_picker);editor.refresh_preview()
 description.text=str(pack.peoples[people_picker.selected].description)
func _preview_changed() -> void:
 if state.is_empty() or ready_view:return
 if editor.preview.get("ok",false):statistics.text=sheet(editor.preview.candidate,state.party.members[selected-1])+"\n\nLIVE PREVIEW · Save this adventurer to retain these choices."
 else:statistics.text="Incomplete build: "+CharacterBuilderRecords.reason(editor.preview)
 if editor.preview.get("ok",false):
  var s: Dictionary=editor.preview.snapshot.stats
  live_summary.text="Preview HP %d · Defence %d\nMelee %+d · Ranged %+d"%[s.HP,s.defence,s.melee_attack,s.ranged_attack]
 else:live_summary.text="Incomplete build · review choices"
 if save_button!=null:_busy()
func recommend(role_id: String) -> void:
 if ready_view or state.is_empty():return
 var rec := RulesRecords.registry(state).recommendation(role_id)
 var record_value := CharacterBuilderRecords.kernel(state).create(state.party_ids[selected-1],rec.attributes,selected_id(heritage_picker))
 record_value.equipment=rec.equipment.duplicate()
 var choice := CharacterBuilderRecords.kernel(state).suggested_choice(record_value,rec["class"],rec.feat)
 var applied := CharacterBuilderRecords.kernel(state).preview_advancement(record_value,choice.choice)
 if applied.ok:editor.setup(applied.candidate);_preview_changed()
func dirty() -> bool:
 return not ready_view and not state.is_empty() and saved_form!=RulesJson.digest({"identity":_identity(),"build":editor.definition()})
func _save_changes(_regenerate: bool=false) -> void:
 if thread!=null or ready_view:return
 if state.is_empty():_start("builder_open");return
 _start("builder_save",{"before_hash":RulesJson.digest(state),"identity":_identity(),"build":editor.definition()})
func _select_member(index: int) -> void:
 if updating or thread!=null or state.is_empty():return
 if dirty():pending_selection=index+1;_save_changes()
 else:selected=index+1;refresh()
func _finish() -> void:
 if thread!=null or state.is_empty():return
 if ready_view:
  PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":expedition_cache_root}
  get_tree().change_scene_to_file("res://scenes/gameplay/expedition.tscn")
 else:_start("builder_ready",{"before_hash":RulesJson.digest(state)})
func _advance_changed() -> void:
 if state.is_empty() or not ready_view:return
 var id: String=state.party_ids[selected-1]
 var r := CharacterBuilderRecords.record(state,id)
 if r.is_empty():advancement_button.disabled=true;advancement_status.text="No saved mechanics yet. Enter the hometown and prepare your existing party first.";return
 var next: int=r.advancement_history.size()+1
 var amount := CharacterBuilderRecords.xp(state,id)
 advancement_status.text="Level %d → %d · Journey XP %d / %d required. No XP is granted here."%[next-1,next,amount,CharacterBuilderRecords.threshold(next)]
 var preview := CharacterBuilderRecords.preview_advancement(state,id,advance_editor.choice())
 advancement_button.disabled=thread!=null or not preview.get("ok",false)
 if not preview.ok:advancement_status.text+="\n"+CharacterBuilderRecords.reason(preview)
 elif advance_editor.preview.get("ok",false):advancement_status.text+="\nPreview: "+stat_line(advance_editor.preview.snapshot)+"\nReview the selected class, ranks and scheduled feat before committing."
func _commit_advancement() -> void:
 if thread!=null:return
 var id: String=state.party_ids[selected-1]
 var preview := CharacterBuilderRecords.preview_advancement(state,id,advance_editor.choice())
 if not preview.ok:message=CharacterBuilderRecords.reason(preview);_busy();return
 _start("builder_advance",{"before_hash":preview.before_hash,"candidate_hash":preview.candidate_hash,"character_id":id,"choice":preview.choice})
static func stat_line(snapshot: Dictionary) -> String:
 var s: Dictionary=snapshot.stats
 return "HP %d/%d · Defence %d · Melee %+d · Ranged %+d\nFort %+d · Reflex %+d · Will %+d · Initiative %+d\nMovement %d · Reach %d"%[snapshot.current_hp,s.HP,s.defence,s.melee_attack,s.ranged_attack,s.fortitude,s.reflex,s.will,s.initiative,s.stride,s.reach]
func sheet(r: Dictionary,m: Dictionary) -> String:
 if r.is_empty():return "Your saved identity is preserved. Enter the hometown to prepare its existing GAME-32 mechanics."
 var result := CharacterBuilderRecords.kernel(state).derive_character(r)
 if not result.ok:return CharacterBuilderRecords.reason(result)
 var s: Dictionary=result.snapshot
 var lines: Array=[m.name+" · Level "+str(s.level),stat_line(s),"\nAttributes"]
 for id in RulesExpressions.ATTRIBUTES:
  var modifier := RulesExpressions.evaluate_formula({"op":"modifier","id":id},result.context)
  lines.append("%s %d (%+d)"%[id,s.attributes[id],modifier.value])
 lines.append("\nSkills · rank / total")
 for id in s.skills:
  var skill: Dictionary=s.skills[id];lines.append("%s: %d / %+d%s"%[RulesRecords.registry(state).definition("skills",id).name,skill.ranks,skill.total," · requires training" if not skill.usable else ""])
 lines.append("\nFeats: "+", ".join(s.feats.map(func(id: String):return str(RulesRecords.registry(state).definition("feats",id).name))))
 lines.append("Equipment: "+", ".join(s.equipment.map(func(id: String):return str(RulesRecords.registry(state).definition("equipment",id).name))))
 lines.append("\nClass features: "+", ".join(s.features.map(func(id: String):return str(RulesRecords.registry(state).definition("features",id).get("name",id)))))
 lines.append("\nKnown abilities · current tactical availability")
 for id in s.abilities:
  var ability := RulesRecords.registry(state).definition("abilities",id)
  var costs: Array=[]
  for key in ["main","move","reaction"]:
   if int(ability.cost.get(key,0))>0:costs.append(str(ability.cost[key])+" "+key+" action")
  for resource in ability.cost.get("resources",{}):costs.append(str(ability.cost.resources[resource])+" "+str(resource))
  var status_text := "available in V0 combat" if id in ["attack","move","guard","spark","slow","healing-thread"] else ("automatic combat effect" if id in ["precision","departure-attack"] else "rules implemented; tactical integration belongs to GAME-33")
  lines.append(str(ability.name)+" · "+(", ".join(costs) if not costs.is_empty() else "no action cost")+" · "+status_text)
 lines.append("Preparations: "+", ".join(s.prepared_abilities))
 lines.append("\nResources")
 for id in s.resource_capacities:lines.append("%s: %d / %d"%[id,s.current_resources.get(id,0),s.resource_capacities[id]])
 lines.append("\nOrdered class history")
 for step in r.advancement_history:lines.append("Level %d: %s%s"%[step.level,RulesRecords.registry(state).definition("classes",step.class_id).name," · "+step.feat_id if not step.feat_id.is_empty() else ""])
 lines.append("Journey XP: %d · Next level requires %d total"%[CharacterBuilderRecords.xp(state,m.character_id),CharacterBuilderRecords.threshold(int(s.level)+1)])
 lines.append("\nBackground: "+str(m.generated_facts.occupation_id)+" · Narrative role: "+str(m.role_id)+"\n"+str(m.biography))
 return "\n".join(lines)
func _return_menu() -> void:
 if thread!=null:return
 if dirty():message="Save your edited adventurer before leaving, or select a saved build again.";_busy();return
 if sheet_mode:
  PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":expedition_cache_root}
 get_tree().change_scene_to_file(return_scene if sheet_mode else "res://scenes/ui/main_menu.tscn")
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):get_viewport().set_input_as_handled();_return_menu()
func _exit_tree() -> void:
 if thread!=null:thread.wait_to_finish()
