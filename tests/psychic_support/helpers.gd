extends "res://tests/psychic_parity/mechanics.gd"
const WISDOM := {"STR":8,"DEX":13,"CON":14,"INT":12,"WIS":15,"CHA":10}
func cognition(heritage := "heritage-human",count := 5) -> Dictionary:
 var record := kernel.create("cognition",PSI,heritage)
 for index in 8+count:
  var cls := "psychic-warrior" if index<8 else "cognition-adept"
  var suggested := kernel.suggested_choice(record,cls,"psychic-discipline" if index==0 else "steady-study")
  check(suggested.ok,"lawful cognition suggestion "+str(index)+JSON.stringify(suggested.get("errors",[])))
  if not suggested.ok:return {}
  var choice: Dictionary=suggested.choice
  if index<4:
   var allocation: Dictionary=choice.skill_allocations
   if not allocation.has("perception"):
    var first: String=str(allocation.keys()[0]);allocation[first]-=1
    if allocation[first]==0:allocation.erase(first)
    allocation.perception=1
  if not choice.attribute_increase.is_empty():choice.attribute_increase="INT"
  var step := kernel.preview_advancement(record,choice)
  check(step.ok,"lawful cognition history "+str(index)+JSON.stringify(step.get("errors",[])))
  if not step.ok:return {}
  record=step.candidate
 record.equipment=["shortblade"]
 record.runtime.hp=int(kernel.derive_character(record).snapshot.stats.HP)
 record.runtime.resources=kernel._replay(record).context.capacities.duplicate(true)
 check(kernel.validate_build(record).ok,"lawful equipped cognition history")
 return record
