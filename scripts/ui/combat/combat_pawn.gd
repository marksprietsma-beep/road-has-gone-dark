class_name CombatPawn
extends Control
## Draw original provider layers. Tween effects follow committed state; never send commands.
var recipe := {}
var unit := {}
var active := false
var max_hp := 1
var badge := ""
var animation := "idle"
var age := 0.0
var effect_time := 0.0
var effect_kind := ""
var feedback := ""
var travel := Vector2.ZERO
var impulse := Vector2.ZERO
var down := false
var mirror := false

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
 age+=delta
 effect_time=maxf(0.0,effect_time-delta)
 if effect_time==0.0: animation="down" if down else "idle";effect_kind="";feedback=""
 queue_redraw()

func present(value: Dictionary, art: Dictionary, selected: bool, hp: int, label: String) -> void:
 unit=value;recipe=art;active=selected;max_hp=hp;badge=label
 down=int(unit.record.runtime.hp)<=0;mirror=unit.team=="enemy"
 animation="down" if down else "idle"
 queue_redraw()

func animate(kind: String, offset: Vector2=Vector2.ZERO, text: String="") -> void:
 effect_kind=kind;effect_time=0.65;feedback=text;age=0.0
 animation="move" if kind=="move" else "spell" if kind in ["spark","slow","healing-thread","guard"] else "attack" if kind=="attack" else "hit" if kind=="hit" else "down"
 if kind=="move":
  travel=offset
  create_tween().tween_property(self,"travel",Vector2.ZERO,0.4).set_trans(Tween.TRANS_SINE)
 elif kind=="attack":
  impulse=Vector2(-4 if mirror else 4,0)
  create_tween().tween_property(self,"impulse",Vector2.ZERO,0.35)

func animate_route(points: Array) -> void:
 if points.is_empty(): return
 travel=points[0]
 var tween := create_tween()
 for point in points.slice(1): tween.tween_property(self,"travel",point,0.09)
 effect_time=maxf(effect_time,points.size()*0.09+0.1)

func _draw() -> void:
 if unit.is_empty(): return
 var ink := GameUI.GOLD if active else GameUI.INK
 var faction := Color("a5d3ea") if unit.team=="party" else Color("f0b1a0")
 var center := Vector2(size.x/2,size.y*0.50)+travel+impulse
 var width: float=minf(size.x-3,size.y-8)*float(recipe.get("scale",1.0))
 var origin := center-Vector2(width,width)/2.0
 draw_circle(center+Vector2(0,width*0.34),width*0.27,Color(0,0,0,0.45))
 if not recipe.get("available",false):
  draw_string(ThemeDB.fallback_font,center+Vector2(-5,5),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,18,GameUI.ERROR)
 else:
  var layers: Array=recipe.animations.get(animation,recipe.animations.idle)
  for layer in layers:
   var path: String=layer.get("path","")
   var sequence: Array=layer.get("sequence",[])
   if not sequence.is_empty(): path="res://assets/combat/"+str(sequence[int(age*8.0)%sequence.size()] if animation!="down" else sequence[0])
   var tex := CombatArt.texture(path)
   if tex==null: continue
   var frame := Vector2(float(layer.frame[0]),float(layer.frame[1]))
   var region: Rect2
   if not layer.get("rect",[]).is_empty(): region=Rect2(layer.rect[0],layer.rect[1],layer.rect[2],layer.rect[3])
   elif not sequence.is_empty(): region=Rect2(Vector2.ZERO,frame)
   else:
    var count: int=maxi(1,int(tex.get_width()/frame.x))
    var index := 0 if animation=="idle" else mini(count-1,int(age*12.0)) if animation=="down" else int(age*12.0)%count
    region=Rect2(Vector2(index*frame.x,float(layer.get("row",0))*frame.y),frame)
   var native: float=float(recipe.native)
   var offset := Vector2(float(layer.get("offset",[0,0])[0]),float(layer.get("offset",[0,0])[1]))
   var destination := Rect2(origin+offset*width/native,region.size*width/native)
   # Ready-made 0x72 16x28 bodies use a 32px reference; center their narrower silhouettes.
   if recipe.style_id=="0x72": destination.position.x+=width*0.25
   var tint := Color(0.65,0.65,0.65,0.7) if down else Color.WHITE
   if effect_kind=="hit" and effect_time>0.3: tint=Color(1.6,0.65,0.55)
   if down and recipe.style_id!="lpc": destination.position.y+=width*0.15;destination.size.y*=0.55
   if mirror: draw_set_transform(Vector2(center.x*2,0),0,Vector2(-1,1))
   var proportions := Vector2(recipe.proportions[0],recipe.proportions[1])
   destination.position=center+(destination.position-center)*proportions
   destination.size*=proportions
   draw_texture_rect_region(tex,destination,region,tint)
   if mirror: draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  if recipe.get("procedural_weapon",false):
   # Navinius WIP has no bow or staff; these are explicitly labelled engine props.
   var at := center+Vector2(-width*0.32 if mirror else width*0.32,0)
   if recipe.role=="scout":
    draw_arc(at,width*0.22,-PI/2,PI/2,8,Color("bca074"),2.0)
    draw_line(at+Vector2(0,-width*0.22),at+Vector2(0,width*0.22),GameUI.INK,1.0)
   else:
    draw_line(at+Vector2(0,-width*0.30),at+Vector2(0,width*0.35),Color("bca074"),2.0)
    draw_circle(at-Vector2(0,width*0.30),2.5,Color("a8bff4"))
 if effect_kind in ["spark","slow","healing-thread","guard"]:
  var color := Color("b0d2ff") if effect_kind=="spark" else Color("b2d98d") if effect_kind=="healing-thread" else GameUI.GOLD
  draw_arc(center,width*(0.3+(0.65-effect_time)*0.3),0,TAU,20,color,2.0)
 if effect_kind=="attack" and recipe.get("style_id")=="navinius":
  var slash := CombatArt.texture("res://assets/combat/navinius/Modular RPG Pixel Art/Effects/Slash/Slash_White.png")
  if slash!=null: draw_texture_rect(slash,Rect2(center-Vector2(width,width)/2,Vector2(width,width)),false,Color(1,1,1,effect_time/0.65))
 var font := ThemeDB.fallback_font
 var font_size := 10 if size.x<50 else 12
 draw_string(font,Vector2(3,font_size),badge,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
 # Team glyphs and weapon names supplement colour, including downed units.
 draw_string(font,Vector2(size.x-12,font_size),"◆" if unit.team=="party" else "×",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,faction)
 var hp := int(unit.record.runtime.hp)
 draw_rect(Rect2(3,size.y-7,size.x-6,4),Color("100f0d"))
 draw_rect(Rect2(3,size.y-7,(size.x-6)*clampf(float(hp)/max_hp,0,1),4),faction)
 if down: draw_string(font,center+Vector2(-12,0),"DOWN",HORIZONTAL_ALIGNMENT_LEFT,-1,10,GameUI.ERROR)
 if not feedback.is_empty(): draw_string(font,center+Vector2(-12,-10-(0.65-effect_time)*20),feedback,HORIZONTAL_ALIGNMENT_LEFT,-1,12,GameUI.INK)
