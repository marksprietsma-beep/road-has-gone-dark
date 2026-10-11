extends SceneTree
var checks := 0
var failures := 0
var service := CharacterBuilderService.new()
var base := ""
var state := {}
var entry := {}
var slot := ""
var adventure := AdventureService.new()
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 base=OS.get_environment("GAME103_TEST_ROOT")
 DirAccess.make_dir_recursive_absolute(base)
 service.store.save_root=base.path_join("saves");service.library.library_root=base.path_join("library");service.library.save_root=service.store.save_root
 entry=service.library.discover()[0]
 if OS.get_environment("GAME103_PHASE")=="reload":
  var saved: Dictionary=WorldOriginLore.read_json(base.path_join("ready.json"))
  var loaded := service.store.load_save(saved.slot,entry.world)
  check(loaded.ok and RulesJson.digest(loaded.state)==saved.state_hash,"whole custom campaign survives a fresh process")
  if loaded.ok:
   for id in loaded.state.party_ids:check(CharacterBuilderRecords.kernel().derive_character(loaded.state.mechanics.records[id]).snapshot.snapshot_hash==saved.snapshots[id],"custom derived snapshot survives a fresh process")
  var legacy := CharacterBuilderService.new();legacy.store.save_root=base.path_join("legacy/saves");legacy.library.library_root=base.path_join("legacy/library")
  var metadata := WorldOriginLore.read_json(base.path_join("legacy.json"))
  var matching: Array=legacy.library.discover().filter(func(e: Dictionary):return e.world.source_sha256==metadata.world_sha)
  var reloaded := legacy.store.load_save(metadata.slot,matching[0].world)
  check(reloaded.ok and RulesJson.digest(reloaded.state)==metadata.state_hash,"earned multiclass and original rewards survive restart")
  finish();return
 var profiles := OriginProfiles.new();check(profiles.load_world(entry.world),profiles.error)
 var homes: Array=profiles.projection.hometowns.values()
 var home: Dictionary=homes[0]
 var created := service.store.create_playthrough(entry.world,int(home.state_id),int(home.burg_id),int(home.province_id))
 check(created.ok,"source origin")
 slot=created.state.playthrough_id
 check(service.store.save_new(slot,created.state,entry.world).ok,"original save")
 var opened := service.operate(entry,slot,"builder_open")
 check(opened.ok,str(opened.get("error",opened.get("errors",[]))))
 if not opened.ok:finish();return
 state=opened.state
 check(state.party.schema_version==2 and state.character_builder.confirmed.is_empty() and not state.has("mechanics"),"draft suggestions are not final mechanics")
 check(not service.operate(entry,slot,"builder_ready",1,{"before_hash":RulesJson.digest(state)}).ok,"unreviewed party cannot become ready")
 matrix()
 for i in 3:
  var id: String=state.party_ids[i]
  var def := CharacterBuilderRecords.definition(state.character_builder.drafts[id])
  var role: String=["vanguard","scout","adept"][i]
  var rec := RulesRecords.registry().recommendation(role)
  var person: String=["human","dwarf","wood-elf"][i]
  var r := CharacterBuilderRecords.kernel().create(id,rec.attributes,CharacterBuilderRecords.ancestry(person)[0])
  r.equipment=rec.equipment.duplicate()
  var choice := CharacterBuilderRecords.kernel().suggested_choice(r,rec["class"],rec.feat)
  var result := CharacterBuilderRecords.kernel().preview_advancement(r,choice.choice)
  check(result.ok,"kernel starting choice")
  def=CharacterBuilderRecords.definition(result.candidate)
  var burg: int=int(homes[i].burg_id)
  var jobs := CharacterBuilderRecords.backgrounds(entry.world,burg)
  check(not jobs.is_empty(),"origin-compatible profession choices")
  var selected := {"before_hash":RulesJson.digest(state),"identity":{"name":"Custom Adventurer %d"%i,"people_id":person,"role_id":"expert" if i==0 else role,"origin_burg":burg,"occupation_id":jobs[0].id},"build":def}
  var saved := service.operate(entry,slot,"builder_save",i+1,selected)
  check(saved.ok,str(saved.get("error",saved.get("errors",[]))))
  if not saved.ok:finish();return
  state=saved.state
  var bytes := FileAccess.get_file_as_string(service.store._slot_path(slot))
  check(not service.operate(entry,slot,"builder_save",i+1,selected).ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==bytes,"stale repeated save retains exact bytes")
 var ready := service.operate(entry,slot,"builder_ready",1,{"before_hash":RulesJson.digest(state)})
 check(ready.ok,str(ready.get("error",ready.get("errors",[]))))
 if ready.ok:
  state=ready.state
  check(state.character_builder.drafts.is_empty() and state.mechanics.records.size()==3,"one authoritative mechanics roster")
  check(state.party.members[0].origin_refs.burg_id!=state.party.members[1].origin_refs.burg_id,"independent source-backed personal origins")
  check(state.party.members[0].role_id=="expert" and state.mechanics.records[state.party_ids[0]].advancement_history[0].class_id=="roadwarden","narrative role does not dictate class")
  for id in state.party_ids:
   check(CharacterBuilderRecords.kernel().derive_character(state.mechanics.records[id]).ok,"saved derived stats")
   var choice := CharacterBuilderRecords.kernel().suggested_choice(state.mechanics.records[id],"wayfinder")
   check(not CharacterBuilderRecords.preview_advancement(state,id,choice.choice).ok,"zero XP cannot grant a level")
  journey()
  var snapshots := {}
  for id in state.party_ids:snapshots[id]=CharacterBuilderRecords.kernel().derive_character(state.mechanics.records[id]).snapshot.snapshot_hash
  FileAccess.open(base.path_join("ready.json"),FileAccess.WRITE).store_string(JSON.stringify({"slot":slot,"state_hash":RulesJson.digest(state),"world":entry.id,"snapshots":snapshots}))
  legacy_progression()
 finish()
