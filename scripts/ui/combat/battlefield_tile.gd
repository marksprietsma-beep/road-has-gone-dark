class_name BattlefieldTile
extends Button
## Original project-authored 32px terrain. Draws beneath authoritative overlays.
## Coordinates choose texture flecks only; no world, combat RNG or map generation.
var ground := "g"
var feature := ""
var coordinates := Vector2i.ZERO
var terrain_blocked := false
var faction := ""
var active_tile := false
var target_tile := false
var move_tile := false
var hovered := false
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 mouse_entered.connect(func():hovered=true;queue_redraw())
 mouse_exited.connect(func():hovered=false;queue_redraw())
func pixel(rect: Rect2,color: String) -> void:draw_rect(rect,Color(color))
func _draw() -> void:
 if size.x<=0 or size.y<=0:return
 draw_set_transform(Vector2.ZERO,0,size/32.0)
 var road := ground=="r"
 pixel(Rect2(0,0,32,32),"756347" if road else "776b4e" if ground=="d" else "545b4d" if ground=="u" else "655f50" if ground=="p" else "34482e")
 # Sparse fixed-coordinate flecks: visual variation, never a new layout.
 var pattern: int=("terrain:%d:%d"%[coordinates.x,coordinates.y]).sha256_text().left(6).hex_to_int()
 for i in 12:
  var x := (pattern+i*11)%30;var y := (pattern/13+i*7)%30
  pixel(Rect2(x,y,2,1),"8c7855" if road else "928265" if ground=="d" else "677062" if ground=="u" else "817b68" if ground=="p" else "42583a")
  if ground=="g" and i%3==0:pixel(Rect2(x,y-2,1,3),"52663e")
 if road:
  var rut := 15 if coordinates.y%2==1 else 17
  pixel(Rect2(0,rut,32,2),"665339");pixel(Rect2(0,rut+3,32,1),"a0885c")
  pixel(Rect2(3+(coordinates.x%3)*7,16,6,1),"b0986b")
 elif ground=="g" and coordinates.y in [2,5]:
  # Broken verge avoids a solid geometric road edge.
  pixel(Rect2(0,27 if coordinates.y==2 else 0,32,5),"536042")
  pixel(Rect2(4,29 if coordinates.y==2 else 0,18,3),"736348")
 match feature:
  "wall":
   pixel(Rect2(2,6,28,22),"333a32");pixel(Rect2(3,5,26,19),"80816e")
   for y in [6,12,18]:
    pixel(Rect2(3,y+5,26,1),"555d4c")
    for x in [4,14,24]:pixel(Rect2(x+(3 if y==12 else 0),y,1,5),"525a49")
   pixel(Rect2(7,3,8,3),"a6a48a");pixel(Rect2(18,19,9,6),"424c3b")
  "rubble":
   for r in [Rect2(4,17,8,6),Rect2(14,12,9,7),Rect2(19,22,9,5)]:pixel(r,"96957d")
  "campfire":
   pixel(Rect2(8,18,18,8),"282c24");pixel(Rect2(10,20,13,3),"857056")
   pixel(Rect2(14,12,6,10),"b98141");pixel(Rect2(16,15,3,7),"e1ba65")
  "tree":
   pixel(Rect2(5,23,23,5),"253727");pixel(Rect2(14,17,4,11),"66503a")
   pixel(Rect2(7,4,18,18),"1d3028");pixel(Rect2(4,9,25,9),"243e2d")
   pixel(Rect2(9,2,14,18),"355338");pixel(Rect2(8,7,11,7),"496640")
   pixel(Rect2(13,3,7,4),"5d7649");pixel(Rect2(19,16,6,4),"29452f")
  "rock":
   pixel(Rect2(4,23,24,5),"253126");pixel(Rect2(6,10,21,14),"53594f")
   pixel(Rect2(9,7,15,15),"72786a");pixel(Rect2(10,7,10,3),"a4a38b")
   pixel(Rect2(7,12,3,8),"90927f");pixel(Rect2(19,15,5,7),"606759")
   pixel(Rect2(2,25,6,3),"7d806d")
  "cart":
   pixel(Rect2(3,24,25,4),"28352a");pixel(Rect2(6,8,20,14),"352d25")
   for y in [10,14,18]:pixel(Rect2(7,y,18,3),"95734a")
   pixel(Rect2(9,6,3,19),"bd9861");pixel(Rect2(22,6,3,17),"795639")
   pixel(Rect2(4,21,7,5),"20221d");pixel(Rect2(22,20,7,5),"252620")
   pixel(Rect2(25,13,6,2),"b29362");pixel(Rect2(2,14,5,2),"70523a")
  "milestone":
   pixel(Rect2(8,23,17,4),"25372a");pixel(Rect2(12,8,9,17),"75786b")
   pixel(Rect2(13,6,7,16),"b2ae91");pixel(Rect2(15,10,3,1),"626757")
   pixel(Rect2(15,13,3,1),"626757");pixel(Rect2(17,7,3,14),"979e85")
  "scrub":
   pixel(Rect2(7,24,20,3),"293b29");pixel(Rect2(8,16,15,10),"3d582f")
   pixel(Rect2(4,20,21,5),"4d6438");pixel(Rect2(10,14,7,7),"69794a")
   pixel(Rect2(20,16,6,6),"536b3c")
  "ditch":
   pixel(Rect2(0,8,32,6),"283a2b");pixel(Rect2(0,9,32,3),"202f28")
   pixel(Rect2(0,14,32,1),"61704a");pixel(Rect2(7,16,1,5),"819361")
 draw_set_transform(Vector2.ZERO)
 var area := Rect2(Vector2.ZERO,size)
 if not faction.is_empty():draw_rect(area,Color(0.14,0.31,0.40,0.28) if faction=="party" else Color(0.43,0.16,0.12,0.25))
 if move_tile:draw_rect(area,Color(0.57,0.70,0.42,0.20))
 if target_tile:draw_rect(area,Color(0.88,0.65,0.33,0.22))
 if hovered and not disabled:draw_rect(area,Color(1,0.93,0.73,0.10))
 var border := GameUI.GOLD if active_tile else Color(0.91,0.84,0.63,0.55) if move_tile or target_tile else Color(0.77,0.79,0.65,0.18)
 draw_rect(area,border,false,2 if active_tile else 1)
 if terrain_blocked:
  # This flag comes from the board, never the drawn feature.
  draw_line(size-Vector2(9,9),size-Vector2(3,3),Color("e9c5a0"),1)
  draw_line(size-Vector2(9,3),size-Vector2(3,9),Color("e9c5a0"),1)
 elif move_tile:draw_circle(size*0.5,1.5,Color("eadfb4"))
