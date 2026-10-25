extends "res://tests/hybrid_acceptance/mechanics.gd"
## Lawful development histories through existing previews, never campaign XP.
const DUAL_ARRAY := {"STR":8,"DEX":12,"CON":10,"INT":15,"WIS":13,"CHA":14}
const WIZARD_ARRAY := {"STR":8,"DEX":12,"CON":13,"INT":15,"WIS":14,"CHA":10}
const MARTIAL_ARRAY := {"STR":10,"DEX":14,"CON":13,"INT":15,"WIS":12,"CHA":8}
func repeated(id: String,count: int) -> Array:
 var result := []
 for n in count:result.append(id)
 return result
func route(sequence: Array,attrs: Dictionary=WIZARD_ARRAY,path := "mystic-theurge",options: Dictionary={}) -> Dictionary:
 var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new()
 planner.source=source;planner.kernel=kernel
 var goals: Dictionary=planner.requirements(path,0)
 goals.nodes.append({"op":"skill","id":"spellcraft","min":4})
 var r := kernel.create("dual-prestige-fixture",attrs,"heritage-human")
 for cls in sequence:
  var proposed: Dictionary=planner.advance(r,str(cls),goals)
  check(proposed.ok,"lawful fixture step "+str(cls)+" at"+str(r.advancement_history.size()+1)+JSON.stringify(proposed.get("errors",[])))
  if not proposed.ok:planner.free();return {}
  # The planner already returned an authoritative preview. Re-evaluate only
  # deliberately changed choices, and reuse its actual snapshot for learning.
  var out: Dictionary=proposed
  var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level")
  var changed := false
  for group in choice.specialisations:
   if options.has(group) and choice.specialisations[group]!=options[group]:choice.specialisations[group]=options[group];changed=true
  if changed:
   out=kernel.preview_advancement(r,choice)
   check(out.ok,"deliberate persistent fixture choices "+str(cls)+JSON.stringify(out.get("errors",[])))
   if not out.ok:planner.free();return {}
  r=learn(out.candidate,out.snapshot)
  if r.is_empty():planner.free();return {}
 planner.free()
 if not r.advancement_history.is_empty():r.equipment=source.definition("classes",str(sequence[0])).recommended_equipment.duplicate()
 var d := kernel.derive_character(r);check(d.ok,"full fixture history/equipment valid")
 if not d.ok:return {}
 r.runtime.hp=int(d.snapshot.stats.HP)
 return RulesJson.string_keys(r)
func learn(record: Dictionary,preview_snapshot: Dictionary={}) -> Dictionary:
 var r := record.duplicate(true);var snapshot: Dictionary=preview_snapshot
 if snapshot.is_empty():
  var d := kernel.derive_character(r);check(d.ok,"legal history before spell choices")
  if not d.ok:return {}
  snapshot=d.snapshot
 var copies := RulesCoreContent.starting_preparations(snapshot,source)
 var spells: Array=copies.keys()
 for id in r.choices.prepared_abilities:
  if source.definition("abilities",id).tags.has("spontaneous") and not spells.has(id):spells.append(id)
 for cls in snapshot.class_levels:
  if source.definition("classes",cls).get("spell_mode")!="spontaneous":continue
  var candidates: Array=snapshot.abilities.filter(func(id: String):
   var a := source.definition("abilities",id)
   return a.get("casting_class")==cls and a.tags.has("spell") and not a.has("channel_spell") and RulesCoreContent.spell_eligible(snapshot,a))
  candidates.sort_custom(func(a: String,b: String):return int(source.definition("abilities",a).spell_tier)>int(source.definition("abilities",b).spell_tier) if source.definition("abilities",a).spell_tier!=source.definition("abilities",b).spell_tier else a<b)
  var limit: int=RulesCoreContent.selection_limit(cls,int(snapshot.casting_levels[cls]),source)
  for id in candidates:
   if not spells.has(id) and spells.filter(func(known: String):return source.definition("abilities",known).get("casting_class")==cls).size()<limit:spells.append(id)
 r.choices.prepared_abilities=spells;r.choices.spell_preparations=copies
 var replay := kernel._replay(r);check(replay.ok,"owned selected spells remain legal "+JSON.stringify(replay.get("errors",[])))
 if not replay.ok:return {}
 r.runtime=RulesEffects.new(source).refresh_resources(r.runtime,replay.context.capacities,"eligible_rest").runtime
 return r