func matrix() -> void:
 var source := RulesRecords.registry()
 var example: Dictionary=state.character_builder.drafts[state.party_ids[0]]
 var definition := CharacterBuilderRecords.definition(example)
 for ancestry_id in source.ids("ancestries"):
  var changed := definition.duplicate(true);changed.ancestry_ref=ancestry_id
  check(CharacterBuilderRecords.create(example.character_id,changed).ok,"current selectable ancestry: "+ancestry_id)
 var broken := definition.duplicate(true);broken.attributes.STR=broken.attributes.DEX
 check(not CharacterBuilderRecords.create(example.character_id,broken).ok,"illegal repeated standard-array score rejected")
 broken=definition.duplicate(true);broken.skill_allocations={"arcana":9}
 check(not CharacterBuilderRecords.create(example.character_id,broken).ok,"rank cap/budget rejected")
 broken=definition.duplicate(true);broken.equipment=["shortblade","mail","leathers"]
 check(not CharacterBuilderRecords.create(example.character_id,broken).ok,"conflicting armour rejected")
 broken=definition.duplicate(true);broken.equipment=["shield"]
 check(not CharacterBuilderRecords.create(example.character_id,broken).ok,"weaponless combat build rejected")
 broken=definition.duplicate(true);broken.prepared_abilities=["not-granted"]
 check(not CharacterBuilderRecords.create(example.character_id,broken).ok,"unknown preparation rejected")
 var base_record := CharacterBuilderRecords.kernel().create(example.character_id,source.recommendation("vanguard").attributes,"heritage-human")
 var options := CharacterBuilderRecords.kernel().preview_choices(base_record,"roadwarden",{})
 check(options.ok and not options.feat_choices["keen-focus"].ok and options.feat_choices["sentry-trained"].ok,"real casting and STR feat prerequisites")
 var choices := CharacterBuilderRecords.kernel().available_advancement(base_record)
 check(choices.classes.roadwarden.ok and choices.classes.wayfinder.ok and choices.classes["lantern-adept"].ok and not choices.classes["veil-adept"].ok,"all base classes selectable, prestige accurately locked")
 for role in ["vanguard","scout","adept"]:
  var rec := source.recommendation(role)
  var raw := CharacterBuilderRecords.kernel().create(example.character_id,rec.attributes,"heritage-orc")
  raw.equipment=rec.equipment
  var suggestion := CharacterBuilderRecords.kernel().suggested_choice(raw,rec["class"],rec.feat)
  var built := CharacterBuilderRecords.kernel().preview_advancement(raw,suggestion.choice)
  check(built.ok,"distinct working base class: "+rec["class"])
  var changed := CharacterBuilderRecords.definition(built.candidate)
  var value: int=changed.attributes.CHA;changed.attributes.CHA=changed.attributes.CON;changed.attributes.CON=value
  changed.feat_id="steady-study"
  var derived := CharacterBuilderRecords.create(example.character_id,changed)
  check(derived.ok and derived.snapshot.stats.HP!=built.snapshot.stats.HP,"legal custom allocation changes real HP")
  var unarmoured := CharacterBuilderRecords.definition(built.candidate);unarmoured.equipment=["shortblade"]
  var light := CharacterBuilderRecords.create(example.character_id,unarmoured)
  unarmoured.equipment=["shortblade","mail","shield"]
  var heavy := CharacterBuilderRecords.create(example.character_id,unarmoured)
  check(light.ok and heavy.ok and heavy.snapshot.stats.defence-light.snapshot.stats.defence==4,"equipment grants actual armour/shield defence")
 # Privileged development build: direct kernel only, no XP/save/player UI grants.
 var caster_rec := source.recommendation("adept")
 var development := CharacterBuilderRecords.kernel().create("development-prestige",caster_rec.attributes,"heritage-human")
 for level in 4:
  var suggestion := CharacterBuilderRecords.kernel().suggested_choice(development,"lantern-adept","veiled-casting" if level==2 else "steady-study")
  var built := CharacterBuilderRecords.kernel().preview_advancement(development,suggestion.choice)
  check(built.ok,"isolated legal prestige qualification fixture")
  if not built.ok:return
  development=built.candidate
 var prestige := CharacterBuilderRecords.kernel().available_advancement(development)
 check(prestige.classes["veil-adept"].ok,"earned prerequisites unlock the existing prestige class")
 var suggestion := CharacterBuilderRecords.kernel().suggested_choice(development,"veil-adept")
 var applied := CharacterBuilderRecords.kernel().preview_advancement(development,suggestion.choice)
 check(applied.ok and applied.snapshot.class_levels["veil-adept"]==1 and applied.snapshot.abilities.has("veil-echo"),"existing prestige mechanics really derive")
