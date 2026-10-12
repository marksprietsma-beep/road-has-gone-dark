extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,why: String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred('run')
func run():
 var source := RulesRecords.new_character_registry()
 check(source.ready(),'default content available: '+RulesJson.canonical(source.errors))
 if not source.ready():quit(1);return
 check(source.ids('classes').size()==11,'eleven genuine core classes')
 check(RulesCoreContent.ancestry_rows(source).size()==9,'nine familiar races independent of prototype presence data')
 var kernel := RulesCharacter.new(source)
 var feats := {}
 for cls in source.ids('classes'):
  for heritage in source.ids('ancestries'):
   var record := kernel.create('core:'+cls,{'STR':15,'DEX':14,'CON':13,'INT':12,'WIS':10,'CHA':8},heritage)
   for level in range(1,int(source.definition("classes",cls).max_level)+1):
    var choice := kernel.suggested_choice(record,cls)
    check(choice.ok,cls+' valid advancement')
    if not choice.ok:continue
    var available := kernel.preview_choices(record,cls,{'skill_allocations':choice.choice.skill_allocations,'attribute_increase':choice.choice.attribute_increase})
    for id in available.get('feat_choices',{}):
     if available.feat_choices[id].ok:feats[id]=true
    var applied := kernel.preview_advancement(record,choice.choice)
    check(applied.ok,cls+' actual ordered progression '+str(level))
    if not applied.ok:continue
    record=applied.candidate
    var saved: Dictionary=JSON.parse_string(JSON.stringify(record))
    check(kernel.derive_character(record).snapshot.snapshot_hash==kernel.derive_character(saved).snapshot.snapshot_hash,'exact derived snapshot after JSON round trip')
   record.equipment=source.definition('classes',cls).recommended_equipment.duplicate()
   check(kernel.validate_build(record).ok,'class equipment legal')
   record.equipment.append('mail' if cls in ['wizard','sorcerer','monk'] else 'staff')
   check(not kernel.validate_build(record).ok,'unproficient or conflicting equipment rejected')
 for cls in source.ids('classes'):
  var editor := BuildEditor.new();root.add_child(editor)
  var record := kernel.create('editor',source.recommendation('vanguard').attributes,'heritage-human');record=kernel.preview_advancement(record,kernel.suggested_choice(record,'fighter','toughness').choice).candidate
  editor.setup(record);editor.set_class(cls)
  check(editor.preview.ok,'actual class picker makes a valid '+cls+' build: '+CharacterBuilderRecords.reason(editor.preview))
  if editor.preview.ok:
   var a: Dictionary=editor.preview.candidate
   var derived := kernel.derive_character(a)
   for id in derived.snapshot.abilities:
    var ability := source.definition('abilities',id)
    if id in ['attack','move','departure-attack','precision'] or ability.has('trigger') or ability.tags.has('passive'):continue
    if ability.tags.has('spell') and not a.choices.prepared_abilities.has(id):continue
    var target := kernel.create('target',source.recommendation('vanguard').attributes,'heritage-human');target=kernel.preview_advancement(target,kernel.suggested_choice(target,'fighter','toughness').choice).candidate
    target.runtime.hp=1
    var used := RulesEffects.new(source).use_ability(a,a if ability.targeting.kind=='self' else target,id,{'move':1,'main':1,'reaction':1},RulesRng.initial('class-ability'))
    check(used.ok,'real owned ability '+id+' resolves: '+CharacterBuilderRecords.reason(used))
    if used.ok:
     for resource in ability.cost.resources:check(int(used.actor.runtime.resources[resource])==int(a.runtime.resources[resource])-int(ability.cost.resources[resource]),'slot/use spent exactly once')
     var replay := RulesEffects.new(source).use_ability(a,a if ability.targeting.kind=='self' else target,id,{'move':1,'main':1,'reaction':1},RulesRng.initial('class-ability'))
     check(RulesJson.digest(used)==RulesJson.digest(replay),'deterministic ability/RNG output')
   if cls=="wizard":
    var actor := a.duplicate(true)
    var spell_id := "wizard-arcane-bolt"
    var initial_copies: int=int(actor.choices.spell_preparations[spell_id])
    var target := kernel.create("durable-target",source.recommendation("vanguard").attributes,"heritage-human")
    for level in range(1,7):target=kernel.preview_advancement(target,kernel.suggested_choice(target,"fighter").choice).candidate
    target.runtime.hp=kernel.derive_character(target).snapshot.stats.HP
    for cast in initial_copies:
     var used := RulesEffects.new(source).use_ability(actor,target,spell_id,{"move":1,"main":1,"reaction":1},RulesRng.initial("prepared-cast-"+str(cast)))
     check(used.ok,"each actually prepared copy can be cast")
     if used.ok:actor=used.actor;target=used.target
    check(int(actor.runtime.resources["wizard-slots-1"])>0,"another tier slot remains for the other prepared spell")
    check(not RulesEffects.new(source).use_ability(actor,target,spell_id,{"move":1,"main":1,"reaction":1},RulesRng.initial("prepared-exhausted")).ok,"cannot cast an exhausted prepared spell even with another shared slot")
    var invalid := a.duplicate(true);invalid.choices.spell_preparations[spell_id]=30
    check(not kernel.validate_build(invalid).ok,"over-budget preparation copies rejected")
   for attribute in RulesExpressions.ATTRIBUTES:
    for score in source.rule('standard_array'):
     var picker: OptionButton=editor.attribute_pickers[attribute];editor.select_id(picker,str(score));picker.item_selected.emit(picker.selected)
     var values: Array=editor.attributes.values();values.sort();var expected: Array=source.rule('standard_array').duplicate();expected.sort()
     check(values==expected and int(editor.attributes[attribute])==int(score),'score picker swaps the intended attribute')
     for key in editor.attribute_pickers:check(int(editor.id_of(editor.attribute_pickers[key]))==int(editor.attributes[key]),'all visible scores match draft values')
  editor.queue_free()
 print('GAME118 CORE ',checks,' / ',failures,'; playable feats ',feats.keys())
 var output := OS.get_environment('GAME118_TEST_ROOT')
 if not output.is_empty():
  DirAccess.make_dir_recursive_absolute(output)
  FileAccess.open(output.path_join('core-proof.json'),FileAccess.WRITE).store_string(JSON.stringify({'checks':checks,'failures':failures,'races':RulesCoreContent.ancestry_rows(source).size(),'heritages':source.ids('ancestries').size(),'classes':11,'class_level_cap':8,'prestige_classes':0,'feats':feats.keys(),'rules_ref':source.rules_ref()},'  '))
 quit(1 if failures else 0)
