extends "res://tests/character_psychic/journey_driver.gd"
## Real production renders and selector input, from writer-owned labelled fixtures.
func run() -> void:
 base=OS.get_environment("GAME112W3_CAPTURE_ROOT")
 DirAccess.make_dir_recursive_absolute(base)
 var source_root := OS.get_environment("GAME112W3_SOURCE_ROOT").path_join("journey")
 var proof: Dictionary=WorldOriginLore.read_json(source_root.path_join("proof.json"));slot=proof.slot
 service.library.library_root=source_root.path_join("library");entry=service.library.discover()[0]
 service.cache_root=base.path_join("cache");service.store.save_root=base.path_join("fresh-creator");service.library.save_root=service.store.save_root
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"existing source-world profiles")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 var review_slot: String=slot;slot=born.state.playthrough_id
 check(service.store.save_new(slot,born.state,entry.world).ok,"normal fresh creator fixture")
 action_builder("builder_open")
 var ui := await open_screen("res://scenes/ui/party_creation.tscn")
 if ui==null:finish();return
 ui.editor.set_class("ardent");ui._identity_changed();ui.detail_tabs.current_tab=1
 for i in ui.editor.sections.get_tab_count():
  if ui.editor.sections.get_tab_title(i)=="Specialisation":ui.editor.sections.current_tab=i
 await screenshot("ardent-mantle-selection",false)
 for i in ui.editor.sections.get_tab_count():
  if ui.editor.sections.get_tab_title(i)=="Powers":ui.editor.sections.current_tab=i
 check(ui.editor.preview.ok,"creator mantle/power defaults are legal")
 await screenshot("ardent-power-selection",false)
 ui.editor.set_class("psion");ui._identity_changed();ui.detail_tabs.current_tab=1
 for i in ui.editor.sections.get_tab_count():
  if ui.editor.sections.get_tab_title(i)=="Powers":ui.editor.sections.current_tab=i
 check(ui.editor.preview.ok,"creator distinct Psion power controls")
 await screenshot("psion-power-selection",false)
 await close_screen()
 if OS.get_environment("GAME112W3_CREATOR_ONLY")=="1":finish();return
 slot=review_slot
 var source := RulesRecords.new_character_registry()
 var worker: Node=load("res://tests/character_psychic/mechanics_driver.gd").new()
 worker.source=source;worker.kernel=RulesCharacter.new(source);worker.test_prestige()
 check(worker.failures==0,"authentic prerequisite fixtures")
 var prestige: Dictionary=worker.advanced_examples.duplicate(true);worker.free()
 for path in ["psion-offence","psion-control","ardent","lurk","druid","boar-companion","beast-steward","cerebremancer"]:
  var input_root := source_root.path_join("development-"+("druid" if path in ["beast-steward","boar-companion"] else "psion-offence" if path=="cerebremancer" else path))
  var store := GamePlaythroughStore.new();store.save_root=input_root
  var loaded := store.load_save(slot,entry.world);check(loaded.ok,"saved development history "+path)
  if not loaded.ok:finish();return
  state=loaded.state
  var actor_id: String=state.party_ids[0]
  if prestige.has(path):
   var record: Dictionary=prestige[path].duplicate(true);var original_id: String=record.character_id
   record.character_id=actor_id
   if not record.runtime.companions.is_empty():
    var pet: Dictionary=record.runtime.companions[original_id+":companion"]
    pet.record.character_id=actor_id+":companion";record.runtime.companions={actor_id+":companion":pet}
   state.mechanics.records[actor_id]=record;state.character_builder.initial_levels[actor_id]=record.advancement_history.size()
  var record: Dictionary=state.mechanics.records[actor_id]
  if path=="psion-offence":record.advancement_history.back().specialisations["psion-power-12"]="power-astral-guardian"
  if path=="boar-companion":
   record.advancement_history[0].specialisations["druid-companion"]="boar"
   check(RulesEntities.synchronize(record,source).ok,"legal chosen boar companion")
  record.equipment=["shortblade","leathers"] if path=="lurk" else ["staff"]
  var kernel := RulesCharacter.new(source)
  record.runtime.hp=int(kernel.derive_character(record).snapshot.stats.HP);record.runtime.resources=kernel._replay(record).context.capacities.duplicate()
  service.store.save_root=base.path_join("fixtures/"+path);service.library.save_root=service.store.save_root
  check(service.store.save_new(slot,state,entry.world).ok,"original writer saves valid labelled history "+path)
  await advanced_capture(state,service.store.save_root,path)
  if path in ["psion-control","ardent","cerebremancer"]:continue
  action("cycle_seek")
  var found := false
  for i in 4:
   if OpportunityGenerator.template(cycle().base.sites[i].activity_id).family!="contested":continue
   travel(i);action("cycle_fight");found=true;break
  check(found,"real generated encounter for fixture "+path)
  engine.configure(state)
  for n in 40:
   var battle := AdventureService.active_battle(state)
   if engine.current(battle).id==actor_id:break
   var command := engine.enemy_command(battle) if engine.current(battle).team=="enemy" else {"actor_id":engine.current(battle).id,"revision":battle.revision,"kind":"end"}
   action("cycle_command",{"command":command})
  if path=="psion-offence":await selector_evidence(actor_id)
  elif path=="lurk":
   issue_saved("lurk-veil",actor_id);await capture("lurk-veil-active","combat")
   for n in 50:
    var battle := AdventureService.active_battle(state);var actor := engine.current(battle)
    var targets: Array=battle.units.values().filter(func(target: Dictionary):return target.team=="enemy" and engine.eligible(battle,actor,target,"lurk-psychic-ambush"))
    if actor.id==actor_id and int(battle.budget.main)>0 and not targets.is_empty():issue_saved("lurk-psychic-ambush",targets[0].id);break
    var command := engine.enemy_command(battle) if actor.id==actor_id or actor.team=="enemy" else {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
    action("cycle_command",{"command":command})
   await capture("lurk-ambush-resolved","combat")
  else:
   var battle := AdventureService.active_battle(state)
   var pet_id := actor_id+":companion"
   if path=="druid":
    issue_saved("wild-shape-leopard",actor_id);await capture("leopard-form-active","combat")
    await owner_next_turn(actor_id);issue_saved("wild-shape-boar",actor_id);await capture("boar-form-active","combat")
   elif path=="beast-steward":
    issue_saved("steward-rally",pet_id);await capture("prestige-companion-rally","combat")
   await owner_next_turn(pet_id)
   if path=="boar-companion":
    issue_saved("boar-special",pet_id);await capture("boar-companion-guarding","combat");continue
   battle=AdventureService.active_battle(state)
   var actor := engine.current(battle);var command := engine.enemy_command(battle)
   if command.kind=="move":action("cycle_command",{"command":command})
   battle=AdventureService.active_battle(state);actor=engine.current(battle)
   var targets: Array=battle.units.values().filter(func(target: Dictionary):return target.team=="enemy" and engine.eligible(battle,actor,target,actor.entity.definition_id+"-special"))
   if not targets.is_empty():issue_saved(actor.entity.definition_id+"-special",targets[0].id);await capture("companion-special-action-"+path,"combat")
 if failures==0:
  FileAccess.open(base.path_join("render-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source_commit":OS.get_environment("GAME112W3_SOURCE_SHA"),"screenshots":screenshots,"rules_ref":source.rules_ref(),"fixtures_are_earned":false}))
 finish()