func action(operation: String,extra: Dictionary={}) -> void:
 var changes := {"revision":state.get("expedition",{}).get("revision",-1)};changes.merge(extra)
 var result := adventure.operate(entry,slot,operation,1,changes)
 check(result.ok,operation+": "+str(result.get("error",result.get("errors",[]))))
 if result.ok:state=result.state
func visit(site: Dictionary) -> void:
 action("sandbox_accept",{"lead":site.id})
 if state.sandbox.knowledge[site.id]=="rumoured":action("sandbox_scout")
 action("sandbox_travel")
func journey() -> void:
 adventure.store=service.store;adventure.library=service.library;adventure.cache_root=base.path_join("cache")
 SandboxAdventure.legacy_review=false
 var resumed := adventure.operate(entry,slot,"resume")
 check(resumed.ok,"created party enters real regional loop")
 if not resumed.ok:return
 state=resumed.state;action("sandbox_begin")
 check(state.sandbox.version==OpportunityGenerator.VERSION,"current GAME101 V2 preserved")
 var recovery: Dictionary=state.sandbox.base.sites.filter(func(s: Dictionary):return OpportunityGenerator.template(s.activity_id).family=="recovery")[0]
 visit(recovery);action("sandbox_activity",{"choice":"quick"});action("sandbox_return")
 check(state.sandbox.results[recovery.id].xp_each==0,"noncombat cannot finance a level")
 var site: Dictionary=state.sandbox.base.sites.filter(func(s: Dictionary):return OpportunityGenerator.template(s.activity_id).family=="contested")[0]
 visit(site);action("sandbox_fight")
 var b := AdventureService.active_battle(state)
 for id in state.party_ids:
  check(RulesJson.digest(b.units[id].record.base_attributes)==RulesJson.digest(state.mechanics.records[id].base_attributes) and RulesJson.digest(b.units[id].record.equipment)==RulesJson.digest(state.mechanics.records[id].equipment),"combat consumes player-chosen snapshot: "+id)
  var choice := CharacterBuilderRecords.kernel().suggested_choice(state.mechanics.records[id],"wayfinder")
  check(not CharacterBuilderRecords.preview_advancement(state,id,choice.choice).ok,"advancement blocked away from home")
 var engine := TacticalCombat.new()
 for step in 200:
  b=AdventureService.active_battle(state)
  if b.status!="active":break
  var command := engine.enemy_command(b);var actor := engine.current(b)
  if actor.team=="party" and int(b.budget.main)>0 and engine.characters.derive_character(actor.record).snapshot.abilities.has("spark"):
   for id in b.order:
    if engine.eligible(b,actor,b.units[id],"spark"):command.kind="spark";command.target_id=id;command.erase("destination");break
  var expected := engine.command(b,command)
  check(expected.ok and engine.command(b,command).battle.state_hash==expected.battle.state_hash,"pure combat RNG replay")
  action("sandbox_command",{"command":command})
  check(AdventureService.active_battle(state).state_hash==expected.battle.state_hash,"save owner preserves exact tactical authority")
 check(AdventureService.active_battle(state).status!="active","custom builds complete actual combat")
 action("sandbox_return")
 check(state.sandbox.active.is_empty() and service.store.load_save(slot,entry.world).ok,"player build → expedition → combat → return is durable")
