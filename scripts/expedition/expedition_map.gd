extends Control
## Only a public projection enters this presentation component.
var texture: ImageTexture
var view := {}
var selected := ""
var location := ""
var rendered_svg := ""
signal chosen(id: String)
func setup(svg: String, projection: Dictionary, current: String, selection: String) -> void:
 view=projection
 location=current
 selected=selection
 if rendered_svg!=svg:
  rendered_svg=svg
  var image := Image.new()
  if image.load_svg_from_string(LocalMapArt.for_gameplay(svg),1.0)==OK: texture=ImageTexture.create_from_image(image)
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
  var b := preload("res://scripts/ui/components/site_marker.gd").new()
  b.tooltip_text=s.name+" · "+s.knowledge+(" · Party position" if s.id==location else "")
  b.position=rect.position+Vector2(s.position[0],s.position[1])*rect.size/1000-Vector2(11,11)
  b.size=Vector2(22,22)
  b.selected=s.id==selected
  b.party=s.id==location
  add_child(b)
  b.pressed.connect(func(): chosen.emit(s.id))
 queue_redraw()
func _draw() -> void:
 var rect := map_rect()
 if texture!=null: draw_texture_rect(texture,rect,false)
 if view.is_empty(): return
 var p: Array = view.home_position
 var home := rect.position+Vector2(p[0],p[1])*rect.size/1000
 draw_rect(Rect2(home-Vector2(9,9),Vector2(18,18)),Color("22261f"))
 draw_polyline(PackedVector2Array([home+Vector2(-6,-1),home+Vector2(0,-6),home+Vector2(6,-1)]),GameUI.GOLD,1.5,true)
 draw_rect(Rect2(home+Vector2(-4,-1),Vector2(8,7)),GameUI.GOLD,false,1.5)
 if location.is_empty():
  # One combined hometown/party glyph, with a small pennant rather than rings.
  draw_line(home+Vector2(7,-9),home+Vector2(7,2),GameUI.GOLD,1.5)
  draw_colored_polygon(PackedVector2Array([home+Vector2(7,-9),home+Vector2(13,-7),home+Vector2(7,-5)]),GameUI.GOLD)
