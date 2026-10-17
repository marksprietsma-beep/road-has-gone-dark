extends "res://tests/adventure_cycles/earned_driver.gd"
signal completed
var no_quit := false
var cohort := 0
var configs: Array=[]
var source: RulesRegistry
var kernel: RulesCharacter
var planner: Node
var used_skills := {}
var journeys := []
var combat_actions := {}
var failed_check := {}
func run() -> void:
 cohort=int(OS.get_environment("GAME126_COHORT"))
 base=OS.get_environment("GAME126_JOURNEY_ROOT").path_join("cohort-"+str(cohort));DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("cache")
 entry=service.library.discover()[0]
 if OS.get_environment("GAME126_COMBAT_ONLY")=="1":
  var saved := WorldOriginLore.read_json(base.path_join("proof.json"));slot=saved.slot
  var loaded := service.operate(entry,slot,"resume")
  check(loaded.ok,"load preserved earned campaign for tactical acceptance")
  state=loaded.state;source=RulesRecords.registry(state);kernel=RulesCharacter.new(source)
  journeys=saved.journeys;used_skills=saved.skills
  test_real_combat();checkpoint();finish_journey();return
 if OS.get_environment("GAME126_AUDIT_RESTART")=="1":
  var saved := WorldOriginLore.read_json(base.path_join("proof.json"));slot=saved.slot
  var loaded := service.operate(entry,slot,"resume")
  check(loaded.ok and RulesJson.digest(loaded.state)==saved.state_hash,"all three earned careers exact cold campaign restart")
  if loaded.ok:
   for id in loaded.state.party_ids:
    check(CharacterBuilderRecords.xp(loaded.state,id)==360,"earned XP exact restart "+id)
    check(loaded.state.mechanics.records[id].advancement_history.size()==7,"earned history exact restart "+id)
  if saved.get("failed_check",{}).has("hash"):
   var alternate := GamePlaythroughStore.new();alternate.save_root=base.path_join("failed-check")
   var failed := alternate.load_save(slot,entry.world)
   check(failed.ok and RulesJson.digest(failed.state)==saved.failed_check.hash,"failed trained check exact cold restart without reward")
  finish_journey(true);return
 source=RulesRecords.new_character_registry();kernel=RulesCharacter.new(source)
 planner=load("res://tests/character_completeness/prestige_driver.gd").new();planner.source=source;planner.kernel=kernel
 var groups := [
  [["fighter","human","duelist"],["rogue","catfolk","shadowdancer"],["wizard","dwarf",""]],
  [["cleric","dwarf","mystic-theurge"],["druid","elf","beast-steward"],["bard","halfling","war-chanter"]],
  [["monk","xeph",""],["duskblade","human","abjurant-champion"],["spirit-shaman","wildborn","grove-warden"]],
  [["psion","elan","pyrokineticist"],["warlock","tiefling", ""],["lurk","ratfolk","shadowdancer"]]
 ]
 configs=groups[cohort]
 if OS.get_environment("GAME126_RESUME")=="1":
  var saved := WorldOriginLore.read_json(base.path_join("proof.json"));slot=saved.slot
  var loaded := service.operate(entry,slot,"resume");check(loaded.ok,"resume existing earned fixture without rewriting history")
  state=loaded.state;used_skills=saved.skills
  for i in 3:prepare(i);promote(i)
 else:create_party()
 if failures:finish_journey();return
 for n in 12:
  if CharacterBuilderRecords.xp(state,state.party_ids[0])>=360:break
  if state.get("adventure_cycles",{}).get("cycles",[]).is_empty() or cycle().results.size()==4:action("cycle_seek")
  for i in 4:
   if cycle().results.has(cycle().base.sites[i].id):continue
   travel(i)
   if failures:finish_journey();return
   var site := SandboxRecords.site(cycle(),cycle().active.site_id)
   var options := OpportunityCycles.choices(state,site)
   test_failed_check(options)
   var before := RulesJson.digest(state)
   check(RulesJson.digest(options)==RulesJson.digest(OpportunityCycles.choices(state,site)) and before==RulesJson.digest(state),"checks deterministic without state or RNG mutation")
   var choice: String="negotiate" if OpportunityGenerator.template(site.activity_id).family=="contested" else "careful"
   var candidates: Array=options.filter(func(o: Dictionary):return o.id.begins_with("skill:") and o.outcome!="failed_check")
   candidates.sort_custom(func(a: Dictionary,b: Dictionary):return not used_skills.has(a.profession) if used_skills.has(a.profession)!=used_skills.has(b.profession) else str(a.id)<str(b.id))
   var example := {}
   if not candidates.is_empty():example=candidates[0];choice=example.id
   var xp := CharacterBuilderRecords.xp(state,state.party_ids[0])
   action("cycle_activity",{"choice":choice})
   if not example.is_empty():
    check(cycle().results[site.id].information==example.information,"selected check stored through original writer")
    used_skills[example.profession]=example
   for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==xp+10,"objective funds each actual adventurer once")
   reject("cycle_activity",{"choice":choice})
   action("cycle_return")
   for member in 3:promote(member)
   checkpoint()
   if failures:finish_journey();return
 for id in state.party_ids:
  check(CharacterBuilderRecords.xp(state,id)==360 and state.mechanics.records[id].advancement_history.size()==7,"real level7 with360 earned XP, no injection")
  var r: Dictionary=state.mechanics.records[id]
  journeys.append({"character_id":id,"ancestry":r.ancestry_ref,"history":r.advancement_history,"earned_xp":CharacterBuilderRecords.xp(state,id),"fixture":false,"rules_ref":r.rules_ref})
 test_real_combat()
 checkpoint();finish_journey()

