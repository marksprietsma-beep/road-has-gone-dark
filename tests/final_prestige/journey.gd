extends "res://tests/nature_repertoires/journey_driver.gd"
## Ordinary objectives, original builder/writer. Short source gate; full native careers once.
var earned_entries := {}
func full_careers() -> bool:return OS.get_environment("FINAL_PRESTIGE_EARNED_FULL")=="1"
func configure() -> void:configs=[["wizard","human","eldritch-knight"],["rogue","human","shadowdancer"],["fighter","dwarf","dwarven-defender"]]
func journey_xp() -> int:return 1960 if full_careers()else 810
func journey_level() -> int:return 15 if full_careers()else 10
func journey_cycles() -> int:return 50 if full_careers()else 21
func create_party() -> void:configure();super.create_party()
func goals_for(index: int) -> Dictionary:
 configure();return planner.requirements(configs[index][2],0)
func creation_attributes(index: int,_goals: Dictionary) -> Dictionary:
 return {"STR":8,"DEX":12,"CON":13,"INT":15,"WIS":14,"CHA":10}if index==0 else {"STR":10,"DEX":15,"CON":13,"INT":14,"WIS":12,"CHA":8}if index==1 else {"STR":10,"DEX":14,"CON":13,"INT":15,"WIS":12,"CHA":8}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var out: Dictionary=planner.advance(record,cls,goals_for(index))
 if not out.ok:return out
 var choice: Dictionary=out.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 if choice.specialisations.has("eldritch-knight-arcane"):choice.specialisations["eldritch-knight-arcane"]="wizard"
 if choice.specialisations.has("eldritch-channel-3"):choice.specialisations["eldritch-channel-3"]="wizard-enfeeble"
 if choice.specialisations.has("eldritch-channel-5"):choice.specialisations["eldritch-channel-5"]="battle-reserve"
 if (record.advancement_history.size()+1)%4==0:choice.attribute_increase="INT"if index==0 else"DEX"if index==1 else"STR"
 var helper: Node=load("res://tests/final_prestige/mechanics.gd").new();helper.source=source;helper.kernel=kernel
 choice=helper.align_skills(record,choice);check(helper.failures==0,"selected attribute uses actual legal skill budget");helper.free()
 return kernel.preview_advancement(record,choice)
func spell_selection(record: Dictionary) -> Dictionary:
 var helper: Node=load("res://tests/dual_prestige_acceptance/base.gd").new();helper.source=source;helper.kernel=kernel
 var selected: Dictionary=helper.learn(record);check(helper.failures==0 and not selected.is_empty(),"original legal preparation/known-spell choices");helper.free()
 if selected.is_empty():return {"spells":[],"preparations":{}}
 var copies: Dictionary=selected.choices.spell_preparations.duplicate(true)
 if kernel.derive_character(record).snapshot.abilities.has("wizard-enfeeble"):
  for id in copies.keys():
   var ability: Dictionary=source.definition("abilities",id)
   if ability.get("casting_class")=="wizard"and ability.get("spell_tier")==1:copies.erase(id)
  copies["wizard-enfeeble"]=1
 return {"spells":copies.keys(),"preparations":copies}