func open_screen(path: String) -> Control:
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 CharacterScreen.handoff=PartyService.handoff.duplicate()
 get_tree().change_scene_to_file(path)
 while get_tree().current_scene==null or get_tree().current_scene.scene_file_path!=path:await get_tree().process_frame
 var ui: Control=get_tree().current_scene
 var deadline := Time.get_ticks_msec()+60000
 while (ui.thread!=null or ui.state.is_empty()) and Time.get_ticks_msec()<deadline:await get_tree().process_frame
 check(ui.thread==null and not ui.state.is_empty(),"actual production scene ready")
 if ui.thread!=null or ui.state.is_empty():return null
 ui.set_process(false);return ui
func close_screen() -> void:
 get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
 for n in 3:await get_tree().process_frame
func selector_evidence(actor_id: String) -> void:
 var ui := await open_screen("res://scenes/combat/first_adventure.tscn")
 if ui==null:return
 var before := RulesJson.digest(ui.state)
 var picker: OptionButton=ui.find_child("PsychicPowerSelector",true,false)
 check(picker!=null,"visible learned-power selector")
 if picker==null:return
 for i in picker.item_count:
  if picker.get_item_metadata(i)=="power-force-screen":picker.select(i);picker.item_selected.emit(i);break
 var augmentation: OptionButton=ui.find_child("PsychicAugmentationSelector",true,false)
 for i in augmentation.item_count:
  if augmentation.get_item_metadata(i)=="power-force-screen-aug2":augmentation.select(i);augmentation.item_selected.emit(i);break
 check(ui.mode=="power-force-screen-aug2","selector updates actual targeting mode to the shown augmentation")
 check(RulesJson.digest(ui.state)==before,"selector changes no battle state, saved resources or RNG")
 ui.title.text="DEVELOPMENT FIXTURE · augmented power selection"
 await screenshot("power-selector-augmentation-input",true)
 await close_screen()
 var battle := AdventureService.active_battle(state)
 var target: String=state.party_ids[1]
 issue_saved("power-force-screen-aug2",target)
 check(int(AdventureService.active_battle(state).units[target].record.runtime.temporary_hp)==7,"selected augmented barrier really grants seven temporary HP")
 await capture("augmented-barrier-applied","combat")
 await owner_next_turn(actor_id);issue_saved("power-astral-guardian-aug2",actor_id)
 var summoned := AdventureService.active_battle(state);var pet_id := actor_id+":summon:"+str(int(summoned.revision)-1)
 check(summoned.units.has(pet_id) and summoned.units[pet_id].entity.remaining==4,"actual augmented summon duration")
 await capture("psychic-summon-cost-and-lifetime","combat")
 action("cycle_command",{"command":{"actor_id":actor_id,"revision":summoned.revision,"kind":"end"}})
 check(engine.current(AdventureService.active_battle(state)).id==pet_id,"temporary summon receives the next ordinary turn")
 await capture("psychic-summon-owned-turn","combat")
 for n in 80:
  var current := AdventureService.active_battle(state)
  if not engine.alive(current.units[pet_id]):break
  var actor := engine.current(current)
  var command := engine.enemy_command(current) if actor.team=="enemy" else {"actor_id":actor.id,"revision":current.revision,"kind":"end"}
  action("cycle_command",{"command":command})
 check(not engine.alive(AdventureService.active_battle(state).units[pet_id]),"summon expires through real saved round boundaries")
 await capture("psychic-summon-expired","combat")
