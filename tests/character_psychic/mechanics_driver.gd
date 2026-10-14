extends Node
signal completed
var no_quit := false
var base := ""
var advanced_examples := {}
var failures := 0
var checks := 0
var source: RulesRegistry
var kernel: RulesCharacter
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(message)
func _ready() -> void:call_deferred("run")
func build(id: String,cls: String,levels: int,ancestry := "heritage-human") -> Dictionary:
 var attributes := {"STR":10,"DEX":13,"CON":14,"INT":15,"WIS":12,"CHA":8}
 var definition := source.definition("classes",cls)
 var priority: Array=definition.get("attribute_priority",[])
 if priority.is_empty():
  var primary: String=definition.get("casting_attribute","")
  if primary.is_empty():primary="STR"
  priority=[primary]
  for key in ["DEX","CON","INT","WIS","CHA","STR"]:
   if not priority.has(key):priority.append(key)
 for i in 6:attributes[priority[i]]=source.rule("standard_array")[i]
 if cls=="wilder":attributes={"STR":10,"DEX":13,"CON":14,"INT":12,"WIS":8,"CHA":15}
 if cls=="ardent":attributes={"STR":10,"DEX":13,"CON":14,"INT":12,"WIS":15,"CHA":8}
 var record := kernel.create(id,attributes,ancestry)
 for n in levels:
  var suggested := kernel.suggested_choice(record,cls)
  check(suggested.ok,"suggest "+cls+str(n))
  if not suggested.ok:return {}
  var step := kernel.preview_advancement(record,suggested.choice)
  check(step.ok,"advance "+cls+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  record=step.candidate
 return record
func run() -> void:
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v13.json")
 check(loaded.ok,"v13 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish();return
 kernel=RulesCharacter.new(source)
 base=OS.get_environment("GAME112W3_TEST_ROOT")
 if not base.is_empty():DirAccess.make_dir_recursive_absolute(base)
 if OS.get_environment("GAME112W3_RESTART")=="1":
  var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("psychic-restart.json")))
  for record in saved.records.values():check(kernel.validate_build(record).ok,"separate process saved known powers, class resources and companion")
  var before: Dictionary=kernel.derive_character(saved.records.actor).snapshot
  check(before.snapshot_hash==saved.snapshot_hash,"separate process exact psychic snapshot")
  var replay := use(saved.records.actor,saved.records.target,saved.ability_id)
  FileAccess.open(base.path_join("restart-actual.json"),FileAccess.WRITE).store_string(JSON.stringify(replay))
  check(replay.ok and RulesJson.digest(replay)==saved.expected_hash,"separate process next augmentation and RNG replay")
  finish();return
 for cls in source.ids("classes").filter(func(id: String):return source.definition("classes",id).get("class_kind")=="base"):
  var record := build(cls,cls,20)
  if record.is_empty():continue
  check(kernel.validate_build(JSON.parse_string(JSON.stringify(record))).ok,"twenty-level saved "+cls)
 test_psychic()
 test_repertoire()
 test_tactical()
 test_entities()
 test_prestige()
 print("WAVE3_COUNTS ",source.ids("psychic_powers").size()," powers; ",source.ids("creatures").size()," creatures")
 finish()
func use(actor: Dictionary,target: Dictionary,id: String) -> Dictionary:
 return RulesEffects.new(source).use_ability(actor,target,id,{"main":1,"move":1,"reaction":1},RulesRng.initial("wave-three"))
