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
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v7.json").ok,"validated career pack")
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
 print("GAME119 CAREERS ",checks," / ",failures)
 quit(1 if failures else 0)
