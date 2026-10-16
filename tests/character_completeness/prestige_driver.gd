extends "res://tests/character_wave_four/mechanics_driver.gd"
## Bounded prerequisite-directed fixture search. Only production previews decide legality.
var pairs := {}
var records := {}
func run() -> void:
 base=OS.get_environment("GAME126_PRESTIGE_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v15.json")
 check(loaded.ok,"prestige audit source")
 if not loaded.ok:done();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME126_AUDIT_RESTART")=="1":
  var saved: Dictionary=WorldOriginLore.read_json(base.path_join("records.json"))
  for id in saved.records:
   var derived := kernel.derive_character(saved.records[id])
   check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"prestige exact restart "+id)
  done();return
 var shard := int(OS.get_environment("GAME126_SHARD"));var shards := maxi(1,int(OS.get_environment("GAME126_SHARDS")))
 var bases := kernel.starting_classes();var paths: Array=source.ids("classes").filter(func(id: String):return source.definition("classes",id).get("class_kind")=="prestige")
 for i in bases.size():
  if i%shards!=shard:continue
  var cls: String=bases[i];pairs[cls]={}
  for path in paths:
   var attempts := []
   for strategy in [[5,0],[1,0],[5,1],[1,1]]:
    var result := search_route(cls,path,int(strategy[0]),int(strategy[1]))
    attempts.append(result)
    if result.get("complete",false):break
   pairs[cls][path]={"attempts":attempts,"scope":"Bounded fixture search: base-first5 or1, two OR branches, directed bridge classes; failure is not impossibility proof.","earned_xp":false,"player_validated":false}
   print("PRESTIGE ",cls," / ",path," ",attempts.back().get("complete",false))
   checkpoint()
 done()

func leaves(node: Dictionary,branch: int) -> Array:
 if node.op=="all":
  var out: Array=[]
  for child in node.args:out.append_array(leaves(child,branch))
  return out
 if node.op=="any":return leaves(node.args[mini(branch,node.args.size()-1)],branch)
 return [node]

func requirements(path: String,branch: int) -> Dictionary:
 var nodes := leaves(source.definition("classes",path).requirements,branch)
 var feats: Array=[];var seen := {}
 var cursor := 0
 while cursor<nodes.size():
  var n: Dictionary=nodes[cursor];cursor+=1
  if n.op=="feat" and not seen.has(n.id):
   seen[n.id]=true;feats.push_front(n.id)
   nodes.append_array(leaves(source.definition("feats",n.id).requirements,branch))
 return {"nodes":nodes,"feats":feats}

func attributes_for(cls: String,nodes: Array) -> Dictionary:
 var priority: Array=source.definition("classes",cls).get("attribute_priority",[]).duplicate()
 if priority.is_empty():priority=["STR","DEX","CON","INT","WIS","CHA"]
 for n in nodes:
  var attr := ""
  if n.op=="casting":attr="INT" if n.id=="arcane" else "WIS" if n.id=="divine" else ""
  if n.op=="resource":attr=str(source.definition("classes",str(source.definition("resources",n.id).get("slot_class","psion"))).get("casting_attribute","INT"))
  if not attr.is_empty():priority.erase(attr);priority.push_front(attr)
 var values := {}
 for i in 6:values[priority[i]]=source.rule("standard_array")[i]
 var minima := {}
 for n in nodes:
  if n.op=="attribute":minima[n.id]=maxi(int(minima.get(n.id,3)),mini(15,int(n.min)))
 for attr in minima:
  if int(values[attr])>=int(minima[attr]):continue
  for other in priority.duplicate().slice(0,6):
   if other!=attr and int(values[other])>=int(minima[attr]) and int(values[attr])>=int(minima.get(other,3)):
    var temp: int=int(values[attr]);values[attr]=values[other];values[other]=temp;break
 return values

func advance(record: Dictionary,cls: String,goals: Dictionary) -> Dictionary:
 var proposal := kernel.suggested_choice(record,cls)
 if not proposal.ok:return proposal
 var choice: Dictionary=proposal.choice
 var replay := kernel._replay(record)
 var points := 0
 for value in choice.skill_allocations.values():points+=int(value)
 var rank_goals := {}
 for n in goals.nodes:
  if n.op=="skill":rank_goals[n.id]=maxi(int(rank_goals.get(n.id,0)),int(n.min))
 var allocation := {};var next: int=record.advancement_history.size()+1
 var order: Array=rank_goals.keys()
 for id in source.definition("classes",cls).class_skills+source.ids("skills"):
  if not order.has(id):order.append(id)
 for id in order:
  var cap: int=mini(next,int(rank_goals[id])) if rank_goals.has(id) else next
  var amount: int=mini(points,maxi(0,cap-int(replay.context.skills.get(id,0))))
  if amount>0:allocation[id]=amount;points-=amount
 choice.skill_allocations=allocation
 var choices: Array=[]
 if not choice.feat_id.is_empty():
  for id in goals.feats:
   if not replay.context.feats.has(id):choices.append(id)
 choices.append(choice.feat_id)
 for id in choices:
  choice.feat_id=id
  var result := kernel.preview_advancement(record,choice)
  if result.ok:return result
 return kernel.preview_advancement(record,choice)

