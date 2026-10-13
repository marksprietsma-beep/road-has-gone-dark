extends SceneTree
## A filled permanent repertoire must have room at every new spontaneous tier.
var checks := 0
var failures := 0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func run():
 var source := RulesRecords.new_character_registry();var kernel := RulesCharacter.new(source)
 for cls in source.ids("classes"):
  if source.definition("classes",cls).spell_mode!="spontaneous":continue
  for tier in source.definition("classes",cls).features:
   var definition := source.definition("features",tier.id)
   if not definition.tags.has("casting_tier"):continue
   var record := kernel.create("repertoire:"+cls,{"CHA":15,"INT":14,"WIS":13,"CON":12,"DEX":10,"STR":8},"heritage-human")
   for level in range(1,int(tier.at)):record=kernel.preview_advancement(record,kernel.suggested_choice(record,cls).choice).candidate
   var before: Dictionary=kernel.derive_character(record).snapshot
   var prior: Array=before.abilities.filter(func(id: String):return source.definition("abilities",id).get("casting_class")==cls and source.definition("abilities",id).tags.has("spell"))
   prior=prior.slice(0,mini(prior.size(),RulesCoreContent.selection_limit(cls,int(tier.at)-1,source)))
   record.choices.prepared_abilities=prior.duplicate()
   check(kernel.derive_character(record).ok,"maximum prior permanent repertoire legal "+cls+str(tier.at))
   var next := kernel.preview_advancement(record,kernel.suggested_choice(record,cls).choice)
   check(next.ok,"new tier advancement retains every learned spell")
   if not next.ok:continue
   var selected: String=str(definition.abilities[0]);next.candidate.choices.prepared_abilities.append(selected)
   check(kernel.derive_character(next.candidate).ok,"filled prior repertoire can immediately learn new tier "+cls+str(tier.at))
   check(prior.all(func(id: String):return next.candidate.choices.prepared_abilities.has(id)),"no forgetting to acquire newly unlocked tier")
   var target := kernel.create("target",source.recommendation("vanguard").attributes,"heritage-human")
   target=kernel.preview_advancement(target,kernel.suggested_choice(target,"fighter").choice).candidate
   var used := RulesEffects.new(source).use_ability(next.candidate,target,selected,{"main":1,"move":1,"reaction":1},RulesRng.initial("new-tier:"+cls+str(tier.at)))
   check(used.ok,"newly learned spell actually functions immediately "+selected)
   var loaded: Dictionary=JSON.parse_string(JSON.stringify(next.candidate))
   check(kernel.derive_character(loaded).snapshot.snapshot_hash==kernel.derive_character(next.candidate).snapshot.snapshot_hash,"known repertoire and slots persist exactly")
 # Published v8 definitions are retained, not silently repaired in old campaigns.
 var old := RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v8.json").ok,"v8 retained")
 check(RulesCoreContent.selection_limit("bard",10,old)==6 and RulesCoreContent.selection_limit("sorcerer",6,old)==4,"older allowance contract unchanged")
 check(RulesCoreContent.selection_limit("bard",10,source)==7 and RulesCoreContent.selection_limit("sorcerer",6,source)==5,"latest allowances explicitly revised")
 print("GAME119 REPERTOIRE ",checks," / ",failures)
 quit(1 if failures else 0)
