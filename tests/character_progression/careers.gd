extends SceneTree
var checks := 0
var failures := 0
var source: RulesRegistry
var kernel: RulesCharacter
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func run():
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v9.json").ok,"validated career pack")
 kernel=RulesCharacter.new(source)
 for cls in source.ids("classes"):
  if source.definition("classes",cls).class_kind!="base":continue
  var record := kernel.create("career:"+cls,source.recommendation("adept").attributes,"heritage-human")
  for level in range(1,13):
   var suggestion := kernel.suggested_choice(record,cls)
   check(suggestion.ok,"suggestion "+cls+str(level))
   var next := kernel.preview_advancement(record,suggestion.choice)
   check(next.ok,"actual progression "+cls+str(level)+" "+JSON.stringify(next.get("errors",[])))
   if not next.ok:break
   record=next.candidate
   var reloaded: Dictionary=JSON.parse_string(JSON.stringify(record))
   check(kernel.derive_character(reloaded).snapshot.snapshot_hash==next.snapshot.snapshot_hash,"reload exact "+cls+str(level))
   check(next.snapshot.level==level,"ordered level")
  if record.advancement_history.size()==12:
   var snap: Dictionary=kernel.derive_character(record).snapshot
   check(snap.abilities.has(cls+"-career-9") and snap.abilities.has(cls+"-career-11"),"real higher actions "+cls)
   check(snap.specialisations.size()>=2,"durable two choices "+cls)
   var illegal := kernel.suggested_choice(record,cls)
   check(not kernel.preview_advancement(record,illegal.choice).ok,"honest current cap")
 verify_feat_chains()
 verify_refined_fury()
 print("GAME119 CAREERS ",checks," / ",failures)
 quit(1 if failures else 0)

func verify_feat_chains() -> void:
 var record := kernel.create("feat-chain",source.recommendation("adept").attributes,"heritage-human")
 for level in range(1,11):
  var chosen := "weapon-focus" if level==1 else "veteran-weapon-training" if level==6 else "greater-weapon-focus" if level==8 else "greater-weapon-specialisation" if level==10 else "steady-study"
  var proposal := kernel.suggested_choice(record,"fighter",chosen)
  var result := kernel.preview_advancement(record,proposal.choice)
  check(result.ok,"actual earned prerequisite chain "+chosen)
  if not result.ok:return
  if level in [8,10]:
   var control: Dictionary=proposal.choice.duplicate(true);control.feat_id="steady-study"
   var baseline := kernel.preview_advancement(record,control)
   check(baseline.ok,"same-level feat control")
   check(result.snapshot.stats.melee_attack==baseline.snapshot.stats.melee_attack+1 if level==8 else result.snapshot.stats.damage==baseline.snapshot.stats.damage+2,"typed greater focus/specialisation actually changes statistics")
  record=result.candidate
 var caster := kernel.create("greater-focus",source.recommendation("adept").attributes,"heritage-human")
 for level in range(1,6):
  var proposal := kernel.suggested_choice(caster,"wizard","spell-focus" if level==1 else "greater-spell-focus" if level==5 else "steady-study")
  var result := kernel.preview_advancement(caster,proposal.choice)
  check(result.ok,"actual spell-focus chain")
  if level==5:
   var control: Dictionary=proposal.choice.duplicate(true);control.feat_id="steady-study"
   check(result.snapshot.stats.save_dc==kernel.preview_advancement(caster,control).snapshot.stats.save_dc+1,"greater focus improves actual effect DC")
  caster=result.candidate
 var mover := kernel.create("spring-chain",source.recommendation("scout").attributes,"heritage-human")
 for level in range(1,6):
  var proposal := kernel.suggested_choice(mover,"ranger","dodge" if level==1 else "mobility" if level==3 else "spring-attack" if level==5 else "steady-study")
  var result := kernel.preview_advancement(mover,proposal.choice)
  check(result.ok,"actual movement feat chain")
  if level==5:
   var control: Dictionary=proposal.choice.duplicate(true);control.feat_id="steady-study"
   check(result.snapshot.stats.stride==kernel.preview_advancement(mover,control).snapshot.stats.stride+1,"spring attack changes actual reachable movement budget")
  mover=result.candidate
 var blank := kernel.create("negative-feat",source.recommendation("adept").attributes,"heritage-human")
 for id in ["greater-weapon-focus","greater-spell-focus","spring-attack","greater-weapon-specialisation"]:
  var proposal := kernel.suggested_choice(blank,"fighter",id)
  check(not kernel.preview_advancement(blank,proposal.choice).ok,"higher feat rejects unmet prerequisites "+id)

func verify_refined_fury() -> void:
 var record := kernel.create("fury",source.recommendation("vanguard").attributes,"heritage-human")
 for n in 11:record=kernel.preview_advancement(record,kernel.suggested_choice(record,"barbarian").choice).candidate
 var snapshot: Dictionary=kernel.derive_character(record).snapshot
 record.runtime.resources=snapshot.resource_capacities.duplicate()
 var status := source.definition("statuses","off-balance")
 record.runtime.statuses=[{"id":"off-balance","source":"development","remaining":status.duration.amount,"expiry":status.duration.expiry}]
 var budget := {"main":1,"move":1,"reaction":1};var rng := RulesRng.initial("fury-refinement")
 var lesser := RulesEffects.new(source).use_ability(record,record,"barbarian-career-9",budget,rng)
 var greater := RulesEffects.new(source).use_ability(record,record,"barbarian-career-11",budget,rng)
 check(lesser.ok and greater.ok,"both higher Barbarian powers function")
 check(greater.target.runtime.statuses.any(func(s: Dictionary):return s.id=="raging") and not lesser.target.runtime.statuses.any(func(s: Dictionary):return s.id=="raging"),"level eleven combines real Rage, not duplicate temporary HP")
 check(not greater.target.runtime.statuses.any(func(s: Dictionary):return s.id=="off-balance") and lesser.target.runtime.statuses.any(func(s: Dictionary):return s.id=="off-balance"),"level eleven also clears actual offensive impairment")
 check(greater.actor.runtime.resources["rage-uses"]==record.runtime.resources["rage-uses"]-2 and greater.target.runtime.temporary_hp==22,"cost and temporary-HP amount remain explicit")
 check(greater.rng==rng,"self recovery consumes no combat RNG")
 var old := RulesRegistry.new();check(old.load_pack("res://data/rules/trhgd-character-v7.json").ok,"published v7 remains installed")
 var prior := RulesCharacter.new(old);var saved := prior.create("v7-fury",old.recommendation("vanguard").attributes,"heritage-human")
 for n in 11:saved=prior.preview_advancement(saved,prior.suggested_choice(saved,"barbarian").choice).candidate
 var before: Dictionary=prior.derive_character(saved).snapshot
 check(RulesRecords.registry(saved).rules_ref()==old.rules_ref(),"old career campaign never upgrades to v8")
 check(prior.derive_character(JSON.parse_string(JSON.stringify(saved))).snapshot.snapshot_hash==before.snapshot_hash,"v7 history/pin/snapshot survive reload")
 check(old.definition("abilities","barbarian-career-11").name=="Unstoppable rage perfected" and source.definition("abilities","barbarian-career-11").name=="Renewed fury","old higher-power definition unchanged; new default is distinct")
