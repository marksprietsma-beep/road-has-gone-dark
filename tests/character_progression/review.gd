extends "res://tests/character_core/review.gd"
## Native production journey + isolated, labelled high-level development saves.
var advanced_saves: Array=[]
func review_build(index: int,member: int) -> void:
 await super.review_build(index,member)
 if index==0 and member==2:
  ui.detail_tabs.current_tab=1
  ui.editor.sections.current_tab=ui.editor.sections.get_tab_count()-1;await frames()
  var control: OptionButton=ui.editor.career_pickers["wizard-choice-1"]
  await click(control);await shot("game119-select-wizard-school");await key(KEY_ESCAPE)
  ui.editor.select_id(control,"abjuration");control.item_selected.emit(control.selected);await frames()
  check(ui.editor.preview.ok and ui.editor.preview.snapshot.abilities.has("wizard-abjuration-1"),"deliberate visible school applies before actual save")
  await shot("game119-selected-school-mechanics")
func journey(spec: Dictionary,index: int) -> void:
 await super.journey(spec,index)
 if index==0:await advanced_review()
func make_core(id: String,cls: String,ancestry: String) -> Dictionary:
 var source := RulesRecords.new_character_registry();var kernel := RulesCharacter.new(source)
 var r := kernel.create(id,source.recommendation("adept").attributes,ancestry)
 r.equipment=source.definition("classes",cls).recommended_equipment.duplicate()
 for n in 12:
  var result := kernel.preview_advancement(r,kernel.suggested_choice(r,cls).choice)
  check(result.ok,"development core twelve "+cls);r=result.candidate
 r.runtime.hp=kernel.derive_character(r).snapshot.stats.HP
 r.runtime.resources=kernel.derive_character(r).snapshot.resource_capacities.duplicate()
 return r
func advanced_review() -> void:
 var original: Dictionary=ui.state.duplicate(true);var entry: Dictionary=ui.entry;var library_root: String=ui.service.library.library_root;var cache_root: String=ui.service.cache_root
 var source := RulesRecords.registry(original);var kernel := RulesCharacter.new(source)
 var fixture_root := OS.get_environment("GAME119_TEST_ROOT")
 var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(fixture_root.path_join("advanced-fixtures.json")))
 for path in fixtures:
  var state := original.duplicate(true);var snapshots := {};var id: String=state.party_ids[0]
  var r: Dictionary=fixtures[path].duplicate(true);r.character_id=id;r.ancestry_ref=state.mechanics.records[id].ancestry_ref
  r.runtime.hp=kernel.derive_character(r).snapshot.stats.HP;r.runtime.resources=kernel.derive_character(r).snapshot.resource_capacities.duplicate()
  state.mechanics.records[id]=r
  for member in [1,2]:
   id=state.party_ids[member];state.mechanics.records[id]=make_core(id,"fighter" if member==1 else "wizard",state.mechanics.records[id].ancestry_ref)
  state.character_builder.advancements=[]
  for character in state.party_ids:
   state.character_builder.initial_levels[character]=state.mechanics.records[character].advancement_history.size()
   snapshots[character]=kernel.derive_character(state.mechanics.records[character]).snapshot.snapshot_hash
  var root_path := base.path_join("advanced-development-fixtures/"+path)
  var store := GamePlaythroughStore.new();store.save_root=root_path
  check(store.save_new(state.playthrough_id,state,entry.world).ok,"isolated advanced save through existing writer "+path)
  var loaded := store.load_save(state.playthrough_id,entry.world)
  check(loaded.ok and RulesJson.digest(loaded.state)==RulesJson.digest(state),"advanced save reload exactly "+path)
  check(state.sandbox==original.sandbox and state.party==original.party,"fixture keeps actual identities/consequences/earned XP "+path)
  CharacterScreen.handoff={"entry":entry,"slot":state.playthrough_id,"save_root":root_path,"library_root":library_root,"cache_root":cache_root}
  tree.change_scene_to_file("res://scenes/ui/character_sheet.tscn");await wait_scene("res://scenes/ui/character_sheet.tscn")
  ui.detail_tabs.current_tab=2;await frames()
  ui.title.text="DEVELOPMENT FIXTURE · "+path.capitalize()+" · actual earned XP unchanged"
  await shot("game119-"+path+"-advanced-sheet")
  var sheet_scroll: ScrollContainer=ui.detail_tabs.get_child(2)
  sheet_scroll.scroll_vertical=int(sheet_scroll.get_v_scroll_bar().max_value);await frames();await shot("game119-"+path+"-multiclass-history")
  ui.detail_tabs.current_tab=3;await frames()
  ui.advance_editor.set_class(path);await frames();await shot("game119-"+path+"-prestige-requirements")
  ui.advance_editor.sections.current_tab=0;await frames();await shot("game119-"+path+"-feat-choices")
  check(ui.advancement_button.disabled,"fixture never grants free production advancement XP")
  if path=="mystic-theurge":
   ui.detail_tabs.current_tab=ui.detail_tabs.get_tab_count()-1;await frames();await shot("game119-hybrid-spell-choices")
  advanced_saves.append({"path":path,"save_root":root_path,"slot":state.playthrough_id,"world_sha":entry.world.source_sha256,"library_root":library_root,"snapshots":snapshots})
  await combat_fixture(state,path)
 proof.advanced_development_saves=advanced_saves
 # This is a fixture-only rendering; no battle is committed or XP awarded.