func legacy_progression() -> void:
 var old: Dictionary=WorldOriginLore.read_json("res://tests/map_icons/existing-game99-save.json")
 var legacy := CharacterBuilderService.new();legacy.store.save_root=base.path_join("legacy/saves");legacy.library.library_root=base.path_join("legacy/library");legacy.library.save_root=legacy.store.save_root
 var legacy_entry: Dictionary=legacy.library.discover().filter(func(e: Dictionary):return e.world.source_sha256==old.world_ref.sha256)[0]
 DirAccess.make_dir_recursive_absolute(legacy.store.save_root)
 var path := legacy.store._slot_path(old.playthrough_id)
 var original := FileAccess.get_file_as_bytes("res://tests/map_icons/existing-game99-save.json")
 FileAccess.open(path,FileAccess.WRITE).store_buffer(original)
 var loaded := legacy.operate(legacy_entry,old.playthrough_id,"builder_open")
 check(loaded.ok and FileAccess.get_file_as_bytes(path)==original and loaded.state==old,"existing GAME99/V1 party never recreated, exact bytes unchanged")
 if not loaded.ok:return
 var id: String=old.party_ids[0]
 check(CharacterBuilderRecords.xp(old,id)==20,"legacy XP comes from two actual validated saved victories")
 var choice := CharacterBuilderRecords.kernel().suggested_choice(old.mechanics.records[id],"wayfinder")
 var preview := CharacterBuilderRecords.preview_advancement(old,id,choice.choice)
 check(preview.ok and FileAccess.get_file_as_bytes(path)==original,"earned multiclass preview does not write")
 if not preview.ok:return
 var changes := {"before_hash":preview.before_hash,"candidate_hash":preview.candidate_hash,"character_id":id,"choice":preview.choice}
 var saved := legacy.operate(legacy_entry,old.playthrough_id,"builder_advance",1,changes)
 check(saved.ok,"earned multiclass commits through existing journal")
 if not saved.ok:return
 check(saved.state.party==old.party and saved.state.sandbox==old.sandbox and saved.state.world_ref==old.world_ref and saved.state.origin==old.origin,"old identities, origins, wins/XP/sites remain untouched")
 var hash := FileAccess.get_sha256(path)
 check(not legacy.operate(legacy_entry,old.playthrough_id,"builder_advance",1,changes).ok and FileAccess.get_sha256(path)==hash,"duplicate/stale advancement cannot give another level")
 var next := CharacterBuilderRecords.kernel().suggested_choice(saved.state.mechanics.records[id],"wayfinder")
 check(not CharacterBuilderRecords.preview_advancement(saved.state,id,next.choice).ok,"20 XP cannot unlock level three")
 var bad: Dictionary=saved.state.duplicate(true);bad.character_builder.advancements[0].xp=0
 check(not legacy.store._validate(bad,legacy_entry.world).is_empty(),"unfunded persisted advancement rejected")
 FileAccess.open(base.path_join("legacy.json"),FileAccess.WRITE).store_string(JSON.stringify({"slot":old.playthrough_id,"world_sha":old.world_ref.sha256,"state_hash":RulesJson.digest(saved.state)}))
func finish() -> void:
 FileAccess.open(base.path_join("results-"+OS.get_environment("GAME103_PHASE")+".json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
 print("GAME103 builder ",checks," / ",failures)
 quit(1 if failures else 0)
