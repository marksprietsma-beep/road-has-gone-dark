extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var legacy := RulesRecords.registry()
 var expanded := RulesRecords.new_character_registry()
 check(legacy.ready(),"legacy pack loads")
 check(expanded.ready(),"expanded pack loads: "+RulesJson.canonical(expanded.errors))
 if not expanded.ready():finish();return
 check(legacy.rules_ref().pack_id=="trhgd-rules-v1" and expanded.rules_ref().pack_id=="trhgd-character-v2","separate pack identity")
 var wrong := expanded.rules_ref();wrong.content_hash="0".repeat(64)
 check(not RulesRecords.registry(wrong).ready(),"tampered pin rejected without substitution")
 check(legacy.ids("classes").size()==4 and expanded.ids("classes").size()==7,"immutable v1, extended v2")
 var kernel := RulesCharacter.new(expanded)
 for class_id in ["blade-dancer","iron-bulwark","road-stalker"]:
  for ancestry in expanded.ids("ancestries"):
   var rec := expanded.recommendation("vanguard")
   var record := kernel.create("test:"+class_id+":"+ancestry,rec.attributes,ancestry)
   record.equipment=["shortblade"]
   for level in range(1,21):
    var choice := kernel.suggested_choice(record,class_id)
    check(choice.ok,"legal choice "+class_id+" level "+str(level))
    if not choice.ok:break
    var applied := kernel.apply_advancement(record,choice.choice,int(record.revision))
    check(applied.ok,"actual progression "+class_id+" level "+str(level))
    if not applied.ok:break
    record=applied.candidate
    check(kernel.validate_build(JSON.parse_string(JSON.stringify(record))).ok,"saved history replay "+class_id)
   check(record.advancement_history.size()==20,"full twenty-level progression")
   check(not RulesCharacter.new(legacy).validate_build(record).ok,"v2 is never interpreted as v1")
 for id in expanded.ids("ancestries"):
  if not id.begins_with("lineage-"):continue
  var row := expanded.definition("ancestries",id)
  var rec := expanded.recommendation("vanguard")
  var a := kernel.create("trait",rec.attributes,id)
  var neutral := kernel.create("trait",rec.attributes,"heritage-"+str(row.people_id))
  var changed := kernel.derive_character(a);var baseline := kernel.derive_character(neutral)
  for modifier in row.modifiers:check(int(changed.snapshot.stats[modifier.stat])-int(baseline.snapshot.stats[modifier.stat])==int(modifier.value.value),"inherited numerical consequence "+id+" "+str(modifier.stat))
 for id in ["quick-start","sure-shot","stout-heart","clear-mind","fleet-foot","blade-practice","weathered"]:
  var rec := expanded.recommendation("vanguard")
  var a := kernel.create("feat",rec.attributes,"heritage-human");a.equipment=["shortblade"]
  var choice := kernel.suggested_choice(a,"blade-dancer",id)
  check(choice.ok,"new feat has a legal real starting choice "+id)
  if choice.ok:check(kernel.apply_advancement(a,choice.choice,0).ok,"new feat mechanically applies "+id)
 var invalid_namespace := {"mechanics":[]}
 check(not RulesRecords.registry(invalid_namespace).ready(),"malformed rules namespace cleanly rejected")
 check(not RulesRecords.registry({"rules_ref":{}}).ready(),"explicit empty pin never falls back")
 var original := RulesCharacter.new(legacy)
 var rec := legacy.recommendation("vanguard")
 var old := original.create("legacy",rec.attributes,"heritage-human");old.equipment=["shortblade"]
 old=original.apply_advancement(old,original.suggested_choice(old,"roadwarden").choice,0).candidate
 check(RulesCharacter.new(RulesRecords.registry(old)).derive_character(old).snapshot.snapshot_hash==original.derive_character(old).snapshot.snapshot_hash,"exact legacy snapshot unchanged")
 finish()
func finish() -> void:
 print(JSON.stringify({"checks":checks,"failures":failures}))
 quit(1 if failures else 0)