func promote(index: int) -> void:
 if failures:return
 configure();var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id];var next: int=record.advancement_history.size()+1
 if next>journey_level()or CharacterBuilderRecords.xp(state,id)<CharacterBuilderRecords.threshold(next,state):return
 var parent: String=configs[index][0];var path: String=configs[index][2];var cls: String=parent
 if index==0 and next in [6,7]:cls="fighter"
 if kernel.available_advancement(record).classes[path].ok and int(kernel.derive_character(record).snapshot.class_levels.get(path,0))<int(source.definition("classes",path).max_level):
  var before: String=RulesJson.digest(state)
  if not record.advancement_history.any(func(s: Dictionary):return s.class_id==path):
   var alternatives: Dictionary={}
   for option in [parent,path]:
    var preview: Dictionary=planned(record,option,index);check(preview.ok,"earned legal parent/prestige alternative "+option)
    if not preview.ok:continue
    var choice: Dictionary=preview.candidate.advancement_history.back().duplicate(true);choice.erase("level")
    var funded: Dictionary=CharacterBuilderRecords.preview_advancement(state,id,choice)
    check(funded.ok,"single XP authority funds explicit option "+option);alternatives[option]=funded.ok
   check(before==RulesJson.digest(state),"qualification and previews generate neither XP nor levels")
   earned_entries[id]={"member_index":index,"character_id":id,"path":path,"parent":parent,"earned_xp":CharacterBuilderRecords.xp(state,id),"required_xp":CharacterBuilderRecords.threshold(next,state),"original_history":record.advancement_history,"alternatives":alternatives,"state_hash":before}
   FileAccess.open(base.path_join("earned-entry-"+str(index)+".json"),FileAccess.WRITE).store_string(JSON.stringify(state))
   var decline: Dictionary=planned(record,parent,index);var choice: Dictionary=decline.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   var preview: Dictionary=CharacterBuilderRecords.preview_advancement(state,id,choice)
   var fork:=GamePlaythroughStore.new();fork.save_root=base.path_join("declined-"+str(index));check(fork.save_new(slot,state,entry.world).ok,"genuine earned decline fork uses original writer")
   var builder:=CharacterBuilderService.new();builder.store=fork;builder.library=service.library
   var result: Dictionary=builder.operate(entry,slot,"builder_advance",index+1,{"before_hash":before,"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
   check(result.ok,"qualified player actually commits decline through production service")
   if result.ok:
    var reloaded: Dictionary=fork.load_save(slot,entry.world)
    check(reloaded.ok and not reloaded.state.mechanics.records[id].advancement_history.any(func(s: Dictionary):return s.class_id==path)and CharacterBuilderRecords.xp(reloaded.state,id)==earned_entries[id].earned_xp,"decline retains identity/earned XP and does not assign prestige")
    earned_entries[id].decline_committed=true;earned_entries[id].decline_hash=RulesJson.digest(reloaded.state)
   check(before==RulesJson.digest(state),"independent committed decline never edits primary choice")
  cls=path
 var proposed: Dictionary=planned(record,cls,index);check(proposed.ok,"actual funded career step "+cls+str(next)+JSON.stringify(proposed.get("errors",[])))
 if not proposed.ok:return
 var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 var preview: Dictionary=CharacterBuilderRecords.preview_advancement(state,id,choice)
 check(preview.ok,"XP authority accepts manual level commitment")
 if preview.ok:action_builder("builder_advance",index+1,{"character_id":id,"choice":choice,"candidate_hash":preview.candidate_hash})
 prepare(index)
func test_known_authority() -> void:
 for index in 3:
  var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id];var derived: Dictionary=kernel.derive_character(record)
  check(derived.ok and record.advancement_history.size()==journey_level()and CharacterBuilderRecords.xp(state,id)==journey_xp(),"actual earned career level and XP, no developer grant")
  var path: String=configs[index][2];var expected: int=(5 if index==0 else 10)if full_careers()else(3 if index==0 else 5)
  check(derived.snapshot.class_levels[path]==expected,"complete intended earned prestige track for selected test profile")
  if index==0:check(derived.snapshot.casting_levels.wizard==derived.snapshot.class_levels.wizard+expected,"Knight advances only its existing selected Wizard parent")
  check(earned_entries.has(id),"actual funded entry/decline state saved")
  if earned_entries.has(id):check(earned_entries[id].earned_xp==earned_entries[id].required_xp and earned_entries[id].required_xp==(490 if index==0 else 250),"distinct actual permanent entry thresholds")
  var next: Dictionary=planned(record,configs[index][0],index);check(next.ok,"unfunded next level remains mechanically legal")
  if next.ok:
   var choice: Dictionary=next.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   check(not CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"class selector cannot generate missing next-level XP")
func test_real_combat() -> void:
 # Connected real attacks/cold resolution are a separate phase, not edited state.
 var xp: int=CharacterBuilderRecords.xp(state,state.party_ids[0])
 if cycle().results.size()==4:action("cycle_seek")
 var index := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):index=i;break
 check(index>=0,"genuine unresolved trip exists for eligible home recovery")
 if index>=0:travel(index);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==xp and xp==journey_xp(),"recovery trip grants no XP and preserves earned career")
func checkpoint() -> void:
 super.checkpoint()
 var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"));proof.earned_entries=earned_entries;proof.builds={};proof.full_careers=full_careers()
 for i in state.party_ids.size():
  var id: String=state.party_ids[i];var record: Dictionary=state.mechanics.records[id]
  proof.builds[id]={"role":["wizard-knight","rogue-shadow","dwarf-defender"][i],"history":record.advancement_history,"choices":record.choices,"companions":record.runtime.companions,"xp":CharacterBuilderRecords.xp(state,id)}
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 if int(proof.earned_xp)%100==0 or int(proof.earned_xp)==journey_xp():print("FINAL_PRESTIGE_EARNED ",proof.earned_xp," failures ",failures)
func finish_journey(restart := false) -> void:
 if restart:
  var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"))
  for info in proof.earned_entries.values():
   var fork:=GamePlaythroughStore.new();fork.save_root=base.path_join("declined-"+str(int(info.member_index)));var loaded: Dictionary=fork.load_save(slot,entry.world)
   check(loaded.ok and info.decline_committed and RulesJson.digest(loaded.state)==info.decline_hash,"actual committed earned decline survives independent process restart")
 super.finish_journey(restart)
