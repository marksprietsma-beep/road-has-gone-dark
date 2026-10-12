extends SceneTree
var checks := 0
var failures := 0
var source: RulesRegistry
var kernel: RulesCharacter
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func first(cls: String,feat: String,heritage := "heritage-human") -> Dictionary:
 var record := kernel.create("continuation",{"STR":15,"DEX":13,"CON":12,"INT":14,"WIS":10,"CHA":8},heritage)
 record.equipment=source.definition("classes",cls).recommended_equipment.duplicate()
 var choice := kernel.suggested_choice(record,cls,feat)
 if not choice.ok:return {}
 choice.choice.feat_id=feat
 var result := kernel.preview_advancement(record,choice.choice)
 return result.get("candidate",{})
func active_feat(cls: String,feat: String,action: String) -> void:
 var actor := first(cls,feat)
 check(not actor.is_empty(),"active feat is a real starting build: "+feat)
 if actor.is_empty():return
 var state := {"world_ref":{"id":"continuation-world"},"origin":{"home_burg_id":1},"party_ids":["continuation","b","c"],"party":{"members":[{"name":"Actor"},{"name":"Ally"},{"name":"Ally"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":{"continuation":actor}}}
 for id in ["b","c"]:
  var record := kernel.create(id,source.recommendation("vanguard").attributes,"heritage-human")
  record=kernel.preview_advancement(record,kernel.suggested_choice(record,"fighter","toughness").choice).candidate
  record.equipment=["shortblade"];state.mechanics.records[id]=record
 var engine := TacticalCombat.new(state)
 var battle := engine.create(state,"continuation-site")
 check(not battle.is_empty(),"feat uses the existing tactical authority")
 if battle.is_empty():return
 battle.cursor=battle.order.find("continuation")
 battle.units.continuation.position=[0,0];battle.units.b.position=[0,1];battle.units.c.position=[0,2]
 var enemies: Array=battle.order.filter(func(id: String):return battle.units[id].team=="enemy")
 battle.units[enemies[0]].position=[1,0];battle.units[enemies[1]].position=[2,0]
 battle=engine.seal(battle)
 var command := {"actor_id":"continuation","revision":battle.revision,"kind":action,"target_id":enemies[0]}
 var result := engine.command(battle,command)
 check(result.ok,"active feat makes an actual legal weapon attack: "+action)
 if not result.ok:return
 check(result.battle.log.any(func(line: String):return "hits" in line or "miss." in line),"feat really rolls a weapon attack")
 check(not result.battle.units.continuation.record.runtime.statuses.is_empty(),"feat applies its advertised actor stance")
 check(result.battle.state_hash==engine.command(battle,command).battle.state_hash,"feat command/log/RNG replay is exact")
 if feat=="combat-expertise":
  var bow := battle.duplicate(true);bow.units.continuation.record.equipment=["bow"];bow.units.continuation.weapon="bow";bow=engine.seal(bow)
  check(not engine.command(bow,command).ok,"melee expertise cannot bypass its weapon requirement with a bow")
 if feat=="arcane-strike":
  check(result.battle.units.continuation.record.runtime.resources.focus==battle.units.continuation.record.runtime.resources.focus-1,"Arcane strike spends actual Focus")
  var empty := battle.duplicate(true);empty.units.continuation.record.runtime.resources.focus=0;empty=engine.seal(empty)
  check(not engine.command(empty,command).ok,"zero Focus blocks Arcane strike")
func run() -> void:
 source=RulesRecords.registry(JSON.parse_string(FileAccess.get_file_as_string("res://data/rules/packs.json")).packs.filter(func(row: Dictionary):return row.rules_ref.pack_id=="trhgd-character-v6")[0].rules_ref);kernel=RulesCharacter.new(source)
 check(source.ready() and source.rules_ref().pack_id=="trhgd-character-v6","explicit continuation default")
 var old: RulesRegistry
 for pin in RulesRecords.installed_packs():
  if pin.rules_ref.pack_id=="trhgd-character-v4":old=RulesRecords.registry(pin.rules_ref)
 check(old!=null and old.ready(),"previous core content remains installed")
 var old_kernel := RulesCharacter.new(old)
 for cls in source.ids("classes"):
  check(old.definition("classes",cls).max_level==6 and source.definition("classes",cls).max_level==8,"old cap retained; new cap is eight: "+cls)
  var legacy := old_kernel.create("old-core",old.recommendation("vanguard").attributes,"heritage-human")
  for n in 6:legacy=old_kernel.preview_advancement(legacy,old_kernel.suggested_choice(legacy,cls).choice).candidate
  check(not old_kernel.preview_advancement(legacy,old_kernel.suggested_choice(legacy,cls).choice).ok,"pinned v4 never receives later class levels")
  var saved: Dictionary=JSON.parse_string(JSON.stringify(legacy))
  check(RulesRecords.registry(saved).rules_ref()==old.rules_ref() and old_kernel.derive_character(saved).snapshot.snapshot_hash==old_kernel.derive_character(legacy).snapshot.snapshot_hash,"previous core record reload retains exact pin and snapshot")
 var baseline := first("fighter","toughness")
 var baseline_stats: Dictionary=kernel.derive_character(baseline).snapshot.stats
 for row in [["dodge","defence",1],["endurance","HP",1],["battle-awareness","initiative",2]]:
  var record := first("fighter",row[0])
  check(not record.is_empty(),"real feat selectable: "+str(row[0]))
  if not record.is_empty():check(int(kernel.derive_character(record).snapshot.stats[row[1]])-int(baseline_stats[row[1]])==row[2],"feat numerical effect: "+str(row[0]))
 check(first("fighter","mobility").is_empty(),"Mobility rejects missing Dodge")
 var mobile := first("fighter","dodge")
 var choice := kernel.suggested_choice(mobile,"fighter","mobility")
 choice.choice.feat_id="mobility"
 var applied := kernel.preview_advancement(mobile,choice.choice)
 check(applied.ok,"Fighter bonus feat can select Mobility after Dodge")
 if applied.ok:check(kernel.derive_character(applied.candidate).snapshot.stats.stride==5,"Mobility changes legal movement")
 check(first("fighter","spell-focus").is_empty(),"Spell focus rejects a noncaster")
 var focus := first("wizard","spell-focus")
 var scholar := first("wizard","toughness")
 check(not focus.is_empty() and kernel.derive_character(focus).snapshot.stats.save_dc==kernel.derive_character(scholar).snapshot.stats.save_dc+1,"Spell focus actually changes save DC")
 check(first("fighter","arcane-strike").is_empty(),"Arcane strike rejects a noncaster")
 active_feat("fighter","combat-expertise","defensive-strike")
 active_feat("wizard","arcane-strike","arcane-strike")
 check(first("fighter","veteran-weapon-training").is_empty(),"Veteran training rejects insufficient BAB and missing focus")
 var veteran := first("fighter","weapon-focus")
 for n in range(2,7):
  var step := kernel.suggested_choice(veteran,"fighter","veteran-weapon-training" if n==6 else "steady-study")
  if n==6:step.choice.feat_id="veteran-weapon-training"
  var next := kernel.preview_advancement(veteran,step.choice)
  check(next.ok,"legal prerequisite-dependent ordered feat history")
  if next.ok:veteran=next.candidate
 check(kernel.derive_character(veteran).snapshot.feats.has("veteran-weapon-training"),"earned BAB prerequisite permits veteran feat")
 var control := veteran.duplicate(true);control.advancement_history.back().feat_id="steady-study"
 check(kernel.derive_character(veteran).snapshot.stats.damage==kernel.derive_character(control).snapshot.stats.damage+2,"veteran training adds actual weapon damage")
 var seven: Dictionary=kernel.create("seven",source.recommendation("adept").attributes,"heritage-human")
 for n in range(1,9):
  var step := kernel.suggested_choice(seven,"wizard")
  var applied_level := kernel.preview_advancement(seven,step.choice)
  check(applied_level.ok,"Wizard progression through eight")
  if applied_level.ok:seven=applied_level.candidate
  var snapshot: Dictionary=kernel.derive_character(seven).snapshot
  check(snapshot.abilities.has("wizard-ice-lance")== (n>=7),"tier four unlocks at actual class seven")
 check(not kernel.preview_advancement(seven,kernel.suggested_choice(seven,"wizard").choice).ok,"unimplemented level nine is unavailable")
 for heritage in ["heritage-goblin","heritage-goblin-cavern","heritage-orc","heritage-orc-highland"]:
  var record := first("fighter","toughness",heritage)
  check(not record.is_empty(),"new ancestry has real playable mechanics: "+heritage)
  if not record.is_empty():
   var restored: Dictionary=JSON.parse_string(JSON.stringify(record))
   check(kernel.derive_character(record).snapshot.snapshot_hash==kernel.derive_character(restored).snapshot.snapshot_hash,"new inherited traits survive reload")
 var editor := BuildEditor.new();root.add_child(editor);editor.setup(first("wizard","toughness"))
 var attributes_before := editor.attributes.duplicate(true)
 var equipment_before: Array = editor.definition().equipment.duplicate()
 editor.ancestry_ref="heritage-orc";editor.refresh_preview()
 check(not editor.preview.ok,"inherited INT change requires explicit skills/preparation review")
 editor.suggest_allocation();editor.suggest_spell_selections()
 check(editor.preview.ok,"explicit Skills and Spells suggestions repair the changed budgets")
 check(editor.attributes==attributes_before and editor.definition().equipment==equipment_before,"spell recommendation preserves allocated attributes and chosen equipment")
 editor.queue_free()
 var caster := kernel.create("known-caster",{"STR":8,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":15},"heritage-human")
 for n in range(1,8):caster=kernel.preview_advancement(caster,kernel.suggested_choice(caster,"sorcerer").choice).candidate
 caster.choices.prepared_abilities=["sorcerer-arcane-bolt","sorcerer-mage-armour","sorcerer-enfeeble","sorcerer-scorching-ray","sorcerer-haste-spell"]
 check(kernel.validate_build(caster).ok,"full class-seven known repertoire is legal")
 var known_before: Array=caster.choices.prepared_abilities.duplicate()
 var learned := kernel.preview_advancement(caster,kernel.suggested_choice(caster,"sorcerer").choice)
 check(learned.ok,"full known repertoire can advance into class eight")
 if learned.ok:
  caster=learned.candidate;caster.choices.prepared_abilities.append("sorcerer-ice-lance")
  check(kernel.validate_build(caster).ok and known_before.all(func(id: String):return caster.choices.prepared_abilities.has(id)),"new tier-four spell fits without erasing already learned spells")
  var target := kernel.create("spell-target",source.recommendation("vanguard").attributes,"heritage-human")
  target=kernel.preview_advancement(target,kernel.suggested_choice(target,"fighter").choice).candidate
  var used := RulesEffects.new(source).use_ability(caster,target,"sorcerer-ice-lance",{"move":1,"main":1,"reaction":1},RulesRng.initial("known-tier-four"))
  check(used.ok,"newly learned tier-four spell actually casts")
  if used.ok:check(used.actor.runtime.resources["sorcerer-slots-4"]==caster.runtime.resources["sorcerer-slots-4"]-1,"tier-four casting spends its proper shared slot")
  caster.choices.prepared_abilities.append("sorcerer-greater-ward")
  check(not kernel.validate_build(caster).ok,"known repertoire above six remains invalid")
 for limits in [[0,2],[0,2,1,3,3,4,4,5,6],[1,2,2,3,3,4,4,5,6],[0,2,2,3,3,4,4,5,41]]:
  var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/rules/trhgd-character-v6.json"))
  for cls in data.classes:
   if cls.id=="sorcerer":cls.known_spell_limits=limits
  check(not RulesRegistry.new().load_data(data).ok,"malformed/shrinking/unbounded known-spell table rejected")
 for row in RulesRecords.installed_packs():
  if row.rules_ref.pack_id=="trhgd-character-v5":check(RulesCoreContent.selection_limit("sorcerer",8,RulesRecords.registry(row.rules_ref))==5,"already-pushed v5 retains original repertoire mechanics")
 var output := OS.get_environment("GAME118_TEST_ROOT")
 if not output.is_empty():FileAccess.open(output.path_join("continuation-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref()},"  "))
 print("GAME118 CONTINUATION ",checks," / ",failures);quit(1 if failures else 0)
