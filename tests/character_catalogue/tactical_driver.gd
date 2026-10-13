extends "res://tests/character_catalogue/mechanics_driver.gd"
var advanced := {}
func run() -> void:
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v10.json").ok,"new tactical pack")
 kernel=RulesCharacter.new(source)
 for path in ["shadowdancer","dragon-disciple","dwarven-defender","pyrokineticist"]:
  var base_class: String={"shadowdancer":"rogue","dragon-disciple":"sorcerer","dwarven-defender":"fighter","pyrokineticist":"psion"}[path]
  var record:=kernel.create("a",source.recommendation("adept").attributes,"heritage-dwarf" if path=="dwarven-defender" else "heritage-human")
  for n in 5:
   var suggestion:=kernel.suggested_choice(record,base_class,"dodge" if path=="shadowdancer" and n==0 else "toughness" if path=="dwarven-defender" and n==0 else "steady-study")
   var next:=kernel.preview_advancement(record,suggestion.choice)
   check(next.ok,"real prestige prerequisite history "+path+str(n))
   if not next.ok:break
   record=next.candidate
  check(kernel.available_advancement(record).classes[path].ok,"attainable saved permanent prerequisites "+path)
  if not kernel.available_advancement(record).classes[path].ok:continue
  for n in 10:
   var next:=kernel.preview_advancement(record,kernel.suggested_choice(record,path).choice)
   check(next.ok,"real prestige progression "+path+str(n))
   if not next.ok:break
   record=next.candidate
  record.runtime.resources=kernel.derive_character(record).snapshot.resource_capacities.duplicate()
  record.equipment=["staff"] if path=="dragon-disciple" or path=="pyrokineticist" else ["shortblade"]
  advanced[path]=record
  check(kernel.derive_character(JSON.parse_string(JSON.stringify(record))).snapshot.snapshot_hash==kernel.derive_character(record).snapshot.snapshot_hash,"ordered prestige history reload "+path)
  for at in [1,4,7,10]:exercise(record,path+"-technique-"+str(at))
 for cls in source.ids("classes"):
  if source.definition("classes",cls).class_kind!="base":continue
  var record:=build("a",cls,"heritage-human",int(source.definition("classes",cls).max_level))
  if record.is_empty():continue
  record.equipment=["bow"] if cls in ["scout","ranger"] else ["unarmed"] if cls in ["monk","soulknife"] else ["shortblade"] if source.definition("classes",cls).proficiencies.has("martial") else ["staff"]
  record.runtime.resources=kernel.derive_character(record).snapshot.resource_capacities.duplicate()
  for ability in kernel.derive_character(record).snapshot.abilities:
   var def:=source.definition("abilities",ability)
   if def.provenance.get("revision")!="game112-wave-one" or def.tags.has("spell") or def.has("trigger") or def.tags.has("passive"):continue
   exercise(record,ability)
 verify_spells()
 verify_feats()
 verify_geometry()
 if not OS.get_environment("GAME112_TEST_ROOT").is_empty():
  FileAccess.open(OS.get_environment("GAME112_TEST_ROOT").path_join("tactical-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"prestige_paths":advanced.keys(),"rules_ref":source.rules_ref()}," "))
  FileAccess.open(OS.get_environment("GAME112_TEST_ROOT").path_join("prestige-fixtures.json"),FileAccess.WRITE).store_string(JSON.stringify(advanced))
 print("GAME112 TACTICAL ",checks," / ",failures)
 completed.emit()
 if not no_quit:get_tree().quit(1 if failures else 0)
func fixture(record: Dictionary) -> Dictionary:
 var state:={"world_ref":{"id":"catalogue-development"},"origin":{"home_burg_id":1},"party_ids":["a","b","c"],"party":{"members":[{"name":"Actor"},{"name":"Ally"},{"name":"Companion"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":{"a":record}}}
 for id in ["b","c"]:
  var ally:=build(id,"fighter");ally.equipment=["shortblade"];ally.runtime.hp=1;state.mechanics.records[id]=ally
 var engine:=TacticalCombat.new(state);var battle:=engine.create(state,"catalogue-testing")
 battle.cursor=battle.order.find("a");battle.units.a.position=[0,0];battle.units.b.position=[0,1];battle.units.c.position=[0,2]
 battle.units["bandit-blade"].position=[1,0];battle.units["bandit-bow"].position=[2,0]
 return engine.seal(battle)
func exercise(record: Dictionary,ability: String) -> void:
 var battle:=fixture(record);var engine:=TacticalCombat.new(record);var def:=source.definition("abilities",ability)
 var target:="a" if def.targeting.kind in ["self","ally"] else "bandit-blade"
 var command:={"actor_id":"a","revision":battle.revision,"kind":ability,"target_id":target}
 var result:=engine.command(battle,command)
 check(result.ok,"existing tactical command "+ability+": "+str(result.get("error","")))
 if not result.ok:return
 check(engine.validate(result.battle).is_empty(),"valid bounded tactical result "+ability)
 check(engine.validate(JSON.parse_string(JSON.stringify(result.battle))).is_empty(),"tactical snapshot reload "+ability)
 var replay:=engine.command(battle,command)
 check(replay.ok and result.battle.state_hash==replay.battle.state_hash and result.battle.log==replay.battle.log and result.battle.rng==replay.battle.rng,"exact command/log/RNG "+ability)
 check(result.battle.budget.main==0,"one main action "+ability)
func verify_spells() -> void:
 for cls in ["wizard","sorcerer","cleric","druid","bard","paladin","ranger"]:
  var priority: String=source.definition("classes",cls).casting_attribute
  var attributes: Dictionary=source.recommendation("adept").attributes.duplicate()
  var old: int=int(attributes[priority])
  for id in attributes:
   if int(attributes[id])==15:attributes[id]=old;break
  attributes[priority]=15
  var record:=kernel.create("a",attributes,"heritage-human")
  for n in 20:
   var suggestion:=kernel.suggested_choice(record,cls)
   if source.rule("attribute_increase_levels").has(n+1):
    # Scores affect the point budget: recalculate through the actual preview.
    suggestion.choice.attribute_increase=priority
    var preview:=kernel.preview_choices(record,cls,{"attribute_increase":priority})
    var points: int=int(preview.skill_points);var allocation:={};var ranks: Dictionary=kernel.derive_character(record).context.skills
    for id in source.ids("skills"):
     var count:=mini(points,n+1-int(ranks[id]))
     if count>0:allocation[id]=count;points-=count
    suggestion.choice.skill_allocations=allocation
   var result:=kernel.preview_advancement(record,suggestion.choice)
   check(result.ok,"legal high casting history "+cls+str(n))
   if not result.ok:break
   record=result.candidate
  record.equipment=["staff"];record.runtime.resources=kernel.derive_character(record).snapshot.resource_capacities.duplicate()
  for ability in kernel.derive_character(record).snapshot.abilities:
   var def:=source.definition("abilities",ability)
   if def.provenance.get("revision")!="game112-wave-one" or not def.tags.has("spell"):continue
   var cast_record:=record.duplicate(true);cast_record.choices.prepared_abilities=[ability]
   cast_record.choices.spell_preparations={ability:1} if def.tags.has("prepared") else {}
   RulesCoreContent.refill_prepared(cast_record,source)
   exercise(cast_record,ability)
func verify_feats() -> void:
 for id in ["psychic-reservoir","iron-soul","mobile-skirmisher","invocation-ward","adamant-stance","natural-armour","greater-resilience","master-arcane-focus"]:
  var cls: String={"psychic-reservoir":"psion","iron-soul":"soulknife","mobile-skirmisher":"scout","invocation-ward":"warlock","adamant-stance":"warblade","natural-armour":"fighter","greater-resilience":"fighter","master-arcane-focus":"wizard"}[id]
  var level:=13 if id in ["greater-resilience","master-arcane-focus"] else 1 if id=="natural-armour" else 5
  var record:=kernel.create("feat:"+id,source.recommendation("adept").attributes,"heritage-lizardfolk" if id=="natural-armour" else "heritage-human")
  for n in level:
   var feat: String=id if n+1==level else "dodge" if id=="mobile-skirmisher" and n==0 else "mobility" if id=="mobile-skirmisher" and n==2 else "spell-focus" if id=="master-arcane-focus" and n==0 else "greater-spell-focus" if id=="master-arcane-focus" and n==4 else "toughness" if id=="greater-resilience" and n==0 else "steady-study"
   var result:=kernel.preview_advancement(record,kernel.suggested_choice(record,cls,feat).choice)
   check(result.ok,"genuine new feat chain "+id+str(n))
   if not result.ok:break
   record=result.candidate
  var snap:=kernel.derive_character(record)
  check(snap.ok and snap.snapshot.feats.has(id),"new mechanical feat selected "+id)
  if not snap.ok:continue
  check(snap.snapshot.features.has(id+"-feature"),"new feat reaches authoritative snapshot "+id)
  var before:=record.duplicate(true);before.advancement_history.back().feat_id="steady-study"
  var control:=kernel.derive_character(before)
  check(control.ok and (control.snapshot.stats!=snap.snapshot.stats or control.snapshot.capabilities!=snap.snapshot.capabilities),"new feat changes actual derived rules "+id)
func verify_geometry() -> void:
 for ancestry in ["kobold","lizardfolk","gnoll"]:
  var natural:=build("a","fighter","heritage-"+ancestry);natural.equipment=["bow"]
  exercise(natural,ancestry+"-claws")
 var large:=build("a","fighter","heritage-goliath")
 large.equipment=["shortblade"]
 var battle:=fixture(large);battle.units["bandit-blade"].position=[2,0];battle.units["bandit-bow"].position=[5,0]
 var engine:=TacticalCombat.new(large)
 check(engine.eligible(battle,battle.units.a,battle.units["bandit-blade"],"attack"),"large ancestry actually attacks at reach2")
 check(int(engine.stats(battle.units.a).stride)==3,"large inherited stride executes in path allowance")
 var defender: Dictionary=advanced.get("dwarven-defender",{})
 if not defender.is_empty():
  battle=fixture(defender);engine=TacticalCombat.new(defender)
  var result:=engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":"dwarven-defender-technique-1","target_id":"a"})
  check(result.ok and engine.paths(result.battle,result.battle.units.a).is_empty(),"defensive stance sacrifices actual movement")
