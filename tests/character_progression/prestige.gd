extends SceneTree
## Explicit development progression fixtures, never production XP or campaign grants.
var checks := 0
var failures := 0
var source: RulesRegistry
var kernel: RulesCharacter
var advanced := {}
var entry_builds := {}
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func step(record: Dictionary,cls: String,feat := "steady-study",priorities: Array=[]) -> Dictionary:
 var proposal := kernel.suggested_choice(record,cls,feat)
 if not proposal.ok:check(false,"suggestion");return record
 var choice: Dictionary=proposal.choice
 var ranks: Dictionary=kernel.derive_character(record).get("context",{}).get("skills",{})
 var allocation := {};var points := 0
 for n in choice.skill_allocations.values():points+=int(n)
 var order: Array=priorities.duplicate()
 for id in source.ids("skills"):
  if not order.has(id):order.append(id)
 for id in order:
  var amount := mini(points,record.advancement_history.size()+1-int(ranks.get(id,0)))
  if amount>0:allocation[id]=amount;points-=amount
 choice.skill_allocations=allocation
 var result := kernel.preview_advancement(record,choice)
 check(result.ok,"legitimate "+cls+" entry/progression: "+JSON.stringify(result.get("errors",[])))
 return result.get("candidate",record)
func fixture(path: String) -> Dictionary:
 var r := kernel.create("advanced:"+path,{"INT":15,"WIS":14,"DEX":13,"STR":12,"CON":10,"CHA":8},"heritage-human")
 r.equipment=["shortblade" if path=="duelist" or path=="eldritch-knight" else "staff"]
 var schedule: Array=[]
 if path=="duelist":schedule=["fighter","fighter","fighter","fighter","fighter","fighter"]
 elif path=="eldritch-knight":schedule=["fighter","fighter","wizard","wizard","wizard","wizard","wizard"]
 elif path=="arcane-trickster":schedule=["rogue","rogue","wizard","wizard","wizard"]
 else:schedule=["wizard","wizard","wizard","cleric","cleric","cleric"]
 for i in schedule.size():
  var feat := "steady-study"
  if path=="duelist" and i==0:feat="dodge"
  if path=="duelist" and i==1:feat="mobility"
  if path=="eldritch-knight" and i==0:feat="weapon-focus"
  r=step(r,schedule[i],feat,["acrobatics"] if path=="duelist" else ["spellcraft"] if path=="eldritch-knight" else ["stealth","arcana"] if path=="arcane-trickster" else ["arcana","insight"])
 return r
func run():
 source=RulesRecords.new_character_registry();kernel=RulesCharacter.new(source)
 check(source.ready() and RulesCareer.enabled(source),"new default career pack")
 var virgin := kernel.create("entry",source.recommendation("adept").attributes,"heritage-human")
 for path in ["duelist","eldritch-knight","arcane-trickster","mystic-theurge"]:
  var early := kernel.available_advancement(virgin)
  check(not early.classes[path].ok,"prestige unavailable on first level "+path)
  var r := fixture(path)
  var qualify := kernel.available_advancement(r)
  check(qualify.classes[path].ok,"attainable ordered prerequisite path "+path)
  var prior: Dictionary=kernel.derive_character(r).snapshot
  entry_builds[path]=r.duplicate(true)
  var normal_level: int= r.advancement_history.size()
  for n in 5:r=step(r,path)
  var derived := kernel.derive_character(r)
  check(derived.ok,"complete prestige build "+path)
  if not derived.ok:continue
  var snap: Dictionary=derived.snapshot
  check(snap.class_levels[path]==5 and snap.level==normal_level+5,"ordered total and prestige levels "+path)
  for at in [1,3,5]:check(snap.abilities.has(path+"-power-"+str(at)),"genuine prestige action "+path+str(at))
  if path!="duelist":
   check(snap.casting_levels.wizard==prior.class_levels.wizard+5,"selected arcane casting advances without base powers "+path)
   check(snap.abilities.has("wizard-ice-lance"),"hybrid unlocks actual higher-tier spell")
   check(not snap.abilities.has("wizard-career-9"),"hybrid never grants unrelated base power")
   if path=="mystic-theurge":check(snap.casting_levels.cleric==8 and snap.resource_capacities.has("cleric-slots-4"),"dual casting separately advances divine track")
  var reload: Dictionary=JSON.parse_string(JSON.stringify(r))
  check(kernel.derive_character(reload).snapshot.snapshot_hash==snap.snapshot_hash,"advanced JSON save/reload "+path)
  advanced[path]=r
  var forged := r.duplicate(true);forged.advancement_history[0].class_id=path
  check(not kernel.derive_character(forged).ok,"cannot forge earlier prestige qualification")
 # Simultaneous class/general feat grants are both real, not collapsed.
 var dual := kernel.create("dual",source.recommendation("vanguard").attributes,"heritage-human")
 dual=step(dual,"rogue");dual=step(dual,"fighter")
 var selection := kernel.suggested_choice(dual,"fighter","dodge")
 check(selection.choice.bonus_feats.size()==1,"two feats scheduled at total3/Fighter2")
 selection.choice.bonus_feats=["endurance"]
 var next := kernel.preview_advancement(dual,selection.choice)
 check(next.ok and next.snapshot.feats.has("dodge") and next.snapshot.feats.has("endurance"),"two distinct benefits persist")
 selection.choice.bonus_feats=[];check(not kernel.preview_advancement(dual,selection.choice).ok,"missing bonus feat rejected")
 selection.choice.bonus_feats=["dodge"];check(not kernel.preview_advancement(dual,selection.choice).ok,"nonrepeatable duplicate rejected")
 # Selection is mandatory and immutable in each historic advancement.
 var chosen := kernel.suggested_choice(virgin,"wizard")
 chosen.choice.specialisations={};check(not kernel.preview_advancement(virgin,chosen.choice).ok,"missing school rejected")
 chosen=kernel.suggested_choice(virgin,"wizard");chosen.choice.specialisations["wizard-choice-1"]="invented"
 check(not kernel.preview_advancement(virgin,chosen.choice).ok,"unknown school rejected")
 chosen=kernel.suggested_choice(virgin,"wizard");chosen.choice.specialisations["wizard-choice-1"]="abjuration"
 next=kernel.preview_advancement(virgin,chosen.choice)
 check(next.ok and next.snapshot.abilities.has("wizard-abjuration-1") and not next.snapshot.abilities.has("wizard-evocation-1"),"exclusive school is functional")
 check(entry_builds.size()==4,"all four pre-entry histories retained for visible prerequisite evidence")
 var output := OS.get_environment("GAME119_TEST_ROOT")
 if not output.is_empty():
  FileAccess.open(output.path_join("advanced-fixtures.json"),FileAccess.WRITE).store_string(JSON.stringify(advanced,"  "))
  FileAccess.open(output.path_join("entry-fixtures.json"),FileAccess.WRITE).store_string(JSON.stringify(entry_builds,"  "))
 print("GAME119 PRESTIGE ",checks," / ",failures)
 quit(1 if failures else 0)
