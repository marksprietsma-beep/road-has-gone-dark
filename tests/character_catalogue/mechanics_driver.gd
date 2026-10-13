extends Node
signal completed
var no_quit := false
var checks := 0
var failures := 0
var source: RulesRegistry
var kernel: RulesCharacter
var records := {}
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _ready() -> void:call_deferred("run")
func build(id: String,cls: String,ancestry: String="heritage-human",levels: int=1) -> Dictionary:
 var record := kernel.create(id,source.recommendation("adept").attributes,ancestry)
 for n in levels:
  var proposed := kernel.suggested_choice(record,cls)
  check(proposed.ok,"suggested "+cls)
  if not proposed.ok:return {}
  var result := kernel.preview_advancement(record,proposed.choice)
  check(result.ok,"legal "+cls+" level"+str(n+1)+" "+JSON.stringify(result.get("errors",[])))
  if not result.ok:return {}
  record=result.candidate
 return record
func run() -> void:
 source=RulesRegistry.new()
 var installed := source.load_pack("res://data/rules/trhgd-character-v11.json")
 check(installed.ok,"v10 validates: "+JSON.stringify(installed.get("errors",[])))
 if not installed.ok:get_tree().quit(1);return
 kernel=RulesCharacter.new(source)
 var history: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/character_catalogue/historical-pins.json"))
 for row in history.packs:
  var installed_rows:=RulesRecords.installed_packs().filter(func(candidate: Dictionary):return candidate.rules_ref.pack_id==row.rules_ref.pack_id)
  check(installed_rows.size()==1 and RulesJson.normalize(installed_rows[0])==RulesJson.normalize(row),"published installed pin unchanged "+str(row.rules_ref.pack_id))
  check(FileAccess.get_sha256(row.path)==history.file_hashes[row.path],"historical content bytes unchanged "+str(row.rules_ref.pack_id))
 check(RulesRecords.new_character_registry().rules_ref().pack_id==RulesRecords.NEW_PACK,"fresh normal default is latest supported pack; historical v11 tested separately")
 check(RulesCoreContent.ancestry_rows(source).size()==17,"seventeen family options")
 check(RulesCoreContent.ancestry_description(source.definition("ancestries","heritage-elf")).contains("not implemented"),"unsupported vision is never claimed as functioning battlefield mechanics")
 check(source.ids("ancestries").size()==26 and source.ids("feats").size()==40,"real content counts")
 for cls in source.ids("classes"):
  if source.definition("classes",cls).class_kind!="base":continue
  var cap: int=int(source.definition("classes",cls).max_level)
  var record := build(cls,cls,"heritage-human",cap)
  if record.is_empty():continue
  records[cls]=record
  var derived := kernel.derive_character(record)
  check(derived.ok,"derived max-level "+cls)
  if not derived.ok:continue
  check(kernel.derive_character(JSON.parse_string(JSON.stringify(record))).snapshot.snapshot_hash==derived.snapshot.snapshot_hash,"round-trip exact "+cls)
  check(not kernel.preview_advancement(record,kernel.suggested_choice(record,cls).choice).ok,"honest cap "+cls)
  if cap==20:check(derived.snapshot.abilities.has(cls+"-master-20"),"functional high progression "+cls)
  record.runtime.resources=derived.snapshot.resource_capacities.duplicate()
  record.runtime.hp=maxi(1,int(derived.snapshot.stats.HP)-20)
  # Every new granted action executes through the original effects authority.
  var target := build("target","fighter","heritage-human",12)
  for id in derived.snapshot.abilities:
   var ability := source.definition("abilities",id)
   if id in ["attack","move","departure-attack","precision"] or ability.has("trigger") or ability.tags.has("passive") or ability.tags.has("spell"):continue
   if not ability.provenance.get("revision","")=="game112-wave-one":continue
   var actor:=record.duplicate(true)
   actor.equipment=["bow"] if cls in ["scout","ranger"] else ["unarmed"] if cls=="monk" else ["shortblade"] if source.definition("classes",cls).proficiencies.has("martial") else ["staff"]
   var actual := RulesEffects.new(source).use_ability(actor,actor if ability.targeting.kind=="self" else target,id,{"main":1,"move":1,"reaction":1},RulesRng.initial("new-action:"+id))
   check(actual.ok,"actual action "+id+" "+JSON.stringify(actual.get("errors",[])))
   if not actual.ok:continue
   check(actual.budget.main==0,"main action spent "+id)
   var replay := RulesEffects.new(source).use_ability(actor,actor if ability.targeting.kind=="self" else target,id,{"main":1,"move":1,"reaction":1},RulesRng.initial("new-action:"+id))
   check(RulesJson.digest(actual)==RulesJson.digest(replay),"effect/RNG repeat "+id)
 verify_skill_frontiers()
 verify_ancestries()
 verify_resource_identities()
 verify_negatives()
 var output: String=OS.get_environment("GAME112_TEST_ROOT")
 if not output.is_empty():
  DirAccess.make_dir_recursive_absolute(output)
  var file:=FileAccess.open(output.path_join("mechanics-proof.json"),FileAccess.WRITE)
  file.store_string(JSON.stringify({"checks":checks,"failures":failures,"base_classes":records.keys(),"rules_ref":source.rules_ref()}," "))
  FileAccess.open(output.path_join("advanced-fixtures.json"),FileAccess.WRITE).store_string(JSON.stringify(records))
 print("GAME112 MECHANICS ",checks," / ",failures)
 completed.emit()
 if not no_quit:get_tree().quit(1 if failures else 0)