func next_class(cls: String,record: Dictionary,goals: Dictionary) -> String:
 var context: Dictionary=kernel._replay(record).context
 var missing: Array=goals.nodes.filter(func(n: Dictionary):return not RulesExpressions.evaluate_requirements(n,context).ok)
 for n in missing:
  if n.op=="class_level" and source.definition("classes",n.id).get("class_kind")=="base":return n.id
  if n.op=="casting":return cls if source.definition("classes",cls).casting_tradition==n.id else "wizard" if n.id=="arcane" else "cleric"
  if n.op=="resource":return str(source.definition("resources",n.id).get("slot_class","psion"))
  if n.op in ["feature","tag"]:
   for producer in kernel.starting_classes():
    var c := source.definition("classes",producer)
    var features: Array=c.features.map(func(f: Dictionary):return f.id)
    for group in c.get("career_choices",[]):
     for option in group.options:features.append_array(option.features)
    if features.any(func(f: String):return f==n.id if n.op=="feature" else source.definition("features",f).tags.has(n.id)):return producer
 for n in missing:
  if n.op=="bab":return cls if source.definition("classes",cls).bab.get("op")=="class_level" else "fighter"
 return cls

func search_route(cls: String,path: String,base_min: int,branch: int) -> Dictionary:
 var goals := requirements(path,branch)
 var ancestry := "heritage-dwarf" if goals.nodes.any(func(n: Dictionary):return n.op=="ancestry" and n.id=="dwarf") else "heritage-human"
 var record := kernel.create("prestige:"+cls+":"+path,attributes_for(cls,goals.nodes),ancestry)
 var entered := 0;var prefix: Dictionary={};var declined := false;var cap: int=int(source.definition("classes",path).max_level)
 var row := {"base_minimum_strategy":base_min,"or_branch":branch,"complete":false,"ancestry":ancestry}
 for total in 20:
  var context: Dictionary=kernel._replay(record).get("context",{})
  if context.is_empty():row.blocker="invalid prefix";break
  var target := cls
  if total>0:
   var available := kernel.available_advancement(record)
   if entered>0:
    target=path if int(context.classes.get(path,0))<cap else cls
   elif int(context.classes.get(cls,0))>=base_min and available.classes[path].ok:
    entered=total+1;prefix=record.duplicate(true)
    var unchanged := RulesJson.digest(record)
    var decline := advance(record,cls,goals)
    declined=decline.ok
    check(RulesJson.digest(record)==unchanged,"eligibility/decline preview never auto-promotes "+cls+":"+path)
    target=path
   elif int(context.classes.get(cls,0))>=base_min:target=next_class(cls,record,goals)
  var next := advance(record,target,goals)
  if not next.ok:
   row.blocker={"at":total+1,"class":target,"errors":next.get("errors",[])};break
  record=next.candidate
 var derived := kernel.derive_character(record)
 if entered>0:
  row.entry_level=entered;row.entry_history=prefix.advancement_history;row.entry_rules_eligibility=kernel.available_advancement(prefix).classes[path]
  row.manual_choice=true;row.can_decline=declined;row.base_levels_at_entry=kernel._replay(prefix).context.classes.get(cls,0)
  row.bridge_dominates=int(row.base_levels_at_entry)*2<prefix.advancement_history.size()
 if derived.ok:
  row.total_level=derived.snapshot.level;row.class_levels=derived.snapshot.class_levels;row.prestige_levels=derived.snapshot.class_levels.get(path,0)
  row.complete=entered>0 and int(row.prestige_levels)==cap and int(row.total_level)==20
  row.snapshot_hash=derived.snapshot.snapshot_hash
  if row.complete:
   var key: String=cls+":"+path;records[key]=record
 return row

func checkpoint() -> void:
 var hashes := {}
 for id in records:hashes[id]=pairs[id.split(":")[0]][id.split(":")[1]].attempts.back().snapshot_hash
 FileAccess.open(base.path_join("routes.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"rules_ref":source.rules_ref(),"prestige":pairs,"scope":"Bounded production-kernel fixture search, not earned campaign levels or an exhaustive impossibility proof."})))
 FileAccess.open(base.path_join("records.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes})))

func done() -> void:
 FileAccess.open(base.path_join("proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false}))
 print("PRESTIGE AUDIT ",checks," failures ",failures)
 get_tree().quit(1 if failures else 0)
