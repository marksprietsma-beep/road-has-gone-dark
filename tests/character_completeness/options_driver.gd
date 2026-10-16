extends "res://tests/character_completeness/prestige_driver.gd"
## Selection witnesses and concrete derived consequences, not blanket tactical-effect claims.
var options := {"feats":{},"ancestries":{}}
func run() -> void:
 base=OS.get_environment("GAME126_OPTIONS_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRecords.new_character_registry();kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME126_AUDIT_RESTART")=="1":
  var saved := WorldOriginLore.read_json(base.path_join("records.json"))
  for id in saved.records:
   var derived := kernel.derive_character(saved.records[id])
   check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"option cold exact history "+id)
  done();return
 for id in source.ids("ancestries"):
  var record := kernel.create("ancestry:"+id,{"STR":15,"DEX":14,"CON":13,"INT":12,"WIS":10,"CHA":8},id)
  var advanced := kernel.preview_advancement(record,kernel.suggested_choice(record,"fighter").choice)
  check(advanced.ok,"heritage legal birth "+id)
  if not advanced.ok:continue
  record=advanced.candidate;record.equipment=source.definition("classes","fighter").recommended_equipment.duplicate()
  var derived := kernel.derive_character(record)
  var body_rejection := false
  if not derived.ok:
   body_rejection=derived.get("errors",[]).any(func(e: Dictionary):return e.code=="equipment.body")
   check(body_rejection,"equipment rejection must be explicit inherited body restriction "+id)
   var bare: Dictionary=record.duplicate(true);bare.equipment=[]
   var caps: Dictionary=kernel.derive_character(bare).snapshot.capabilities
   record.equipment=record.equipment.filter(func(item: String):return not caps.blocked_equipment.has(source.definition("equipment",item).kind))
   derived=kernel.derive_character(record)
  check(derived.ok,"heritage compatible equipment accepted "+id)
  if derived.ok:
   records[record.character_id]=record
   options.ancestries[id]={"selectable":true,"scope":"Legal level1 Fighter, inherited attributes/skills/capabilities, recommended equipment; not every class or art/body animation.","attributes":derived.snapshot.attributes,"stats":derived.snapshot.stats,"capabilities":derived.snapshot.capabilities,"equipment":record.equipment,"body_restriction_enforced":body_rejection,"snapshot_hash":derived.snapshot.snapshot_hash}
 for id in source.ids("feats"):
  var nodes := leaves(source.definition("feats",id).requirements,0)
  var goals := {"nodes":nodes,"feats":[id]};var cursor := 0;var seen := {id:true}
  while cursor<goals.nodes.size():
   var n: Dictionary=goals.nodes[cursor];cursor+=1
   if n.op=="feat" and not seen.has(n.id):
    seen[n.id]=true;goals.feats.push_front(n.id);goals.nodes.append_array(leaves(source.definition("feats",n.id).requirements,0))
  var cls := "fighter";var ancestry := "heritage-human"
  for n in goals.nodes:
   if n.op=="class_level":cls=n.id
   if n.op=="ancestry":ancestry="heritage-"+str(n.id)
   if n.op=="casting":cls="wizard" if n.id=="arcane" else "cleric"
   if n.op=="tag":cls="druid" if n.id=="permanent_nature_bond" else "psion" if n.id=="psychic_manifester" else cls
   if n.op=="feature":
    if str(n.id).begins_with("druid-"):cls="druid"
    elif str(n.id).begins_with("troglodyte-"):ancestry="heritage-troglodyte"
    elif str(n.id).begins_with("power-"):cls="psion"
  var record := kernel.create("feat:"+id,attributes_for(cls,goals.nodes),ancestry)
  var selected := false
  for level in 20:
   var current: Dictionary=kernel._replay(record).context
   var target: String=next_class(cls,record,goals) if level>0 else cls
   for n in goals.nodes:
    if n.op=="class_level" and int(current.classes.get(n.id,0))<int(n.min):target=n.id;break
   if cls=="psion":target="psion"
   var result := advance(record,target,goals)
   if not result.ok:break
   record=result.candidate
   if kernel._replay(record).context.feats.has(id):selected=true;break
  check(selected,"legal feat witness "+id)
  if selected:
   var s: Dictionary=kernel.derive_character(record).snapshot
   records[record.character_id]=record
   options.feats[id]={"selectable":true,"level":s.level,"history":record.advancement_history,"features_applied":source.definition("feats",id).features,"stats":s.stats,"capabilities":s.capabilities,"resource_capacities":s.resource_capacities,"snapshot_hash":s.snapshot_hash,"scope":"Actual prerequisite-directed selection, ordered replay and derived features/stats/capabilities. Tactical conditional execution is separately unverified unless another receipt supplies it."}
 var hashes := {}
 for id in records:hashes[id]=kernel.derive_character(records[id]).snapshot.snapshot_hash
 FileAccess.open(base.path_join("records.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes})))
 FileAccess.open(base.path_join("options.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"rules_ref":source.rules_ref(),"options":options}),"  "))
 done()