func selected_build(id: String,cls: String,levels: int,overrides: Dictionary={}) -> Dictionary:
 var record := kernel.create(id,{"STR":10,"DEX":13,"CON":14,"INT":15,"WIS":12,"CHA":8},"heritage-human")
 for n in levels:
  var choice: Dictionary=kernel.suggested_choice(record,cls).choice
  for key in overrides:
   if choice.specialisations.has(key):choice.specialisations[key]=overrides[key]
  var step := kernel.preview_advancement(record,choice)
  check(step.ok,"selected progression "+cls+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  record=step.candidate
 record.runtime.hp=int(kernel.derive_character(record).snapshot.stats.HP)
 record.runtime.resources=kernel._replay(record).context.capacities.duplicate()
 return record
func test_psychic() -> void:
 var a := selected_build("a","psion",3,{"psion-power-1":"power-kinetic-bolt","psion-second-power":"power-force-screen"})
 var b := selected_build("b","psion",3,{"psion-power-1":"power-thought-fog","psion-second-power":"power-keen-mind","psion-power-2":"power-fellowship"})
 if a.is_empty() or b.is_empty():return
 var sa: Dictionary=kernel.derive_character(a).snapshot;var sb: Dictionary=kernel.derive_character(b).snapshot
 check(sa.known_powers!=sb.known_powers and a.ancestry_ref==b.ancestry_ref,"same ancestry, different persistent power repertoire")
 check(not use(b,a,"power-kinetic-bolt").ok,"unlearned power rejected")
 check(not use(a,b,"power-kinetic-bolt-aug4").ok,"expenditure exceeds manifesting level rejected")
 var basic := use(a,b,"power-kinetic-bolt");var augmented := use(a,b,"power-kinetic-bolt-aug2")
 check(basic.ok and augmented.ok,"basic and legal augmented power execute")
 if basic.ok and augmented.ok:
  check(int(a.runtime.resources["psychic-points"])-int(basic.actor.runtime.resources["psychic-points"])==1,"base power spends one actual point")
  check(int(a.runtime.resources["psychic-points"])-int(augmented.actor.runtime.resources["psychic-points"])==3,"augmentation spends three actual points")
  check(int(b.runtime.hp)-int(augmented.target.runtime.hp)>int(b.runtime.hp)-int(basic.target.runtime.hp),"augmentation increases actual damage")
  check(RulesJson.digest(augmented)==RulesJson.digest(use(a,b,"power-kinetic-bolt-aug2")),"identical command/resource/RNG replay")
  if not base.is_empty():
   var druid := selected_build("persisted-shape","druid",8,{"druid-companion":"leopard"})
   var shaped := use(druid,druid,"wild-shape-leopard")
   var saved := {"records":{"actor":augmented.actor,"target":augmented.target,"druid":shaped.actor},"snapshot_hash":kernel.derive_character(augmented.actor).snapshot.snapshot_hash,"ability_id":"power-kinetic-bolt","expected_hash":RulesJson.digest(use(augmented.actor,augmented.target,"power-kinetic-bolt")),"expected_result":use(augmented.actor,augmented.target,"power-kinetic-bolt")}
   FileAccess.open(base.path_join("psychic-restart.json"),FileAccess.WRITE).store_string(JSON.stringify(saved))
  var depleted: Dictionary=a.duplicate(true);depleted.runtime.resources["psychic-points"]=0
  check(not use(depleted,b,"power-kinetic-bolt").ok,"exhaustion rejects power")
 var tampered := a.duplicate(true);tampered.advancement_history[0].specialisations["psion-second-power"]="power-kinetic-bolt"
 check(not kernel.validate_build(tampered).ok,"duplicate known-power selection rejected")
 tampered=a.duplicate(true);tampered.advancement_history[0].specialisations["psion-power-1"]="power-perfect-unity"
 check(not kernel.validate_build(tampered).ok,"high-tier historical entry rejected")
 var partial := selected_build("mixed","psion",2)
 var step := kernel.preview_advancement(partial,kernel.suggested_choice(partial,"psychic-warrior").choice)
 check(step.ok,"psychic multiclass advancement")
 if step.ok:
  var mixed: Dictionary=kernel.derive_character(step.candidate).snapshot
  check(mixed.manifesting_level==3 and mixed.resource_capacities["psychic-points"]==7,"shared manifesting level/reserve sums different class contributions")
 var lurk := build("l","lurk",4)
 if not lurk.is_empty():
  lurk.equipment=["shortblade"]
  check(not use(lurk,b,"lurk-psychic-ambush").ok,"ambush requires an earned prior veil")
  var veiled := use(lurk,lurk,"lurk-veil");check(veiled.ok,"veil actually applies concealment")
  if veiled.ok:
   var ambush := use(veiled.actor,b,"lurk-psychic-ambush");check(ambush.ok,"costed psychic ambush executes after veil")
   if ambush.ok:check(not kernel.derive_character(ambush.actor).snapshot.tags.has("psychic_ambush_ready"),"ambush consumes veil eligibility")
 var ardent := build("ar","ardent",1)
 if not ardent.is_empty():
  tampered=ardent.duplicate(true);tampered.advancement_history[0].specialisations["ardent-power-1"]="power-thought-fog"
  check(not kernel.validate_build(tampered).ok,"mantle-ineligible known power rejected")
 for ancestry in ["heritage-elan","heritage-xeph","heritage-maenad","heritage-dromite"]:
  var record := build(ancestry,"fighter",1,ancestry)
  if record.is_empty():continue
  var id: String=ancestry.replace("heritage-","")+"-inheritance-action"
  var inherited := use(record,b if ancestry=="heritage-dromite" else record,id)
  check(inherited.ok and int(inherited.actor.runtime.resources["inherited-psychic"])==1,"actual inherited resource/effect "+ancestry)
func test_repertoire() -> void:
 var carrier := selected_build("repertoire","psion",20)
 var target := build("target","fighter",20);target.runtime.hp=int(kernel.derive_character(target).snapshot.stats.HP)-20
 if carrier.is_empty() or target.is_empty():return
 for id in source.ids("psychic_powers"):
  var record := carrier.duplicate(true)
  var snap: Dictionary=kernel.derive_character(record).snapshot
  if not snap.known_powers.has(id):record.advancement_history.back().specialisations["psion-power-20"]=id
  check(kernel.validate_build(record).ok,"actual eligible learned repertoire "+id)
  for variant in source.definition("psychic_powers",id).variants:
   var definition := source.definition("abilities",variant)
   var used := use(record,record if definition.targeting.kind=="self" else target,variant)
   check(used.ok,"every advertised power/augmentation executes "+variant+JSON.stringify(used.get("errors",[])))
   if used.ok:
    check(int(record.runtime.resources["psychic-points"])-int(used.actor.runtime.resources["psychic-points"])==int(definition.cost.resources["psychic-points"]),"every augmentation has exact point expenditure "+variant)
    check(used.budget.main==0 and kernel.validate_build(JSON.parse_string(JSON.stringify(used.actor))).ok,"power action/resource persistence "+variant)
 var corrupt := source.source_data()
 corrupt.psychic_powers[0].tier=10
 check(not RulesRegistry.new().load_data(corrupt).ok,"unknown power tiers rejected")
 corrupt=source.source_data();corrupt.abilities.filter(func(row: Dictionary):return row.has("psychic_power"))[0].cost.resources["psychic-points"]=0
 check(not RulesRegistry.new().load_data(corrupt).ok,"false augmentation costs rejected by content schema")
func test_tactical() -> void:
 var a := selected_build("a","psion",5,{"psion-power-1":"power-kinetic-bolt","psion-second-power":"power-force-screen"})
 var b := build("b","fighter",5);var c := build("c","fighter",5)
 var campaign := {"world_ref":{"id":"wave-three"},"origin":{"home_burg_id":1},"party_ids":["a","b","c"],"party":{"members":[{"name":"Psion"},{"name":"Ally"},{"name":"Guard"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":{"a":a,"b":b,"c":c}}}
 var engine := TacticalCombat.new(campaign);var battle := engine.create(campaign,"wave-three")
 battle.cursor=battle.order.find("a");battle=engine.seal(battle)
 check(engine.eligible(battle,battle.units.a,battle.units.b,"power-force-screen"),"support power legally targets an ally on the real grid")
 check(not engine.eligible(battle,battle.units.a,battle.units["bandit-blade"],"power-force-screen"),"support power cannot target an enemy")
 var command := {"actor_id":"a","revision":battle.revision,"kind":"power-force-screen-aug2","target_id":"b"}
 var used := engine.command(battle,command)
 check(used.ok,"augmented ally power executes through tactical command")
 if not used.ok:return
 check(engine.validate(used.battle).is_empty(),"augmented tactical state remains valid")
 var replay := engine.command(JSON.parse_string(JSON.stringify(battle)),JSON.parse_string(JSON.stringify(command)))
 check(replay.ok and replay.battle.state_hash==used.battle.state_hash and replay.battle.rng==used.battle.rng,"raw and JSON tactical command replay identical")
 check(int(used.battle.units.a.record.runtime.resources["psychic-points"])==int(battle.units.a.record.runtime.resources["psychic-points"])-3,"tactical augmentation spends the real shared reserve")
 check(used.battle.units.b.record.runtime.temporary_hp==7,"tactical augmentation creates advertised temporary health")
 var moved := battle.duplicate(true)
 moved=engine.command(moved,{"actor_id":"a","revision":moved.revision,"kind":"power-burst-step","target_id":"a"})
 # A power not selected in this build remains unavailable even via explicit commands.
 check(not moved.ok,"direct tactical command cannot bypass powers-known choices")
 a=selected_build("a","psion",20)
 if not kernel.derive_character(a).snapshot.known_powers.has("power-astral-guardian"):a.advancement_history.back().specialisations["psion-power-20"]="power-astral-guardian"
 campaign.mechanics.records.a=a;engine=TacticalCombat.new(campaign);battle=engine.create(campaign,"psychic-summon")
 battle.cursor=battle.order.find("a");battle=engine.seal(battle)
 var summoned := engine.command(battle,{"actor_id":"a","revision":battle.revision,"kind":"power-astral-guardian-aug2","target_id":"a"})
 check(summoned.ok,"psychic summon creates an owned actor through ordinary command authority")
 if summoned.ok:
  var pet_id := "a:summon:0"
  check(summoned.battle.units.has(pet_id) and summoned.battle.units[pet_id].entity.remaining==4,"augmentation extends real summon lifetime")
  check(int(summoned.battle.units.a.record.runtime.resources["psychic-points"])==int(battle.units.a.record.runtime.resources["psychic-points"])-11,"psychic summon spends eleven actual points")
  var duplicate: Dictionary=summoned.battle.duplicate(true);duplicate.budget.main=1;duplicate=engine.seal(duplicate)
  check(not engine.command(duplicate,{"actor_id":"a","revision":duplicate.revision,"kind":"power-astral-guardian","target_id":"a"}).ok,"psychic summons obey the existing one-active-summon limit")
  var living: Dictionary=summoned.battle.duplicate(true)
  for n in 4:CombatEntities.round_start(engine,living)
  check(not engine.alive(living.units[pet_id]),"psychic summon expires at augmented duration without refund")
func test_entities() -> void:
 for creature in ["leopard","boar","stag","stone-guardian","renewal-spirit"]:
  var pet := RulesEntities.creature_record("pet:"+creature+":companion",creature,8,source)
  check(not pet.is_empty(),"real creature advancement "+creature)
  if pet.is_empty():continue
  var target := build("ally","fighter",8);target.runtime.hp-=6
  var result := use(pet,pet if creature=="boar" else target,creature+"-special")
  check(result.ok,"actual creature special action "+creature+JSON.stringify(result.get("errors",[])))
  if result.ok:check(int(result.actor.runtime.resources["creature-effort"])==int(pet.runtime.resources["creature-effort"])-1,"creature action spends bounded effort "+creature)
 var druid := selected_build("shape","druid",8,{"druid-companion":"leopard"})
 if druid.is_empty():return
 var before: Dictionary=kernel.derive_character(druid).snapshot;druid.runtime.hp-=4
 for form in ["leopard","boar","stone"]:
  var shaped := use(druid,druid,"wild-shape-"+form);check(shaped.ok,"new body form executes "+form)
  if not shaped.ok:continue
  var snapshot: Dictionary=kernel.derive_character(shaped.actor).snapshot
  check(snapshot.stats.HP==before.stats.HP and snapshot.current_hp==int(druid.runtime.hp),"form preserves health "+form)
  check(snapshot.ancestry.id==before.ancestry.id and shaped.actor.advancement_history==druid.advancement_history,"form retains ancestry/history "+form)
  check(snapshot.abilities.all(func(id: String):return not source.definition("abilities",id).tags.has("spell") and not source.definition("abilities",id).tags.has("psychic")),"form suppresses spells and psychic powers "+form)
  check(kernel.validate_build(JSON.parse_string(JSON.stringify(shaped.actor))).ok,"active form/companion saved reload "+form)
  var reverted := use(shaped.actor,shaped.actor,"revert-form")
  check(reverted.ok and kernel.derive_character(reverted.actor).snapshot.body_form.is_empty() and reverted.actor.runtime.hp==druid.runtime.hp,"explicit reversion without healing "+form)
 var mixed := selected_build("mixed-form","druid",5)
 var added := kernel.preview_advancement(mixed,kernel.suggested_choice(mixed,"psychic-warrior").choice)
 check(added.ok,"real martial psychic/Druid multiclass history")
 if added.ok:
  var shaped := use(added.candidate,added.candidate,"wild-shape")
  check(shaped.ok,"mixed psychic body form executes")
  if shaped.ok:
   var snapshot: Dictionary=kernel.derive_character(shaped.actor).snapshot
   check(snapshot.abilities.all(func(id: String):return not source.definition("abilities",id).cost.resources.has("psychic-points")),"body form suppresses legacy psychic class techniques as well as new learned powers")
 var inherited := build("inherited-form","druid",5,"heritage-dromite")
 var inherited_shape := use(inherited,inherited,"wild-shape")
 check(inherited_shape.ok,"inherited psychic character transforms")
 if inherited_shape.ok:check(not kernel.derive_character(inherited_shape.actor).snapshot.abilities.has("dromite-inheritance-action"),"body form suppresses inherited psychic actions")
 var spent := druid.duplicate(true);var id: String=RulesEntities.identity(druid.character_id)
 spent.runtime.companions[id].record.runtime.resources["creature-effort"]=0
 var advanced := kernel.preview_advancement(spent,kernel.suggested_choice(spent,"druid").choice)
 check(advanced.ok and int(advanced.candidate.runtime.companions[id].record.runtime.resources["creature-effort"])==0,"companion growth does not refill spent resource")
func test_prestige() -> void:
 var record := kernel.create("steward",{"STR":10,"DEX":13,"CON":14,"INT":12,"WIS":15,"CHA":8},"heritage-human")
 for n in 5:
  var proposed: Dictionary=kernel.suggested_choice(record,"druid").choice
  # Real saved ranks, not transient grants. Preserve the complete skill budget.
  var allocations: Dictionary=proposed.skill_allocations
  var total := 0
  for amount in allocations.values():total+=int(amount)
  proposed.skill_allocations={"nature":1,"animal-handling":1,"perception":1,"insight":1,"arcana":total-4}
  if n==2:proposed.feat_id="beast-stewardship"
  var step := kernel.preview_advancement(record,proposed);check(step.ok,"legitimate steward prerequisite history "+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return
  record=step.candidate
 check(kernel.available_advancement(record).classes["beast-steward"].ok,"permanent bond/ranks/feat open prestige")
 var denied := build("nonbond","wizard",5)
 check(not kernel.available_advancement(denied).classes["beast-steward"].ok,"arcane summon access does not qualify as permanent companion")
 for n in 5:
  var step := kernel.preview_advancement(record,kernel.suggested_choice(record,"beast-steward").choice)
  check(step.ok,"five playable steward levels "+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return
  record=step.candidate
 check(RulesEntities.bonds(record,source)[0].level==11,"chosen swift training and prestige levels grow the actual permanent pet")
 check(kernel.validate_build(JSON.parse_string(JSON.stringify(record))).ok,"earned-entry prestige/creature ordered history reload")
 advanced_examples["beast-steward"]=record.duplicate(true)
 var hybrid := selected_build("hybrid","psion",3)
 for n in 3:
  var choice: Dictionary=kernel.suggested_choice(hybrid,"wizard").choice
  if n==1:choice.feat_id="psychic-discipline"
  var step := kernel.preview_advancement(hybrid,choice)
  check(step.ok,"hybrid saved prerequisite class "+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return
  hybrid=step.candidate
 check(kernel.available_advancement(hybrid).classes.cerebremancer.ok,"attainable arcane/psychic prestige")
 for n in 5:
  var step := kernel.preview_advancement(hybrid,kernel.suggested_choice(hybrid,"cerebremancer").choice)
  check(step.ok,"five hybrid prestige levels "+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return
  hybrid=step.candidate
 var snapshot: Dictionary=kernel.derive_character(hybrid).snapshot
 check(snapshot.manifesting_level==8 and snapshot.casting_levels.wizard==8,"prestige actually advances both traditions")
 check(kernel.validate_build(JSON.parse_string(JSON.stringify(hybrid))).ok,"hybrid histories and selected powers survive JSON reload")
 advanced_examples["cerebremancer"]=hybrid.duplicate(true)
func finish() -> void:
 print("WAVE3_MECHANICS ",checks," checks; ",failures," failures")
 if not base.is_empty():FileAccess.open(base.path_join("mechanics-restart-proof.json" if OS.get_environment("GAME112W3_RESTART")=="1" else "mechanics-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref()}))
 completed.emit()
 if not no_quit:get_tree().quit(1 if failures else 0)