func verify_skill_frontiers() -> void:
 for ancestry in ["heritage-tiefling","heritage-tiefling-ash","heritage-goblin"]:
  var record:=build("int-frontier","rogue",ancestry,20)
  check(not record.is_empty() and record.advancement_history.size()==20,"high-Intelligence ancestry can spend every skill point through20 "+ancestry)
 var ranger:=kernel.create("capped-attribute",{"DEX":15,"WIS":14,"CON":13,"STR":12,"INT":10,"CHA":8},"heritage-goblin")
 for n in 20:
  var suggestion:=kernel.suggested_choice(ranger,"ranger")
  var result:=kernel.preview_advancement(ranger,suggestion.choice)
  check(result.ok,"suggestion respects inherited attribute maximum "+str(n))
  if not result.ok:break
  ranger=result.candidate
 check(ranger.advancement_history.size()==20,"high-Dexterity ancestry can complete20 without an illegal suggestion")
 var old:=RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v10.json").ok,"pushed v10 retained exactly")
 check(old.ids("skills").size()==12 and source.ids("skills").size()==14,"refinement adds real Nature/Performance without editing prior pins")
func verify_ancestries() -> void:
 for ancestry in source.ids("ancestries"):
  var record := build("ancestry:"+ancestry,"fighter",ancestry)
  if record.is_empty():continue
  var snap: Dictionary=kernel.derive_character(record).snapshot
  check(snap.ancestry.id==ancestry,"identity separate from culture/class "+ancestry)
  check(kernel.derive_character(JSON.parse_string(JSON.stringify(record))).snapshot.snapshot_hash==snap.snapshot_hash,"inherited effects reload "+ancestry)
 var resistant:=build("fireproof","fighter","heritage-tiefling")
 var attacker:=build("attacker","fighter")
 var t: Dictionary=kernel.derive_character(resistant).snapshot
 var context: Dictionary=kernel.derive_character(attacker).context
 context.target_id=resistant.character_id;context.target_stats=t.stats;context.target_capabilities=t.capabilities
 var effect := {"op":"damage","damage_type":"fire","amount":{"op":"const","value":9}}
 var result := RulesEffects.new(source).resolve_rules_effect(effect,attacker.runtime,resistant.runtime,context,RulesRng.initial("ancestry-fire"))
 check(result.ok and resistant.runtime.hp-result.target.hp==4,"fire resistance changes actual HP")
 var immune:=build("stable","fighter","heritage-hobgoblin")
 var caps: Dictionary=kernel.derive_character(immune).snapshot.capabilities
 context.target_capabilities=caps
 var status:=RulesEffects.new(source).resolve_rules_effect({"op":"apply_status","id":"off-balance"},attacker.runtime,immune.runtime,context,RulesRng.initial("ancestry-status"))
 check(status.ok and status.target.statuses.is_empty() and status.events[0].type=="status_resisted","inherited condition immunity executes")
 var steel:=build("steel","fighter","heritage-steelbound")
 steel.equipment=["shortblade","mail"]
 check(not kernel.validate_build(steel).ok,"constructed integrated body rejects armour")
 steel.equipment=["shortblade","shield"]
 check(kernel.validate_build(steel).ok,"compatible constructed equipment accepted")