func issue_saved(kind: String,target_id: String) -> void:
 var battle := AdventureService.active_battle(state)
 action("cycle_command",{"command":{"actor_id":engine.current(battle).id,"revision":battle.revision,"kind":kind,"target_id":target_id}})
func owner_next_turn(owner_id: String) -> void:
 for n in 60:
  var battle := AdventureService.active_battle(state);var actor := engine.current(battle)
  if actor.id==owner_id and int(battle.budget.main)>0:return
  var command := engine.enemy_command(battle) if actor.team=="enemy" else {"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
  action("cycle_command",{"command":command})
 check(false,"living owned actor receives a next turn")
func screenshot(name: String,development: bool) -> void:
 if name in ["ardent-power-selection","psion-power-selection","ardent-mantle-selection"]:
  var ui: Control=get_tree().current_scene
  var group: String="ardent-mantle" if name=="ardent-mantle-selection" else "ardent-power-1" if name=="ardent-power-selection" else "psion-power-1"
  var control: Control=ui.editor.career_pickers[group]
  control.grab_focus()
  var outer: ScrollContainer=ui.detail_tabs.get_child(1)
  outer.ensure_control_visible(control)
  for n in 4:await get_tree().process_frame
 if development or service.store.save_root.contains("fixtures/"):
  if get_tree().current_scene!=null and get_tree().current_scene.get("title") is Label and not get_tree().current_scene.title.text.begins_with("DEVELOPMENT FIXTURE"):get_tree().current_scene.title.text="DEVELOPMENT FIXTURE · XP not granted · "+get_tree().current_scene.title.text
 await super.screenshot(name,development or service.store.save_root.contains("fixtures/"))
