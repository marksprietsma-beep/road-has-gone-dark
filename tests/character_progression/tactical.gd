extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred('run')
func run():
 var source := RulesRecords.new_character_registry();var kernel := RulesCharacter.new(source)
 for cls in source.ids('classes'):
  if source.definition('classes',cls).get('class_kind')!='base':continue
  var editor := BuildEditor.new();root.add_child(editor)
  var record := kernel.create('a',source.recommendation('vanguard').attributes,'heritage-human')
  record=kernel.preview_advancement(record,kernel.suggested_choice(record,'fighter','toughness').choice).candidate
  editor.setup(record);editor.set_class(cls);record=editor.preview.candidate
  for level in range(1,int(source.definition("classes",cls).max_level)+1):
   if level>1:record=kernel.preview_advancement(record,kernel.suggested_choice(record,cls).choice).candidate
   var snapshot: Dictionary=kernel.derive_character(record).snapshot
   record.runtime.hp=int(snapshot.stats.HP)
   for id in snapshot.abilities:
    var ability := source.definition('abilities',id)
    if id in ['move','departure-attack','precision'] or ability.has('trigger') or ability.tags.has('passive'):continue
    var actor := record.duplicate(true)
    # Explicit rested development fixture; advancement does not refill spent pools.
    actor.runtime.resources=snapshot.resource_capacities.duplicate()
    if ability.tags.has('spell'):
     actor.choices.prepared_abilities=[id];actor.choices.spell_preparations={id:1} if ability.tags.has('prepared') else {};RulesCoreContent.refill_prepared(actor,source)
    var state := {'world_ref':{'id':'test-world'},'origin':{'home_burg_id':1},'party_ids':['a','b','c'],'party':{'members':[{'name':'Actor'},{'name':'Ally B'},{'name':'Ally C'}]},'mechanics':{'rules_ref':source.rules_ref(),'records':{'a':actor}}}
    for ally_id in ['b','c']:
     var ally := kernel.create(ally_id,source.recommendation('vanguard').attributes,'heritage-human')
     ally=kernel.preview_advancement(ally,kernel.suggested_choice(ally,'fighter','toughness').choice).candidate;ally.equipment=['shortblade'];ally.runtime.hp=1
     state.mechanics.records[ally_id]=ally
    var engine := TacticalCombat.new(state);var battle := engine.create(state,'test-site')
    check(not battle.is_empty(),'same authority builds real '+cls+' encounter')
    if battle.is_empty():continue
    battle.cursor=battle.order.find('a')
    battle.units.a.position=[0,0];battle.units.b.position=[0,1];battle.units.c.position=[0,2]
    var enemies: Array=battle.order.filter(func(unit_id: String):return battle.units[unit_id].team=='enemy')
    battle.units[enemies[0]].position=[1,0];battle.units[enemies[1]].position=[2,0]
    var target: String='a' if ability.targeting.kind=='self' or int(ability.targeting.get('radius',0))>0 else 'b' if ability.targeting.kind=='ally' else enemies[0]
    battle=engine.seal(battle)
    check(engine.validate(battle).is_empty(),'valid deterministic fixture')
    var command := {'actor_id':'a','revision':battle.revision,'kind':id,'target_id':target}
    var result := engine.command(battle,command)
    check(result.ok,cls+' L'+str(level)+' genuine tactical '+id+': '+str(result.get('error','')))
    if not result.ok:continue
    check(engine.validate(result.battle).is_empty(),'result valid and resources bounded')
    var replay := engine.command(battle,command)
    check(result.battle.state_hash==replay.battle.state_hash and result.battle.rng==replay.battle.rng,'exact replay logs/state/RNG')
    check(result.battle.commands.size()==1,'one authoritative command')
    if int(ability.targeting.get('radius',0))>0:
     check(int(result.battle.units.b.record.runtime.hp)>1 or not result.battle.units.b.record.runtime.statuses.is_empty(),'area effect reaches first ally')
     check(int(result.battle.units.c.record.runtime.hp)>1 or not result.battle.units.c.record.runtime.statuses.is_empty(),'area effect reaches second ally without spending again')
    if ability.tags.has('spell'):
     var unselected := battle.duplicate(true);unselected.units.a.record.choices.prepared_abilities=[];unselected.units.a.record.choices.spell_preparations={};RulesCoreContent.refill_prepared(unselected.units.a.record,source);unselected=engine.seal(unselected)
     check(not engine.command(unselected,command).ok,'unprepared or unknown spell cannot cast')
    if ability.tags.has('weapon_strike'):
     check(result.battle.log.any(func(line: String):return 'hits' in line or 'miss.' in line),'weapon technique really rolls attacks')
  editor.queue_free()
 var caster := kernel.create("save-caster",{"INT":15,"WIS":14,"CON":13,"DEX":12,"STR":10,"CHA":8},"heritage-human")
 for level in range(1,4):caster=kernel.preview_advancement(caster,kernel.suggested_choice(caster,"wizard").choice).candidate
 caster.choices.prepared_abilities=["wizard-scorching-ray"];caster.choices.spell_preparations={"wizard-scorching-ray":1};RulesCoreContent.refill_prepared(caster,source)
 var ordinary := kernel.create("ordinary",source.recommendation("vanguard").attributes,"heritage-human")
 var evader := kernel.create("evader",source.recommendation("vanguard").attributes,"heritage-human")
 for level in [1,2]:
  ordinary=kernel.preview_advancement(ordinary,kernel.suggested_choice(ordinary,"fighter").choice).candidate
  evader=kernel.preview_advancement(evader,kernel.suggested_choice(evader,"rogue").choice).candidate
 var demonstrated := false
 for seed in 40:
  var rng := RulesRng.initial("evasion:"+str(seed));var budget := {"move":1,"main":1,"reaction":1}
  var normal := RulesEffects.new(source).use_ability(caster,ordinary,"wizard-scorching-ray",budget,rng)
  var avoided := RulesEffects.new(source).use_ability(caster,evader,"wizard-scorching-ray",budget,rng)
  check(normal.ok and avoided.ok,"save-for-half resolves for both targets")
  if not normal.ok or not avoided.ok:continue
  if normal.events.any(func(event: Dictionary):return event.type=="save_resolved" and event.success):
   check(avoided.events.any(func(event: Dictionary):return event.type=="save_resolved" and event.success),"same successful save with Evasion")
   check(int(normal.target.runtime.hp)<int(ordinary.runtime.hp),"ordinary successful Reflex save takes half damage")
   check(avoided.target.runtime.hp==evader.runtime.hp,"Evasion prevents all damage after successful Reflex save")
   demonstrated=true;break
 check(demonstrated,"genuine Evasion demonstrated deterministically")
 print('GAME119 TACTICAL ',checks,' / ',failures)
 var output := OS.get_environment('GAME118_TEST_ROOT')
 if not output.is_empty():FileAccess.open(output.path_join('career-tactical-proof.json'),FileAccess.WRITE).store_string(JSON.stringify({'checks':checks,'failures':failures,'all_classes_through_level':12,'rules_ref':source.rules_ref()},'  '))
 quit(1 if failures else 0)
