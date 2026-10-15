extends Node
signal completed
var no_quit := false
var failures := 0
var checks := 0
var source: RulesRegistry
var kernel: RulesCharacter
var fixtures := {}
var restart_payload := {}
var base := OS.get_environment("GAME112W4_TEST_ROOT")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func build(cls: String,levels: int,ancestry := "heritage-human",preferred_feat := "steady-study") -> Dictionary:
 var attrs := {}
 var priority: Array=source.definition("classes",cls).get("attribute_priority",[])
 if priority.is_empty():
  var primary: String=source.definition("classes",cls).get("casting_attribute","")
  if primary.is_empty():primary="STR"
  priority=[primary]
  for key in ["DEX","CON","INT","WIS","CHA","STR"]:
   if not priority.has(key):priority.append(key)
 for i in 6:attrs[priority[i]]=source.rule("standard_array")[i]
 if cls=="psychic-warrior":attrs={"STR":10,"DEX":12,"CON":14,"INT":13,"WIS":15,"CHA":8}
 var record := kernel.create(cls,attrs,ancestry)
 for n in levels:
  var suggestion := kernel.suggested_choice(record,cls,preferred_feat if n==0 else "steady-study")
  check(suggestion.ok,"suggestion "+cls+str(n))
  if not suggestion.ok:return {}
  if cls=="psychic-warrior" and n<4:
   var allocation: Dictionary=suggestion.choice.skill_allocations
   if not allocation.has("perception"):
    var first: String=str(allocation.keys()[0]);allocation[first]-=1
    if allocation[first]==0:allocation.erase(first)
    allocation.perception=1
  var step := kernel.preview_advancement(record,suggestion.choice)
  check(step.ok,"progression "+cls+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  record=step.candidate
 record.runtime.hp=int(kernel.derive_character(record).snapshot.stats.HP)
 record.runtime.resources=kernel._replay(record).context.capacities.duplicate()
 return record
func use(actor: Dictionary,target: Dictionary,id: String) -> Dictionary:
 return RulesEffects.new(source).use_ability(actor,target,id,{"main":1,"move":1,"reaction":1},RulesRng.initial("wave-four"))
func run() -> void:
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v14.json")
 check(loaded.ok,"v14 schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME112W4_RESTART")=="1":
  var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("saved.json")))
  for id in saved.records:
   check(kernel.validate_build(saved.records[id]).ok,"cold saved build "+id)
   var derived := kernel.derive_character(saved.records[id])
   check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"cold exact snapshot "+id)
  var repeated := use(saved.erudite,saved.erudite,saved.repeat)
  check(repeated.ok,"cold reuse of manifested identity")
  check(not use(saved.erudite,saved.erudite,saved.blocked).ok,"cold distinct limit retained")
  finish();return
 for cls in source.ids("classes"):
  if source.definition("classes",cls).get("class_kind")!="base":continue
  print("PROGRESSION ",cls)
  var record := build(cls,20)
  if record.is_empty():continue
  check(kernel.validate_build(JSON.parse_string(JSON.stringify(record))).ok,"level20 saved "+cls)
  fixtures[cls]=record
 test_erudite();test_auras();test_ancestries();test_powers();test_prestige();test_creatures();test_spells();test_feats();test_tactical()
 finish()
func test_erudite() -> void:
 var record := build("erudite",1)
 if record.is_empty():return
 var powers: Array=kernel.derive_character(record).snapshot.known_powers
 check(powers.size()==2,"Erudite knows two but one distinct per rest")
 var id: String=source.definition("psychic_powers",powers[0]).variants[0]
 var other: String=source.definition("psychic_powers",powers[1]).variants[0]
 var target := build("fighter",1)
 var cast := use(record,target,id)
 check(cast.ok,"first distinct manifest")
 if not cast.ok:return
 check(cast.actor.runtime.manifested_powers==[powers[0]],"persist first identity")
 check(use(cast.actor,cast.actor,id).ok,"same identity reusable")
 check(not use(cast.actor,cast.actor,other).ok,"second distinct denied")
 check(RulesJson.digest(cast)==RulesJson.digest(use(record,target,id)),"power deterministic replay")
 var effects := RulesEffects.new(source)
 var short := effects.refresh_resources(cast.actor.runtime,kernel.derive_character(cast.actor).snapshot.resource_capacities,"encounter")
 check(short.runtime.manifested_powers==cast.actor.runtime.manifested_powers,"encounter cannot reset distinct allowance")
 var rest := effects.refresh_resources(cast.actor.runtime,kernel.derive_character(cast.actor).snapshot.resource_capacities,"eligible_rest")
 check(rest.runtime.manifested_powers.is_empty(),"eligible rest resets allowance")
 var rested: Dictionary=cast.actor.duplicate(true);rested.runtime=rest.runtime
 check(use(rested,rested,other).ok,"new identity after legitimate rest")
 fixtures.erudite_spent=cast.actor
 if not base.is_empty():
  DirAccess.make_dir_recursive_absolute(base)
  restart_payload={"erudite":cast.actor,"repeat":id,"blocked":other}