func goals_for(index: int) -> Dictionary:
 var cfg: Array=configs[index]
 var goals: Dictionary=planner.requirements(cfg[2],1 if cfg[0]=="bard" else 0) if not str(cfg[2]).is_empty() else {"nodes":[],"feats":[]}
 # Deliberate supporting skill choices; not free ranks or unspent budgets.
 var skill: String={"fighter":"athletics","rogue":"stealth","wizard":"spellcraft","cleric":"spellcraft","druid":"animal-handling","bard":"performance","monk":"acrobatics","duskblade":"spellcraft","spirit-shaman":"animal-handling","psion":"spellcraft","warlock":"acrobatics","lurk":"stealth"}[cfg[0]]
 goals.nodes.append({"op":"skill","id":skill,"min":3})
 if cfg[2]=="mystic-theurge":goals.nodes.append({"op":"skill","id":"spellcraft","min":3})
 return goals
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 return planner.advance(record,cls,goals_for(index))
func create_party() -> void:
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),"source-backed home")
 var home: Dictionary=profiles.projection.hometowns.values()[0]
 var born := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id));slot=born.state.playthrough_id
 check(service.store.save_new(slot,born.state,entry.world).ok,"fresh ordinary save")
 action_builder("builder_open")
 check(RulesRecords.registry(state).rules_ref()==source.rules_ref(),"fresh default exact latest pin")
 for i in 3:
  var cfg: Array=configs[i];var cls: String=cfg[0];var id: String=state.party_ids[i]
  var goals := goals_for(i)
  var attrs: Dictionary=planner.attributes_for(cls,goals.nodes)
  if cfg[2]=="mystic-theurge":attrs={"STR":8,"DEX":10,"CON":13,"INT":15,"WIS":14,"CHA":12}
  var record := kernel.create(id,attrs,"heritage-"+str(cfg[1]))
  var step := planned(record,cls,i)
  check(step.ok,"lawful identity and starting class "+cls+JSON.stringify(step.get("errors",[])))
  if not step.ok:return
  record=step.candidate;record.equipment=source.definition("classes",cls).recommended_equipment.duplicate()
  var initial := spell_selection(record)
  record.choices.prepared_abilities=initial.spells;record.choices.spell_preparations=initial.preparations
  var identity := {"name":["Arin","Lysa","Doran"][i]+str(cohort),"people_id":cfg[1],"role_id":"expert","origin_burg":int(home.burg_id),"occupation_id":CharacterBuilderRecords.backgrounds(entry.world,int(home.burg_id))[0].id}
  action_builder("builder_save",i+1,{"identity":identity,"build":CharacterBuilderRecords.definition(record)})
 action_builder("builder_ready")
 for i in 3:prepare(i)
 var resumed := service.operate(entry,slot,"resume");check(resumed.ok,"ready distinct party "+str(resumed.get("error",resumed.get("errors",[]))));state=resumed.get("state",state)
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==0,"begins with no injected XP")
func spell_selection(record: Dictionary) -> Dictionary:
 var derived := kernel.derive_character(record)
 var copies := RulesCoreContent.starting_preparations(derived.snapshot,source)
 var spells: Array=copies.keys()
 # Permanent spontaneous knowledge is cumulative. Rest retrieval is explicit;
 # this fixture keeps those selections unless a newly unlocked choice fits.
 for id in record.choices.prepared_abilities:
  var ability := source.definition("abilities",id)
  var cls := source.definition("classes",str(ability.get("casting_class","")))
  if cls.get("spell_mode")=="spontaneous" and not spells.has(id):spells.append(id)
 for aid in RulesCoreContent.suggested_spells(derived.snapshot,source):
  var a := source.definition("abilities",aid);var cls: String=str(a.get("casting_class",""))
  if source.definition("classes",cls).get("spell_mode")!="spontaneous" or spells.has(aid):continue
  var count: int=spells.filter(func(id: String):return source.definition("abilities",id).get("casting_class")==cls).size()
  if count<RulesCoreContent.selection_limit(cls,int(derived.snapshot.casting_levels.get(cls,0)),source):spells.append(aid)
 return {"spells":spells,"preparations":copies}
func prepare(index: int) -> void:
 var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
 var selection := spell_selection(record)
 if selection.spells==record.choices.prepared_abilities and selection.preparations==record.choices.spell_preparations:return
 if not selection.spells.is_empty():action_builder("builder_spells",index+1,{"character_id":id,"spells":selection.spells,"preparations":selection.preparations})