func verify_resource_identities() -> void:
 var psion:=build("psychic","psion", "heritage-human",4)
 var target:=build("psychic-target","fighter","heritage-human",4)
 var fx:=RulesEffects.new(source);var budget:={"main":1,"move":1,"reaction":1};var rng:=RulesRng.initial("points")
 var used:=fx.use_ability(psion,target,"psion-technique-4",budget,rng)
 check(used.ok and used.actor.runtime.resources["psion-points"]==psion.runtime.resources["psion-points"]-2,"augmented psychic power spends shared points")
 psion.runtime.resources["psion-points"]=0
 check(not fx.use_ability(psion,target,"psion-technique-1",budget,rng).ok,"exhausted psychic resource rejects")
 var warlock:=build("invoker","warlock")
 var repeat:=fx.use_ability(warlock,target,"warlock-technique-1",budget,rng)
 check(repeat.ok and repeat.actor.runtime.resources==warlock.runtime.resources,"invocations have no spell slots/power-point expenditure")
 var warblade:=build("adept","warblade")
 warblade.runtime.resources["warblade-readiness"]=0
 check(not fx.use_ability(warblade,target,"warblade-technique-1",budget,rng).ok,"unreadied manoeuvre rejects")
 var recovery:=fx.use_ability(warblade,warblade,"warblade-recover",budget,rng)
 check(recovery.ok and recovery.actor.runtime.resources["warblade-readiness"]==2 and recovery.budget.main==0,"main-action manoeuvre recovery is distinct and bounded")
func verify_negatives() -> void:
 var data:=source.source_data()
 var cycle:=data.duplicate(true);cycle.feats[0].requirements={"op":"feat","id":cycle.feats[1].id};cycle.feats[1].requirements={"op":"feat","id":cycle.feats[0].id}
 check(not RulesRegistry.new().load_data(cycle).ok,"cyclic feat requirements reject")
 var impossible:=data.duplicate(true);impossible.classes[0].requirements={"op":"skill","id":"nature","min":21}
 check(not RulesRegistry.new().load_data(impossible).ok,"unreachable rank prerequisite rejects")
 var malformed:=data.duplicate(true);malformed.ancestries[0].capabilities={"flight":true}
 check(not RulesRegistry.new().load_data(malformed).ok,"unsupported movement cannot masquerade as a capability")
 malformed=data.duplicate(true);malformed.ancestries[0].capabilities={"immunities":["invented-condition"]}
 check(not RulesRegistry.new().load_data(malformed).ok,"missing immunity reference rejects")
 malformed=data.duplicate(true);malformed.features[0].capabilities={"concealment":101}
 check(not RulesRegistry.new().load_data(malformed).ok,"unbounded concealment rejects")
 for cls in ["shadowdancer","dragon-disciple","dwarven-defender","pyrokineticist"]:
  var record:=kernel.create("illegal:"+cls,source.recommendation("adept").attributes,"heritage-human")
  check(not kernel.preview_advancement(record,kernel.suggested_choice(record,cls).choice).ok,"real prestige prerequisites reject fresh "+cls)
