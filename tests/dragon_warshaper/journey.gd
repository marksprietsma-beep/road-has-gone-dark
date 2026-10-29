extends "res://tests/nature_repertoires/journey_driver.gd"
## Ordinary objectives, original builder/writer. Short source gate; full native careers once.
var earned_entries := {}
func full_careers() -> bool:return OS.get_environment("DRAGON_WARSHAPER_EARNED_FULL")=="1"
func configure() -> void:configs=[["sorcerer","human","dragon-disciple"],["druid","ogre","warshaper"],["wizard","elf","dragon-disciple"]]
func journey_xp() -> int:return 2280 if full_careers()else 480
func journey_level() -> int:return 16 if full_careers()else 7
func journey_cycles() -> int:return 60 if full_careers()else 16
func create_party() -> void:configure();super.create_party()
func goals_for(index: int) -> Dictionary:
 configure();return planner.requirements(configs[index][2],0)
func creation_attributes(index: int,_goals: Dictionary) -> Dictionary:
 return {"STR":8,"DEX":12,"CON":13,"INT":14,"WIS":10,"CHA":15}if index==0 else{"STR":10,"DEX":12,"CON":13,"INT":14,"WIS":15,"CHA":8}if index==1 else{"STR":8,"DEX":12,"CON":13,"INT":15,"WIS":14,"CHA":10}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var out: Dictionary=planner.advance(record,cls,goals_for(index))
 if not out.ok:return out
 var choice: Dictionary=out.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 if choice.specialisations.has("dragon-disciple-casting"):choice.specialisations["dragon-disciple-casting"]=configs[index][0]
 if choice.specialisations.has("druid-companion"):choice.specialisations["druid-companion"]="wolf"
 if (record.advancement_history.size()+1)%4==0:choice.attribute_increase=source.definition("classes",configs[index][0]).casting_attribute
 return kernel.preview_advancement(record,choice)
func spell_selection(record: Dictionary) -> Dictionary:
 var helper: Node=load("res://tests/dual_prestige_acceptance/base.gd").new();helper.source=source;helper.kernel=kernel
 var selected: Dictionary=helper.learn(record);check(helper.failures==0 and not selected.is_empty(),"original legal preparation/known-spell choices")
 helper.free()
 if selected.is_empty():return {"spells":[],"preparations":{}}
 var copies: Dictionary=selected.choices.spell_preparations.duplicate(true)
 if record.advancement_history[0].class_id=="druid":
  # Deliberately prepare one Sentinel instead of the automatic tier-one set.
  # Only selection payloads are submitted; fixture recovery is never copied.
  for id in copies.keys():
   var ability: Dictionary=source.definition("abilities",id)
   if ability.get("casting_class")=="druid"and ability.get("spell_tier")==1:copies.erase(id)
  copies["druid-summon-sentinel"]=1
  return {"spells":copies.keys(),"preparations":copies}
 return {"spells":selected.choices.prepared_abilities,"preparations":copies}
func promote(index: int) -> void:
 if failures:return
 configure();var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id];var next: int=record.advancement_history.size()+1
 if next>journey_level()or CharacterBuilderRecords.xp(state,id)<CharacterBuilderRecords.threshold(next,state):return
 var parent: String=configs[index][0];var path: String=configs[index][2];var cls: String=parent
 if kernel.available_advancement(record).classes[path].ok:
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
  var path: String=configs[index][2]
  var expected: int=(5 if index==1 else 10)if full_careers()else(2 if index==2 else 1)
  check(derived.snapshot.class_levels[path]==expected,"all advertised earned prestige levels for selected test profile")
  if index!=1:
   var parent: String=configs[index][0]
   check(derived.snapshot.casting_levels[parent]==derived.snapshot.class_levels[parent]+expected/2,"earned Dragon advances only its selected actual caster at the authored ratio")
  else:check(record.runtime.companions.values()[0].definition_id=="wolf","Ogre Warshaper keeps actual permanent Wolf identity")
  check(earned_entries.has(id),"actual funded entry/decline state saved")
  if earned_entries.has(id):check(earned_entries[id].earned_xp==earned_entries[id].required_xp and earned_entries[id].required_xp==(250 if index==2 else 360),"chosen Wizard/Sorcerer/Druid routes use their genuine distinct entry thresholds")
  var next: Dictionary=planned(record,configs[index][0],index)
  check(next.ok,"unfunded next level remains mechanically legal")
  if next.ok:
   var choice: Dictionary=next.candidate.advancement_history.back().duplicate(true);choice.erase("level")
   check(not CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"class selector cannot generate the missing next-level XP")
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
  proof.builds[id]={"role":["dragon-sorcerer","warshaper-druid","dragon-wizard"][i],"history":record.advancement_history,"choices":record.choices,"companions":record.runtime.companions,"xp":CharacterBuilderRecords.xp(state,id)}
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 if int(proof.earned_xp)%100==0 or int(proof.earned_xp)==journey_xp():print("DRAGON_WARSHAPER_EARNED ",proof.earned_xp," failures ",failures)
func finish_journey(restart := false) -> void:
 if restart:
  var proof: Dictionary=WorldOriginLore.read_json(base.path_join("proof.json"))
  for info in proof.earned_entries.values():
   var fork:=GamePlaythroughStore.new();fork.save_root=base.path_join("declined-"+str(int(info.member_index)));var loaded: Dictionary=fork.load_save(slot,entry.world)
   check(loaded.ok and info.decline_committed and RulesJson.digest(loaded.state)==info.decline_hash,"actual committed earned decline survives independent process restart")
 super.finish_journey(restart)
