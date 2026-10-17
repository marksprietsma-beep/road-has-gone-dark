extends "res://tests/character_completeness/prestige_driver.gd"
## Replay known legal historical fixture routes against v16. Never migrate a campaign.
func run() -> void:
 base=OS.get_environment("GAME126_COMPATIBILITY_ROOT");DirAccess.make_dir_recursive_absolute(base)
 # This archived GAME-126 compatibility witness must stay on v16 even after
 # a newer default pack is installed (v17+). New-pack journeys belong to the
 # newer wave's native suite; do not silently repin historical test claims.
 source=RulesRegistry.new()
 var loaded := source.load_pack("res://data/rules/trhgd-character-v16.json")
 check(loaded.ok,"load the exact v16 compatibility rules pack")
 if not loaded.ok:done();return
 kernel=RulesCharacter.new(source)
 if OS.get_environment("GAME126_AUDIT_RESTART")=="1":
  var saved := WorldOriginLore.read_json(base.path_join("records.json"))
  for id in saved.records:
   var derived := kernel.derive_character(saved.records[id])
   check(derived.ok and derived.snapshot.snapshot_hash==saved.hashes[id],"v16 full-cap compatibility cold replay "+id)
  done();return
 var old := WorldOriginLore.read_json("res://tests/character_completeness/fixtures/prestige-v15-records.json")
 var routes := {};var rejected := {};var hashes := {}
 for id in old.records:
  # A new, explicitly labelled QA fixture, NOT a saved campaign repin.
  var candidate: Dictionary=old.records[id].duplicate(true);repin_fixture(candidate)
  var result := kernel.derive_character(candidate)
  if not result.ok:rejected[id]=result.get("errors",[]);continue
  records[id]=candidate;hashes[id]=result.snapshot.snapshot_hash
  var path: String=id.split(":")[1];var base_class: String=id.split(":")[0]
  var entry := 0;var before := {};var prefix := candidate.duplicate(true);prefix.advancement_history=[]
  for step in candidate.advancement_history:
   if step.class_id==path:entry=prefix.advancement_history.size()+1;before=prefix.duplicate(true);break
   prefix.advancement_history.append(step)
  var projected := kernel._replay(before)
  check(projected.ok,"legal entry-prefix history "+id)
  before.runtime.resources=projected.context.capacities.duplicate();before.runtime.hp=int(projected.context.stats.HP)
  before.runtime.companions={}
  check(RulesEntities.synchronize(before,source).ok,"entry-prefix owned companion uses its actual owner level")
  var available := kernel.available_advancement(before)
  check(available.ok and available.classes[path].ok,"v16 actual permanent entry "+id)
  var classes: Dictionary=kernel._replay(before).context.classes
  routes[id]={"base_class":base_class,"path":path,"entry_level":entry,"entry_classes":classes,"single_class_entry":classes.size()==1 and classes.has(base_class),"bridge_dominates":int(classes.get(base_class,0))*2<before.advancement_history.size(),"final_classes":result.snapshot.class_levels,"total_level":result.snapshot.level,"prestige_cap":source.definition("classes",path).max_level,"snapshot_hash":result.snapshot.snapshot_hash,"development_fixture":true,"earned_xp":false}
  check(int(result.snapshot.class_levels[path])==int(source.definition("classes",path).max_level) and int(result.snapshot.level)==20,"full prestige cap and total20 continuation "+id)
 FileAccess.open(base.path_join("records.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"records":records,"hashes":hashes})))
 FileAccess.open(base.path_join("compatibility.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys({"rules_ref":source.rules_ref(),"source_routes":485,"source_search_pairs":576,"not_witnessed_by_bounded_search":91,"validated":routes,"no_current_fixture":rejected,"scope":"Actual v16 replay of previously witnessed histories, not exhaustive reachability, XP-funded levels or player acceptance."}),"  "))
 done()

func repin_fixture(value: Variant) -> void:
 if value is Dictionary:
  if value.has("advancement_history") and value.has("rules_ref"):value.rules_ref=source.rules_ref()
  for child in value.values():repin_fixture(child)
 elif value is Array:
  for child in value:repin_fixture(child)
