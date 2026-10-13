extends Node
var checks := 0
var failures := 0
var service := AdventureService.new()
var engine := TacticalCombat.new()
var entry := {}
var state := {}
var slot := ""
var base: String
var timings: Array=[]
var screenshots: Array=[]
var prestige_used := false
var spell_used := false
func _ready() -> void:call_deferred("run")
func check(value: bool,why: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(why)
func action(operation: String,extra: Dictionary={}) -> void:
 if failures>0:return
 var changes := {"revision":state.expedition.revision};changes.merge(extra)
 var started := Time.get_ticks_msec()
 var result := service.operate(entry,slot,operation,1,changes)
 timings.append({"operation":operation,"milliseconds":Time.get_ticks_msec()-started})
 check(result.get("ok",false),operation+": "+str(result.get("error","")))
 state=result.get("state",state)
func reject(operation: String,extra: Dictionary={}) -> void:
 var raw := FileAccess.get_file_as_string(service.store._slot_path(slot))
 var changes := {"revision":state.expedition.revision};changes.merge(extra)
 var result := service.operate(entry,slot,operation,1,changes)
 check(not result.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==raw,"rejected duplicate preserves exact bytes: "+operation)
var earned_choices: Array=[]
func cycle() -> Dictionary:return OpportunityCycles.current(state)
func campaign(start_cycles: bool=true) -> void:
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),profiles.error)
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var origin := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(origin.ok,"fresh source origin");slot=origin.state.playthrough_id
 check(service.store.save_new(slot,origin.state,entry.world).ok,"fresh save")
 action_builder("builder_open")
 var source := RulesRecords.registry(state);var kernel := RulesCharacter.new(source)
 for i in 3:
  var id: String=state.party_ids[i];var record: Dictionary=state.character_builder.drafts[id]
  var cls: String=["rogue","bard","cleric"][i]
  var choice := kernel.suggested_choice(kernel.create(id,{"INT":15,"WIS":14,"DEX":13,"STR":12,"CON":10,"CHA":8},"heritage-human"),cls,"steady-study")
  var made := kernel.create(id,{"INT":15,"WIS":14,"DEX":13,"STR":12,"CON":10,"CHA":8},"heritage-human")
  made=kernel.preview_advancement(made,choice.choice).candidate
  made.equipment=["shortblade" if i==0 else "staff"]
  var identity := {"name":["Mira","Tarin","Elara"][i],"people_id":"human","role_id":["scout","expert","adept"][i],"origin_burg":int(home.burg_id),"occupation_id":state.party.members[i].generated_facts.occupation_id}
  var jobs := CharacterBuilderRecords.backgrounds(entry.world,int(home.burg_id))
  identity.occupation_id=jobs[0].id
  action_builder("builder_save",i+1,{"identity":identity,"build":CharacterBuilderRecords.definition(made)})
 action_builder("builder_ready")
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,str(resumed.get("error","")));state=resumed.state
 check(CharacterBuilderRecords.xp(state,state.party_ids[0])==0,"fresh character, no injected XP")
 if start_cycles:action("cycle_seek")
func action_builder(operation: String,member: int=1,extra: Dictionary={}) -> void:
 var changes := {"before_hash":RulesJson.digest(state)};changes.merge(extra)
 var builder := CharacterBuilderService.new();builder.store=service.store;builder.library=service.library
 var result := builder.operate(entry,slot,operation,member,changes)
 check(result.ok,operation+": "+str(result.get("error",result.get("errors",[]))));state=result.get("state",state)
func travel(index: int) -> void:
 var site: Dictionary=cycle().base.sites[index]
 action("cycle_accept",{"lead":site.id})
 if cycle().knowledge[site.id]=="rumoured":action("cycle_scout")
 action("cycle_travel")
func earn(index: int) -> void:
 travel(index)
 if failures>0:return
 var site := SandboxRecords.site(cycle(),cycle().active.site_id)
 var choice: String="negotiate" if OpportunityGenerator.template(site.activity_id).family=="contested" else "careful"
 if OpportunityGenerator.template(site.activity_id).family=="contested" and state.mechanics.records[state.party_ids[0]].advancement_history.size()>=3:
  await fight(site)
  check(cycle().results[site.id].xp_each==(10 if cycle().results[site.id].outcome=="victory" else 0),"one authoritative combat objective reward")
 else:
  action("cycle_activity",{"choice":choice})
  check(cycle().results[site.id].xp_each==10,"genuine completed objective grants10 once")
  reject("cycle_activity",{"choice":choice})
 if not screenshots.any(func(row: Dictionary):return str(row.file).begins_with("completed-objective")):await capture("completed-objective","expedition")
 action("cycle_return")