func test_auras() -> void:
 var owner := build("marshal",5);var ally := build("fighter",5)
 if owner.is_empty() or ally.is_empty():return
 var engine := TacticalAuras.new(source.rules_ref())
 owner.character_id="owner";ally.character_id="ally"
 var b := {"units":{"owner":engine.unit("owner","Marshal","party",[1,1],owner,"shortblade"),"ally":engine.unit("ally","Fighter","party",[2,1],ally,"shortblade")},"order":["owner","ally"],"status":"active","board":{"blocked":[]}}
 var original: int=engine.stats(b.units.ally).melee_attack
 var ability_id: String=kernel.derive_character(owner).snapshot.abilities.filter(func(id: String):return id.begins_with("marshal-aura-"))[0]
 var cast := use(owner,owner,ability_id)
 check(cast.ok,"aura uses real action and reserve")
 if not cast.ok:return
 b.units.owner.record=cast.actor;fixtures.active_aura=cast.actor;RulesWaveFour.project_auras(engine,b)
 check(int(engine.stats(b.units.ally).melee_attack)>original,"nearby ally receives actual attack benefit")
 check(cast.budget.main==0 and int(cast.actor.runtime.resources["marshal-resolve"])==int(owner.runtime.resources["marshal-resolve"])-1,"aura costs")
 var applied := RulesJson.digest(b);RulesWaveFour.project_auras(engine,b)
 check(RulesJson.digest(b)==applied,"aura projection idempotent")
 b.units.ally.position=[7,5];RulesWaveFour.project_auras(engine,b)
 check(int(engine.stats(b.units.ally).melee_attack)==original,"leaving radius removes benefit")
 b.units.ally.position=[2,1];b.board.blocked=[[2,1]];RulesWaveFour.project_auras(engine,b)
 check(int(engine.stats(b.units.ally).melee_attack)==original,"blocked line removes benefit")
 b.board.blocked=[];b.units.owner.record.runtime.hp=0;RulesWaveFour.project_auras(engine,b)
 check(int(engine.stats(b.units.ally).melee_attack)==original,"downed source removes aura")
 var divine := build("divine-mind",1)
 check(kernel.derive_character(divine).snapshot.known_powers.size()==1,"Divine Mind learns mantle-restricted power")
 var switching := use(cast.actor,cast.actor,"marshal-aura-bulwark")
 check(switching.ok and switching.actor.runtime.statuses.size()==1,"switching replaces maintained aura")
func test_ancestries() -> void:
 for id in ["bugbear","ogre","half-giant","troglodyte"]:
  var record := build("fighter",1,"heritage-"+id)
  check(not record.is_empty() and kernel.validate_build(record).ok,"inherited playable "+id)
  if not record.is_empty():check(kernel.derive_character(record).snapshot.ancestry.people_id==id,"real inherited identity "+id)
func test_powers() -> void:
 var master: Dictionary=fixtures.get("psion",{})
 if master.is_empty():return
 var learned: Array=kernel.derive_character(master).snapshot.known_powers
 for pid in source.ids("psychic_powers"):
  var power := source.definition("psychic_powers",pid)
  # Fixture grants a known feature through the existing runtime handler; actual choice tests above use history.
  var record: Dictionary=master.duplicate(true)
  if not learned.has(pid):record.runtime.granted_features.append(power.feature_id)
  for id in power.variants:
   if int(source.definition("abilities",id).cost.resources["psychic-points"])>20:continue
   var cast := use(record,record,id)
   check(cast.ok,"executable power variant "+id+JSON.stringify(cast.get("errors",[])))
   if cast.ok:
    check(int(cast.actor.runtime.resources["psychic-points"])<int(record.runtime.resources["psychic-points"]),"actual points "+id)
    check(cast.budget.main==0,"actual action "+id)
