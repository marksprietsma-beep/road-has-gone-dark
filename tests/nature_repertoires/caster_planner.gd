extends "res://tests/character_completeness/prestige_driver.gd"
var starting_arrays := {}
func attributes_for(cls: String,nodes: Array) -> Dictionary:
 if starting_arrays.has(cls):return starting_arrays[cls].duplicate(true)
 var values := super.attributes_for(cls,nodes)
 var attr: String=source.definition("classes",cls).get("casting_attribute","")
 if attr.is_empty():return values
 for key in values:
  if int(values[key])==15:
   var previous: int=int(values[attr]);values[attr]=15;values[key]=previous;break
 return values
