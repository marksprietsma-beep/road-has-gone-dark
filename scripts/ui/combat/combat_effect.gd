class_name CombatEffect
extends Control
## A short visual trace; it consumes no game commands or randomness.
var from := Vector2.ZERO
var to := Vector2.ZERO
var kind := "arrow"
var progress := 0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var tween := create_tween()
 tween.tween_property(self,"progress",1.0,CombatPacing.PROJECTILE_SECONDS)
 tween.finished.connect(queue_free)
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
 var point := from.lerp(to,progress)
 if kind=="arrow":
  var direction := (to-from).normalized()
  draw_line(point-direction*14,point,Color("171911"),4)
  draw_line(point-direction*12,point,GameUI.INK,2)
  draw_line(point-direction.rotated(0.5)*5,point,GameUI.INK,2)
  draw_line(point-direction.rotated(-0.5)*5,point,GameUI.INK,2)
 else:
  var color := Color("b6d5ff") if kind=="spark" else Color("b9dd98") if kind=="healing-thread" else GameUI.GOLD
  draw_circle(point,4,color)
  draw_arc(to,5+progress*12,0,TAU,16,Color(color,1.0-progress),2)
