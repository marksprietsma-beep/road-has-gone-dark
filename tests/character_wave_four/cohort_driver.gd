extends "res://tests/character_wave_four/mechanics_driver.gd"
## Additional cohort mechanics, backed by original ordered histories and exact restart.
var save_seeds := {}
func run() -> void:
 base=OS.get_environment("GAME112W4_TEST_ROOT").path_join("cohort")
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v14.json")
 check(loaded.ok,"expanded v14 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish();return
 kernel=RulesCharacter.new(source)
 base=OS.get_environment("GAME112W4_TEST_ROOT").path_join("cohort")
 DirAccess.make_dir_recursive_absolute(base)
 if OS.get_environment("GAME112W4_RESTART")=="1":
  var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("saved.json")))
  for id in saved.records:
   var derived := kernel.derive_character(saved.records[id])
   check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"cohort cold exact snapshot "+id)
  var recharge := use(saved.records.metamind,saved.records.metamind,"metamind-reclaim")
  check(not recharge.ok,"cold finite reserve remains exhausted")
  finish();return
 var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("GAME112W4_TEST_ROOT").path_join("saved.json")))
 fixtures=previous.records
 check(fixtures.has("beguiler") and fixtures.has("dragonfire-adept"),"new classes completed existing1–20 matrix")
 test_choice_keys();test_beguiler();test_dragon();test_paths();test_inheritances();test_additional_creatures();test_additional_feats();test_new_powers();test_starting_equipment()
 var hashes := {}
 var records := {}
 for id in ["beguiler","dragonfire-adept","war-chanter","archmage","metamind"]:
  if not fixtures.has(id):check(false,"missing cohort fixture "+id);continue
  records[id]=fixtures[id];hashes[id]=kernel.derive_character(records[id]).snapshot.snapshot_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify({"records":records,"hashes":hashes}))
 finish()
func prep(record: Dictionary,id: String) -> Dictionary:
 var result: Dictionary=record.duplicate(true)
 result.choices.prepared_abilities=[id];result.choices.spell_preparations={}
 if source.definition("abilities",id).tags.has("prepared"):result.choices.spell_preparations[id]=1
 result.runtime.resources=kernel._replay(result).context.capacities.duplicate()
 return result
func test_beguiler() -> void:
 var caster: Dictionary=fixtures.beguiler
 var target: Dictionary=build("fighter",1);target.runtime.hp=maxi(1,int(target.runtime.hp)-2)
 var schema_effects := {}
 for id in kernel.derive_character(caster).snapshot.abilities:
  var a := source.definition("abilities",id)
  if a.get("casting_class")!="beguiler":continue
  var prepared := prep(caster,id)
  var recipient: Dictionary=prepared if a.targeting.kind=="self"else target
  var cast := use_at_save(prepared,recipient,id,1)
  check(cast.ok,"executable Beguiler spell "+id+JSON.stringify(cast.get("errors",[])))
  if cast.ok:
   check(cast.budget.main==0,"spell actual action "+id)
   var pool: String="beguiler-slots-"+str(a.spell_tier)
   check(int(prepared.runtime.resources[pool])-int(cast.actor.runtime.resources[pool])==1,"spell actual tier cost "+id)
   check(RulesJson.digest(cast)==RulesJson.digest(use_at_save(prepared,recipient,id,1)),"spell replay "+id)
   check(effect_state(cast.target)!=effect_state(recipient),"spell changes actual HP or statuses "+id+JSON.stringify(cast.events))
   if a.targeting.kind=="creature":
    var resistant: Dictionary=fixtures.fighter
    var resisted := use_at_save(prepared,resistant,id,20)
    check(resisted.ok and effect_state(resisted.target)==effect_state(resistant),"successful Will save negates hostile spell "+id)
  schema_effects[RulesJson.digest(a.effects)]=true
 fixtures.beguiler=prep(caster,"beguiler-beguiling-control-1")
 check(schema_effects.size()>=14,"illusion/control repertoire has diverse actual effect bodies")
 var first := build("beguiler",1)
 var alternate: Dictionary=first.duplicate(true);alternate.advancement_history[0].specialisations["beguiler-discipline-1"]="compelling"
 check(kernel.validate_build(alternate).ok,"selectable persistent Beguiler discipline")
 check(kernel.derive_character(alternate).snapshot.stats.save_dc>kernel.derive_character(first).snapshot.stats.save_dc,"control discipline changes actual DC")
 var veiled := prep(first,"beguiler-beguiling-ward-1")
 var veil := use(veiled,veiled,"beguiler-beguiling-ward-1")
 check(veil.ok and kernel.derive_character(veil.target).snapshot.capabilities.concealment==25,"illusion has actual weapon concealment")
 check(not use(first,first,"beguiler-beguiling-control-1").ok,"unknown spell cannot execute")
