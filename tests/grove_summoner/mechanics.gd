extends "res://tests/grove_summoner/probe.gd"
## Lawful development histories only. Earned campaigns are verified separately.
var attacks := {"hits":0,"misses":0}
func run() -> void:
 base=OS.get_environment("GROVE_SUMMONER_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded: Dictionary=source.load_pack("res://data/rules/trhgd-character-v33.json")
 check(loaded.ok,"current33 complete schema "+JSON.stringify(loaded.get("errors",[])))
 if not loaded.ok:finish_cohort();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GROVE_SUMMONER_RESTART")=="1":cold_cohort();finish_cohort(true);return
 fixtures.fighter=build("fighter",12)
 var roots := {"grove-shaman":route(repeated("spirit-shaman",6),WIZARD_ARRAY,"grove-warden"),"grove-druid":route(["spirit-shaman"]+repeated("druid",5),WIZARD_ARRAY,"grove-warden"),"bonded-wizard":route(repeated("wizard",5),WIZARD_ARRAY,"bonded-summoner"),"bonded-sorcerer":route(repeated("sorcerer",6),DUAL_ARRAY,"bonded-summoner")}
 for key in roots:
  var r: Dictionary=roots[key];check(not r.is_empty(),"legal parent "+key)
  if r.is_empty():continue
  saved_records[key+"-prefix"]=r.duplicate(true)
  var path: String="grove-warden"if str(key).begins_with("grove")else"bonded-summoner"
  var parent: String=str(key).split("-")[1];parent="spirit-shaman"if parent=="shaman"else parent
  for level in range(1,4 if path=="grove-warden"else 6):
   r=advance_parent(r,path,parent)
   if r.is_empty():break
   saved_records[key+str(level)]=r.duplicate(true)
   var snap: Dictionary=kernel.derive_character(r).snapshot
   check(snap.class_levels[path]==level and snap.casting_levels[parent]==roots[key].advancement_history.size()-(1 if key=="grove-druid"else 0)+level,"selected real caster advances exactly once per prestige level "+key+str(level))
 if failures:finish_cohort();return
 test_entry();test_aura();test_renewal();test_casting();test_calls();test_creature_roles();test_limits();test_forms();test_late()
 persist_cohort();finish_cohort()
func advance_parent(record: Dictionary,path: String,parent: String) -> Dictionary:
 var proposed: Dictionary=kernel.suggested_choice(record,path)
 check(proposed.ok,"legal prestige suggestion "+path)
 if not proposed.ok:return {}
 if not record.advancement_history.any(func(s: Dictionary):return s.class_id==path):proposed.choice.specialisations["grove-casting"if path=="grove-warden"else"bonded-casting"]=parent
 if (record.advancement_history.size()+1)%4==0:proposed.choice.attribute_increase=source.definition("classes",parent).casting_attribute
 var out: Dictionary=kernel.preview_advancement(record,proposed.choice)
 check(out.ok,"deliberate persistent parent choice "+parent+JSON.stringify(out.get("errors",[])))
 return learn(out.candidate,out.snapshot)if out.ok else {}
func encounter(record: Dictionary) -> Dictionary:
 var b: Dictionary=super.encounter(record);var engine := TacticalAuras.new(record)
 b.units.b.position=[0,4];b.units.c.position=[0,5];b.units["bandit-bow"].position=[6,4]
 if not record.runtime.companions.is_empty():
  var original: Dictionary=record.runtime.companions.values()[0];var pid: String=RulesEntities.identity("a")
  var pet_record: Dictionary=original.record.duplicate(true);pet_record.character_id=pid
  b.units.a.record.runtime.companions={pid:{"definition_id":original.definition_id,"record":pet_record.duplicate(true)}}
  if pet_record.runtime.hp==0:b.units.erase(pid);b.order.erase(pid)
  else:b.units[pid].record=pet_record
 for actor in b.units.values():
  if actor.has("entity"):actor.position=[1,0]
 b.cursor=b.order.find("a");b=engine.seal(b)
 check(engine.validate(b).is_empty(),"valid original board and preserved owner/creature state "+engine.validate(b));return b
func turn(engine: TacticalAuras,battle: Dictionary,id: String) -> Dictionary:
 var b: Dictionary=battle.duplicate(true)
 for n in 120:
  if engine.current(b).id==id and b.budget.main==1:return b
  var out: Dictionary=engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"})
  check(out.ok,"original next-turn authority")
  if not out.ok:return b
  b=out.battle
 check(false,"requested living actor gets a legal activation");return b
func rounds(engine: TacticalAuras,battle: Dictionary,count: int) -> Dictionary:
 var b: Dictionary=battle.duplicate(true);var until: int=int(b.round)+count
 for n in 240:
  if b.round>=until:return b
  var out: Dictionary=engine.command(b,{"actor_id":engine.current(b).id,"revision":b.revision,"kind":"end"})
  check(out.ok,"original global-round boundary")
  if not out.ok:return b
  b=out.battle
 check(false,"bounded round progression");return b
func deny(engine: TacticalAuras,battle: Dictionary,ability: String,target: String,reason: String) -> void:
 var before := RulesJson.digest(battle);var out: Dictionary=execute(engine,battle,ability,target)
 check(not out.ok and before==RulesJson.digest(battle),"invalid command preserves actions/resources/log/RNG: "+reason)
func test_entry() -> void:
 for path in ["grove-warden","bonded-summoner"]:
  check(not kernel.starting_classes().has(path),"prestige absent from starting classes")
  var blank: Dictionary=kernel.create("forged-birth",WIZARD_ARRAY,"heritage-human")
  var forged: Dictionary=kernel.suggested_choice(blank,path)
  check(not forged.ok or not kernel.preview_advancement(blank,forged.choice).ok,"forged prestige-at-birth rejected by authority")
  var key: String="grove-shaman-prefix"if path=="grove-warden"else"bonded-wizard-prefix"
  var r: Dictionary=saved_records[key];var before := RulesJson.digest(r)
  check(kernel.available_advancement(r).classes[path].ok,"genuine permanent entry recognised "+path)
  var decline: Dictionary=kernel.suggested_choice(r,"spirit-shaman"if path=="grove-warden"else"wizard")
  check(decline.ok and kernel.preview_advancement(r,decline.choice).ok,"qualified character can decline prestige")
  check(RulesJson.digest(r)==before and not kernel.derive_character(r).snapshot.class_levels.has(path),"eligibility/preview never automatically enters prestige")
 var missing: Dictionary=route(["spirit-shaman"]+repeated("cleric",5),WIZARD_ARRAY,"grove-warden")
 check(not missing.is_empty() and not kernel.available_advancement(missing).classes["grove-warden"].ok,"Grove no longer offers an impossible nature parent")
 var weak: Dictionary=route(["wizard"]+repeated("sorcerer",2)+repeated("fighter",2),DUAL_ARRAY,"bonded-summoner")
 check(not weak.is_empty() and not kernel.available_advancement(weak).classes["bonded-summoner"].ok,"aggregate caster score does not replace actual tier3 spells")
 if not weak.is_empty():
  var temporary: Dictionary=weak.duplicate(true)
  var feature: String=""
  for row in source.definition("classes","wizard").features:
   if row.at==5 and source.definition("features",row.id).tags.has("casting_tier"):feature=row.id;break
  check(not feature.is_empty(),"existing real casting-tier feature found")
  if not feature.is_empty():
   temporary.runtime.granted_features.append(feature)
   var replay: Dictionary=kernel._replay(temporary)
   if replay.ok:temporary.runtime.resources=replay.context.capacities.duplicate(true)
   check(kernel.validate_build(temporary).ok and not kernel.available_advancement(temporary).classes["bonded-summoner"].ok,"temporary granted spell features cannot satisfy permanent entry")
 for spec in [["grove-shaman3","grove-warden"],["bonded-wizard5","bonded-summoner"]]:
  var r: Dictionary=saved_records[spec[0]];var next: Dictionary=kernel.suggested_choice(r,spec[1])
  check(not next.ok or not kernel.preview_advancement(r,next.choice).ok,"authored prestige cap remains enforced "+spec[1])
 contracts.entry=true
func test_aura() -> void:
 var r: Dictionary=saved_records["grove-druid1"];var engine := TacticalAuras.new(r);var b: Dictionary=encounter(r)
 b.units.b.position=[1,3];b.units.c.position=[1,4];b=engine.seal(b)
 var before: Dictionary={"b":engine.stats(b.units.b),"c":engine.stats(b.units.c),"enemy":engine.stats(b.units["bandit-blade"]),"pet":engine.stats(b.units["a:companion"])}
 var out: Dictionary=execute(engine,b,"grove-protection-1","a");check(out.ok,"paid actual sanctuary")
 if not out.ok:return
 var active: Dictionary=out.battle
 check(active.budget.main==0 and active.units.a.record.runtime.resources["grove-favour"]==b.units.a.record.runtime.resources["grove-favour"]-1,"sanctuary main/favour spent exactly once")
 check(engine.stats(active.units.b).defence==before.b.defence+3 and engine.stats(active.units.b).will==before.b.will+3,"radius2 ally receives real Defence/Will protection")
 check(engine.stats(active.units.c).defence==before.c.defence and engine.stats(active.units["bandit-blade"]).defence==before.enemy.defence,"out-of-range ally and nearby enemy excluded")
 check(engine.stats(active.units["a:companion"]).defence==before.pet.defence+3,"actual permanent companion benefits from sanctuary")
 var escaped: Dictionary=active.duplicate(true);escaped.units.b.position=[0,4];escaped=engine.seal(escaped)
 check(engine.stats(escaped.units.b).defence==before.b.defence,"leaving sanctuary loses projection without changing the spell record")
 var blocked: Dictionary=active.duplicate(true);blocked.units.b.position=[4,1];blocked=engine.seal(blocked)
 check(engine.stats(blocked.units.b).defence==before.b.defence,"blocked line of sight prevents aura projection")
 var fallen: Dictionary=active.duplicate(true);fallen.units.a.record.runtime.hp=0;fallen=engine.seal(fallen)
 check(engine.stats(fallen.units.b).defence==before.b.defence,"incapacitated provider cannot project protection")
 var expired: Dictionary=rounds(engine,active,3)
 check(not expired.units.a.record.runtime.statuses.any(func(s: Dictionary):return s.id=="ancestral-sanctuary") and engine.stats(expired.units.b).defence==before.b.defence,"three actual global boundaries expire sanctuary and projected modifiers")
 deny(engine,active,"grove-protection-1","a","main already spent")
 var empty: Dictionary=b.duplicate(true);empty.units.a.record.runtime.resources["grove-favour"]=0;empty=engine.seal(empty);deny(engine,empty,"grove-protection-1","a","no favour")
 battles.sanctuary=active;contracts.aura=true
func test_renewal() -> void:
 for level in [2,3]:
  var r: Dictionary=saved_records["grove-druid"+str(level)];var engine := TacticalAuras.new(r);var b: Dictionary=encounter(r);var aid := "grove-protection-"+str(level)
  b.units.b.position=[1,2];b.units.c.position=[1,3]
  for id in ["b","c","a:companion"]:b.units[id].record.runtime.hp=1
  b.units.b.record.runtime.statuses.append({"id":"weakened","source":"development-fixture","remaining":3,"expiry":"global_round_start"});b=engine.seal(b)
  var out: Dictionary=execute(engine,b,aid,"b");check(out.ok,"actual ally renewal "+aid)
  if out.ok:
   check(out.battle.units.b.record.runtime.hp>1,"renewal really restores capped HP")
   if level==2:check(not out.battle.units.b.record.runtime.statuses.any(func(s: Dictionary):return s.id=="weakened") and out.battle.units.c.record.runtime.hp==1,"single ally cleanse/heal has no phantom area")
   else:check(out.battle.units.c.record.runtime.hp>1 and out.battle.units.b.record.runtime.temporary_hp==12 and kernel.derive_character(out.battle.units.b.record).snapshot.capabilities.resistances.physical==2,"final area renewal heals/guards real nearby allies")
   check(out.battle.budget.main==0 and out.battle.units.a.record.runtime.resources["grove-favour"]==b.units.a.record.runtime.resources["grove-favour"]-1,"renewal spends one main and one favour")
   battles[aid]=out.battle
  deny(engine,b,aid,"bandit-blade","enemy cannot receive ally renewal")
  var distant: Dictionary=b.duplicate(true);distant.units.b.position=[7,5];distant=engine.seal(distant);deny(engine,distant,aid,"b","ally beyond range4")
  var pet: Dictionary=execute(engine,b,aid,"a:companion");check(pet.ok and pet.battle.units["a:companion"].record.runtime.hp>1,"actual owned animal is a legal renewal target")
 contracts.renewal=true
func test_casting() -> void:
 for key in ["grove-shaman3","grove-druid3","bonded-wizard5","bonded-sorcerer5"]:
  var r: Dictionary=saved_records[key];var d: Dictionary=kernel.derive_character(r)
  var cls: String="spirit-shaman"if key.begins_with("grove-shaman")else"druid"if key.begins_with("grove")else"wizard"if key.begins_with("bonded-wizard")else"sorcerer"
  var permanent_known: bool=source.definition("classes",cls).get("spell_mode")=="spontaneous" and not RulesWaveFive.retrieval_class(cls,source)
  var legal: Array=d.snapshot.abilities.filter(func(id: String):var row: Dictionary=source.definition("abilities",id);return row.get("casting_class")==cls and row.tags.has("spell") and not row.has("channel_spell") and RulesCoreContent.spell_eligible(d.snapshot,row) and (not permanent_known or r.choices.prepared_abilities.has(id)) and not row.effects.any(func(f: Dictionary):return f.op=="summon"))
  legal.sort_custom(func(a: String,b: String):return source.definition("abilities",a).spell_tier>source.definition("abilities",b).spell_tier if source.definition("abilities",a).spell_tier!=source.definition("abilities",b).spell_tier else a<b)
  check(not legal.is_empty(),"real advanced parent spell choices "+cls)
  if legal.is_empty():continue
  var aid: String=legal[0]
  if not permanent_known:r=prep(r,aid)
  var target: Dictionary=fixtures.fighter.duplicate(true);target.runtime.hp=1
  if permanent_known:
   var unknown: Array=d.snapshot.abilities.filter(func(id: String):return source.definition("abilities",id).get("casting_class")==cls and source.definition("abilities",id).tags.has("spell") and not r.choices.prepared_abilities.has(id))
   check(not unknown.is_empty() and not use(r,target,unknown[0]).ok,"unlearned spontaneous spell remains unavailable rather than rewriting known history")
  var out: Dictionary=use(r,target,aid);check(out.ok,"advanced selected parent spell actually executes "+aid+JSON.stringify(out.get("errors",[])))
  if out.ok:
   for pool in source.definition("abilities",aid).cost.resources:check(out.actor.runtime.resources[pool]==r.runtime.resources[pool]-source.definition("abilities",aid).cost.resources[pool],"exact selected spell pool/copy cost "+pool)
   var reserve: String="grove-favour"if key.begins_with("grove")else"bonded-summoner-uses"
   check(out.actor.runtime.resources[reserve]==r.runtime.resources[reserve],"spells cannot borrow prestige resources")
   saved_records[key+"-spell-spent"]=out.actor
   var spent: Dictionary=r.duplicate(true)
   for pool in source.definition("abilities",aid).cost.resources:spent.runtime.resources[pool]=0
   check(not use(spent,target,aid).ok,"exhausted advanced spell denied")
   var rested: Dictionary=RulesEffects.new(source).refresh_resources(out.actor.runtime,d.snapshot.resource_capacities,"eligible_rest")
   check(rested.ok and rested.runtime.resources[reserve]==d.snapshot.resource_capacities[reserve],"eligible rest restores finite owned pools")
 var hybrid: Dictionary=route(repeated("wizard",5)+["sorcerer"]+repeated("bonded-summoner",3),DUAL_ARRAY,"bonded-summoner",{"bonded-casting":"sorcerer"})
 check(not hybrid.is_empty(),"legal explicit junior spontaneous parent")
 if not hybrid.is_empty():
  var snap: Dictionary=kernel.derive_character(hybrid).snapshot
  check(snap.casting_levels.wizard==5 and snap.casting_levels.sorcerer==4 and not snap.resource_capacities.has("sorcerer-slots-3"),"junior parent advances independently without borrowing Wizard tiers")
  saved_records.junior_parent=hybrid
 contracts.casting=true
func test_calls() -> void:
 for level in [1,3,5]:
  var r: Dictionary=saved_records["bonded-wizard"+str(level)];var engine := TacticalAuras.new(r);var b: Dictionary=encounter(r);var aid := "bonded-summoner-technique-"+str(level)
  var before := RulesJson.digest(b);var out: Dictionary=execute(engine,b,aid,"a");check(out.ok,"original finite prestige call preserved "+aid)
  if not out.ok:continue
  var active: Array=out.battle.units.values().filter(func(u: Dictionary):return u.get("entity",{}).get("kind")=="summon" and engine.alive(u))
  check(active.size()==1 and active[0].entity.owner_id=="a" and active[0].entity.remaining==3+level,"owned temporary identity/duration correct")
  check(active[0].record.advancement_history.size()==int(r.advancement_history.size()/2),"summon scales from actual owner level, not borrowed caster tiers")
  check(out.battle.budget.main==0 and out.battle.units.a.record.runtime.resources["bonded-summoner-uses"]==b.units.a.record.runtime.resources["bonded-summoner-uses"]-1,"one main and finite class use")
  for pool in b.units.a.record.runtime.resources:
   if pool!="bonded-summoner-uses":check(out.battle.units.a.record.runtime.resources[pool]==b.units.a.record.runtime.resources[pool],"class call does not consume unrelated spell or copy resource")
  check(before==RulesJson.digest(b) and out.battle.state_hash==execute(engine,JSON.parse_string(JSON.stringify(b)),aid,"a").battle.state_hash,"exact source immutability and summon/log/RNG replay")
  var ready: Dictionary=turn(engine,out.battle,"a");deny(engine,ready,aid,"a","existing active summon blocks a second call without paying")
  var next: Dictionary=engine.command(out.battle,{"actor_id":"a","revision":out.battle.revision,"kind":"end"})
  check(next.ok and engine.current(next.battle).id==active[0].id and next.battle.budget=={"main":1,"move":1},"new summon receives its own real activation immediately after caster")
  var moved: Dictionary=engine.command(next.battle,{"actor_id":active[0].id,"revision":next.battle.revision,"kind":"move","destination":[2,0]})
  check(moved.ok and moved.battle.units[active[0].id].position==[2,0] and moved.battle.budget=={"main":1,"move":0},"summoned actor really moves through original paths/hitboxes and keeps its attack")
  if not moved.ok:continue
  var creature: Dictionary=moved.battle;creature.rng=attack_seed(19);creature=engine.seal(creature)
  var hit: Dictionary=execute(engine,creature,"attack","bandit-blade");check(hit.ok and hit.battle.units["bandit-blade"].record.runtime.hp<creature.units["bandit-blade"].record.runtime.hp,"actual summoned creature natural attack damages a legal enemy")
  if hit.ok:attacks.hits+=1;battles["call-hit"+str(level)]=hit.battle
  var weak: Dictionary=creature.duplicate(true);weak.rng=attack_seed(1);weak=engine.seal(weak)
  var miss: Dictionary=execute(engine,weak,"attack","bandit-blade")
  check(miss.ok and miss.battle.units["bandit-blade"].record.runtime.hp==weak.units["bandit-blade"].record.runtime.hp and miss.battle.log.back().ends_with("miss."),"real numeric miss consumes the summon attack without damage")
  if miss.ok:attacks.misses+=1;battles["call-miss"+str(level)]=miss.battle
  var ended: Dictionary=rounds(engine,out.battle,3+level)
  check(not engine.alive(ended.units[active[0].id]) and ended.units[active[0].id].entity.remaining==0,"original global duration expires actor without making a permanent companion")
  saved_records["spent-call"+str(level)]=out.battle.units.a.record;battles["active-call"+str(level)]=out.battle
 contracts.calls=true
func test_creature_roles() -> void:
 var r: Dictionary=saved_records["bonded-wizard5"]
 for pair in [["bonded-summoner-call-leopard","leopard-special","enemy"],["bonded-summoner-call-renewal-spirit","renewal-spirit-special","ally"],["bonded-summoner-call-stone-guardian","stone-guardian-special","enemy"],["call-ember-spirit","ember-spirit-special","enemy"],["call-frost-hound","frost-hound-special","enemy"],["call-bulwark-construct","bulwark-construct-special","self"],["call-thorn-guardian","thorn-guardian-special","enemy"]]:
  var engine := TacticalAuras.new(r);var b: Dictionary=encounter(r);var called: Dictionary=execute(engine,b,pair[0],"a");check(called.ok,"existing distinct roster call "+pair[0])
  if not called.ok:continue
  var next: Dictionary=engine.command(called.battle,{"actor_id":"a","revision":called.battle.revision,"kind":"end"});check(next.ok,"real summoned role turn")
  if not next.ok:continue
  b=next.battle;var id: String=engine.current(b).id;b.units[id].position=[2,0]
  var target: String="bandit-blade"if pair[2]=="enemy"else"a"if pair[2]=="ally"else id
  if pair[2]=="ally":b.units.a.record.runtime.hp=1
  if pair[1]=="frost-hound-special":b.rng=attack_seed(1)
  b=engine.seal(b);var out: Dictionary=execute(engine,b,pair[1],target)
  check(out.ok,"actual distinct creature effect "+pair[1]+str(out.get("error","")))
  if out.ok:
   check(out.battle.budget.main==0,"creature special competes with its natural attack main action")
   for pool in source.definition("abilities",pair[1]).cost.resources:check(out.battle.units[id].record.runtime.resources[pool]==b.units[id].record.runtime.resources[pool]-source.definition("abilities",pair[1]).cost.resources[pool],"creature spends its own finite effort")
   check(RulesJson.digest(out.battle.units[target].record.runtime)!=RulesJson.digest(b.units[target].record.runtime),"creature role has a real saved target effect")
   battles[pair[0]]=out.battle
   var empty: Dictionary=b.duplicate(true)
   for pool in source.definition("abilities",pair[1]).cost.resources:empty.units[id].record.runtime.resources[pool]=0
   empty=engine.seal(empty);deny(engine,empty,pair[1],target,"creature effort exhausted")
  if pair[1]=="frost-hound-special":
   var resisted: Dictionary=b.duplicate(true);resisted.rng=attack_seed(19);resisted=engine.seal(resisted)
   var blocked: Dictionary=execute(engine,resisted,pair[1],target)
   check(blocked.ok and not blocked.battle.units[target].record.runtime.statuses.any(func(st: Dictionary):return st.id=="slowed") and blocked.battle.units[id].record.runtime.resources["creature-effort"]==resisted.units[id].record.runtime.resources["creature-effort"]-1,"successful real Fortitude save resists control while its action/effort is still paid")
 contracts.creatures=true
func test_limits() -> void:
 var r: Dictionary=saved_records["bonded-wizard5"];var engine := TacticalAuras.new(r);var b: Dictionary=encounter(r)
 var empty: Dictionary=b.duplicate(true);empty.units.a.record.runtime.resources["bonded-summoner-uses"]=0;empty=engine.seal(empty);deny(engine,empty,"bonded-summoner-technique-5","a","class reserve exhausted")
 var blocked: Dictionary=b.duplicate(true)
 # Every adjacent tile is occupied or blocked; original placement authority denies atomically.
 blocked.units.b.position=[0,1];blocked.units.c.position=[1,0];blocked.units["bandit-bow"].position=[1,2];blocked=engine.seal(blocked)
 deny(engine,blocked,"bonded-summoner-technique-5","a","no clear adjacent placement")
 var called: Dictionary=execute(engine,b,"bonded-summoner-technique-5","a")
 if called.ok:
  var id: String=called.battle.order[int(called.battle.cursor)+1]
  var dead: Dictionary=called.battle.duplicate(true);dead.units[id].record.runtime.hp=0;dead=engine.seal(dead);dead=turn(engine,dead,"a")
  var replace: Dictionary=execute(engine,dead,"bonded-summoner-technique-5","a")
  check(replace.ok and replace.battle.units[id].record.runtime.hp==0 and replace.battle.order[int(replace.battle.cursor)+1]!=id,"a paid replacement has a fresh identity and never revives a defeated summoned record")
  var fallen: Dictionary=called.battle.duplicate(true);fallen.units.a.record.runtime.hp=0;fallen=engine.seal(fallen)
  var after: Dictionary=rounds(engine,fallen,1)
  check(not engine.alive(after.units[id]) and after.units[id].record.runtime.hp==fallen.units[id].record.runtime.hp,"owner defeat withdraws summon at existing global boundary without rewriting HP")
  battles.owner_down=after
 var nature: Dictionary=saved_records["grove-druid3"];var natural: Dictionary=prep(nature,"druid-summon-sentinel");engine=TacticalAuras.new(natural);b=encounter(natural)
 var spell: Dictionary=execute(engine,b,"druid-summon-sentinel","a")
 check(spell.ok and spell.battle.units.has("a:companion") and spell.battle.units.size()==b.units.size()+1,"temporary spell summon coexists with exactly one permanent nature companion")
 var wizard: Dictionary=prep(r,"wizard-summon-sentinel");engine=TacticalAuras.new(wizard);b=encounter(wizard)
 var class_call: Dictionary=execute(engine,b,"bonded-summoner-technique-5","a")
 if class_call.ok:
  var id: String=class_call.battle.order[int(class_call.battle.cursor)+1];var ready: Dictionary=turn(engine,class_call.battle,"a")
  deny(engine,ready,"wizard-summon-sentinel","a","spell and class calls share one active summon limit")
  var dismissed: Dictionary=engine.command(ready,{"actor_id":"a","revision":ready.revision,"kind":"dismiss","target_id":id})
  check(dismissed.ok and not engine.alive(dismissed.battle.units[id]) and dismissed.battle.budget.main==0,"only the owner dismisses with a real main action")
  if dismissed.ok:
   ready=turn(engine,dismissed.battle,"a");var new_spell: Dictionary=execute(engine,ready,"wizard-summon-sentinel","a")
   check(new_spell.ok and new_spell.battle.units.a.record.runtime.resources["bonded-summoner-uses"]==ready.units.a.record.runtime.resources["bonded-summoner-uses"],"after dismissal a real prepared spell summons using only its own slots/copies")
   if new_spell.ok:
    ready=turn(engine,new_spell.battle,"a");deny(engine,ready,"bonded-summoner-technique-5","a","a spell summon also excludes the prestige call")
    battles.shared_limit=new_spell.battle
  var wrong: Dictionary=class_call.battle.duplicate(true);wrong.cursor=wrong.order.find("b");wrong.budget={"main":1,"move":1};wrong=engine.seal(wrong)
  var forbidden: Dictionary=engine.command(wrong,{"actor_id":"b","revision":wrong.revision,"kind":"dismiss","target_id":id})
  check(not forbidden.ok,"another adventurer cannot dismiss a creature they do not own")
 contracts.limits=true
func test_forms() -> void:
 var nature: Dictionary=saved_records["grove-druid3"];var altered: Dictionary=use(nature,nature,"wild-shape");check(altered.ok,"real owned form for Grove suppression")
 if altered.ok:
  var b: Dictionary=encounter(altered.actor);var engine := TacticalAuras.new(altered.actor);deny(engine,b,"grove-protection-1","a","transformed supernatural Grove casting suppressed")
  saved_records.grove_form=altered.actor
 var druid: Dictionary=prep(build("druid",20),"druid-wildheart-mantle")
 var bonded: Dictionary=saved_records["bonded-wizard5"];var form: Dictionary=use(druid,bonded,"druid-wildheart-mantle");check(form.ok,"real ally form suppresses magical class calls")
 if form.ok:
  var b: Dictionary=encounter(form.target);var engine := TacticalAuras.new(form.target)
  for id in kernel.derive_character(bonded).snapshot.abilities:
   if source.definition("abilities",id).effects.any(func(e: Dictionary):return e.op=="summon") and not source.definition("abilities",id).tags.has("spell"):deny(engine,b,id,"a","typed supernatural call cannot bypass transformed body "+id)
  saved_records.bonded_form=form.target
 contracts.forms=true
func test_late() -> void:
 for spec in [["grove-shaman3","spirit-shaman"],["grove-druid3","druid"],["bonded-wizard5","wizard"],["bonded-sorcerer5","sorcerer"]]:
  var r: Dictionary=saved_records[spec[0]]
  while r.advancement_history.size()<20:
   var proposed: Dictionary=kernel.suggested_choice(r,spec[1]);check(proposed.ok,"lawful continuation toward total20")
   if not proposed.ok:break
   var out: Dictionary=kernel.preview_advancement(r,proposed.choice);check(out.ok,"ordinary parent continuation preserves earned prestige history")
   if not out.ok:break
   r=learn(out.candidate,out.snapshot)
  check(r.advancement_history.size()==20 and not kernel.available_advancement(r).classes[spec[1]].ok,"total20 cap and selected prestige history remain real")
  saved_records[spec[0]+"-total20"]=r
 contracts.late=true
func persist_cohort() -> void:
 var payload := {"records":{},"hashes":{},"record_hashes":{},"battles":battles,"next":{},"after":{}}
 for key in saved_records:
  var r: Dictionary=RulesJson.string_keys(saved_records[key]);var d: Dictionary=kernel.derive_character(r);check(d.ok,"full saved character valid "+key+JSON.stringify(d.get("errors",[])))
  if d.ok:payload.records[key]=r;payload.hashes[key]=d.snapshot.snapshot_hash;payload.record_hashes[key]=RulesJson.digest(r)
 for key in battles:
  var engine := TacticalAuras.new(battles[key].units.a.record);check(engine.validate(battles[key]).is_empty(),"saved battle valid "+key)
  var cmd := {"actor_id":engine.current(battles[key]).id,"revision":battles[key].revision,"kind":"end"};var out: Dictionary=engine.command(battles[key],cmd);check(out.ok,"saved next deterministic command "+key)
  if out.ok:payload.next[key]=cmd;payload.after[key]=out.battle.state_hash
 FileAccess.open(base.path_join("saved.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(payload)))
func cold_cohort() -> void:
 var p: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 for key in p.records:
  var r: Dictionary=p.records[key];var d: Dictionary=kernel.derive_character(r)
  check(d.ok and d.snapshot.snapshot_hash==p.hashes[key] and RulesJson.digest(r)==p.record_hashes[key],"exact cold history/parent/choice/form/resources "+key)
 for key in p.battles:
  var engine := TacticalAuras.new(p.battles[key].units.a.record);check(engine.validate(p.battles[key]).is_empty(),"cold owned/aura battle valid "+key)
  var out: Dictionary=engine.command(p.battles[key],p.next[key]);check(out.ok and out.battle.state_hash==p.after[key],"exact cold next command/expiry/log/RNG "+key)
func finish_cohort(restart := false) -> void:
 var proof := {"checks":checks,"failures":failures,"failed_checks":failed_checks,"rules_ref":source.rules_ref(),"contracts":contracts,"attacks":attacks,"development_fixtures":true,"earned_xp":false}
 FileAccess.open(base.path_join("restart-proof.json"if restart else"proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GROVE_SUMMONER ",JSON.stringify(proof))
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
