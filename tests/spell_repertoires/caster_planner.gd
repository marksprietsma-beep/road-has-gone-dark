extends "res://tests/character_completeness/prestige_driver.gd"
## Deliberate caster-first standard-array choices for this earned campaign.
func attributes_for(cls: String,nodes: Array) -> Dictionary:
 var explicit: Array=nodes.duplicate(true)
 if cls in ["wizard","cleric"]:explicit.append({"op":"casting","id":"arcane" if cls=="wizard" else "divine","min":1})
 return super.attributes_for(cls,explicit)