func test_dragon() -> void:
 var caster: Dictionary=fixtures["dragonfire-adept"]
 var target: Dictionary=fixtures.fighter
 var cast := use(caster,target,"dragon-breath-fire")
 check(cast.ok and cast.budget.main==0 and RulesJson.digest(cast.actor.runtime.resources)==RulesJson.digest(caster.runtime.resources),"repeatable breath uses action without phantom resource "+JSON.stringify(cast.get("errors",[]))+" before="+JSON.stringify(caster.runtime.resources)+" after="+JSON.stringify(cast.get("actor",{}).get("runtime",{}).get("resources",{})))
 if cast.ok:
  var second := use(cast.actor,target,"dragon-breath-fire")
  check(second.ok,"breath repeatable on a fresh action budget")
 check(not use(caster,target,"dragon-breath-cold").ok,"unchosen element is not owned")
 var first := build("dragonfire-adept",1)
 var exhausted: Dictionary=first
 for n in 2:
  var ward := use(exhausted,exhausted,"draconic-ward-1")
  check(ward.ok,"finite invocation use "+str(n))
  if ward.ok:exhausted=ward.actor
 check(not use(exhausted,exhausted,"draconic-ward-1").ok,"invocation exhaustion enforced")
 var record: Dictionary=caster.duplicate(true)
 record.advancement_history[0].specialisations["draconic-element"]="cold"
 check(kernel.validate_build(record).ok and use(record,target,"dragon-breath-cold").ok,"cold breath is a different legal persistent build")
 var campaign := {"world_ref":{"id":"cohort"},"origin":{"home_burg_id":1},"party_ids":["a","b","c"],"party":{"members":[{"name":"Adept"},{"name":"Fighter"},{"name":"Beguiler"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":{}}}
 for pair in [["a","dragonfire-adept"],["b","fighter"],["c","beguiler"]]:
  record=fixtures[pair[1]].duplicate(true);record.character_id=pair[0];campaign.mechanics.records[pair[0]]=record
 var engine := TacticalAuras.new(campaign);var battle := engine.create(campaign,"cohort")
 var positioned := false
 for y in battle.board.height:
  for x in battle.board.width:
   var p: Array=[x,y]
   if not engine.inside(battle,p)or not engine.occupant(battle,p).is_empty()or engine.distance(battle.units.a.position,p)>4 or not engine.line_clear(battle,battle.units.a.position,p):continue
   for q in engine.neighbours(p):
    if engine.inside(battle,q)and engine.occupant(battle,q).is_empty():
     battle.units["bandit-blade"].position=p;battle.units["bandit-bow"].position=q;positioned=true;break
   if positioned:break
  if positioned:break
 check(positioned,"authored grid supports two legal burst targets")
 if not positioned:return
 battle.cursor=battle.order.find("a");battle=engine.seal(battle)
 var input := {"actor_id":"a","revision":battle.revision,"kind":"dragon-breath-fire","target_id":"bandit-blade"}
 var used := engine.command(battle,input)
 check(used.ok,"breath through frozen tactical authority")
 if not used.ok:return
 for id in ["bandit-blade","bandit-bow"]:check(int(used.battle.units[id].record.runtime.hp)<int(battle.units[id].record.runtime.hp),"burst reaches real enemy "+id)
 check(engine.validate(used.battle).is_empty(),"burst state valid")
 var replay := engine.command(JSON.parse_string(JSON.stringify(battle)),input)
 check(replay.ok and replay.battle.state_hash==used.battle.state_hash,"burst separate JSON replay/RNG")
func career_fixture(cls: String,count: int,feats: Array=[],skills: Array=[]) -> Dictionary:
 var attrs := {};var priority: Array=source.definition("classes",cls).get("attribute_priority",[])
 if priority.is_empty():
  var primary: String=source.definition("classes",cls).get("casting_attribute","")
  if primary.is_empty():primary="STR"
  priority=[primary]
  for key in ["DEX","CON","INT","WIS","CHA","STR"]:
   if not priority.has(key):priority.append(key)
 for n in 6:attrs[priority[n]]=source.rule("standard_array")[n]
 var record := kernel.create(cls,attrs,"heritage-human")
 var chosen := 0
 for n in count:
  var suggested := kernel.suggested_choice(record,cls)
  if kernel.feat_at(n+1,cls,n+1)and chosen<feats.size():
   var options := kernel.preview_choices(record,cls)
   if options.ok and options.feat_choices.get(feats[chosen],{}).get("ok",false):suggested.choice.feat_id=feats[chosen];chosen+=1
  for skill in skills:
   if n>=4 or suggested.choice.skill_allocations.has(skill):continue
   var allocation: Dictionary=suggested.choice.skill_allocations
   var first: String=str(allocation.keys()[0]);allocation[first]-=1
   if allocation[first]==0:allocation.erase(first)
   allocation[skill]=1
  var step := kernel.preview_advancement(record,suggested.choice)
  check(step.ok,"prerequisite career "+cls+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  record=step.candidate
 return record
func test_paths() -> void:
 for spec in [["war-chanter","marshal",6,["commanding-presence"],["performance"],5],["archmage","wizard",13,["spell-focus","greater-spell-focus"],[],5],["metamind","psion",8,["expanded-psychic-reserve","deep-reserve"],[],10]]:
  var record := career_fixture(spec[1],spec[2],spec[3],spec[4])
  if record.is_empty():continue
  var options := kernel.available_advancement(record)
  check(options.classes[spec[0]].ok,"genuine permanent entry "+spec[0]+JSON.stringify(options.classes[spec[0]].get("errors",[])))
  check(not kernel.derive_character(record).snapshot.class_levels.has(spec[0]),"eligibility never assigns "+spec[0])
  check(kernel.preview_advancement(record,kernel.suggested_choice(record,spec[1]).choice).ok,"can decline "+spec[0])
  var first := kernel.create("forged",record.base_attributes,record.ancestry_ref)
  check(not kernel.preview_advancement(first,kernel.suggested_choice(first,spec[0]).choice).ok,"forged initial prestige rejected "+spec[0])
  for n in spec[5]:
   var step := kernel.preview_advancement(record,kernel.suggested_choice(record,spec[0]).choice)
   check(step.ok,"chosen prestige level "+spec[0]+str(n)+JSON.stringify(step.get("errors",[])))
   if not step.ok:break
   record=step.candidate
  check(not kernel.available_advancement(record).classes[spec[0]].ok,"prestige own level cap "+spec[0])
  record.runtime.resources=kernel._replay(record).context.capacities.duplicate()
  fixtures[spec[0]]=record
 if fixtures.has("metamind"):
  var record: Dictionary=fixtures.metamind;record.runtime.resources["psychic-points"]=0
  var uses: int=record.runtime.resources["metamind-reserve"]
  for n in uses:
   var recovered := use(record,record,"metamind-reclaim")
   check(recovered.ok,"finite psychic reclaim "+str(n))
   if recovered.ok:check(recovered.actor.runtime.resources["psychic-points"]>record.runtime.resources["psychic-points"],"reclaim actual points");record=recovered.actor
  check(not use(record,record,"metamind-reclaim").ok,"reclaim cannot refund its reserve")
  fixtures.metamind=record
 if fixtures.has("archmage"):
  var record: Dictionary=fixtures.archmage
  check(kernel.derive_character(record).snapshot.casting_levels.wizard==18,"selected caster advances through all prestige levels")
  check(use(record,fixtures.fighter,"high-arcana-force-5").ok,"high arcana is an executable power")
 if fixtures.has("war-chanter"):
  var record: Dictionary=fixtures["war-chanter"]
  var active := use(record,record,"chorus-courage")
  check(active.ok,"earned path actually grants wider maintained chorus")
  if active.ok:
   var engine := TacticalAuras.new(source.rules_ref())
   var ally: Dictionary=fixtures.fighter.duplicate(true);ally.character_id="chorus-ally"
   var before: int=kernel.derive_character(ally).snapshot.stats.melee_attack
   var b := {"units":{"owner":engine.unit("owner","Chanter","party",[1,1],active.actor,"shortblade"),"ally":engine.unit("ally","Ally","party",[5,1],ally,"shortblade")},"order":["owner","ally"],"status":"active","board":{"blocked":[]}}
   RulesWaveFour.project_auras(engine,b)
   check(engine.stats(b.units.ally).melee_attack>before,"chorus truly reaches radius4 ally")
   b.units.ally.position=[6,1];RulesWaveFour.project_auras(engine,b)
   check(engine.stats(b.units.ally).melee_attack==before,"chorus excludes radius5 ally")
   var switched := use(active.actor,active.actor,"marshal-aura-assault")
   check(switched.ok and switched.actor.runtime.statuses.size()==1,"multiclass chorus replaces other maintained aura")
func test_inheritances() -> void:
 for id in ["air-genasi","earth-genasi","fire-genasi","water-genasi","air-genasi-highwind","earth-genasi-granite"]:
  var record := build("fighter",1,"heritage-"+id)
  check(not record.is_empty() and kernel.validate_build(record).ok,"inherited creation "+id)
  if record.is_empty():continue
  var people: String=source.definition("ancestries",record.ancestry_ref).people_id
  var result := use(record,record,people+"-gift")
  check(result.ok and int(result.actor.runtime.resources[people+"-inheritance"])==1,"costed inherited gift "+id)
func test_additional_creatures() -> void:
 for id in ["frost-hound","bulwark-construct"]:
  var pet := RulesEntities.creature_record("cohort:summon:"+id,id,8,source)
  check(not pet.is_empty()and kernel.validate_build(pet).ok,"real creature "+id)
  if pet.is_empty():continue
  var result := use(pet,fixtures.fighter,id+"-special")
  check(result.ok and result.budget.main==0,"actual creature action "+id)
  if result.ok:check(result.actor.runtime.resources["creature-effort"]==pet.runtime.resources["creature-effort"]-1,"creature effort spent "+id)
func test_additional_feats() -> void:
 for spec in [["dragonfire-adept","human","draconic-vigor"],["beguiler","human","beguiling-discipline"],["fighter","earth-genasi","elemental-endurance"],["fighter","air-genasi","highwind-footwork"],["fighter","fire-genasi","ember-ward"],["fighter","water-genasi","tidal-reserve"],["druid","human","devoted-bond"],["druid","human","form-reach-training"]]:
  var record := build(spec[0],4,"heritage-"+spec[1],"beast-stewardship"if spec[2]=="devoted-bond"else"steady-study")
  # Most feats are level3 choices; dedicated shape prerequisite is available at5.
  var suggestion := kernel.suggested_choice(record,spec[0],spec[2])
  var applied := kernel.preview_advancement(record,suggestion.choice)
  check(applied.ok,"additional feat selection "+spec[2]+JSON.stringify(applied.get("errors",[])))
  if not applied.ok:continue
  check(applied.snapshot.feats.has(spec[2]),"feat saved "+spec[2])
  var control: Dictionary=suggestion.choice.duplicate(true);control.feat_id="steady-study"
  var baseline := kernel.preview_advancement(record,control)
  check(baseline.ok,"feat control "+spec[2])
  if not baseline.ok:continue
  match spec[2]:
   "draconic-vigor":check(applied.snapshot.stats.HP==baseline.snapshot.stats.HP+4 and applied.snapshot.resource_capacities["draconic-resolve"]==baseline.snapshot.resource_capacities["draconic-resolve"]+1,"draconic HP/reserve effect")
   "beguiling-discipline":check(applied.snapshot.stats.save_dc>baseline.snapshot.stats.save_dc,"control save DC effect")
   "elemental-endurance":check(applied.snapshot.stats.fortitude>baseline.snapshot.stats.fortitude,"earth endurance effect")
   "highwind-footwork":check(applied.snapshot.stats.reflex>baseline.snapshot.stats.reflex and applied.snapshot.stats.initiative>baseline.snapshot.stats.initiative,"air footwork effect")
   "ember-ward":check(applied.snapshot.capabilities.resistances.fire==5 and baseline.snapshot.capabilities.resistances.fire==3,"inherited fire reduction effect")
   "tidal-reserve":check(applied.snapshot.resource_capacities["water-genasi-inheritance"]==baseline.snapshot.resource_capacities["water-genasi-inheritance"]+1,"inherited reserve effect")
   "devoted-bond":check(RulesEntities.bonds(applied.candidate,source)[0].level==RulesEntities.bonds(baseline.candidate,source)[0].level+1,"owned companion growth effect")
   "form-reach-training":
    var active := use(applied.candidate,applied.candidate,"wild-shape-leopard")
    var ordinary := use(baseline.candidate,baseline.candidate,"wild-shape-leopard")
    check(active.ok and ordinary.ok,"form feat positive/control forms")
    if active.ok and ordinary.ok:check(kernel.derive_character(active.actor).snapshot.stats.reach==kernel.derive_character(ordinary.actor).snapshot.stats.reach+1 and applied.snapshot.stats.reach==baseline.snapshot.stats.reach,"form-only reach effect")
func finish() -> void:
 DirAccess.make_dir_recursive_absolute(base)
 var name: String="restart-proof.json"if OS.get_environment("GAME112W4_RESTART")=="1"else"mechanics-proof.json"
 FileAccess.open(base.path_join(name),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true}))
 print("COHORT ",checks," / ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)

func test_choice_keys() -> void:
 var record := build("marshal",1)
 var suggestion := kernel.suggested_choice(record,"marshal")
 var allocation: Dictionary=suggestion.choice.skill_allocations
 if not allocation.has("performance"):
  var first: String=str(allocation.keys()[0]);allocation[first]-=1
  if allocation[first]==0:allocation.erase(first)
  allocation.performance=1
 var before := RulesJson.digest(suggestion.choice)
 var preview := kernel.preview_advancement(record,suggestion.choice)
 check(preview.ok,"typed StringName skill choice accepted")
 if not preview.ok:return
 var step: Dictionary=preview.candidate.advancement_history.back()
 check(RulesJson.digest(step)==RulesJson.digest(JSON.parse_string(JSON.stringify(step))),"advancement step hash stable across JSON key types")
 check(RulesJson.digest(suggestion.choice)==before,"normalisation does not mutate submitted choice")
 check(kernel.derive_character(JSON.parse_string(JSON.stringify(preview.candidate))).snapshot.snapshot_hash==preview.snapshot.snapshot_hash,"mixed-key advancement exact snapshot reload")

func effect_state(record: Dictionary) -> String:
 return RulesJson.digest({"hp":record.runtime.hp,"temporary_hp":record.runtime.temporary_hp,"statuses":record.runtime.statuses,"modifiers":record.runtime.modifiers})
func use_at_save(actor: Dictionary,target: Dictionary,id: String,roll: int) -> Dictionary:
 if not save_seeds.has(roll):
  for n in 2000:
   var rng := RulesRng.initial("cohort-save-"+str(n))
   if int(RulesRng.roll("1d20",rng).total)==roll:save_seeds[roll]=rng;break
 return RulesEffects.new(source).use_ability(actor,target,id,{"main":1,"move":1,"reaction":1},save_seeds[roll])

func test_new_powers() -> void:
 var master: Dictionary=fixtures.psion
 var target := build("fighter",1);target.runtime.hp=1
 for name in ["frost-lance","vigilant-link","severing-thought","communal-renewal","iron-carapace","void-detonation"]:
  var power := source.definition("psychic_powers","power-"+name)
  for id in power.variants:
   var record: Dictionary=master.duplicate(true)
   if not kernel.derive_character(record).snapshot.known_powers.has(power.id):record.runtime.granted_features.append(power.feature_id)
   var recipient: Dictionary=record if source.definition("abilities",id).targeting.kind=="self"else target
   var cast := use_at_save(record,recipient,id,1)
   check(cast.ok,"new psychic effect probe "+id)
   if cast.ok:
    check(effect_state(cast.target)!=effect_state(recipient),"actual psychic HP/status effect "+id)
    check(int(record.runtime.resources["psychic-points"])-int(cast.actor.runtime.resources["psychic-points"])==int(source.definition("abilities",id).cost.resources["psychic-points"]),"exact augmentation cost "+id)

func test_starting_equipment() -> void:
 var record := build("wizard",1)
 record.equipment=["staff"]
 var definition := CharacterBuilderRecords.definition(record)
 check(CharacterBuilderRecords.create(record.character_id,definition,record).ok,"normal starting gear remains legal")
 for id in source.ids("equipment"):
  var item := source.definition("equipment",id)
  if not item.tags.has("natural"):continue
  var forged: Dictionary=definition.duplicate(true);forged.equipment=[id]
  check(not CharacterBuilderRecords.create(record.character_id,forged,record).ok,"forged creature-only starting weapon rejected "+id)
  var saved: Dictionary=record.duplicate(true);saved.equipment=[id]
  check(kernel.validate_build(saved).ok,"existing candidate saved gear remains replay-compatible "+id)
  check(not RulesWaveFour.starting_equipment_allowed(item,source),"creator excludes natural gear "+id)
 var legacy := RulesRegistry.new();check(legacy.load_pack("res://data/rules/trhgd-character-v13.json").ok,"legacy gear pin")
 check(RulesWaveFour.starting_equipment_allowed(legacy.definition("equipment","nature-bite"),legacy),"historical creation policy unchanged")
 var legacy_kernel := RulesCharacter.new(legacy)
 var old := legacy_kernel.create("legacy-gear",record.base_attributes,"heritage-human")
 var old_step := legacy_kernel.preview_advancement(old,legacy_kernel.suggested_choice(old,"wizard","steady-study").choice)
 check(old_step.ok,"historical initial build")
 if old_step.ok:
  old=old_step.candidate;old.equipment=["nature-bite"]
  check(CharacterBuilderRecords.create(old.character_id,CharacterBuilderRecords.definition(old),old).ok,"historical creation acceptance preserved")
 var trog := build("fighter",1,"heritage-troglodyte")
 check(kernel.derive_character(trog).snapshot.abilities.has("troglodyte-natural-bite")and source.definition("abilities","troglodyte-natural-bite").attack_weapon=="boar-tusks","inherited natural attack remains available without equipping it")
 for id in ["frost-hound","bulwark-construct"]:
  check(kernel.validate_build(RulesEntities.creature_record("natural-test:summon:"+id,id,8,source)).ok,"actual creature retains its natural attack "+id)