func advance_to_prestige() -> void:
 var id: String=state.party_ids[0]
 var schedule: Array=["rogue","rogue","wizard","wizard","wizard","arcane-trickster","arcane-trickster"]
 var record: Dictionary=state.mechanics.records[id];var next: int=record.advancement_history.size()+1
 while next<=schedule.size() and CharacterBuilderRecords.xp(state,id)>=CharacterBuilderRecords.threshold(next,state):
  var kernel := RulesCharacter.new(RulesRecords.registry(state));var proposal := kernel.suggested_choice(record,schedule[next-1],"steady-study")
  var ranks: Dictionary=kernel.derive_character(record).context.skills;var points := 0
  for n in proposal.choice.skill_allocations.values():points+=int(n)
  var allocation := {};var order: Array=["stealth","arcana"]
  for skill in kernel.registry.ids("skills"):
   if not order.has(skill):order.append(skill)
  for skill in order:
   var amount := mini(points,next-int(ranks.get(skill,0)))
   if amount>0:allocation[skill]=amount;points-=amount
  proposal.choice.skill_allocations=allocation
  var preview := CharacterBuilderRecords.preview_advancement(state,id,proposal.choice)
  check(preview.ok,"earned legal advancement "+str(next)+": "+JSON.stringify(preview.get("errors",[]))+str(preview.get("error","")))
  if next==6:await capture("prestige-entry-review","sheet",3)
  action_builder("builder_advance",1,{"character_id":id,"choice":proposal.choice,"candidate_hash":preview.candidate_hash})
  var snapshot: Dictionary=kernel.derive_character(state.mechanics.records[id]).snapshot
  if snapshot.class_levels.has("wizard"):
   action_builder("builder_spells",1,{"character_id":id,"spells":RulesCoreContent.starting_preparations(snapshot,kernel.registry).keys(),"preparations":RulesCoreContent.starting_preparations(snapshot,kernel.registry)})
  earned_choices.append({"level":next,"class":schedule[next-1],"xp":CharacterBuilderRecords.xp(state,id)})
  if next==2:await capture("earned-level2-sheet","sheet",2)
  if next==6:await capture("prestige-earned-sheet","sheet",2)
  record=state.mechanics.records[id];next+=1
func run() -> void:
 base=OS.get_environment("GAME121_TEST_ROOT");DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 if OS.get_environment("GAME121_RESTART")=="1":
  var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("earned-proof.json")));slot=saved.slot
  var resumed := service.operate(entry,slot,"resume");check(resumed.ok,str(resumed.get("error","")));state=resumed.state
  check(RulesJson.digest(state)==saved.state_sha,"new process restores exact saved campaign")
  check(CharacterBuilderRecords.xp(state,state.party_ids[0])==saved.xp,"earned XP reload exact")
  check(state.mechanics.records[state.party_ids[0]].advancement_history==saved.history,"prestige/multiclass/choices reload exact")
  await capture("prestige-reloaded","sheet",2)
  finish();return
 campaign()
 if failures>0:finish();return
 await capture("new-leads","expedition")
 var identities := RulesJson.digest(state.party);var id: String=state.party_ids[0]
 for round_index in 20:
  for i in 4:
   await earn(i)
   if round_index==0 and i==0:await capture("earned-xp-home","expedition")
   if failures>0:finish();return
   await advance_to_prestige()
   if failures>0:finish();return
  if CharacterBuilderRecords.xp(state,id)>=360:break
  action("cycle_seek")
 check(CharacterBuilderRecords.xp(state,id)>=360,"sustained real earned XP beyond prestige entry")
 var snapshot: Dictionary=RulesCharacter.new(RulesRecords.registry(state)).derive_character(state.mechanics.records[id]).snapshot
 check(snapshot.class_levels.get("arcane-trickster")==2,"legitimate earned prestige and next advancement")
 check(snapshot.abilities.has("arcane-trickster-power-1"),"earned actual prestige action")
 check(RulesJson.digest(state.party)==identities,"same persistent party")
 FileAccess.open(base.path_join("earned-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"slot":slot,"state_sha":RulesJson.digest(state),"xp":CharacterBuilderRecords.xp(state,id),"history":state.mechanics.records[id].advancement_history,"cycles":state.adventure_cycles.cycles.size(),"earned_choices":earned_choices,"checks":checks,"failures":failures,"platform":OS.get_name(),"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"empty_path":OS.get_environment("PATH").is_empty(),"screenshots":screenshots,"spell_used":spell_used,"prestige_used":prestige_used},"  "))
 finish()