func combat_fixture(state: Dictionary,path: String) -> void:
 var engine := TacticalCombat.new(state);var battle := engine.create(state,"game119-development-encounter")
 var actor: String=state.party_ids[0];battle.cursor=battle.order.find(actor)
 battle.units[actor].position=[0,0];battle.units[state.party_ids[1]].position=[0,1];battle.units[state.party_ids[2]].position=[0,2]
 var enemies: Array=battle.order.filter(func(id: String):return battle.units[id].team=="enemy")
 battle.units[enemies[0]].position=[1,0];battle.units[enemies[1]].position=[2,0];battle=engine.seal(battle)
 PartyService.handoff={}
 var scene: Control=load("res://scenes/combat/first_adventure.tscn").instantiate()
 tree.root.add_child(scene);tree.current_scene.queue_free();tree.current_scene=scene;ui=scene;ui.set_process(false)
 ui.state=state.duplicate(true);ui.state.first_adventure={"battle":battle};ui.engine.configure(state);ui.message="Development fixture: no gameplay XP granted or combat save committed.";ui.refresh();await frames()
 var ability: String=path+"-power-3";ui.mode=ability;ui.refresh();await frames();await shot("game119-"+path+"-combat-before")
 var command := {"actor_id":actor,"revision":battle.revision,"kind":ability,"target_id":actor if path=="mystic-theurge" else enemies[0]}
 var result := engine.command(battle,command)
 check(result.ok,"rendered original tactical authority prestige action "+path)
 if result.ok:
  ui.state.first_adventure.battle=result.battle;ui.refresh();await frames();await shot("game119-"+path+"-combat-effect")
func restart() -> void:
 # super.restart quits the process; check advanced fixtures first.
 var saved: Dictionary=WorldOriginLore.read_json(base.path_join("review-proof.json"))
 for fixture in saved.get("advanced_development_saves",[]):
  var library := GameWorldLibrary.new();library.library_root=fixture.library_root
  var entry: Dictionary=library.discover().filter(func(row: Dictionary):return row.world.source_sha256==fixture.world_sha)[0]
  var store := GamePlaythroughStore.new();store.save_root=fixture.save_root
  var loaded := store.load_save(fixture.slot,entry.world)
  check(loaded.ok,"fresh process advanced fixture load "+fixture.path)
  for id in loaded.state.party_ids:check(RulesCharacter.new(RulesRecords.registry(loaded.state)).derive_character(loaded.state.mechanics.records[id]).snapshot.snapshot_hash==fixture.snapshots[id],"advanced fresh-process history/options/spells exact")
 await super.restart()
