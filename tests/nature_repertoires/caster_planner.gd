extends "res://tests/character_completeness/prestige_driver.gd"
func attributes_for(cls: String,nodes: Array) -> Dictionary:
 var values := super.attributes_for(cls,nodes)
 var attr: String=source.definition("classes",cls).get("casting_attribute","")
 if attr.is_empty():return values
 for key in values:
  if int(values[key])==15:
   var previous: int=int(values[attr]);values[attr]=15;values[key]=previous;break
 return values
