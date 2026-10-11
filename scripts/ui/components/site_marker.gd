extends Button
## Fixed public-coordinate hitbox. Artwork and state ornaments never move the site.
var selected := false
var party := false
var completed := false
var hometown := false
var icon_role := "unidentified"
var icon_texture: Texture2D
var icon_diameter := 24.0
func _ready() -> void:
 custom_minimum_size=Vector2(32,32)
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for state in ["normal","hover","pressed","focus","disabled"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
 for event in [mouse_entered,mouse_exited,focus_entered,focus_exited]: event.connect(queue_redraw)
func _draw() -> void:
 var centre:=size/2
 var radius:=icon_diameter/2+2
 draw_circle(centre,radius+1,Color("171b17"))
 draw_circle(centre,radius,Color("efe1bd"))
 draw_arc(centre,radius,0,TAU,32,GameUI.GOLD if selected or hometown else Color("66583e"),1.5,true)
 if icon_texture:
  draw_texture_rect(icon_texture,Rect2(centre-Vector2.ONE*icon_diameter/2,Vector2.ONE*icon_diameter),false)
 else:
  # Resource failure remains visibly neutral; never borrow another semantic icon.
  draw_string(ThemeDB.fallback_font,centre+Vector2(-4,5),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("28221b"))
 if selected or has_focus() or is_hovered(): draw_arc(centre,radius+3,0,TAU,32,GameUI.GOLD,2.0,true)
 if completed:
  var at:=centre+Vector2(radius-2,radius-2)
  draw_circle(at,5,Color("171b17"))
  draw_polyline(PackedVector2Array([at+Vector2(-3,0),at+Vector2(-1,2),at+Vector2(3,-3)]),GameUI.GOLD,1.5,true)
 if party:
  var at:=centre+Vector2(-radius-1,-radius-2)
  draw_line(at,at+Vector2(0,12),GameUI.GOLD,1.5,true)
  draw_colored_polygon(PackedVector2Array([at,at+Vector2(8,3),at+Vector2(0,6)]),GameUI.GOLD)