func promote(index: int) -> void:
 if failures:return
 var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
 var next: int=record.advancement_history.size()+1
 if next>7 or CharacterBuilderRecords.xp(state,id)<CharacterBuilderRecords.threshold(next,state):return
 var cfg: Array=configs[index];var cls: String=cfg[0]
 if cfg[2]=="mystic-theurge" and next in [4,5,6]:cls="wizard"
 var path: String=cfg[2]
 if not path.is_empty() and kernel.available_advancement(record).classes[path].ok:
  var before := RulesJson.digest(record)
  var decline := planned(record,cls,index)
  check(decline.ok,"earned character may decline "+path)
  check(RulesJson.digest(record)==before and not kernel.derive_character(record).snapshot.class_levels.has(path) if not record.advancement_history.any(func(s: Dictionary):return s.class_id==path) else RulesJson.digest(record)==before,"qualification never automatically changes class")
  cls=path
 var proposal := planned(record,cls,index)
 check(proposal.ok,"lawful earned advancement "+cls+str(next)+JSON.stringify(proposal.get("errors",[])))
 if not proposal.ok:return
 var choice: Dictionary=proposal.candidate.advancement_history.back().duplicate(true)
 choice.erase("level")
 var preview := CharacterBuilderRecords.preview_advancement(state,id,choice)
 check(preview.ok,"original XP authority accepts funded manual choice "+JSON.stringify(preview.get("errors",[]))+str(preview.get("error","")))
 if preview.ok:action_builder("builder_advance",index+1,{"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
 prepare(index)
func test_real_combat() -> void:
 var tactical := TacticalAuras.new(state);var battle := tactical.create(state,"game126-earned-cohort-"+str(cohort))
 for n in 180:
  if battle.status!="active":break
  var actor := tactical.current(battle)
  var command := tactical.enemy_command(battle)
  if actor.team=="party" and int(battle.budget.main)>0:
   var available: Array=tactical.characters.derive_character(actor.record).snapshot.abilities
   for aid in available:
    var a := source.definition("abilities",aid)
    if source.rule("base_abilities").has(aid) or int(a.cost.main)<1:continue
    if a.tags.has("passive") or a.has("trigger") or a.tags.has("weapon_strike") or a.has("channel_spell"):continue
    var targets: Array=battle.units.values().filter(func(u: Dictionary):return tactical.eligible(battle,actor,u,aid))
    if targets.is_empty():continue
    var proposed := {"actor_id":actor.id,"revision":battle.revision,"kind":aid,"target_id":targets[0].id}
    if tactical.command(battle,proposed).ok:command=proposed;break
  var result := tactical.command(battle,command)
  check(result.ok,"production tactical command "+str(command.kind))
  if not result.ok:return
  check(result.battle.state_hash==tactical.command(battle,command).battle.state_hash,"exact tactical replay/RNG")
  if actor.team=="party" and command.kind not in ["move","end"]:combat_actions[actor.id]=str(command.kind)
  battle=result.battle
  if combat_actions.size()==3:break
 check(combat_actions.size()==3,"all three earned identities act in real tactical authority")
 FileAccess.open(base.path_join("combat.json"),FileAccess.WRITE).store_string(JSON.stringify(battle))
func checkpoint() -> void:
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"slot":slot,"state_hash":RulesJson.digest(state),"rules_ref":source.rules_ref(),"earned_xp":CharacterBuilderRecords.xp(state,state.party_ids[0]),"xp_injected":false,"journeys":journeys,"skills":used_skills,"combat_actions":combat_actions,"failed_check":failed_check}))
func finish_journey(restart := false) -> void:
 if restart:FileAccess.open(base.path_join("restart-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
 print("COMPLETENESS JOURNEY ",cohort," ",checks," failures ",failures)
 if is_instance_valid(planner):planner.free()
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)

func test_failed_check(options: Array) -> void:
 if not failed_check.is_empty():return
 var ids := ["skill:athletics","skill:stealth","skill:acrobatics","skill:spellcraft","skill:animal-handling"]
 var failed: Array=options.filter(func(o: Dictionary):return o.outcome=="failed_check" and ids.has(o.profession))
 if failed.is_empty():return
 var alternate := AdventureService.new();alternate.store.save_root=base.path_join("failed-check");alternate.library=service.library;alternate.cache_root=service.cache_root
 var before := RulesJson.digest(state)
 check(alternate.store.save_new(slot,state,entry.world).ok,"fork uses original save owner for negative outcome")
 var result := alternate.operate(entry,slot,"cycle_activity",1,{"revision":state.expedition.revision,"choice":failed[0].id})
 check(result.ok,"real failed trained check commits through original campaign writer")
 if result.ok:
  for id in state.party_ids:check(CharacterBuilderRecords.xp(result.state,id)==CharacterBuilderRecords.xp(state,id),"failed trained check grants no XP")
  check(OpportunityCycles.current(result.state).results[cycle().active.site_id].outcome=="failed_check","failure visibly persists")
  failed_check={"hash":RulesJson.digest(result.state),"choice":failed[0].id,"xp":CharacterBuilderRecords.xp(result.state,state.party_ids[0])}
 check(RulesJson.digest(state)==before,"negative fixture never alters main earned journey")
