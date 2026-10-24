extends "res://tests/nature_repertoires/journey_driver.gd"
##169 ordinary paid objectives; no injected XP, records or automatic prestige.
var entry_witnesses := {}
func journey_xp() -> int:return 1690
func journey_level() -> int:return 14
func journey_cycles() -> int:return 50
func create_party() -> void:
 configs=[["duskblade","human",""],["wizard","human","archmage"],["sorcerer","human","archmage"]]
 super.create_party()
func promote(index: int) -> void:
 if not failures and index in [1,2]:
  var id: String=state.party_ids[index];var record: Dictionary=state.mechanics.records[id]
  if record.advancement_history.size()==13 and CharacterBuilderRecords.xp(state,id)>=CharacterBuilderRecords.threshold(14,state) and kernel.available_advancement(record).classes.archmage.ok:
   var decline := planned(record,str(configs[index][0]),index)
   check(decline.ok,"actual earned qualifying base-class continuation remains available")
   if decline.ok:
    var choice: Dictionary=decline.candidate.advancement_history.back().duplicate(true);choice.erase("level")
    check(CharacterBuilderRecords.preview_advancement(state,id,choice).ok,"real1690XP also funds deliberately declining prestige without committing it")
   var file: String="earned-qualified-"+str(configs[index][0])+".json"
   FileAccess.open(base.path_join(file),FileAccess.WRITE).store_string(JSON.stringify(state))
   entry_witnesses[str(configs[index][0])]={"file":file,"state_hash":RulesJson.digest(state),"character_id":id,"earned_xp":CharacterBuilderRecords.xp(state,id),"current_level":13,"next_level":14,"class_assigned":false}
 super.promote(index)
func checkpoint() -> void:
 super.checkpoint()
 var xp: int=CharacterBuilderRecords.xp(state,state.party_ids[0])
 if xp%100==0 or xp==1690:print("EARNED_HYBRID_CHECKPOINT XP=",xp," level=",state.mechanics.records[state.party_ids[0]].advancement_history.size()," failures=",failures)
 var proof := WorldOriginLore.read_json(base.path_join("proof.json"));proof.earned_entry_witnesses=entry_witnesses
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
func spell_selection(record: Dictionary) -> Dictionary:
 var d := kernel.derive_character(record)
 if not d.ok:return {"spells":[],"preparations":{}}
 var snapshot: Dictionary=d.snapshot;var copies := RulesCoreContent.starting_preparations(snapshot,source)
 var spells: Array=copies.keys()
 # Preserve every permanent spontaneous choice. Add newly unlocked upper tiers
 # first, rather than filling the finite known limit with low-tier variants.
 for id in record.choices.prepared_abilities:
  if source.definition("abilities",id).get("tags",[]).has("spontaneous") and not spells.has(id):spells.append(id)
 for cls in ["duskblade","sorcerer"]:
  if not snapshot.class_levels.has(cls):continue
  var candidates: Array=snapshot.abilities.filter(func(id: String):
   var ability := source.definition("abilities",id)
   return ability.get("casting_class")==cls and ability.tags.has("spell") and not ability.has("channel_spell") and RulesCoreContent.spell_eligible(snapshot,ability))
  candidates.sort_custom(func(a: String,b: String):
   var at: int=int(source.definition("abilities",a).spell_tier);var bt: int=int(source.definition("abilities",b).spell_tier)
   return at>bt if at!=bt else a<b)
  # The actual connected journey uses this low-tier, modest single-target strike.
  if cls=="duskblade" and candidates.has("duskblade-searing-grasp"):
   candidates.erase("duskblade-searing-grasp");candidates.push_front("duskblade-searing-grasp")
  var limit: int=RulesCoreContent.selection_limit(cls,int(snapshot.casting_levels[cls]),source)
  for id in candidates:
   if spells.has(id):continue
   if spells.filter(func(known: String):return source.definition("abilities",known).get("casting_class")==cls).size()<limit:spells.append(id)
 return {"spells":spells,"preparations":copies}
func planned(record: Dictionary,cls: String,index: int) -> Dictionary:
 var proposed := super.planned(record,cls,index)
 if not proposed.ok:return proposed
 var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level")
 if cls=="archmage":
  for key in choice.specialisations:
   if str(key).begins_with("high-arcana-"):choice.specialisations[key]="ward" if index==2 else "force"
  if choice.specialisations.has("archmage-casting"):choice.specialisations["archmage-casting"]=configs[index][0]
 if (record.advancement_history.size()+1)%4==0:choice.attribute_increase=source.definition("classes",configs[index][0]).casting_attribute
 return kernel.preview_advancement(record,choice)
func test_known_authority() -> void:
 var id: String=state.party_ids[2];var record: Dictionary=state.mechanics.records[id]
 check(kernel.derive_character(record).snapshot.class_levels.get("archmage",0)==1,"Sorcerer earned and deliberately selected Archmage1")
 check(kernel.derive_character(state.mechanics.records[state.party_ids[1]]).snapshot.class_levels.get("archmage",0)==1,"Wizard independently earned and selected Archmage1")
 var builder := CharacterBuilderService.new();builder.store=service.store;builder.library=service.library
 var raw := FileAccess.get_file_as_string(service.store._slot_path(slot))
 var result := builder.operate(entry,slot,"builder_spells",3,{"before_hash":RulesJson.digest(state),"character_id":id,"spells":[],"preparations":{}})
 check(not result.ok and FileAccess.get_file_as_string(service.store._slot_path(slot))==raw,"real writer rejects forgetting permanent Sorcerer tier7 knowledge without changing saved bytes")
 var proposed := kernel.suggested_choice(record,"archmage")
 check(proposed.ok,"further prestige remains a legal optional kernel choice")
 if proposed.ok:check(not CharacterBuilderRecords.preview_advancement(state,id,proposed.choice).ok,"class selector cannot grant next level without actual earned XP")
func test_real_combat() -> void:
 # Connected worker forks this exact campaign through the one save writer;
 # this trip only proves eligible home recovery, never awards a fixture reward.
 if cycle().results.size()==4:action("cycle_seek")
 var unfinished := -1
 for i in cycle().base.sites.size():
  if not cycle().results.has(cycle().base.sites[i].id):unfinished=i;break
 check(unfinished>=0,"unresolved genuine opportunity permits eligible return")
 if unfinished<0:return
 travel(unfinished);action("cycle_return")
 for id in state.party_ids:check(CharacterBuilderRecords.xp(state,id)==1690 and state.mechanics.records[id].advancement_history.size()==14,"actual1690 earned XP/14; no high-level fixture substitution")
