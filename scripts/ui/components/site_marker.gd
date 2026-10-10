extends Button
var selected := false
var party := false
func _ready() -> void:
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 for state in ["normal", "hover", "pressed", "focus", "disabled"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
 mouse_entered.connect(queue_redraw)
 mouse_exited.connect(queue_redraw)
 focus_entered.connect(queue_redraw)
 focus_exited.connect(queue_redraw)
func _draw() -> void:
 var centre := size / 2
 var points := PackedVector2Array([centre + Vector2(0,-7),centre + Vector2(7,0),centre + Vector2(0,7),centre + Vector2(-7,0)])
 draw_colored_polygon(points, Color("242920"))
 var rim := GameUI.GOLD if selected else Color("f0e5c7")
 draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]), rim, 1.5, true)
 draw_circle(centre, 2, rim)
 if party:
  draw_colored_polygon(PackedVector2Array([centre+Vector2(-4,9),centre+Vector2(4,9),centre+Vector2(0,4)]), GameUI.GOLD)
 if selected or has_focus() or is_hovered(): draw_arc(centre, 10, 0, TAU, 32, GameUI.GOLD, 1.0, true)
