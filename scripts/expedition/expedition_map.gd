extends Control
## Only a public projection enters this presentation component.
var texture: ImageTexture
var view := {}
var selected := ""
var location := ""
signal chosen(id: String)
func setup(svg: String, projection: Dictionary, current: String, selection: String) -> void:
 view=projection
 location=current
 selected=selection
 var image := Image.new()
 if image.load_svg_from_string(svg,1.0)==OK: texture=ImageTexture.create_from_image(image)
 for child in get_children(): child.queue_free()
 if not resized.is_connected(rebuild): resized.connect(rebuild)
 rebuild()
func map_rect() -> Rect2:
 var edge := minf(size.x,size.y)
 return Rect2((size-Vector2(edge,edge))/2,Vector2(edge,edge))
func rebuild() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var rect := map_rect()
 for i in view.get("sites",[]).size():
  var s: Dictionary = view.sites[i]
  var b := Button.new()
  b.text=str(i+1)
  b.tooltip_text=s.name+" · "+s.knowledge
  b.position=rect.position+Vector2(s.position[0],s.position[1])*rect.size/1000-Vector2(9,10)
  b.size=Vector2(18,20)
  b.add_theme_font_size_override("font_size",12)
  b.modulate=Color(1,0.85,0.4) if s.id==selected else Color.WHITE
  add_child(b)
  b.pressed.connect(func(): chosen.emit(s.id))
 queue_redraw()
func _draw() -> void:
 var rect := map_rect()
 if texture!=null: draw_texture_rect(texture,rect,false)
 if view.is_empty(): return
 var p: Array = view.home_position
 var home := rect.position+Vector2(p[0],p[1])*rect.size/1000
 draw_circle(home,5,Color("#34352b"))
 draw_arc(home,7,0,TAU,24,Color("#f4d47c"),2)
 var current := home
 for s in view.get("sites",[]):
  if s.id==location: current=rect.position+Vector2(s.position[0],s.position[1])*rect.size/1000
 draw_arc(current,12,0,TAU,24,Color("#875430"),2)
