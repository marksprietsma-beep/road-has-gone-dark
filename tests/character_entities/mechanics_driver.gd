extends Node
signal completed
var no_quit := false
var checks := 0
var failures := 0
var source: RulesRegistry
var kernel: RulesCharacter
var root_path := ""
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(message)
func build(id: String,cls: String,levels: int,ancestry: String="heritage-human") -> Dictionary:
 var record := kernel.create(id,source.recommendation("adept").attributes,ancestry)
 for n in levels:
  var proposed := kernel.suggested_choice(record,cls)
  check(proposed.ok,"choice "+cls+str(n))
  if not proposed.ok:return {}
  var step := kernel.preview_advancement(record,proposed.choice)
  check(step.ok,"advancement "+cls+str(n)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  record=step.candidate
 record.runtime.hp=int(kernel.derive_character(record).snapshot.stats.HP)
 return record
func fixture(record: Dictionary) -> Dictionary:
 var state := {"world_ref":{"id":"entity-testing"},"origin":{"home_burg_id":1},"party_ids":["a","b","c"],"party":{"members":[{"name":"Druid"},{"name":"Fighter"},{"name":"Wizard"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":{"a":record}}}
 for id in ["b","c"]:state.mechanics.records[id]=build(id,"fighter",1)
 var engine := TacticalCombat.new(state);var battle := engine.create(state,"entity-testing")
 if battle.is_empty():return {}
 battle.cursor=battle.order.find("a")
 return engine.seal(battle)
func issue(engine: TacticalCombat,battle: Dictionary,kind: String,target: String="a") -> Dictionary:
 var result := engine.command(battle,{"actor_id":engine.current(battle).id,"revision":battle.revision,"kind":kind,"target_id":target})
 check(result.ok,"command "+kind+str(result.get("error","")))
 if result.ok:
  check(engine.validate(result.battle).is_empty(),"valid after "+kind+engine.validate(result.battle))
  check(engine.validate(JSON.parse_string(JSON.stringify(result.battle))).is_empty(),"JSON battle reload "+kind+": "+engine.validate(JSON.parse_string(JSON.stringify(result.battle))))
 return result
func _ready() -> void:call_deferred("run")
func run() -> void:
 root_path=OS.get_environment("GAME112W2_TEST_ROOT")
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v12.json")
 check(loaded.ok,"v12 loads "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:get_tree().quit(1);return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME112W2_RESTART")=="1":
  var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("restart-state.json")))
  for record in saved.records.values():check(kernel.validate_build(record).ok,"separate-process character and companion reload "+JSON.stringify(kernel.validate_build(record).get("errors",[])))
  var engine := TacticalCombat.new(saved.records.a)
  check(engine.validate(saved.battle).is_empty(),"separate-process active transformed/summoned battle reload")
  check(saved.battle.state_hash==saved.battle_hash,"persisted command checksum exact")
  var command: Dictionary=saved.command
  var replay := engine.command(saved.battle,command)
  check(replay.ok and replay.battle.state_hash==saved.expected_hash,"separate-process next command deterministic")
  finish();return
 var druid := build("a","druid",5)
 var ranger := build("r","ranger",7)
 check(druid.runtime.companions.size()==1,"one persistent Druid companion")
 check(druid.runtime.companions["a:companion"].record.advancement_history.size()==5,"Druid companion scales with class level")
 check(ranger.runtime.companions["r:companion"].record.advancement_history.size()==4,"Ranger companion uses distinct level-minus-three progression")
 var bad := druid.duplicate(true);bad.runtime.companions["a:companion"].record.character_id="stolen"
 check(not kernel.validate_build(bad).ok,"reject stolen ownership")
 bad=druid.duplicate(true);bad.runtime.companions["a:companion"].record.runtime.companions={"loop":{}}
 check(not kernel.validate_build(bad).ok,"reject recursive companions")
 bad=druid.duplicate(true);bad.runtime.companions["a:companion"].record.base_attributes.STR=15
 check(not kernel.validate_build(bad).ok,"reject forged creature stats")
 var engine := TacticalCombat.new(druid);var battle := fixture(druid)
 check(battle.order.size()==6 and engine.validate(battle).is_empty(),"permanent companion placed in real encounter")
 var pet: Dictionary=battle.units["a:companion"]
 # Keep all placements distinct; place a real target in its natural attack range.
 battle.units["bandit-blade"].position=[pet.position[0]+1,pet.position[1]]
 if not engine.inside(battle,battle.units["bandit-blade"].position) or engine.occupant(battle,battle.units["bandit-blade"].position)!="bandit-blade":battle.units["bandit-blade"].position=[pet.position[0],pet.position[1]+1]
 battle.cursor=battle.order.find(pet.id);battle=engine.seal(battle)
 var attack := issue(engine,battle,"attack","bandit-blade")
 if not attack.ok:finish();return
 check(attack.battle.commands.back().actor_id==pet.id and attack.battle.budget.main==0,"companion participates through ordinary action authority")
 check(attack.battle.units.a.record.runtime.companions[pet.id].record==attack.battle.units[pet.id].record,"companion state persisted in owner")
 var replay := engine.command(battle,attack.battle.commands.back())
 check(replay.ok and replay.battle.state_hash==attack.battle.state_hash,"companion action exact RNG/replay")
 battle=fixture(druid);var original: Dictionary= kernel.derive_character(battle.units.a.record).snapshot
 battle.units.a.record.runtime.hp-=3
 var hp: int=int(battle.units.a.record.runtime.hp)
 var shaped := issue(engine,battle,"wild-shape")
 if not shaped.ok:finish();return
 var form: Dictionary=kernel.derive_character(shaped.battle.units.a.record).snapshot
 check(form.attributes.STR==int(original.attributes.STR)+4 and form.stats.reach==2,"shape actual Strength and reach")
 check(form.stats.HP==original.stats.HP and form.current_hp==hp,"form preserves maximum HP and existing damage")
 check(shaped.battle.units.a.record.ancestry_ref==druid.ancestry_ref,"shape retains original ancestry")
 check(form.abilities.all(func(id: String):return not source.definition("abilities",id).tags.has("spell")),"form suppresses spellcasting")
 shaped.battle.budget.main=1;shaped.battle=engine.seal(shaped.battle)
 var reverted := issue(engine,shaped.battle,"revert-form")
 if not reverted.ok:finish();return
 check(kernel.derive_character(reverted.battle.units.a.record).snapshot.body_form.is_empty() and reverted.battle.units.a.record.runtime.hp==hp,"revert removes form without healing")
 var stacked: Dictionary= shaped.battle.units.a.record.duplicate(true)
 stacked.runtime.statuses.append({"id":"wolf-form","remaining":3,"expiry":"global_round_start","source":"a"})
 check(not kernel.validate_build(stacked).ok,"reject simultaneous body forms")
 # Actual prepared spell resources; zero slot/copy or no free placement must reject atomically.
 var wizard := build("a","wizard",5)
 wizard.choices.prepared_abilities=["wizard-summon-sentinel"]
 wizard.choices.spell_preparations={"wizard-summon-sentinel":2}
 wizard.runtime.resources=kernel._replay(wizard).context.capacities.duplicate()
 check(kernel.validate_build(wizard).ok,"prepared summon legal")
 battle=fixture(wizard);engine=TacticalCombat.new(wizard)
 var before_hash: String=battle.state_hash
 var summoned := issue(engine,battle,"wizard-summon-sentinel")
 if not summoned.ok:finish();return
 check(battle.state_hash==before_hash and battle.units.size()==5,"command does not mutate source")
 var summon_id := "a:summon:0"
 check(summoned.battle.units.has(summon_id) and summoned.battle.order[int(summoned.battle.cursor)+1]==summon_id,"real summoned actor acts after caster")
 check(summoned.battle.units.a.record.runtime.resources["wizard-slots-1"]==int(battle.units.a.record.runtime.resources["wizard-slots-1"])-1,"summon spends actual slot")
 var duplicate: Dictionary= summoned.battle.duplicate(true);duplicate.budget.main=1;duplicate=engine.seal(duplicate)
 var denied := engine.command(duplicate,{"actor_id":"a","revision":duplicate.revision,"kind":"wizard-summon-sentinel","target_id":"a"})
 check(not denied.ok,"duplicate active summon rejected")
 var ended := issue(engine,summoned.battle,"end")
 if not ended.ok:finish();return
 check(engine.current(ended.battle).id==summon_id,"summoned creature receives legal turn")
 var living: Dictionary= ended.battle.duplicate(true)
 # Exercise ordinary movement when a free route exists.
 var route := engine.paths(living,living.units[summon_id]).values().filter(func(p: Array):return p.size()>1)
 check(not route.is_empty(),"summon has movement capability")
 if not route.is_empty():
  var moved := engine.command(living,{"actor_id":summon_id,"revision":living.revision,"kind":"move","destination":route[0].back()})
  check(moved.ok and moved.battle.budget.move==0,"summon actually moves on grid")
 # Expiration is authoritative, not cosmetic, no resources refunded.
 for n in 3:CombatEntities.round_start(engine,living)
 check(not engine.alive(living.units[summon_id]) and living.units[summon_id].entity.remaining==0,"summon expires at bounded global-round boundary")
 var dismissed: Dictionary= duplicate.duplicate(true)
 var dismiss := issue(engine,dismissed,"dismiss",summon_id)
 check(dismiss.ok and not engine.alive(dismiss.battle.units[summon_id]) and dismiss.battle.budget.main==0,"explicit dismissal costs action")
 var forged: Dictionary= summoned.battle.duplicate(true);forged.units[summon_id].entity.owner_id="b";forged=engine.seal(forged)
 check(not engine.validate(forged).is_empty(),"reject forged summon owner")
 # Save transformed character plus active summon battle and resume in a new process.
 var command := {"actor_id":"a","revision":summoned.battle.revision,"kind":"end","target_id":"a"}
 var expected := engine.command(summoned.battle,command)
 check(expected.ok,"restart command preview")
 if not root_path.is_empty():
  DirAccess.make_dir_recursive_absolute(root_path)
  FileAccess.open(root_path.path_join("restart-state.json"),FileAccess.WRITE).store_string(JSON.stringify({"records":{"a":shaped.battle.units.a.record,"r":ranger,"wizard":wizard},"battle":summoned.battle,"battle_hash":summoned.battle.state_hash,"command":command,"expected_hash":expected.battle.state_hash}))
 verify_content()
 finish()
func verify_content() -> void:
 for cls in source.ids("classes"):
  var definition := source.definition("classes",cls)
  if definition.get("class_kind")!="base":continue
  var record := build("content:"+cls,cls,int(definition.max_level))
  if record.is_empty():continue
  check(kernel.validate_build(JSON.parse_string(JSON.stringify(record))).ok,"twenty-level saved career "+cls)
  var snap: Dictionary=kernel.derive_character(record).snapshot
  for id in snap.abilities:
   var ability := source.definition("abilities",id)
   if ability.provenance.get("revision")!="game112-wave-two" or ability.tags.has("spell"):continue
   var actor: Dictionary=record.duplicate(true)
   actor.runtime.resources=snap.resource_capacities.duplicate()
   actor.runtime.hp=maxi(1,int(snap.stats.HP)-10)
   var target := build("target","fighter",1)
   var used := RulesEffects.new(source).use_ability(actor,actor if ability.targeting.kind=="self" else target,id,{"main":1,"move":1,"reaction":1},RulesRng.initial(id))
   check(used.ok,"actual expanded career ability "+id+JSON.stringify(used.get("errors",[])))
   if used.ok:check(used.budget.main==0,"expanded ability spends main "+id)
 var novice := build("novice","fighter",1)
 for path in ["warshaper","bonded-summoner"]:
  check(not kernel.available_advancement(novice).classes[path].ok,"invalid prestige entry "+path)
  var record := build("career:"+path,"druid" if path=="warshaper" else "wizard",6 if path=="warshaper" else 5)
  check(kernel.available_advancement(record).classes[path].ok,"genuine prestige prerequisites "+path)
  for n in 5:
   var advanced := kernel.preview_advancement(record,kernel.suggested_choice(record,path).choice)
   check(advanced.ok,"real prestige tier "+path+str(n)+JSON.stringify(advanced.get("errors",[])))
   if not advanced.ok:break
   record=advanced.candidate
  check(kernel.validate_build(JSON.parse_string(JSON.stringify(record))).ok,"prestige ordered history reload "+path)
 for ancestry in ["centaur","minotaur","changeling","shifter"]:
  var record := build("ancestry:"+ancestry,"fighter",1,"heritage-"+ancestry)
  check(kernel.validate_build(record).ok,"new inherited mechanics "+ancestry)
  if record.is_empty():continue
  var snap: Dictionary=kernel.derive_character(record).snapshot
  if ancestry=="centaur":check(snap.stats.stride==6 and snap.stats.reach==2,"centaur changes real movement/reach")
  if ancestry=="minotaur":check(snap.capabilities.resistances.physical==2 and snap.abilities.has("minotaur-gore"),"minotaur resistance/natural weapon")
 var mixed := kernel.create("multiclass",source.recommendation("vanguard").attributes,"heritage-human")
 for n in 20:
  var cls: String=["fighter","warblade","swordsage","crusader"][n/5]
  var next := kernel.preview_advancement(mixed,kernel.suggested_choice(mixed,cls).choice)
  check(next.ok,"twenty-level multiclass "+str(n)+JSON.stringify(next.get("errors",[])))
  if not next.ok:break
  mixed=next.candidate
 check(mixed.advancement_history.size()==20 and kernel.validate_build(JSON.parse_string(JSON.stringify(mixed))).ok,"ordered mixed history survives reload")
func finish() -> void:
 print("WAVE TWO ENTITY CHECKS ",checks," / ",failures)
 if not root_path.is_empty():FileAccess.open(root_path.path_join("restart-proof.json" if OS.get_environment("GAME112W2_RESTART")=="1" else "mechanics-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref()}," "))
 completed.emit()
 if not no_quit:get_tree().quit(1 if failures else 0)
