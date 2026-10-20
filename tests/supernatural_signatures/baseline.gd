extends "res://tests/class_signatures/mechanics_driver.gd"
## Actual Windows reproduction of the v20 gaps, before implementation.
func run() -> void:
 base=OS.get_environment("GAME148_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded := source.load_pack("res://data/rules/trhgd-character-v20.json")
 check(loaded.ok,"frozen v20 baseline loads")
 if not loaded.ok:finish_baseline();return
 kernel=RulesCharacter.new(source)
 var warlock := build("warlock",20)
 var binder := build("binder",8)
 var dragon := build("dragonfire-adept",20)
 var target := build("fighter",20);target.character_id="baseline-target"
 # Pressure improves weapon accuracy, but cannot change this class's blast save.
 var pressure: Dictionary=warlock.duplicate(true)
 pressure.advancement_history[15].specialisations["warlock-career-16"]="pressure"
 var d := kernel.derive_character(pressure);check(d.ok,"legal pressure selection")
 check(d.snapshot.stats.save_dc==kernel.derive_character(warlock).snapshot.stats.save_dc,"v20 pressure has no effect on defining save-based invocations")
 var late := use(warlock,target,"warlock-master-20")
 check(late.ok and not late.events.any(func(e: Dictionary):return e.get("type")=="save_resolved"),"v20 late invocation executes without a saving throw")
 check(late.ok and late.target.runtime.hp<target.runtime.hp,"v20 late unavoidable damage is real")
 # The alternative covenant is durable, but control is unavoidable and has no
 # distinct later support action: every base class level grants the same shelter.
 binder.advancement_history[0].specialisations["binder-pact"]="sentinel"
 check(kernel.validate_build(binder).ok,"legal sentinel covenant")
 var stopped := use(binder,target,"binder-sentinel")
 check(stopped.ok and stopped.target.runtime.statuses.any(func(s: Dictionary):return s.id=="slowed"),"v20 sentinel applies Slowed without a save")
 check(stopped.ok and int(stopped.actor.runtime.resources["binder-commitments"])==int(binder.runtime.resources["binder-commitments"])-1,"v20 covenant spends actual finite commitment")
 check(not use(binder,target,"binder-embers").ok,"v20 already rejects unselected covenant; preserve it")
 # Later schedules reuse the same effect structure/targets; Ward and Hindrance
 # scale numbers, while Veil is byte-identical.
 for kind in ["ward","veil","hindrance"]:
  var first := source.definition("abilities","draconic-"+kind+"-1")
  for at in [6,11,16]:
   var later := source.definition("abilities","draconic-"+kind+"-"+str(at))
   check(effect_shape(first.effects)==effect_shape(later.effects) and first.targeting==later.targeting,"v20 repeated invocation structure "+kind+str(at))
 var breath := use(dragon,target,"dragon-breath-fire")
 check(breath.ok and breath.actor.runtime.resources==dragon.runtime.resources,"v20 repeatable breath already has no finite cost")
 finish_baseline()
func finish_baseline() -> void:
 var proof := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"scope":"v20 Windows deficiency reproduction; no production changes or release claim"}
 FileAccess.open(base.path_join("baseline-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof))
 print("GAME148 BASELINE ",JSON.stringify(proof));get_tree().quit(1 if failures else 0)

func effect_shape(value: Variant) -> Variant:
 if value is Array:return value.map(effect_shape)
 if value is Dictionary:
  var out := {}
  for key in value:
   if key not in ["amount","dc","value"]:out[key]=effect_shape(value[key])
  return out
 return value