func finish() -> void:
 FileAccess.open(base.path_join("screenshots.json"),FileAccess.WRITE).store_string(JSON.stringify(screenshots,"  "))
 FileAccess.open(base.path_join("timings.json"),FileAccess.WRITE).store_string(JSON.stringify(timings,"  "))
 print("GAME121 EARNED ",checks," / ",failures)
 get_tree().quit(1 if failures else 0)

func capture(name: String,screen: String,tab: int=0) -> void:
 if DisplayServer.get_name()=="headless":return
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 CharacterScreen.handoff=PartyService.handoff.duplicate()
 var path: String="res://scenes/ui/character_sheet.tscn" if screen=="sheet" else "res://scenes/combat/first_adventure.tscn" if screen=="combat" else "res://scenes/gameplay/expedition.tscn"
 get_tree().change_scene_to_file(path)
 var deadline := Time.get_ticks_msec()+60000
 while get_tree().current_scene==null or get_tree().current_scene.scene_file_path!=path:await get_tree().process_frame
 var ui: Control=get_tree().current_scene
 while ui.thread!=null and Time.get_ticks_msec()<deadline:await get_tree().process_frame
 check(ui.thread==null and not ui.state.is_empty(),"actual rendered UI loaded "+name)
 ui.set_process(false)
 if screen=="sheet":
  ui.detail_tabs.current_tab=tab
  if tab==3:ui.advance_editor.set_class("arcane-trickster")
 if screen=="expedition" and name=="completed-objective":ui.selected=""
 for resolution in [Vector2i(1280,720),Vector2i(2560,1440),Vector2i(640,360)]:
  get_tree().root.size=resolution
  for frame in 4:await get_tree().process_frame
  await RenderingServer.frame_post_draw
  var folder := base.path_join("screenshots");DirAccess.make_dir_recursive_absolute(folder)
  var file := name+"-%dx%d.png"%[resolution.x,resolution.y]
  var saved := get_tree().root.get_texture().get_image().save_png(folder.path_join(file))
  check(saved==OK,"genuine Godot screenshot "+file)
  screenshots.append({"file":file,"sha256":FileAccess.get_sha256(folder.path_join(file)),"earned_xp":CharacterBuilderRecords.xp(state,state.party_ids[0]),"development_fixture":false})
 get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
 for frame in 2:await get_tree().process_frame

func fight(site: Dictionary) -> void:
 action("cycle_fight")
 engine.configure(state)
 for n in 250:
  if failures>0:return
  var b := AdventureService.active_battle(state)
  if b.status!="active":break
  var actor := engine.current(b)
  var command := engine.enemy_command(b)
  if actor.team=="party" and int(b.budget.main)>0:
   var abilities: Array=["arcane-trickster-power-1"]+actor.record.choices.prepared_abilities
   for ability in abilities:
    if not engine.characters.derive_character(actor.record).snapshot.abilities.has(ability):continue
    var available := engine.effects.validate_ability_cost(ability,actor.record.runtime,{"move":int(b.budget.move),"main":int(b.budget.main),"reaction":int(actor.reaction)})
    if not available.ok:continue
    var targets: Array=b.units.values().filter(func(unit: Dictionary):return unit.team=="enemy" and engine.eligible(b,actor,unit,ability))
    if targets.is_empty():continue
    command={"revision":b.revision,"actor_id":actor.id,"kind":ability,"target_id":targets[0].id}
    if ability=="arcane-trickster-power-1":prestige_used=true
    else:spell_used=true
    break
  var capture_power: bool=str(command.kind)=="arcane-trickster-power-1" and not screenshots.any(func(row: Dictionary):return str(row.file).begins_with("prestige-combat-effect"))
  if capture_power:await capture("prestige-combat-before","combat")
  var expected := engine.command(b,command)
  action("cycle_command",{"command":command})
  check(AdventureService.active_battle(state).state_hash==expected.battle.state_hash,"actual cycle combat equals pure command")
  if capture_power:await capture("prestige-combat-effect","combat")
 check(AdventureService.active_battle(state).status!="active","real scaled fight reaches a terminal outcome")
