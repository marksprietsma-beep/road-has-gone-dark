extends "res://scripts/ui/first_adventure.gd"
## Capture only the UI intent; production authority is tested by the mechanics suite.
var sent := {}
func send(kind: String,target: String="",destination: Array=[]) -> void:
 sent={"kind":kind,"target":target,"destination":destination}
