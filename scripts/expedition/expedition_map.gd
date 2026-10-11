extends Control
## Only the established public projection and known hometown enter this renderer.
var texture: ImageTexture
var view := {}
var selected := ""
var location := ""
var rendered_svg := ""
var home_view := {}
var icons := MapIconProvider.new()
var markers: Dictionary = {}
signal chosen(id: String)
func setup(svg: String, projection: Dictionary, current: String, selection: String, hometown: Dictionary={}) -> void:
 view=projection
 location=current
 selected=selection
 home_view=hometown
 if rendered_svg!=svg:
  rendered_svg=svg
  var image:=Image.new()
  if image.load_svg_from_string(LocalMapArt.for_gameplay(svg),1.0)==OK: texture=ImageTexture.create_from_image(image)
 if not resized.is_connected(rebuild): resized.connect(rebuild)
 rebuild()
func map_rect() -> Rect2:
 var edge:=minf(size.x,size.y)
 return Rect2((size-Vector2(edge,edge))/2,Vector2(edge,edge))
func screen_point(point: Array) -> Vector2:
 var rect:=map_rect()
 return rect.position+Vector2(point[0],point[1])*rect.size/1000
func rebuild() -> void:
 if view.is_empty(): return
 var rows: Array=[]
 for s in view.get("sites",[]):
  # Defense in depth: rejected states never acquire a texture, tooltip or hitbox.
  if s.get("knowledge","") not in ["discovered","visited","investigated","resolved"]: continue
  rows.append(s)
 var home: Dictionary={"id":"hometown","name":home_view.get("name","Hometown"),"position":view.home_position,"knowledge":"known","role":home_view.get("role","unidentified")}
 rows.append(home)
 var retained: Dictionary={}
 for s: Dictionary in rows:
  var id: String=s.id
  retained[id]=true
  var b: Variant=markers.get(id)
  if b==null:
   b=preload("res://scripts/ui/components/site_marker.gd").new()
   markers[id]=b
   add_child(b)
   if id!="hometown": b.pressed.connect(func(): chosen.emit(id))
  b.hometown=id=="hometown"
  b.icon_role=str(s.role) if b.hometown else MapIconRoles.site(str(s.kind))
  b.icon_texture=icons.texture_for(b.icon_role)
  b.selected=id==selected
  b.party=(id==location) or (b.hometown and location.is_empty())
  b.completed=s.knowledge in ["resolved","investigated"]
  # In crowded areas shrink only the artwork. Coordinates and hitboxes stay exact.
  var nearest:=1000.0
  for other: Dictionary in rows:
   if other.id!=id: nearest=minf(nearest,screen_point(s.position).distance_to(screen_point(other.position)))
  b.icon_diameter=clampf(nearest-7.0,14.0,24.0)
  b.size=Vector2(32,32)
  b.position=screen_point(s.position)-b.size/2
  var kind: String="Source "+b.icon_role if b.hometown else str(s.kind).capitalize()+" · Generated local site"
  b.tooltip_text=str(s.name)+" · "+kind+" · "+str(s.knowledge).capitalize()+(" · Completed" if b.completed else "")+(" · Party position" if b.party else "")
  if b.icon_texture==null: b.tooltip_text+=" · Icon unavailable"
  b.queue_redraw()
 for id in markers.keys():
  if not retained.has(id):
   var stale: Node=markers[id]
   remove_child(stale)
   stale.queue_free()
   markers.erase(id)
 # Stable baseline order; known hometown, active party and selection have priority.
 for s: Dictionary in rows: move_child(markers[s.id],get_child_count()-1)
 for id in ["hometown",location,selected]:
  if markers.has(id): move_child(markers[id],get_child_count()-1)
 queue_redraw()
func _draw() -> void:
 if texture!=null: draw_texture_rect(texture,map_rect(),false)

func marker_at(point: Vector2) -> String:
 # Overlapping rectangular targets choose the nearest genuine geographic centre.
 # No site moves; keyboard activation still uses the focused public button's ID.
 var found: String=""
 var distance:=INF
 for id in markers:
  var b: Control=markers[id]
  if not Rect2(b.position,b.size).has_point(point):continue
  var candidate:=point.distance_squared_to(b.position+b.size/2)
  if candidate<distance:
   found=id;distance=candidate
 return found
func _get_tooltip(at_position: Vector2) -> String:
 var id:=marker_at(at_position)
 return str(markers[id].tooltip_text) if not id.is_empty() else ""
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  var id:=marker_at(event.position)
  mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if not id.is_empty() else Control.CURSOR_ARROW
  for key in markers:
   markers[key].hovered=key==id
   markers[key].queue_redraw()
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  var id:=marker_at(event.position)
  if not id.is_empty():
   accept_event()
   if not event.pressed:
    markers[id].grab_focus()
    if id!="hometown":markers[id].pressed.emit()