func test_prestige() -> void:
 var initial := kernel.create("forged",{"STR":10,"DEX":13,"CON":14,"INT":15,"WIS":12,"CHA":8},"heritage-human")
 check(not kernel.available_advancement(initial).classes["cognition-adept"].ok,"prestige unavailable at1")
 var record := build("psychic-warrior",8,"heritage-human","psychic-discipline")
 if record.is_empty():return
 var choice := kernel.suggested_choice(record,"cognition-adept")
 check(choice.ok,"prestige suggestion")
 if not choice.ok:return
 var eligible: Dictionary=kernel.available_advancement(record).classes["cognition-adept"]
 check(eligible.ok,"permanent prestige prerequisites "+JSON.stringify(eligible.get("errors",[])))
 check(record.advancement_history.back().class_id=="psychic-warrior","eligibility never auto advances")
 check(kernel.preview_advancement(record,kernel.suggested_choice(record,"psychic-warrior").choice).ok,"can decline prestige")
 for n in 5:
  choice=kernel.suggested_choice(record,"cognition-adept")
  var step := kernel.preview_advancement(record,choice.choice)
  check(step.ok,"manual prestige level "+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return
  record=step.candidate
 check(not kernel.available_advancement(record).classes["cognition-adept"].ok,"prestige cap5")
 check(RulesWaveFour.distinct_limit(kernel.derive_character(record).context,source)==1000,"non-Erudite prestige does not inherit distinct-power limit")
 fixtures.prestige=record
 check(kernel.derive_character(JSON.parse_string(JSON.stringify(record))).snapshot.snapshot_hash==kernel.derive_character(record).snapshot.snapshot_hash,"exact prestige JSON snapshot")
func test_creatures() -> void:
 for id in ["thorn-guardian","ember-spirit"]:
  var record := RulesEntities.creature_record("qa:summon:"+id,id,5,source)
  check(not record.is_empty() and kernel.validate_build(record).ok,"real owned creature "+id)
  var cast := use(record,record,id+"-special")
  check(cast.ok and cast.budget.main==0,"distinct creature action "+id)
 var druid: Dictionary=fixtures.get("druid",{})
 if not druid.is_empty():
  var shape := use(druid,druid,"wild-shape-scaled-guardian")
  check(shape.ok,"additional form executes")
  if shape.ok:
   fixtures.active_form=shape.actor
   check(not RulesEntities.form(shape.actor,source).is_empty(),"real body configuration")
   check(not kernel.derive_character(shape.actor).snapshot.abilities.any(func(id: String):return source.definition("abilities",id).tags.has("spell")),"form suppresses magic")
   check(use(shape.actor,shape.actor,"revert-form").ok,"form reverts")
func test_spells() -> void:
 for cls in ["wizard","sorcerer","cleric","bard"]:
  var record: Dictionary=fixtures.get(cls,{})
  if record.is_empty():continue
  for suffix in ["fracture-concentration","cleansing-ward"]:
   var id: String=cls+"-"+suffix
   record.choices.prepared_abilities=[id]
   record.choices.spell_preparations={}
   if source.definition("abilities",id).tags.has("prepared"):record.choices.spell_preparations[id]=1
   record.runtime.resources=kernel._replay(record).context.capacities.duplicate()
   check(use(record,record,id).ok,"new executable spell "+id)
func finish() -> void:
 if OS.get_environment("GAME112W4_RESTART")!="1" and not restart_payload.is_empty():
  var hashes := {}
  for key in fixtures:hashes[key]=kernel.derive_character(fixtures[key]).snapshot.snapshot_hash
  restart_payload.records=fixtures;restart_payload.hashes=hashes
  FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(restart_payload))
 if not base.is_empty():
  DirAccess.make_dir_recursive_absolute(base)
  FileAccess.open(base.path_join("restart-proof.json"if OS.get_environment("GAME112W4_RESTART")=="1"else"mechanics-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true}))
 print("WAVE4 ",checks," checks ",failures," failures")
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)

func test_feats() -> void:
 for spec in [["psion","human","psychic-discipline","iron-discipline"],["psion","human","expanded-psychic-reserve","deep-reserve"],["marshal","human","steady-study","commanding-presence"],["divine-mind","human","steady-study","steadfast-mantle"],["fighter","bugbear","steady-study","bugbear-skirmisher"],["fighter","ogre","steady-study","ogre-endurance"],["fighter","troglodyte","steady-study","natural-ferocity"],["druid","human","beast-stewardship","bond-veteran"]]:
  var record := build(spec[0],2,"heritage-"+spec[1],spec[2])
  if record.is_empty():continue
  var suggestion := kernel.suggested_choice(record,spec[0],spec[3])
  var step := kernel.preview_advancement(record,suggestion.choice)
  check(step.ok,"feat is selectable with real prerequisites "+spec[3]+JSON.stringify(step.get("errors",[])))
  if not step.ok:continue
  check(step.snapshot.feats.has(spec[3]),"feat persisted "+spec[3])
  var alternate: Dictionary=suggestion.choice.duplicate(true);alternate.feat_id="steady-study"
  var baseline := kernel.preview_advancement(record,alternate)
  check(baseline.ok,"control build for feat "+spec[3])
  if not baseline.ok:continue
  var stats: Dictionary=step.snapshot.stats;var old: Dictionary=baseline.snapshot.stats
  var pools: Dictionary=step.snapshot.resource_capacities;var oldp: Dictionary=baseline.snapshot.resource_capacities
  match spec[3]:
   "iron-discipline":check(int(stats.will)>int(old.will),"Will feat works")
   "deep-reserve":check(int(pools["psychic-points"])==int(oldp["psychic-points"])+4,"deep reserve actual capacity")
   "commanding-presence":check(int(pools["marshal-resolve"])==int(oldp["marshal-resolve"])+2,"command feat actual capacity")
   "steadfast-mantle":check(int(pools["divine-mind-resolve"])==int(oldp["divine-mind-resolve"])+2,"divine feat actual capacity")
   "bugbear-skirmisher":check(int(stats.stride)>int(old.stride) and int(stats.reflex)>int(old.reflex),"ancestry footwork works")
   "ogre-endurance":check(int(stats.HP)==int(old.HP)+4,"ancestry health works")
   "natural-ferocity":check(step.snapshot.capabilities.weapon_damage.get("boar-tusks")=="1d10" and not baseline.snapshot.capabilities.weapon_damage.has("boar-tusks"),"natural weapon-specific damage feat works")
   "bond-veteran":check(int(stats.fortitude)>int(old.fortitude),"bond resilience works")
func test_tactical() -> void:
 var records := {}
 for pair in [["a","marshal"],["b","divine-mind"],["c","erudite"]]:
  var record := build(pair[1],5);record.character_id=pair[0];records[pair[0]]=record
 var campaign := {"world_ref":{"id":"wave-four"},"origin":{"home_burg_id":1},"party_ids":["a","b","c"],"party":{"members":[{"name":"Marshal"},{"name":"Divine Mind"},{"name":"Erudite"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":records}}
 var engine := TacticalAuras.new(campaign);var battle := engine.create(campaign,"wave-four")
 check(not battle.is_empty() and engine.validate(battle).is_empty(),"real new-class battle")
 if battle.is_empty():return
 battle.cursor=battle.order.find("a");battle=engine.seal(battle)
 var before := RulesJson.digest(battle)
 var input := {"actor_id":"a","revision":battle.revision,"kind":"marshal-aura-assault","target_id":"a"}
 var used := engine.command(battle,input)
 check(used.ok,"aura through tactical command authority")
 if not used.ok:return
 check(engine.validate(used.battle).is_empty(),"aura battle validates")
 check(used.battle.rng==battle.rng,"aura does not consume RNG")
 check(RulesJson.digest(battle)==before,"aura preview cannot mutate input")
 var replay := engine.command(JSON.parse_string(JSON.stringify(battle)),JSON.parse_string(JSON.stringify(input)))
 check(replay.ok and replay.battle.state_hash==used.battle.state_hash,"aura deterministic tactical replay")
 fixtures.tactical_marshal=used.battle.units.a.record
 if not base.is_empty():FileAccess.open(base.path_join("battle.json"),FileAccess.WRITE).store_string(JSON.stringify(used.battle))
